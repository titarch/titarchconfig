#Requires -Version 5.1
# titarchconfig - Windows bootstrap: scoop + CLI tools + PowerShell profile.
# One-liner:
#   irm https://raw.githubusercontent.com/titarch/titarchconfig/master/windows/setup.ps1 | iex
# or from a checkout:  .\windows\setup.ps1
$ErrorActionPreference = 'Stop'
function info($m) { Write-Host ":: $m" -ForegroundColor Magenta }
function warn($m) { Write-Host "!! $m" -ForegroundColor Yellow }

# --- scoop: no-admin package manager (the Linux-feeling one) ---
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
  info 'installing scoop'
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}
scoop bucket add extras 6>$null 2>$null   # eza/delta/lazygit/atuin live here
info 'installing CLI tools (scoop)'
scoop install git zoxide starship fzf ripgrep fd bat eza delta lazygit jq neovim atuin

# --- PowerShell modules: fzf keybindings + inline predictions ---
info 'installing PowerShell modules (PSFzf, PSReadLine)'
if (-not (Get-Module -ListAvailable PSFzf))      { Install-Module PSFzf      -Scope CurrentUser -Force }
if (-not (Get-Module -ListAvailable PSReadLine)) { Install-Module PSReadLine -Scope CurrentUser -Force }

# --- deploy profile + starship config (local checkout, else fetch from repo) ---
$rawBase = 'https://raw.githubusercontent.com/titarch/titarchconfig/master/windows'
$local   = $PSScriptRoot
function Fetch($name, $dest) {
  if ($local -and (Test-Path (Join-Path $local $name))) { Copy-Item (Join-Path $local $name) $dest -Force }
  else { Invoke-RestMethod "$rawBase/$name" -OutFile $dest }
}

New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
if ((Test-Path $PROFILE) -and -not (Test-Path "$PROFILE.titarch-bak")) {
  Copy-Item $PROFILE "$PROFILE.titarch-bak"; info "backed up existing profile -> $PROFILE.titarch-bak"
}
info 'writing PowerShell profile'
Fetch 'Microsoft.PowerShell_profile.ps1' $PROFILE

$cfgDir = Join-Path $HOME '.config'
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
if (-not (Test-Path (Join-Path $cfgDir 'starship.toml'))) {
  info 'writing starship config'
  Fetch 'starship.toml' (Join-Path $cfgDir 'starship.toml')
}

info 'done - restart PowerShell (or run:  . $PROFILE )'
warn 'set a Nerd Font in Windows Terminal for the prompt/eza glyphs (see windows/README.md)'
