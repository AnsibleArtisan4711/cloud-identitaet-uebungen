# Quelle: Skript „M365 Governance“, Modul 08, Lösung zu Aufgabe 4 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
Get-MgIdentityConditionalAccessPolicy -All |
  Select-Object DisplayName, State,
    @{n='NurBericht'; e={ $_.State -eq 'enabledForReportingButNotEnforced' }} |
  Sort-Object NurBericht -Descending | Format-Table -AutoSize
