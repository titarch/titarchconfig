export PATH=$PATH:~/.local/bin
eval `ssh-agent`
systemctl --user import-environment DISPLAY
xrdb -merge .Xresources && exec i3
