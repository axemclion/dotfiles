#!/usr/bin/env bash
#
# server.sh - dashboard to start/stop/monitor the local dev services.
#
# Usage: ./server.sh
#   up/down (or j/k)  move the selection
#   space / enter     toggle start/stop on the selected process
#   r                 refresh CPU/RAM/GPU/port stats
#   l                 tail the selected process's log (press any key to return)
#   c                 show the actual code that starts it
#   q / esc           quit the dashboard (processes keep running)

set -u

# ============================================================================
# PROCESS LIST - edit this section to add/change services.
# Each process needs a matching entry (same index) in every array below.
# ============================================================================

PROC_NAMES=(smbd comfyui ollama rustfs vibecomics)
PROC_LABEL=(
  "Samba (smbd)"
  "ComfyUI"
  "Ollama"
  "RustFS (S3 storage)"
  "VibeComics dev server"
)
# The data folder each process owns, shown in its own column (blank if none).
PROC_FOLDER=(
  "~/data/podcasts"
  ""
  ""
  "~/data/rustfs"
  ""
)
# Log file per process, as requested: /tmp/<process_name>.log
PROC_LOG=()
for name in "${PROC_NAMES[@]}"; do PROC_LOG+=("/tmp/${name}.log"); done

# A substring of the full command line (as seen in /proc/<pid>/cmdline) that
# uniquely identifies the running process. Used by pgrep -f for status/stop.
PROC_MATCH=(
  "smbd -F --no-process-group"
  "_workspace/comfyui/ComfyUI/main.py"
  "ollama serve"
  "/usr/bin/rustfs server"
  "node_modules/vite/bin/vite.js"
)

# Ports each process listens on (space separated, shown in the dashboard).
PROC_PORTS=(
  "139 445"
  "8188"
  "11434"
  "9000 9001"
  "8080"
)

# Whether start/stop needs sudo.
PROC_SUDO=(1 0 0 0 0)

# Function that starts the process (defined below). Called with no args.
PROC_START=(start_smbd start_comfyui start_ollama start_rustfs start_vibecomics)

VIBE_DIR="$HOME/_workspace/vibecomics"
COMFY_DIR="$HOME/_workspace/comfyui"
RUSTFS_DATA_DIR="$HOME/data/rustfs"

# ============================================================================
# START FUNCTIONS
# ============================================================================

# Assumes samba is installed and /etc/samba/smb.conf is already configured
# (this file only starts/stops services, it doesn't provision them).
start_smbd() {
  nohup sudo smbd -F --no-process-group >>"${PROC_LOG[0]}" 2>&1 &
  disown
}

start_comfyui() {
  (
    cd "$COMFY_DIR/ComfyUI" || exit 1
    export PYTORCH_HIP_ALLOC_CONF=expandable_segments:True
    exec "$COMFY_DIR/.venv/bin/python" "$COMFY_DIR/ComfyUI/main.py" \
      --listen 0.0.0.0 --reserve-vram 15 --enable-cors-header \
      --supports-fp8-compute --fast fp8_matrix_mult \
      --output-directory /tmp/comfyui-outputs \
      --input-directory "$HOME/data/comfyui/inputs"
  ) >>"${PROC_LOG[1]}" 2>&1 &
  disown
}

start_ollama() {
  (
    export OLLAMA_MODELS="$HOME/data/ollama-models"
    export OLLAMA_HOST=0.0.0.0
    export OLLAMA_KEEP_ALIVE=-1
    export OLLAMA_MAX_LOADED_MODELS=1
    export OLLAMA_FLASH_ATTENTION=1
    export OLLAMA_KV_CACHE_TYPE=q8_0
    export OLLAMA_CONTEXT_LENGTH=131072
    exec ollama serve
  ) >>"${PROC_LOG[2]}" 2>&1 &
  disown
}

# RustFS: S3-compatible storage for VibeComics. Root
# access key/secret are required by RustFS itself - must match whatever is used to connect
# the app (its connect screen, or scripts/configure-s3-bucket.mjs's connection string).
# No global CORS flag exists in 1.0.1 (checked `rustfs server --help` directly) - CORS is
# applied per bucket instead, via scripts/configure-s3-bucket.mjs in the vibecomics repo.
start_rustfs() {
  mkdir -p "$RUSTFS_DATA_DIR"
  (
    export RUSTFS_ACCESS_KEY="changeme"
    export RUSTFS_SECRET_KEY="changeme"
    export RUSTFS_VOLUMES="$RUSTFS_DATA_DIR"
    export RUSTFS_ADDRESS=":9000"
    export RUSTFS_CONSOLE_ENABLE=true
    export RUSTFS_CONSOLE_ADDRESS=":9001"
    exec /usr/bin/rustfs server
  ) >>"${PROC_LOG[3]}" 2>&1 &
  disown
}

start_vibecomics() {
  node "$VIBE_DIR/scripts/extract-docs.mjs" >>"${PROC_LOG[4]}" 2>&1
  node "$VIBE_DIR/scripts/build-cli.mjs" >>"${PROC_LOG[4]}" 2>&1
  (
    cd "$VIBE_DIR" || exit 1
    exec node "$VIBE_DIR/node_modules/vite/bin/vite.js"
  ) >>"${PROC_LOG[4]}" 2>&1 &
  disown
}

# ============================================================================
# STATUS / STOP HELPERS
# ============================================================================

# Prints one PID per line, empty if not running.
find_pids() {
  pgrep -f -- "${PROC_MATCH[$1]}" 2>/dev/null
}

# Fills the array named by $2 (via nameref) with the PIDs for process $1.
read_pids() {
  local -n _out=$2
  mapfile -t _out < <(find_pids "$1")
}

kill_pids() {
  local idx=$1; shift
  if [[ "${PROC_SUDO[$idx]}" == "1" ]]; then
    sudo kill "$@" 2>/dev/null
  else
    kill "$@" 2>/dev/null
  fi
}

stop_process() {
  local idx=$1
  local -a pids
  read_pids "$idx" pids
  (( ${#pids[@]} == 0 )) && return

  echo "Stopping ${PROC_LABEL[$idx]} (pid(s): ${pids[*]})..."
  kill_pids "$idx" "${pids[@]}"
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.3
    read_pids "$idx" pids
    (( ${#pids[@]} == 0 )) && return
  done
  echo "Still alive, force killing..."
  kill_pids "$idx" -9 "${pids[@]}"
}

toggle_process() {
  local idx=$1
  if [[ -n "$(find_pids "$idx")" ]]; then
    stop_process "$idx"
  else
    echo "Starting ${PROC_LABEL[$idx]}..."
    "${PROC_START[$idx]}"
    sleep 0.5
  fi
}

# Per-pid GPU memory via KFD (ROCm), if the kernel exposes it. Best effort:
# AMD APUs share system RAM with the GPU and there is no nvidia-smi/rocm-smi
# equivalent here, so this is often unavailable - the header's system-wide
# GPU total is the reliable number.
gpu_mem_for_pid() {
  local pid=$1
  local f="/sys/class/kfd/kfd/proc/$pid/vram_usage"
  if [[ -r "$f" ]]; then
    echo "$(( $(cat "$f" 2>/dev/null || echo 0) / 1024 / 1024 ))"
  else
    echo "-"
  fi
}

proc_stats() {
  # Prints "PIDS CPU% RSS_MIB GPU_MIB" for a process index, "- - - -" if down.
  local idx=$1
  local -a pids
  read_pids "$idx" pids
  if (( ${#pids[@]} == 0 )); then
    echo "- - - -"
    return
  fi

  local pid_list cpu rss
  pid_list=$(IFS=,; echo "${pids[*]}")
  read -r cpu rss < <(
    ps -o %cpu=,rss= -p "$pid_list" 2>/dev/null \
      | awk '{cpu+=$1; rss+=$2} END{printf "%.1f %d", cpu, rss}'
  )

  local p g gpu_total=0 gpu_known=0
  for p in "${pids[@]}"; do
    g=$(gpu_mem_for_pid "$p")
    if [[ "$g" != "-" ]]; then
      gpu_total=$(( gpu_total + g ))
      gpu_known=1
    fi
  done
  local gpu_disp="-"
  (( gpu_known )) && gpu_disp="$gpu_total"

  echo "$pid_list $cpu $(( rss / 1024 )) $gpu_disp"
}

ports_display() {
  local idx=$1
  local out=""
  for p in ${PROC_PORTS[$idx]}; do
    if ss -H -ltn "( sport = :$p )" 2>/dev/null | grep -q LISTEN; then
      out="$out $p"
    else
      out="$out ($p)"
    fi
  done
  echo "${out# }"
}

gpu_summary() {
  local base=/sys/class/drm/card0/device
  if [[ -r "$base/mem_info_vram_used" ]]; then
    local vu vt gu gt
    vu=$(( $(cat "$base/mem_info_vram_used") / 1024 / 1024 ))
    vt=$(( $(cat "$base/mem_info_vram_total") / 1024 / 1024 ))
    gu=$(( $(cat "$base/mem_info_gtt_used") / 1024 / 1024 ))
    gt=$(( $(cat "$base/mem_info_gtt_total") / 1024 / 1024 ))
    printf "GPU VRAM: %d/%d MiB   GPU GTT: %d/%d MiB" "$vu" "$vt" "$gu" "$gt"
  else
    printf "GPU memory info not available"
  fi
}

# ============================================================================
# DASHBOARD
#
# Stats (pgrep/ps/ss calls - the expensive part) are only recomputed into the
# CACHE_* arrays by refresh_stats(), which runs on startup, after a toggle, or
# when you press 'r'. Plain cursor movement (arrows/j/k) only calls render(),
# which just repaints from the cache - no process lookups, so it's instant and
# there's no background auto-refresh ticking in the background either.
# ============================================================================

CACHE_HEADER1=""
CACHE_HEADER2=""
CACHE_ROW=()   # one pre-formatted "box label folder pid cpu rss gpu ports" line per process

refresh_stats() {
  CACHE_HEADER1="server.sh - $(date '+%Y-%m-%d %H:%M:%S')"
  CACHE_HEADER2="$(gpu_summary)   |   $(uptime | sed 's/.*load average: /load avg: /')"
  local i pid cpu rss gpu box
  for i in "${!PROC_NAMES[@]}"; do
    read -r pid cpu rss gpu < <(proc_stats "$i")
    box="[ ]"; [[ "$pid" != "-" ]] && box="[x]"
    CACHE_ROW[$i]=$(printf "%-4s %-22s %-18s %-22s %6s %9s %8s %-14s" \
      "$box" "${PROC_LABEL[$i]}" "${PROC_FOLDER[$i]}" "$pid" "$cpu" "$rss" "$gpu" "$(ports_display "$i")")
  done
}

render() {
  local cursor=$1
  tput cup 0 0 2>/dev/null
  printf '%s\033[K\n' "$CACHE_HEADER1"
  printf '%s\033[K\n' "$CACHE_HEADER2"
  printf '\033[K\n'
  printf "    %-4s %-22s %-18s %-22s %6s %9s %8s %-14s\033[K\n" "   " "PROCESS" "FOLDER" "PID(S)" "CPU%" "RAM(MiB)" "GPU(MiB)" "PORTS"
  printf '%s\033[K\n' "------------------------------------------------------------------------------------------------------------"
  local i
  for i in "${!PROC_NAMES[@]}"; do
    if [[ "$i" == "$cursor" ]]; then
      printf "> \033[7m%s\033[0m\033[K\n" "${CACHE_ROW[$i]}"
    else
      printf "  %s\033[K\n" "${CACHE_ROW[$i]}"
    fi
  done
  printf '\033[K\n'
  printf '%s\033[K\n' "up/down move   space/enter = toggle   r = refresh stats   l = tail log   c = show full command   q/esc = quit"
  tput ed 2>/dev/null
}

view_logs() {
  local idx=$1
  clear
  echo "Tailing ${PROC_LOG[$idx]} for ${PROC_LABEL[$idx]} (press any key to return)..."
  echo
  touch "${PROC_LOG[$idx]}"
  tail -n 200 -f "${PROC_LOG[$idx]}" &
  local tail_pid=$!
  # Set AFTER backgrounding tail, not before: SIG_IGN survives exec, so a
  # trap set first would make tail itself immune to Ctrl-C too.
  trap '' INT
  local key
  while kill -0 "$tail_pid" 2>/dev/null; do
    IFS= read -rsn1 -t 0.3 key && break   # any key ends the view
  done
  kill "$tail_pid" 2>/dev/null
  wait "$tail_pid" 2>/dev/null
  trap_int
}

view_cmdline() {
  local idx=$1
  clear
  echo "Full command for ${PROC_LABEL[$idx]}:"
  echo "(literal source of ${PROC_START[$idx]}(), below - the actual code that runs)"
  echo
  declare -f "${PROC_START[$idx]}"
  echo
  echo "(log: ${PROC_LOG[$idx]})"
  echo
  echo -n "Press any key to return..."
  IFS= read -rsn1 _
}

enable_raw_mode() {
  stty -echo -icanon time 0 min 0 2>/dev/null
  tput civis 2>/dev/null       # hide cursor
}

restore_tty() {
  [[ -n "${_OLD_STTY:-}" ]] && stty "$_OLD_STTY" 2>/dev/null
  tput cnorm 2>/dev/null       # show cursor
}

# Ctrl-C/TERM during the dashboard should restore the tty before exiting,
# same as a normal quit. view_logs briefly overrides this so Ctrl-C there
# just stops `tail` instead of killing the whole script.
trap_int() {
  trap 'restore_tty; exit 130' INT TERM
}

# Reads one logical keypress from the user into $KEY: a literal character,
# $'\n' for Enter, "ESC" for a bare Escape, or "ESC[A"/"ESC[B"/... for an
# arrow key (sent as Escape followed by a 2-byte CSI sequence). Sets
# KEY="__EOF__" if stdin closes.
read_key() {
  local key rest rc rc2
  IFS= read -rsn1 key
  rc=$?
  if (( rc != 0 )); then
    KEY="__EOF__"
  elif [[ -z "$key" ]]; then
    KEY=$'\n'
  elif [[ "$key" == $'\x1b' ]]; then
    IFS= read -rsn2 -t 0.05 rest
    rc2=$?
    if (( rc2 != 0 )) || [[ -z "$rest" ]]; then
      KEY="ESC"
    else
      KEY="ESC${rest}"
    fi
  else
    KEY="$key"
  fi
}

main() {
  local cursor=0
  local last=$(( ${#PROC_NAMES[@]} - 1 ))
  _OLD_STTY=$(stty -g 2>/dev/null) || true
  trap restore_tty EXIT
  trap_int
  enable_raw_mode
  clear
  refresh_stats
  render "$cursor"

  local KEY
  while true; do
    read_key
    case "$KEY" in
      __EOF__|q|Q|ESC) break ;;
      "ESC[A"|k|K)
        (( cursor > 0 )) && { (( cursor-- )); render "$cursor"; }
        ;;
      "ESC[B"|j|J)
        (( cursor < last )) && { (( cursor++ )); render "$cursor"; }
        ;;
      " "|$'\n')
        toggle_process "$cursor"
        refresh_stats
        render "$cursor"
        ;;
      r|R)
        refresh_stats
        render "$cursor"
        ;;
      l|L)
        view_logs "$cursor"
        clear
        refresh_stats
        render "$cursor"
        ;;
      c|C)
        view_cmdline "$cursor"
        clear
        render "$cursor"
        ;;
      *) : ;;
    esac
  done
  restore_tty
  clear
  echo "Leaving dashboard. Background processes keep running."
}

main
