# PowerShell 7 profile — oh-my-posh (paradox) + PSReadLine
# Drives the "PowerShell 7" Ghostty window (config/ghostty/launch pwsh).
# Safe to load from any pwsh session.

# --- PATH -------------------------------------------------------------------
# The launcher runs `pwsh -l` directly, not via a login shell, so zprofile is
# not sourced and Homebrew's bin (where oh-my-posh lives) may be missing.
# Prepend it ourselves.
foreach ($p in '/opt/homebrew/bin', '/usr/local/bin') {
    if ((Test-Path $p) -and (":$($env:PATH):" -notlike "*:$($p):*")) {
        $env:PATH = "$p" + [IO.Path]::PathSeparator + $env:PATH
    }
}

# --- oh-my-posh -------------------------------------------------------------
# 'paradox' = the full-powerline, black-background theme from Microsoft's own
# "Customize PowerShell with Oh My Posh" docs. Swap the filename to retheme;
# preview all with:  Get-PoshThemes
$OmpTheme = '/opt/homebrew/share/oh-my-posh/themes/paradox.omp.json'
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config $OmpTheme | Invoke-Expression
}

# --- PSReadLine -------------------------------------------------------------
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource HistoryAndPlugin   # inline + list suggestions
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -Colors @{ InlinePrediction = '#767676' }

# Windows-Terminal-style key bindings
Set-PSReadLineKeyHandler -Key UpArrow        -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow      -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab            -Function MenuComplete
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
