#!/bin/sh
# root-owned sunshine/x11 files, idempotent, run: sudo system/install-system.sh
set -eu
cd "$(dirname "$0")"

install -Dm644 sunshine/virtual-edid.bin /etc/X11/edid/virtual-edid.bin
install -Dm644 sunshine/vg27a-edid.bin   /etc/X11/edid/vg27a-edid.bin

[ -f /etc/X11/xorg.conf ] && cp /etc/X11/xorg.conf "/etc/X11/xorg.conf.bak.$(date +%Y%m%d%H%M%S)"
install -m644 sunshine/xorg.conf          /etc/X11/xorg.conf
install -m644 sunshine/Xwrapper.config    /etc/X11/Xwrapper.config
install -Dm644 sunshine/30-sunshine-keyboard.conf /etc/X11/xorg.conf.d/30-sunshine-keyboard.conf
install -m644 sunshine/61-sunshine-uinput.rules   /etc/udev/rules.d/61-sunshine-uinput.rules
udevadm control --reload

# old in-repo EDID compat copies no longer needed
rm -rf ../sunshine

echo "system files installed; xorg.conf now reads EDIDs from /etc/X11/edid/"
