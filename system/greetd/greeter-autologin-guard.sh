#!/bin/sh
# greetd-dms-greeter-bin upgrades relink the greeter config symlinks to /root
# (root's DMS config is {} -> greeterAutoLogin reads false -> autologin gate
# shuts -> launch-session FATALs "auto-login is disabled") and can strip
# [initial_session] from config.toml. Re-point the cache symlinks to bparsy and
# restore the autologin config. Run by the greeter-autologin.hook after each
# upgrade, and once by install-system.sh. Self-gates on greeterAutoLogin true,
# so a box without autologin (thinkpad) no-ops.
set -eu
U=bparsy
H="/home/$U"
CACHE=/var/cache/dms-greeter
CFG=/etc/greetd/config.toml
SET="$H/.config/DankMaterialShell/settings.json"

[ -d "$CACHE" ] || exit 0
grep -q '"greeterAutoLogin"[[:space:]]*:[[:space:]]*true' "$SET" 2>/dev/null || exit 0

# gate = greeterAutoLogin read through this symlink; must be bparsy, not /root
ln -sfn "$SET"                                            "$CACHE/settings.json"
ln -sfn "$H/.local/state/DankMaterialShell/session.json" "$CACHE/session.json"
ln -sfn "$H/.cache/DankMaterialShell/dms-colors.json"    "$CACHE/colors.json"

grep -q '^\[initial_session\]' "$CFG" 2>/dev/null \
    || install -m644 /etc/greetd/config.toml.autologin "$CFG"

echo "greeter-autologin-guard: relinked greeter config to $H, autologin ensured"
