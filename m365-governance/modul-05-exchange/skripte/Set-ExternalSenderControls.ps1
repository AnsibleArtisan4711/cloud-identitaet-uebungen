# Quelle: Skript „M365 Governance“, Modul 05, Listing 46 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline

Get-ExternalInOutlook | Format-List Enabled, AllowList

Set-ExternalInOutlook -Enabled $true
Set-ExternalInOutlook -AllowList @{Add = "partner.example.com"}

"== Authentifizierung eigener Domaenen =="
foreach ($d in Get-AcceptedDomain | Where-Object { $_.DomainType -eq "Authoritative" }) {
    $name = $d.DomainName.ToString()
    $spf   = Resolve-DnsName -Name $name -Type TXT -ErrorAction SilentlyContinue |
             Where-Object { $_.Strings -like "v=spf1*" }
    $dmarc = Resolve-DnsName -Name "_dmarc.$name" -Type TXT -ErrorAction SilentlyContinue |
             Where-Object { $_.Strings -like "v=DMARC1*" }
    [pscustomobject]@{ Domain = $name; SPF = [bool]$spf; DMARC = [bool]$dmarc }
}
