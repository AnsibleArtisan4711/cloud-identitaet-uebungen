# Mock-Automation.ps1 - Simulation für die Tests von Modul 11 (Automation, Graph API und Policy-as-Code).
# Alle Daten sind erfunden (tools/fixtures/automation-klein.json). Es wird nichts im Netz aufgerufen.
#
# Voraussetzung: Mock-MgGraph.ps1 ist geladen (liefert Add-MockCall / Get-MockCall).
# ACHTUNG: Diese Datei definiert Connect-MgGraph, Connect-ExchangeOnline, Get-MgGroup, Update-MgGroup, Get-MgGroupOwner,
#   Get-MgUser, New-MgGroupOwnerByRef, Get-/Update-MgGroupLifecyclePolicy, Get-MgIdentityConditionalAccessPolicy,
#   Get-TransportRule, Get-MgServicePrincipal, Get-MgServicePrincipalAppRoleAssignment, Invoke-MgGraphRequest und
#   Invoke-RestMethod neu und überschreibt gleichnamige Funktionen anderer Mocks. Laden Sie sie nur in den Tests von Modul 11.
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#   - Invoke-MgGraphRequest kennt nur: GET .../groups?... (seitenweise, Seitengröße = options.pageSize, Fortsetzung über
#     "@odata.nextLink") und POST .../$batch (höchstens 20 Anfragen, sonst Fehler). Alles andere löst einen Fehler aus.
#   - Antworten sind Hashtables, wie sie Invoke-MgGraphRequest in PowerShell 7 liefert; ob Windows PowerShell 5.1 dasselbe
#     liefert, ist nicht geprüft.
#   - "Nicht gefunden" und Lesefehler werden mit Write-Error gemeldet (nicht terminierend), damit -ErrorAction wirkt.
#   - Das Ticket-System (Invoke-RestMethod) ist stark vereinfacht und entspricht keinem echten Produkt.

function Initialize-MockAutomation {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockAut = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Copy-AutBound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }
function Find-AutGroup { param([string]$Id) @($global:MockAut.groups | Where-Object { $_.id -eq $Id }) }
function ConvertTo-AutGroup { param($G) [pscustomobject]@{ Id = $G.id; DisplayName = $G.name; Description = $G.description } }

function Connect-MgGraph {
    [CmdletBinding()] param([string[]]$Scopes, [switch]$NoWelcome, [string]$TenantId, [string]$ClientId, [string]$CertificateThumbprint)
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}
function Connect-ExchangeOnline { [CmdletBinding()] param([switch]$ShowBanner); Add-MockCall 'Connect-ExchangeOnline' }

# --- Gruppen ---
function Get-MgGroup {
    [CmdletBinding()] param([string]$Filter, [switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgGroup' @{ Filter = $Filter; Property = $Property }
    if ($Filter -ne "groupTypes/any(c:c eq 'Unified')") { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($g in @($global:MockAut.groups | Where-Object { $_.unified })) { ConvertTo-AutGroup $g }
}
function Update-MgGroup {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [string]$Description)
    Add-MockCall 'Update-MgGroup' @{ GroupId = $GroupId; Description = $Description }
    if (@($global:MockAut.options.updateFailIds) -contains $GroupId) { throw "Mock: Aktualisierung von '$GroupId' abgelehnt." }
    $g = Find-AutGroup $GroupId
    if ($g.Count -eq 0) { throw "Mock: Gruppe '$GroupId' nicht gefunden." }
    $g[0].description = $Description
}
function Get-MgGroupOwner {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [switch]$All)
    Add-MockCall 'Get-MgGroupOwner' @{ GroupId = $GroupId }
    $g = Find-AutGroup $GroupId
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    foreach ($o in @($g[0].owners)) { [pscustomobject]@{ Id = $o } }
}
function New-MgGroupOwnerByRef {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [hashtable]$BodyParameter)
    Add-MockCall 'New-MgGroupOwnerByRef' @{ GroupId = $GroupId; BodyParameter = $BodyParameter }
    $g = Find-AutGroup $GroupId
    if ($g.Count -eq 0) { throw "Mock: Gruppe '$GroupId' nicht gefunden." }
    $g[0].owners = @($g[0].owners) + (($BodyParameter['@odata.id'] -split '/')[-1])
}
function Get-MgUser {
    [CmdletBinding()] param([string]$UserId)
    Add-MockCall 'Get-MgUser' @{ UserId = $UserId }
    $u = @($global:MockAut.users | Where-Object { $_.id -eq $UserId -or $_.upn -eq $UserId })
    if ($u.Count -eq 0) { Write-Error "Mock: Benutzer '$UserId' nicht gefunden."; return }
    [pscustomobject]@{ Id = $u[0].id; UserPrincipalName = $u[0].upn }
}

# --- Ablaufrichtlinie ---
function ConvertTo-AutPolicy { param($P) [pscustomobject]@{ Id = $P.id; GroupLifetimeInDays = [int]$P.days; ManagedGroupTypes = $P.types; AlternateNotificationEmails = $P.emails } }
function Get-MgGroupLifecyclePolicy {
    [CmdletBinding()] param([string]$GroupLifecyclePolicyId)
    Add-MockCall 'Get-MgGroupLifecyclePolicy' @{ GroupLifecyclePolicyId = $GroupLifecyclePolicyId }
    $liste = @($global:MockAut.lifecyclePolicies)
    if ($GroupLifecyclePolicyId) {
        $liste = @($liste | Where-Object { $_.id -eq $GroupLifecyclePolicyId })
        if ($liste.Count -eq 0) { Write-Error "Mock: Richtlinie '$GroupLifecyclePolicyId' nicht gefunden."; return }
    }
    foreach ($p in $liste) { ConvertTo-AutPolicy $p }
}
function Update-MgGroupLifecyclePolicy {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupLifecyclePolicyId, [int]$GroupLifetimeInDays)
    Add-MockCall 'Update-MgGroupLifecyclePolicy' @{ GroupLifecyclePolicyId = $GroupLifecyclePolicyId; GroupLifetimeInDays = $GroupLifetimeInDays }
    if ([int]$global:MockAut.options.lifecycleUpdateFailures -gt 0) {
        $global:MockAut.options.lifecycleUpdateFailures = [int]$global:MockAut.options.lifecycleUpdateFailures - 1
        throw 'Mock: Richtlinie kann gerade nicht geändert werden.'
    }
    if ($global:MockAut.options.lifecycleUpdateIgnored) { return }
    $p = @($global:MockAut.lifecyclePolicies | Where-Object { $_.id -eq $GroupLifecyclePolicyId })
    if ($p.Count -eq 0) { throw "Mock: Richtlinie '$GroupLifecyclePolicyId' nicht gefunden." }
    $p[0].days = $GroupLifetimeInDays
}

# --- Konfigurationsexport ---
function Get-MgIdentityConditionalAccessPolicy {
    [CmdletBinding()] param([switch]$All)
    Add-MockCall 'Get-MgIdentityConditionalAccessPolicy'
    foreach ($p in @($global:MockAut.caPolicies)) {
        [pscustomobject]@{ Id = $p.Id; DisplayName = $p.DisplayName; State = $p.State; ModifiedDateTime = $p.ModifiedDateTime; Grant = $p.Grant }
    }
}
function Get-TransportRule {
    [CmdletBinding()] param()
    Add-MockCall 'Get-TransportRule'
    foreach ($r in @($global:MockAut.transportRules)) {
        [pscustomobject]@{ Name = $r.Name; Priority = $r.Priority; State = $r.State; Mode = $r.Mode; Comments = $r.Comments; Description = $r.Description; WhenChanged = $r.WhenChanged }
    }
}

# --- Dienstprinzipale ---
function Get-MgServicePrincipal {
    [CmdletBinding()] param([string]$Filter, [switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgServicePrincipal' @{ Filter = $Filter; Property = $Property }
    $gsp = $global:MockAut.graphServicePrincipal
    if ($Filter) {
        if ($Filter -ne "appId eq '$($gsp.appId)'") { throw "Mock: Filter nicht bekannt: $Filter" }
        [pscustomobject]@{ Id = $gsp.id; DisplayName = $gsp.name; AppId = $gsp.appId
                           AppRoles = @($gsp.appRoles | ForEach-Object { [pscustomobject]@{ Id = $_.id; Value = $_.value } }) }
        return
    }
    [pscustomobject]@{ Id = $gsp.id; DisplayName = $gsp.name; AppId = $gsp.appId }
    foreach ($s in @($global:MockAut.servicePrincipals)) { [pscustomobject]@{ Id = $s.id; DisplayName = $s.name; AppId = $s.appId } }
}
function Get-MgServicePrincipalAppRoleAssignment {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$ServicePrincipalId, [switch]$All)
    Add-MockCall 'Get-MgServicePrincipalAppRoleAssignment' @{ ServicePrincipalId = $ServicePrincipalId }
    $s = @($global:MockAut.servicePrincipals | Where-Object { $_.id -eq $ServicePrincipalId })
    if ($s.Count -eq 0) { return }
    if ($s[0].readFails) { Write-Error "Mock: Zuweisungen von '$ServicePrincipalId' nicht lesbar."; return }
    foreach ($a in @($s[0].assignments)) { [pscustomobject]@{ AppRoleId = $a.role; ResourceId = $a.resource; PrincipalId = $s[0].id } }
}

# --- Graph-Anfragen: Seitenabruf und Batch ---
function Invoke-MgGraphRequest {
    [CmdletBinding()] param([string]$Method, [string]$Uri, $Body, [string]$ContentType)
    Add-MockCall 'Invoke-MgGraphRequest' @{ Method = $Method; Uri = $Uri; Body = $Body; ContentType = $ContentType }
    if ([int]$global:MockAut.options.requestFailures -gt 0) {
        $global:MockAut.options.requestFailures = [int]$global:MockAut.options.requestFailures - 1
        throw 'Mock: Anfrage fehlgeschlagen.'
    }
    if ($Method -eq 'GET' -and $Uri -match '^https://graph\.microsoft\.com/v1\.0/groups\?') {
        $start = 0
        if ($Uri -match 'skiptoken=(\d+)') { $start = [int]$Matches[1] }
        $alle = @($global:MockAut.groups | Where-Object { $_.unified })
        $groesse = [int]$global:MockAut.options.pageSize
        $seite = @($alle | Select-Object -Skip $start -First $groesse)
        $antwort = @{ value = @($seite | ForEach-Object { @{ id = $_.id; displayName = $_.name; createdDateTime = '2026-01-01T00:00:00Z' } }) }
        if ($start + $groesse -lt $alle.Count) { $antwort['@odata.nextLink'] = "https://graph.microsoft.com/v1.0/groups?`$skiptoken=$($start + $groesse)" }
        return $antwort
    }
    if ($Method -eq 'POST' -and $Uri -eq 'https://graph.microsoft.com/v1.0/$batch') {
        $anfragen = @(($Body | ConvertFrom-Json).requests)
        if ($anfragen.Count -gt 20) { throw "Mock: Ein Batch darf höchstens 20 Anfragen enthalten (erhalten: $($anfragen.Count))." }
        $antworten = foreach ($a in $anfragen) {
            if (@($global:MockAut.options.throttleBatchIds) -contains [string]$a.id) { @{ id = [string]$a.id; status = 429; body = @{ error = @{ code = 'TooManyRequests' } } } }
            else { @{ id = [string]$a.id; status = 200; body = @{ value = @() } } }
        }
        return @{ responses = @($antworten) }
    }
    throw "Mock: Anfrage nicht bekannt: $Method $Uri"
}

# --- Ticket-System (stark vereinfacht) ---
function Invoke-RestMethod {
    [CmdletBinding()] param([string]$Method, [string]$Uri, [hashtable]$Headers, [string]$ContentType, $Body)
    Add-MockCall 'Invoke-RestMethod' @{ Method = $Method; Uri = $Uri; Headers = $Headers; ContentType = $ContentType; Body = $Body }
    if ($Method -eq 'GET' -and $Uri -match '/tickets\?externalKey=([^&]+)&status=open$') {
        $k = $Matches[1]
        return [pscustomobject]@{ items = @($global:MockAut.itsm.tickets | Where-Object { $_.externalKey -eq $k -and $_.status -eq 'open' }) }
    }
    if ($Method -eq 'POST' -and $Uri -match '/tickets$') {
        $t = $Body | ConvertFrom-Json
        $neu = [pscustomobject]@{ number = 'INC' + (1000 + @($global:MockAut.itsm.tickets).Count + 1); externalKey = $t.externalKey; status = 'open'; title = $t.title }
        $global:MockAut.itsm.tickets = @($global:MockAut.itsm.tickets) + $neu
        return $neu
    }
    if ($Method -eq 'GET' -and $Uri -match '/changes/([^/]+)$') {
        $c = @($global:MockAut.itsm.changes | Where-Object { $_.number -eq $Matches[1] })
        if ($c.Count -eq 0) { throw "Mock: Change '$($Matches[1])' nicht gefunden (404)." }
        return [pscustomobject]@{ number = $c[0].number; state = $c[0].state }
    }
    throw "Mock: Anfrage nicht bekannt: $Method $Uri"
}
