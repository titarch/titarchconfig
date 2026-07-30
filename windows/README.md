# Windows terminal parity

A lightweight PowerShell setup that mirrors the Linux zsh conveniences (zoxide,
fzf keys, inline autosuggestions, starship, eza/fd/bat/lazygit) for the rare
times work happens on Windows. Not chezmoi-managed - standalone on purpose.

For a full Linux experience instead, prefer WSL2 + `boot.sh headless`.

## Install

In PowerShell:

    irm https://raw.githubusercontent.com/titarch/titarchconfig/master/windows/setup.ps1 | iex

or from a checkout: `.\windows\setup.ps1`. Then launch **PowerShell 7 (`pwsh`)**.

The setup installs pwsh 7 and deploys the profile to both host paths. Use pwsh 7
for the full experience: Windows PowerShell 5.1 loads the same profile fine but
skips inline prediction (it ships PSReadLine 2.0, which lacks it). In Windows
Terminal, set PowerShell 7 as your default profile.

Installs the CLI stack via **winget** (ids verified against winget-pkgs), the
PSFzf/PSReadLine PowerShell modules (from PSGallery - winget doesn't do PS
modules), writes `$PROFILE` (backing up any existing one to
`$PROFILE.titarch-bak`) and `~/.config/starship.toml`.

## What you get

- `z <dir>` / `zi` (zoxide), `Ctrl-r` history + `Ctrl-t` file picker (fzf),
  inline history autosuggestion + fish-style list (PSReadLine).
- `ls`/`ll`/`la` -> eza, `f` -> fd, `lg` -> lazygit, `vim` -> nvim, `g`/`gs`/`gd`.
- Dracula starship prompt reading `~/.config/starship.toml`.

## Two extras for real parity

- **Shared history**: run `atuin register` / `atuin login` then `atuin sync` -
  the same command history follows you between Linux and Windows.
- **Windows Terminal**: install a Nerd Font (winget has some, or grab one from
  https://www.nerdfonts.com) and set it as the profile font, then add the
  official Dracula scheme from https://draculatheme.com/windows-terminal and
  select it. That covers the glyphs the prompt and eza icons use.
