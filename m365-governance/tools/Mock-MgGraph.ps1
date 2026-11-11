# Mock-MgGraph.ps1 - simulierte Microsoft-Graph-Cmdlets für Offline-Tests.
#
# WICHTIG: Diese Funktionen ersetzen die echten Cmdlets nur, um die LOGIK der Übungsskripte prüfen zu können
# (Zählen, Filtern, Schwellenwerte, Ausgabeformat). Sie prüfen NICHT, ob das echte Microsoft Graph so antwortet.
# Parameter, Filter und Berechtigungen müssen weiterhin in einem Testtenant gegen die Microsoft-Dokumentation geprüft werden.
#
# Die Daten kommen aus einer JSON-Datei (tools/fixtures/*.json) mit erfundenen Beispielwerten.

$global:MockCalls = New-Object System.Collections.Generic.List[object]
$global:MockTenant = $null

function Initialize-MockTenant {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockTenant = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}

function Add-MockCall {
    param([string]$Name, [hashtable]$Parameter = @{})
    $global:MockCalls.Add([pscustomobject]@{ Name = $Name; Parameter = $Parameter })
}

function Get-MockScopes {
    # Alle Berechtigungen (Scopes), mit denen sich das Skript angemeldet hat.
    $s = @()
    foreach ($c in $global:MockCalls) { if ($c.Name -eq 'Connect-MgGraph' -and $c.Parameter.Scopes) { $s += $c.Parameter.Scopes } }
    $s
}

function Assert-MockTenant {
    if (-not $global:MockTenant) { throw 'Mock: Initialize-MockTenant wurde nicht aufgerufen.' }
}

function Connect-MgGraph {
    [CmdletBinding()]
    param([string[]]$Scopes, [switch]$NoWelcome, [string]$TenantId, [string]$ClientId, [string]$CertificateThumbprint)
    Assert-MockTenant
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}

function Disconnect-MgGraph {
    [CmdletBinding()] param()
    Add-MockCall 'Disconnect-MgGraph'
}

function Get-MgOrganization {
    [CmdletBinding()] param()
    Assert-MockTenant
    Add-MockCall 'Get-MgOrganization'
    [pscustomobject]@{ DisplayName = $global:MockTenant.organization.displayName }
}

function Get-MgUserCount {
    [CmdletBinding()] param([string]$Filter, [string]$ConsistencyLevel)
    Assert-MockTenant
    Add-MockCall 'Get-MgUserCount' @{ Filter = $Filter }
    # Annahme laut Skript: Zählabfragen brauchen den erweiterten Abfragemodus.
    if ($ConsistencyLevel -ne 'eventual') { throw 'Mock: Get-MgUserCount braucht -ConsistencyLevel eventual.' }
    if (-not $Filter) { return [int]$global:MockTenant.userCount }
    if ($Filter -eq "userType eq 'Guest'") { return [int]$global:MockTenant.guestCount }
    throw "Mock: Filter nicht bekannt: $Filter"
}

function ConvertTo-MockGroup {
    param($Gruppe, [string[]]$Property)
    $voll = [ordered]@{
        Id              = $Gruppe.id
        DisplayName     = $Gruppe.displayName
        CreatedDateTime = (Get-Date).AddDays(-[int]$Gruppe.createdDaysAgo)
        GroupTypes      = @($Gruppe.types)
        SecurityEnabled = [bool]$Gruppe.securityEnabled
        MailEnabled     = [bool]$Gruppe.mailEnabled
        MembershipRule  = $Gruppe.membershipRule
        Visibility      = $Gruppe.visibility
        RenewedDateTime = $(if ($null -ne $Gruppe.renewedDaysAgo) { (Get-Date).AddDays(-[int]$Gruppe.renewedDaysAgo) } else { $null })
        DeletedDateTime = $null
    }
    if (-not $Property) { return [pscustomobject]$voll }
    # Wie im echten Graph: nur ausgewählte Eigenschaften (plus Id) sind gefüllt, alle anderen bleiben leer.
    $teil = [ordered]@{ Id = $Gruppe.id }
    foreach ($p in $Property) { if ($voll.Contains($p)) { $teil[$p] = $voll[$p] } }
    [pscustomobject]$teil
}

function Get-MockGroupSet {
    param([string]$Filter)
    Assert-MockTenant
    $alle = @($global:MockTenant.groups)
    if (-not $Filter) { return $alle }
    if ($Filter -eq "groupTypes/any(c:c eq 'Unified')") { return @($alle | Where-Object { @($_.types) -contains 'Unified' }) }
    if ($Filter -eq "resourceProvisioningOptions/Any(x:x eq 'Team')") { return @($alle | Where-Object { $_.isTeam }) }
    if ($Filter -match "^displayName eq '(.+)'$") { $n = $Matches[1]; return @($alle | Where-Object { $_.displayName -eq $n }) }
    throw "Mock: Filter nicht bekannt: $Filter"
}

function Get-MgGroup {
    [CmdletBinding()]
    param([string]$Filter, [string]$GroupId, [switch]$All, [string[]]$Property, [int]$Top)
    Add-MockCall 'Get-MgGroup' @{ Filter = $Filter; Property = $Property; GroupId = $GroupId }
    if ($GroupId) {
        $g = $global:MockTenant.groups | Where-Object { $_.id -eq $GroupId }
        if (-not $g) { throw "Mock: Gruppe $GroupId unbekannt." }
        return (ConvertTo-MockGroup -Gruppe $g -Property $Property)
    }
    foreach ($g in (Get-MockGroupSet -Filter $Filter)) { ConvertTo-MockGroup -Gruppe $g -Property $Property }
}

function Get-MgGroupCount {
    [CmdletBinding()] param([string]$Filter, [string]$ConsistencyLevel)
    Add-MockCall 'Get-MgGroupCount' @{ Filter = $Filter }
    if ($ConsistencyLevel -ne 'eventual') { throw 'Mock: Get-MgGroupCount braucht -ConsistencyLevel eventual.' }
    @(Get-MockGroupSet -Filter $Filter).Count
}

function Get-MgGroupOwner {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [switch]$All)
    Add-MockCall 'Get-MgGroupOwner' @{ GroupId = $GroupId }
    $g = $global:MockTenant.groups | Where-Object { $_.id -eq $GroupId }
    if (-not $g) { throw "Mock: Gruppe $GroupId unbekannt." }
    for ($i = 1; $i -le [int]$g.ownerCount; $i++) {
        [pscustomobject]@{ Id = "u-$GroupId-$i"; AdditionalProperties = @{ userPrincipalName = "besitzer$i.$GroupId@example.com" } }
    }
}

function Get-MgSubscribedSku {
    [CmdletBinding()] param()
    Assert-MockTenant
    Add-MockCall 'Get-MgSubscribedSku'
    foreach ($s in $global:MockTenant.skus) {
        [pscustomobject]@{
            SkuPartNumber = $s.skuPartNumber
            PrepaidUnits  = [pscustomobject]@{ Enabled = [int]$s.enabled }
            ConsumedUnits = [int]$s.consumed
            ServicePlans  = @(1..[int]$s.servicePlans)
        }
    }
}

function Get-MockRoleItems {
    param($Quelle, [string]$Filter)
    Assert-MockTenant
    if ($Filter -notmatch [regex]::Escape($global:MockTenant.globalAdminRoleId)) { throw "Mock: Rollen-ID im Filter nicht bekannt: $Filter" }
    foreach ($a in $Quelle) {
        [pscustomobject]@{
            Principal = [pscustomobject]@{ AdditionalProperties = @{ userPrincipalName = $a.upn; displayName = $a.name } }
        }
    }
}

function Get-MgRoleManagementDirectoryRoleAssignment {
    [CmdletBinding()] param([string]$Filter, [string]$ExpandProperty, [switch]$All)
    Add-MockCall 'Get-MgRoleManagementDirectoryRoleAssignment' @{ Filter = $Filter }
    Get-MockRoleItems -Quelle $global:MockTenant.activeGlobalAdmins -Filter $Filter
}

function Get-MgRoleManagementDirectoryRoleEligibilitySchedule {
    [CmdletBinding()] param([string]$Filter, [string]$ExpandProperty, [switch]$All)
    Add-MockCall 'Get-MgRoleManagementDirectoryRoleEligibilitySchedule' @{ Filter = $Filter }
    if (-not $Filter) {
        foreach ($e in $global:MockTenant.pimEligible) {
            [pscustomobject]@{
                RoleDefinition = [pscustomobject]@{ DisplayName = $e.role }
                Principal      = [pscustomobject]@{ AdditionalProperties = @{ userPrincipalName = $e.upn } }
                ScheduleInfo   = [pscustomobject]@{ Expiration = [pscustomobject]@{ EndDateTime = (Get-Date).AddDays([int]$e.expiresInDays) } }
            }
        }
        return
    }
    Get-MockRoleItems -Quelle $global:MockTenant.eligibleGlobalAdmins -Filter $Filter
}

function Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy {
    [CmdletBinding()] param()
    Assert-MockTenant
    Add-MockCall 'Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy'
    [pscustomobject]@{ IsEnabled = [bool]$global:MockTenant.securityDefaultsEnabled }
}

function Get-MgIdentityConditionalAccessPolicy {
    [CmdletBinding()] param([switch]$All)
    Assert-MockTenant
    Add-MockCall 'Get-MgIdentityConditionalAccessPolicy'
    foreach ($p in $global:MockTenant.conditionalAccessPolicies) { [pscustomobject]@{ DisplayName = $p.name; State = $p.state } }
}

# ---------------------------------------------------------------------------------------------
# Erweiterung für Modul 02 bis 04: Benutzer, Gäste, Teams, Zustimmungen, Verzeichniseinstellungen,
# Identity Governance. Schreibende Cmdlets legen nichts an, sondern merken sich nur den Aufruf
# (Get-MockCall zeigt ihn an), damit Tests die übergebenen Werte prüfen können.
# ---------------------------------------------------------------------------------------------

function Get-MockCall {
    param([Parameter(Mandatory)][string]$Name)
    @($global:MockCalls | Where-Object { $_.Name -eq $Name })
}

function ConvertTo-MockUser {
    param($Benutzer, [string[]]$Property)
    $letzte = $null
    if ($null -ne $Benutzer.lastSignInDaysAgo) { $letzte = (Get-Date).AddDays(-[int]$Benutzer.lastSignInDaysAgo) }
    $voll = [ordered]@{
        Id                = $Benutzer.id
        DisplayName       = $Benutzer.displayName
        Mail              = $Benutzer.mail
        UserPrincipalName = $Benutzer.upn
        UserType          = $Benutzer.userType
        ExternalUserState = $Benutzer.externalUserState
        CreatedDateTime   = (Get-Date).AddDays(-[int]$Benutzer.createdDaysAgo)
        SignInActivity    = [pscustomobject]@{ LastSuccessfulSignInDateTime = $letzte }
    }
    if (-not $Property) { return [pscustomobject]$voll }
    $teil = [ordered]@{ Id = $Benutzer.id }
    foreach ($p in $Property) { if ($voll.Contains($p)) { $teil[$p] = $voll[$p] } }
    [pscustomobject]$teil
}

function Get-MgUser {
    [CmdletBinding()]
    param([string]$Filter, [string]$UserId, [switch]$All, [string[]]$Property)
    Assert-MockTenant
    Add-MockCall 'Get-MgUser' @{ Filter = $Filter; Property = $Property; UserId = $UserId }
    $alle = @($global:MockTenant.users)
    if ($UserId) {
        $u = $alle | Where-Object { $_.upn -eq $UserId -or $_.id -eq $UserId }
        if (-not $u) { throw "Mock: Benutzer $UserId nicht gefunden." }
        return (ConvertTo-MockUser -Benutzer $u -Property $Property)
    }
    if ($Filter -eq "userType eq 'Guest'") { $menge = @($alle | Where-Object { $_.userType -eq 'Guest' }) }
    elseif ($Filter -eq "userType eq 'Guest' and externalUserState eq 'PendingAcceptance'") {
        $menge = @($alle | Where-Object { $_.userType -eq 'Guest' -and $_.externalUserState -eq 'PendingAcceptance' })
    }
    elseif (-not $Filter) { $menge = $alle }
    else { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($u in $menge) { ConvertTo-MockUser -Benutzer $u -Property $Property }
}

function New-MgInvitation {
    [CmdletBinding()]
    param([string]$InvitedUserEmailAddress, [string]$InvitedUserDisplayName, [string]$InviteRedirectUrl, [bool]$SendInvitationMessage)
    Add-MockCall 'New-MgInvitation' @{ Mail = $InvitedUserEmailAddress; Name = $InvitedUserDisplayName; Redirect = $InviteRedirectUrl; Mitteilung = $SendInvitationMessage }
    [pscustomobject]@{ Id = 'einladung-1' }
}

function Get-MgGroupMember {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [switch]$All)
    Add-MockCall 'Get-MgGroupMember' @{ GroupId = $GroupId }
    $g = $global:MockTenant.groups | Where-Object { $_.id -eq $GroupId }
    if (-not $g) { throw "Mock: Gruppe $GroupId unbekannt." }
    foreach ($m in @($g.members)) {
        [pscustomobject]@{ Id = $m.id; AdditionalProperties = @{ userType = $m.userType; displayName = $m.displayName; mail = $m.mail } }
    }
}

function New-MgGroupLifecyclePolicy {
    [CmdletBinding()] param([int]$GroupLifetimeInDays, [string]$ManagedGroupTypes, [string]$AlternateNotificationEmails)
    Add-MockCall 'New-MgGroupLifecyclePolicy' @{ Tage = $GroupLifetimeInDays; Typen = $ManagedGroupTypes; Mail = $AlternateNotificationEmails }
    [pscustomobject]@{ Id = 'richtlinie-1' }
}

function New-MgGroup {
    [CmdletBinding()]
    param([string]$DisplayName, [string]$MailNickname, [bool]$MailEnabled, [bool]$SecurityEnabled, [string[]]$GroupTypes,
          [string]$MembershipRule, [string]$MembershipRuleProcessingState)
    Add-MockCall 'New-MgGroup' @{ Name = $DisplayName; Typen = $GroupTypes; Regel = $MembershipRule; Verarbeitung = $MembershipRuleProcessingState }
    [pscustomobject]@{ Id = 'gruppe-neu-1' }
}

function Get-MgTeam {
    [CmdletBinding()] param([string]$TeamId, [switch]$All)
    Assert-MockTenant
    Add-MockCall 'Get-MgTeam' @{ TeamId = $TeamId }
    $teams = @($global:MockTenant.groups | Where-Object { $_.isTeam })
    if ($TeamId) { $teams = @($teams | Where-Object { $_.id -eq $TeamId }); if ($teams.Count -eq 0) { throw "Mock: Team $TeamId nicht gefunden." } }
    foreach ($t in $teams) { [pscustomobject]@{ Id = $t.id; DisplayName = $t.displayName; IsArchived = [bool]$t.archived } }
}

function Get-MgTeamChannel {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$TeamId, [switch]$All)
    Add-MockCall 'Get-MgTeamChannel' @{ TeamId = $TeamId }
    $t = $global:MockTenant.groups | Where-Object { $_.id -eq $TeamId }
    if (-not $t) { throw "Mock: Team $TeamId unbekannt." }
    if ($t.channelError) { throw $t.channelError }
    foreach ($k in @($t.channels)) { [pscustomobject]@{ DisplayName = $k.name; MembershipType = $k.membershipType } }
}

function Invoke-MgArchiveTeam {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$TeamId)
    Add-MockCall 'Invoke-MgArchiveTeam' @{ TeamId = $TeamId }
}

function Get-MgServicePrincipal {
    [CmdletBinding()] param([switch]$All, [string[]]$Property)
    Assert-MockTenant
    Add-MockCall 'Get-MgServicePrincipal'
    foreach ($a in $global:MockTenant.servicePrincipals) { [pscustomobject]@{ Id = $a.id; DisplayName = $a.displayName } }
}

function Get-MgOauth2PermissionGrant {
    [CmdletBinding()] param([switch]$All)
    Assert-MockTenant
    Add-MockCall 'Get-MgOauth2PermissionGrant'
    foreach ($g in $global:MockTenant.permissionGrants) { [pscustomobject]@{ ClientId = $g.clientId; ConsentType = $g.consentType; Scope = $g.scope } }
}

function Get-MgBetaDirectorySettingTemplate {
    [CmdletBinding()] param()
    Assert-MockTenant
    Add-MockCall 'Get-MgBetaDirectorySettingTemplate'
    foreach ($t in $global:MockTenant.directorySettingTemplates) { [pscustomobject]@{ Id = $t.id; DisplayName = $t.displayName } }
}

function Get-MgBetaDirectorySetting {
    [CmdletBinding()] param()
    Assert-MockTenant
    Add-MockCall 'Get-MgBetaDirectorySetting'
    foreach ($e in @($global:MockTenant.directorySettings)) {
        $vorlage = @($global:MockTenant.directorySettingTemplates | Where-Object { $_.id -eq $e.templateId })
        [pscustomobject]@{ Id = $e.id; TemplateId = $e.templateId
                           DisplayName = $(if ($vorlage.Count -gt 0) { $vorlage[0].displayName } else { $null })
                           Values = @($e.values | ForEach-Object { [pscustomobject]@{ Name = $_.name; Value = $_.value } }) }
    }
}

function New-MgBetaDirectorySetting {
    [CmdletBinding()] param([hashtable]$BodyParameter)
    Add-MockCall 'New-MgBetaDirectorySetting' @{ Body = $BodyParameter }
    [pscustomobject]@{ Id = 'einstellung-neu-1' }
}

function Update-MgBetaDirectorySetting {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$DirectorySettingId, $Values, [hashtable]$BodyParameter)
    Add-MockCall 'Update-MgBetaDirectorySetting' @{ Id = $DirectorySettingId; Values = $Values; Body = $BodyParameter }
}
function Update-MgUser {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$UserId, [switch]$AccountEnabled)
    Add-MockCall 'Update-MgUser' @{ UserId = $UserId; AccountEnabled = [bool]$AccountEnabled }
}

function Get-MockLizenzFehler {
    param([string]$Name)
    if (@($global:MockTenant.fehlendeLizenz) -contains $Name) {
        throw "Mock: Der Mandant hat keine Lizenz fuer diese Funktion ($Name).`nZweite Zeile des Fehlers."
    }
}
function Get-MgEntitlementManagementCatalog { [CmdletBinding()] param([switch]$All); Add-MockCall 'Get-MgEntitlementManagementCatalog'; Get-MockLizenzFehler 'Kataloge'; 1..[int]$global:MockTenant.anzahl.kataloge | ForEach-Object { [pscustomobject]@{ Id = "k$_" } } }
function Get-MgIdentityGovernanceAccessReviewDefinition { [CmdletBinding()] param([switch]$All); Add-MockCall 'Get-MgIdentityGovernanceAccessReviewDefinition'; Get-MockLizenzFehler 'Zugriffsueberpruefungen'; if ([int]$global:MockTenant.anzahl.ueberpruefungen -gt 0) { 1..[int]$global:MockTenant.anzahl.ueberpruefungen | ForEach-Object { [pscustomobject]@{ Id = "r$_" } } } }
function Get-MgIdentityGovernanceLifecycleWorkflow { [CmdletBinding()] param([switch]$All); Add-MockCall 'Get-MgIdentityGovernanceLifecycleWorkflow'; Get-MockLizenzFehler 'Lifecycle Workflows'; if ([int]$global:MockTenant.anzahl.workflows -gt 0) { 1..[int]$global:MockTenant.anzahl.workflows | ForEach-Object { [pscustomobject]@{ Id = "w$_" } } } }
function Get-MgEntitlementManagementAccessPackage {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgEntitlementManagementAccessPackage' @{ Filter = $Filter }
    Get-MockLizenzFehler 'Zugriffspakete'
    $alle = @($global:MockTenant.accessPackages)
    if ($Filter -match "^displayName eq '(.+)'$") { $n = $Matches[1]; $alle = @($alle | Where-Object { $_.displayName -eq $n }) }
    elseif ($Filter) { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($p in $alle) { [pscustomobject]@{ Id = $p.id; DisplayName = $p.displayName } }
}
function New-MgEntitlementManagementAssignmentPolicy { [CmdletBinding()] param([hashtable]$BodyParameter); Add-MockCall 'New-MgEntitlementManagementAssignmentPolicy' @{ Body = $BodyParameter }; [pscustomobject]@{ Id = 'zp-1' } }
function Get-MgEntitlementManagementAssignment {
    [CmdletBinding()] param([string]$Filter, [string]$ExpandProperty, [switch]$All)
    Add-MockCall 'Get-MgEntitlementManagementAssignment' @{ Filter = $Filter }
    foreach ($z in @($global:MockTenant.assignments)) { [pscustomobject]@{ Id = $z.id; Target = [pscustomobject]@{ DisplayName = $z.name; PrincipalName = $z.upn } } }
}
function New-MgIdentityGovernanceAccessReviewDefinition { [CmdletBinding()] param([hashtable]$BodyParameter); Add-MockCall 'New-MgIdentityGovernanceAccessReviewDefinition' @{ Body = $BodyParameter }; [pscustomobject]@{ Id = 'ar-1' } }
function New-MgIdentityGovernanceLifecycleWorkflow { [CmdletBinding()] param([hashtable]$BodyParameter); Add-MockCall 'New-MgIdentityGovernanceLifecycleWorkflow' @{ Body = $BodyParameter }; [pscustomobject]@{ Id = 'wf-1' } }
function Get-MgIdentityGovernanceLifecycleWorkflowRun { [CmdletBinding()] param([string]$WorkflowId); Add-MockCall 'Get-MgIdentityGovernanceLifecycleWorkflowRun' @{ WorkflowId = $WorkflowId } }
function Get-MgRoleManagementDirectoryRoleDefinition {
    [CmdletBinding()] param([string]$Filter)
    Add-MockCall 'Get-MgRoleManagementDirectoryRoleDefinition' @{ Filter = $Filter }
    if ($Filter -match "^displayName eq '(.+)'$") { [pscustomobject]@{ Id = "rolle-$($Matches[1] -replace ' ','-')"; DisplayName = $Matches[1] } } else { throw "Mock: Filter nicht bekannt: $Filter" }
}
function New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest { [CmdletBinding()] param([hashtable]$BodyParameter); Add-MockCall 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest' @{ Body = $BodyParameter }; [pscustomobject]@{ Id = 'pim-1' } }
function New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest { [CmdletBinding()] param([hashtable]$BodyParameter); Add-MockCall 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest' @{ Body = $BodyParameter }; [pscustomobject]@{ Id = 'pim-2' } }

function Get-MgAuditLogSignIn {
    [CmdletBinding()] param([string]$Filter, [int]$Top)
    Assert-MockTenant
    Add-MockCall 'Get-MgAuditLogSignIn' @{ Filter = $Filter; Top = $Top }
    foreach ($a in @($global:MockTenant.signIns) | Select-Object -First $(if ($Top) { $Top } else { 1000 })) {
        [pscustomobject]@{
            CreatedDateTime = (Get-Date).AddHours(-[int]$a.hoursAgo); AppDisplayName = $a.app
            Status = [pscustomobject]@{ ErrorCode = [int]$a.errorCode; FailureReason = $a.reason }
            ConditionalAccessStatus = $a.ca
        }
    }
}
function Get-MgAuditLogDirectoryAudit {
    [CmdletBinding()] param([string]$Filter, [int]$Top)
    Assert-MockTenant
    Add-MockCall 'Get-MgAuditLogDirectoryAudit' @{ Filter = $Filter; Top = $Top }
    foreach ($a in @($global:MockTenant.directoryAudits) | Select-Object -First $(if ($Top) { $Top } else { 1000 })) {
        [pscustomobject]@{
            ActivityDateTime = (Get-Date).AddHours(-[int]$a.hoursAgo); ActivityDisplayName = $a.activity; Result = $a.result
            InitiatedBy = [pscustomobject]@{ User = [pscustomobject]@{ UserPrincipalName = $a.by } }
        }
    }
}
