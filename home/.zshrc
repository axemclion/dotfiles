# Path to your oh-my-zsh installation.
export ZSH=/Users/axemclion/.oh-my-zsh
export DEFAULT_USER=axemclion

ZSH_THEME="agnoster"
plugins=(git node npm osx)

# User configuration

export ANDROID_HOME=~/_workspace/_software/android-sdk-macosx

export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/_workspace/_software/ant/bin

alias subl="open -a /Applications/Sublime\ Text.app"

source ~/.zsh-util/agnoster.zsh-theme
source ~/.zsh-util/git.zsh


alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'
alias rm='rm -rf'
alias cp='cp -i'
alias mv='mv -i'
