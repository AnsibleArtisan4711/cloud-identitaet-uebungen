# Quelle: Skript „M365 Governance“, Modul 09, Listing 111 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Ordner,
    [int]$MaxAlterTage = 365
)

$pflicht = "Zweck", "Voraussetzungen", "Schritte", "Pruefung", "Rueckweg", "Eskalation"
$dateien = Get-ChildItem -Path $Ordner -Filter *.md -File -Recurse
if (-not $dateien) { throw "Keine Runbooks in $Ordner gefunden." }

$ergebnis = foreach ($d in $dateien) {
    $text = Get-Content -Path $d.FullName -Raw -Encoding UTF8
    $fehlt = $pflicht | Where-Object { $text -notmatch "(?im)^#+\s*$_\b" }

    $alt = "kein Datum"
    if ($text -match "Letzte Pruefung:\s*(\d{4}-\d{2}-\d{2})") {
        $tage = ((Get-Date) - [datetime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)).Days
        $alt  = if ($tage -gt $MaxAlterTage) { "veraltet ($tage Tage)" } else { "aktuell ($tage Tage)" }
    }

    [pscustomobject]@{
        Runbook = $d.Name
        Fehlend = if ($fehlt) { $fehlt -join ", " } else { "-" }
        Pruefung = $alt
    }
}
$ergebnis | Format-Table -AutoSize
$schlecht = $ergebnis | Where-Object { $_.Fehlend -ne "-" -or $_.Pruefung -notlike "aktuell*" }
"{0} von {1} Runbooks brauchen Pflege." -f @($schlecht).Count, @($ergebnis).Count
