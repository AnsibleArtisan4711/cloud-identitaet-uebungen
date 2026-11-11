# Quelle: Skript „M365 Governance“, Modul 08, Listing 86 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome

$alle = Get-MgReportAuthenticationMethodUserRegistrationDetail -All
if (-not $alle) { throw "Keine Registrierungsdaten erhalten." }

function Quote($menge, $filter) {
    $n = @($menge | Where-Object $filter).Count
    "{0} von {1} ({2:P0})" -f $n, @($menge).Count, ($n / [math]::Max(1, @($menge).Count))
}

"MFA registriert:            " + (Quote $alle { $_.IsMfaRegistered })
"Kennwortlos moeglich:       " + (Quote $alle { $_.IsPasswordlessCapable })
"Administratoren mit MFA:    " + (Quote ($alle | Where-Object IsAdmin) { $_.IsMfaRegistered })

"--- Benutzer ohne MFA (erste 20) ---"
$alle | Where-Object { -not $_.IsMfaRegistered } |
    Select-Object -First 20 UserPrincipalName, IsAdmin, DefaultMfaMethod |
    Format-Table -AutoSize
