# Quelle: Skript „M365 Governance“, Modul 09, Lösung zu Aufgabe 4 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: Logik offline getestet mit erfundenen Berichtsdaten, aber an einer Kopie mit geändertem Anfangswert: Das Original scheitert in PowerShell 7 und Windows PowerShell 5.1 an [datetime]::TryParse mit $d = $null (siehe README dieses Moduls, Abschnitt "Hinweise"). Nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome
Get-MgReportOffice365ActiveUserDetail -Period D30 -OutFile .\aktiv30.csv
$z = Import-Csv .\aktiv30.csv | Where-Object 'Is Deleted' -ne 'True'
if ('Teams Last Activity Date' -notin $z[0].PSObject.Properties.Name) { throw "Spalte fehlt" }
$grenze = (Get-Date).AddDays(-30).Date
$aktiv = $z | Where-Object {
  $d = $null
  [datetime]::TryParse($_.'Teams Last Activity Date', [ref]$d) -and $d -ge $grenze
}
"{0} von {1} ({2:P0}) in Teams aktiv" -f @($aktiv).Count, @($z).Count, (@($aktiv).Count / @($z).Count)
