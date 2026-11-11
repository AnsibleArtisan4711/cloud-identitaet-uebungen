# Mock-SharePoint.ps1 - simulierte Cmdlets der SharePoint Online Management Shell (Microsoft.Online.SharePoint.PowerShell).
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (stellt Add-MockCall / Get-MockCall bereit).
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Get-SPOSite -Filter "Url -like 'x'" wird als Teilzeichenfolgen-Suche nachgebildet. Wie der echte Filter
#     Muster behandelt, ist hier NICHT geprüft.
#   - Get-SPOSite ohne -IncludePersonalSite $true liefert keine persönlichen Websites (wie beim echten Cmdlet angenommen).
#   - Start-Sleep wird überschrieben, damit Tests nicht warten; der Aufruf wird protokolliert.

function Initialize-MockSharePoint {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockSPO = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}

function ConvertTo-MockSite {
    param($S, [switch]$Detailed)
    $o = [ordered]@{
        Url = $S.url; Title = $S.title; Owner = $S.owner; Template = $S.template
        StorageQuota = [int64]$S.storageQuotaMB; StorageUsageCurrent = [int64]$S.storageUsageMB
        SharingCapability = $S.sharingCapability; SensitivityLabel = $S.sensitivityLabel
        LockState = $S.lockState
        LastContentModifiedDate = (Get-Date).AddDays(-[double]$S.lastModifiedDaysAgo)
        HubSiteId = $(if ($S.hubSiteId) { [guid]$S.hubSiteId } else { [guid]::Empty })
    }
    [pscustomobject]$o
}

function Connect-SPOService { [CmdletBinding()] param([Parameter(Mandatory)][string]$Url); Add-MockCall 'Connect-SPOService' @{ Url = $Url } }

function Get-SPOSite {
    [CmdletBinding()]
    param([string]$Identity, $Limit, [string]$Filter, [bool]$IncludePersonalSite = $false, [switch]$Detailed)
    Add-MockCall 'Get-SPOSite' @{ Identity = $Identity; Limit = $Limit; Filter = $Filter; IncludePersonalSite = $IncludePersonalSite; Detailed = [bool]$Detailed }
    $alle = @($global:MockSPO.sites)
    if ($Identity) {
        $treffer = @($alle | Where-Object { $_.url -eq $Identity })
        if ($treffer.Count -eq 0) { Write-Error "Mock: Website nicht gefunden: $Identity"; return }
        return (ConvertTo-MockSite $treffer[0] -Detailed:$Detailed)
    }
    if (-not $IncludePersonalSite) { $alle = @($alle | Where-Object { -not $_.isPersonal }) }
    if ($Filter) {
        if ($Filter -match "^Url -like '(.+)'$") { $teil = $Matches[1]; $alle = @($alle | Where-Object { $_.url -like "*$teil*" }) }
        else { throw "Mock: Filter nicht bekannt: $Filter" }
    }
    foreach ($s in $alle) { ConvertTo-MockSite $s }
}

function New-SPOSite {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Url, [Parameter(Mandatory)][string]$Title, [Parameter(Mandatory)][string]$Owner,
          [string]$Template, [int]$StorageQuota, [switch]$NoWait)
    Add-MockCall 'New-SPOSite' @{ Url = $Url; Title = $Title; Owner = $Owner; Template = $Template; StorageQuota = $StorageQuota; NoWait = [bool]$NoWait }
    $global:MockSPO.sites += [pscustomobject]@{ url = $Url; title = $Title; owner = $Owner; template = $Template; storageQuotaMB = $StorageQuota
        storageUsageMB = 0; sharingCapability = 'ExternalUserAndGuestSharing'; sensitivityLabel = $null; lockState = 'Unlock'; lastModifiedDaysAgo = 0; isPersonal = $false; groups = @() }
}

function Set-SPOSite {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Identity, [string]$SharingCapability, [string]$SensitivityLabel, [string]$LockState, [int]$StorageQuota)
    $p = @{ Identity = $Identity }
    foreach ($k in 'SharingCapability', 'SensitivityLabel', 'LockState', 'StorageQuota') { if ($PSBoundParameters.ContainsKey($k)) { $p[$k] = $PSBoundParameters[$k] } }
    Add-MockCall 'Set-SPOSite' $p
}

function Get-SPOSiteGroup {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Site)
    Add-MockCall 'Get-SPOSiteGroup' @{ Site = $Site }
    $s = @($global:MockSPO.sites | Where-Object { $_.url -eq $Site })
    if ($s.Count -eq 0) { Write-Error "Mock: Website nicht gefunden: $Site"; return }
    foreach ($g in @($s[0].groups)) { [pscustomobject]@{ Title = $g.title; Roles = @($g.roles); Users = @($g.users) } }
}

function Get-SPOHubSite {
    [CmdletBinding()] param([string]$Identity)
    Add-MockCall 'Get-SPOHubSite' @{ Identity = $Identity }
    $h = @($global:MockSPO.hubs)
    if ($Identity) { $h = @($h | Where-Object { $_.siteUrl -eq $Identity }); if ($h.Count -eq 0) { Write-Error "Mock: Hub nicht gefunden: $Identity"; return } }
    foreach ($x in $h) { [pscustomobject]@{ Title = $x.title; SiteUrl = $x.siteUrl } }
}
function Register-SPOHubSite {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Site)
    Add-MockCall 'Register-SPOHubSite' @{ Site = $Site }
    $global:MockSPO.hubs += [pscustomobject]@{ title = ''; siteUrl = $Site }
    [pscustomobject]@{ SiteUrl = $Site }
}
function Set-SPOHubSite {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity, [string]$Title)
    Add-MockCall 'Set-SPOHubSite' @{ Identity = $Identity; Title = $Title }
    foreach ($h in @($global:MockSPO.hubs | Where-Object { $_.siteUrl -eq $Identity })) { $h.title = $Title }
    [pscustomobject]@{ SiteUrl = $Identity; Title = $Title }
}
function Add-SPOHubSiteAssociation {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Site, [Parameter(Mandatory)][string]$HubSite)
    Add-MockCall 'Add-SPOHubSiteAssociation' @{ Site = $Site; HubSite = $HubSite }
}

function Set-SPOTenant {
    [CmdletBinding()]
    param([string]$SharingCapability, [string]$DefaultSharingLinkType, [int]$RequireAnonymousLinksExpireInDays,
          [bool]$ExternalUserExpirationRequired, [int]$ExternalUserExpireInDays)
    $p = @{}
    foreach ($k in $PSBoundParameters.Keys) { $p[$k] = $PSBoundParameters[$k] }
    Add-MockCall 'Set-SPOTenant' $p
    if ($PSBoundParameters.ContainsKey('SharingCapability')) { $global:MockSPO.tenant.sharingCapability = $SharingCapability }
}
function Get-SPOTenant {
    [CmdletBinding()] param()
    Add-MockCall 'Get-SPOTenant'
    [pscustomobject]@{ SharingCapability = $global:MockSPO.tenant.sharingCapability }
}

function Start-Sleep { [CmdletBinding()] param([int]$Seconds, [int]$Milliseconds); Add-MockCall 'Start-Sleep' @{ Seconds = $Seconds } }
