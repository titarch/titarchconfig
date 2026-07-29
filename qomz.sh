#!/bin/sh
# qomz - quick familiar shell for throwaway remote VMs.
#   curl -L z.pyy.fr | sh
# Installs zsh + oh-my-zsh + starship + a couple comfort plugins and drops a
# small self-contained ~/.zshrc (the familiar git aliases/history/prompt).
# Everything is best-effort and non-destructive: an existing ~/.zshrc is backed
# up, missing tools are simply skipped. Nothing here assumes the full dotfiles.
set -u

info() { printf '\033[1;35m::\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }

# --- privilege + package manager ---
SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"
PM="" PMUP=""
if   command -v apt-get >/dev/null 2>&1; then PM="apt-get install -y"; PMUP="apt-get update"
elif command -v dnf     >/dev/null 2>&1; then PM="dnf install -y"
elif command -v pacman  >/dev/null 2>&1; then PM="pacman -S --noconfirm --needed"
elif command -v apk     >/dev/null 2>&1; then PM="apk add"
elif command -v zypper  >/dev/null 2>&1; then PM="zypper install -y"
elif command -v yum     >/dev/null 2>&1; then PM="yum install -y"
else warn "no known package manager - will use whatever is already installed"
fi
pkg() { [ -n "$PM" ] && $SUDO $PM "$1" >/dev/null 2>&1; }

# --- core deps ---
[ -n "$PMUP" ] && { info "refreshing package lists"; $SUDO $PMUP >/dev/null 2>&1 || true; }
for c in zsh git curl; do
  command -v "$c" >/dev/null 2>&1 || { info "installing $c"; pkg "$c" || warn "could not install $c"; }
done
command -v zsh >/dev/null 2>&1 || { warn "zsh is required and unavailable; aborting"; exit 1; }

# --- comfort tools (best effort; names differ per distro, failures ignored) ---
info "installing comfort tools (best effort)"
for t in eza fd fd-find ripgrep bat batcat zoxide fzf; do pkg "$t" || true; done

# --- starship (single binary, no root needed) ---
export PATH="$HOME/.local/bin:$PATH"
if ! command -v starship >/dev/null 2>&1; then
  info "installing starship prompt into ~/.local/bin"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1 \
    || warn "starship install skipped (prompt falls back to the omz theme)"
fi

# --- oh-my-zsh + plugins ---
export RUNZSH=no CHSH=no KEEP_ZSHRC=yes
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "installing oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1 \
    || warn "oh-my-zsh install had issues"
fi
ZC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone() { [ -d "$ZC/plugins/$1" ] || git clone -q --depth=1 "$2" "$ZC/plugins/$1" >/dev/null 2>&1; }
info "adding autosuggestions + syntax-highlighting"
clone zsh-autosuggestions     https://github.com/zsh-users/zsh-autosuggestions
clone zsh-syntax-highlighting  https://github.com/zsh-users/zsh-syntax-highlighting

# --- the familiar ~/.zshrc (backed up if one exists) ---
[ -f "$HOME/.zshrc" ] && cp "$HOME/.zshrc" "$HOME/.zshrc.qomz-bak" && info "backed up existing ~/.zshrc -> ~/.zshrc.qomz-bak"
info "writing ~/.zshrc"
cat > "$HOME/.zshrc" <<'ZRC'
# qomz remote shell -- lightweight, self-contained
export PATH="$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"                    # replaced by starship below if present
# syntax-highlighting must be last
plugins=(git docker kubectl zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# history: keep a lot, ignore space-prefixed, share across sessions
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=$HISTSIZE
setopt hist_ignore_space share_history extended_history hist_ignore_dups hist_reduce_blanks

export EDITOR="${EDITOR:-$(command -v nvim || command -v vim || echo vi)}"

# distro binary-name fixups (Debian ships fd as fdfind, bat as batcat)
command -v fdfind >/dev/null && alias fd='fdfind'
command -v batcat >/dev/null && alias bat='batcat'

# familiar aliases (omz git plugin already gives gst/gcmsg/gd/gco/gapa/gp/...)
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
command -v fd >/dev/null && alias f='fd'    # fd here resolves the fdfind alias too

# tool integrations, only when present
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v fzf      >/dev/null && { fzf --zsh 2>/dev/null | source /dev/stdin 2>/dev/null; }
command -v starship >/dev/null && eval "$(starship init zsh)"
ZRC

# --- make zsh the default shell ---
if command -v chsh >/dev/null 2>&1; then
  $SUDO chsh -s "$(command -v zsh)" "$(id -un)" >/dev/null 2>&1 \
    && info "default shell set to zsh" || warn "could not chsh; run 'chsh -s $(command -v zsh)' yourself"
fi

printf '\033[1;32m::\033[0m done. start your familiar shell now:  \033[1mexec zsh\033[0m\n'
