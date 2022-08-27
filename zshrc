# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="dracula"

# CASE_SENSITIVE="true"
# HYPHEN_INSENSITIVE="true"
# DISABLE_AUTO_UPDATE="true"
# DISABLE_UPDATE_PROMPT="true"
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(cp git docker pip python sudo z systemd autoswitch_virtualenv zsh-syntax-highlighting zsh-completions zsh-autosuggestions kubectl aws minikube history web-search enhancd zsh-kubectl-prompt terraform terragrunt)

source $ZSH/oh-my-zsh.sh

autoload -Uz compinit
compinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# User configuration

export EDITOR='vim'

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.

makewatch() {
    [[ -n "$1" ]] && texfile="$1" || texfile=(*.tex(N[1]))
    echo "Selected file: $texfile"
    while true; do inotifywait -e modify "$texfile"; date; make; done
}

alias rm='rm -I'
alias grep='grep --color -n'
alias i3lock='i3lock -c 420042'
alias p='vim -p'
alias f='find -name'
alias ccw='g++ -Wall -Werror -Wextra -pedantic -std=c++20'
alias ccgdb='ccw -g'
alias ccasan='ccgdb -fsanitize=address -lasan'
alias fr='setxkbmap -option compose:menu'
export PGDATA="$HOME/postgres_data"
export PGHOST="/tmp"
alias pgrun='postgres -k "$PGHOST"'
alias eb='vim ~/.zshrc'
alias ei='vim ~/.config/i3/config'
alias sb='source ~/.zshrc'
alias ebh='vim ~/.zsh_history'
alias psh='pipenv shell'
alias goodbye='systemctl poweroff'
eval $(thefuck --alias)
alias newalias='/home/bparsy/Scripts/newalias.sh'
alias jn='jupyter notebook'
alias makj='make -j8'
alias nj='ninja'
alias cnj='cmake -G "Ninja"'
alias cnjd='cnj -DCMAKE_BUILD_TYPE=Debug'
alias cnjr='cnj -DCMAKE_BUILD_TYPE=Release'
alias x='startx'
