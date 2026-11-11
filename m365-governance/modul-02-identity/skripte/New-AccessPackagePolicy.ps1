# Quelle: Skript „M365 Governance“, Modul 02, Listing 12 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All" -NoWelcome

$ap = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq 'Marketing Kampagne'"
if (-not $ap) { throw "Zugriffspaket nicht gefunden" }

$params = @{
    displayName        = "Mitarbeiter fordern an - Genehmigung durch Teamleitung"
    description        = "Interne Mitglieder, 180 Tage, 1 Genehmiger"
    allowedTargetScope = "allMemberUsers"
    expiration         = @{ type = "afterDuration"; duration = "P180D" }
    requestorSettings  = @{
        enableTargetsToSelfAddAccess    = $true
        enableTargetsToSelfUpdateAccess = $true
        enableTargetsToSelfRemoveAccess = $true
    }
    requestApprovalSettings = @{
        isApprovalRequiredForAdd    = $true
        isApprovalRequiredForUpdate = $true
        stages = @(
            @{
                durationBeforeAutomaticDenial   = "P7D"
                isApproverJustificationRequired = $false
                isEscalationEnabled             = $false
                primaryApprovers = @(
                    @{ "@odata.type" = "#microsoft.graph.singleUser"; userId = "<Objekt-ID Genehmiger>" }
                )
                fallbackPrimaryApprovers = @()
                escalationApprovers      = @()
                fallbackEscalationApprovers = @()
            }
        )
    }
    accessPackage = @{ id = $ap.Id }
}
New-MgEntitlementManagementAssignmentPolicy -BodyParameter $params | Out-Null

$assignments = @(Get-MgEntitlementManagementAssignment `
    -Filter "accessPackage/id eq '$($ap.Id)' and state eq 'Delivered'" `
    -ExpandProperty target -All)
$assignments | Select-Object Id, @{n='Benutzer';e={$_.Target.DisplayName}}, @{n='UPN';e={$_.Target.PrincipalName}} |
    Export-Csv ".\zuweisungen.csv" -NoTypeInformation -Encoding UTF8
