export PATH=$PATH:$HOME/.local/bin:$HOME/.cabal/bin:$HOME/.ghcup/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin
pasystray &
eval `ssh-agent`
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
systemctl --user import-environment DISPLAY
xrdb -merge .Xresources && exec i3
