# modul-11.tests.ps1 - Offline-Tests für die Skripte aus Modul 11 (Automation, Graph API und Policy-as-Code).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-11-automation/tests/modul-11.tests.ps1
# Graph-, Exchange- und Ticket-Aufrufe sind simuliert (tools/Mock-Automation.ps1, erfundene Daten in tools/fixtures/automation-klein.json).
# Geprüft wird die Logik der Skripte, nicht das Verhalten eines echten Tenants oder eines echten Ticket-Systems.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Automation.ps1')   # überschreibt mehrere Funktionen anderer Mocks
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'automation-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test { Initialize-MockAutomation $fixture }
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
function Get-Scopes { param([int]$Index = 0) @((Get-Aufruf 'Connect-MgGraph')[$Index].Parameter.Scopes) }
function Test-Zeile { param($Ausgabe, [string]$Muster) @($Ausgabe | Where-Object { $_ -match $Muster }).Count -gt 0 }
function Get-Funktionsteil {
    # Text eines Skripts bis zur ersten Zeile, die mit der Marke beginnt (nur die Funktionen, ohne den Aufrufteil)
    param([string]$Pfad, [string]$Marke)
    $text = Get-Content -LiteralPath $Pfad -Raw -Encoding UTF8
    $i = $text.IndexOf($Marke, [System.StringComparison]::Ordinal)
    if ($i -lt 0) { throw "Marke '$Marke' nicht gefunden in $Pfad" }
    $text.Substring(0, $i)
}
function Write-Datei { param([string]$Pfad, [string]$Text) Set-Content -LiteralPath $Pfad -Value $Text -Encoding UTF8 }
function Get-ExitCode { $global:LASTEXITCODE }
function Invoke-MitExit { param([string]$Pfad, [hashtable]$Arg = @{}) $global:LASTEXITCODE = $null; Invoke-ScriptUnderTest $Pfad $Arg }
function Read-JsonListe { param([string]$Pfad) $k = Get-Content -LiteralPath $Pfad -Raw -Encoding UTF8 | ConvertFrom-Json; $k = @($k); $k }
function Set-Gruppe { param([string]$Id, [string]$Feld, $Wert) $g = @($global:MockAut.groups | Where-Object { $_.id -eq $Id })[0]; $g.$Feld = $Wert }

# ---------------------------------------------------------------- Listing 134
Write-Host 'Listing 134: Graph-Bausteine.ps1'
$graph = Join-Path $skripte 'Graph-Bausteine.ps1'
$graphCode = [scriptblock]::Create((Get-Funktionsteil $graph 'Connect-MgGraph -Scopes'))
$gruppenUri = 'https://graph.microsoft.com/v1.0/groups?$select=id,displayName&$top=100'
Test-Case 'Get-GraphAll folgt dem nextLink unverändert bis zur letzten Seite' {
    Start-Test; . $graphCode
    $r = @(Get-GraphAll -Uri $gruppenUri)
    Assert-Equal 6 $r.Count
    Assert-Equal @('g1', 'g2', 'g3', 'g4', 'g5', 'g7') @($r | ForEach-Object { $_.id })
    $c = @(Get-Aufruf 'Invoke-MgGraphRequest')
    Assert-Equal 2 $c.Count 'zwei Seiten zu je drei Gruppen'
    Assert-Equal $gruppenUri $c[0].Parameter.Uri
    Assert-Equal 'https://graph.microsoft.com/v1.0/groups?$skiptoken=3' $c[1].Parameter.Uri 'Adresse der nächsten Seite unverändert'
    Assert-Equal 'GET' $c[1].Parameter.Method
}
Test-Case 'Get-GraphAll: eine einzige Seite, und eine leere Antwort ergibt keine Ausgabe' {
    Start-Test; . $graphCode
    $global:MockAut.options.pageSize = 100
    Assert-Equal 6 @(Get-GraphAll -Uri $gruppenUri).Count
    Assert-Equal 1 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
    $global:MockAut.groups = @()
    Assert-Equal 0 @(Get-GraphAll -Uri $gruppenUri).Count
}
Test-Case 'Hinweis: bei genau einem Ergebnis ist .Count die Zahl der Schlüssel, nicht 1' {
    Start-Test; . $graphCode
    $global:MockAut.groups = @($global:MockAut.groups | Where-Object { $_.id -eq 'g1' })
    $x = Get-GraphAll -Uri $gruppenUri
    Assert-True ($x -is [hashtable]) 'ein einzelnes Ergebnis wird ausgepackt'
    Assert-Equal 3 $x.Count 'drei Schlüssel: id, displayName, createdDateTime'
    Assert-Equal 1 @(Get-GraphAll -Uri $gruppenUri).Count 'mit @() stimmt die Zahl'
}
Test-Case 'Get-GraphBatch teilt in Pakete zu 20 und nummeriert die Anfragen durchgehend' {
    Start-Test; . $graphCode
    $pfade = @(0..44 | ForEach-Object { '/groups/x{0}/owners?$select=id' -f $_ })
    $r = Get-GraphBatch -Pfade $pfade
    $c = @(Get-Aufruf 'Invoke-MgGraphRequest')
    Assert-Equal 3 $c.Count
    $groessen = @($c | ForEach-Object { @(($_.Parameter.Body | ConvertFrom-Json).requests).Count })
    Assert-Equal @(20, 20, 5) $groessen
    Assert-Equal 'POST' $c[0].Parameter.Method
    Assert-Equal 'https://graph.microsoft.com/v1.0/$batch' $c[0].Parameter.Uri
    Assert-Equal 'application/json' $c[0].Parameter.ContentType
    $erste = @(($c[1].Parameter.Body | ConvertFrom-Json).requests)[0]
    Assert-Equal '20' $erste.id 'Nummer zählt über die Pakete hinweg'
    Assert-Equal $pfade[20] $erste.url
    Assert-Equal 45 $r.Count
    Assert-Equal 200 $r[$pfade[44]].status
    Assert-Equal '44' $r[$pfade[44]].id
}
Test-Case 'Get-GraphBatch: genau 20 Pfade sind ein Paket, 21 sind zwei' {
    Start-Test; . $graphCode
    $null = Get-GraphBatch -Pfade @(1..20 | ForEach-Object { "/groups/y$_/owners" })
    Assert-Equal 1 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
    Start-Test; . $graphCode
    $null = Get-GraphBatch -Pfade @(1..40 | ForEach-Object { "/groups/y$_/owners" })
    Assert-Equal 2 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
}
Test-Case 'Get-GraphBatch: auch ein einzelner übrig bleibender Pfad bleibt eine vollständige Adresse' {
    Start-Test; . $graphCode
    $pfade = @(1..21 | ForEach-Object { "/groups/z$_/owners" })
    $r = Get-GraphBatch -Pfade $pfade
    $letztes = @(((Get-Aufruf 'Invoke-MgGraphRequest')[1].Parameter.Body | ConvertFrom-Json).requests)
    Assert-Equal 1 $letztes.Count
    Assert-Equal '/groups/z21/owners' ([string]$letztes[0].url)
    Assert-Equal '20' ([string]$letztes[0].id)
    Assert-Equal 21 $r.Count
    Start-Test; . $graphCode
    $null = Get-GraphBatch -Pfade @('/groups/einzeln/owners')
    $einzeln = @(((Get-Aufruf 'Invoke-MgGraphRequest')[0].Parameter.Body | ConvertFrom-Json).requests)
    Assert-Equal '/groups/einzeln/owners' ([string]$einzeln[0].url)
}
Test-Case 'das Skript als Ganzes liest die Gruppen und zählt gedrosselte Stapelantworten' {
    Start-Test
    $r = Invoke-ScriptUnderTest $graph
    Assert-Equal @('Group.Read.All') (Get-Scopes)
    Assert-True ($r.Output -contains '6 Gruppen gelesen.')
    Assert-True ($r.Output -contains '6 Stapelantworten, davon 0 gedrosselt.')
    $post = (Get-Aufruf 'Invoke-MgGraphRequest') | Where-Object { $_.Parameter.Method -eq 'POST' }
    $urls = @((@($post)[0].Parameter.Body | ConvertFrom-Json).requests | ForEach-Object { $_.url })
    Assert-Equal '/groups/g1/owners?$select=id' $urls[0]
    Start-Test
    $global:MockAut.options.throttleBatchIds = @('1', '4')
    $r = Invoke-ScriptUnderTest $graph
    Assert-True ($r.Output -contains '6 Stapelantworten, davon 2 gedrosselt.')
}
Test-Case 'Hinweis: gedrosselte Antworten (429) werden nur gezählt, nicht wiederholt' {
    Start-Test
    $global:MockAut.options.throttleBatchIds = @('0', '1', '2')
    $null = Invoke-ScriptUnderTest $graph
    $post = @((Get-Aufruf 'Invoke-MgGraphRequest') | Where-Object { $_.Parameter.Method -eq 'POST' })
    Assert-Equal 1 $post.Count
}

# ---------------------------------------------------------------- Listing 136
Write-Host 'Listing 136: Set-MissingGroupDescription.ps1'
$beschr = Join-Path $skripte 'Set-MissingGroupDescription.ps1'
function Get-Protokoll { @(Import-Csv -LiteralPath '.\beschreibung-protokoll.csv') }
Test-Case 'mit -WhatIf wird nichts geändert; Hinweis: auch das Protokoll wird dann nicht geschrieben' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'Zweck ergaenzen'; WhatIf = $true }
        Assert-Equal @('Group.ReadWrite.All') (Get-Scopes)
        Assert-Equal 0 @(Get-Aufruf 'Update-MgGroup').Count
        Assert-True (-not (Test-Path '.\beschreibung-protokoll.csv')) 'WhatIf gilt auch für Export-Csv'
        Assert-True ($r.Output -contains '4 Gruppen bearbeitet.') 'die Zahl zählt die geplanten Änderungen mit'
    }
}
Test-Case 'ohne -WhatIf: Text mit Gruppenname, nur Gruppen ohne Beschreibung, Sicherheitsgruppen bleiben außen vor' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'Zweck ergaenzen' }
        $u = @(Get-Aufruf 'Update-MgGroup')
        Assert-Equal @('g2', 'g3', 'g4', 'g7') @($u | ForEach-Object { $_.Parameter.GroupId })
        Assert-Equal 'Zweck ergaenzen (ABT-HR-Team)' $u[0].Parameter.Description
        Assert-Equal 'Zweck ergaenzen (KND-XY-Alt)' $u[3].Parameter.Description
        $p = Get-Protokoll
        Assert-Equal @('Zeit', 'GruppenId', 'Name', 'Status') @($p[0].PSObject.Properties.Name)
        Assert-Equal @('g2', 'g3', 'g4', 'g7') @($p | ForEach-Object { $_.GruppenId })
        Assert-Equal @('gesetzt') @($p | ForEach-Object { $_.Status } | Select-Object -Unique)
        Assert-Match $p[0].Zeit '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
        Assert-Equal 'Messeauftritt' (@($global:MockAut.groups | Where-Object { $_.id -eq 'g1' })[0].description) 'vorhandene Beschreibung bleibt'
        Assert-Equal '' (@($global:MockAut.groups | Where-Object { $_.id -eq 'g6' })[0].description) 'Sicherheitsgruppe bleibt'
    }
}
Test-Case 'ein zweiter Lauf ist wirkungslos (idempotent) und ändert das Protokoll nicht' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'Zweck ergaenzen' }
        $global:MockCalls.Clear()
        $r = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'Zweck ergaenzen' }
        Assert-Equal 0 @(Get-Aufruf 'Update-MgGroup').Count
        Assert-True ($r.Output -contains '0 Gruppen bearbeitet.')
        Assert-Equal 4 (Get-Protokoll).Count
    }
}
Test-Case 'ein Fehler bei einer Gruppe wird protokolliert, die übrigen werden trotzdem bearbeitet' {
    Start-Test
    $global:MockAut.options.updateFailIds = @('g3')
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'Zweck ergaenzen' }
        $p = Get-Protokoll
        Assert-Equal @('gesetzt', 'Fehler: Mock: Aktualisierung von ''g3'' abgelehnt.', 'gesetzt', 'gesetzt') @($p | ForEach-Object { $_.Status })
    }
}
Test-Case 'das Protokoll wird fortgeschrieben: der Wiederholungslauf hängt nur die zuvor gescheiterte Gruppe an' {
    Start-Test
    $global:MockAut.options.updateFailIds = @('g3')
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'x' }
        $global:MockAut.options.updateFailIds = @()
        $r = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'x' }
        Assert-True ($r.Output -contains '1 Gruppen bearbeitet.')
        $p = Get-Protokoll
        Assert-Equal 5 $p.Count
        Assert-Equal 'gesetzt' $p[4].Status
        Assert-Equal 'g3' $p[4].GruppenId
    }
}
Test-Case 'eine Beschreibung nur aus Leerzeichen gilt als fehlend; Standardtext ist Pflicht und darf nicht leer sein' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $beschr @{ Standardtext = 'x' }
        Assert-True (@(Get-Protokoll | Where-Object { $_.GruppenId -eq 'g4' }).Count -eq 1) 'g4 hat nur Leerzeichen'
        Assert-Throws { Invoke-ScriptUnderTest $beschr @{ Standardtext = '' } }
    }
    Assert-Mandatory $beschr @('Standardtext')
}

# ---------------------------------------------------------------- Listing 138
Write-Host 'Listing 138: Export-TenantConfig.ps1'
$export = Join-Path $skripte 'Export-TenantConfig.ps1'
Test-Case 'schreibt drei Dateien in den Zielordner und meldet sie' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        Assert-Equal @('bedingter-zugriff.json', 'gruppen-ablauf.json', 'transportregeln.json') @(Get-ChildItem '.\out' | ForEach-Object { $_.Name } | Sort-Object)
        Assert-Equal @('Policy.Read.All') (Get-Scopes 0)
        Assert-Equal @('Directory.Read.All') (Get-Scopes 1)
        Assert-Equal 2 @(Get-Aufruf 'Connect-MgGraph').Count
        Assert-Equal 1 @(Get-Aufruf 'Connect-ExchangeOnline').Count
        Assert-True (Test-Zeile $r.Output '^Export abgeschlossen: 3 Dateien in \.\\?/?out$')
    }
}
Test-Case 'ohne Parameter landet der Export in .\config-export' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export
        Assert-True (Test-Path '.\config-export\transportregeln.json')
    }
}
Test-Case 'bedingter Zugriff: nach Namen sortiert, ohne Änderungszeitpunkt' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        $ca = @(Read-JsonListe '.\out\bedingter-zugriff.json')
        Assert-Equal @('CA-01 Administratoren', 'CA-02 MFA fuer alle') @($ca | ForEach-Object { $_.DisplayName })
        Assert-True ($null -eq $ca[0].PSObject.Properties['ModifiedDateTime']) 'flüchtiges Feld entfernt'
        Assert-Equal 'enabled' $ca[1].State
        Assert-Equal 'mfa' $ca[1].Grant
    }
}
Test-Case 'Transportregeln: nach Namen sortiert, genau die sechs ausgewählten Felder (ohne WhenChanged)' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        $t = @(Read-JsonListe '.\out\transportregeln.json')
        Assert-Equal @('Alpha Archivierung', 'Zeta Externe Kennzeichnung') @($t | ForEach-Object { $_.Name })
        Assert-Equal @('Name', 'Priority', 'State', 'Mode', 'Comments', 'Description') @($t[0].PSObject.Properties.Name)
    }
}
Test-Case 'Ablaufrichtlinie: die drei ausgewählten Felder' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        $l = @(Read-JsonListe '.\out\gruppen-ablauf.json')
        Assert-Equal 1 $l.Count
        Assert-Equal @('GroupLifetimeInDays', 'ManagedGroupTypes', 'AlternateNotificationEmails') @($l[0].PSObject.Properties.Name)
        Assert-Equal 365 $l[0].GroupLifetimeInDays
    }
}
Test-Case 'der Export ist stabil: geänderte Zeitstempel ändern die Dateien nicht' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\a' }
        foreach ($p in @($global:MockAut.caPolicies)) { $p.ModifiedDateTime = '2030-01-01T00:00:00Z' }
        foreach ($r in @($global:MockAut.transportRules)) { $r.WhenChanged = '2030-01-01T00:00:00Z' }
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\b' }
        foreach ($n in 'bedingter-zugriff.json', 'transportregeln.json', 'gruppen-ablauf.json') {
            Assert-Equal (Get-Content ".\a\$n" -Raw) (Get-Content ".\b\$n" -Raw) $n
        }
    }
}
Test-Case 'eine echte Änderung zeigt sich im Export' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\a' }
        $global:MockAut.caPolicies[0].State = 'disabled'
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\b' }
        Assert-True ((Get-Content '.\a\bedingter-zugriff.json' -Raw) -ne (Get-Content '.\b\bedingter-zugriff.json' -Raw))
    }
}
Test-Case 'Hinweis: bei genau einem Eintrag schreibt das Skript ein Objekt statt einer Liste' {
    Start-Test
    $global:MockAut.caPolicies = @($global:MockAut.caPolicies[0])
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        Assert-Equal '{' ((Get-Content '.\out\bedingter-zugriff.json' -Raw).TrimStart()[0].ToString())
        Start-Test
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\zwei' }
        Assert-Equal '[' ((Get-Content '.\zwei\bedingter-zugriff.json' -Raw).TrimStart()[0].ToString())
    }
}
Test-Case 'Hinweis: ohne Ablaufrichtlinie enthält die Datei nur das Wort null (Windows PowerShell 5.1: keine Datei)' {
    Start-Test
    $global:MockAut.lifecyclePolicies = @()
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $export @{ Ziel = '.\out' }
        if (Test-Path '.\out\gruppen-ablauf.json') { Assert-Equal 'null' ((Get-Content '.\out\gruppen-ablauf.json' -Raw).Trim()) }
        else { Assert-Equal 2 @(Get-ChildItem '.\out').Count 'die Datei fehlt, die beiden anderen sind da' }
    }
}

# ---------------------------------------------------------------- Listing 140/141
Write-Host 'Listing 140/141: standards.json und Test-StandardsFile.ps1'
$standards = Join-Path $skripte 'standards.json'
$pruef = Join-Path $skripte 'Test-StandardsFile.ps1'
function New-Standards {
    # Gültige Standards als Text; Änderungen als Hashtable { 'Text im Original' = 'Ersatz' }
    param([hashtable]$Ersetzen = @{})
    $t = Get-Content -LiteralPath $standards -Raw -Encoding UTF8
    foreach ($k in $Ersetzen.Keys) { if (-not $t.Contains($k)) { throw "Ersetzung nicht anwendbar: $k" }; $t = $t.Replace($k, $Ersetzen[$k]) }
    Write-Datei '.\s.json' $t
    '.\s.json'
}
function Get-Fehler { param($Ergebnis) @($Ergebnis.Info | Where-Object { $_ -like 'FEHLER:*' }) }
Test-Case 'die mitgelieferte standards.json ist gültig' {
    $r = Invoke-MitExit $pruef @{ Datei = $standards }
    Assert-True ($r.Info -contains 'Standards-Datei ist gueltig (Version 1.3.0).')
    Assert-True ((Get-ExitCode) -ne 1) 'kein Fehlercode'
    $s = Get-Content -LiteralPath $standards -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Equal 2 $s.gruppen.mindestBesitzer
    Assert-Equal 3 @($s.gruppen.pflichtMetadaten).Count
    Assert-True ('PRJ-VER-messe-2026' -match $s.gruppen.namensmuster) 'das Namensmuster passt auf einen Beispielnamen'
}
Test-Case 'jede Regelverletzung wird gemeldet und führt zu Exit-Code 1' {
    Use-Arbeitsordner {
        $faelle = [ordered]@{
            'version muss Form x.y.z haben'                       = @{ '"1.3.0"' = '"1.3"' }
            'gueltigAb ist kein Datum'                            = @{ '"2026-11-01"' = '"morgen"' }
            'namensmuster ist kein gueltiger regulaerer Ausdruck' = @{ '"^(PRJ|ABT|GRM|KND)-[A-Z]{2,5}-[a-z0-9-]{3,40}$"' = '"(offen"' }
            'mindestBesitzer muss mindestens 2 sein'              = @{ '"mindestBesitzer": 2' = '"mindestBesitzer": 1' }
            'lebensdauerTage muss mindestens 30 sein'             = @{ '"lebensdauerTage": 365' = '"lebensdauerTage": 29' }
            'pflichtMetadaten darf nicht leer sein'               = @{ '["Zweck", "Abteilung", "Vertraulichkeit"]' = '[]' }
        }
        foreach ($meldung in $faelle.Keys) {
            $r = Invoke-MitExit $pruef @{ Datei = (New-Standards $faelle[$meldung]) }
            Assert-Equal 1 (Get-ExitCode) "Exit-Code: $meldung"
            Assert-Equal @("FEHLER: $meldung") (Get-Fehler $r) $meldung
            Assert-True (-not ($r.Info -like 'Standards-Datei ist gueltig*')) 'keine Erfolgsmeldung'
        }
    }
}
Test-Case 'Grenzwerte: 2 Besitzer und 30 Tage sind erlaubt' {
    Use-Arbeitsordner {
        $r = Invoke-MitExit $pruef @{ Datei = (New-Standards @{ '"lebensdauerTage": 365' = '"lebensdauerTage": 30' }) }
        Assert-Equal 0 (Get-Fehler $r).Count
        Assert-True ((Get-ExitCode) -ne 1)
    }
}
Test-Case 'mehrere Fehler werden zusammen gemeldet, in der Reihenfolge der Prüfung' {
    Use-Arbeitsordner {
        $r = Invoke-MitExit $pruef @{ Datei = (New-Standards @{ '"1.3.0"' = '"x"'; '"mindestBesitzer": 2' = '"mindestBesitzer": 0'; '"lebensdauerTage": 365' = '"lebensdauerTage": 1' }) }
        Assert-Equal @('FEHLER: version muss Form x.y.z haben', 'FEHLER: mindestBesitzer muss mindestens 2 sein', 'FEHLER: lebensdauerTage muss mindestens 30 sein') (Get-Fehler $r)
    }
}
Test-Case 'fehlende Abschnitte und Felder werden bemerkt' {
    Use-Arbeitsordner {
        Write-Datei '.\o.json' '{ "version": "1.0.0", "gueltigAb": "2026-01-01" }'
        $r = Invoke-MitExit $pruef @{ Datei = '.\o.json' }
        Assert-Equal @("FEHLER: Abschnitt 'gruppen' fehlt") (Get-Fehler $r)
        Assert-Equal 1 (Get-ExitCode)
        Write-Datei '.\v.json' '{ "gruppen": { "namensmuster": "^a$", "mindestBesitzer": 2, "lebensdauerTage": 90, "pflichtMetadaten": ["Zweck"] } }'
        $r = Invoke-MitExit $pruef @{ Datei = '.\v.json' }
        Assert-Equal @('FEHLER: version muss Form x.y.z haben', 'FEHLER: gueltigAb ist kein Datum') (Get-Fehler $r)
    }
}
Test-Case 'eine Datei ohne gültiges JSON endet mit Fehlermeldung und Exit-Code 1' {
    Use-Arbeitsordner {
        Write-Datei '.\kaputt.json' '{ "version": '
        $r = Invoke-MitExit $pruef @{ Datei = '.\kaputt.json' }
        Assert-Equal 1 (Get-ExitCode)
        Assert-Equal 1 @($r.Errors | Where-Object { $_ -like 'Datei ist kein gueltiges JSON:*' }).Count
        Assert-Equal 0 (Get-Fehler $r).Count
    }
    Assert-Mandatory $pruef @('Datei')
}
Test-Case 'Hinweis: ein Text als mindestBesitzer wird nicht beanstandet, freigabestufen werden nicht geprüft' {
    Use-Arbeitsordner {
        $r = Invoke-MitExit $pruef @{ Datei = (New-Standards @{ '"mindestBesitzer": 2' = '"mindestBesitzer": "abc"' }) }
        Assert-Equal 0 (Get-Fehler $r).Count 'Textvergleich statt Zahlenvergleich'
        Write-Datei '.\f.json' ((Get-Content $standards -Raw -Encoding UTF8) -replace '(?s),\s*"freigabestufen".*\}\s*\}\s*$', "`n}")
        $r = Invoke-MitExit $pruef @{ Datei = '.\f.json' }
        Assert-Equal 0 (Get-Fehler $r).Count 'ohne Abschnitt freigabestufen'
    }
}

# ---------------------------------------------------------------- Listing 143
Write-Host 'Listing 143: Compare-ConfigDrift.ps1'
$drift = Join-Path $skripte 'Compare-ConfigDrift.ps1'
$sollJson = '[ { "Name": "Alpha", "Priority": 0, "State": "Enabled" }, { "Name": "Beta", "Priority": 1, "State": "Enabled" } ]'
# Das Original überschreibt den Parameter $Ist durch die Variable $ist (PowerShell unterscheidet Groß-/Kleinschreibung nicht).
# Die übrigen Tests laufen deshalb an einer Kopie, in der die Variable $istDaten heißt.
$driftOrdner = New-TestDirectory
$driftKopie = Join-Path $driftOrdner 'Compare-ConfigDrift.kopie.ps1'
$driftText = Get-Content -LiteralPath $drift -Raw -Encoding UTF8
foreach ($paar in @(@('$ist  = Read-Config $Ist', '$istDaten = Read-Config $Ist'), @('$ist.ContainsKey($k)', '$istDaten.ContainsKey($k)'),
                    @('$ist[$k].$p', '$istDaten[$k].$p'), @('$ist.Keys', '$istDaten.Keys'))) {
    if (-not $driftText.Contains($paar[0])) { throw "Ersetzung nicht anwendbar: $($paar[0])" }
    $driftText = $driftText.Replace($paar[0], $paar[1])
}
[System.IO.File]::WriteAllText($driftKopie, $driftText, (New-Object System.Text.UTF8Encoding($true)))
function Invoke-Drift {
    param([string]$Soll, [string]$Ist, [hashtable]$Zusatz = @{})
    Write-Datei '.\soll.json' $Soll; Write-Datei '.\ist.json' $Ist
    $a = @{ Baseline = '.\soll.json'; Ist = '.\ist.json' }
    foreach ($k in $Zusatz.Keys) { $a[$k] = $Zusatz[$k] }
    Invoke-MitExit $driftKopie $a
}
Test-Case 'Hinweis: das Original scheitert, weil die Variable $ist den Parameter $Ist (Typ string) überschreibt' {
    Use-Arbeitsordner {
        Write-Datei '.\soll.json' $sollJson; Write-Datei '.\ist.json' $sollJson
        Assert-Throws { Invoke-ScriptUnderTest $drift @{ Baseline = '.\soll.json'; Ist = '.\ist.json' } } 'ContainsKey'
    }
}
Test-Case 'identische Stände: keine Abweichung, Exit-Code 0 (an der Kopie)' {
    Use-Arbeitsordner {
        $r = Invoke-Drift $sollJson $sollJson
        Assert-True ($r.Info -contains 'Keine Abweichung.')
        Assert-Equal 0 (Get-ExitCode)
    }
}
Test-Case 'meldet fehlende, zusätzliche und abweichende Einträge mit Exit-Code 2' {
    Use-Arbeitsordner {
        $ist = '[ { "Name": "Alpha", "Priority": 5, "State": "Enabled" }, { "Name": "Gamma", "Priority": 2, "State": "Enabled" } ]'
        $r = Invoke-Drift $sollJson $ist
        Assert-Equal 2 (Get-ExitCode)
        Assert-Match $r.OutputText 'Beta\s+fehlt im Tenant'
        Assert-NotMatch $r.OutputText 'Beta\s+Wert abweichend' 'ein fehlender Eintrag wird nicht zusätzlich Feld für Feld gemeldet'
        Assert-Match $r.OutputText 'Gamma\s+zusaetzlich im Tenant'
        Assert-Match $r.OutputText 'Alpha\s+Wert abweichend\s+Priority\s+0\s+5'
        Assert-NotMatch $r.OutputText 'Keine Abweichung'
    }
}
Test-Case '-Ignorieren nimmt Felder von der Prüfung aus' {
    Use-Arbeitsordner {
        $ist = '[ { "Name": "Alpha", "Priority": 0, "State": "Disabled" }, { "Name": "Beta", "Priority": 1, "State": "Enabled" } ]'
        $r = Invoke-Drift $sollJson $ist
        Assert-Equal 2 (Get-ExitCode)
        $r = Invoke-Drift $sollJson $ist @{ Ignorieren = @('State') }
        Assert-Equal 0 (Get-ExitCode)
        Assert-True ($r.Info -contains 'Keine Abweichung.')
    }
}
Test-Case '-Schluessel wählt das Feld, über das die Einträge zugeordnet werden' {
    Use-Arbeitsordner {
        $soll = '[ { "Id": "a1", "Wert": 1 }, { "Id": "a2", "Wert": 2 } ]'
        $ist = '[ { "Id": "a2", "Wert": 3 }, { "Id": "a1", "Wert": 1 } ]'
        $r = Invoke-Drift $soll $ist @{ Schluessel = 'Id' }
        Assert-Equal 2 (Get-ExitCode)
        Assert-Match $r.OutputText 'a2\s+Wert abweichend\s+Wert\s+2\s+3'
        Assert-NotMatch $r.OutputText 'a1\s+Wert abweichend'
    }
}
Test-Case 'eine Datei mit einem einzigen Objekt statt einer Liste wird verstanden' {
    Use-Arbeitsordner {
        $r = Invoke-Drift '{ "Name": "Alpha", "Priority": 0 }' '{ "Name": "Alpha", "Priority": 1 }'
        Assert-Equal 2 (Get-ExitCode)
        Assert-Match $r.OutputText 'Alpha\s+Wert abweichend\s+Priority'
    }
}
Test-Case 'verschachtelte Werte werden als Ganzes verglichen' {
    Use-Arbeitsordner {
        $soll = '[ { "Name": "R", "Bedingung": { "Benutzer": [ "a", "b" ], "Apps": "alle" } } ]'
        $r = Invoke-Drift $soll $soll
        Assert-Equal 0 (Get-ExitCode)
        $r = Invoke-Drift $soll '[ { "Name": "R", "Bedingung": { "Benutzer": [ "a", "c" ], "Apps": "alle" } } ]'
        Assert-Equal 2 (Get-ExitCode)
        Assert-Match $r.OutputText 'Bedingung'
    }
}
Test-Case 'Hinweis: zusätzliche Felder im Ist-Stand und die Groß-/Kleinschreibung der Schlüssel bleiben unbemerkt' {
    Use-Arbeitsordner {
        $null = Invoke-Drift $sollJson '[ { "Name": "Alpha", "Priority": 0, "State": "Enabled", "Neu": "x" }, { "Name": "Beta", "Priority": 1, "State": "Enabled" } ]'
        Assert-Equal 0 (Get-ExitCode) 'neues Feld im Ist-Stand'
        $null = Invoke-Drift $sollJson '[ { "Name": "ALPHA", "Priority": 0, "State": "Enabled" }, { "Name": "beta", "Priority": 1, "State": "Enabled" } ]'
        Assert-Equal 0 (Get-ExitCode) 'andere Schreibweise des Schlüssels'
    }
}
Test-Case 'Hinweis: die Reihenfolge der Felder in verschachtelten Objekten und von Listen zählt als Abweichung' {
    Use-Arbeitsordner {
        $null = Invoke-Drift '[ { "Name": "R", "O": { "a": 1, "b": 2 } } ]' '[ { "Name": "R", "O": { "b": 2, "a": 1 } } ]'
        Assert-Equal 2 (Get-ExitCode) 'gleiche Felder, andere Reihenfolge'
        $null = Invoke-Drift '[ { "Name": "R", "L": [ "x", "y" ] } ]' '[ { "Name": "R", "L": [ "y", "x" ] } ]'
        Assert-Equal 2 (Get-ExitCode) 'gleiche Liste, andere Reihenfolge'
    }
}
Test-Case 'Hinweis: doppelte Schlüssel in der Baseline werden stillschweigend zusammengelegt, fehlt der Schlüssel, ist er leer' {
    Use-Arbeitsordner {
        $null = Invoke-Drift '[ { "Name": "A", "W": 1 }, { "Name": "A", "W": 2 } ]' '[ { "Name": "A", "W": 2 } ]'
        Assert-Equal 0 (Get-ExitCode) 'der zweite Eintrag überschreibt den ersten'
        $r = Invoke-Drift '[ { "W": 1 }, { "W": 2 } ]' '[ { "W": 2 } ]'
        Assert-Equal 0 (Get-ExitCode) 'Einträge ohne Schlüssel fallen unter einem leeren Schlüssel zusammen'
    }
}
Test-Case 'ein Feld der Baseline, das im Ist-Stand fehlt, ist eine Abweichung (Ist = null in PowerShell 7, leer in 5.1)' {
    Use-Arbeitsordner {
        $r = Invoke-Drift '[ { "Name": "A", "W": 1 } ]' '[ { "Name": "A" } ]'
        Assert-Equal 2 (Get-ExitCode)
        Assert-Match $r.OutputText 'A\s+Wert abweichend\s+W\s+1(\s+null)?\s*(\n|$)'
    }
    Assert-Mandatory $drift @('Baseline', 'Ist')
}

# ---------------------------------------------------------------- Listing 145
Write-Host 'Listing 145: Itsm-Bausteine.ps1'
$itsm = Join-Path $skripte 'Itsm-Bausteine.ps1'
$itsmCode = [scriptblock]::Create((Get-Content -LiteralPath $itsm -Raw -Encoding UTF8))
$env:ITSM_URL = 'https://itsm.example.com/api'
$env:ITSM_TOKEN = 'testtoken-123'
Test-Case 'Invoke-Itsm: Adresse aus Basis und Pfad, Token im Kopf, GET ohne Body' {
    Start-Test; . $itsmCode
    $c = Invoke-Itsm -Methode GET -Pfad '/changes/CHG0001'
    Assert-Equal 'approved' $c.state
    $a = (Get-Aufruf 'Invoke-RestMethod')[0].Parameter
    Assert-Equal 'GET' $a.Method
    Assert-Equal 'https://itsm.example.com/api/changes/CHG0001' $a.Uri
    Assert-Equal 'Bearer testtoken-123' $a.Headers.Authorization
    Assert-Equal 'application/json' $a.Headers.Accept
    Assert-Equal 'application/json' $a.ContentType
    Assert-True ($null -eq $a.Body) 'kein Body'
}
Test-Case 'Invoke-Itsm bricht ohne ITSM_URL oder ITSM_TOKEN ab, ohne etwas aufzurufen' {
    Start-Test
    $url = $env:ITSM_URL; $token = $env:ITSM_TOKEN
    try {
        $env:ITSM_TOKEN = $null
        . $itsmCode
        Assert-Throws { Invoke-Itsm -Methode GET -Pfad '/changes/CHG0001' } 'ITSM_URL und ITSM_TOKEN muessen gesetzt sein'
        $env:ITSM_TOKEN = $token; $env:ITSM_URL = $null
        . $itsmCode
        Assert-Throws { Invoke-Itsm -Methode GET -Pfad '/changes/CHG0001' } 'ITSM_URL und ITSM_TOKEN muessen gesetzt sein'
        Assert-Equal 0 @(Get-Aufruf 'Invoke-RestMethod').Count
    } finally { $env:ITSM_URL = $url; $env:ITSM_TOKEN = $token }
}
Test-Case 'New-DriftTicket legt ein Ticket mit stabilem Schlüssel an' {
    Start-Test; . $itsmCode
    $t = New-DriftTicket -Eintrag 'Transport Rule #1' -Beschreibung 'Wert abweichend'
    Assert-Equal 'INC1001' $t.number
    $c = @(Get-Aufruf 'Invoke-RestMethod')
    Assert-Equal 2 $c.Count
    Assert-Equal 'https://itsm.example.com/api/tickets?externalKey=drift-transport-rule-1&status=open' $c[0].Parameter.Uri
    Assert-Equal 'POST' $c[1].Parameter.Method
    $b = $c[1].Parameter.Body | ConvertFrom-Json
    Assert-Equal 'incident' $b.type
    Assert-Equal 'drift-transport-rule-1' $b.externalKey
    Assert-Equal '3' $b.priority
    Assert-Equal 'Konfigurationsabweichung: Transport Rule #1' $b.title
    Assert-Equal 'Wert abweichend' $b.description
    Assert-Equal 'M365-Betrieb' $b.assignmentGroup
}
Test-Case 'New-DriftTicket ist idempotent: ein offenes Ticket mit gleichem Schlüssel wird wiederverwendet' {
    Start-Test; . $itsmCode
    $erstes = New-DriftTicket -Eintrag 'Regel A' -Beschreibung 'x'
    $global:MockCalls.Clear()
    $zweites = New-DriftTicket -Eintrag 'Regel A' -Beschreibung 'x'
    Assert-Equal $erstes.number $zweites.number
    Assert-Equal 0 @((Get-Aufruf 'Invoke-RestMethod') | Where-Object { $_.Parameter.Method -eq 'POST' }).Count
    Assert-Equal 1 @($global:MockAut.itsm.tickets).Count
    $drittes = New-DriftTicket -Eintrag 'Regel B' -Beschreibung 'y'
    Assert-True ($drittes.number -ne $erstes.number) 'anderer Eintrag, anderes Ticket'
    Assert-Equal 2 @($global:MockAut.itsm.tickets).Count
}
Test-Case 'ein geschlossenes Ticket zählt nicht: dann entsteht ein neues' {
    Start-Test; . $itsmCode
    $erstes = New-DriftTicket -Eintrag 'Regel A' -Beschreibung 'x'
    $global:MockAut.itsm.tickets[0].status = 'closed'
    $neu = New-DriftTicket -Eintrag 'Regel A' -Beschreibung 'x'
    Assert-True ($neu.number -ne $erstes.number)
}
Test-Case 'Hinweis: der Schlüssel macht aus Umlauten und Sonderzeichen Bindestriche; verschiedene Einträge können kollidieren' {
    Start-Test; . $itsmCode
    $null = New-DriftTicket -Eintrag 'Größe' -Beschreibung 'x'
    $null = New-DriftTicket -Eintrag 'Regel!' -Beschreibung 'x'
    $null = New-DriftTicket -Eintrag 'A B' -Beschreibung 'x'
    $zweites = New-DriftTicket -Eintrag 'A-B' -Beschreibung 'anderer Eintrag'
    Assert-Equal @('drift-gr-e', 'drift-regel-', 'drift-a-b') @($global:MockAut.itsm.tickets | ForEach-Object { $_.externalKey })
    Assert-Equal 'INC1003' $zweites.number 'A-B bekommt das Ticket von A B'
}
Test-Case 'Assert-ChangeApproved gibt freigegebene Changes zurück und lehnt andere ab' {
    Start-Test; . $itsmCode
    Assert-Equal 'CHG0001' (Assert-ChangeApproved -Nummer 'CHG0001').number
    Assert-Throws { Assert-ChangeApproved -Nummer 'CHG0002' } "Change CHG0002 hat Status 'new', erwartet 'approved'"
    Assert-Throws { Assert-ChangeApproved -Nummer 'CHG9999' } 'nicht gefunden'
}
Test-Case 'Hinweis: der Statusvergleich unterscheidet nicht zwischen Groß- und Kleinschreibung' {
    Start-Test; . $itsmCode
    Assert-Equal 'Approved' (Assert-ChangeApproved -Nummer 'CHG0003').state
}

# ---------------------------------------------------------------- Listing 147
Write-Host 'Listing 147: Get-RiskyAppPermissions.ps1'
$risiko = Join-Path $skripte 'Get-RiskyAppPermissions.ps1'
Test-Case 'meldet Zuweisungen mit *ReadWrite.All und zählt Zuweisungen und Anwendungen' {
    Start-Test
    $r = Invoke-ScriptUnderTest $risiko
    Assert-Equal @('Application.Read.All') (Get-Scopes)
    Assert-Equal "appId eq '00000003-0000-0000-c000-000000000000'" (Get-Aufruf 'Get-MgServicePrincipal')[0].Parameter.Filter
    Assert-True ($r.Output -contains '3 Zuweisungen mit weitreichendem Schreibzugriff bei 2 Anwendungen.')
    Assert-Match $r.OutputText 'Berichtsdienst\s+app-1\s+Group\.ReadWrite\.All'
    Assert-Match $r.OutputText 'Berichtsdienst\s+app-1\s+Directory\.ReadWrite\.All'
    Assert-Match $r.OutputText 'Archivierer\s+app-2\s+Directory\.ReadWrite\.All'
}
Test-Case 'die Tabelle ist nach Anwendung sortiert' {
    Start-Test
    $r = Invoke-ScriptUnderTest $risiko
    $a = $r.OutputText.IndexOf('Archivierer', [System.StringComparison]::Ordinal)
    $b = $r.OutputText.IndexOf('Berichtsdienst', [System.StringComparison]::Ordinal)
    Assert-True ($a -ge 0 -and $a -lt $b) 'Archivierer vor Berichtsdienst'
}
Test-Case 'nicht gemeldet: Lesen, Mail.ReadWrite, FullControl, andere Ressourcen, Dienstprinzipale ohne Rechte oder nicht lesbar' {
    Start-Test
    $r = Invoke-ScriptUnderTest $risiko
    Assert-NotMatch $r.OutputText 'Fremdressource'
    Assert-NotMatch $r.OutputText 'Postfachwerkzeug' 'Mail.ReadWrite, Files.Write.All und Sites.FullControl.All gelten nicht als ReadWrite.All'
    Assert-NotMatch $r.OutputText 'Ohne Rechte'
    Assert-NotMatch $r.OutputText 'Nicht lesbar'
    Assert-NotMatch $r.OutputText 'User\.Read\.All'
    Assert-Equal 7 @(Get-Aufruf 'Get-MgServicePrincipalAppRoleAssignment').Count 'jeder Dienstprinzipal, auch der von Graph selbst'
}
Test-Case 'ohne Treffer erscheint der Hinweis statt einer Tabelle' {
    Start-Test
    foreach ($s in @($global:MockAut.servicePrincipals)) { $s.assignments = @() }
    $r = Invoke-ScriptUnderTest $risiko
    Assert-True ($r.Output -contains "Keine Zuweisungen mit '*ReadWrite.All' gefunden.")
}
Test-Case 'Hinweis: die Zahl der Anwendungen zählt Anzeigenamen, nicht Anwendungen (AppId)' {
    Start-Test
    $global:MockAut.servicePrincipals[1].name = 'Berichtsdienst'
    $r = Invoke-ScriptUnderTest $risiko
    Assert-True ($r.Output -contains '3 Zuweisungen mit weitreichendem Schreibzugriff bei 1 Anwendungen.')
}

# ---------------------------------------------------------------- Listing 149
Write-Host 'Listing 149: Set-LifetimeWithRollback.ps1'
$rollback = Join-Path $skripte 'Set-LifetimeWithRollback.ps1'
function Get-Sicherung { @(Get-ChildItem -LiteralPath '.\rollback' -Filter '*.json' -ErrorAction SilentlyContinue) }
function Get-Lebensdauer { (@($global:MockAut.lifecyclePolicies)[0]).days }
Test-Case 'sichert den alten Stand, ändert die Lebensdauer und prüft das Ergebnis' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 180; ChangeNummer = 'CHG1' }
        Assert-Equal @('Directory.ReadWrite.All') (Get-Scopes)
        $s = Get-Sicherung
        Assert-Equal 1 $s.Count
        Assert-Match $s[0].Name '^CHG1-\d{8}-\d{6}\.json$'
        $alt = Get-Content -LiteralPath $s[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert-Equal @('Id', 'GroupLifetimeInDays', 'ManagedGroupTypes', 'AlternateNotificationEmails') @($alt.PSObject.Properties.Name)
        Assert-Equal 'lp-1' $alt.Id
        Assert-Equal 365 $alt.GroupLifetimeInDays
        $u = @(Get-Aufruf 'Update-MgGroupLifecyclePolicy')
        Assert-Equal 1 $u.Count
        Assert-Equal 180 $u[0].Parameter.GroupLifetimeInDays
        Assert-Equal 'lp-1' $u[0].Parameter.GroupLifecyclePolicyId
        Assert-Equal 180 (Get-Lebensdauer)
        Assert-True ($r.Info -contains 'Aenderung erfolgreich (CHG1).')
        Assert-True (Test-Zeile $r.Info '^Sicherung geschrieben: .*CHG1-')
    }
}
Test-Case 'mit -WhatIf bleibt die Richtlinie unverändert; Hinweis: es entsteht auch keine Sicherung, obwohl das Skript sie meldet' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 180; ChangeNummer = 'CHG1'; WhatIf = $true }
        Assert-Equal 0 @(Get-Aufruf 'Update-MgGroupLifecyclePolicy').Count
        Assert-Equal 365 (Get-Lebensdauer)
        Assert-True (-not (Test-Path '.\rollback')) 'WhatIf gilt auch für New-Item und Set-Content'
        Assert-True (Test-Zeile $r.Info '^Sicherung geschrieben: ') 'die Meldung erscheint trotzdem'
        Assert-True (-not ($r.Info -contains 'Aenderung erfolgreich (CHG1).'))
    }
}
Test-Case 'wirkt die Änderung nicht, schlägt die Prüfung fehl und die alte Lebensdauer wird zurückgeschrieben' {
    Start-Test
    $global:MockAut.options.lifecycleUpdateIgnored = $true
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 180; ChangeNummer = 'CHG1' } } 'Rollback ausgefuehrt, Aenderung CHG1 fehlgeschlagen'
        $u = @(Get-Aufruf 'Update-MgGroupLifecyclePolicy')
        Assert-Equal @(180, 365) @($u | ForEach-Object { $_.Parameter.GroupLifetimeInDays }) 'erst neu, dann zurück'
    }
    Start-Test
    $global:MockAut.options.lifecycleUpdateIgnored = $true
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 400; ChangeNummer = 'CHG1' } } 'Rollback ausgefuehrt' 
    }
}
Test-Case 'Hinweis: bei mehreren Ablaufrichtlinien ändert das Skript nur die erste' {
    Start-Test
    $global:MockAut.lifecyclePolicies = @($global:MockAut.lifecyclePolicies) + [pscustomobject]@{ id = 'lp-2'; days = 90; types = 'All'; emails = '' }
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 180; ChangeNummer = 'CHG1' }
        Assert-Equal @('lp-1') @(Get-Aufruf 'Update-MgGroupLifecyclePolicy' | ForEach-Object { $_.Parameter.GroupLifecyclePolicyId })
    }
}
Test-Case 'schlägt die Änderung einmal fehl, stellt der Rollback den alten Wert her' {
    Start-Test
    $global:MockAut.options.lifecycleUpdateFailures = 1
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 90; ChangeNummer = 'CHG7' } } 'Rollback ausgefuehrt, Aenderung CHG7 fehlgeschlagen'
        Assert-Equal 2 @(Get-Aufruf 'Update-MgGroupLifecyclePolicy').Count
        Assert-Equal 365 (Get-Lebensdauer)
    }
}
Test-Case 'Hinweis: scheitert auch der Rollback, kommt dessen Fehler ohne den Satz "Rollback ausgefuehrt"' {
    Start-Test
    $global:MockAut.options.lifecycleUpdateFailures = 2
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 90; ChangeNummer = 'CHG7' } } 'kann gerade nicht geändert werden'
        Assert-Equal 2 @(Get-Aufruf 'Update-MgGroupLifecyclePolicy').Count
    }
}
Test-Case 'Wertebereich 30 bis 3650; ohne Richtlinie Abbruch vor der Sicherung' {
    Start-Test
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 29; ChangeNummer = 'CHG1' } }
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 3651; ChangeNummer = 'CHG1' } }
        Assert-Equal 0 @(Get-Aufruf 'Connect-MgGraph').Count
        $null = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 30; ChangeNummer = 'CHG1' }
        Assert-Equal 30 (Get-Lebensdauer)
        $null = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 3650; ChangeNummer = 'CHG2' }
        Assert-Equal 3650 (Get-Lebensdauer)
    }
    Start-Test
    $global:MockAut.lifecyclePolicies = @()
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 90; ChangeNummer = 'CHG1' } } 'Keine Ablaufrichtlinie vorhanden'
        Assert-True (-not (Test-Path '.\rollback')) 'keine Sicherung ohne Richtlinie'
    }
    Assert-Mandatory $rollback @('NeueLebensdauer', 'ChangeNummer')
}
Test-Case 'Hinweis: die Change-Nummer wird nicht im Ticket-System geprüft, und ein unveränderter Wert wird trotzdem geschrieben' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $rollback @{ NeueLebensdauer = 365; ChangeNummer = 'CHG0002' }
        Assert-Equal 0 @(Get-Aufruf 'Invoke-RestMethod').Count 'keine Abfrage beim Ticket-System'
        Assert-Equal 1 @(Get-Aufruf 'Update-MgGroupLifecyclePolicy').Count
    }
}

# ---------------------------------------------------------------- Aufgabe 4
Write-Host 'Aufgabe 4: Gruppen ohne Besitzer'
$ohneBesitzer = Join-Path $loesungen 'aufgabe-04-ohne-besitzer.ps1'
Test-Case 'mit -WhatIf: keine Zuweisung; Hinweis: die Datei mit dem Status "geplant" entsteht nicht' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $ohneBesitzer @{ Ersatzbesitzer = 'ersatz@example.com'; WhatIf = $true }
        Assert-Equal @('Group.ReadWrite.All', 'User.Read.All') (Get-Scopes)
        Assert-Equal 0 @(Get-Aufruf 'New-MgGroupOwnerByRef').Count
        Assert-True (-not (Test-Path '.\ohne-besitzer.csv')) 'WhatIf gilt auch für Export-Csv'
    }
}
Test-Case 'ohne -WhatIf: der Ersatzbesitzer wird den Gruppen ohne Besitzer zugewiesen' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $ohneBesitzer @{ Ersatzbesitzer = 'ersatz@example.com'; Ausgabe = '.\liste.csv' }
        $n = @(Get-Aufruf 'New-MgGroupOwnerByRef')
        Assert-Equal @('g3', 'g5') @($n | ForEach-Object { $_.Parameter.GroupId })
        Assert-Equal 'https://graph.microsoft.com/v1.0/users/u9' $n[0].Parameter.BodyParameter['@odata.id']
        $z = @(Import-Csv '.\liste.csv')
        Assert-Equal @('Gruppe', 'Id', 'Status') @($z[0].PSObject.Properties.Name)
        Assert-Equal @('Marketing Team', 'GRM-BR-Rat') @($z | ForEach-Object { $_.Gruppe })
        Assert-Equal @('zugewiesen') @(Import-Csv '.\liste.csv' | ForEach-Object { $_.Status } | Select-Object -Unique)
    }
}
Test-Case 'idempotent: ein zweiter Lauf findet keine Gruppen mehr (die Liste ist dann leer)' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $ohneBesitzer @{ Ersatzbesitzer = 'ersatz@example.com' }
        $global:MockCalls.Clear()
        $null = Invoke-ScriptUnderTest $ohneBesitzer @{ Ersatzbesitzer = 'ersatz@example.com' }
        Assert-Equal 0 @(Get-Aufruf 'New-MgGroupOwnerByRef').Count
        Assert-Equal 0 @(Import-Csv '.\ohne-besitzer.csv').Count 'die Datei wird überschrieben, das Protokoll des ersten Laufs geht verloren'
    }
}
Test-Case 'ein unbekannter Ersatzbesitzer bricht vor jeder Änderung ab' {
    Start-Test
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest $ohneBesitzer @{ Ersatzbesitzer = 'niemand@example.com' } } 'nicht gefunden'
        Assert-Equal 0 @(Get-Aufruf 'New-MgGroupOwnerByRef').Count
    }
    Assert-Mandatory $ohneBesitzer @('Ersatzbesitzer')
}

Remove-Item -LiteralPath $driftOrdner -Recurse -Force
Complete-Tests
