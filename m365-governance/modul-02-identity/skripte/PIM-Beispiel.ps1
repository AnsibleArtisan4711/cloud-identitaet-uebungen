# Quelle: Skript „M365 Governance“, Modul 02, Listing 14 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "RoleEligibilitySchedule.ReadWrite.Directory","RoleAssignmentSchedule.ReadWrite.Directory","RoleManagement.Read.Directory" -NoWelcome

$userId = "<Objekt-ID der Person>"
$role   = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Exchange Administrator'"

# 1) Berechtigt machen (zwoelf Monate)
$eligible = @{
    action           = "adminAssign"
    justification    = "Betrieb Exchange Online, Antrag 4711"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId      = $userId
    scheduleInfo     = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration    = @{ type = "afterDuration"; duration = "P365D" }
    }
}
New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $eligible | Out-Null

# 2) Spaeter: die Person aktiviert selbst fuer vier Stunden
$activate = @{
    action           = "selfActivate"
    justification    = "Postfachmigration Abteilung Vertrieb"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId      = $userId
    scheduleInfo     = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration    = @{ type = "afterDuration"; duration = "PT4H" }
    }
}
New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $activate | Out-Null

# 3) Berechtigte Zuweisungen auflisten
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty "roleDefinition,principal" -All |
    Select-Object @{n='Rolle';e={$_.RoleDefinition.DisplayName}},
                  @{n='Person';e={$_.Principal.AdditionalProperties.userPrincipalName}},
                  @{n='Ablauf';e={$_.ScheduleInfo.Expiration.EndDateTime}}
