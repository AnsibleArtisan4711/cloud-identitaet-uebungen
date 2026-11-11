# Quelle: Skript „M365 Governance“, Modul 05, Lösung zu Aufgabe 5 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline
$eigene = (Get-AcceptedDomain).DomainName | ForEach-Object { $_.ToString().ToLower() }
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ForwardingSmtpAddress } | ForEach-Object {
    $ziel = ($_.ForwardingSmtpAddress.ToString() -replace '^smtp:','').ToLower()
    $domain = $ziel.Split('@')[-1]
    if ($domain -notin $eigene) {
        [pscustomobject]@{ Postfach = $_.PrimarySmtpAddress; Ziel = $ziel }
    }
}
