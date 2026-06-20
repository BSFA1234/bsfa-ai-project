# Coords.ps1 -- Machine-specific TIA Portal UI click coordinates (single source of truth).
#
# BASELINE: TIA Portal MAXIMIZED on a 1920x1080 display at 100% scaling.
# On a different display / scaling these will be off. To re-calibrate on a new machine:
#   1) Start-Tia.ps1 -Grid   (and use Save-Crop ... -Grid on regions)
#   2) Read the coordinate labels off the grid and update the numbers below.
# Each value is @(x, y). This is the ONLY file you should need to edit per machine.
#
# Dot-source this file: . "$PSScriptRoot\Coords.ps1"   then use $TiaCoords / Test-TiaResolution.
# ASCII-only on purpose (PowerShell 5.1 / code page safety).

$TiaBaselineResolution = '1920x1080'

$TiaCoords = @{
    OpenExistingOpt = @(290, 162)   # start screen: "Open existing project" option
    RecentRow1      = @(800, 180)   # start screen: first recent-project row (center)
    RecentRowStep   = 30            #   each subsequent recent row is +this in Y
    HspOpen         = @(1125, 672)  # "optional products are missing" dialog -> green Open
    ProjectViewLink = @(60, 1016)   # Portal "First steps" page -> Project view link
    PortalViewLink  = @(45, 1016)   # Project view -> Portal view toggle
    ProjectMenu     = @(45, 31)     # menu bar: "Project"
    TreePlcExpand   = @(49, 239)    # project tree: PLC node expand arrow
    TreePlcTags     = @(69, 391)    # project tree: "PLC tags" expand arrow
    TreeDefaultTags = @(160, 448)   # project tree: "Default tag table"
    ExportIcon      = @(352, 135)   # tag-table editor toolbar: Export icon
    ExportPathField = @(830, 443)   # export dialog: path text field
    ExportOk        = @(1054, 623)  # export dialog: OK button
    ExportSuccessOk = @(1085, 562)  # "Export completed successfully" dialog: OK button
}

# Warn (do not block) if the current display differs from the calibration baseline.
function Test-TiaResolution {
    Add-Type -AssemblyName System.Windows.Forms
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $cur = "$($b.Width)x$($b.Height)"
    if ($cur -ne $TiaBaselineResolution) {
        Write-Output "WARN: display is $cur but coordinates are calibrated for $TiaBaselineResolution. Re-derive with 'Capture-Screen -Grid' and update Coords.ps1 before trusting clicks."
    }
}
