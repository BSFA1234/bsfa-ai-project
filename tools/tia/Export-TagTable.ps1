# Export-TagTable.ps1 -- Export the OPEN PLC tag table to XML  (skill step 3)
# Precondition: a PLC tag table editor is already open and active in TIA Portal
#   (navigate the tree and double-click a tag table first).
# Flow: click the Export icon on the tag-table toolbar -> fill the export path
#   (clipboard paste, Korean-safe) -> click OK.
# The "Export completed successfully" confirmation is dismissed by the calling
#   procedure (SKILL.md) via capture-verify; the file is only flushed to disk
#   once that dialog is closed.
# Coordinates are for a maximized 1920x1080 window (verify with Capture-Screen -Grid).
# Usage: powershell -File Export-TagTable.ps1 -OutPath "C:\...\out.xml" [-Grid]
# ASCII-only on purpose (PowerShell 5.1 / code page safety).
param([Parameter(Mandatory=$true)][string]$OutPath, [switch]$Grid)

. "$PSScriptRoot\..\desktop\Ui.ps1"
. "$PSScriptRoot\Coords.ps1"
Test-TiaResolution

Ui-Activate -Maximize | Out-Null
Start-Sleep -Milliseconds 400

$ic = $TiaCoords.ExportIcon
Write-Output "Clicking Export icon ($($ic -join ','))..."
Ui-Click $ic[0] $ic[1]
Start-Sleep -Milliseconds 1500

Write-Output "Filling export path..."
$pf = $TiaCoords.ExportPathField
Ui-Click $pf[0] $pf[1]      # path text field
Start-Sleep -Milliseconds 300
Ui-Key "^a"                 # select existing text
Start-Sleep -Milliseconds 150
Ui-Paste $OutPath           # paste path (clipboard = Korean-safe)
Start-Sleep -Milliseconds 500

$ok = $TiaCoords.ExportOk
Write-Output "Clicking OK ($($ok -join ','))..."
Ui-Click $ok[0] $ok[1]
Start-Sleep -Seconds 2

# Dismiss the "Export completed successfully" dialog. File flushes only after this closes.
Ui-Activate -Maximize | Out-Null
Start-Sleep -Milliseconds 400
$sk = $TiaCoords.ExportSuccessOk
Write-Output "Dismissing success dialog ($($sk -join ','))..."
Ui-Click $sk[0] $sk[1]
Start-Sleep -Seconds 3

if (Test-Path $OutPath) {
    $len = (Get-Item $OutPath).Length
    if ($len -gt 0) { Write-Output "RESULT: OK | $OutPath ($len bytes)" }
    else { Write-Output "RESULT: WARN | file is 0 bytes -- success dialog may still be open; dismiss it and recheck." }
} else {
    Write-Output "RESULT: FAIL | file not created (check the tag-table editor was open and the export path)."
}
