export ZSH=/Users/axemclion/.oh-my-zsh
export DEFAULT_USER=axemclion

ZSH_THEME="agnoster"

plugins=(git)

source $ZSH/oh-my-zsh.sh

export ANDROID_HOME=~/_workspace/_software/android-sdk-macosx
export JAVA_HOME="$(/usr/libexec/java_home)"

export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/_workspace/_software/npm/node_modules/bin
export PATH=$PATH:./node_modules/.bin

export GEM_HOME=~/.gem
export GEM_PATH=~/.gem

alias subl="open -a /Applications/Sublime\ Text.app"

alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias rm='rm -rf'
alias cp='cp -i'
alias mv='mv -i'

cd ~/_workspace

function adball()
{
    adb devices | egrep '\t(device|emulator)' | cut -f 1 | xargs -t -J% -n1 -P5 \
          adb -s % "$@"
}
