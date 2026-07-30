#Requires -Version 5.1
# titarchconfig - Windows bootstrap: winget CLI tools + PowerShell profile.
# One-liner:
#   irm https://raw.githubusercontent.com/titarch/titarchconfig/master/windows/setup.ps1 | iex
# or from a checkout:  .\windows\setup.ps1
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false   # don't abort on winget's nonzero (already-installed) exits
function info($m) { Write-Host ":: $m" -ForegroundColor Magenta }
function warn($m) { Write-Host "!! $m" -ForegroundColor Yellow }

# --- winget (ships as App Installer on Win10 1709+/Win11) ---
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  warn 'winget not found - install "App Installer" from the Microsoft Store, then re-run.'
  return
}
# ids verified against microsoft/winget-pkgs
$pkgs = @(
  'Git.Git', 'ajeetdsouza.zoxide', 'Starship.Starship', 'junegunn.fzf',
  'BurntSushi.ripgrep.MSVC', 'sharkdp.fd', 'sharkdp.bat', 'eza-community.eza',
  'dandavison.delta', 'JesseDuffield.lazygit', 'jqlang.jq', 'Neovim.Neovim', 'Atuinsh.Atuin'
)
info 'installing CLI tools (winget)'
foreach ($id in $pkgs) {
  winget install --id $id -e --source winget --silent --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) { warn "winget '$id' returned $LASTEXITCODE (already installed / no match - continuing)" }
}

# --- PowerShell modules (not winget): fzf keybindings + inline predictions ---
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
