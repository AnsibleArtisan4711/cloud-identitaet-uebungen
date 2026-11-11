# Mock-GraphSecurity.ps1 - simulierte Microsoft-Graph-Cmdlets für Modul 08 (Security Governance).
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (stellt Add-MockCall / Get-MockCall bereit). Danach:
#   Initialize-MockSecurity tools/fixtures/sicherheit-klein.json
#
# ACHTUNG: Diese Datei ÜBERSCHREIBT Funktionen aus Mock-MgGraph.ps1, weil Modul 08 andere Daten braucht:
#   Connect-MgGraph (ohne Mandantendaten), Get-MgUser, Get-MgGroup, Get-MgGroupMember, Get-MgIdentityConditionalAccessPolicy,
#   Get-MgAuditLogSignIn. Laden Sie sie deshalb nur in den Tests von Modul 08.
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#   - Unbekannte Filter lösen einen Fehler aus; es werden nur die Filter nachgebildet, die die Skripte verwenden.
#   - "Nicht gefunden" wird mit Write-Error gemeldet (nicht terminierend), damit -ErrorAction SilentlyContinue wirkt.
#   - Neu angelegte Richtlinien werden nur im Speicher abgelegt. Ob Graph den Inhalt eines Aufrufs akzeptiert, wird nicht geprüft.
#   - Zeitwerte (CreatedDateTime) sind DateTimeOffset in UTC, wie in den Antworten des Graph-SDK.

function Initialize-MockSecurity {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockSec = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Copy-SecBound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }
function ConvertTo-SecTime { param([double]$HoursAgo) [datetimeoffset]::UtcNow.AddHours(-$HoursAgo) }

function Connect-MgGraph {
    [CmdletBinding()]
    param([string[]]$Scopes, [switch]$NoWelcome, [string]$TenantId, [string]$ClientId, [string]$CertificateThumbprint)
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}

# --- Secure Score ---
function Get-MgSecuritySecureScore {
    [CmdletBinding()] param([int]$Top, [switch]$All)
    Add-MockCall 'Get-MgSecuritySecureScore' (Copy-SecBound $PSBoundParameters)
    $liste = @($global:MockSec.secureScores | Sort-Object { [double]$_.daysAgo })
    if ($Top) { $liste = @($liste | Select-Object -First $Top) }
    foreach ($s in $liste) {
        [pscustomobject]@{ CreatedDateTime = ([datetimeoffset]::new([datetimeoffset]::UtcNow.Date.AddDays(-[double]$s.daysAgo).AddHours(12), [timespan]::Zero))
                           CurrentScore = [double]$s.current; MaxScore = [double]$s.max }
    }
}

# --- Conditional Access ---
function ConvertTo-SecPolicy {
    param($P)
    [pscustomobject]@{ Id = $P.id; DisplayName = $P.name; State = $P.state
        Conditions = [pscustomobject]@{ Users = [pscustomobject]@{ IncludeUsers = @('All'); ExcludeUsers = @($P.excludeUsers); ExcludeGroups = @($P.excludeGroups); ExcludeRoles = @($P.excludeRoles) } } }
}
function Get-MgIdentityConditionalAccessPolicy {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgIdentityConditionalAccessPolicy' (Copy-SecBound $PSBoundParameters)
    $liste = @($global:MockSec.caPolicies)
    if ($Filter) {
        if ($Filter -notmatch "^displayName eq '(.*)'$") { throw "Mock: Filter nicht bekannt: $Filter" }
        $n = $Matches[1]; $liste = @($liste | Where-Object { $_.name -eq $n })
    }
    foreach ($p in $liste) { ConvertTo-SecPolicy $p }
}
function New-MgIdentityConditionalAccessPolicy {
    [CmdletBinding()] param([hashtable]$BodyParameter)
    Add-MockCall 'New-MgIdentityConditionalAccessPolicy' @{ BodyParameter = $BodyParameter }
    $p = [pscustomobject]@{ id = 'p-neu-' + (@($global:MockSec.caPolicies).Count + 1); name = $BodyParameter.displayName; state = $BodyParameter.state
        excludeUsers = @(); excludeGroups = @($BodyParameter.conditions.users.excludeGroups); excludeRoles = @() }
    $global:MockSec.caPolicies = @($global:MockSec.caPolicies) + $p
    ConvertTo-SecPolicy $p
}

# --- Benutzer, Gruppen, Rollen ---
function Get-MgUser {
    [CmdletBinding()] param([string]$Filter, [string]$UserId, [switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgUser' @{ Filter = $Filter; Property = $Property; UserId = $UserId }
    $u = @($global:MockSec.users | Where-Object { $_.id -eq $UserId -or $_.upn -eq $UserId })
    if ($u.Count -eq 0) { Write-Error "Mock: Benutzer '$UserId' nicht gefunden (kein Benutzerobjekt)."; return }
    $voll = [ordered]@{ Id = $u[0].id; DisplayName = $u[0].displayName; UserPrincipalName = $u[0].upn; UserType = $u[0].userType
                        AccountEnabled = [bool]$u[0].accountEnabled; Mail = $u[0].mail }
    if (-not $Property) { return [pscustomobject]$voll }
    $teil = [ordered]@{ Id = $u[0].id }
    foreach ($p in $Property) { if ($voll.Contains($p)) { $teil[$p] = $voll[$p] } }
    [pscustomobject]$teil
}
function Get-MgGroup {
    [CmdletBinding()] param([string]$Filter, [string]$GroupId, [switch]$All)
    Add-MockCall 'Get-MgGroup' @{ Filter = $Filter; GroupId = $GroupId }
    $liste = @($global:MockSec.groups)
    if ($GroupId) {
        $g = @($liste | Where-Object { $_.id -eq $GroupId })
        if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
        return [pscustomobject]@{ Id = $g[0].id; DisplayName = $g[0].name }
    }
    if ($Filter) {
        if ($Filter -match "^startswith\(displayName,\s*'(.*)'\)$") { $pre = $Matches[1]; $liste = @($liste | Where-Object { $_.name.StartsWith($pre, [System.StringComparison]::OrdinalIgnoreCase) }) }
        else { throw "Mock: Filter nicht bekannt: $Filter" }
    }
    foreach ($g in $liste) { [pscustomobject]@{ Id = $g.id; DisplayName = $g.name } }
}
function Get-MgGroupMember {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [switch]$All)
    Add-MockCall 'Get-MgGroupMember' @{ GroupId = $GroupId }
    $g = @($global:MockSec.groups | Where-Object { $_.id -eq $GroupId })
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    foreach ($m in @($g[0].members)) { [pscustomobject]@{ Id = $m } }
}
function Get-MgDirectoryRole {
    [CmdletBinding()] param([string]$Filter)
    Add-MockCall 'Get-MgDirectoryRole' @{ Filter = $Filter }
    if ($Filter -ne "displayName eq 'Global Administrator'") { throw "Mock: Filter nicht bekannt: $Filter" }
    if ($global:MockSec.directoryRole) { [pscustomobject]@{ Id = $global:MockSec.directoryRole.id; DisplayName = $global:MockSec.directoryRole.displayName } }
}
function Get-MgDirectoryRoleMember {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$DirectoryRoleId, [switch]$All)
    Add-MockCall 'Get-MgDirectoryRoleMember' @{ DirectoryRoleId = $DirectoryRoleId }
    if ($DirectoryRoleId -ne $global:MockSec.directoryRole.id) { Write-Error 'Mock: Rolle nicht gefunden.'; return }
    foreach ($m in @($global:MockSec.directoryRole.members)) { [pscustomobject]@{ Id = $m } }
}

# --- Berichte ---
function Get-MgReportAuthenticationMethodUserRegistrationDetail {
    [CmdletBinding()] param([switch]$All)
    Add-MockCall 'Get-MgReportAuthenticationMethodUserRegistrationDetail'
    foreach ($r in @($global:MockSec.registration)) {
        [pscustomobject]@{ Id = $r.id; UserPrincipalName = $r.upn; IsAdmin = [bool]$r.isAdmin; IsMfaRegistered = [bool]$r.isMfaRegistered
                           IsPasswordlessCapable = [bool]$r.isPasswordlessCapable; DefaultMfaMethod = $r.defaultMfaMethod }
    }
}

# --- Defender-Warnungen ---
function Get-MgSecurityAlertV2 {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgSecurityAlertV2' (Copy-SecBound $PSBoundParameters)
    if ($Filter -notmatch '^createdDateTime ge (\S+)$') { throw "Mock: Filter nicht bekannt: $Filter" }
    $seit = [datetime]::ParseExact($Matches[1], "yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    foreach ($a in @($global:MockSec.alerts)) {
        $zeit = ConvertTo-SecTime $a.hoursAgo
        if ($zeit.UtcDateTime -lt $seit) { continue }
        [pscustomobject]@{ Id = "a-$($a.hoursAgo)"; CreatedDateTime = $zeit; Severity = $a.severity; ServiceSource = $a.source; Status = $a.status; Title = $a.title }
    }
}

# --- Intune ---
function Invoke-MgGraphRequest {
    [CmdletBinding()] param([string]$Method, [string]$Uri, $Body, [string]$ContentType)
    Add-MockCall 'Invoke-MgGraphRequest' @{ Method = $Method; Uri = $Uri; Body = $Body; ContentType = $ContentType }
    if ($Method -ne 'POST' -or $Uri -ne 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies') {
        Write-Error "Mock: Aufruf nicht bekannt: $Method $Uri"; return
    }
    $inhalt = $Body | ConvertFrom-Json
    @{ displayName = $inhalt.displayName; id = '00000000-0000-0000-0000-00000000c0de' }
}
function Get-MgDeviceManagementManagedDevice {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgDeviceManagementManagedDevice' (Copy-SecBound $PSBoundParameters)
    if ($Filter -notmatch "^complianceState eq '(\w+)'$") { throw "Mock: Filter nicht bekannt: $Filter" }
    $status = $Matches[1]
    foreach ($d in @($global:MockSec.devices | Where-Object { $_.state -eq $status })) {
        [pscustomobject]@{ DeviceName = $d.name; UserPrincipalName = $d.upn; OperatingSystem = $d.os; OsVersion = $d.osVersion
                           LastSyncDateTime = (ConvertTo-SecTime ([double]$d.lastSyncDaysAgo * 24)) }
    }
}

# --- Anmeldeprotokoll ---
function Get-MgAuditLogSignIn {
    [CmdletBinding()] param([string]$Filter, [int]$Top)
    Add-MockCall 'Get-MgAuditLogSignIn' @{ Filter = $Filter; Top = $Top }
    if ($Filter -notmatch "^userPrincipalName eq '(.*)' and createdDateTime ge (\S+)$") { throw "Mock: Filter nicht bekannt: $Filter" }
    $upn = $Matches[1]
    $seit = [datetime]::ParseExact($Matches[2], "yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    $liste = foreach ($s in @($global:MockSec.signIns | Sort-Object { [double]$_.hoursAgo })) {
        if ($s.upn -ne $upn) { continue }
        $zeit = ConvertTo-SecTime $s.hoursAgo
        if ($zeit.UtcDateTime -lt $seit) { continue }
        [pscustomobject]@{ CreatedDateTime = $zeit; AppDisplayName = $s.app; ConditionalAccessStatus = $s.ca
            Status = [pscustomobject]@{ ErrorCode = [int]$s.errorCode; FailureReason = $s.reason }
            AppliedConditionalAccessPolicies = @($s.policies | ForEach-Object { [pscustomobject]@{ DisplayName = $_.name; Result = $_.result } }) }
    }
    if ($Top) { $liste = @($liste) | Select-Object -First $Top }
    $liste
}
