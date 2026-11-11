# Quelle: Skript „M365 Governance“, Modul 12, Lösung zu Aufgabe 6 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei, [int]$Mindestgroesse = 5)
$z = Import-Csv -Path $Datei -Delimiter ";"
$gross = $z | Where-Object { [int]$_.Beschaeftigte -ge $Mindestgroesse }
$klein = $z | Where-Object { [int]$_.Beschaeftigte -lt $Mindestgroesse }
$ausgabe = foreach ($a in $gross) {
    $grad = [int]$a.Aktive / [int]$a.Beschaeftigte
    [pscustomobject]@{ Abteilung = $a.Abteilung; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
if ($klein) {
    $b = ($klein | Measure-Object Beschaeftigte -Sum).Sum
    $ak = ($klein | Measure-Object Aktive -Sum).Sum
    $grad = $ak / $b
    $ausgabe += [pscustomobject]@{ Abteilung = "(kleine Abteilungen zusammengefasst)"; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
$ausgabe | Format-Table -AutoSize
