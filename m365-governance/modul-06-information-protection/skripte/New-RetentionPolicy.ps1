# Quelle: Skript „M365 Governance“, Modul 06, Listing 54 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: nur Syntax geprüft. Laut Parameterliste der Microsoft-Dokumentation vermutlich nicht lauffähig (siehe README dieses Moduls, Abschnitt "Hinweise"); ein Test belegt nur, dass die Simulation nach Dokumentation den Aufruf ablehnt. Nicht gegen einen Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-RetentionCompliancePolicy -Name "Mail und Chat 7 Jahre" `
    -ExchangeLocation All `
    -TeamsChatLocation All `
    -Enabled $true `
    -Comment "Geschaeftskorrespondenz: 7 Jahre aufbewahren, dann loeschen"

New-RetentionComplianceRule -Name "7 Jahre ab Erstellung" `
    -Policy "Mail und Chat 7 Jahre" `
    -RetentionDuration 2555 `
    -RetentionComplianceAction KeepAndDelete `
    -ExpirationDateOption CreationAgeInDays

Get-RetentionCompliancePolicy "Mail und Chat 7 Jahre" -DistributionDetail |
    Select-Object Name, Enabled, DistributionStatus
