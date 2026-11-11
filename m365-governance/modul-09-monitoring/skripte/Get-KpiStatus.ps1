# Quelle: Skript „M365 Governance“, Modul 09, Listing 114 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Definition,
    [Parameter(Mandatory)][hashtable]$Werte,
    [string]$Verlauf = ".\kpi-verlauf.csv"
)

$kpis = Get-Content -Path $Definition -Raw -Encoding UTF8 | ConvertFrom-Json

$ergebnis = foreach ($k in $kpis) {
    if (-not $Werte.ContainsKey($k.id)) {
        Write-Warning "Kein Messwert fuer $($k.id)"
        continue
    }
    $w = [double]$Werte[$k.id]
    $status =
        if ($k.richtung -eq "hoeher") {
            if ($w -ge $k.ziel) { "gruen" } elseif ($w -lt $k.alarm) { "rot" } else { "gelb" }
        } else {
            if ($w -le $k.ziel) { "gruen" } elseif ($w -gt $k.alarm) { "rot" } else { "gelb" }
        }
    [pscustomobject]@{
        Datum = (Get-Date -Format "yyyy-MM-dd"); Kennzahl = $k.name
        Wert = $w; Ziel = $k.ziel; Alarm = $k.alarm; Status = $status
        Verantwortlich = $k.verantwortlich
    }
}

$ergebnis | Format-Table -AutoSize
$ergebnis | Export-Csv -Path $Verlauf -Append -NoTypeInformation -Encoding UTF8
"{0} Kennzahlen bewertet, {1} rot." -f @($ergebnis).Count, @($ergebnis | Where-Object Status -eq "rot").Count
