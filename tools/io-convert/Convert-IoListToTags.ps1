# Convert-IoListToTags.ps1
# Convert an I/O list (CSV exported from Excel) into a TIA Portal tag-table XML
# that can be imported via the PLC tags editor's Import button.
#
# This needs NO TIA Portal / license -- it is pure text conversion. The resulting
# XML matches the format TIA actually exports (verified: tia-projects/sample_tags.xml).
#
# CSV columns (header row required): Name, DataType, Address, Comment
#   - Name/Comment may be Korean (read as UTF-8).
#   - DataType: Bool, Int, Real, DInt, Word, ... (TIA data types)
#   - Address:  %I0.0, %Q0.1, %IW100, %MD1000, ... (or leave blank for symbolic)
#
# Usage:
#   powershell -File Convert-IoListToTags.ps1 -CsvPath in.csv -OutXml out.xml [-TableName "My tags"]
# ASCII-only script body (PowerShell 5.1 / code page safety); data may be Korean.
param(
    [Parameter(Mandatory=$true)][string]$CsvPath,
    [string]$OutXml = "tags.xml",
    [string]$TableName = "ImportedTags"
)

if (-not (Test-Path $CsvPath)) { Write-Output "FAIL: CSV not found: $CsvPath"; return }

$rows = Import-Csv -Path $CsvPath -Encoding UTF8
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("<?xml version='1.0' encoding='utf-8'?>")
[void]$sb.AppendLine("<Tagtable name='$([System.Security.SecurityElement]::Escape($TableName))'>")

$n = 0
foreach ($r in $rows) {
    if (-not $r.Name) { continue }
    $name = [System.Security.SecurityElement]::Escape($r.Name)
    $rem  = [System.Security.SecurityElement]::Escape(("" + $r.Comment))
    $type = ("" + $r.DataType).Trim()
    $addr = ("" + $r.Address).Trim()
    [void]$sb.AppendLine("  <Tag type='$type' hmiVisible='True' hmiWriteable='True' hmiAccessible='True' retain='False' remark='$rem' addr='$addr'>$name</Tag>")
    $n++
}
[void]$sb.AppendLine("</Tagtable>")

[System.IO.File]::WriteAllText($OutXml, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
Write-Output "OK: converted $n tags -> $OutXml"
