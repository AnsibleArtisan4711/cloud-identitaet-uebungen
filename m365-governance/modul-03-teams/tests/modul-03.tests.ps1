# modul-03.tests.ps1 - Offline-Tests für die Skripte aus Modul 03 (Teams Governance und Collaboration Lifecycle).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-03-teams/tests/modul-03.tests.ps1
# Die Graph-Cmdlets sind simuliert (tools/Mock-MgGraph.ps1). Geprüft wird die Logik der Skripte, nicht das echte Microsoft Graph.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'teams-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

# Hilfen: Gruppe im simulierten Tenant ändern bzw. Test in einem leeren Arbeitsordner ausführen
function Get-Gruppe { param([string]$Id) $global:MockTenant.groups | Where-Object { $_.id -eq $Id } }
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}

Write-Host 'Listing 18: Get-TeamsInventory.ps1'
Test-Case 'schreibt für alle 7 Teams eine Zeile (die Gruppe ohne Team zählt nicht) und sortiert nach Besitzern, dann Alter' {
    Initialize-MockTenant $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamsInventory.ps1')
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'teams-bestand.csv'))
        Assert-Equal 7 $csv.Count
        Assert-Equal 'Marketing intern' $csv[0].Team 'kein Besitzer zuerst'
        Assert-Equal @('KND-Fabrikam-Zusammenarbeit','PRJ-Alpha-Marktstart','PRJ-Beta-Pilot') @($csv[1..3].Team) 'ein Besitzer, älteste zuerst'
        $t2 = $csv | Where-Object { $_.Team -eq 'PRJ-Alpha-Marktstart' }
        Assert-Equal '1' $t2.Besitzer
        Assert-Equal '6' $t2.Mitglieder
        Assert-Equal '2' $t2.Gaeste
        Assert-Equal 'Private' $t2.Sichtbar
        foreach ($name in 'Marketing intern','KND-Fabrikam-Zusammenarbeit','PRJ-Alpha-Marktstart','PRJ-Beta-Pilot') { Assert-Match $r.OutputText ([regex]::Escape($name)) }
        foreach ($name in 'ABT-Vertrieb-Allgemein','GRM-Betriebsrat-Intern','ABT-Einkauf-Lieferanten','Projekt Wiki') { Assert-NotMatch $r.OutputText ([regex]::Escape($name)) "$name hat genug Besitzer bzw. ist kein Team" }
    }
}

Write-Host 'Listing 19: Test-TeamNaming.ps1'
Test-Case 'meldet 6 von 7 Teams als konform und nennt das abweichende Team' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TeamNaming.ps1')
    Assert-Match $r.OutputText '6 von 7 Teams entsprechen der Konvention\.'
    Assert-Match $r.OutputText 'Marketing intern\s+\S+.*False'
    Assert-NotMatch $r.OutputText 'ABT-Vertrieb-Allgemein'
}
Test-Case 'Grenzfälle der Namenskonvention: falsches Präfix, fehlender Teil, Namensteil mit 1 Zeichen' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't1').displayName = 'XYZ-Vertrieb-Allgemein'
    (Get-Gruppe 't2').displayName = 'PRJ-Alpha'
    (Get-Gruppe 't4').displayName = 'KND-Fabrikam-Z'
    (Get-Gruppe 't5').displayName = 'GRM-Betriebsrat-In'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TeamNaming.ps1')
    Assert-Match $r.OutputText '3 von 7 Teams entsprechen der Konvention\.' 'konform bleiben nur GRM-Betriebsrat-In (genau 2 Zeichen), ABT-Einkauf-Lieferanten und PRJ-Beta-Pilot'
    foreach ($n in 'XYZ-Vertrieb-Allgemein','PRJ-Alpha ','KND-Fabrikam-Z','Marketing intern') { Assert-Match $r.OutputText ([regex]::Escape($n)) }
    Assert-NotMatch $r.OutputText 'GRM-Betriebsrat-In\s'
}
Test-Case 'Hinweis: -match unterscheidet nicht zwischen Groß- und Kleinschreibung, "abt-..." gilt daher als konform' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't6').displayName = 'abt-Einkauf-Lieferanten'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TeamNaming.ps1')
    Assert-Match $r.OutputText '6 von 7 Teams entsprechen der Konvention\.'
}

Write-Host 'Listing 21: Get-TeamsGuestReport.ps1'
Test-Case 'listet jeden Gast je Team, zählt Teams mit Gästen und findet den Gast in mehr als 5 Teams' {
    Initialize-MockTenant $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamsGuestReport.ps1')
        Assert-Match $r.OutputText 'Teams mit Gaesten: 6'
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'teams-gaeste.csv'))
        Assert-Equal 9 $csv.Count '2 + 1 + 3 + 1 + 1 + 1'
        Assert-Equal 6 @($csv | Where-Object { $_.GastId -eq 'gx' }).Count
        $ab = $r.OutputText.Substring($r.OutputText.IndexOf('Gaeste in mehr als 5 Teams:'))
        Assert-Match $ab '6\s+\S.*\S+@\S+'
        Assert-Equal 1 ([regex]::Matches($ab, '\n\s*\d+\s+\S').Count) 'genau ein Gast über der Schwelle'
    }
}
Test-Case 'Schwelle ist "mehr als 5": bei genau 5 Teams erscheint niemand' {
    Initialize-MockTenant $fixture
    $global:MockTenant.groups = @($global:MockTenant.groups | Where-Object { $_.id -ne 't7' })
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamsGuestReport.ps1')
        $ab = $r.OutputText.Substring($r.OutputText.IndexOf('Gaeste in mehr als 5 Teams:'))
        Assert-Equal 0 ([regex]::Matches($ab, '\n\s*\d+\s+\S').Count)
    }
}

Write-Host 'Listing 22: Get-TeamsChannelReport.ps1'
Test-Case 'zählt private und freigegebene Kanäle und warnt bei einem Team ohne Zugriff, statt abzubrechen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamsChannelReport.ps1')
    Assert-Equal 1 $r.Warnings.Count
    Assert-Match $r.Warnings[0] "Team 'PRJ-Beta-Pilot': Forbidden"
    Assert-Match $r.OutputText 'Summe private Kanaele: 3, freigegebene Kanaele: 1'
    $t = $r.OutputText
    Assert-True ($t.IndexOf('GRM-Betriebsrat-Intern') -lt $t.IndexOf('PRJ-Alpha-Marktstart')) 'zwei private Kanäle vor einem'
    Assert-True ($t.IndexOf('PRJ-Alpha-Marktstart') -lt $t.IndexOf('Marketing intern')) 'Team nur mit freigegebenem Kanal zuletzt'
    Assert-NotMatch $t 'ABT-Vertrieb-Allgemein' 'Team nur mit Standardkanälen fehlt'
}

Write-Host 'Listing 23: Get-RiskyConsents.ps1'
Test-Case 'zeigt nur Apps mit riskanten Rechten, sortiert, mit Zustimmungsart' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-RiskyConsents.ps1')
    Assert-Match $r.OutputText 'Archiv-Tool\s+AllPrincipals\s+Sites\.ReadWrite\.All, Mail\.ReadWrite'
    Assert-Match $r.OutputText 'Kalender-App\s+AllPrincipals\s+Mail\.Send\s*(\n|$)'
    Assert-NotMatch $r.OutputText 'Notiz-App'
    Assert-NotMatch $r.OutputText 'Calendars\.Read' 'harmlose Rechte werden nicht mit aufgelistet'
    Assert-True ($r.OutputText.IndexOf('Archiv-Tool') -lt $r.OutputText.IndexOf('Kalender-App'))
}
Test-Case 'einzelne Benutzerzustimmung wird ebenfalls erkannt, "Mail.Read" ist nicht riskant' {
    Initialize-MockTenant $fixture
    $global:MockTenant.permissionGrants[1].scope = 'Files.ReadWrite.All Mail.Read'
    $global:MockTenant.permissionGrants[0].scope = 'Mail.Read'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-RiskyConsents.ps1')
    Assert-Match $r.OutputText 'Notiz-App\s+Principal\s+Files\.ReadWrite\.All\s*(\n|$)'
    Assert-NotMatch $r.OutputText 'Kalender-App'
}

Write-Host 'Listing 24: Invoke-TeamArchive.ps1'
Test-Case 'Probelauf archiviert nichts; Teams mit Gästen werden gemeldet und übersprungen' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't6').members = @((Get-Gruppe 't6').members | Where-Object { $_.userType -ne 'Guest' })
    Use-Arbeitsordner { param($tmp)
        "TeamId`nt1`nt2`nt6" | Set-Content -LiteralPath (Join-Path $tmp 'ids.csv') -Encoding UTF8
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Invoke-TeamArchive.ps1') @{ CsvPfad = (Join-Path $tmp 'ids.csv') }
        Assert-Equal 0 @(Get-MockCall 'Invoke-MgArchiveTeam').Count
        Assert-Match $r.OutputText 'PROBELAUF: wuerde archivieren: ABT-Vertrieb-Allgemein'
        Assert-Match $r.OutputText 'PROBELAUF: wuerde archivieren: ABT-Einkauf-Lieferanten'
        Assert-Equal 1 $r.Warnings.Count
        Assert-Match $r.Warnings[0] "'PRJ-Alpha-Marktstart': 2 Gaeste"
    }
}
Test-Case 'mit -Ausfuehren werden nur die Teams ohne Gäste archiviert' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't6').members = @((Get-Gruppe 't6').members | Where-Object { $_.userType -ne 'Guest' })
    Use-Arbeitsordner { param($tmp)
        "TeamId`nt1`nt2`nt6" | Set-Content -LiteralPath (Join-Path $tmp 'ids.csv') -Encoding UTF8
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Invoke-TeamArchive.ps1') @{ CsvPfad = (Join-Path $tmp 'ids.csv'); Ausfuehren = $true }
        $a = @(Get-MockCall 'Invoke-MgArchiveTeam')
        Assert-Equal @('t1','t6') @($a | ForEach-Object { $_.Parameter.TeamId })
        Assert-Match $r.OutputText 'Archivierung angestossen: ABT-Vertrieb-Allgemein'
        Assert-NotMatch $r.OutputText 'PROBELAUF'
    }
}
Test-Case 'schon ein einzelner Gast verhindert die Archivierung' {
    Initialize-MockTenant $fixture
    Use-Arbeitsordner { param($tmp)
        "TeamId`nt3" | Set-Content -LiteralPath (Join-Path $tmp 'ids.csv') -Encoding UTF8
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Invoke-TeamArchive.ps1') @{ CsvPfad = (Join-Path $tmp 'ids.csv'); Ausfuehren = $true }
        Assert-Equal 0 @(Get-MockCall 'Invoke-MgArchiveTeam').Count
        Assert-Match $r.Warnings[0] "'Marketing intern': 1 Gaeste"
    }
}
Test-Case 'Parameter CsvPfad ist Pflicht, Ausfuehren ist ein Schalter' {
    $cmd = Get-Command (Join-Path $skripte 'Invoke-TeamArchive.ps1')
    Assert-True $cmd.Parameters['CsvPfad'].Attributes.Mandatory
    Assert-Equal 'SwitchParameter' $cmd.Parameters['Ausfuehren'].ParameterType.Name
}

Write-Host 'Listing 25: Get-TeamStatus.ps1'
Test-Case 'zeigt Status eines Teams' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamStatus.ps1') @{ TeamName = 'PRJ-Alpha-Marktstart' }
    Assert-Match $r.OutputText 'Name\s+: PRJ-Alpha-Marktstart'
    Assert-Match $r.OutputText 'Archiviert\s+: False'
    Assert-Match $r.OutputText 'Sichtbarkeit\s+: Private'
    Assert-Match $r.OutputText 'Besitzer\s+: \S+@example\.com\s*\n'
    Assert-Match $r.OutputText 'Mitglieder\s+: 6'
    Assert-Match $r.OutputText 'Gaeste\s+: 2'
    Assert-Match $r.OutputText 'Kanaele\s+: 3'
    Assert-Equal 0 $r.Warnings.Count
}
Test-Case 'archiviertes Team wird als archiviert angezeigt' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't3').archived = $true
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamStatus.ps1') @{ TeamName = 'Marketing intern' }
    Assert-Match $r.OutputText 'Archiviert\s+: True'
    Assert-Match $r.OutputText 'Besitzer\s+:\s*\n' 'kein Besitzer: leere Angabe'
}
Test-Case 'unbekanntes Team: Warnung mit Hinweis auf gelöschte Gruppen, keine Ausgabe' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TeamStatus.ps1') @{ TeamName = 'Gibt es nicht' }
    Assert-Equal 1 $r.Warnings.Count
    Assert-Match $r.Warnings[0] 'Keine aktive Gruppe gefunden'
    Assert-Equal '' $r.OutputText
}

Write-Host 'Listing 20: Set-GroupCreationControl.ps1'
Test-Case 'legt die Einstellung neu an, wenn es noch keine gibt' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupCreationControl.ps1') @{ GroupName = 'SEC-Team-Ersteller' }
    $b = (Get-MockCall 'New-MgBetaDirectorySetting')[0].Parameter.Body
    Assert-Equal 'tpl-1' $b.TemplateId 'Vorlage Group.Unified'
    $w = @{}; foreach ($v in $b.Values) { $w[$v.Name] = $v.Value }
    Assert-Equal 'false' $w['EnableGroupCreation']
    Assert-Equal 'g-sec' $w['GroupCreationAllowedGroupId']
    Assert-Equal 0 @(Get-MockCall 'Update-MgBetaDirectorySetting').Count
    Assert-Match $r.OutputText 'Einstellung neu angelegt\.'
    Assert-Match $r.OutputText 'Hinweis: Die Aenderung kann 30 Minuten'
}
Test-Case 'aktualisiert die vorhandene Einstellung (Vorlage Group.Unified), statt eine zweite anzulegen' {
    Initialize-MockTenant $fixture
    $global:MockTenant.directorySettings = @([pscustomobject]@{ id = 'ds-andere'; templateId = 'tpl-2' }, [pscustomobject]@{ id = 'ds-1'; templateId = 'tpl-1' })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupCreationControl.ps1') @{ GroupName = 'SEC-Team-Ersteller' }
    $u = @(Get-MockCall 'Update-MgBetaDirectorySetting')
    Assert-Equal 1 $u.Count
    Assert-Equal 'ds-1' $u[0].Parameter.Id
    Assert-Equal 0 @(Get-MockCall 'New-MgBetaDirectorySetting').Count
    Assert-Match $r.OutputText 'Einstellung aktualisiert\.'
}
Test-Case 'nur eine Einstellung zu einer anderen Vorlage: es wird eine neue angelegt' {
    Initialize-MockTenant $fixture
    $global:MockTenant.directorySettings = @([pscustomobject]@{ id = 'ds-andere'; templateId = 'tpl-2' })
    Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupCreationControl.ps1') @{ GroupName = 'SEC-Team-Ersteller' } | Out-Null
    Assert-Equal 1 @(Get-MockCall 'New-MgBetaDirectorySetting').Count
    Assert-Equal 0 @(Get-MockCall 'Update-MgBetaDirectorySetting').Count
}
Test-Case 'unbekannte Gruppe: Abbruch ohne Änderung' {
    Initialize-MockTenant $fixture
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupCreationControl.ps1') @{ GroupName = 'Gibt es nicht' } | Out-Null } 'nicht gefunden - Abbruch'
    Assert-Equal 0 @(Get-MockCall 'New-MgBetaDirectorySetting').Count
    Assert-Equal 0 @(Get-MockCall 'Update-MgBetaDirectorySetting').Count
}
Test-Case 'mehrdeutiger Gruppenname: Abbruch ohne Änderung' {
    Initialize-MockTenant $fixture
    $global:MockTenant.groups += [pscustomobject]@{ id = 'g-sec2'; displayName = 'SEC-Team-Ersteller'; types = @(); securityEnabled = $true; mailEnabled = $false; ownerCount = 1; createdDaysAgo = 5; isTeam = $false; members = @(); channels = @() }
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupCreationControl.ps1') @{ GroupName = 'SEC-Team-Ersteller' } | Out-Null } 'nicht eindeutig'
    Assert-Equal 0 @(Get-MockCall 'New-MgBetaDirectorySetting').Count
}

Write-Host 'Aufgabe 6: Teams mit weniger als 2 Besitzern und mindestens 1 Gast'
Test-Case 'nennt genau die vier Teams mit Besitzerlücke und Gast' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-06-teams-ohne-besitzer-mit-gaesten.ps1')
    foreach ($n in 'PRJ-Alpha-Marktstart','Marketing intern','KND-Fabrikam-Zusammenarbeit','PRJ-Beta-Pilot') { Assert-Match $r.OutputText ([regex]::Escape($n)) }
    foreach ($n in 'ABT-Vertrieb-Allgemein','GRM-Betriebsrat-Intern','ABT-Einkauf-Lieferanten') { Assert-NotMatch $r.OutputText ([regex]::Escape($n)) }
    Assert-Match $r.OutputText 'KND-Fabrikam-Zusammenarbeit\s+1\s+3'
    Assert-Match $r.OutputText 'Marketing intern\s+0\s+1'
}
Test-Case 'ein Team mit einem Besitzer, aber ohne Gast, erscheint nicht' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't4').members = @((Get-Gruppe 't4').members | Where-Object { $_.userType -ne 'Guest' })
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-06-teams-ohne-besitzer-mit-gaesten.ps1')
    Assert-NotMatch $r.OutputText 'KND-Fabrikam-Zusammenarbeit'
}

Write-Host 'Aufgabe 8: Archivierung nur bei mehr als 365 Tagen ohne Verlängerung, mit Protokoll'
Test-Case 'Probelauf: protokolliert Entscheidungen, archiviert nichts' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't5').renewedDaysAgo = 364
    (Get-Gruppe 't6').renewedDaysAgo = 366
    Use-Arbeitsordner { param($tmp)
        "TeamId`nt1`nt3`nt5`nt6" | Set-Content -LiteralPath (Join-Path $tmp 'ids.csv') -Encoding UTF8
        Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-08-archivierung-mit-protokoll.ps1') @{ CsvPfad = (Join-Path $tmp 'ids.csv') } | Out-Null
        Assert-Equal 0 @(Get-MockCall 'Invoke-MgArchiveTeam').Count
        $log = @(Get-ChildItem -LiteralPath $tmp -Filter 'archivierung-*.log')
        Assert-Equal 1 $log.Count
        Assert-Match $log[0].Name '^archivierung-\d{8}\.log$'
        $zeilen = @(Get-Content -LiteralPath $log[0].FullName)
        Assert-Equal 4 $zeilen.Count
        Assert-Match $zeilen[0] '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d UEBERSPRUNGEN ABT-Vertrieb-Allgemein \(juenger als 365 Tage\)$'
        Assert-Match $zeilen[1] ' PROBELAUF Marketing intern$'
        Assert-Match $zeilen[2] ' UEBERSPRUNGEN GRM-Betriebsrat-Intern ' '364 Tage: knapp unter der Grenze'
        Assert-Match $zeilen[3] ' PROBELAUF ABT-Einkauf-Lieferanten$' '366 Tage: knapp über der Grenze'
    }
}
Test-Case 'mit -Ausfuehren werden nur die abgelaufenen Teams archiviert' {
    Initialize-MockTenant $fixture
    (Get-Gruppe 't6').renewedDaysAgo = 366
    Use-Arbeitsordner { param($tmp)
        "TeamId`nt1`nt3`nt6" | Set-Content -LiteralPath (Join-Path $tmp 'ids.csv') -Encoding UTF8
        Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-08-archivierung-mit-protokoll.ps1') @{ CsvPfad = (Join-Path $tmp 'ids.csv'); Ausfuehren = $true } | Out-Null
        Assert-Equal @('t3','t6') @(Get-MockCall 'Invoke-MgArchiveTeam' | ForEach-Object { $_.Parameter.TeamId })
        $zeilen = @(Get-Content -LiteralPath (Get-ChildItem -LiteralPath $tmp -Filter 'archivierung-*.log')[0].FullName)
        Assert-Match ($zeilen -join "`n") ' ARCHIVIERT Marketing intern'
        Assert-Match ($zeilen -join "`n") ' ARCHIVIERT ABT-Einkauf-Lieferanten'
        Assert-Equal 1 @($zeilen | Where-Object { $_ -match 'UEBERSPRUNGEN' }).Count
    }
}

Complete-Tests
