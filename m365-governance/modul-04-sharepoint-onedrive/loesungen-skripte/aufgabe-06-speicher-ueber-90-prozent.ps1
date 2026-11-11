# Quelle: Skript „M365 Governance“, Modul 04, Lösung zu Aufgabe 6 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"
Get-SPOSite -Limit All -IncludePersonalSite $false |
  Where-Object { $_.StorageQuota -gt 0 -and
                 ($_.StorageUsageCurrent / $_.StorageQuota) -gt 0.9 } |
  Select-Object Url, Owner,
    @{n='FreiGB'; e={ [math]::Round(($_.StorageQuota - $_.StorageUsageCurrent) / 1024, 2) }} |
  Sort-Object FreiGB | Format-Table -AutoSize
