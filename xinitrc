eval `ssh-agent`
xrdb -merge .Xresources && exec i3
