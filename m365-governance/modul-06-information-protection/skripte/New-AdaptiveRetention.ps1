# Quelle: Skript „M365 Governance“, Modul 06, Listing 58 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: nur Syntax geprüft. Laut Parameterliste der Microsoft-Dokumentation vermutlich nicht lauffähig (siehe README dieses Moduls, Abschnitt "Hinweise"); ein Test belegt nur, dass die Simulation nach Dokumentation den Aufruf ablehnt. Nicht gegen einen Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-AdaptiveScope -Name "Abteilung Personal" `
    -LocationType User `
    -RawQuery "Department -eq 'Personal'"

New-RetentionCompliancePolicy -Name "Personal Postfaecher 10 Jahre" `
    -AdaptiveScopeLocation "Abteilung Personal" `
    -ExchangeLocation All `
    -Enabled $true

New-RetentionComplianceRule -Name "Personal 10 Jahre" `
    -Policy "Personal Postfaecher 10 Jahre" `
    -RetentionDuration 3650 `
    -RetentionComplianceAction Keep `
    -ExpirationDateOption CreationAgeInDays
