# Close-Project.ps1 -- Close the currently open project, without saving  (skill step / close skill)
# Uses the Ctrl+W shortcut (Project > Close). In read-only use (no edits made) the
# project closes immediately with no prompt. If edits WERE made, TIA shows a
# "Save changes?" dialog -- the calling procedure should then click "No" to keep
# the original project untouched (we never want automated saves to live projects).
# Usage: powershell -File Close-Project.ps1 [-Grid]
# ASCII-only on purpose (PowerShell 5.1 / code page safety).
param([switch]$Grid)

. "$PSScriptRoot\..\desktop\Ui.ps1"

Ui-Activate -Maximize | Out-Null
Start-Sleep -Milliseconds 400
Ui-Key "{ESC}"          # close any stray menu first
Start-Sleep -Milliseconds 300
Write-Output "Sending Ctrl+W (close project)..."
Ui-Key "^w"
Start-Sleep -Seconds 4

if ($Grid) { Capture-Screen -Grid } else { Capture-Screen }
$p = Get-TiaProcess
$title = "$($p.MainWindowTitle)"
if ($title -match "\.ap\d") {
    Write-Output "RESULT: still open ($title) -- a 'Save changes?' dialog may be showing; click 'No' (do not save) and recheck."
} else {
    Write-Output "RESULT: OK | project closed (title: $title)"
}
