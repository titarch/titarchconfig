#!/bin/bash
# remove relics of the pre-2026 x11/i3 setup, idempotent, safe on fresh installs
set -u

echo "== packages"
for p in i3-wm i3blocks i3status xorg-xinit pasystray arandr lxappearance \
         flameshot dunst picom compton nitrogen greenclip urxvt rxvt-unicode; do
    if pacman -Q "$p" >/dev/null 2>&1; then
        read -p "Remove $p? " -n 1 -r; echo
        [[ $REPLY =~ ^[Yy]$ ]] && sudo pacman -Rns "$p"
    fi
done

echo "== pipx tools"
if command -v pipx >/dev/null && pipx list 2>/dev/null | grep -q nvx; then
    pipx uninstall nvx
fi

echo "== /etc relics"
for f in /etc/X11/xorg.conf /etc/X11/Xwrapper.config \
         /etc/X11/xorg.conf.d/30-sunshine-keyboard.conf; do
    [ -f "$f" ] && sudo rm -v "$f"
done
[ -d /etc/X11/edid ] && sudo rm -rv /etc/X11/edid
ls /etc/X11/xorg.conf.bak.* >/dev/null 2>&1 && sudo rm -v /etc/X11/xorg.conf.bak.*

echo "== home relics"
for f in ~/.xinitrc ~/.Xresources ~/.zshrc.wasmedge_backup ~/.zshrc.backup; do
    [ -e "$f" ] && rm -v "$f"
done
for d in ~/.config/i3 ~/.config/i3blocks ~/.config/rofi ~/.config/nvx ~/.config/dunst; do
    [ -d "$d" ] && rm -rv "$d"
done
[ -e ~/.local/bin/nvinit ] && rm -v ~/.local/bin/nvinit

echo "done"
