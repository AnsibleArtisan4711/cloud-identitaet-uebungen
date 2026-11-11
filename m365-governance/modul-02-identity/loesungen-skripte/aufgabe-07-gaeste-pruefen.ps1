# Quelle: Skript „M365 Governance“, Modul 02, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
$g = Get-MgUser -Filter "userType eq 'Guest'" -All `
     -Property Id,DisplayName,Mail,CreatedDateTime,ExternalUserState,SignInActivity
$inaktiv = $g | Where-Object {
  $_.ExternalUserState -ne 'PendingAcceptance' -and
  ( -not $_.SignInActivity.LastSuccessfulSignInDateTime -or
    $_.SignInActivity.LastSuccessfulSignInDateTime -lt (Get-Date).AddDays(-120) ) }
$offen = $g | Where-Object {
  $_.ExternalUserState -eq 'PendingAcceptance' -and
  $_.CreatedDateTime -lt (Get-Date).AddDays(-45) }
"--- Inaktiv (>120 Tage) ---"; $inaktiv | Select-Object DisplayName, Mail
"--- Einladung offen (>45 Tage) ---"; $offen | Select-Object DisplayName, Mail, CreatedDateTime
