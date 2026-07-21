#!/bin/sh
# enable the zsh history backup timer. needs the user systemd bus, so it skips
# quietly when applying without a session (e.g. over ssh).
systemctl --user daemon-reload 2>/dev/null || exit 0
systemctl --user enable --now zsh-history-backup.timer >/dev/null 2>&1 || true
