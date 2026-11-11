# Quelle: Skript „M365 Governance“, Modul 02, Listing 16 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "User.Invite.All","User.Read.All","AuditLog.Read.All" -NoWelcome

# 1) Gast einladen
New-MgInvitation -InvitedUserEmailAddress "partner@fabrikam.example" `
    -InvitedUserDisplayName "Partner Fabrikam" `
    -InviteRedirectUrl "https://myapps.microsoft.com" `
    -SendInvitationMessage:$true

# 2) Ausstehende Einladungen aelter als 30 Tage
$grenze = (Get-Date).AddDays(-30)
Get-MgUser -Filter "userType eq 'Guest' and externalUserState eq 'PendingAcceptance'" -All `
    -Property Id,DisplayName,Mail,CreatedDateTime,ExternalUserState |
    Where-Object { $_.CreatedDateTime -lt $grenze } |
    Select-Object DisplayName, Mail, CreatedDateTime
# 3) Gaeste ohne Anmeldung seit 90 Tagen
$inaktiv = (Get-Date).AddDays(-90)
Get-MgUser -Filter "userType eq 'Guest'" -All `
    -Property Id,DisplayName,Mail,SignInActivity |
    Where-Object { -not $_.SignInActivity.LastSuccessfulSignInDateTime -or
                   $_.SignInActivity.LastSuccessfulSignInDateTime -lt $inaktiv } |
    Select-Object DisplayName, Mail, @{n='LetzteAnmeldung';e={$_.SignInActivity.LastSuccessfulSignInDateTime}}
