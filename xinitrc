export PATH=$PATH:$HOME/.local/bin:$HOME/.cabal/bin:$HOME/.ghcup/bin:$HOME/.npm-global/bin:$HOME/.cargo/bin
pasystray &
eval `ssh-agent`
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export GTK_IM_MODULE=ibus
export GTK_THEME=Dracula
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
systemctl --user import-environment DISPLAY XAUTHORITY
# restart (not start): a stale instance must pick up the fresh X auth cookie
systemctl --user restart app-dev.lizardbyte.app.Sunshine.service
# X defaults primary to the (inactive) virtual HDMI-0, which breaks Sunshine's
# display indexing (output_name); the middle monitor is the real primary
xrandr --output DP-4 --primary
xrdb -merge .Xresources && exec i3
