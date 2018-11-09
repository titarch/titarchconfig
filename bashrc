# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [ -d ~/afs/bin ] ; then
	export PATH=~/afs/bin:$PATH
fi

if [ -d ~/.local/bin ] ; then
	export PATH=~/.local/bin:$PATH
fi

export LANG=en_US.utf8
export NNTPSERVER="news.epita.fr"

export EDITOR=vim
#export EDITOR=emacs

# Color support for less
#export LESS_TERMCAP_mb=$'\E[01;31m'       # begin blinking
#export LESS_TERMCAP_md=$'\E[01;38;5;74m'  # begin bold
#export LESS_TERMCAP_me=$'\E[0m'           # end mode
#export LESS_TERMCAP_se=$'\E[0m'           # end standout-mode
#export LESS_TERMCAP_so=$'\E[38;5;246m'    # begin standout-mode - info box
#export LESS_TERMCAP_ue=$'\E[0m'           # end underline
#export LESS_TERMCAP_us=$'\E[04;38;5;146m' # begin underline

alias ls='ls --color=auto'
alias grep='grep --color -n'
#PS1='[\u@\h \W]\$ '
export PS1="\[$(tput bold)\]\[\033[38;5;161m\][\[$(tput sgr0)\]\[\033[38;5;141m\]\u\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;219m\]\w\[$(tput sgr0)\]\[\033[38;5;161m\]]\[$(tput sgr0)\]\[\033[38;5;49m\]\\$\[$(tput sgr0)\] "
alias i3lock='i3lock -i /home/baptiste.parsy/afs/.confs/config/i3/backgound.png'

alias sb='source /home/baptiste.parsy/.bashrc'

#MAKE
alias mcmake='/home/baptiste.parsy/afs/utils/cmake.sh'
alias cake='/home/baptiste.parsy/afs/utils/cmake.sh .; make'
alias ccake='/home/baptiste.parsy/afs/utils/cmake.sh .; make -B'
alias mcake='make -B'
alias mcl='make clean'
alias comp='/home/baptiste.parsy/afs/utils/comp.sh'
alias compt='/home/baptiste.parsy/afs/utils/comp.sh test test.c'
alias mdb='make debug'
alias mgdb='make gdb'
alias mt='make test'
alias mck='make check'
alias kdb='make -B debug'
alias kgdb='make -B gdb'
alias kt='make -B test'
alias kck='make -B check'

#VIM
alias v='vim'
alias p='vim -p'
alias r='vim -'

#OTHER

alias f='find -name'
alias g='grep -r'
