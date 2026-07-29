#!/bin/sh
# boot.sh - one bootstrap for every titarch setup. Pick a tier:
#   curl -fsSL z.pyy.fr | sh                    # interactive menu
#   curl -fsSL z.pyy.fr | sh -s -- quick        # throwaway VM: familiar shell, self-contained
#   curl -fsSL z.pyy.fr | sh -s -- headless     # permanent server: full terminal dotfiles, any distro
#   curl -fsSL z.pyy.fr | sh -s -- desktop      # full Arch + GUI, guided
# no curl? swap in:  wget -qO- z.pyy.fr | sh -s -- <tier>
set -u

REPO="https://github.com/titarch/titarchconfig.git"
SRC="${BOOT_SOURCE:-$REPO}"          # override (local path/repo) for testing

info() { printf '\033[1;35m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }

# --- pick tier: arg, else prompt on the terminal (stdin is the curl pipe) ---
tier="${1:-}"
if [ -z "$tier" ]; then
  if [ -r /dev/tty ]; then
    printf 'titarch bootstrap - choose a setup:\n'
    printf '  q) quick     throwaway VM: zsh + omz + starship, self-contained\n'
    printf '  h) headless  permanent server: full terminal dotfiles (any distro)\n'
    printf '  d) desktop   full Arch + graphical, guided\n> '
    read -r tier </dev/tty
  else
    warn "no terminal to prompt; pass a tier:  ... | sh -s -- quick|headless|desktop"; exit 1
  fi
fi
case "$tier" in
  q|quick)            tier=quick ;;
  h|headless|server)  tier=headless ;;
  d|desktop)          tier=desktop ;;
  *) warn "unknown tier '$tier' (want quick|headless|desktop)"; exit 1 ;;
esac

# --- shared: privilege + package manager ---
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"
PM="" PMUP=""
if   command -v apt-get >/dev/null 2>&1; then PM="apt-get install -y";              PMUP="apt-get update"
elif command -v dnf     >/dev/null 2>&1; then PM="dnf install -y"
elif command -v pacman  >/dev/null 2>&1; then PM="pacman -S --noconfirm --needed";  PMUP="pacman -Sy --noconfirm"
elif command -v apk     >/dev/null 2>&1; then PM="apk add";                         PMUP="apk update"
elif command -v zypper  >/dev/null 2>&1; then PM="zypper --non-interactive install"; PMUP="zypper --non-interactive refresh"
elif command -v yum     >/dev/null 2>&1; then PM="yum install -y"
else warn "no known package manager - using whatever is installed"
fi
pkg()     { [ -n "$PM" ] && $SUDO $PM "$1" >/dev/null 2>&1; }
refresh() { [ -n "$PMUP" ] && { info "refreshing package lists"; $SUDO $PMUP >/dev/null 2>&1 || true; }; }

need() {   # ensure listed commands exist (best effort), + TLS roots
  refresh
  for c in "$@"; do command -v "$c" >/dev/null 2>&1 || { info "installing $c"; pkg "$c" || warn "could not install $c"; }; done
  pkg ca-certificates || true
}

install_starship() {   # prefer the signed distro package; upstream installer only where absent/stale
  command -v starship >/dev/null 2>&1 && return 0
  pkg starship && command -v starship >/dev/null 2>&1 && { info "installed starship (pkg)"; return 0; }
  info "installing starship (upstream -> ~/.local/bin)"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1 || warn "starship skipped"
}

set_zsh_default() {
  command -v chsh >/dev/null 2>&1 || return 0
  $SUDO chsh -s "$(command -v zsh)" "$(id -un)" >/dev/null 2>&1 && info "default shell -> zsh" || warn "chsh skipped (set it yourself)"
}

install_omz() {   # idempotent; --unattended skips chsh + shell launch, keeps any existing ~/.zshrc
  export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "installing oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1 || warn "oh-my-zsh had issues"
  else info "updating oh-my-zsh"; git -C "$HOME/.oh-my-zsh" pull -q >/dev/null 2>&1 || true; fi
}

# ============================ QUICK ============================
do_quick() {
  need zsh git curl
  command -v zsh >/dev/null 2>&1 || { warn "zsh unavailable; aborting"; exit 1; }
  info "installing comfort tools (best effort)"
  for t in eza fd fd-find ripgrep bat batcat zoxide fzf; do pkg "$t" || true; done
  info "installing editor (neovim, else vim)"
  command -v nvim >/dev/null 2>&1 || pkg neovim || true
  command -v nvim >/dev/null 2>&1 || command -v vim >/dev/null 2>&1 || pkg vim || true
  export PATH="$HOME/.local/bin:$PATH"
  install_starship
  install_omz
  ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone() { if [ -d "$ZC/plugins/$1" ]; then git -C "$ZC/plugins/$1" pull -q >/dev/null 2>&1 || true; else git clone -q --depth=1 "$2" "$ZC/plugins/$1" >/dev/null 2>&1; fi; }
  info "adding autosuggestions + syntax-highlighting"
  clone zsh-autosuggestions    https://github.com/zsh-users/zsh-autosuggestions
  clone zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
  [ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.qomz-bak" && info "backed up existing ~/.zshrc"
  info "writing ~/.zshrc"
  cat > "$HOME/.zshrc" <<'ZRC'
# qomz remote shell -- lightweight, self-contained
export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"                    # replaced by starship below if present
plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
setopt hist_ignore_space share_history extended_history hist_ignore_dups hist_reduce_blanks

export EDITOR="${EDITOR:-$(command -v nvim || command -v vim || echo vi)}"
command -v nvim >/dev/null && alias vim='nvim'

command -v fdfind >/dev/null && alias fd='fdfind'
command -v batcat >/dev/null && alias bat='batcat'

alias ..='cd ..'
alias ...='cd ../..'
alias rm='rm -I'
alias grep='grep --color=auto'
alias ll='ls -lh'
alias la='ls -lah'
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --git --group-directories-first'
  alias la='eza -lah --git --group-directories-first'
fi
command -v fd >/dev/null && alias f='fd'

command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v fzf      >/dev/null && { fzf --zsh 2>/dev/null | source /dev/stdin 2>/dev/null; }
command -v starship >/dev/null && eval "$(starship init zsh)"
ZRC
  mkdir -p "$HOME/.cache/vim/undo" "$HOME/.config/nvim"
  [ -f "$HOME/.vimrc" ] && cp "$HOME/.vimrc" "$HOME/.vimrc.qomz-bak"
  info "writing editor config"
  cat > "$HOME/.vimrc" <<'VRC'
" qomz remote editor: plugin-free, comfortable defaults (nvim & vim)
set nocompatible
syntax on
filetype plugin indent on
set number
set mouse=a
set hidden
set backspace=indent,eol,start
set ignorecase smartcase
set incsearch hlsearch
set scrolloff=4
set expandtab shiftwidth=4 softtabstop=4
set autoindent
set wildmenu wildmode=longest:full,full
set laststatus=2 ruler
set clipboard=unnamedplus
set undofile undodir=~/.cache/vim/undo//
silent! set termguicolors
silent! colorscheme habamax
let mapleader=" "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>e :Explore<CR>
nnoremap <leader>h :nohlsearch<CR>
VRC
  printf 'source ~/.vimrc\n' > "$HOME/.config/nvim/init.vim"
  set_zsh_default
  printf '\033[1;32m::\033[0m quick setup done - exec zsh to start.\n'
  printf '   re-run to refresh; for a permanent box:  ... | sh -s -- headless\n'
}

# ============================ HEADLESS ============================
do_headless() {
  need zsh git curl
  info "installing terminal stack (best effort)"
  for t in neovim ripgrep fd fd-find bat batcat eza zoxide fzf lazygit git-delta direnv jq atuin; do pkg "$t" || true; done
  export PATH="$HOME/.local/bin:$PATH"
  install_starship
  if ! command -v zellij >/dev/null 2>&1; then pkg zellij || true; fi
  if ! command -v zellij >/dev/null 2>&1; then
    info "fetching zellij release binary (~/.local/bin)"
    curl -fsSL https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz 2>/dev/null \
      | tar -xz -C "$HOME/.local/bin" zellij 2>/dev/null || warn "zellij skipped"
  fi
  # prefer the signed distro package; upstream installer only where absent/stale (debian stable etc.)
  command -v chezmoi >/dev/null 2>&1 || { info "installing chezmoi (pkg)"; pkg chezmoi || true; }
  if ! command -v chezmoi >/dev/null 2>&1; then
    info "installing chezmoi (upstream -> ~/.local/bin)"
    sh -c "$(curl -fsSL get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null 2>&1 || warn "chezmoi install failed"
  fi
  command -v chezmoi >/dev/null 2>&1 || { warn "chezmoi required; aborting"; exit 1; }
  install_omz   # the deployed ~/.zshrc sources oh-my-zsh; it must exist first
  # pre-seed the config so chezmoi runs non-interactively (promptBoolOnce reads
  # these instead of demanding a TTY; --promptBool only feeds promptBool, not Once)
  mkdir -p "$HOME/.config/chezmoi"
  [ -f "$HOME/.config/chezmoi/chezmoi.toml" ] || cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'CFG'
[data]
    composeKey = "rwin"
    capsSwapEscape = false
    kittyFontSize = "15"
[data.features]
    streaming = false
    nvidia = false
    fancyFx = false
    work = false
    headless = true
[data.work]
    ecrRegistry = ""
    acrRegistry = ""
    email = ""
CFG
  info "deploying dotfiles (headless profile) from $SRC"
  # init (not bare apply): promptBoolOnce reads the pre-seeded [data] so it never
  # prompts, and init records the config-template hash -> no "config changed"
  # warning on later apply/config-sync. URL is cloned by chezmoi to its default source.
  if [ -d "$SRC" ]; then
    chezmoi init --apply --source "$SRC" || { warn "chezmoi init failed"; exit 1; }
  else
    chezmoi init --apply "$SRC" || { warn "chezmoi init failed"; exit 1; }
  fi
  # full custom-plugin set the deployed zshrc expects (single source of truth;
  # run via sh so it works where bash is absent, e.g. alpine)
  if [ -f "$HOME/.local/bin/zsh-plugins-setup" ]; then
    info "installing zsh plugins"; sh "$HOME/.local/bin/zsh-plugins-setup" >/dev/null 2>&1 || warn "zsh-plugins-setup had issues"
  fi
  if command -v nvim >/dev/null 2>&1; then info "bootstrapping neovim plugins"; nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true; fi
  set_zsh_default
  printf '\033[1;32m::\033[0m headless setup done - exec zsh to start.\n'
  printf '   zj = persistent zellij session; re-run with:  ~/.local/bin/config-sync\n'
}

# ============================ DESKTOP ============================
do_desktop() {
  command -v pacman >/dev/null 2>&1 || { warn "the desktop tier targets Arch Linux (needs pacman)"; exit 1; }
  need git
  if [ -d "$HOME/titarchconfig/.git" ]; then
    info "updating existing ~/titarchconfig"; git -C "$HOME/titarchconfig" pull --ff-only || true
  else
    info "cloning dotfiles -> ~/titarchconfig"; git clone "$REPO" "$HOME/titarchconfig" || { warn "clone failed"; exit 1; }
  fi
  info "launching the guided installer (answer its prompts)"
  cd "$HOME/titarchconfig" && ./install.sh </dev/tty
}

do_"$tier"
