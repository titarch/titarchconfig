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
    read -p "greeter extras (monitor layout, 1min screen-off, autologin guard)? " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install -m644 greetd/dms-greeter-hypr.conf /etc/greetd/dms-greeter-hypr.conf
        install -m644 greetd/hypridle-greeter.conf /etc/greetd/hypridle-greeter.conf
        grep -q 'dms-greeter-hypr.conf' /etc/greetd/config.toml 2>/dev/null \
            || sed -i 's|--command hyprland|--command hyprland -C /etc/greetd/dms-greeter-hypr.conf|' /etc/greetd/config.toml
        # autologin guard: greetd-dms-greeter-bin upgrades relink the greeter
        # config to /root (greeterAutoLogin reads false -> autologin gate shuts)
        # and can strip [initial_session]. hook re-points symlinks + restores
        # config after each upgrade. guard self-gates on greeterAutoLogin, so
        # deploying on a no-autologin box is a no-op. run it now to apply.
        install -m644 greetd/config.toml /etc/greetd/config.toml.autologin
        install -m755 greetd/greeter-autologin-guard.sh /etc/greetd/greeter-autologin-guard.sh
        install -Dm644 greetd/greeter-autologin.hook /etc/pacman.d/hooks/greeter-autologin.hook
        /etc/greetd/greeter-autologin-guard.sh || true
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

# CPU package power (RAPL energy_uj) is root-only since PLATYPUS. The kraken/
# cpu-power dms widget reads it as group powermon. Membership needs a re-login.
if [ -d /sys/class/powercap/intel-rapl:0 ]; then
    read -p "rapl power access for the cooling widget (powermon group + tmpfiles)? " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        getent group powermon >/dev/null || groupadd powermon
        u=${SUDO_USER:-$USER}
        id -nG "$u" | grep -qw powermon || gpasswd -a "$u" powermon
        install -Dm644 powercap/powercap-rapl.conf /etc/tmpfiles.d/powercap-rapl.conf
        systemd-tmpfiles --create /etc/tmpfiles.d/powercap-rapl.conf
    fi
fi

echo "done"
