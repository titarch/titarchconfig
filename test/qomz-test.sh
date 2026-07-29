#!/usr/bin/env bash
# Run qomz.sh in a fresh container per supported distro and assert it produces a
# working zsh. One image per package-manager family (apt/dnf/pacman/apk/zypper).
# Usage: test/qomz-test.sh [distro ...]   (default: all)
set -u
here="$(cd "$(dirname "$0")" && pwd)"
qomz="$here/../qomz.sh"
[ -f "$qomz" ] || { echo "qomz.sh not found at $qomz"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker is required"; exit 1; }

# name : image  (one per package manager)
images="
debian|debian:stable-slim
ubuntu|ubuntu:24.04
fedora|fedora:latest
arch|archlinux:latest
alpine|alpine:latest
opensuse|opensuse/tumbleweed:latest
"
sel="${*:-debian ubuntu fedora arch alpine opensuse}"

# assertions run inside the container after qomz.sh
probe='
  set -u
  sh /qomz.sh || { echo "!! qomz.sh exited $?"; exit 1; }
  command -v zsh >/dev/null      || { echo "!! zsh missing"; exit 1; }
  [ -d "$HOME/.oh-my-zsh" ]      || { echo "!! oh-my-zsh missing"; exit 1; }
  [ -f "$HOME/.zshrc" ]          || { echo "!! .zshrc missing"; exit 1; }
  zsh -ic "print QOMZ_SHELL_OK" 2>/dev/null | grep -q QOMZ_SHELL_OK \
                                 || { echo "!! .zshrc failed to load in zsh"; exit 1; }
  { [ -x "$HOME/.local/bin/starship" ] || command -v starship >/dev/null; } \
    || { echo "!! starship not installed"; exit 1; }
  echo "   starship: ok"
  command -v nvim >/dev/null || command -v vim >/dev/null || { echo "!! no editor (nvim/vim)"; exit 1; }
  [ -f "$HOME/.vimrc" ] || { echo "!! editor config missing"; exit 1; }
  if command -v nvim >/dev/null; then ED=nvim; nvim --headless -c qa >/tmp/ed 2>&1 || true
  else ED=vim; vim -es -c qa </dev/null >/tmp/ed 2>&1 || true; fi
  grep -qiE "E[0-9]{2,}" /tmp/ed && { echo "!! editor config error:"; cat /tmp/ed; exit 1; }
  echo "   editor: $ED ok"
  echo "   ASSERTIONS_OK"
'

pass=0 fail=0 summary=""
for row in $images; do
  name="${row%%|*}"; image="${row#*|}"
  case " $sel " in *" $name "*) ;; *) continue ;; esac
  printf '\n==================== %s (%s) ====================\n' "$name" "$image"
  if timeout 600 docker run --rm -v "$qomz":/qomz.sh:ro "$image" sh -c "$probe"; then
    printf '  -> PASS\n'; pass=$((pass+1)); summary="$summary  PASS  $name\n"
  else
    printf '  -> FAIL\n'; fail=$((fail+1)); summary="$summary  FAIL  $name\n"
  fi
done

printf '\n==================== summary ====================\n'
printf '%b' "$summary"
printf 'passed=%s failed=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
