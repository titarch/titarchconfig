# titarchconfig

Chezmoi source repo for Baptiste's Arch machines. Hyprland + DankMaterialShell
(DMS), Dracula everywhere, keyboard-first (i3 muscle memory).

## Workflow rules
- Edit files under `home/`, then `chezmoi apply`. Never edit deployed files in
  `$HOME` directly; if it happened, `chezmoi re-add <target>`. Drift shown by
  `chezmoi status` is actionable, not normal.
- Never run pacman/yay directly; give the user the command to run.

## Layout
- `home/` chezmoi source (`.chezmoiroot`), chezmoi name encoding
  (`dot_`, `executable_`, `.tmpl`, `create_`, `run_once_`).
- `system/` root-owned files, deployed by `sudo system/install-system.sh`
  (interactive sections: uinput rule, greeter extras, firefox fix).
- `install.sh` guided new-machine setup; `cleanup-x11.sh` removes i3-era
  relics; `_legacy/` untracked graveyard.
- `windows/` standalone PowerShell parity (NOT chezmoi-managed): `setup.ps1`
  (winget tools + PSFzf/PSReadLine + deploy), `Microsoft.PowerShell_profile.ps1`
  (zoxide/fzf/eza/starship/atuin, mirrors zshrc), static `starship.toml`
  (Dracula render of the templated one). For rare Windows-native work; WSL2 +
  `boot.sh headless` is the fuller option.
- Per-machine data: `~/.config/chezmoi/chezmoi.toml` from
  `home/.chezmoi.toml.tmpl` prompts: features.streaming/nvidia/fancyFx,
  composeKey, capsSwapEscape. Per-host monitor tables in
  `home/.chezmoidata.toml` (template lookup by hostname).

## Machines
- grodarch: desktop, RTX 4080 (nvidia flag on), 3x 2560x1440@144
  (DP-2 left, DP-3 mid, DP-1 right), sunshine streaming host, greetd
  autologin + lock-on-boot, caps2esc system service handles caps/esc
  (do NOT add xkb swap here), compose rwin.
- thinkpad: intel iris xe (fancyFx off), fr-us keyboard with compose prsc,
  capsSwapEscape via xkb, moonlight client, no autologin.
- tinasx: NixOS home server (zfs tank, docker), headless fleet member. NOT
  managed by pacman/install.sh: toolchain is declared in `nix/fleet-headless.nix`
  (imported into /etc/nixos/configuration.nix via fetchGit) + `nixos-rebuild`;
  dotfiles via `boot.sh headless`, which detects NixOS (/etc/NIXOS) and deploys
  the chezmoi headless profile only (no PM/curl-binary/chsh). Tools = Nix,
  config = chezmoi. Do not hand-edit /etc/nixos in this repo (root-owned there).

## Key components
- `home/dot_config/hypr/hyprland.conf.tmpl`: i3 keybind port. Workspace
  binds 2-12/14-24 live in `binds-workspaces.conf` (sourced) ON PURPOSE:
  the DMS keybind cheatsheet (mod+F1) only parses the main file.
- `stream` (dot_local/bin): sunshine away mode. Persistent parked headless
  output (20000x20000, named ws stream-park) so sunshine wlr capture always
  sees it; monitor switching writes `~/.config/hypr/monitors-runtime.conf`
  + `hyprctl reload`. Never restart sunshine from its own prep-cmd.
- `presence`: idle inhibit + ydotool jiggler (mod+P). `cursor-drift`:
  catppuccin cursor accent rotation. `config-sync`: non-interactive pull +
  apply + dms refresh (calls dms-bar-setup / dms-plugins-setup), the normal
  way to sync a machine.
- DMS plugins in `home/dot_config/DankMaterialShell/plugins/`: netspeed is
  homegrown (fixed-width rates + vpn toggle popout); registry plugins are
  installed by dms-plugins-setup (list lives in that script).
- Firefox tab-scroll fix: autoconfig in `system/firefox/` + pacman hook
  (accumulates hi-res wheel deltas; stock handler switches per event).

## Hard-won gotchas
- Hyprland (0.55): `hyprctl keyword monitor` and wlr-output-management are
  silently ignored at runtime. Working mechanism: write rules to a sourced
  file, then `hyprctl reload`. ALL monitor ops no-op while the hyprland VT
  is not the active seat ("drm: Session inactive" in its log) -- never
  debug monitor behavior from another TTY.
- Debug a live session from anywhere:
  `export HYPRLAND_INSTANCE_SIGNATURE=$(ls -t /run/user/1000/hypr/ | head -1)`
  then hyprctl works (configerrors, reload, -j monitors). `dms ipc` lists
  all shell verbs; verbs need exact args (brightness needs step AND device,
  keybinds toggle needs provider "hyprland").
- DMS settings: `dms ipc call settings set` works for simple settings.json
  keys only. Session-backed keys (weather location, wallpaper) and complex
  values (barConfigs) need: `dms kill`, edit the json, `setsid -f dms run`
  (with WAYLAND_DISPLAY + HYPRLAND_INSTANCE_SIGNATURE exported). The shell
  saves memory state on exit, so edit only while it is stopped.
- Seeds for app-managed configs: use `run_once_` scripts, not `create_`
  (create_ files raise conflicts every time the app rewrites them; fcitx5
  learned this the hard way).
- kitty.conf contains literal `{{` (its tab title syntax): not templatable.
  Machine-dependent kitty bits go in `fx.conf` (templated, included last).
- DMS dock ignores dockPosition and anchors top (bug in 1.5.2, bind parked
  in hyprland template; retry after dms updates).
- zsh eats words starting with `=` (echo === fails); zshrc must be checked
  with `zsh -n`, not bash.
- Known upstream bug: hyprland may segfault in CGroup::remove when a
  grouped window dies (crash report in ~/.cache/hyprland/).
- DO NOT enable HDR / 10-bit on grodarch: an HDR modeset (`cm, hdr` +
  `bitdepth, 10`) hard-wedges the nvidia-open 610 display engine
  ("nvidia-modeset: Error while waiting for GPU progress", modeset task
  stuck in D-state holding a semaphore, Hyprland unkillable, reboot-only).
  Known open-module + GSP hang class; proprietary module + GSP-off is the
  only workaround and is not a confirmed HDR fix. Revisit on a newer driver.
  For HDR video, tone-map instead (mpv --vo=gpu-next), never real HDR out.
- hyprlang .conf is DEPRECATED (0.55+; 0.56 warns on startup) in favor of Lua
  (~/.config/hypr/hyprland.lua). .conf still loads (support ~1-2 releases past
  0.55, so ~0.57-0.58); no auto-converter; the two cannot coexist (hyprland.lua
  wins if present). DO NOT migrate yet: DMS mod+F1 cheatsheet parses the .conf
  main file (Lua likely breaks it), and the whole config is chezmoi-templated
  (per-host monitors, theme palette, feature gates, sourced binds-workspaces).
  Revisit when DMS gains Lua keybind support + Lua config stabilizes. Warning
  is cosmetic; no clean suppress found (hyprlang noerror is for plugins only).
