# Mock-Provisioning.ps1 - simulierte Graph-Cmdlets für Modul 10 (Provisioning, Standards und Lifecycle Automation).
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (Add-MockCall / Get-MockCall). Danach:
#   Initialize-MockProvisioning tools/fixtures/provisioning-klein.json
#
# ACHTUNG: Diese Datei ÜBERSCHREIBT Funktionen aus Mock-MgGraph.ps1 (Connect-MgGraph, Get-MgUser, Get-MgGroup,
# Get-MgGroupOwner, Get-MgGroupMember, Invoke-MgGraphRequest, New-MgGroup, Remove-MgGroup, Get-MgTeamChannel u. a.).
# Laden Sie sie deshalb nur in den Tests von Modul 10.
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#   - Unbekannte Filter lösen einen Fehler aus; nachgebildet sind nur die Filter, die die Skripte verwenden.
#   - "Nicht gefunden" wird mit Write-Error gemeldet (nicht terminierend), damit -ErrorAction SilentlyContinue wirkt.
#   - Die Verzögerung nach dem Anlegen einer Gruppe (404 beim Erzeugen des Teams) wird nur über die Option teamFailures
#     nachgestellt: So viele Aufrufe von PUT .../groups/{id}/team schlagen fehl (Status teamFailureStatus), danach klappt es.
#   - Eine gelöschte Gruppe bleibt im Speicher mit deleted = true; die 30-Tage-Frist wird nicht simuliert.

function Initialize-MockProvisioning {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockProv = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Copy-ProvBound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }
function Find-ProvGroup { param([string]$Id, [switch]$MitGeloeschten) @($global:MockProv.groups | Where-Object { $_.id -eq $Id -and ($MitGeloeschten -or -not $_.deleted) }) }
function ConvertTo-ProvGroup { param($G) [pscustomobject]@{ Id = $G.id; DisplayName = $G.name; Description = $G.description; Visibility = $G.visibility; MailNickname = $G.nickname; CreatedDateTime = [datetimeoffset]::UtcNow.AddDays(-100) } }
function New-ProvHttpException {
    # Ausnahme mit Response.StatusCode (und bei 429 mit Retry-After), wie sie Invoke-MgGraphRequest in PowerShell 7 liefert
    param([int]$Status, [string]$Message, $RetryAfter)
    $ex = [System.Exception]::new($Message)
    $kopfzeilen = @()
    if ($null -ne $RetryAfter) { $kopfzeilen = @([pscustomobject]@{ Key = 'Retry-After'; Value = @([string]$RetryAfter) }) }
    $antwort = [pscustomobject]@{ StatusCode = $Status; Headers = $kopfzeilen }
    Add-Member -InputObject $ex -NotePropertyName Response -NotePropertyValue $antwort
    $ex
}

function Connect-MgGraph {
    [CmdletBinding()]
    param([string[]]$Scopes, [switch]$NoWelcome, [string]$TenantId, [string]$ClientId, [string]$CertificateThumbprint)
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}

# --- Benutzer ---
function Get-MgUser {
    [CmdletBinding()] param([string]$UserId, [string[]]$Property)
    Add-MockCall 'Get-MgUser' @{ UserId = $UserId; Property = $Property }
    $u = @($global:MockProv.users | Where-Object { $_.id -eq $UserId -or $_.upn -eq $UserId })
    if ($u.Count -eq 0) { Write-Error "Mock: Benutzer '$UserId' nicht gefunden."; return }
    [pscustomobject]@{ Id = $u[0].id; UserPrincipalName = $u[0].upn; AccountEnabled = [bool]$u[0].enabled; Department = $u[0].department }
}

# --- Gruppen ---
function Get-MgGroup {
    [CmdletBinding()] param([string]$Filter, [switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgGroup' @{ Filter = $Filter; Property = $Property }
    $liste = @($global:MockProv.groups | Where-Object { -not $_.deleted })
    if ($Filter -match "^mailNickname eq '(.*)'$") { $n = $Matches[1]; $liste = @($liste | Where-Object { $_.nickname -eq $n }) }
    elseif ($Filter -eq "groupTypes/any(c:c eq 'Unified')") { $liste = @($liste | Where-Object { $_.unified }) }
    else { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($g in $liste) { ConvertTo-ProvGroup $g }
}
function New-MgGroup {
    [CmdletBinding()]
    param([string]$DisplayName, [string]$MailNickname, [string]$Description, [string[]]$GroupTypes, [switch]$MailEnabled,
          [switch]$SecurityEnabled, [string]$Visibility, [hashtable]$AdditionalProperties)
    $p = Copy-ProvBound $PSBoundParameters
    $p['MailEnabled'] = [bool]$MailEnabled; $p['SecurityEnabled'] = [bool]$SecurityEnabled
    Add-MockCall 'New-MgGroup' $p
    if (@($global:MockProv.groups | Where-Object { $_.nickname -eq $MailNickname }).Count -gt 0) { Write-Error "Mock: Nickname '$MailNickname' ist schon vergeben."; return }
    $id = 'g-neu-' + (@($global:MockProv.groups).Count + 1)
    $eigner = @()
    if ($AdditionalProperties -and $AdditionalProperties['owners@odata.bind']) { $eigner = @($AdditionalProperties['owners@odata.bind'] | ForEach-Object { ($_ -split '/')[-1] }) }
    $neu = [pscustomobject]@{ id = $id; name = $DisplayName; nickname = $MailNickname; description = $Description; unified = ($GroupTypes -contains 'Unified')
                              owners = $eigner; members = $eigner; deleted = $false; deletedDaysAgo = $null; visibility = $Visibility }
    $global:MockProv.groups = @($global:MockProv.groups) + $neu
    ConvertTo-ProvGroup $neu
}
function Remove-MgGroup {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId)
    Add-MockCall 'Remove-MgGroup' @{ GroupId = $GroupId }
    $g = @(Find-ProvGroup $GroupId)
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    $g[0].deleted = $true; $g[0].deletedDaysAgo = 0
}
function Get-MgDirectoryDeletedItemAsGroup {
    [CmdletBinding()] param([switch]$All)
    Add-MockCall 'Get-MgDirectoryDeletedItemAsGroup'
    foreach ($g in @($global:MockProv.groups | Where-Object { $_.deleted })) {
        [pscustomobject]@{ Id = $g.id; DisplayName = $g.name; DeletedDateTime = [datetimeoffset]::UtcNow.AddDays(-[double]$g.deletedDaysAgo) }
    }
}
function Restore-MgDirectoryDeletedItem {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$DirectoryObjectId)
    Add-MockCall 'Restore-MgDirectoryDeletedItem' @{ DirectoryObjectId = $DirectoryObjectId }
    $g = @(Find-ProvGroup $DirectoryObjectId -MitGeloeschten | Where-Object { $_.deleted })
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$DirectoryObjectId' nicht unter den gelöschten Objekten."; return }
    $g[0].deleted = $false; $g[0].deletedDaysAgo = $null
    [pscustomobject]@{ Id = $g[0].id }
}
function Get-MgGroupOwner {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId)
    Add-MockCall 'Get-MgGroupOwner' @{ GroupId = $GroupId }
    $g = @(Find-ProvGroup $GroupId)
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    foreach ($o in @($g[0].owners)) { [pscustomobject]@{ Id = $o } }
}
function Get-MgGroupMember {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId, [int]$Top, [switch]$All)
    Add-MockCall 'Get-MgGroupMember' @{ GroupId = $GroupId; Top = $Top }
    $g = @(Find-ProvGroup $GroupId)
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    $m = @($g[0].members)
    if ($Top) { $m = @($m | Select-Object -First $Top) }
    foreach ($x in $m) { [pscustomobject]@{ Id = $x } }
}

# --- Teams ---
function Get-MgTeamChannel {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$TeamId)
    Add-MockCall 'Get-MgTeamChannel' @{ TeamId = $TeamId }
    if (-not $global:MockProv.teams.PSObject.Properties[$TeamId]) { Write-Error "Mock: Team '$TeamId' nicht gefunden."; return }
    foreach ($k in @($global:MockProv.teams.$TeamId)) { [pscustomobject]@{ DisplayName = $k } }
}
function New-MgTeamChannel {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$TeamId, [Parameter(Mandatory)][string]$DisplayName, [string]$Description)
    Add-MockCall 'New-MgTeamChannel' @{ TeamId = $TeamId; DisplayName = $DisplayName; Description = $Description }
    if (-not $global:MockProv.teams.PSObject.Properties[$TeamId]) { Write-Error "Mock: Team '$TeamId' nicht gefunden."; return }
    $global:MockProv.teams.$TeamId = @($global:MockProv.teams.$TeamId) + $DisplayName
    [pscustomobject]@{ DisplayName = $DisplayName }
}
function Invoke-MgArchiveTeam {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$TeamId)
    Add-MockCall 'Invoke-MgArchiveTeam' @{ TeamId = $TeamId }
    if (@($global:MockProv.options.archiveFailIds) -contains $TeamId) { Write-Error "Mock: Team '$TeamId' kann nicht archiviert werden (kein Team)."; return }
    $global:MockProv.archived = @($global:MockProv.archived) + $TeamId
}

# --- Ablaufrichtlinie ---
function Get-MgGroupLifecyclePolicy {
    [CmdletBinding()] param()
    Add-MockCall 'Get-MgGroupLifecyclePolicy'
    foreach ($p in @($global:MockProv.lifecyclePolicies)) {
        [pscustomobject]@{ Id = $p.id; GroupLifetimeInDays = $p.days; ManagedGroupTypes = $p.types; AlternateNotificationEmails = $p.mails; Gruppen = @($p.groups) }
    }
}
function New-MgGroupLifecyclePolicy {
    [CmdletBinding()] param([int]$GroupLifetimeInDays, [string]$ManagedGroupTypes, [string]$AlternateNotificationEmails)
    Add-MockCall 'New-MgGroupLifecyclePolicy' (Copy-ProvBound $PSBoundParameters)
    $p = [pscustomobject]@{ id = 'lp-1'; days = $GroupLifetimeInDays; types = $ManagedGroupTypes; mails = $AlternateNotificationEmails; groups = @() }
    $global:MockProv.lifecyclePolicies = @($global:MockProv.lifecyclePolicies) + $p
    [pscustomobject]@{ Id = $p.id; GroupLifetimeInDays = $p.days; ManagedGroupTypes = $p.types; AlternateNotificationEmails = $p.mails }
}
function Add-MgGroupLifecyclePolicyGroup {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupLifecyclePolicyId, [Parameter(Mandatory)][string]$GroupId)
    Add-MockCall 'Add-MgGroupLifecyclePolicyGroup' @{ GroupLifecyclePolicyId = $GroupLifecyclePolicyId; GroupId = $GroupId }
    $p = @($global:MockProv.lifecyclePolicies | Where-Object { $_.id -eq $GroupLifecyclePolicyId })
    if ($p.Count -eq 0) { Write-Error "Mock: Richtlinie '$GroupLifecyclePolicyId' nicht gefunden."; return }
    if (@(Find-ProvGroup $GroupId).Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    $p[0].groups = @($p[0].groups) + $GroupId
}

# --- Rohe Graph-Aufrufe (Team aus Gruppe erzeugen) ---
function Invoke-MgGraphRequest {
    [CmdletBinding()] param([string]$Method, [string]$Uri, $Body, [string]$ContentType)
    Add-MockCall 'Invoke-MgGraphRequest' @{ Method = $Method; Uri = $Uri; Body = $Body; ContentType = $ContentType }
    if ($Method -eq 'PUT' -and $Uri -match '^https://graph\.microsoft\.com/v1\.0/groups/([^/]*)/team$') {
        $o = $global:MockProv.options
        if ([int]$o.teamFailures -gt 0) {
            $o.teamFailures = [int]$o.teamFailures - 1
            $status = [int]$o.teamFailureStatus
            throw (New-ProvHttpException $status "Mock: Antwort $status beim Erzeugen des Teams" $o.teamFailureRetryAfter)
        }
        return @{ id = $Matches[1] }
    }
    Write-Error "Mock: Aufruf nicht bekannt: $Method $Uri"
}
