export ZSH=/Users/axemclion/.oh-my-zsh
export DEFAULT_USER=axemclion

ZSH_THEME="agnoster"

plugins=(git)

source $ZSH/oh-my-zsh.sh

export ANDROID_HOME=~/_workspace/_software/android-sdk-macosx

export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/_workspace/_software/ant/bin

alias subl="open -a /Applications/Sublime\ Text.app"

alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias rm='rm -rf'
alias cp='cp -i'
alias mv='mv -i'
