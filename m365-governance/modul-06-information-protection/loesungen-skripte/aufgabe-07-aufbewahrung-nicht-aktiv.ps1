# Quelle: Skript „M365 Governance“, Modul 06, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession
Get-RetentionCompliancePolicy -DistributionDetail |
    Where-Object { -not $_.Enabled -or $_.DistributionStatus -ne 'Success' } |
    Select-Object Name, Enabled, DistributionStatus |
    Format-Table -AutoSize
