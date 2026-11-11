# Quelle: Skript „M365 Governance“, Modul 02, Listing 17 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$UserPrincipalName)

Connect-MgGraph -Scopes "AuditLog.Read.All","Directory.Read.All" -NoWelcome

Write-Host "== Letzte Anmeldungen ==" -ForegroundColor Cyan
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 15 |
    Select-Object CreatedDateTime, AppDisplayName,
        @{n='Status';e={ if ($_.Status.ErrorCode -eq 0) {'OK'} else {"Fehler $($_.Status.ErrorCode)"} }},
        @{n='Grund';e={$_.Status.FailureReason}},
        ConditionalAccessStatus |
    Format-Table -AutoSize

Write-Host "== Letzte Verzeichnisaenderungen am Konto ==" -ForegroundColor Cyan
$user = Get-MgUser -UserId $UserPrincipalName
Get-MgAuditLogDirectoryAudit -Filter "targetResources/any(t:t/id eq '$($user.Id)')" -Top 15 |
    Select-Object ActivityDateTime, ActivityDisplayName, Result,
        @{n='Durch';e={$_.InitiatedBy.User.UserPrincipalName}} |
    Format-Table -AutoSize
