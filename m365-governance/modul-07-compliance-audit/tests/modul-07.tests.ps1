# modul-07.tests.ps1 - Offline-Tests für die Skripte aus Modul 07 (Compliance, Audit und Risk Management).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-07-compliance-audit/tests/modul-07.tests.ps1
# Audit-, eDiscovery-, Hold- und Rollengruppen-Cmdlets sind simuliert (tools/Mock-Compliance.ps1). Geprüft wird die Logik der Skripte.
# Drei Skripte lesen nur CSV-Dateien; sie laufen mit erfundenen Testdateien in einem Wegwerf-Ordner.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-ExchangeOnline.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Purview.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Compliance.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'compliance-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'
$istPs7 = $PSVersionTable.PSVersion.Major -ge 6

function Start-Test { Initialize-MockCompliance $fixture }
function Get-Aufruf { param([string]$Name) @(Get-MockCall $Name) }
function Get-Position {
    # Index des ersten/letzten Aufrufs mit diesem Namen in $global:MockCalls (-1, wenn nicht vorhanden)
    param([string]$Name, [switch]$Letzte)
    $pos = -1; $i = 0
    foreach ($c in $global:MockCalls) { if ($c.Name -eq $Name -and ($Letzte -or $pos -lt 0)) { $pos = $i }; $i++ }
    $pos
}
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
function New-Csv { param([string]$Pfad, [string[]]$Zeilen) Set-Content -LiteralPath $Pfad -Value $Zeilen -Encoding UTF8 }
function Assert-Mandatory {
    param([string]$Pfad, [string[]]$Namen)
    $cmd = Get-Command $Pfad
    foreach ($n in $Namen) {
        $pflicht = @($cmd.Parameters[$n].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] -and $_.Mandatory }).Count -gt 0
        Assert-True $pflicht "$n ist Pflicht"
    }
}
# Wartezeiten der Skripte durch eine Funktion ohne Wartezeit ersetzen; mehr als 20 Aufrufe gelten als Endlosschleife.
function Start-Sleep {
    param([int]$Seconds, [int]$Milliseconds)
    Add-MockCall 'Start-Sleep' @{ Seconds = $Seconds }
    if (@(Get-MockCall 'Start-Sleep').Count -gt 20) { throw 'Start-Sleep zu oft aufgerufen: Schleife endet nicht' }
}

Write-Host 'Listing 66: Search-FileDeletions.ps1'
Test-Case 'sucht Löschungen eines Benutzers der letzten 7 Tage in UTC, sortiert nach Zeit' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Search-FileDeletions.ps1') @{ Benutzer = 'anna@example.com' }
    $c = @(Get-Aufruf 'Search-UnifiedAuditLog')
    Assert-Equal 1 $c.Count 'Hinweis: nur ein Abruf, keine Seitenabfrage mit gleicher SessionId'
    $p = $c[0].Parameter
    Assert-Equal @('FileDeleted', 'FileRecycled') @($p.Operations)
    Assert-Equal @('anna@example.com') @($p.UserIds)
    Assert-Equal 5000 $p.ResultSize
    Assert-Equal 'ReturnLargeSet' ([string]$p.SessionCommand)
    Assert-Match $p.SessionId '^del-\d{14}$'
    Assert-Equal 'Utc' ([string]$p.StartDate.Kind)
    Assert-True ([math]::Abs(($p.EndDate - $p.StartDate).TotalDays - 7) -lt 0.001) 'Zeitraum 7 Tage'
    Assert-Equal 1 @(Get-Aufruf 'Connect-ExchangeOnline').Count
    Assert-Match $r.Text 'Treffer: 2'
    Assert-Match $r.OutputText 'Vertrag\.docx'
    Assert-Match $r.OutputText 'Angebot\.xlsx'
    Assert-Match $r.OutputText '203\.0\.113\.10'
    Assert-NotMatch $r.OutputText 'Altlast' 'älter als 7 Tage'
    Assert-NotMatch $r.OutputText 'Notizen' 'anderer Benutzer'
    Assert-NotMatch $r.OutputText 'Budget' 'Operation FileAccessed gehört nicht dazu'
    Assert-True ($r.OutputText.IndexOf('Vertrag.docx') -lt $r.OutputText.IndexOf('Angebot.xlsx')) 'ältere Löschung zuerst (die Simulation liefert unsortiert)'
    Assert-Equal 0 @(Get-Aufruf 'Set-AdminAuditLogConfig').Count 'Erfassung ist an: nichts ändern'
    Assert-Equal 0 $r.Warnings.Count
}
Test-Case 'Parameter -Tage 10 bezieht auch die ältere Löschung ein' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Search-FileDeletions.ps1') @{ Benutzer = 'anna@example.com'; Tage = 10 }
    Assert-Match $r.Text 'Treffer: 3'
    Assert-Match $r.OutputText 'Altlast\.docx'
}
Test-Case 'ausgeschaltete Audit-Erfassung: Warnung und Einschalten, bevor gesucht wird' {
    Start-Test
    $global:MockCompliance.auditConfig.unifiedAuditLogIngestionEnabled = $false
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Search-FileDeletions.ps1') @{ Benutzer = 'anna@example.com' }
    Assert-Match ($r.Warnings -join "`n") 'Audit-Erfassung ist ausgeschaltet'
    $s = @(Get-Aufruf 'Set-AdminAuditLogConfig')
    Assert-Equal 1 $s.Count
    Assert-Equal $true $s[0].Parameter.UnifiedAuditLogIngestionEnabled
    Assert-True ((Get-Position 'Set-AdminAuditLogConfig') -lt (Get-Position 'Search-UnifiedAuditLog')) 'erst einschalten, dann suchen'
}
Test-Case 'Benutzer ohne Treffer: "Treffer: 0"' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Search-FileDeletions.ps1') @{ Benutzer = 'niemand@example.com' }
    Assert-Match $r.Text 'Treffer: 0'
}
Test-Case 'Parameter Benutzer ist Pflicht' {
    Assert-Mandatory (Join-Path $skripte 'Search-FileDeletions.ps1') @('Benutzer')
}

Write-Host 'Listing 68: New-EDiscoverySearch.ps1'
$eds = @{ Fall = 'F-2026-05'; Postfach = 'anna@example.com'; Stichwort = 'Vertrag'; Von = '2026-01-01'; Bis = '2026-06-30' }
Test-Case 'legt Fall und Suche an, startet sie, wartet bis "Completed" und meldet Elemente und Größe' {
    Start-Test
    $global:MockCompliance.options.clearLocationWhenNameHasSpacesAndCase = $false   # so tun, als ob die Dokumentation das nicht kennt
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-EDiscoverySearch.ps1') $eds
    $fall = @(Get-Aufruf 'New-ComplianceCase')
    Assert-Equal 1 $fall.Count
    Assert-Equal 'F-2026-05' $fall[0].Parameter.Name
    Assert-Match $fall[0].Parameter.Description 'Genehmigung siehe Ticket'
    $s = (Get-Aufruf 'New-ComplianceSearch')[0].Parameter
    Assert-Equal 'F-2026-05 - Suche 1' $s.Name
    Assert-Equal 'F-2026-05' $s.Case
    Assert-Equal @('anna@example.com') @($s.ExchangeLocation)
    Assert-Equal '(Vertrag) AND (Date>=2026-01-01) AND (Date<=2026-06-30)' $s.ContentMatchQuery
    Assert-Equal 'F-2026-05 - Suche 1' (Get-Aufruf 'Start-ComplianceSearch')[0].Parameter.Identity
    Assert-True ((Get-Position 'New-ComplianceCase') -lt (Get-Position 'New-ComplianceSearch')) 'erst Fall, dann Suche'
    Assert-True ((Get-Position 'New-ComplianceSearch') -lt (Get-Position 'Start-ComplianceSearch')) 'erst anlegen, dann starten'
    Assert-Equal 2 @(Get-Aufruf 'Start-Sleep').Count 'zwei Abfragen: InProgress, dann Completed'
    Assert-Equal 15 (Get-Aufruf 'Start-Sleep')[0].Parameter.Seconds
    Assert-True ($r.Output -contains 'F-2026-05 - Suche 1: 42 Elemente, 1048576 Bytes') 'Ergebniszeile'
}
Test-Case 'vorhandener Fall wird nicht noch einmal angelegt' {
    Start-Test
    $global:MockCompliance.options.clearLocationWhenNameHasSpacesAndCase = $false
    $a = $eds.Clone(); $a.Fall = 'F-2026-01'; $a.Postfach = 'ben@example.com'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-EDiscoverySearch.ps1') $a
    Assert-Equal 0 @(Get-Aufruf 'New-ComplianceCase').Count
    Assert-True ($r.Output -contains 'F-2026-01 - Suche 1: 7 Elemente, 20480 Bytes')
}
Test-Case 'Hinweis: laut Dokumentation wird die ExchangeLocation gelöscht (Name mit Leerzeichen und -Case): die Suche findet nichts' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-EDiscoverySearch.ps1') $eds
    Assert-True ($r.Output -contains 'F-2026-05 - Suche 1: 0 Elemente, 0 Bytes') 'leere Suche, ohne Fehlermeldung'
    Assert-Equal 0 $r.Errors.Count
}
Test-Case 'Hinweis: endet eine Suche mit "Failed", läuft die Warteschleife endlos (hier durch eine Sperre in Start-Sleep abgebrochen)' {
    Start-Test
    $global:MockCompliance.options.searchOutcome = 'Failed'
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'New-EDiscoverySearch.ps1') $eds | Out-Null } 'Schleife endet nicht'
}
Test-Case 'alle fünf Parameter sind Pflicht' {
    Assert-Mandatory (Join-Path $skripte 'New-EDiscoverySearch.ps1') @('Fall', 'Postfach', 'Stichwort', 'Von', 'Bis')
}

Write-Host 'Listing 70: Summary-ComplianceActions.ps1'
$ma = @('Status,Owner,Title', 'Implemented,Anna,A', 'Umgesetzt,Anna,B', 'Open,Ben,C', 'In Progress,Ben,D', 'In Progress,Anna,E', 'Completed,Ida,F')
Test-Case 'zählt je Status und nennt offene Maßnahmen je Verantwortlichem, größte Zahl zuerst' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'ma.csv'; New-Csv $f $ma
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Summary-ComplianceActions.ps1') @{ Datei = $f }
        $t = $r.OutputText
        Assert-True ($r.Output -contains '--- Nach Status ---')
        Assert-True ($r.Output -contains '--- Offene Massnahmen je Verantwortlichem ---')
        Assert-Match $t 'In Progress\s+2'
        Assert-Match $t 'Implemented\s+1'
        $status = $t.Substring(0, $t.IndexOf('--- Offene'))
        Assert-True ($status.IndexOf('In Progress') -lt $status.IndexOf('Implemented')) 'Status mit den meisten Zeilen zuerst'
        $offen = $t.Substring($t.IndexOf('--- Offene'))
        Assert-Match $offen 'Ben\s+2'
        Assert-Match $offen 'Anna\s+1'
        Assert-NotMatch $offen 'Ida' 'Completed zählt als erledigt'
        Assert-True ($offen.IndexOf('Ben') -lt $offen.IndexOf('Anna')) 'Ben (2) vor Anna (1)'
    }
}
Test-Case 'eigene Spaltennamen über Parameter' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'ma.csv'; New-Csv $f @('Zustand,Besitzer,Titel', 'Open,Carl,X', 'Completed,Dora,Y')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Summary-ComplianceActions.ps1') @{ Datei = $f; SpalteStatus = 'Zustand'; SpalteOwner = 'Besitzer'; SpalteTitel = 'Titel' }
        $offen = $r.OutputText.Substring($r.OutputText.IndexOf('--- Offene'))
        Assert-Match $offen 'Carl\s+1'
        Assert-NotMatch $offen 'Dora'
    }
}
Test-Case 'fehlende Spalte: Abbruch mit Liste der vorhandenen Spalten' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'ma.csv'; New-Csv $f @('Status,Title', 'Open,X')
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Summary-ComplianceActions.ps1') @{ Datei = $f } | Out-Null } 'Spalte nicht gefunden: Owner\. Vorhanden: Status, Title'
    }
}
Test-Case 'Datei ohne Zeilen: Abbruch' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'leer.csv'; New-Csv $f @('Status,Owner,Title')
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Summary-ComplianceActions.ps1') @{ Datei = $f } | Out-Null } 'Datei enthaelt keine Zeilen'
    }
}
Test-Case 'Hinweis: "Nicht umgesetzt" enthält "umgesetzt" und zählt deshalb als erledigt' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'ma.csv'; New-Csv $f @('Status,Owner,Title', 'Nicht umgesetzt,Carl,X', 'Open,Dora,Y')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Summary-ComplianceActions.ps1') @{ Datei = $f }
        $offen = $r.OutputText.Substring($r.OutputText.IndexOf('--- Offene'))
        Assert-NotMatch $offen 'Carl' 'fehlt in der Liste der offenen Maßnahmen'
        Assert-Match $offen 'Dora'
    }
}

Write-Host 'Listing 72: Convert-HrExport.ps1'
$hr = @('UPN;Name;Gehalt;Kuendigung;LetzterTag',
        'anna@example.com;Anna Beispiel;1111;01.03.2026;31.05.2026',
        'ben@example.com;Ben Muster;2222;31.02.2026;30.06.2026',
        'ida@example.com;Ida Admin;3333;15.04.2026;01.04.2026',
        'rita@example.com;Rita Recht;4444;10.05.2026;10.05.2026',
        'carl@example.com;Carl Test;5555;1.2.2026;28.02.2026')
# Die Originalzeile "$kuendigung = $null" lässt TryParseExact scheitern (PowerShell 7 und 5.1). Für die Logik-Tests läuft eine Kopie, in der nur
# die Anfangswerte [datetime]::MinValue sind; ein eigener Test prüft das Original.
function New-HrKopie {
    param([string]$Ordner)
    $text = [System.IO.File]::ReadAllText((Join-Path $skripte 'Convert-HrExport.ps1'))
    $alt = '$kuendigung = $null; $letzter = $null'
    Assert-True $text.Contains($alt) 'Anfangswerte im Original gefunden'
    $kopie = Join-Path $Ordner 'Convert-HrExport.kopie.ps1'
    [System.IO.File]::WriteAllText($kopie, $text.Replace($alt, '$kuendigung = [datetime]::MinValue; $letzter = [datetime]::MinValue'), (New-Object System.Text.UTF8Encoding($true)))
    $kopie
}
Test-Case 'Logik (Kopie mit Anfangswert MinValue): gültige Zeilen werden übernommen, ungültige mit Warnung übersprungen, nur drei Spalten' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'personal.csv'; New-Csv $f $hr
        $skript = New-HrKopie $tmp
        $r = Invoke-ScriptUnderTest $skript @{ Eingabe = $f }
        $w = $r.Warnings -join "`n"
        Assert-Equal 3 $r.Warnings.Count
        Assert-Match $w 'Datum ungueltig fuer ben@example\.com'
        Assert-Match $w 'Letzter Tag vor Kuendigung fuer ida@example\.com'
        Assert-Match $w 'Datum ungueltig fuer carl@example\.com'
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'HR-Konnektor.csv') -Encoding UTF8)
        Assert-Equal 2 $csv.Count
        Assert-Equal @('UserPrincipalName', 'ResignationDate', 'LastWorkingDate') @($csv[0].PSObject.Properties.Name)
        Assert-Equal 'anna@example.com' $csv[0].UserPrincipalName
        Assert-Equal '2026-03-01' $csv[0].ResignationDate
        Assert-Equal '2026-05-31' $csv[0].LastWorkingDate
        Assert-Equal '2026-05-10' $csv[1].LastWorkingDate 'letzter Tag = Kündigungstag ist erlaubt'
        $roh = [System.IO.File]::ReadAllText((Join-Path $tmp 'HR-Konnektor.csv'))
        Assert-NotMatch $roh 'Gehalt|1111|Anna Beispiel' 'Datenminimierung: keine weiteren Spalten'
        Assert-True ($r.Output -contains '2 Datensaetze geschrieben nach .\HR-Konnektor.csv')
    }
}
Test-Case 'Logik (Kopie): eigener Ausgabepfad; ohne gültige Zeile "0 Datensaetze"' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'personal.csv'; New-Csv $f @('UPN;Kuendigung;LetzterTag', 'x@example.com;31.02.2026;01.01.2026')
        $skript = New-HrKopie $tmp
        $aus = Join-Path $tmp 'ausgabe.csv'
        $r = Invoke-ScriptUnderTest $skript @{ Eingabe = $f; Ausgabe = $aus }
        Assert-True ($r.Output -contains ('0 Datensaetze geschrieben nach ' + $aus))
        Assert-Equal 1 $r.Warnings.Count
    }
}
Test-Case 'Original: die Datumsprüfung scheitert (TryParseExact mit Anfangswert $null), in PowerShell 7 und in Windows PowerShell 5.1' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'personal.csv'; New-Csv $f $hr
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Convert-HrExport.ps1') @{ Eingabe = $f } | Out-Null } 'TryParseExact'
    }
}
Test-Case 'Parameter Eingabe ist Pflicht' {
    Assert-Mandatory (Join-Path $skripte 'Convert-HrExport.ps1') @('Eingabe')
}

Write-Host 'Listing 74: Test-CommunicationComplianceRoles.ps1'
Test-Case 'listet die Mitglieder der Rollengruppen und nennt, wer Admin und Prüfer zugleich ist' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-CommunicationComplianceRoles.ps1')
    Assert-Equal 1 @(Get-Aufruf 'Connect-IPPSSession').Count
    Assert-Match $r.OutputText 'Communication Compliance Admins\s+Ida Admin'
    Assert-Match $r.OutputText 'Communication Compliance Admins\s+Anna Beispiel'
    Assert-Match $r.OutputText 'Communication Compliance Analysts\s+Ben Muster'
    Assert-Match $r.OutputText 'Communication Compliance Investigators\s+Rita Recht'
    Assert-NotMatch $r.OutputText 'Viewers' 'leere Gruppe erzeugt keine Zeile'
    $t = $r.OutputText
    Assert-True ($t.IndexOf('Admins') -lt $t.IndexOf('Analysts')) 'sortiert nach Gruppe: Admins vor Analysts'
    Assert-True ($t.IndexOf('Analysts') -lt $t.IndexOf('Investigators')) 'sortiert nach Gruppe: Analysts vor Investigators'
    Assert-True ($t.IndexOf('Anna Beispiel') -lt $t.IndexOf('Ida Admin')) 'innerhalb der Gruppe nach Mitglied sortiert (Anna vor Ida)'
    Assert-True ($r.Output -contains '--- Personen in Admin-Gruppe UND Pruefergruppe ---')
    Assert-True ($r.Output -contains 'Anna Beispiel') 'Überschneidung'
    Assert-True (-not ($r.Output -contains 'Ida Admin')) 'nur Admin: keine Überschneidung'
    Assert-Equal 0 $r.Warnings.Count
}
Test-Case 'mehrere Überschneidungen werden alle genannt' {
    Start-Test
    ($global:MockCompliance.roleGroups | Where-Object { $_.name -like '*Admins' }).members = @('Ida Admin', 'Anna Beispiel', 'Rita Recht')
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-CommunicationComplianceRoles.ps1')
    Assert-True ($r.Output -contains 'Anna Beispiel')
    Assert-True ($r.Output -contains 'Rita Recht')
}
Test-Case 'keine Überschneidung: nach der Überschrift folgt kein Name' {
    Start-Test
    ($global:MockCompliance.roleGroups | Where-Object { $_.name -like '*Investigators' }).members = @('Rita Recht')
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-CommunicationComplianceRoles.ps1')
    Assert-True (-not ($r.Output -contains 'Anna Beispiel'))
    Assert-True (-not ($r.Output -contains 'Rita Recht'))
}
Test-Case 'fehlende Rollengruppe: Warnung, die übrigen Gruppen werden trotzdem ausgewertet' {
    Start-Test
    $global:MockCompliance.roleGroups = @($global:MockCompliance.roleGroups | Where-Object { $_.name -notlike '*Viewers' })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-CommunicationComplianceRoles.ps1')
    Assert-Match ($r.Warnings -join "`n") 'Rollengruppe nicht gefunden: Communication Compliance Viewers'
    Assert-Equal 3 @(Get-Aufruf 'Get-RoleGroupMember').Count
    Assert-True ($r.Output -contains 'Anna Beispiel')
}

Write-Host 'Listing 76: New-CaseHold.ps1'
$hold = @{ Fall = 'F-2026-09'; Postfaecher = @('anna@example.com', 'ben@example.com'); OneDriveUrls = @('https://example-my.sharepoint.com/personal/anna_example_com') }
Test-Case 'legt Fall, Sperrrichtlinie (Postfächer und OneDrive) und Regel ohne Abfrage an und liest den Verteilungsstatus' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaseHold.ps1') $hold
    Assert-Equal 1 @(Get-Aufruf 'Connect-IPPSSession').Count
    Assert-Equal 'F-2026-09' (Get-Aufruf 'New-ComplianceCase')[0].Parameter.Name
    $p = (Get-Aufruf 'New-CaseHoldPolicy')[0].Parameter
    Assert-Equal 'F-2026-09 - Sperre' $p.Name
    Assert-Equal 'F-2026-09' $p.Case
    Assert-Equal @('anna@example.com', 'ben@example.com') @($p.ExchangeLocation)
    Assert-Equal @('https://example-my.sharepoint.com/personal/anna_example_com') @($p.SharePointLocation)
    Assert-Equal $true $p.Enabled
    $regel = (Get-Aufruf 'New-CaseHoldRule')[0].Parameter
    Assert-Equal 'F-2026-09 - Sperre - Regel' $regel.Name
    Assert-Equal 'F-2026-09 - Sperre' $regel.Policy
    Assert-True (-not $regel.ContainsKey('ContentMatchQuery')) 'ohne Abfrage: alles halten'
    Assert-True ((Get-Position 'New-ComplianceCase') -lt (Get-Position 'New-CaseHoldPolicy')) 'Fall vor Richtlinie'
    Assert-True ((Get-Position 'New-CaseHoldPolicy') -lt (Get-Position 'New-CaseHoldRule')) 'Richtlinie vor Regel'
    $g = (Get-Aufruf 'Get-CaseHoldPolicy')[0].Parameter
    Assert-Equal 'F-2026-09 - Sperre' $g.Identity
    Assert-Equal $true ([bool]$g.DistributionDetail)
    Assert-Match $r.OutputText 'F-2026-09 - Sperre\s+True\s+Pending'
    Assert-Equal 0 $r.Errors.Count
}
Test-Case 'vorhandener Fall wird nicht noch einmal angelegt' {
    Start-Test
    $a = $hold.Clone(); $a.Fall = 'F-2026-01'
    Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaseHold.ps1') $a | Out-Null
    Assert-Equal 0 @(Get-Aufruf 'New-ComplianceCase').Count
    Assert-Equal 'F-2026-01 - Sperre' (Get-Aufruf 'New-CaseHoldPolicy')[0].Parameter.Name
}
Test-Case 'Hinweis: ohne -OneDriveUrls wird ein leeres Array als SharePointLocation übergeben' {
    Start-Test
    Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaseHold.ps1') @{ Fall = 'F-2026-09'; Postfaecher = @('anna@example.com') } | Out-Null
    $p = (Get-Aufruf 'New-CaseHoldPolicy')[0].Parameter
    Assert-True $p.ContainsKey('SharePointLocation')
    Assert-Equal 0 @($p.SharePointLocation).Count
}
Test-Case 'Hinweis: ein zweiter Lauf mit demselben Fall scheitert, weil die Sperrrichtlinie schon existiert' {
    Start-Test
    Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaseHold.ps1') $hold | Out-Null
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaseHold.ps1') $hold
    Assert-Equal 1 $r.Errors.Count
    Assert-Match $r.Errors[0] "Sperrrichtlinie 'F-2026-09 - Sperre' existiert bereits"
}
Test-Case 'Fall und Postfaecher sind Pflicht' {
    Assert-Mandatory (Join-Path $skripte 'New-CaseHold.ps1') @('Fall', 'Postfaecher')
}

Write-Host 'Listing 78: Test-EvidenceMatrix.ps1'
$kopf = 'Anforderung;Kontrollziel;Massnahme;Verantwortlich;Nachweis;Status'
Test-Case 'nennt je Zeile die Lücken mit Grund und zählt die betroffenen Zeilen' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'
        New-Csv $f @($kopf, 'R1;Z1;M1;V1;N1;umgesetzt', 'R2;Z2;;V2;N2;umgesetzt', 'R3;Z3;M3;;N3;umgesetzt', 'R4;Z4;M4;V4;;umgesetzt',
                     'R5;Z5;M5;V5;N5;offen', 'R6;Z6;  ;;;Open')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f }
        $t = $r.OutputText
        Assert-NotMatch $t '(?m)^R1\s' 'vollständige Zeile'
        Assert-Match $t '(?m)^R2\s+Z2\s+keine Massnahme\s*$'
        Assert-Match $t '(?m)^R3\s+Z3\s+kein Verantwortlicher\s*$'
        Assert-Match $t '(?m)^R4\s+Z4\s+kein Nachweis\s*$'
        Assert-Match $t '(?m)^R5\s+Z5\s+Status offen\s*$'
        Assert-Match $t '(?m)^R6\s+Z6\s+keine Massnahme; kein Verantwortlicher; kein Nachweis; Status offen\s*$'
        Assert-True ($r.Output -contains '5 von 6 Zeilen mit Luecken')
    }
}
Test-Case 'ohne Lücken: "Keine Luecken gefunden." und 0 Zeilen' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'
        New-Csv $f @($kopf, 'R1;Z1;M1;V1;N1;umgesetzt', 'R2;Z2;M2;V2;N2;geplant')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f }
        Assert-True ($r.Output -contains 'Keine Luecken gefunden.')
        Assert-True ($r.Output -contains '0 von 2 Zeilen mit Luecken')
    }
}
Test-Case 'fehlende Spalten: Abbruch mit Namen der fehlenden Spalten' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'
        New-Csv $f @('Anforderung;Kontrollziel;Massnahme;Verantwortlich', 'R1;Z1;M1;V1')
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f } | Out-Null } 'Spalten fehlen: Nachweis, Status'
    }
}
Test-Case 'mit Komma getrennte Datei wird abgelehnt (erwartet wird das Semikolon)' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'
        New-Csv $f @($kopf.Replace(';', ','), 'R1,Z1,M1,V1,N1,umgesetzt')
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f } | Out-Null } 'Spalten fehlen'
    }
}
Test-Case 'Datei ohne Zeilen: Abbruch' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'; New-Csv $f @($kopf)
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f } | Out-Null } 'Keine Zeilen in'
    }
}
Test-Case 'Hinweis: "erledigt, keine offenen Punkte" enthält "offen" und wird als Lücke gemeldet' {
    Use-Arbeitsordner { param($tmp)
        $f = Join-Path $tmp 'matrix.csv'
        New-Csv $f @($kopf, 'R7;Z7;M7;V7;N7;"erledigt, keine offenen Punkte"')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = $f }
        Assert-Match $r.OutputText '(?m)^R7\s+Z7\s+Status offen\s*$'
    }
}

Write-Host 'Listing 80: Test-ComplianceHealth.ps1'
Test-Case 'prüft Audit, Stichprobe, aktive Fälle und Sperrrichtlinien' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-ComplianceHealth.ps1')
    $t = $r.OutputText
    Assert-Equal 1 @(Get-Aufruf 'Connect-ExchangeOnline').Count
    Assert-Equal 1 @(Get-Aufruf 'Connect-IPPSSession').Count
    Assert-Match $t '(?m)^Audit-Erfassung\s+OK\s+UnifiedAuditLogIngestionEnabled = True'
    Assert-Match $t '(?m)^Audit-Eintraege letzte 24 h\s+OK\s+Treffer in Stichprobe: 3'
    Assert-Match $t '(?m)^Aktive eDiscovery-Faelle\s+OK\s+2 aktiv'
    Assert-Match $t '(?m)^Sperrrichtlinien verteilt\s+HINWEIS\s+3 gesamt, 1 nicht erfolgreich'
    $s = (Get-Aufruf 'Search-UnifiedAuditLog')[0].Parameter
    Assert-Equal 5 $s.ResultSize
    Assert-True ([math]::Abs(($s.EndDate - $s.StartDate).TotalHours - 24) -lt 0.01) 'Stichprobe: letzte 24 Stunden'
    Assert-Equal $true ([bool](Get-Aufruf 'Get-CaseHoldPolicy')[0].Parameter.DistributionDetail)
}
Test-Case 'ausgeschaltete Erfassung und keine Einträge in 24 Stunden: beide Zeilen HINWEIS' {
    Start-Test
    $global:MockCompliance.auditConfig.unifiedAuditLogIngestionEnabled = $false
    $global:MockCompliance.auditLog = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-ComplianceHealth.ps1')
    Assert-Match $r.OutputText '(?m)^Audit-Erfassung\s+HINWEIS\s+UnifiedAuditLogIngestionEnabled = False'
    Assert-Match $r.OutputText '(?m)^Audit-Eintraege letzte 24 h\s+HINWEIS\s+Treffer in Stichprobe: 0'
}
Test-Case 'schon ein einziger Audit-Eintrag in 24 Stunden genügt für OK' {
    Start-Test
    $global:MockCompliance.auditLog = @($global:MockCompliance.auditLog | Where-Object { $_.hoursAgo -eq 5 })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-ComplianceHealth.ps1')
    Assert-Match $r.OutputText '(?m)^Audit-Eintraege letzte 24 h\s+OK\s+Treffer in Stichprobe: 1'
}
Test-Case 'alle Sperrrichtlinien verteilt: OK' {
    Start-Test
    foreach ($p in $global:MockCompliance.holdPolicies) { $p.status = 'Success' }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-ComplianceHealth.ps1')
    Assert-Match $r.OutputText '(?m)^Sperrrichtlinien verteilt\s+OK\s+3 gesamt, 0 nicht erfolgreich'
}
Test-Case 'Hinweis: eine ausgeschaltete Sperrrichtlinie mit Status "Success" gilt als in Ordnung (Enabled wird nicht geprüft)' {
    Start-Test
    foreach ($p in $global:MockCompliance.holdPolicies) { $p.status = 'Success' }
    $aus = @($global:MockCompliance.holdPolicies | Where-Object { -not $_.enabled })
    Assert-Equal 1 $aus.Count 'Testdaten enthalten eine ausgeschaltete Sperre'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-ComplianceHealth.ps1')
    Assert-Match $r.OutputText '(?m)^Sperrrichtlinien verteilt\s+OK'
}

Write-Host 'Aufgabe 4: Erstellungen von Freigabelinks der letzten drei Tage'
Test-Case 'listet SharingLinkCreated der letzten 3 Tage mit Zeit, Benutzer und Datei, älteste zuerst' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-04-sharing-links.ps1')
    $p = (Get-Aufruf 'Search-UnifiedAuditLog')[0].Parameter
    Assert-Equal @('SharingLinkCreated') @($p.Operations)
    Assert-Equal 5000 $p.ResultSize
    Assert-True ([math]::Abs(($p.EndDate - $p.StartDate).TotalDays - 3) -lt 0.001) 'drei Tage'
    Assert-Match $r.OutputText 'Aktionsplan\.pdf'
    Assert-Match $r.OutputText 'Konzept\.docx'
    Assert-NotMatch $r.OutputText 'Altentwurf' 'vier Tage alt'
    Assert-NotMatch $r.OutputText 'Vertrag' 'andere Operation'
    Assert-True ($r.OutputText.IndexOf('Konzept.docx') -lt $r.OutputText.IndexOf('Aktionsplan.pdf')) 'ältester Eintrag zuerst'
    Assert-Match $r.OutputText 'ben@example\.com'
}

Write-Host 'Aufgabe 7: Nachweismatrix als CSV'
Test-Case 'die sechs Zeilen der Lösung haben keine Lücken' {
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-EvidenceMatrix.ps1') @{ Datei = (Join-Path $loesungen 'nachweismatrix-aufgabe-07.csv') }
    Assert-True ($r.Output -contains 'Keine Luecken gefunden.')
    Assert-True ($r.Output -contains '0 von 6 Zeilen mit Luecken')
}

Complete-Tests
