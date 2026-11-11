# Quelle: Skript „M365 Governance“, Modul 05, Listing 40 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Name = "Warnung: Absender imitiert Geschaeftsleitung")

Connect-ExchangeOnline

if (Get-TransportRule -Identity $Name -ErrorAction SilentlyContinue) {
    throw "Regel '$Name' existiert bereits."
}

$anzeigenamen = "Erika Mustermann","Max Beispiel"

New-TransportRule -Name $Name `
    -FromScope NotInOrganization `
    -HeaderMatchesMessageHeader "From" `
    -HeaderMatchesPatterns $anzeigenamen `
    -PrependSubject "[EXTERN] " `
    -SetAuditSeverity High `
    -Mode AuditAndNotify `
    -Comments "Zweck: Phishing-Hinweis. Besitzer: Messaging-Team. Angelegt: Testmodus." `
    -Priority 0

Get-TransportRule -Identity $Name | Format-List Name, State, Mode, Priority
