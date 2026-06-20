# Start-Tia.ps1 -- Launch / activate / maximize TIA Portal  (skill step 1)
# - If already running, bring to front + maximize; otherwise launch and wait for window.
# - Captures the screen at the end (-Grid for coordinate grid).
# Usage: powershell -File Start-Tia.ps1 [-Grid]
# ASCII-only on purpose (PowerShell 5.1 / code page safety).
param([switch]$Grid)

. "$PSScriptRoot\..\desktop\Ui.ps1"

# Auto-detect the installed TIA Portal version (V18 / V19 / V20 / ...), highest first.
# Portability: works regardless of which TIA version is installed on this machine.
$exe = Get-ChildItem "C:\Program Files\Siemens\Automation\Portal V*\Bin\Siemens.Automation.Portal.exe" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $exe) { $exe = "C:\Program Files\Siemens\Automation\Portal V20\Bin\Siemens.Automation.Portal.exe" }

$proc = Get-TiaProcess
if (-not $proc) {
    if (-not (Test-Path $exe)) { Write-Output "RESULT: FAIL (exe not found: $exe)"; return }
    Write-Output "TIA not running -> launching (takes 1-3 min)..."
    Start-Process $exe
    for ($i = 1; $i -le 24; $i++) {
        Start-Sleep -Seconds 10
        $proc = Get-TiaProcess
        if ($proc) { Write-Output "[$($i*10)s] window appeared"; break }
        Write-Output "[$($i*10)s] loading..."
    }
} else {
    Write-Output "TIA already running (pid $($proc.Id))"
}

if (-not $proc) { Write-Output "RESULT: FAIL (window did not appear)"; return }

Ui-Activate -Proc $proc -Maximize
Start-Sleep -Milliseconds 500
if ($Grid) { Capture-Screen -Grid } else { Capture-Screen }
Write-Output "RESULT: OK | title: $($proc.MainWindowTitle)"
