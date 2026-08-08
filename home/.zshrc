# Axe's zshrc
HISTSIZE=5000
SAVEHIST=5000
HISTDUP=erase

# Prompts
FG_PATH='black' # white black
BG_PATH='blue'  # cyan  blue
PROMPT="%B%(?..%F{red}[%?] ✘ )%F{yellow}%K{black}%(!.⚡.)%F{${FG_PATH}}%K{${BG_PATH}} %~ %K{default}%F{${BG_PATH}}▶%F{default}%K{default}%b "

FG_RPROMPT='black'
BG_RPROMPT='green' # cyan  green

RPROMPT="%${${FG_RPROMPT:+F{${FG_RPROMPT}}}}%K{${BG_RPROMPT}} %n@%M %K{default}"

# Specific to zsh

if [[ -n "$ZSH_VERSION" ]]; then
  export HISTFILE=~/.zsh_history

  setopt appendhistory
  setopt sharehistory
  setopt incappendhistory

  setopt APPEND_HISTORY
  setopt SHARE_HISTORY
  setopt INC_APPEND_HISTORY
  setopt HIST_EXPIRE_DUPS_FIRST

  setopt HIST_IGNORE_DUPS
  setopt HIST_FIND_NO_DUPS
  setopt HIST_REDUCE_BLANKS

  setopt HIST_IGNORE_DUPS
  setopt HIST_FIND_NO_DUPS

  
  bindkey "^[[A" history-search-backward
  bindkey "^[[B" history-search-forward

  # macOS Native Standard: Option + Arrows to skip words
  bindkey '^[[1;3D' backward-word       # Option + Left
  bindkey '^[[1;3C' forward-word        # Option + Right

  # macOS Native Standard: Command + Arrows to jump to start/end of line
  bindkey '^[[1;9D' beginning-of-line   # Command + Left
  bindkey '^[[1;9C' end-of-line         # Command + Right

fi

alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias cp='cp -i'

export PATH="/usr/local/sbin:$PATH"

# node
export PATH=$PATH:~/.npm/global/bin
export PATH=$PATH:./node_modules/.bin

#ruby
export GEM_HOME=~/.gem
export GEM_PATH=~/.gem
export PATH=$PATH:~/.gem/bin

# Homebrew
export PATH="$HOME/homebrew/bin:$HOME/homebrew/sbin:$PATH"


# JAVA
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-24.0.1.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# android
export ANDROID_SDK=/opt/android_sdk
export ANDROID_NDK_REPOSITORY=/opt/android_ndk
export ANDROID_HOME=${ANDROID_SDK}
export PATH=${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools:${PATH}

# adb
function adball()
{
    adb devices | egrep '\t(device|emulator)' | cut -f 1 | xargs -t -J% -n1 -P5 \
          adb -s % "$@"
}
alias adb_mirror='adb exec-out screenrecord --output-format=h264 - | ffplay -framerate 60 -probesize 32 -vf crop=1400:1500:10:10 -sync video -'

# oculus
alias oc_cast='adb shell am startservice -n com.oculus.horizon/com.oculus.horizon.service_media.OVRMediaService --es message_type com.oculus.horizon.START_LOCAL_STREAM --ez cast_option_www true'
alias oc_on='adb shell am broadcast -a com.oculus.vrpowermanager.prox_close'
alias oc_type='adb shell am broadcast -a com.oculus.vrshell.intent.action.SEND_KEYS -n com.oculus.vrshell/.ShellControlBroadcastReceiver -e input_type "text" -e input_keys "$1"'

# iOS
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'


# Trash RM
if [[ "$OSTYPE" == "darwin"* ]]; then
  TRASH=~/.Trash
  function rm () {
    local path
    for path in "$@"; do
      if [[ "$path" = -* ]]; then :
      else
        local dst=${path##*/}
        while [ -e "$TRASH"/"$dst" ]; do
          dst="$dst "$(/bin/date +%H-%M-%S)
        done
        /bin/mv "$path" "$TRASH"/"$dst"
      fi
    done
  }
fi
