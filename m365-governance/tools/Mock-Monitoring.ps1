# Mock-Monitoring.ps1 - simulierte Cmdlets für Modul 09 (Monitoring, Reporting und Service Operations).
# Nur für Offline-Tests. Es wird nichts mit einem echten Tenant verbunden.
# Voraussetzung: vorher Mock-MgGraph.ps1 laden (Add-MockCall / Get-MockCall). Danach:
#   Initialize-MockMonitoring tools/fixtures/monitoring-klein.json
#
# ACHTUNG: Diese Datei ÜBERSCHREIBT Connect-MgGraph und Get-MgAuditLogSignIn aus Mock-MgGraph.ps1.
# Laden Sie sie deshalb nur in den Tests von Modul 09.
#
# Grenzen der Simulation (bewusst vereinfacht):
#   - Die Nutzungsberichte (CSV) enthalten nur die Spalten, die die Skripte lesen, mit den englischen Spaltennamen der Berichte.
#     Datumswerte stehen als yyyy-MM-dd, Wahrheitswerte als True/False. Ob die echte Ausgabedatei genauso aufgebaut ist
#     (Kodierung, weitere Spalten), ist nicht geprüft.
#   - Unbekannte Filter lösen einen Fehler aus; nachgebildet sind nur die Filter, die die Skripte verwenden.
#   - Zeitwerte sind DateTimeOffset in UTC.

function Initialize-MockMonitoring {
    param([Parameter(Mandatory)][string]$FixturePath)
    $global:MockMon = Get-Content -LiteralPath $FixturePath -Raw -Encoding UTF8 | ConvertFrom-Json
    $global:MockCalls.Clear()
}
function Copy-MonBound { param($Bound) $p = @{}; foreach ($k in $Bound.Keys) { $p[$k] = $Bound[$k] }; $p }
function ConvertTo-MonTime { param([double]$HoursAgo) [datetimeoffset]::UtcNow.AddHours(-$HoursAgo) }
function ConvertTo-MonDate { param($DaysAgo) if ($null -eq $DaysAgo) { '' } else { [datetime]::UtcNow.Date.AddDays(-[double]$DaysAgo).ToString('yyyy-MM-dd') } }
function Get-MonSince {
    param([string]$Filter, [string]$Feld)
    if ($Filter -notmatch ('^' + $Feld + ' ge (\S+)$')) { throw "Mock: Filter nicht bekannt: $Filter" }
    [datetime]::ParseExact($Matches[1], "yyyy-MM-ddTHH:mm:ssZ", [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
}
function Write-MonReport {
    param($Zeilen, [string]$OutFile, [string[]]$Auslassen)
    if ($null -eq $Zeilen) { Set-Content -LiteralPath $OutFile -Value '' -NoNewline -Encoding UTF8; return }
    $ziel = @($Zeilen | ForEach-Object {
        $z = $_
        if ($Auslassen) { $kopie = [ordered]@{}; foreach ($p in $z.PSObject.Properties) { if ($Auslassen -notcontains $p.Name) { $kopie[$p.Name] = $p.Value } }; [pscustomobject]$kopie } else { $z }
    })
    if ($ziel.Count -eq 0) { Set-Content -LiteralPath $OutFile -Value '' -NoNewline -Encoding UTF8; return }
    $ziel | ConvertTo-Csv -NoTypeInformation | Set-Content -LiteralPath $OutFile -Encoding UTF8
}
function Get-MonHash { param([string]$Text) $md5 = [System.Security.Cryptography.MD5]::Create(); ([System.BitConverter]::ToString($md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))) -replace '-', '') }

function Connect-MgGraph {
    [CmdletBinding()]
    param([string[]]$Scopes, [switch]$NoWelcome, [string]$TenantId, [string]$ClientId, [string]$CertificateThumbprint)
    Add-MockCall 'Connect-MgGraph' @{ Scopes = $Scopes }
}
function Connect-ExchangeOnline { [CmdletBinding()] param(); Add-MockCall 'Connect-ExchangeOnline' }

# --- Nutzungsberichte (schreiben eine CSV-Datei) ---
function Get-MgReportOffice365ActiveUserDetail {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('D7', 'D30', 'D90', 'D180')][string]$Period, [Parameter(Mandatory)][string]$OutFile)
    Add-MockCall 'Get-MgReportOffice365ActiveUserDetail' @{ Period = $Period; OutFile = $OutFile }
    $zeilen = foreach ($u in @($global:MockMon.activeUsers)) {
        $l = @($u.lic); $a = @($u.act)
        $anzeige = if ($global:MockMon.options.hideNames) { Get-MonHash $u.upn } else { $u.upn }
        $name = if ($global:MockMon.options.hideNames) { Get-MonHash $u.name } else { $u.name }
        [pscustomobject][ordered]@{
            'Report Refresh Date' = (ConvertTo-MonDate 0); 'User Principal Name' = $anzeige; 'Display Name' = $name
            'Is Deleted' = [string][bool]$u.deleted
            'Has Exchange License' = [string][bool]$l[0]; 'Has OneDrive License' = [string][bool]$l[1]
            'Has SharePoint License' = [string][bool]$l[2]; 'Has Teams License' = [string][bool]$l[3]
            'Exchange Last Activity Date' = (ConvertTo-MonDate $a[0]); 'OneDrive Last Activity Date' = (ConvertTo-MonDate $a[1])
            'SharePoint Last Activity Date' = (ConvertTo-MonDate $a[2]); 'Teams Last Activity Date' = (ConvertTo-MonDate $a[3])
        }
    }
    Write-MonReport $zeilen $OutFile @($global:MockMon.options.omitColumns)
}
function Get-MgReportSharePointSiteUsageDetail {
    [CmdletBinding()]
    param([Parameter(Mandatory)][ValidateSet('D7', 'D30', 'D90', 'D180')][string]$Period, [Parameter(Mandatory)][string]$OutFile)
    Add-MockCall 'Get-MgReportSharePointSiteUsageDetail' @{ Period = $Period; OutFile = $OutFile }
    $zeilen = foreach ($s in @($global:MockMon.sites)) {
        [pscustomobject][ordered]@{ 'Report Refresh Date' = (ConvertTo-MonDate 0); 'Site URL' = $s.url; 'Is Deleted' = [string][bool]$s.deleted
            'Last Activity Date' = (ConvertTo-MonDate $s.daysAgo); 'Storage Used (Byte)' = [string][int64]([double]$s.gb * 1GB) }
    }
    Write-MonReport $zeilen $OutFile @()
}

# --- Überwachungsprotokoll (nur das, was Get-LabelActivity braucht) ---
function Search-UnifiedAuditLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][datetime]$StartDate, [Parameter(Mandatory)][datetime]$EndDate, [string[]]$Operations,
          [int]$ResultSize = 100, [string]$SessionId, [ValidateSet('ReturnLargeSet', 'ReturnNextPreviewPage')][string]$SessionCommand)
    Add-MockCall 'Search-UnifiedAuditLog' (Copy-MonBound $PSBoundParameters)
    if ($ResultSize -gt 5000) { Write-Error 'Mock: ResultSize darf höchstens 5000 sein.'; return }
    if ($SessionCommand -and -not $SessionId) { Write-Error 'Mock: SessionCommand braucht eine SessionId.'; return }
    $von = $StartDate.ToUniversalTime(); $bis = $EndDate.ToUniversalTime(); $jetzt = [datetime]::UtcNow
    $liste = foreach ($r in @($global:MockMon.labelAudit)) {
        $zeit = $jetzt.AddHours(-[double]$r.hoursAgo)
        if ($zeit -lt $von -or $zeit -gt $bis) { continue }
        if ($Operations -and ($Operations -notcontains $r.operation)) { continue }
        [pscustomobject]@{ CreationDate = $zeit; Operations = $r.operation }
    }
    $liste | Select-Object -First $ResultSize
}

# --- Sicherheitsvorfälle ---
function Get-MgSecurityIncident {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgSecurityIncident' (Copy-MonBound $PSBoundParameters)
    $seit = Get-MonSince $Filter 'createdDateTime'
    foreach ($i in @($global:MockMon.incidents)) {
        $erstellt = ConvertTo-MonTime $i.createdHoursAgo
        if ($erstellt.UtcDateTime -lt $seit) { continue }
        [pscustomobject]@{ Id = "i-$($i.name)"; CreatedDateTime = $erstellt; LastUpdateDateTime = (ConvertTo-MonTime $i.updatedHoursAgo)
                           Status = $i.status; Severity = $i.severity; DisplayName = $i.name }
    }
}

# --- Dienstintegrität und Nachrichtencenter ---
function Get-MgServiceAnnouncementIssue {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgServiceAnnouncementIssue' (Copy-MonBound $PSBoundParameters)
    if ($Filter -ne 'isResolved eq false') { throw "Mock: Filter nicht bekannt: $Filter" }
    foreach ($i in @($global:MockMon.serviceIssues | Where-Object { -not $_.resolved })) {
        [pscustomobject]@{ Id = $i.id; Service = $i.service; Classification = $i.classification; Status = $i.status
                           StartDateTime = (ConvertTo-MonTime $i.hoursAgo); Title = $i.title; IsResolved = $false }
    }
}
function Get-MgServiceAnnouncementHealthOverview {
    [CmdletBinding()] param()
    Add-MockCall 'Get-MgServiceAnnouncementHealthOverview'
    foreach ($h in @($global:MockMon.serviceHealth)) { [pscustomobject]@{ Service = $h.service; Status = $h.status } }
}
function Get-MgServiceAnnouncementMessage {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgServiceAnnouncementMessage' (Copy-MonBound $PSBoundParameters)
    $seit = Get-MonSince $Filter 'lastModifiedDateTime'
    foreach ($m in @($global:MockMon.serviceMessages)) {
        $zeit = ConvertTo-MonTime $m.hoursAgo
        if ($zeit.UtcDateTime -lt $seit) { continue }
        [pscustomobject]@{ Id = $m.id; Title = $m.title; IsMajorChange = [bool]$m.major; LastModifiedDateTime = $zeit
                           ActionRequiredByDateTime = $m.due }
    }
}

# --- Protokollfluss ---
function Get-MgAuditLogSignIn {
    [CmdletBinding()] param([string]$Filter, [int]$Top)
    Add-MockCall 'Get-MgAuditLogSignIn' @{ Filter = $Filter; Top = $Top }
    $seit = Get-MonSince $Filter 'createdDateTime'
    $liste = foreach ($s in @($global:MockMon.signInLogs)) { $z = ConvertTo-MonTime $s.hoursAgo; if ($z.UtcDateTime -ge $seit) { [pscustomobject]@{ CreatedDateTime = $z } } }
    if ($Top) { $liste = @($liste) | Select-Object -First $Top }
    $liste
}
function Get-MgAuditLogDirectoryAudit {
    [CmdletBinding()] param([string]$Filter, [int]$Top)
    Add-MockCall 'Get-MgAuditLogDirectoryAudit' @{ Filter = $Filter; Top = $Top }
    $seit = Get-MonSince $Filter 'activityDateTime'
    $liste = foreach ($s in @($global:MockMon.directoryAudits)) { $z = ConvertTo-MonTime $s.hoursAgo; if ($z.UtcDateTime -ge $seit) { [pscustomobject]@{ ActivityDateTime = $z } } }
    if ($Top) { $liste = @($liste) | Select-Object -First $Top }
    $liste
}
function Get-MgRiskyUser {
    [CmdletBinding()] param([string]$Filter, [switch]$All)
    Add-MockCall 'Get-MgRiskyUser' (Copy-MonBound $PSBoundParameters)
    if ($Filter -ne "riskState eq 'atRisk'") { throw "Mock: Filter nicht bekannt: $Filter" }
    if ($global:MockMon.options.riskyUnavailable) { Write-Error 'Mock: Keine Berechtigung bzw. Lizenz fuer Identity Protection.'; return }
    foreach ($r in @($global:MockMon.riskyUsers)) { [pscustomobject]@{ UserPrincipalName = $r.upn; RiskState = 'atRisk' } }
}
