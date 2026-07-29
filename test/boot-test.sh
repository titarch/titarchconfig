#!/usr/bin/env bash
# Exercise boot.sh across distros in fresh containers. Tests the `quick` tier
# (self-contained) and the `headless` tier (deploys the dotfiles from a copy of
# this working tree via BOOT_SOURCE, so it needs no push). Also a `nixsim` case
# (arch + /etc/NIXOS marker) exercising the NixOS branch. Desktop tier is
# Arch-only + interactive, so it's not covered here.
# Usage: test/boot-test.sh [distro ...]   (default: all; nixsim runs with arch)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
[ -f "$root/boot.sh" ] || { echo "boot.sh not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker required"; exit 1; }

images="
debian|debian:stable-slim
ubuntu|ubuntu:24.04
fedora|fedora:latest
arch|archlinux:latest
alpine|alpine:latest
opensuse|opensuse/tumbleweed:latest
"
sel="${*:-debian ubuntu fedora arch alpine opensuse}"

quick_probe='
  sh /repo/boot.sh quick || { echo "!! quick exited $?"; exit 1; }
  command -v zsh >/dev/null                                   || { echo "!! zsh"; exit 1; }
  [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.zshrc" ]          || { echo "!! omz/zshrc"; exit 1; }
  zsh -ic "print QOMZ_OK" 2>/dev/null | grep -q QOMZ_OK       || { echo "!! zshrc load"; exit 1; }
  { [ -x "$HOME/.local/bin/starship" ] || command -v starship >/dev/null; } || { echo "!! starship"; exit 1; }
  command -v nvim >/dev/null || command -v vim >/dev/null     || { echo "!! editor"; exit 1; }
  echo "   quick: ok"
'
headless_probe='
  export PATH="$HOME/.local/bin:$PATH"
  BOOT_SOURCE=/repo sh /repo/boot.sh headless || { echo "!! headless exited $?"; exit 1; }
  [ -f "$HOME/.zshrc" ]                       || { echo "!! zshrc missing"; exit 1; }
  [ ! -e "$HOME/.config/hypr" ]               || { echo "!! GUI (hypr) not gated"; exit 1; }
  grep -q "gpgsign = false" "$HOME/.gitconfig" || { echo "!! signing not disabled"; exit 1; }
  [ -f "$HOME/.config/zellij/config.kdl" ]    || { echo "!! zellij config missing"; exit 1; }
  { command -v zellij >/dev/null || [ -x "$HOME/.local/bin/zellij" ]; } || echo "   (zellij: soft-missing)"
  w="$(zsh -ic true 2>&1)"                     # interactive startup must be clean
  printf "%s" "$w" | grep -q "\[oh-my-zsh\] plugin" && { echo "!! omz plugin warnings:"; printf "%s\n" "$w" | grep "\[oh-my-zsh\]"; exit 1; } || true
  echo "   headless: ok"
'

# NixOS path: arch image + /etc/NIXOS marker + tools pre-provided (standing in for
# nix/fleet-headless.nix). Asserts boot.sh takes the nix branch and deploys dotfiles
# WITHOUT trying to install the toolchain itself (starship must stay absent here).
nixsim_probe='
  touch /etc/NIXOS
  pacman -Sy --noconfirm --needed chezmoi git zsh neovim curl >/dev/null 2>&1 || { echo "!! tool preinstall"; exit 1; }
  BOOT_SOURCE=/repo sh /repo/boot.sh headless 2>&1 | tee /tmp/o | sed "s/^/    /"
  grep -q "NixOS detected" /tmp/o                            || { echo "!! nix branch not taken"; exit 1; }
  grep -q "headless setup done (NixOS)" /tmp/o               || { echo "!! nix deploy did not finish"; exit 1; }
  [ -f "$HOME/.zshrc" ]                                      || { echo "!! zshrc missing"; exit 1; }
  [ ! -e "$HOME/.config/hypr" ]                              || { echo "!! GUI (hypr) not gated"; exit 1; }
  grep -q "gpgsign = false" "$HOME/.gitconfig"               || { echo "!! signing not disabled"; exit 1; }
  command -v starship >/dev/null && { echo "!! boot.sh installed starship on NixOS (should defer to Nix)"; exit 1; } || true
  w="$(zsh -ic true 2>&1)"; printf "%s" "$w" | grep -q "\[oh-my-zsh\] plugin" && { echo "!! omz plugin warnings"; exit 1; } || true
  echo "   nixsim: ok"
'

pass=0 fail=0 summary=""
run() { # name image tier probe
  printf '  %-9s %-8s\n' "$2" "$3"
  # copy the (read-only mounted) repo to a writable path so chezmoi can use it.
  # capture first, THEN check rc: piping straight to sed reports sed's exit (always 0)
  local out rc
  out="$(timeout 900 docker run --rm -v "$root":/src:ro "$1" sh -c "cp -a /src /repo && $4" 2>&1)"; rc=$?
  printf '%s\n' "$out" | sed 's/^/    /'
  if [ "$rc" -eq 0 ]; then echo "    -> PASS"; return 0
  else echo "    -> FAIL (rc=$rc)"; return 1; fi
}
for row in $images; do
  name="${row%%|*}"; image="${row#*|}"
  case " $sel " in *" $name "*) ;; *) continue ;; esac
  printf '\n==================== %s (%s) ====================\n' "$name" "$image"
  run "$image" "$name" quick    "$quick_probe"    && q=PASS || q=FAIL
  run "$image" "$name" headless "$headless_probe" && h=PASS || h=FAIL
  [ "$q" = PASS ] && [ "$h" = PASS ] && { pass=$((pass+1)); summary="$summary  PASS  $name\n"; } \
                                     || { fail=$((fail+1)); summary="$summary  FAIL  $name (quick=$q headless=$h)\n"; }
done
# NixOS simulation (reuses the arch image); runs when arch/nixsim is in the selection
case " $sel " in *" arch "*|*" nixsim "*)
  printf '\n==================== nixsim (archlinux:latest + /etc/NIXOS) ====================\n'
  run archlinux:latest nixsim nixos "$nixsim_probe" \
    && { pass=$((pass+1)); summary="$summary  PASS  nixsim\n"; } \
    || { fail=$((fail+1)); summary="$summary  FAIL  nixsim\n"; }
;; esac
printf '\n==================== summary ====================\n%b passed=%s failed=%s\n' "$summary" "$pass" "$fail"
[ "$fail" -eq 0 ]
