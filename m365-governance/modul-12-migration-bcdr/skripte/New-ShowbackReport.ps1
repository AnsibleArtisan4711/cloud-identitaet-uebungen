# Quelle: Skript „M365 Governance“, Modul 12, Listing 155 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Verbrauch,       # CSV: Abteilung;SpeicherGB;SicherungGB
    [Parameter(Mandatory)][decimal]$FreiesKontingentGB,
    [Parameter(Mandatory)][decimal]$PreisSpeicherProGBMonat,
    [Parameter(Mandatory)][decimal]$PreisSicherungProGBMonat,
    [string]$Ausgabe = ".\showback.csv"
)

$daten = Import-Csv -Path $Verbrauch -Delimiter ";"
if (-not $daten) { throw "Keine Verbrauchsdaten." }

$gesamtSpeicher = ($daten | ForEach-Object { [decimal]$_.SpeicherGB } | Measure-Object -Sum).Sum
$ueber = [math]::Max(0, $gesamtSpeicher - $FreiesKontingentGB)
$anteilUeber = if ($gesamtSpeicher -gt 0) { $ueber / $gesamtSpeicher } else { 0 }

$bericht = foreach ($z in $daten) {
    $sp = [decimal]$z.SpeicherGB
    $si = [decimal]$z.SicherungGB
    $kostenSpeicher  = [math]::Round($sp * $anteilUeber * $PreisSpeicherProGBMonat, 2)
    $kostenSicherung = [math]::Round($si * $PreisSicherungProGBMonat, 2)
    [pscustomobject]@{
        Abteilung = $z.Abteilung; SpeicherGB = $sp; SicherungGB = $si
        KostenSpeicher = $kostenSpeicher; KostenSicherung = $kostenSicherung
        Summe = $kostenSpeicher + $kostenSicherung
    }
}

$bericht | Sort-Object Summe -Descending | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$bericht | Sort-Object Summe -Descending | Format-Table -AutoSize
"Gesamt pro Monat: {0:N2}" -f ($bericht | Measure-Object Summe -Sum).Sum
