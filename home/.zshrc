export ZSH=/Users/axemclion/.oh-my-zsh
export DEFAULT_USER=axemclion

ZSH_THEME="agnoster"


source $ZSH/oh-my-zsh.sh

export ANDROID_HOME=~/_workspace/_software/android-sdk-macosx
export JAVA_HOME="$(/usr/libexec/java_home)"

export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/_workspace/_software/npm/node_modules/bin
export PATH=$PATH:./node_modules/.bin
export PATH=$PATH:~/.gem/bin

export GEM_HOME=~/.gem
export GEM_PATH=~/.gem

alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias cp='cp -i'
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

cd ~/_workspace

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

function adball()
{
    adb devices | egrep '\t(device|emulator)' | cut -f 1 | xargs -t -J% -n1 -P5 \
          adb -s % "$@"
}
