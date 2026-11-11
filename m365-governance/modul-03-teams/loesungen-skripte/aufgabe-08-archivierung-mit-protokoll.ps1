# Quelle: Skript „M365 Governance“, Modul 03, Lösung zu Aufgabe 8 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$CsvPfad, [switch]$Ausfuehren)
Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","Group.Read.All" -NoWelcome
$grenze = (Get-Date).AddDays(-365)
$log = ".\archivierung-$(Get-Date -Format yyyyMMdd).log"
foreach ($z in Import-Csv $CsvPfad) {
  $g = Get-MgGroup -GroupId $z.TeamId -Property Id,DisplayName,RenewedDateTime
  if ($g.RenewedDateTime -gt $grenze) {
    Add-Content $log "$(Get-Date -Format s) UEBERSPRUNGEN $($g.DisplayName) (juenger als 365 Tage)"
    continue
  }
  if ($Ausfuehren) { Invoke-MgArchiveTeam -TeamId $g.Id }
  Add-Content $log "$(Get-Date -Format s) $(if($Ausfuehren){'ARCHIVIERT'}else{'PROBELAUF'}) $($g.DisplayName)"
}
