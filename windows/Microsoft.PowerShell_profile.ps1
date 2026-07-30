# titarchconfig - PowerShell profile mirroring the Linux zsh setup.
# Deployed to $PROFILE by windows/setup.ps1; CLI tools come from winget.

# --- environment ---
$env:EDITOR = 'nvim'
# fzf uses fd (gitignore-aware), matching the Linux FZF_DEFAULT_COMMAND
$env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
$env:FZF_CTRL_T_COMMAND  = $env:FZF_DEFAULT_COMMAND
$env:FZF_ALT_C_COMMAND   = 'fd --type d --hidden --exclude .git'

# --- PSReadLine: zsh-autosuggestions-like inline prediction + history search ---
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine
  Set-PSReadLineOption -EditMode Emacs                    # ctrl-a/e/w/u like zsh default
  # inline prediction needs PSReadLine 2.2+ (Windows PowerShell 5.1 ships 2.0 -> skip).
  # launch PowerShell 7 (pwsh) to get it; that host bundles a new enough PSReadLine.
  if ((Get-Module PSReadLine).Version -ge [version]'2.2.0') {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin # inline autosuggestion
    Set-PSReadLineOption -PredictionViewStyle ListView      # fish-style dropdown
  }
  Set-PSReadLineOption -HistoryNoDuplicates
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# --- fzf keybindings via PSFzf: Ctrl-t files, Ctrl-r history ---
if (Get-Module -ListAvailable PSFzf) {
  Import-Module PSFzf
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# --- tool integrations (loaded only if the binary is present) ---
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })   # z <dir> / zi
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
  $env:STARSHIP_CONFIG = "$HOME\.config\starship.toml"
  Invoke-Expression (&starship init powershell)
}
if (Get-Command atuin -ErrorAction SilentlyContinue) {
  # atuin owns ctrl-r when present (loaded after PSFzf so it wins, as on Linux);
  # `atuin sync` unifies this history with your Linux machines
  Invoke-Expression (& { (atuin init powershell | Out-String) })
}

# --- aliases / functions (mirror the zsh ones; @args splats through) ---
if (Get-Command eza -ErrorAction SilentlyContinue) {
  function ls { eza --group-directories-first @args }
  function ll { eza -lh --group-directories-first --git --icons=auto @args }
  function la { eza -lah --group-directories-first --git --icons=auto @args }
}
if (Get-Command nvim -ErrorAction SilentlyContinue) { Set-Alias vim nvim }
function f   { fd @args }              # was find; fd is faster + gitignore-aware
function lg  { lazygit @args }
function g   { git @args }
function gs  { git status @args }
function gd  { git diff @args }
function eb  { nvim $PROFILE }          # edit this profile
function sb  { . $PROFILE }             # reload it
