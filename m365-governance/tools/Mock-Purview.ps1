# Mock-Purview.ps1 - simulierte Cmdlets für Security & Compliance PowerShell (Purview): Labels, DLP, Aufbewahrung, Information Barriers.
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (stellt Add-MockCall / Get-MockCall bereit).
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#     Ein Tippfehler im Parameternamen fällt dadurch auf; ob der Parameter im echten Cmdlet existiert, wird nicht geprüft.
#   - Ausnahme: New-RetentionCompliancePolicy bildet die zwei Parametersätze der Microsoft-Dokumentation nach
#     (Default mit statischen Standorten, AdaptiveScopeLocation nur mit adaptivem Bereich). TeamsChatLocation fehlt im Default-Satz.
#   - Neu angelegte Richtlinien haben den Verteilungsstatus "Pending"; ein echter Tenant braucht Zeit.

function Initialize-MockPurview {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockPurview = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Add-MockEntry { param([string]$Liste, $Eintrag) $global:MockPurview.$Liste = @($global:MockPurview.$Liste) + $Eintrag }
function Find-MockEntry { param([string]$Liste, [string]$Name) @($global:MockPurview.$Liste | Where-Object { $_.name -eq $Name }) }
function Copy-Bound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }

function Connect-IPPSSession { [CmdletBinding()] param(); Add-MockCall 'Connect-IPPSSession' }

# --- Sensitivity Labels ---
function New-Label {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$DisplayName, [Parameter(Mandatory)][string]$Name, [string]$Tooltip, [string]$ContentType,
          [bool]$ApplyContentMarkingFooterEnabled, [string]$ApplyContentMarkingFooterText, [int]$ApplyContentMarkingFooterFontSize)
    Add-MockCall 'New-Label' (Copy-Bound $PSBoundParameters)
    if (@(Find-MockEntry 'labels' $Name).Count -gt 0) { Write-Error "Mock: Label '$Name' existiert bereits."; return }
    Add-MockEntry 'labels' ([pscustomobject]@{ name = $Name; displayName = $DisplayName; guid = [guid]::NewGuid().ToString()
        priority = @($global:MockPurview.labels).Count; contentType = $ContentType })
}
function Get-Label {
    [CmdletBinding()] param()
    Add-MockCall 'Get-Label'
    foreach ($l in @($global:MockPurview.labels)) { [pscustomobject]@{ Name = $l.name; DisplayName = $l.displayName; Guid = [guid]$l.guid; Priority = [int]$l.priority; ContentType = $l.contentType } }
}
function New-LabelPolicy {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [string[]]$Labels, [string[]]$ExchangeLocation, [hashtable]$AdvancedSettings)
    Add-MockCall 'New-LabelPolicy' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'labelPolicies' ([pscustomobject]@{ name = $Name; status = 'Pending' })
}
function Get-LabelPolicy {
    [CmdletBinding()] param()
    Add-MockCall 'Get-LabelPolicy'
    foreach ($p in @($global:MockPurview.labelPolicies)) { [pscustomobject]@{ Name = $p.name; DistributionStatus = $p.status } }
}

# --- DLP ---
function New-DlpCompliancePolicy {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [string[]]$ExchangeLocation, [string[]]$SharePointLocation, [string[]]$OneDriveLocation, [string]$Mode, [string]$Comment)
    Add-MockCall 'New-DlpCompliancePolicy' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'dlpPolicies' ([pscustomobject]@{ name = $Name; mode = $Mode; status = 'Pending' })
}
function New-DlpComplianceRule {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Policy, $ContentContainsSensitiveInformation, [string]$AccessScope,
          [bool]$BlockAccess, [string]$NotifyUser, [string]$GenerateAlert, [string]$GenerateIncidentReport)
    Add-MockCall 'New-DlpComplianceRule' (Copy-Bound $PSBoundParameters)
    if (@(Find-MockEntry 'dlpPolicies' $Policy).Count -eq 0) { Write-Error "Mock: Richtlinie '$Policy' nicht gefunden."; return }
}
function Get-DlpCompliancePolicy {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity, [switch]$DistributionDetail)
    Add-MockCall 'Get-DlpCompliancePolicy' @{ Identity = $Identity; DistributionDetail = [bool]$DistributionDetail }
    $l = @($global:MockPurview.dlpPolicies); if ($Identity) { $l = @($l | Where-Object { $_.name -eq $Identity }) }
    foreach ($p in $l) { [pscustomobject]@{ Name = $p.name; Mode = $p.mode; DistributionStatus = $(if ($DistributionDetail) { $p.status } else { $null }) } }
}

# --- Aufbewahrung ---
function New-RetentionCompliancePolicy {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param([Parameter(Mandatory, Position = 0)][string]$Name, [string]$Comment, [bool]$Enabled,
          [Parameter(ParameterSetName = 'Default')][string[]]$ExchangeLocation,
          [Parameter(ParameterSetName = 'Default')][string[]]$SharePointLocation,
          [Parameter(ParameterSetName = 'Default')][string[]]$OneDriveLocation,
          [Parameter(Mandatory, ParameterSetName = 'AdaptiveScopeLocation')][string[]]$AdaptiveScopeLocation)
    Add-MockCall 'New-RetentionCompliancePolicy' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'retentionPolicies' ([pscustomobject]@{ name = $Name; enabled = [bool]$Enabled; status = 'Pending' })
}
function New-RetentionComplianceRule {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$Policy, [int]$RetentionDuration, [string]$RetentionComplianceAction,
          [string]$ExpirationDateOption, [string]$PublishComplianceTag)
    Add-MockCall 'New-RetentionComplianceRule' (Copy-Bound $PSBoundParameters)
    if (@(Find-MockEntry 'retentionPolicies' $Policy).Count -eq 0) { Write-Error "Mock: Richtlinie '$Policy' nicht gefunden."; return }
}
function Get-RetentionCompliancePolicy {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity, [switch]$DistributionDetail)
    Add-MockCall 'Get-RetentionCompliancePolicy' @{ Identity = $Identity; DistributionDetail = [bool]$DistributionDetail }
    $l = @($global:MockPurview.retentionPolicies); if ($Identity) { $l = @($l | Where-Object { $_.name -eq $Identity }) }
    foreach ($p in $l) { [pscustomobject]@{ Name = $p.name; Enabled = [bool]$p.enabled; DistributionStatus = $(if ($DistributionDetail) { $p.status } else { $null }) } }
}
function New-ComplianceTag {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [string]$Comment, [bool]$IsRecordLabel, [bool]$Regulatory, [string]$RetentionAction, [int]$RetentionDuration, [string]$RetentionType)
    Add-MockCall 'New-ComplianceTag' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'complianceTags' ([pscustomobject]@{ name = $Name; isRecordLabel = $IsRecordLabel; regulatory = $Regulatory; retentionDuration = $RetentionDuration })
}
function Get-ComplianceTag {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity)
    Add-MockCall 'Get-ComplianceTag' @{ Identity = $Identity }
    $l = @($global:MockPurview.complianceTags); if ($Identity) { $l = @($l | Where-Object { $_.name -eq $Identity }) }
    foreach ($t in $l) { [pscustomobject]@{ Name = $t.name; IsRecordLabel = [bool]$t.isRecordLabel; Regulatory = [bool]$t.regulatory; RetentionDuration = [int]$t.retentionDuration } }
}
function New-AdaptiveScope {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$LocationType, [Parameter(Mandatory)][string]$RawQuery)
    Add-MockCall 'New-AdaptiveScope' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'adaptiveScopes' ([pscustomobject]@{ name = $Name })
}

# --- Information Barriers ---
function New-OrganizationSegment { [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$UserGroupFilter); Add-MockCall 'New-OrganizationSegment' (Copy-Bound $PSBoundParameters); Add-MockEntry 'segments' ([pscustomobject]@{ name = $Name }) }
function New-InformationBarrierPolicy {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][string]$AssignedSegment, [Parameter(Mandatory)][string]$SegmentsBlocked, [string]$State)
    Add-MockCall 'New-InformationBarrierPolicy' (Copy-Bound $PSBoundParameters)
    Add-MockEntry 'infoBarrierPolicies' ([pscustomobject]@{ identity = "ib-$Name"; name = $Name; state = $State })
}
function Get-InformationBarrierPolicy { [CmdletBinding()] param(); Add-MockCall 'Get-InformationBarrierPolicy'; foreach ($p in @($global:MockPurview.infoBarrierPolicies)) { [pscustomobject]@{ Identity = $p.identity; Name = $p.name; State = $p.state } } }
function Set-InformationBarrierPolicy {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity, [string]$State)
    Add-MockCall 'Set-InformationBarrierPolicy' (Copy-Bound $PSBoundParameters)
    foreach ($p in @($global:MockPurview.infoBarrierPolicies | Where-Object { $_.identity -eq $Identity })) { $p.state = $State }
}
function Start-InformationBarrierPoliciesApplication { [CmdletBinding()] param(); Add-MockCall 'Start-InformationBarrierPoliciesApplication' }
function Get-InformationBarrierPoliciesApplicationStatus { [CmdletBinding()] param(); Add-MockCall 'Get-InformationBarrierPoliciesApplicationStatus'; [pscustomobject]@{ Status = 'NotStarted' } }
