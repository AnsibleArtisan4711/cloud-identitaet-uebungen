# Mock-Compliance.ps1 - simulierte Cmdlets für Audit, eDiscovery (Standard), Case Holds und Rollengruppen.
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 (Add-MockCall), Mock-ExchangeOnline.ps1 (Connect-ExchangeOnline) und
# Mock-Purview.ps1 (Connect-IPPSSession) laden. Danach: Initialize-MockCompliance tools/fixtures/compliance-klein.json
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#   - Search-UnifiedAuditLog: filtert nach Zeitraum, Benutzer und Operation, begrenzt auf -ResultSize (Standard 100, höchstens 5000)
#     und liefert bei -SessionCommand ReturnLargeSet unsortiert (umgekehrte Reihenfolge). Seitenabfragen mit gleicher SessionId werden
#     NICHT nachgebildet: jeder Aufruf liefert wieder die ersten Treffer.
#   - Compliance-Suchen: Die Abfrage (ContentMatchQuery) wird gespeichert, aber nicht ausgewertet. Treffer kommen aus "searchResults"
#     je Postfach. Eine Suche meldet beim ersten Get-ComplianceSearch "InProgress", beim zweiten das Ergebnis aus options.searchOutcome.
#   - Nach Dokumentation (abgerufen 07.11.2026) wird bei New-ComplianceSearch die ExchangeLocation gelöscht, wenn -Name Leerzeichen enthält
#     und -Case angegeben ist. Das kann über options.clearLocationWhenNameHasSpacesAndCase ausgeschaltet werden.
#   - Get-CaseHoldPolicy zeigt ohne -DistributionDetail den Verteilungsstatus "Pending" (so steht es in der Dokumentation).
#   - Nicht nachgebildet: Genehmigungen, Berechtigungen, Aufbewahrung des Auditprotokolls, die Wirkung von Holds.

function Initialize-MockCompliance {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockCompliance = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Add-CompEntry { param([string]$Liste, $Eintrag) $global:MockCompliance.$Liste = @($global:MockCompliance.$Liste) + $Eintrag }
function Find-CompEntry { param([string]$Liste, [string]$Name) @($global:MockCompliance.$Liste | Where-Object { $_.name -eq $Name }) }
function Copy-CompBound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }

# --- Audit ---
function Get-AdminAuditLogConfig {
    [CmdletBinding()] param()
    Add-MockCall 'Get-AdminAuditLogConfig'
    [pscustomobject]@{ UnifiedAuditLogIngestionEnabled = [bool]$global:MockCompliance.auditConfig.unifiedAuditLogIngestionEnabled }
}
function Set-AdminAuditLogConfig {
    [CmdletBinding()] param([bool]$UnifiedAuditLogIngestionEnabled)
    Add-MockCall 'Set-AdminAuditLogConfig' (Copy-CompBound $PSBoundParameters)
    $global:MockCompliance.auditConfig.unifiedAuditLogIngestionEnabled = $UnifiedAuditLogIngestionEnabled
}
function Search-UnifiedAuditLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][datetime]$StartDate, [Parameter(Mandatory)][datetime]$EndDate, [string[]]$UserIds, [string[]]$Operations,
          [int]$ResultSize = 100, [string]$SessionId, [ValidateSet('ReturnLargeSet', 'ReturnNextPreviewPage')][string]$SessionCommand)
    Add-MockCall 'Search-UnifiedAuditLog' (Copy-CompBound $PSBoundParameters)
    if ($ResultSize -gt 5000) { Write-Error 'Mock: ResultSize darf höchstens 5000 sein.'; return }
    if ($SessionCommand -and -not $SessionId) { Write-Error 'Mock: SessionCommand braucht eine SessionId.'; return }
    $von = $StartDate.ToUniversalTime(); $bis = $EndDate.ToUniversalTime(); $jetzt = (Get-Date).ToUniversalTime()
    $liste = @()
    foreach ($r in @($global:MockCompliance.auditLog)) {
        $zeit = $jetzt.AddHours(-[double]$r.hoursAgo)
        if ($zeit -lt $von -or $zeit -gt $bis) { continue }
        if ($UserIds -and ($UserIds -notcontains $r.user)) { continue }
        if ($Operations -and ($Operations -notcontains $r.operation)) { continue }
        $daten = [ordered]@{ Operation = $r.operation; UserId = $r.user; SourceFileName = $r.file; SiteUrl = $r.site; ClientIP = $r.ip }
        $liste += [pscustomobject]@{ CreationDate = $zeit; UserIds = $r.user; Operations = $r.operation; AuditData = ($daten | ConvertTo-Json -Compress) }
    }
    if ($SessionCommand -eq 'ReturnLargeSet' -and $liste.Count -gt 1) { [array]::Reverse($liste) }
    $liste | Select-Object -First $ResultSize
}

# --- eDiscovery (Standard) ---
function Get-ComplianceCase {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity)
    Add-MockCall 'Get-ComplianceCase' (Copy-CompBound $PSBoundParameters)
    $alle = @($global:MockCompliance.cases)
    if ($Identity) { $alle = @($alle | Where-Object { $_.name -eq $Identity }); if ($alle.Count -eq 0) { Write-Error "Mock: Fall '$Identity' nicht gefunden."; return } }
    foreach ($c in $alle) { [pscustomobject]@{ Name = $c.name; Status = $c.status } }
}
function New-ComplianceCase {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [string]$Description)
    Add-MockCall 'New-ComplianceCase' (Copy-CompBound $PSBoundParameters)
    if (@(Find-CompEntry 'cases' $Name).Count -gt 0) { Write-Error "Mock: Fall '$Name' existiert bereits."; return }
    Add-CompEntry 'cases' ([pscustomobject]@{ name = $Name; status = 'Active' })
}
function New-ComplianceSearch {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [string]$Case, [string[]]$ExchangeLocation, [string]$ContentMatchQuery, [string]$Description)
    Add-MockCall 'New-ComplianceSearch' (Copy-CompBound $PSBoundParameters)
    if ($Case -and @(Find-CompEntry 'cases' $Case).Count -eq 0) { Write-Error "Mock: Fall '$Case' nicht gefunden."; return }
    if (@(Find-CompEntry 'searches' $Name).Count -gt 0) { Write-Error "Mock: Suche '$Name' existiert bereits."; return }
    $orte = @($ExchangeLocation)
    if ($Case -and ($Name -match '\s') -and $global:MockCompliance.options.clearLocationWhenNameHasSpacesAndCase) { $orte = @() }
    Add-CompEntry 'searches' ([pscustomobject]@{ name = $Name; case = $Case; locations = $orte; query = $ContentMatchQuery; started = $false; polls = 0 })
}
function Start-ComplianceSearch {
    [CmdletBinding()] param([Parameter(Mandatory, Position = 0)][string]$Identity)
    Add-MockCall 'Start-ComplianceSearch' (Copy-CompBound $PSBoundParameters)
    $s = @(Find-CompEntry 'searches' $Identity)
    if ($s.Count -eq 0) { Write-Error "Mock: Suche '$Identity' nicht gefunden."; return }
    $s[0].started = $true
}
function Get-ComplianceSearch {
    [CmdletBinding()] param([Parameter(Mandatory, Position = 0)][string]$Identity)
    Add-MockCall 'Get-ComplianceSearch' (Copy-CompBound $PSBoundParameters)
    $s = @(Find-CompEntry 'searches' $Identity)
    if ($s.Count -eq 0) { Write-Error "Mock: Suche '$Identity' nicht gefunden."; return }
    $x = $s[0]
    if (-not $x.started) { $status = 'NotStarted' }
    else {
        $x.polls = [int]$x.polls + 1
        $status = if ($x.polls -lt 2) { 'InProgress' } else { [string]$global:MockCompliance.options.searchOutcome }
    }
    $items = 0; $size = 0
    if ($status -eq 'Completed') {
        foreach ($e in @($global:MockCompliance.searchResults)) {
            if (@($x.locations) -contains 'All' -or @($x.locations) -contains $e.location) { $items += [int]$e.items; $size += [long]$e.size }
        }
    }
    [pscustomobject]@{ Name = $x.name; Status = $status; Items = $items; Size = $size }
}

# --- Case Holds ---
function New-CaseHoldPolicy {
    [CmdletBinding()]
    param([Parameter(Mandatory, Position = 0)][string]$Name, [Parameter(Mandatory)][string]$Case, [string[]]$ExchangeLocation, [string[]]$SharePointLocation, [bool]$Enabled, [string]$Comment)
    Add-MockCall 'New-CaseHoldPolicy' (Copy-CompBound $PSBoundParameters)
    if (@(Find-CompEntry 'cases' $Case).Count -eq 0) { Write-Error "Mock: Fall '$Case' nicht gefunden."; return }
    if (@(Find-CompEntry 'holdPolicies' $Name).Count -gt 0) { Write-Error "Mock: Sperrrichtlinie '$Name' existiert bereits."; return }
    Add-CompEntry 'holdPolicies' ([pscustomobject]@{ name = $Name; case = $Case; enabled = $Enabled; status = 'Pending'
        exchange = @($ExchangeLocation); sharepoint = @($SharePointLocation) })
}
function New-CaseHoldRule {
    [CmdletBinding()] param([Parameter(Mandatory, Position = 0)][string]$Name, [Parameter(Mandatory)][string]$Policy, [string]$ContentMatchQuery)
    Add-MockCall 'New-CaseHoldRule' (Copy-CompBound $PSBoundParameters)
    if (@(Find-CompEntry 'holdPolicies' $Policy).Count -eq 0) { Write-Error "Mock: Sperrrichtlinie '$Policy' nicht gefunden."; return }
    Add-CompEntry 'holdRules' ([pscustomobject]@{ name = $Name; policy = $Policy; query = $ContentMatchQuery })
}
function Get-CaseHoldPolicy {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity, [string]$Case, [switch]$DistributionDetail)
    Add-MockCall 'Get-CaseHoldPolicy' (Copy-CompBound $PSBoundParameters)
    $alle = @($global:MockCompliance.holdPolicies)
    if ($Identity) { $alle = @($alle | Where-Object { $_.name -eq $Identity }); if ($alle.Count -eq 0) { Write-Error "Mock: Sperrrichtlinie '$Identity' nicht gefunden."; return } }
    if ($Case) { $alle = @($alle | Where-Object { $_.case -eq $Case }) }
    foreach ($p in $alle) {
        [pscustomobject]@{ Name = $p.name; Case = $p.case; Enabled = [bool]$p.enabled
            DistributionStatus = $(if ($DistributionDetail) { [string]$p.status } else { 'Pending' })
            ExchangeLocation = @($p.exchange); SharePointLocation = @($p.sharepoint) }
    }
}

# --- Rollengruppen ---
function Get-RoleGroup {
    [CmdletBinding()] param([Parameter(Position = 0)][string]$Identity)
    Add-MockCall 'Get-RoleGroup' (Copy-CompBound $PSBoundParameters)
    $g = @($global:MockCompliance.roleGroups | Where-Object { $_.name -eq $Identity })
    if ($g.Count -eq 0) { Write-Error "Mock: Rollengruppe '$Identity' nicht gefunden."; return }
    [pscustomobject]@{ Name = $g[0].name }
}
function Get-RoleGroupMember {
    [CmdletBinding()] param([Parameter(Mandatory, Position = 0)][string]$Identity)
    Add-MockCall 'Get-RoleGroupMember' (Copy-CompBound $PSBoundParameters)
    $g = @($global:MockCompliance.roleGroups | Where-Object { $_.name -eq $Identity })
    if ($g.Count -eq 0) { Write-Error "Mock: Rollengruppe '$Identity' nicht gefunden."; return }
    foreach ($m in @($g[0].members)) { [pscustomobject]@{ Name = $m } }
}
