#!/bin/sh
# Root-owned system files for the Sunshine/X11 streaming setup (grodarch).
# Run as root from the repo root: sudo system/install-system.sh
#
# Idempotent. After this has been run once, the untracked compat copies in
# ./sunshine/ (EDIDs at the path the pre-2026 xorg.conf referenced) can be
# deleted — this script removes them itself when the new xorg.conf is in.
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

# old in-repo EDID path no longer referenced -> drop the compat copies
rm -rf ../sunshine

echo "system files installed; xorg.conf now reads EDIDs from /etc/X11/edid/"
