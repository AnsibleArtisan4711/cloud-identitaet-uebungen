# Mock-ExchangeOnline.ps1 - simulierte Cmdlets des Exchange-Online-Moduls (ExchangeOnlineManagement).
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (stellt Add-MockCall / Get-MockCall bereit).
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Get-Mailbox -Filter versteht nur "LitigationHoldEnabled -eq $true". Andere Filter lösen einen Fehler aus.
#   - Resolve-DnsName liest aus den Beispieldaten; es gibt keine echte DNS-Abfrage.
#   - Größenangaben (TotalItemSize) werden mit einer Methode ToMB() nachgebildet. Das echte Objekt ist komplexer.

function Initialize-MockExchange {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockEXO = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}

function ConvertTo-MockMailbox {
    param($M)
    [pscustomobject]@{
        DisplayName = $M.displayName; PrimarySmtpAddress = $M.address; RecipientTypeDetails = $M.type
        ExchangeGuid = [guid]$M.guid; ArchiveStatus = $M.archiveStatus; LitigationHoldEnabled = [bool]$M.litigationHold
        LitigationHoldDuration = $M.holdDuration; LitigationHoldDate = $(if ($M.holdDaysAgo -ne $null) { (Get-Date).AddDays(-[double]$M.holdDaysAgo) } else { $null })
        ForwardingAddress = $M.forwardingAddress; ForwardingSmtpAddress = $M.forwardingSmtp
        RetainDeletedItemsFor = [timespan]::FromDays([double]$M.retainDays)
        WhenSoftDeleted = $(if ($M.softDeletedDaysAgo -ne $null) { (Get-Date).AddDays(-[double]$M.softDeletedDaysAgo) } else { $null })
    }
}

function Connect-ExchangeOnline { [CmdletBinding()] param(); Add-MockCall 'Connect-ExchangeOnline' }

function Get-Mailbox {
    [CmdletBinding()]
    param([string]$Identity, [string]$ResultSize, [string]$Filter, [string[]]$RecipientTypeDetails, [switch]$InactiveMailboxOnly)
    Add-MockCall 'Get-Mailbox' @{ Identity = $Identity; ResultSize = $ResultSize; Filter = $Filter; RecipientTypeDetails = $RecipientTypeDetails; Inactive = [bool]$InactiveMailboxOnly }
    $alle = @($global:MockEXO.mailboxes | Where-Object { [bool]$_.inactive -eq [bool]$InactiveMailboxOnly })
    if ($Identity) { $alle = @($alle | Where-Object { $_.address -eq $Identity -or $_.guid -eq $Identity }) }
    if ($RecipientTypeDetails) { $alle = @($alle | Where-Object { $RecipientTypeDetails -contains $_.type }) }
    if ($Filter) {
        if ($Filter -eq 'LitigationHoldEnabled -eq $true') { $alle = @($alle | Where-Object { $_.litigationHold }) }
        else { throw "Mock: Filter nicht bekannt: $Filter" }
    }
    foreach ($m in $alle) { ConvertTo-MockMailbox $m }
}

function Get-MailboxStatistics {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity)
    Add-MockCall 'Get-MailboxStatistics' @{ Identity = $Identity }
    $m = @($global:MockEXO.mailboxes | Where-Object { $_.guid -eq $Identity -or $_.address -eq $Identity })
    if ($m.Count -eq 0 -or $null -eq $m[0].sizeMB) { Write-Error "Mock: keine Statistik für $Identity"; return }
    $wert = [pscustomobject]@{ Bytes = [int64]$m[0].sizeMB * 1MB }
    $wert | Add-Member -MemberType ScriptMethod -Name ToMB -Value { [int64][math]::Floor($this.Bytes / 1MB) } -Force
    [pscustomobject]@{ TotalItemSize = [pscustomobject]@{ Value = $wert }
                       LastLogonTime = $(if ($null -ne $m[0].lastLogonDaysAgo) { (Get-Date).AddDays(-[double]$m[0].lastLogonDaysAgo) } else { $null }) }
}

function Get-DistributionGroup {
    [CmdletBinding()] param([string]$ResultSize)
    Add-MockCall 'Get-DistributionGroup'
    foreach ($g in @($global:MockEXO.distributionGroups)) {
        [pscustomobject]@{ Identity = $g.name; PrimarySmtpAddress = $g.address; ManagedBy = @($g.managedBy)
                           RequireSenderAuthenticationEnabled = [bool]$g.requireAuth }
    }
}
function Get-DistributionGroupMember {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity, [string]$ResultSize)
    Add-MockCall 'Get-DistributionGroupMember' @{ Identity = $Identity }
    $g = @($global:MockEXO.distributionGroups | Where-Object { $_.name -eq $Identity })
    if ($g.Count -eq 0) { Write-Error "Mock: Gruppe nicht gefunden: $Identity"; return }
    foreach ($m in @($g[0].members)) { [pscustomobject]@{ Name = $m.name; RecipientType = $m.type } }
}

function Get-TransportRule {
    [CmdletBinding()] param([string]$Identity)
    Add-MockCall 'Get-TransportRule' @{ Identity = $Identity }
    $r = @($global:MockEXO.transportRules)
    if ($Identity) { $r = @($r | Where-Object { $_.name -eq $Identity }); if ($r.Count -eq 0) { Write-Error "Mock: Regel nicht gefunden: $Identity"; return } }
    foreach ($x in $r) { [pscustomobject]@{ Name = $x.name; State = $x.state; Mode = $x.mode; Priority = [int]$x.priority } }
}
function New-TransportRule {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name, [string]$FromScope, [string]$HeaderMatchesMessageHeader, [string[]]$HeaderMatchesPatterns,
          [string]$PrependSubject, [string]$SetAuditSeverity, [string]$Mode, [string]$Comments, [int]$Priority)
    $p = @{}; foreach ($k in $PSBoundParameters.Keys) { $p[$k] = $PSBoundParameters[$k] }
    Add-MockCall 'New-TransportRule' $p
    $global:MockEXO.transportRules += [pscustomobject]@{ name = $Name; state = 'Enabled'; mode = $Mode; priority = $Priority }
}

function New-Mailbox {
    [CmdletBinding()] param([switch]$Shared, [string]$Name, [string]$DisplayName, [string]$PrimarySmtpAddress)
    Add-MockCall 'New-Mailbox' @{ Shared = [bool]$Shared; Name = $Name; DisplayName = $DisplayName; PrimarySmtpAddress = $PrimarySmtpAddress }
    $global:MockEXO.mailboxes += [pscustomobject]@{ displayName = $DisplayName; address = $PrimarySmtpAddress; type = $(if ($Shared) { 'SharedMailbox' } else { 'UserMailbox' })
        guid = [guid]::NewGuid().ToString(); retainDays = 14; litigationHold = $false; inactive = $false
        permissions = @([pscustomobject]@{ user = 'NT AUTHORITY\SELF'; rights = @('FullAccess'); inherited = $false; deny = $false }) }
}
function Add-MailboxPermission {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity, [Parameter(Mandatory)][string]$User, [string]$AccessRights, [bool]$AutoMapping)
    Add-MockCall 'Add-MailboxPermission' @{ Identity = $Identity; User = $User; AccessRights = $AccessRights; AutoMapping = $AutoMapping }
    $m = @($global:MockEXO.mailboxes | Where-Object { $_.address -eq $Identity })
    if ($m.Count -eq 0) { Write-Error "Mock: Postfach nicht gefunden: $Identity"; return }
    $m[0].permissions = @($m[0].permissions) + [pscustomobject]@{ user = $User; rights = @($AccessRights); inherited = $false; deny = $false }
}
function Add-RecipientPermission {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity, [Parameter(Mandatory)][string]$Trustee, [string]$AccessRights, [bool]$Confirm = $true)
    Add-MockCall 'Add-RecipientPermission' @{ Identity = $Identity; Trustee = $Trustee; AccessRights = $AccessRights; Confirm = $Confirm }
}
function Get-MailboxPermission {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity)
    Add-MockCall 'Get-MailboxPermission' @{ Identity = $Identity }
    $m = @($global:MockEXO.mailboxes | Where-Object { $_.address -eq $Identity })
    if ($m.Count -eq 0) { Write-Error "Mock: Postfach nicht gefunden: $Identity"; return }
    foreach ($p in @($m[0].permissions)) { [pscustomobject]@{ User = $p.user; AccessRights = @($p.rights); IsInherited = [bool]$p.inherited; Deny = [bool]$p.deny } }
}
function Get-Recipient {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Identity)
    Add-MockCall 'Get-Recipient' @{ Identity = $Identity }
    $r = @($global:MockEXO.recipients | Where-Object { $_.identity -eq $Identity })
    if ($r.Count -eq 0) { Write-Error "Mock: Empfänger nicht gefunden: $Identity"; return }
    [pscustomobject]@{ Identity = $r[0].identity; RecipientTypeDetails = $r[0].type }
}

function Get-ExternalInOutlook { [CmdletBinding()] param(); Add-MockCall 'Get-ExternalInOutlook'; [pscustomobject]@{ Enabled = [bool]$global:MockEXO.externalInOutlook.enabled; AllowList = @($global:MockEXO.externalInOutlook.allowList) } }
function Set-ExternalInOutlook {
    [CmdletBinding()] param([bool]$Enabled, $AllowList)
    $p = @{}; foreach ($k in $PSBoundParameters.Keys) { $p[$k] = $PSBoundParameters[$k] }
    Add-MockCall 'Set-ExternalInOutlook' $p
}
function Get-AcceptedDomain {
    [CmdletBinding()] param()
    Add-MockCall 'Get-AcceptedDomain'
    foreach ($d in @($global:MockEXO.acceptedDomains)) { [pscustomobject]@{ DomainName = [string]$d.name; DomainType = $d.type } }
}
function Resolve-DnsName {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$Name, [string]$Type)
    Add-MockCall 'Resolve-DnsName' @{ Name = $Name; Type = $Type }
    $e = @($global:MockEXO.dns | Where-Object { $_.name -eq $Name })
    if ($e.Count -eq 0) { Write-Error "Mock: DNS-Name nicht gefunden: $Name"; return }
    foreach ($t in @($e[0].txt)) { [pscustomobject]@{ Name = $Name; Strings = @($t) } }
}

function Get-MessageTrace {
    [CmdletBinding()] param([datetime]$StartDate, [datetime]$EndDate, [string]$SenderAddress, [string]$RecipientAddress)
    Add-MockCall 'Get-MessageTrace' @{ StartDate = $StartDate; EndDate = $EndDate; SenderAddress = $SenderAddress; RecipientAddress = $RecipientAddress }
    foreach ($m in @($global:MockEXO.messages)) {
        $zeit = (Get-Date).AddDays(-[double]$m.daysAgo)
        if ($zeit -lt $StartDate -or $zeit -gt $EndDate) { continue }
        if ($SenderAddress -and $m.sender -ne $SenderAddress) { continue }
        if ($RecipientAddress -and $m.recipient -ne $RecipientAddress) { continue }
        [pscustomobject]@{ Received = $zeit; SenderAddress = $m.sender; RecipientAddress = $m.recipient; Subject = $m.subject; Status = $m.status; MessageTraceId = $m.id }
    }
}
function Get-MessageTraceDetail {
    [CmdletBinding()] param([Parameter(Mandatory)][string]$MessageTraceId, [string]$RecipientAddress)
    Add-MockCall 'Get-MessageTraceDetail' @{ MessageTraceId = $MessageTraceId; RecipientAddress = $RecipientAddress }
    $m = @($global:MockEXO.messages | Where-Object { $_.id -eq $MessageTraceId })
    if ($m.Count -eq 0) { Write-Error "Mock: Nachricht nicht gefunden"; return }
    foreach ($e in @($m[0].events)) { [pscustomobject]@{ Date = (Get-Date).AddDays(-[double]$m[0].daysAgo); Event = $e.event; Detail = $e.detail } }
}
