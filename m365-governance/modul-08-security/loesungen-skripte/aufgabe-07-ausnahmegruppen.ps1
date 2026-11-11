# Quelle: Skript „M365 Governance“, Modul 08, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "startswith(displayName,'SEC-EXC-')" -All
$zeilen = foreach ($g in $gruppen) {
  Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object {
    [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $_.Id }
  }
}
$zeilen | Group-Object Id | Where-Object Count -gt 2 |
  ForEach-Object { [pscustomobject]@{ Id = $_.Name; Gruppen = ($_.Group.Gruppe -join ', ') } }
