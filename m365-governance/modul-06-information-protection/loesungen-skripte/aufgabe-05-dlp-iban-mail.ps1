# Quelle: Skript „M365 Governance“, Modul 06, Lösung zu Aufgabe 5 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession
New-DlpCompliancePolicy -Name "DLP IBAN Mail" -ExchangeLocation All `
    -Mode TestWithNotifications
New-DlpComplianceRule -Name "IBAN ab drei Treffern" -Policy "DLP IBAN Mail" `
    -ContentContainsSensitiveInformation @{
        Name = "International Banking Account Number (IBAN)"; minCount = "3" } `
    -NotifyUser Owner
