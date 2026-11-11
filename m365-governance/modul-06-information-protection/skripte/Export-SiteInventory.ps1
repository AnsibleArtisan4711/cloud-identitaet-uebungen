# Quelle: Skript „M365 Governance“, Modul 06, Listing 62 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Tenant)

Connect-SPOService -Url "https://$Tenant-admin.sharepoint.com"
Connect-IPPSSession

$labels = @{}
Get-Label | ForEach-Object { $labels[[string]$_.Guid] = $_.DisplayName }

Get-SPOSite -Limit All -IncludePersonalSite $false |
    Select-Object Url, Title, Template, Owner,
        @{ n = 'GB';    e = { [math]::Round($_.StorageUsageCurrent / 1024, 2) } },
        LastContentModifiedDate,
        @{ n = 'Label'; e = { if ($_.SensitivityLabel) {
                                  $labels[[string]$_.SensitivityLabel] } else { '(kein Label)' } } } |
    Sort-Object GB -Descending |
    Export-Csv -Path ".\Standortinventar.csv" -NoTypeInformation -Encoding UTF8
