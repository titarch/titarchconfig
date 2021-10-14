export PATH=$PATH:$HOME/.local/bin:$HOME/.cabal/bin:$HOME/.ghcup/bin
pasystray &
eval `ssh-agent`
systemctl --user import-environment DISPLAY
xrdb -merge .Xresources && exec i3
