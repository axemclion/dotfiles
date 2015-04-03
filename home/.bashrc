#work specific
export workspace="~/Documents/workspace"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias ll='ls -l'
alias la='ls -A'
alias ls='ls -GaFt'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias root='sudo su'

export ANDROID_HOME=~/_workspace/_software/android-sdk-macosx

export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export PATH=$PATH:~/_workspace/_software/ant/bin

export PS1="\[\033[0;32m\][\w]\[\033[0m\]\[\033[01;34m\]$\[\033[00m\] "
