export DEFAULT_USER=axemclion

export HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
HISTDUP=erase

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

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward


#general
alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias cp='cp -i'

function rm () {
  local path
  for path in "$@"; do
    # ignore any arguments
    if [[ "$path" = -* ]]; then :
    else
      local dst=${path##*/}
      # append the time if necessary
      while [ -e ~/.Trash/"$dst" ]; do
        dst="$dst "$(/bin/date +%H-%M-%S)
      done
      /bin/mv "$path" ~/.Trash/"$dst"
    fi
  done
}

#ruby
export GEM_HOME=~/.gem
export GEM_PATH=~/.gem
export PATH=$PATH:~/.gem/bin

# node
export NVM_DIR="$HOME/.nvm"
function nvm-init() {
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
}
export PATH=$PATH:~/.npm/global/bin
export PATH=$PATH:./node_modules/.bin

# iOS
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

# android
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_181.jdk/Contents/Home
export ANDROID_SDK=/opt/android_sdk
export ANDROID_NDK_REPOSITORY=/opt/android_ndk
export ANDROID_HOME=${ANDROID_SDK}
export PATH=${PATH}:${ANDROID_SDK}/tools:${ANDROID_SDK}/tools/bin:${ANDROID_SDK}/platform-tools

# adb
function adball()
{
    adb devices | egrep '\t(device|emulator)' | cut -f 1 | xargs -t -J% -n1 -P5 \
          adb -s % "$@"
}
alias adb_mirror='adb exec-out screenrecord --output-format=h264 - | ffplay -framerate 60 -probesize 32 -vf crop=1400:1500:10:10 -sync video -'
export PATH="/usr/local/sbin:$PATH"

source ~/.zsh-utils/zsh-autosuggestions/zsh-autosuggestions.zsh
PROMPT='%B%(?..%F{red}[%?] ✘ )%F{yellow}%K{black}%(!.⚡.)%F{white}%K{blue} %~ %K{default}%F{blue}▶%F{default}%K{default}%b '
RPROMPT="%K{green} %n@%M %K{default}"

# oculus
alias oc_cast='adb shell am startservice -n com.oculus.horizon/com.oculus.horizon.service_media.OVRMediaService --es message_type com.oculus.horizon.START_LOCAL_STREAM --ez cast_option_www true'
alias oc_on='adb shell am broadcast -a com.oculus.vrpowermanager.prox_close'
alias oc_type='adb shell am broadcast -a com.oculus.vrshell.intent.action.SEND_KEYS -n com.oculus.vrshell/.ShellControlBroadcastReceiver -e input_type "text" -e input_keys "$1"'

function oc_pass() {
  adb root
  read -s oculus_input_password
  R = $(adb shell am broadcast -a com.oculus.vrshell.intent.action.SEND_KEYS -n com.oculus.vrshell/.ShellControlBroadcastReceiver -e input_type "text" -e input_keys "$oculus_input_password")
  unset oculus_input_password
}
