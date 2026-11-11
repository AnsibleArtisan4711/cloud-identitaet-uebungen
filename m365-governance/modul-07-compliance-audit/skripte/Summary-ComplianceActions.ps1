# Quelle: Skript „M365 Governance“, Modul 07, Listing 70 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen CSV-Testdaten), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Datei,
    [string]$SpalteStatus = "Status",
    [string]$SpalteOwner  = "Owner",
    [string]$SpalteTitel  = "Title"
)

$zeilen = Import-Csv -Path $Datei -Encoding UTF8
if (-not $zeilen) { throw "Datei enthaelt keine Zeilen: $Datei" }

foreach ($spalte in $SpalteStatus, $SpalteOwner, $SpalteTitel) {
    if ($spalte -notin $zeilen[0].PSObject.Properties.Name) {
        throw "Spalte nicht gefunden: $spalte. Vorhanden: " +
              ($zeilen[0].PSObject.Properties.Name -join ", ")
    }
}

"--- Nach Status ---"
$zeilen | Group-Object $SpalteStatus |
    Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

"--- Offene Massnahmen je Verantwortlichem ---"
$zeilen | Where-Object { $_.$SpalteStatus -notmatch "Implemented|Umgesetzt|Completed" } |
    Group-Object $SpalteOwner | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize
