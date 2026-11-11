# Quelle: Skript „M365 Governance“, Modul 07, Listing 78 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen CSV-Testdaten), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei)

$soll = "Anforderung","Kontrollziel","Massnahme","Verantwortlich","Nachweis","Status"
$z = Import-Csv -Path $Datei -Delimiter ';' -Encoding UTF8
if (-not $z) { throw "Keine Zeilen in $Datei" }
$fehlend = $soll | Where-Object { $_ -notin $z[0].PSObject.Properties.Name }
if ($fehlend) { throw "Spalten fehlen: $($fehlend -join ', ')" }

$luecken = foreach ($r in $z) {
    $grund = @()
    if ([string]::IsNullOrWhiteSpace($r.Massnahme))      { $grund += "keine Massnahme" }
    if ([string]::IsNullOrWhiteSpace($r.Verantwortlich)) { $grund += "kein Verantwortlicher" }
    if ([string]::IsNullOrWhiteSpace($r.Nachweis))       { $grund += "kein Nachweis" }
    if ($r.Status -match "offen|open")                   { $grund += "Status offen" }
    if ($grund) {
        [pscustomobject]@{ Anforderung = $r.Anforderung; Kontrollziel = $r.Kontrollziel
                           Luecke = ($grund -join "; ") }
    }
}

if ($luecken) { $luecken | Format-Table -AutoSize -Wrap } else { "Keine Luecken gefunden." }
"{0} von {1} Zeilen mit Luecken" -f @($luecken).Count, @($z).Count
