# Quelle: Skript „M365 Governance“, Modul 04, Listing 31 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$sites = Get-SPOSite -Limit All -IncludePersonalSite $false |
    Select-Object Url, Title, Owner,
        @{n='GenutztGB'; e={ [math]::Round($_.StorageUsageCurrent / 1024, 2) }},
        @{n='QuoteGB';   e={ [math]::Round($_.StorageQuota / 1024, 2) }},
        @{n='Auslastung';e={ if ($_.StorageQuota -gt 0) { [math]::Round(100 * $_.StorageUsageCurrent / $_.StorageQuota, 1) } else { $null } }}

$sites | Sort-Object GenutztGB -Descending | Select-Object -First 20 | Format-Table -AutoSize
$sites | Export-Csv ".\speicher-bericht.csv" -NoTypeInformation -Encoding UTF8

"`nWebsites ueber 80 Prozent Auslastung:"
$sites | Where-Object { $_.Auslastung -gt 80 } | Format-Table Url, GenutztGB, QuoteGB, Auslastung -AutoSize

# Beispiel: Quote einer Website auf 200 GB (204800 MB) anheben
# Set-SPOSite -Identity https://contoso.sharepoint.com/sites/PRJ-Messe -StorageQuota 204800
