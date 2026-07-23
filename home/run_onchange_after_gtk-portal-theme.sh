#!/bin/sh
# xdg-desktop-portal-gtk advertises the theme to dbus-activated apps (Thunar
# daemon, keyring/polkit prompters) that never see the session GTK_THEME env,
# reading it from gsettings. Without this they fall back to Adwaita (light).
# Needs a session dbus, so skip cleanly when applying over ssh.
command -v gsettings >/dev/null 2>&1 || exit 0
gsettings set org.gnome.desktop.interface gtk-theme    'Dracula'      2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'  2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme   'Papirus-Dark' 2>/dev/null || true
