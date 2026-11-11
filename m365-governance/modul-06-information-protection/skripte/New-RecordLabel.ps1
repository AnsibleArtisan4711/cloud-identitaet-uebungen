# Quelle: Skript „M365 Governance“, Modul 06, Listing 56 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-ComplianceTag -Name "Vertrag 10 Jahre" `
    -Comment "Unterschriebene Vertraege, Frist ab Erstellung" `
    -IsRecordLabel $true `
    -Regulatory $false `
    -RetentionAction KeepAndDelete `
    -RetentionDuration 3650 `
    -RetentionType CreationAgeInDays

New-RetentionCompliancePolicy -Name "Veroeffentlichung Vertragslabel" `
    -SharePointLocation All `
    -Enabled $true

New-RetentionComplianceRule -Name "Vertragslabel veroeffentlichen" `
    -Policy "Veroeffentlichung Vertragslabel" `
    -PublishComplianceTag "Vertrag 10 Jahre"

Get-ComplianceTag "Vertrag 10 Jahre" |
    Select-Object Name, IsRecordLabel, Regulatory, RetentionDuration
