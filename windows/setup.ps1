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
# ids verified against microsoft/winget-pkgs. Microsoft.PowerShell = pwsh 7
# (Windows PowerShell 5.1's old PSReadLine can't do inline prediction).
$pkgs = @(
  'Microsoft.PowerShell', 'Git.Git', 'ajeetdsouza.zoxide', 'Starship.Starship', 'junegunn.fzf',
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

# deploy to BOTH host profile paths (Windows PowerShell 5.1 + PowerShell 7) so
# whichever is launched picks it up. Derive the sibling from $PROFILE so OneDrive
# Documents redirection is respected.
$targets = @($PROFILE)
if     ($PROFILE -match 'WindowsPowerShell') { $targets += ($PROFILE -replace 'WindowsPowerShell', 'PowerShell') }
elseif ($PROFILE -match '\\PowerShell\\')    { $targets += ($PROFILE -replace '\\PowerShell\\', '\WindowsPowerShell\') }
foreach ($p in ($targets | Select-Object -Unique)) {
  $dir = Split-Path $p
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  if ((Test-Path $p) -and -not (Test-Path "$p.titarch-bak")) {
    Copy-Item $p "$p.titarch-bak"; info "backed up existing profile -> $p.titarch-bak"
  }
  info "writing profile -> $p"
  Fetch 'Microsoft.PowerShell_profile.ps1' $p
  Fetch 'git-aliases.ps1' (Join-Path $dir 'git-aliases.ps1')   # sourced by the profile
}

$cfgDir = Join-Path $HOME '.config'
New-Item -ItemType Directory -Force -Path $cfgDir | Out-Null
if (-not (Test-Path (Join-Path $cfgDir 'starship.toml'))) {
  info 'writing starship config'
  Fetch 'starship.toml' (Join-Path $cfgDir 'starship.toml')
}

info 'done - launch PowerShell 7 (pwsh) for the full experience'
warn 'Windows PowerShell 5.1 works but skips inline prediction (old PSReadLine); use pwsh 7'
warn 'set a Nerd Font in Windows Terminal for the prompt/eza glyphs (see windows/README.md)'
