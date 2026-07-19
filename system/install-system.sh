#!/bin/sh
# root-owned system files, idempotent, run: sudo system/install-system.sh
set -eu
cd "$(dirname "$0")"

# sunshine virtual input devices (also gives ydotool /dev/uinput access)
install -m644 sunshine/61-sunshine-uinput.rules /etc/udev/rules.d/61-sunshine-uinput.rules
udevadm control --reload

# greeter monitor layout; dms greeter sync/install rewrites config.toml and
# drops the -C flag, rerun this script if greeter monitor order regresses
if [ -d /etc/greetd ]; then
    install -m644 greetd/dms-greeter-hypr.conf /etc/greetd/dms-greeter-hypr.conf
    install -m644 greetd/hypridle-greeter.conf /etc/greetd/hypridle-greeter.conf
    grep -q 'dms-greeter-hypr.conf' /etc/greetd/config.toml 2>/dev/null \
        || sed -i 's|--command hyprland|--command hyprland -C /etc/greetd/dms-greeter-hypr.conf|' /etc/greetd/config.toml
fi

# firefox autoconfig (tab wheel fix), pacman hook survives firefox upgrades
if [ -d /usr/lib/firefox ]; then
    install -m644 firefox/config.js /usr/lib/firefox/config.js
    install -m644 firefox/config-prefs.js /usr/lib/firefox/defaults/pref/config-prefs.js
    install -Dm644 firefox/firefox-autoconfig.hook /etc/pacman.d/hooks/firefox-autoconfig.hook
fi

echo "system files installed"
