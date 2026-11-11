# Quelle: Skript „M365 Governance“, Modul 06, Listing 60 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-OrganizationSegment -Name "Handel" `
    -UserGroupFilter "Department -eq 'Handel'"
New-OrganizationSegment -Name "Beratung" `
    -UserGroupFilter "Department -eq 'Beratung'"

New-InformationBarrierPolicy -Name "Handel blockiert Beratung" `
    -AssignedSegment "Handel" -SegmentsBlocked "Beratung" -State Inactive
New-InformationBarrierPolicy -Name "Beratung blockiert Handel" `
    -AssignedSegment "Beratung" -SegmentsBlocked "Handel" -State Inactive

# Nach Pilot und Freigabe: Richtlinien aktivieren und anwenden
Get-InformationBarrierPolicy | ForEach-Object {
    Set-InformationBarrierPolicy -Identity $_.Identity -State Active
}
Start-InformationBarrierPoliciesApplication
Get-InformationBarrierPoliciesApplicationStatus
