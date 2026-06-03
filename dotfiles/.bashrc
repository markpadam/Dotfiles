# ~/.bashrc

# load user environment and helpers
if [ -f "$HOME/.bash_exports" ]; then
    source "$HOME/.bash_exports"
fi
if [ -f "$HOME/.bash_aliases" ]; then
    source "$HOME/.bash_aliases"
fi
if [ -f "$HOME/.bash_functions" ]; then
    source "$HOME/.bash_functions"
fi

# Only run interactive shell settings for interactive shells.
if [[ $- == *i* ]]; then
    export PS1='\u@\h:\w$ '
    shopt -s histappend
    HISTCONTROL=ignoredups:erasedups
    HISTSIZE=10000
    HISTFILESIZE=20000
    bind 'set enable-bracketed-paste off'
fi
