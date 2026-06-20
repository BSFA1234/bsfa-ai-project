# Open-Project.ps1 -- Open a recent project from the TIA Portal start screen  (skill step 2)
# Assumes TIA Portal just started and shows the Portal "Open existing project" page
# (i.e. right after Start-Tia.ps1).
#
# This script does only the DETERMINISTIC part (double-click the recent row) and then
# captures the screen. The conditional / timing-sensitive parts are handled by the
# calling procedure (SKILL.md) with capture-verify, because a blind timed click on the
# HSP dialog proved unreliable:
#   * If an "Open project: optional products are missing" (HSP) dialog appears,
#     click its green "Open" button at ~(1125, 672).
#   * After it loads, if the Portal "First steps" page shows, click "Project view"
#     at ~(60, 1016) to switch to the detailed view.
#   * Verify the project tree shows the PLC (not just Online access / Card Reader).
#
# Tip: opening via the Project menu's recent list (only available once in Project view)
#      jumps straight to Project view and skips the "Project view" click.
#
# Coordinates are for a maximized 1920x1080 window (verify with Capture-Screen -Grid).
# Usage: powershell -File Open-Project.ps1 [-RecentIndex 1] [-Grid]
# ASCII-only on purpose (PowerShell 5.1 / code page safety).
param([int]$RecentIndex = 1, [switch]$Grid)

. "$PSScriptRoot\..\desktop\Ui.ps1"
. "$PSScriptRoot\Coords.ps1"
Test-TiaResolution

Ui-Activate -Maximize | Out-Null
Start-Sleep -Milliseconds 500

# Make sure the "Open existing project" option is selected (so the recent list shows).
$opt = $TiaCoords.OpenExistingOpt
Ui-Click $opt[0] $opt[1]
Start-Sleep -Milliseconds 500

# Recent list: row 1 center, each subsequent row +RecentRowStep in Y.
$rx   = $TiaCoords.RecentRow1[0]
$rowY = $TiaCoords.RecentRow1[1] + (($RecentIndex - 1) * $TiaCoords.RecentRowStep)
Write-Output "Double-clicking recent project row $RecentIndex at ($rx,$rowY)..."
Ui-DoubleClick $rx $rowY

Write-Output "Waiting ~20s for load / HSP dialog..."
Start-Sleep -Seconds 20
if ($Grid) { Capture-Screen -Grid } else { Capture-Screen }
Write-Output "RESULT: open initiated. NEXT (procedure): if HSP dialog -> click Open ($($TiaCoords.HspOpen -join ',')); then if First-steps page -> click Project view ($($TiaCoords.ProjectViewLink -join ',')); verify tree shows the PLC."
