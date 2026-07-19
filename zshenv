# Read by every zsh (login, interactive, and non-interactive — including
# one-shot `ssh host <command>`), unlike .zshrc.
# ~/.local/bin must come FIRST: imagemagick owns /usr/bin/stream, which
# would otherwise shadow the streaming toggle script.
export PATH="$HOME/.local/bin:$PATH"
