# Quelle: Skript „M365 Governance“, Modul 01, Listing 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Policy.Read.All","RoleManagement.Read.Directory" -NoWelcome

$results = New-Object System.Collections.Generic.List[object]
function Add-Result($Check, $Status, $Detail) {
    $results.Add([pscustomobject]@{ Pruefung=$Check; Status=$Status; Detail=$Detail })
}

# 1. Security Defaults
$sd = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy
Add-Result "Security Defaults" "INFO" ("aktiv: " + $sd.IsEnabled)

# 2. Conditional Access
$ca = @(Get-MgIdentityConditionalAccessPolicy -All)
$enabled = @($ca | Where-Object State -eq "enabled").Count
$status = if ($enabled -ge 1) { "OK" } elseif ($sd.IsEnabled) { "PRUEFEN" } else { "ABWEICHUNG" }
Add-Result "Conditional Access" $status "$enabled von $($ca.Count) Richtlinien aktiv"

# 3. Globale Administratoren
$gaId = "62e90394-69f5-4237-9190-012177145e10"
$ga = @(Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$gaId'" -All).Count
Add-Result "Globale Administratoren" $(if ($ga -lt 5) {"OK"} else {"PRUEFEN"}) "$ga aktive Zuweisungen"

# 4. Nicht automatisierbar
Add-Result "Notfallkonten (2 Stueck, getestet)" "MANUELL" "Nachweis im Betriebshandbuch"
$results | Format-Table -AutoSize
