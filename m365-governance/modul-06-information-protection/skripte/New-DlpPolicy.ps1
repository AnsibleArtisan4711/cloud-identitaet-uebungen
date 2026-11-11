# Quelle: Skript „M365 Governance“, Modul 06, Listing 52 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-DlpCompliancePolicy -Name "DLP Finanzdaten" `
    -ExchangeLocation All `
    -SharePointLocation All `
    -OneDriveLocation All `
    -Mode TestWithNotifications `
    -Comment "Pilot: Kreditkarte und IBAN, zuerst nur Test"
New-DlpComplianceRule -Name "Kreditkarte extern blockieren" `
    -Policy "DLP Finanzdaten" `
    -ContentContainsSensitiveInformation @{ Name = "Credit Card Number"; minCount = "1" } `
    -AccessScope NotInOrganization `
    -BlockAccess $true `
    -NotifyUser Owner `
    -GenerateAlert SiteAdmin

New-DlpComplianceRule -Name "IBAN nur warnen" `
    -Policy "DLP Finanzdaten" `
    -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "5" } `
    -NotifyUser Owner `
    -GenerateIncidentReport SiteAdmin

Get-DlpCompliancePolicy "DLP Finanzdaten" -DistributionDetail |
    Select-Object Name, Mode, DistributionStatus
