#!/bin/bash
# root-owned system files, per-section prompts, run: sudo system/install-system.sh
set -eu
cd "$(dirname "$0")"

read -p "uinput udev rule (sunshine host, also needed by ydotool/presence)? " -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    install -m644 sunshine/61-sunshine-uinput.rules /etc/udev/rules.d/61-sunshine-uinput.rules
    udevadm control --reload
fi

# monitor rules only match grodarch connectors, no-ops elsewhere; also gives
# the greeter hypridle (1min dpms) and no anime girl. dms greeter sync/install
# rewrites config.toml and drops the -C flag, rerun this if it regresses
if [ -d /etc/greetd ]; then
    read -p "greeter extras (monitor layout, 1min screen-off)? " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install -m644 greetd/dms-greeter-hypr.conf /etc/greetd/dms-greeter-hypr.conf
        install -m644 greetd/hypridle-greeter.conf /etc/greetd/hypridle-greeter.conf
        grep -q 'dms-greeter-hypr.conf' /etc/greetd/config.toml 2>/dev/null \
            || sed -i 's|--command hyprland|--command hyprland -C /etc/greetd/dms-greeter-hypr.conf|' /etc/greetd/config.toml
    fi
fi

if [ -d /usr/lib/firefox ]; then
    read -p "firefox tab-scroll fix (autoconfig + pacman hook)? " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install -m644 firefox/config.js /usr/lib/firefox/config.js
        install -m644 firefox/config-prefs.js /usr/lib/firefox/defaults/pref/config-prefs.js
        # hook regenerated with this repo's actual path
        sed "s|/home/bparsy/titarchconfig|$(cd .. && pwd)|g" firefox/firefox-autoconfig.hook \
            | install -Dm644 /dev/stdin /etc/pacman.d/hooks/firefox-autoconfig.hook
    fi
fi

if command -v nix >/dev/null 2>&1 || [ -e /etc/profile.d/nix-daemon.sh ]; then
    # the nix package rewrites /etc/profile.d/nix-daemon.sh on every update,
    # re-adding the global ~/.nix-profile/bin PATH prepend. NoExtract tells
    # pacman to never write that file again; zshenv sets the nix env we want.
    read -p "nix: stop pacman restoring the global PATH prepend on updates? " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        grep -q 'etc/profile.d/nix-daemon.sh' /etc/pacman.conf \
            || sed -i '/^\[options\]/a NoExtract = etc/profile.d/nix-daemon.sh' /etc/pacman.conf
    fi
fi

echo "done"
