# Quelle: Skript „M365 Governance“, Modul 04, Listing 32 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Tage = 365, [switch]$SchreibschutzSetzen)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"
$grenze = (Get-Date).AddDays(-$Tage)

$kandidaten = Get-SPOSite -Limit All -IncludePersonalSite $false |
    Where-Object { $_.LastContentModifiedDate -lt $grenze -and $_.LockState -eq 'Unlock' } |
    Select-Object Url, Title, Owner, LastContentModifiedDate,
        @{n='GB'; e={ [math]::Round($_.StorageUsageCurrent / 1024, 2) }}

"{0} Websites ohne Aenderung seit {1} Tagen." -f @($kandidaten).Count, $Tage
$kandidaten | Sort-Object LastContentModifiedDate | Export-Csv ".\inaktive-websites.csv" -NoTypeInformation -Encoding UTF8
$kandidaten | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize

if ($SchreibschutzSetzen) {
    foreach ($k in $kandidaten) {
        Set-SPOSite -Identity $k.Url -LockState ReadOnly
        "Schreibgeschuetzt: $($k.Url)"
    }
}
