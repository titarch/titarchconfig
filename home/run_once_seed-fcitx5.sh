#!/bin/sh
# seed fcitx5 once, fcitx owns and rewrites these files afterwards
d="$HOME/.config/fcitx5"
mkdir -p "$d"
[ -f "$d/config" ] || cat > "$d/config" <<'EOF'
[Hotkey/TriggerKeys]
0=Super+space

[Hotkey]
EnumerateWithTriggerKeys=True
EOF
[ -f "$d/profile" ] || cat > "$d/profile" <<'EOF'
[Groups/0]
Name=Default
Default Layout=fr-us
DefaultIM=keyboard-fr-us

[Groups/0/Items/0]
Name=keyboard-fr-us

[Groups/0/Items/1]
Name=mozc

[GroupOrder]
0=Default
EOF
