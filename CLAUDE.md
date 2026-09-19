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
  (DP-4 left, DP-3 mid, DP-5 right; connectors shuffle on hw changes, match by
  serial in .chezmoidata.toml), sunshine streaming host, greetd
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
- `home/dot_config/hypr/hyprland.lua.tmpl`: i3 keybind port, Lua config
  (chezmoi-templated). Workspace binds 2-12/14-24 live in `binds-workspaces.lua`
  (require'd); kept split for readability - DMS 1.6 parses require'd lua modules
  for the mod+F1 cheatsheet, so the split no longer hides them. Validate any
  edit with `Hyprland -c <rendered.lua> --verify-config` (renders via
  `chezmoi execute-template`).
- `stream` (dot_local/bin): sunshine away mode. Persistent parked headless
  output (20000x20000, named ws stream-park) so sunshine wlr capture always
  sees it; monitor switching writes `hl.monitor{}` to
  `~/.config/hypr/monitors-runtime.lua` + `hyprctl reload`. Never restart
  sunshine from its own prep-cmd.
- `presence`: idle inhibit + ydotool jiggler (mod+P). `cursor-drift`:
  catppuccin cursor accent rotation. `config-sync`: non-interactive pull +
  apply + dms refresh (calls dms-bar-setup / dms-plugins-setup), the normal
  way to sync a machine.
- DMS plugins in `home/dot_config/DankMaterialShell/plugins/`: netspeed is
  homegrown (fixed-width rates + vpn toggle popout); registry plugins are
  installed by dms-plugins-setup (list lives in that script). That script also
  sets the Calculator plugin's engine to qalc (libqalculate: unit/currency/hex
  conversions) by merging calcEngine into plugin_settings.json; DMS never
  rewrites that file except on a GUI change, so the external merge is safe and
  applies on next DMS start. mod+x (spotlight "= ") routes to that plugin.
- Firefox tab-scroll fix: autoconfig in `system/firefox/` + pacman hook
  (accumulates hi-res wheel deltas; stock handler switches per event).

## Hard-won gotchas
- Monitor ops at runtime (Lua config): `hyprctl keyword` HARD-fails ("keyword
  can't work with non-legacy parsers. Use eval.") and wlr-output-management is
  ignored. Working mechanism: write `hl.monitor{}` to a require'd .lua module
  (monitors-override.lua via the `monitors` helper, monitors-runtime.lua via
  `stream`) then `hyprctl reload` (CONFIRMED re-reads require'd modules).
  `hyprctl eval 'hl.monitor{...}'` also works live (returns "ok" even when inert
  -> verify via `hyprctl -j monitors`). ALL monitor ops no-op while the hyprland
  VT is not the active seat ("drm: Session inactive") -- never debug from another TTY.
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
- DMS/quickshell dies at boot racing PipeWire (quickshell 0.3, pipewire 1.6.8):
  its audio thread (QAudioContext) either segfaults in
  libpipewire-module-protocol-native or deadlocks ("pw_core_sync timed out").
  Symptom: no bar + (worse) lock-on-boot never fires -> box sits UNLOCKED.
  Coredumps: `coredumpctl list quickshell`; hypr log is in /run (wiped on
  reboot) so use journalctl -b -1. Mitigations in place: `dms-start` gates
  `dms run` on pipewire readiness (pw-cli info 0 + wpctl); wireplumber
  50-disable-stream-restore.conf turns off the persisted stream state it chokes
  on; the lock-on-boot loop `timeout`s each dms ipc call and falls back to
  hyprlock. Recover a live wedge: `pkill -9 -f quickshell/dms; setsid -f dms run`.
- DO NOT enable HDR / 10-bit on grodarch: an HDR modeset (`cm, hdr` +
  `bitdepth, 10`) hard-wedges the nvidia-open 610 display engine
  ("nvidia-modeset: Error while waiting for GPU progress", modeset task
  stuck in D-state holding a semaphore, Hyprland unkillable, reboot-only).
  Known open-module + GSP hang class; proprietary module + GSP-off is the
  only workaround and is not a confirmed HDR fix. Revisit on a newer driver.
  For HDR video, tone-map instead (mpv --vo=gpu-next), never real HDR out.
- DMS greeter (1.6+): now a single `/usr/bin/dms-greeter` binary, embedded UI
  (the /usr/share/quickshell/dms-greeter tree is gone). `dms greeter <cmd>` is a
  deprecation shim -> `dms-greeter <cmd>`, so the existing /etc/greetd/config.toml
  keeps working. After a greeter repackage, re-run `sudo dms-greeter sync` (theme).
  New `sync --autologin` applies ONLY autologin, not the theme (run plain `sync`
  too). Do NOT re-run `dms-greeter install`/`enable` on grodarch: it may reset the
  hand-tuned initial_session (env XDG_SESSION_TYPE + launch-session --from-memory).
- Config MIGRATED to Lua (2026-09; hyprland 0.56.2, dms 1.6.2). hyprland.lua.tmpl
  is the config; hyprlang .conf retired. Parser chosen at STARTUP: hyprland.lua
  present -> lua; `hyprctl reload` does NOT switch parsers, so a swap needs a
  relogin. Rollback = `rm ~/.config/hypr/hyprland.lua` + relogin (restore .conf
  from git if ever needed). Validated Lua API on 0.56.2: keys are "MOD + KEY"
  (+ separated, no-mod = bare key); hl.monitor/env/config/bind/define_submap/
  window_rule/layer_rule/workspace_rule/curve({type="bezier",points=})/animation
  ({leaf,enabled,speed,bezier,style})/device/on/timer; gradients =
  {colors={..},angle=N}, single colors = "rgb(hex)" strings; dispatchers hl.dsp.*
  (focus{direction=|workspace=}, window.move{workspace=|direction=,group_aware=},
  window.fullscreen{mode=,action=}, window.float{action=}, layout("preselect r"),
  group.toggle/next/prev, workspace.move{monitor=}). Validate edits with
  `Hyprland -c f.lua --verify-config` (EXCEPT hl.timer, which suppresses its
  clean output). DEFERRED: internalizing cursor-drift/presence/screenprivacy into
  hl.timer/hl.on("screenshare.state")/hl.get_windows -- hl.timer is not statically
  verifiable and screenshare.state may fire for sunshine wlr-screencopy (privacy-
  trigger risk); they stay external exec-once until confirmed live.
