# Mock-Betrieb.ps1 - Simulation für die Tests von Modul 12 (Migration, Kosten, Adoption und BCDR).
# Alle Daten sind erfunden (tools/fixtures/betrieb-klein.json). Es wird nichts im Netz aufgerufen.
#
# Voraussetzung: Mock-MgGraph.ps1 ist geladen (liefert Add-MockCall / Get-MockCall).
# ACHTUNG: Diese Datei definiert Connect-MgGraph, Get-MgUser, Get-MgUserCount, Get-MgGroup, Get-MgGroupOwner,
#   Get-MgDirectoryDeletedItemAsUser und Get-MgDirectoryDeletedItemAsGroup neu und überschreibt gleichnamige Funktionen
#   anderer Mocks. Laden Sie sie nur in den Tests von Modul 12.
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Parameterlisten enthalten nur Parameter, die die Skripte dieses Repositories verwenden.
#   - Unbekannte Filter lösen einen Fehler aus; nachgebildet sind nur die Filter, die die Skripte verwenden.
#   - Der Zeitpunkt der Löschung (DeletedDateTime) ist standardmäßig ein DateTime (Annahme, nicht gegen eine SDK-Version geprüft); options.deletedAsDateTime = false liefert einen DateTimeOffset.
#     Welchen Typ das echte Cmdlet liefert, ist nicht geprüft.
#   - Die Anzeigenamen gelöschter Objekte stehen, wie im Skript erwartet, in AdditionalProperties.displayName.

function Initialize-MockBetrieb {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockBet = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}

function Connect-MgGraph {
    [CmdletBinding()] param([string[]]$Scopes, [switch]$NoWelcome)
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}
function Get-MgUser {
    [CmdletBinding()] param([switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgUser' @{ Property = $Property }
    foreach ($u in @($global:MockBet.users)) {
        [pscustomobject]@{ UserPrincipalName = $u.upn; Department = $u.dept; AccountEnabled = [bool]$u.enabled; UserType = $u.type }
    }
}
function Get-MgUserCount {
    [CmdletBinding()] param([string]$Filter, [string]$ConsistencyLevel)
    Add-MockCall 'Get-MgUserCount' @{ Filter = $Filter; ConsistencyLevel = $ConsistencyLevel }
    if ($ConsistencyLevel -ne 'eventual') { Write-Error 'Mock: Für Zählungen ist -ConsistencyLevel eventual nötig.'; return }
    if (-not $Filter) { return [int]@($global:MockBet.users).Count }
    if ($Filter -eq "userType eq 'Guest'") { return [int]@($global:MockBet.users | Where-Object { $_.type -eq 'Guest' }).Count }
    throw "Mock: Filter nicht bekannt: $Filter"
}
function Get-MgGroup {
    [CmdletBinding()] param([string]$Filter, [switch]$All, [string[]]$Property)
    Add-MockCall 'Get-MgGroup' @{ Filter = $Filter; Property = $Property }
    if ($Filter -ne "groupTypes/any(c:c eq 'Unified')") { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($g in @($global:MockBet.groups | Where-Object { $_.unified })) { [pscustomobject]@{ Id = $g.id; DisplayName = $g.name } }
}
function Get-MgGroupOwner {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$GroupId)
    Add-MockCall 'Get-MgGroupOwner' @{ GroupId = $GroupId }
    $g = @($global:MockBet.groups | Where-Object { $_.id -eq $GroupId })
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe '$GroupId' nicht gefunden."; return }
    foreach ($o in @($g[0].owners)) { [pscustomobject]@{ Id = $o } }
}
function ConvertTo-BetDeleted {
    param($Eintrag)
    $zeit = [datetimeoffset]::UtcNow.AddDays(-[double]$Eintrag.daysAgo)
    if ($global:MockBet.options.deletedAsDateTime) { $zeit = $zeit.UtcDateTime }
    [pscustomobject]@{ Id = [guid]::NewGuid().ToString(); DeletedDateTime = $zeit; AdditionalProperties = @{ displayName = $Eintrag.name } }
}
function Get-MgDirectoryDeletedItemAsUser {
    [CmdletBinding()] param([switch]$All)
    Add-MockCall 'Get-MgDirectoryDeletedItemAsUser'
    foreach ($e in @($global:MockBet.deletedUsers)) { ConvertTo-BetDeleted $e }
}
function Get-MgDirectoryDeletedItemAsGroup {
    [CmdletBinding()] param([switch]$All)
    Add-MockCall 'Get-MgDirectoryDeletedItemAsGroup'
    foreach ($e in @($global:MockBet.deletedGroups)) { ConvertTo-BetDeleted $e }
}
