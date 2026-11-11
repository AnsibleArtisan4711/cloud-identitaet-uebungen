# Quelle: Skript „M365 Governance“, Modul 01, Listing 6 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$PolicyFile = ".\policy-tenant.json")

$policy = Get-Content $PolicyFile -Raw | ConvertFrom-Json
Connect-MgGraph -Scopes "RoleManagement.Read.Directory" -NoWelcome

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
