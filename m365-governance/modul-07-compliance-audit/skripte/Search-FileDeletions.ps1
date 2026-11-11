# Quelle: Skript „M365 Governance“, Modul 07, Listing 66 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Benutzer,
    [int]$Tage = 7
)

Connect-ExchangeOnline

$config = Get-AdminAuditLogConfig
if (-not $config.UnifiedAuditLogIngestionEnabled) {
    Write-Warning "Audit-Erfassung ist ausgeschaltet. Wird eingeschaltet."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
}

$ende  = (Get-Date).ToUniversalTime()
$start = $ende.AddDays(-$Tage)
$treffer = Search-UnifiedAuditLog -StartDate $start -EndDate $ende `
    -UserIds $Benutzer `
    -Operations FileDeleted, FileRecycled `
    -ResultSize 5000 -SessionId ("del-" + (Get-Date -Format yyyyMMddHHmmss)) `
    -SessionCommand ReturnLargeSet

$treffer | ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{
        Zeit      = $_.CreationDate
        Benutzer  = $_.UserIds
        Operation = $_.Operations
        Datei     = $d.SourceFileName
        Website   = $d.SiteUrl
        ClientIP  = $d.ClientIP
    }
} | Sort-Object Zeit | Format-Table -AutoSize

Write-Host ("Treffer: {0}" -f @($treffer).Count)
