# Quelle: Skript „M365 Governance“, Modul 08, Listing 92 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Maximum = 5)

Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All","AuditLog.Read.All" -NoWelcome

$rolle = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
if (-not $rolle) { throw "Rolle nicht aktiviert oder nicht gefunden." }

$mitglieder = Get-MgDirectoryRoleMember -DirectoryRoleId $rolle.Id -All
$reg = @{}
Get-MgReportAuthenticationMethodUserRegistrationDetail -All |
    ForEach-Object { $reg[$_.Id] = $_ }

$bericht = foreach ($m in $mitglieder) {
    $u = Get-MgUser -UserId $m.Id -Property DisplayName,UserPrincipalName,UserType,AccountEnabled,Mail
    $r = $reg[$m.Id]
    [pscustomobject]@{
        Konto      = $u.UserPrincipalName
        Typ        = $u.UserType
        Aktiv      = $u.AccountEnabled
        MfaRegistr = if ($r) { $r.IsMfaRegistered } else { "unbekannt" }
        HatPostfach = [bool]$u.Mail
    }
}

$bericht | Format-Table -AutoSize
if (@($bericht).Count -gt $Maximum) { Write-Warning "Mehr als $Maximum Globale Administratoren: $(@($bericht).Count)" }
$bericht | Where-Object { $_.MfaRegistr -ne $true }       | ForEach-Object { Write-Warning "Keine MFA: $($_.Konto)" }
$bericht | Where-Object { $_.Typ -eq "Guest" }            | ForEach-Object { Write-Warning "Gastkonto: $($_.Konto)" }
$bericht | Where-Object { $_.HatPostfach }                | ForEach-Object { Write-Warning "Admin mit Postfach: $($_.Konto)" }
