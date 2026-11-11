# Quelle: Skript „M365 Governance“, Modul 08, Listing 88 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Tage = 7)

Connect-MgGraph -Scopes "SecurityAlert.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddDays(-$Tage).ToString("yyyy-MM-ddTHH:mm:ssZ")
$alarme = Get-MgSecurityAlertV2 -Filter "createdDateTime ge $seit" -All

if (-not $alarme) { Write-Host "Keine Warnungen im Zeitraum."; return }

"--- Nach Schweregrad ---"
$alarme | Group-Object Severity | Sort-Object Name |
    Select-Object Name, Count | Format-Table -AutoSize

"--- Nach Quelle und Status ---"
$alarme | Group-Object ServiceSource, Status |
    Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

"--- Hoch/Kritisch und noch nicht geloest ---"
$alarme | Where-Object { $_.Severity -in "high","critical" -and $_.Status -ne "resolved" } |
    Select-Object CreatedDateTime, ServiceSource, Title, Status |
    Sort-Object CreatedDateTime | Format-Table -AutoSize -Wrap
