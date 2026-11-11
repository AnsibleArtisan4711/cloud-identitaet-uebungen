# Quelle: Skript „M365 Governance“, Modul 01, Listing 4 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
# Rollen-ID "Global Administrator" (fuer alle Tenants gleich)
$gaRoleId = "62e90394-69f5-4237-9190-012177145e10"

Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All" -NoWelcome

$active = Get-MgRoleManagementDirectoryRoleAssignment `
            -Filter "roleDefinitionId eq '$gaRoleId'" -ExpandProperty principal -All

$eligible = Get-MgRoleManagementDirectoryRoleEligibilitySchedule `
            -Filter "roleDefinitionId eq '$gaRoleId'" -ExpandProperty principal -All

function Show-Principals($label, $items) {
    Write-Host "`n$label ($(@($items).Count))" -ForegroundColor Cyan
    foreach ($i in $items) {
        $p = $i.Principal.AdditionalProperties
        "{0,-40} {1}" -f $p.userPrincipalName, $p.displayName
    }
}

Show-Principals "Aktive Globale Administratoren"       $active
Show-Principals "Berechtigte Globale Administratoren"   $eligible

if (@($active).Count -ge 5) {
    Write-Warning "Empfehlung ueberschritten: weniger als 5 Globale Administratoren."
}
