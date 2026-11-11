# modul-09.tests.ps1 - Offline-Tests für die Skripte aus Modul 09 (Monitoring, Reporting und Service Operations).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-09-monitoring/tests/modul-09.tests.ps1
# Graph- und Exchange-Cmdlets sind simuliert (tools/Mock-Monitoring.ps1, erfundene Daten in tools/fixtures/monitoring-klein.json).
# Test-Runbooks.ps1 und Get-KpiStatus.ps1 laufen mit erfundenen Dateien in einem Wegwerf-Ordner.
# Geprüft wird die Logik der Skripte, nicht das Verhalten eines echten Tenants. Die KQL-Dateien werden nicht ausgeführt.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Monitoring.ps1')   # überschreibt Connect-MgGraph und Get-MgAuditLogSignIn
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'monitoring-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test { Initialize-MockMonitoring $fixture }
function Get-Aufruf { param([string]$Name) @(Get-MockCall $Name) }
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
function Assert-Mandatory {
    param([string]$Pfad, [string[]]$Namen)
    $cmd = Get-Command $Pfad
    foreach ($n in $Namen) {
        $pflicht = @($cmd.Parameters[$n].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }).Count -gt 0
        Assert-True $pflicht "$n ist Pflicht"
    }
}
function Get-Pos { param([string]$Text, [string]$Teil) $Text.IndexOf($Teil, [System.StringComparison]::Ordinal) }
function Get-Scopes { @((Get-Aufruf 'Connect-MgGraph')[0].Parameter.Scopes) }
function Get-FilterStunden {
    param([string]$Filter)
    $z = [datetime]::ParseExact(($Filter -replace '^.* ge ', ''), 'yyyy-MM-ddTHH:mm:ssZ', [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    ([datetime]::UtcNow - $z).TotalHours
}
$istPs7 = $PSVersionTable.PSVersion.Major -ge 6
function Invoke-Kopie {
    # Get-StaleSiteStats.ps1 und die Lösung zu Aufgabe 4 setzen $d = $null und rufen [datetime]::TryParse(..., [ref]$d) auf.
    # Das scheitert (siehe Test "Original scheitert"). Die Logik wird deshalb an einer Kopie mit Anfangswert MinValue geprüft.
    param([string]$Pfad, [hashtable]$Argumente = @{})
    $text = Get-Content -LiteralPath $Pfad -Raw -Encoding UTF8
    $neu = $text.Replace('$d = $null', '$d = [datetime]::MinValue')
    if ($neu -eq $text) { throw 'Anfangswert $d = $null nicht gefunden' }
    $kopie = Join-Path (Get-Location).Path 'kopie.ps1'
    Set-Content -LiteralPath $kopie -Value $neu -Encoding UTF8
    Invoke-ScriptUnderTest $kopie $Argumente
}
function Test-OriginalScheitert {
    # Das Original muss in PowerShell 7 und in Windows PowerShell 5.1 scheitern (5.1: vom Anwender am 07.11.2026 bestätigt).
    param([scriptblock]$Aufruf)
    $fehler = $null
    try { $null = & $Aufruf } catch { $fehler = $_ }
    Assert-True ($null -ne $fehler) 'Original scheitert'
    Assert-Match $fehler.Exception.Message 'TryParse'
}
function Test-Zeile { param($Ausgabe, [string]$Muster) @($Ausgabe | Where-Object { $_ -match $Muster }).Count -gt 0 }
function Set-Konten {
    # behält nur die genannten Konten im Nutzungsbericht
    param([string[]]$Namen)
    $global:MockMon.activeUsers = @($global:MockMon.activeUsers | Where-Object { $Namen -contains $_.upn })
}

Write-Host 'Listing 98: Get-InactiveLicensedUsers.ps1'
Test-Case 'lädt den 90-Tage-Bericht und zählt lizenzierte Konten ohne Aktivität (gelöschte ausgenommen)' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1')
        Assert-Equal @('Reports.Read.All') (Get-Scopes)
        $c = (Get-Aufruf 'Get-MgReportOffice365ActiveUserDetail')[0].Parameter
        Assert-Equal 'D90' $c.Period
        Assert-Equal '.\ActiveUserDetail.csv' $c.OutFile
        Assert-True (Test-Zeile $r.Output '^Konten im Bericht:\s+7$') 'alle Zeilen des Berichts'
        Assert-True (Test-Zeile $r.Output '^Lizenziert, aber ohne Aktivitaet:\s+2$') 'ben und gina'
        $t = $r.OutputText
        Assert-Match $t 'ben@example\.com\s+Ben Beispiel'
        Assert-Match $t 'gina@example\.com\s+Gina Beispiel'
        foreach ($nicht in 'anna@', 'carla@', 'dora@', 'emil@', 'fritz@') { Assert-NotMatch $t ([regex]::Escape($nicht)) "$nicht gehört nicht in die Liste" }
    }
}
Test-Case 'schreibt den Bericht in die mit -Datei genannte Datei' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1') @{ Datei = '.\mein-bericht.csv' }
        Assert-Equal '.\mein-bericht.csv' ((Get-Aufruf 'Get-MgReportOffice365ActiveUserDetail')[0].Parameter.OutFile)
        Assert-True (Test-Path '.\mein-bericht.csv')
        Assert-True (-not (Test-Path '.\ActiveUserDetail.csv'))
    }
}
Test-Case 'ein einzelnes Konto ohne Aktivität wird ebenfalls aufgelistet' {
    Start-Test
    Set-Konten 'anna@example.com', 'ben@example.com'
    $global:MockMon.activeUsers[1].upn = 'ben@beispiel.de'   # ohne den Buchstaben x: nur das @ unterscheidet Namen von verborgenen Namen
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1')
        Assert-True (Test-Zeile $r.Output '^Lizenziert, aber ohne Aktivitaet:\s+1$')
        Assert-Match $r.OutputText 'ben@beispiel\.de'
    }
}
Test-Case 'bei verborgenen Namen wird gezählt, aber keine Liste ausgegeben' {
    Start-Test
    $global:MockMon.options.hideNames = $true
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1')
        Assert-True (Test-Zeile $r.Output '^Lizenziert, aber ohne Aktivitaet:\s+2$')
        Assert-Match $r.Text 'Namen sind verborgen'
        Assert-NotMatch $r.OutputText 'Display Name' 'keine Tabelle'
    }
}
Test-Case 'ohne inaktive Konten steht 0 und es folgt keine Liste' {
    Start-Test
    Set-Konten 'anna@example.com', 'emil@example.com'
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1')
        Assert-True (Test-Zeile $r.Output '^Lizenziert, aber ohne Aktivitaet:\s+0$')
        Assert-NotMatch $r.OutputText 'Display Name' 'keine Liste'
    }
}
Test-Case 'bricht bei fehlender Spalte oder leerem Bericht ab' {
    Start-Test
    $global:MockMon.options.omitColumns = @('Teams Last Activity Date')
    Use-Arbeitsordner { Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1') } 'Spalten nicht gefunden: Teams Last Activity Date' }
    Start-Test
    $global:MockMon.activeUsers = @()
    Use-Arbeitsordner { Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Get-InactiveLicensedUsers.ps1') } 'Bericht ist leer' }
}

Write-Host 'Listing 100: Get-StaleSiteStats.ps1'
Test-Case 'zählt Websites ohne Aktivität seit 180 Tagen samt Speicher (gelöschte ausgenommen)' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-Kopie (Join-Path $skripte 'Get-StaleSiteStats.ps1')
        Assert-Equal @('Reports.Read.All') (Get-Scopes)
        $c = (Get-Aufruf 'Get-MgReportSharePointSiteUsageDetail')[0].Parameter
        Assert-Equal 'D180' $c.Period
        Assert-Equal '.\SiteUsage.csv' $c.OutFile
        Assert-True (Test-Zeile $r.Output '^Websites gesamt:\s+4$')
        Assert-True (Test-Zeile $r.Output '^Ohne Aktivitaet seit 180 Tagen: 2 \(50\s?%\)$') 'PRJ-Alt und PRJ-OhneDatum'
        Assert-True (Test-Zeile $r.Output '^Belegter Speicher dort:\s+5[.,]0 GB$') '2 GB + 3 GB'
    }
}
Test-Case '-InaktivTage verschiebt die Grenze' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-Kopie (Join-Path $skripte 'Get-StaleSiteStats.ps1') @{ InaktivTage = 90 }
        Assert-True (Test-Zeile $r.Output '^Ohne Aktivitaet seit 90 Tagen: 3 \(75\s?%\)$')
        Assert-True (Test-Zeile $r.Output '^Belegter Speicher dort:\s+6[.,]0 GB$')
        $r = Invoke-Kopie (Join-Path $skripte 'Get-StaleSiteStats.ps1') @{ InaktivTage = 365; Datei = '.\x.csv' }
        Assert-True (Test-Zeile $r.Output '^Ohne Aktivitaet seit 365 Tagen: 1 \(25\s?%\)$') 'nur die Website ohne Datum'
        Assert-True (Test-Zeile $r.Output '^Belegter Speicher dort:\s+3[.,]0 GB$')
        Assert-True (Test-Path '.\x.csv')
    }
}
Test-Case 'ohne ruhende Websites steht 0 und der Speicher 0 GB' {
    Start-Test
    $global:MockMon.sites = @($global:MockMon.sites | Where-Object { $_.url -like '*PRJ-Aktiv' })
    Use-Arbeitsordner {
        $r = Invoke-Kopie (Join-Path $skripte 'Get-StaleSiteStats.ps1')
        Assert-True (Test-Zeile $r.Output '^Ohne Aktivitaet seit 180 Tagen: 0 \(0\s?%\)$')
        Assert-True (Test-Zeile $r.Output '^Belegter Speicher dort:\s+0[.,]0 GB$')
    }
}
Test-Case 'Original scheitert an [datetime]::TryParse mit $null als Anfangswert' {
    Start-Test
    Use-Arbeitsordner { Test-OriginalScheitert { Invoke-ScriptUnderTest (Join-Path $skripte 'Get-StaleSiteStats.ps1') } }
}
Test-Case 'bricht ab, wenn der Bericht keine (nicht gelöschten) Websites enthält' {
    Start-Test
    $global:MockMon.sites = @($global:MockMon.sites | Where-Object { $_.deleted })
    Use-Arbeitsordner { Assert-Throws { Invoke-Kopie (Join-Path $skripte 'Get-StaleSiteStats.ps1') } 'Keine Websites im Bericht' }
}

Write-Host 'Listing 102: Get-LabelActivity.ps1'
Test-Case 'fragt die sechs Label-Operationen der letzten 7 Tage in UTC ab' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1')
    Assert-Equal 1 @(Get-Aufruf 'Connect-ExchangeOnline').Count
    $c = @(Get-Aufruf 'Search-UnifiedAuditLog')
    Assert-Equal 1 $c.Count
    $p = $c[0].Parameter
    Assert-Equal @('SensitivityLabelApplied', 'SensitivityLabelUpdated', 'SensitivityLabelRemoved', 'FileSensitivityLabelApplied', 'FileSensitivityLabelChanged', 'FileSensitivityLabelRemoved') @($p.Operations)
    Assert-Equal 5000 $p.ResultSize
    Assert-Equal 'ReturnLargeSet' ([string]$p.SessionCommand)
    Assert-Match $p.SessionId '^lbl-\d{14}$'
    $tage = ($p.EndDate - $p.StartDate).TotalDays
    Assert-True ($tage -gt 6.99 -and $tage -lt 7.01) "Zeitraum 7 Tage, war $tage"
    Assert-True ([math]::Abs(([datetime]::UtcNow - $p.EndDate.ToUniversalTime()).TotalMinutes) -lt 2) 'Ende ist jetzt'
}
Test-Case 'gruppiert nach Operation, häufigste zuerst; andere Operationen und alte Einträge zählen nicht' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1')).OutputText
    Assert-Match $t 'SensitivityLabelApplied\s+3'
    Assert-Match $t 'SensitivityLabelRemoved\s+2'
    Assert-Match $t 'FileSensitivityLabelChanged\s+1'
    Assert-NotMatch $t 'FileDeleted'
    Assert-True ((Get-Pos $t 'SensitivityLabelApplied') -lt (Get-Pos $t 'SensitivityLabelRemoved') -and (Get-Pos $t 'SensitivityLabelRemoved') -lt (Get-Pos $t 'FileSensitivityLabelChanged')) 'Count absteigend'
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1') @{ Tage = 14 }).OutputText
    Assert-Match $t 'SensitivityLabelApplied\s+4' 'mit 14 Tagen kommt der ältere Eintrag dazu'
}
Test-Case 'meldet fehlende Label-Aktivität' {
    Start-Test
    $global:MockMon.labelAudit = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1')
    Assert-Match $r.Text 'Keine Label-Aktivitaet gefunden'
}
Test-Case 'warnt genau ab 5000 Treffern' {
    Start-Test
    $global:MockMon.labelAudit = @(1..4999 | ForEach-Object { [pscustomobject]@{ hoursAgo = 1; operation = 'SensitivityLabelApplied' } })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1')
    Assert-Equal 0 @($r.Warnings).Count '4999 Treffer: keine Warnung'
    $global:MockMon.labelAudit = @(1..5000 | ForEach-Object { [pscustomobject]@{ hoursAgo = 1; operation = 'SensitivityLabelApplied' } })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LabelActivity.ps1')
    Assert-Equal 1 @($r.Warnings).Count
    Assert-Match $r.Warnings[0] '^5000 Treffer erreicht'
}

Write-Host 'Listing 104: Get-IncidentTimes.ps1'
Test-Case 'fragt Vorfälle der letzten 30 Tage in UTC ab und zählt gesamt, gelöst, offen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1')
    Assert-Equal @('SecurityIncident.Read.All') (Get-Scopes)
    $h = Get-FilterStunden ((Get-Aufruf 'Get-MgSecurityIncident')[0].Parameter.Filter)
    Assert-True ($h -gt 719.9 -and $h -lt 720.1) "30 Tage, war $h"
    Assert-True (Test-Zeile $r.Output '^Vorfaelle gesamt:\s+8$') 'Zu-alt liegt außerhalb'
    Assert-True (Test-Zeile $r.Output '^Geloest:\s+2$')
    Assert-True (Test-Zeile $r.Output '^Offen:\s+6$')
}
Test-Case 'berechnet die mittlere Dauer gelöster Vorfälle (24 h und 48 h ergeben 36 h)' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1')
    Assert-True (Test-Zeile $r.Output '^Mittlere Dauer \(Naeherung\): 36[.,]0 Stunden$')
}
Test-Case 'zeigt die fünf ältesten offenen Vorfälle, älteste zuerst' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1')).OutputText
    $teil = $t.Substring((Get-Pos $t '--- Aelteste offene Vorfaelle ---'))
    $p = 1..5 | ForEach-Object { Get-Pos $teil "Offen-$_" }
    Assert-True ($p[0] -ge 0 -and $p[0] -lt $p[1] -and $p[1] -lt $p[2] -and $p[2] -lt $p[3] -and $p[3] -lt $p[4]) 'Reihenfolge nach CreatedDateTime'
    Assert-NotMatch $teil 'Offen-6' 'nur fünf'
    Assert-NotMatch $teil 'Geloest-' 'gelöste gehören nicht dazu'
    Assert-Match $teil 'CreatedDateTime\s+Severity\s+DisplayName'
}
Test-Case '-Tage ändert den Zeitraum; leerer Zeitraum wird gemeldet' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1') @{ Tage = 40 }
    Assert-True (Test-Zeile $r.Output '^Vorfaelle gesamt:\s+9$')
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1') @{ Tage = 0 }
    Assert-Match $r.Text 'Keine Vorfaelle im Zeitraum'
    Assert-NotMatch $r.Text 'Vorfaelle gesamt'
}
Test-Case 'ohne gelöste oder ohne offene Vorfälle steht jeweils 0' {
    Start-Test
    $global:MockMon.incidents = @($global:MockMon.incidents | Where-Object { $_.status -eq 'resolved' })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1')
    Assert-True (Test-Zeile $r.Output '^Offen:\s+0$')
    Assert-True (Test-Zeile $r.Output '^Geloest:\s+2$')
    Start-Test
    $global:MockMon.incidents = @($global:MockMon.incidents | Where-Object { $_.status -ne 'resolved' -and $_.name -ne 'Zu-alt' })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IncidentTimes.ps1')
    Assert-True (Test-Zeile $r.Output '^Geloest:\s+0$')
    Assert-NotMatch $r.Text 'Mittlere Dauer' 'ohne gelöste Vorfälle keine Dauer'
}

Write-Host 'Listing 107: Test-EntraLogFlow.ps1'
Test-Case 'prüft Anmeldeprotokoll und Verzeichnis-Audit der letzten 24 Stunden mit je einem Eintrag' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-Equal @('AuditLog.Read.All', 'Directory.Read.All') (Get-Scopes)
    $s = (Get-Aufruf 'Get-MgAuditLogSignIn')[0].Parameter
    $a = (Get-Aufruf 'Get-MgAuditLogDirectoryAudit')[0].Parameter
    Assert-Equal 1 $s.Top
    Assert-Equal 1 $a.Top
    Assert-Match $s.Filter '^createdDateTime ge \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
    Assert-Match $a.Filter '^activityDateTime ge \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
    foreach ($f in $s.Filter, $a.Filter) { $h = Get-FilterStunden $f; Assert-True ($h -gt 23.9 -and $h -lt 24.1) "24 Stunden, war $h" }
    Assert-True (Test-Zeile $r.Output '^Anmeldeprotokoll\s+OK \(Eintraege vorhanden\)$')
    Assert-True (Test-Zeile $r.Output '^Verzeichnis-Audit\s+OK \(Eintraege vorhanden\)$')
}
Test-Case 'weist darauf hin, wenn in 24 Stunden keine Einträge vorliegen' {
    Start-Test
    $global:MockMon.signInLogs = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-True (Test-Zeile $r.Output '^Anmeldeprotokoll\s+HINWEIS: keine Eintraege in 24 h$')
    Assert-True (Test-Zeile $r.Output '^Verzeichnis-Audit\s+OK ')
    Start-Test
    $global:MockMon.directoryAudits = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-True (Test-Zeile $r.Output '^Anmeldeprotokoll\s+OK ')
    Assert-True (Test-Zeile $r.Output '^Verzeichnis-Audit\s+HINWEIS: keine Eintraege in 24 h$')
}
Test-Case 'zählt Benutzer mit Risiko' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-Equal "riskState eq 'atRisk'" ((Get-Aufruf 'Get-MgRiskyUser')[0].Parameter.Filter)
    Assert-True (Test-Zeile $r.Output '^Benutzer mit Risiko \(atRisk\): 2$')
}
Test-Case 'ohne Risiko-Benutzer, auch bei fehlender Berechtigung, steht 0 (der Fehler wird unterdrückt)' {
    Start-Test
    $global:MockMon.riskyUsers = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-True (Test-Zeile $r.Output '^Benutzer mit Risiko \(atRisk\): 0$')
    Start-Test
    $global:MockMon.options.riskyUnavailable = $true
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EntraLogFlow.ps1')
    Assert-True (Test-Zeile $r.Output '^Benutzer mit Risiko \(atRisk\): 0$')
    Assert-Equal 0 @($r.Errors).Count 'der Fehler wird unterdrückt'
}

Write-Host 'Listing 109: Get-ServiceStatus.ps1'
Test-Case 'listet offene Störungen, neueste zuerst; gelöste fehlen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-ServiceStatus.ps1')
    Assert-Equal @('ServiceHealth.Read.All', 'ServiceMessage.Read.All') (Get-Scopes)
    Assert-Equal 'isResolved eq false' ((Get-Aufruf 'Get-MgServiceAnnouncementIssue')[0].Parameter.Filter)
    $t = $r.OutputText
    $a = Get-Pos $t 'Suche nicht verfuegbar'; $b = Get-Pos $t 'Verzoegerte Mails'; $c = Get-Pos $t 'Anrufe schlagen fehl'
    Assert-True ($a -ge 0 -and $a -lt $b -and $b -lt $c) 'StartDateTime absteigend'
    Assert-NotMatch $t 'Behoben' 'gelöste Störung'
    Assert-Match $t 'Id\s+Service\s+Classification\s+Status\s+StartDateTime\s+Title'
}
Test-Case 'meldet, wenn keine Störung offen ist' {
    Start-Test
    $global:MockMon.serviceIssues = @($global:MockMon.serviceIssues | Where-Object { $_.resolved })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-ServiceStatus.ps1')
    Assert-True (Test-Zeile $r.Output '^Keine offenen Stoerungen gemeldet\.$')
}
Test-Case 'zeigt den Zustand je Dienst alphabetisch' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-ServiceStatus.ps1')).OutputText
    $teil = $t.Substring((Get-Pos $t '--- Zustand je Dienst ---'))
    $a = Get-Pos $teil 'Exchange Online'; $b = Get-Pos $teil 'SharePoint Online'; $c = Get-Pos $teil 'Teams'
    Assert-True ($a -ge 0 -and $a -lt $b -and $b -lt $c) 'nach Service sortiert'
    Assert-Match $teil 'Teams\s+serviceDegradation'
}
Test-Case 'zählt Nachrichten der letzten 7 Tage und listet größere Änderungen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-ServiceStatus.ps1')
    $h = Get-FilterStunden ((Get-Aufruf 'Get-MgServiceAnnouncementMessage')[0].Parameter.Filter)
    Assert-True ($h -gt 167.9 -and $h -lt 168.1) "7 Tage, war $h"
    Assert-True (Test-Zeile $r.Output '^Nachrichtencenter, neu oder geaendert in 7 Tagen: 4$') 'MC5 ist zu alt'
    $t = $r.OutputText
    $teil = $t.Substring((Get-Pos $t 'Nachrichtencenter, neu oder'))
    Assert-Match $teil 'Neue Funktion A'
    Assert-Match $teil 'Neue Funktion C'
    Assert-NotMatch $teil 'Kleine Aenderung B' 'keine größere Änderung'
    Assert-NotMatch $teil 'Info D'
    Assert-NotMatch $teil 'Alte Meldung E' 'außerhalb des Zeitraums'
}
Test-Case 'ohne neue Nachrichten steht 0' {
    Start-Test
    $global:MockMon.serviceMessages = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-ServiceStatus.ps1')
    Assert-True (Test-Zeile $r.Output '^Nachrichtencenter, neu oder geaendert in 7 Tagen: 0$')
}

Write-Host 'Listing 111: Test-Runbooks.ps1'
function New-Runbook {
    param([string]$Name, [string[]]$Abschnitte = @('Zweck', 'Voraussetzungen', 'Schritte', 'Pruefung', 'Rueckweg', 'Eskalation'), $TageAlt = 10, [string]$Ordner = '.')
    $zeilen = @("# Runbook $Name", '')
    foreach ($a in $Abschnitte) { $zeilen += "## $a"; $zeilen += 'Text.'; $zeilen += '' }
    if ($null -ne $TageAlt) { $zeilen += ('Letzte Pruefung: ' + (Get-Date).AddDays(-$TageAlt).ToString('yyyy-MM-dd')) }
    if (-not (Test-Path -LiteralPath $Ordner)) { New-Item -ItemType Directory -Path $Ordner | Out-Null }
    Set-Content -LiteralPath (Join-Path $Ordner "$Name.md") -Value $zeilen -Encoding UTF8
}
$runbookSkript = Join-Path $skripte 'Test-Runbooks.ps1'
Test-Case 'ein vollständiges, aktuelles Runbook braucht keine Pflege' {
    Use-Arbeitsordner {
        New-Runbook 'gast' -TageAlt 10
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'gast\.md\s+-\s+aktuell \(10 Tage\)'
        Assert-True (Test-Zeile $r.Output '^0 von 1 Runbooks brauchen Pflege\.$')
    }
}
Test-Case 'nennt fehlende Abschnitte in der Reihenfolge der Pflichtliste' {
    Use-Arbeitsordner {
        New-Runbook 'luecke' -Abschnitte 'Zweck', 'Schritte', 'Pruefung'
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'luecke\.md\s+Voraussetzungen, Rueckweg, Eskalation\s+aktuell'
        Assert-True (Test-Zeile $r.Output '^1 von 1 Runbooks brauchen Pflege\.$')
    }
}
Test-Case 'erkennt veraltete Prüfdaten und kennt -MaxAlterTage' {
    Use-Arbeitsordner {
        New-Runbook 'alt' -TageAlt 400
        New-Runbook 'neu' -TageAlt 300
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'alt\.md\s+-\s+veraltet \(400 Tage\)'
        Assert-Match $r.OutputText 'neu\.md\s+-\s+aktuell \(300 Tage\)'
        Assert-True (Test-Zeile $r.Output '^1 von 2 Runbooks brauchen Pflege\.$')
        # Grenze: genau das gemeldete Alter ist noch aktuell, ein Tag weniger Spielraum nicht (unabhängig von Uhrzeit und Zeitumstellung)
        $n = [int]([regex]::Match($r.OutputText, 'neu\.md\s+-\s+aktuell \((\d+) Tage\)').Groups[1].Value)
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.'; MaxAlterTage = $n }
        Assert-Match $r.OutputText "neu\.md\s+-\s+aktuell \($n Tage\)"
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.'; MaxAlterTage = $n - 1 }
        Assert-Match $r.OutputText "neu\.md\s+-\s+veraltet \($n Tage\)"
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.'; MaxAlterTage = 100 }
        Assert-Match $r.OutputText 'neu\.md\s+-\s+veraltet \(300 Tage\)'
        Assert-True (Test-Zeile $r.Output '^2 von 2 Runbooks brauchen Pflege\.$')
    }
}
Test-Case 'ein Runbook ohne Datum gilt als pflegebedürftig' {
    Use-Arbeitsordner {
        New-Runbook 'ohnedatum' -TageAlt $null
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'ohnedatum\.md\s+-\s+kein Datum'
        Assert-True (Test-Zeile $r.Output '^1 von 1 Runbooks brauchen Pflege\.$')
    }
}
Test-Case 'sucht in Unterordnern, nur *.md, und wertet nur echte Überschriften' {
    Use-Arbeitsordner {
        New-Runbook 'unten' -Ordner '.\sub'
        Set-Content -LiteralPath '.\notiz.txt' -Value '## Zweck' -Encoding UTF8
        New-Runbook 'nurtext' -Abschnitte 'Zweck'
        $zeilen = @('# Test', 'Zweck: steht nur im Text', 'Siehe auch # Zweck im Handbuch', '## Voraussetzungen', '#Schritte', '### pruefung', '## Rueckweg', '## Eskalation')
        Set-Content -LiteralPath '.\gemischt.md' -Value $zeilen -Encoding UTF8
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'unten\.md'
        Assert-NotMatch $r.OutputText 'notiz\.txt'
        Assert-Match $r.OutputText 'gemischt\.md\s+Zweck\s+kein Datum' 'Text ohne Überschrift zählt nicht; #Schritte und klein geschriebenes pruefung zählen'
        Assert-True (Test-Zeile $r.Output '^2 von 3 Runbooks brauchen Pflege\.$') 'unten ist in Ordnung, nurtext und gemischt nicht'
    }
}
Test-Case 'Hinweis: "Prüfung" mit Umlaut gilt als fehlender Abschnitt' {
    Use-Arbeitsordner {
        New-Runbook 'umlaut' -Abschnitte 'Zweck', 'Voraussetzungen', 'Schritte', 'Prüfung', 'Rueckweg', 'Eskalation'
        $r = Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' }
        Assert-Match $r.OutputText 'umlaut\.md\s+Pruefung\s+aktuell'
    }
}
Test-Case 'bricht ohne Runbooks ab und verlangt -Ordner' {
    Use-Arbeitsordner { Assert-Throws { Invoke-ScriptUnderTest $runbookSkript @{ Ordner = '.' } } 'Keine Runbooks in' }
    Assert-Mandatory $runbookSkript @('Ordner')
}

Write-Host 'Listing 113/114: kpi-definition.json und Get-KpiStatus.ps1'
$kpiDef = Join-Path $skripte 'kpi-definition.json'
function Get-Verlauf { param([string]$Pfad = '.\kpi-verlauf.csv') @(Import-Csv -LiteralPath $Pfad) }
Test-Case 'die Definitionsdatei enthält drei Kennzahlen mit den erwarteten Feldern' {
    $k = Get-Content -LiteralPath $kpiDef -Raw -Encoding UTF8 | ConvertFrom-Json
    $k = @($k)   # Windows PowerShell 5.1 liefert die Liste als ein Objekt, PowerShell 7 einzeln
    Assert-Equal 3 $k.Count
    Assert-Equal @('mfa-abdeckung', 'teams-2-besitzer', 'vorfaelle-offen') @($k | ForEach-Object { $_.id })
    foreach ($e in $k) { foreach ($f in 'id', 'name', 'ziel', 'alarm', 'richtung', 'verantwortlich') { Assert-True ($null -ne $e.$f) "$($e.id): $f" } }
}
Test-Case 'bewertet "höher ist besser" mit Ziel 98 und Alarm 90 (Grenzen eingeschlossen)' {
    Use-Arbeitsordner {
        foreach ($fall in @(@(98, 'gruen'), @(97.9, 'gelb'), @(90, 'gelb'), @(89.9, 'rot'))) {
            Remove-Item '.\kpi-verlauf.csv' -ErrorAction SilentlyContinue
            $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = @{ 'mfa-abdeckung' = $fall[0] } }
            $z = Get-Verlauf
            Assert-Equal $fall[1] $z[0].Status "Wert $($fall[0])"
        }
    }
}
Test-Case 'bewertet "niedriger ist besser" mit Ziel 5 und Alarm 15 (Grenzen eingeschlossen)' {
    Use-Arbeitsordner {
        foreach ($fall in @(@(5, 'gruen'), @(6, 'gelb'), @(15, 'gelb'), @(16, 'rot'))) {
            Remove-Item '.\kpi-verlauf.csv' -ErrorAction SilentlyContinue
            $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = @{ 'vorfaelle-offen' = $fall[0] } }
            Assert-Equal $fall[1] (Get-Verlauf)[0].Status "Wert $($fall[0])"
        }
    }
}
Test-Case 'schreibt Datum, Name, Wert, Ziel, Alarm, Status und Verantwortliche in den Verlauf und zählt rote' {
    Use-Arbeitsordner {
        $w = @{ 'mfa-abdeckung' = 99; 'teams-2-besitzer' = 80; 'vorfaelle-offen' = 20 }
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = $w }
        $z = Get-Verlauf
        Assert-Equal 3 $z.Count
        Assert-Equal @('Datum', 'Kennzahl', 'Wert', 'Ziel', 'Alarm', 'Status', 'Verantwortlich') @($z[0].PSObject.Properties.Name)
        Assert-Equal (Get-Date -Format 'yyyy-MM-dd') $z[0].Datum
        Assert-Equal 'Benutzer mit MFA (Prozent)' $z[0].Kennzahl
        Assert-Equal '98' $z[0].Ziel
        Assert-Equal '90' $z[0].Alarm
        Assert-Equal 'Identity-Team' $z[0].Verantwortlich
        Assert-Equal @('gruen', 'rot', 'rot') @($z | ForEach-Object { $_.Status })
        Assert-True (Test-Zeile $r.Output '^3 Kennzahlen bewertet, 2 rot\.$')
        Assert-Match $r.OutputText 'Kennzahl\s+Wert\s+Ziel\s+Alarm\s+Status\s+Verantwortlich'
    }
}
Test-Case 'warnt bei fehlendem Messwert und lässt die Kennzahl aus' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = @{ 'mfa-abdeckung' = 99 } }
        Assert-Equal @('Kein Messwert fuer teams-2-besitzer', 'Kein Messwert fuer vorfaelle-offen') @($r.Warnings)
        Assert-Equal 1 @(Get-Verlauf).Count
        Assert-True (Test-Zeile $r.Output '^1 Kennzahlen bewertet, 0 rot\.$')
    }
}
Test-Case 'hängt bei jedem Lauf an und akzeptiert -Verlauf' {
    Use-Arbeitsordner {
        $w = @{ 'mfa-abdeckung' = 99 }
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = $w }
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = $w }
        Assert-Equal 2 @(Get-Verlauf).Count
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = $w; Verlauf = '.\anders.csv' }
        Assert-Equal 1 @(Get-Verlauf '.\anders.csv').Count
        Assert-Equal 2 @(Get-Verlauf).Count
    }
}
Test-Case 'ohne bewertbare Kennzahl: drei Warnungen und 0 bewertet' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-KpiStatus.ps1') @{ Definition = $kpiDef; Werte = @{ 'unbekannt' = 1 } }
        Assert-Equal 3 @($r.Warnings).Count
        Assert-True (Test-Zeile $r.Output '^0 Kennzahlen bewertet, 0 rot\.$')
    }
    Assert-Mandatory (Join-Path $skripte 'Get-KpiStatus.ps1') @('Definition', 'Werte')
}

Write-Host 'Aufgabe 4: Anteil der in Teams aktiven Konten'
Test-Case 'berechnet den Anteil der Konten mit Teams-Aktivität in 30 Tagen (gelöschte ausgenommen)' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-Kopie (Join-Path $loesungen 'aufgabe-04-teams-aktiv.ps1')
        Assert-Equal @('Reports.Read.All') (Get-Scopes)
        $c = (Get-Aufruf 'Get-MgReportOffice365ActiveUserDetail')[0].Parameter
        Assert-Equal 'D30' $c.Period
        Assert-Equal '.\aktiv30.csv' $c.OutFile
        Assert-True (Test-Zeile $r.Output '^2 von 6 \(33\s?%\) in Teams aktiv$') 'anna (2 Tage) und fritz (20 Tage); emil (45 Tage) nicht'
    }
}
Test-Case 'Original scheitert an [datetime]::TryParse mit $null als Anfangswert' {
    Start-Test
    Use-Arbeitsordner { Test-OriginalScheitert { Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-04-teams-aktiv.ps1') } }
}
Test-Case 'bricht ab, wenn die Teams-Spalte fehlt' {
    Start-Test
    $global:MockMon.options.omitColumns = @('Teams Last Activity Date')
    Use-Arbeitsordner { Assert-Throws { Invoke-Kopie (Join-Path $loesungen 'aufgabe-04-teams-aktiv.ps1') } 'Spalte fehlt' }
}
Test-Case 'ohne aktive Konten steht 0 von 2' {
    Start-Test
    $global:MockMon.activeUsers = @($global:MockMon.activeUsers | Where-Object { $_.upn -in 'ben@example.com', 'emil@example.com' })
    Use-Arbeitsordner {
        $r = Invoke-Kopie (Join-Path $loesungen 'aufgabe-04-teams-aktiv.ps1')
        Assert-True (Test-Zeile $r.Output '^0 von 2 \(0\s?%\) in Teams aktiv$')
    }
}

Write-Host 'Aufgabe 7: Markdown-Bericht der Kennzahlen'
Test-Case 'schreibt eine Markdown-Tabelle mit roten Kennzahlen zuerst, danach nach Name' {
    Use-Arbeitsordner {
        $ergebnis = @(
            [pscustomobject]@{ Kennzahl = 'B grün'; Wert = 99; Ziel = 98; Status = 'gruen'; Verantwortlich = 'Team 1' },
            [pscustomobject]@{ Kennzahl = 'A gelb'; Wert = 95; Ziel = 98; Status = 'gelb'; Verantwortlich = 'Team 2' },
            [pscustomobject]@{ Kennzahl = 'D rot'; Wert = 80; Ziel = 98; Status = 'rot'; Verantwortlich = 'Team 3' },
            [pscustomobject]@{ Kennzahl = 'C rot'; Wert = 85; Ziel = 98; Status = 'rot'; Verantwortlich = 'Team 4' })
        $null = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-kpi-bericht.ps1')
        $z = @(Get-Content -LiteralPath '.\kpi-bericht.md' -Encoding UTF8)
        Assert-Equal 6 $z.Count
        Assert-Equal '| Kennzahl | Wert | Ziel | Status | Verantwortlich |' $z[0]
        Assert-Equal '|---|---|---|---|---|' $z[1]
        Assert-Equal '| C rot | 85 | 98 | rot | Team 4 |' $z[2]
        Assert-Equal '| D rot | 80 | 98 | rot | Team 3 |' $z[3]
        Assert-Equal '| A gelb | 95 | 98 | gelb | Team 2 |' $z[4]
        Assert-Equal '| B grün | 99 | 98 | gruen | Team 1 |' $z[5]
    }
}

Complete-Tests
