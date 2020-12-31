export PATH=$PATH:~/.local/bin
pasystray &
eval `ssh-agent`
systemctl --user import-environment DISPLAY
xrdb -merge .Xresources

session=${1:-i3}

case $session in
    i3|i3wm           ) exec i3;;
    xfce|xfce4        ) exec startxfce4;;
    # No known session, try to run it as command
    *                 ) exec $1;;
esac
