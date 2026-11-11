# Zusammengesetzt aus Listing 6 und dem Codeausschnitt der Lösung zu Aufgabe 5 (Skript, Modul 01). Die Zusammensetzung stammt aus diesem Repository, nicht aus dem Skript.
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$PolicyFile = ".\policy-tenant.json")

$policy = Get-Content $PolicyFile -Raw | ConvertFrom-Json
Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All" -NoWelcome

$gaRoleId = "62e90394-69f5-4237-9190-012177145e10"
$gaCount  = @(Get-MgRoleManagementDirectoryRoleAssignment `
              -Filter "roleDefinitionId eq '$gaRoleId'" -All).Count

$ok = $gaCount -le $policy.rules.maxGlobalAdmins

[pscustomobject]@{
    Regel   = "maxGlobalAdmins"
    Soll    = "<= $($policy.rules.maxGlobalAdmins)"
    Ist     = $gaCount
    Ergebnis= if ($ok) { "OK" } else { "ABWEICHUNG" }
}

# --- Ergänzung aus der Lösung zu Aufgabe 5 ---
$all    = Get-MgUserCount -ConsistencyLevel eventual
$guests = Get-MgUserCount -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$share  = if ($all -gt 0) { [math]::Round($guests / $all, 3) } else { 0 }
[pscustomobject]@{
    Regel    = "maxGuestShare"
    Soll     = "<= $($policy.rules.maxGuestShare)"
    Ist      = $share
    Ergebnis = if ($share -le $policy.rules.maxGuestShare) { "OK" } else { "ABWEICHUNG" }
}
