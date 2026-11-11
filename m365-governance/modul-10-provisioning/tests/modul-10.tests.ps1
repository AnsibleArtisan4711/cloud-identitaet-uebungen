# modul-10.tests.ps1 - Offline-Tests für die Skripte aus Modul 10 (Provisioning, Standards und Lifecycle Automation).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-10-provisioning/tests/modul-10.tests.ps1
# Alle Graph-Cmdlets sind simuliert (tools/Mock-Provisioning.ps1, erfundene Daten in tools/fixtures/provisioning-klein.json).
# Geprüft wird die Logik der Skripte, nicht das Verhalten eines echten Tenants.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Provisioning.ps1')   # überschreibt mehrere Funktionen aus Mock-MgGraph.ps1
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'provisioning-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test { Initialize-MockProvisioning $fixture }
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
function Test-Zeile { param($Ausgabe, [string]$Muster) @($Ausgabe | Where-Object { $_ -match $Muster }).Count -gt 0 }
function Get-Funktionsteil {
    # Text eines Skripts bis zur Zeile "# Beispiel…" (nur die Funktionen, ohne den Beispielaufruf)
    param([string]$Pfad, [string]$Marke = '# Beispiel')
    $text = Get-Content -LiteralPath $Pfad -Raw -Encoding UTF8
    $i = $text.IndexOf($Marke, [System.StringComparison]::Ordinal)
    if ($i -lt 0) { throw "Marke '$Marke' nicht gefunden in $Pfad" }
    $text.Substring(0, $i)
}
# Wartezeiten der Skripte durch eine Funktion ohne Wartezeit ersetzen; mehr als 20 Aufrufe gelten als Endlosschleife.
function Start-Sleep {
    param([int]$Seconds, [int]$Milliseconds)
    Add-MockCall 'Start-Sleep' @{ Seconds = $Seconds }
    if (@(Get-MockCall 'Start-Sleep').Count -gt 20) { throw 'Start-Sleep zu oft aufgerufen: Schleife endet nicht' }
}
function Get-Pausen { @(Get-Aufruf 'Start-Sleep' | ForEach-Object { $_.Parameter.Seconds }) }
function Set-Gruppe { param([string]$Id, [string]$Feld, $Wert) $g = @($global:MockProv.groups | Where-Object { $_.id -eq $Id })[0]; $g.$Feld = $Wert }

Write-Host 'Listing 120/121: vorlage-projekt.json und Apply-TeamTemplate.ps1'
$vorlage = Join-Path $skripte 'vorlage-projekt.json'
Test-Case 'die Vorlage ist gültiges JSON mit drei Kanälen und einem Label' {
    $v = Get-Content -LiteralPath $vorlage -Raw -Encoding UTF8 | ConvertFrom-Json
    $k = @($v.kanaele)
    Assert-Equal @('Planung', 'Dokumentation', 'Abstimmung') @($k | ForEach-Object { $_.name })
    Assert-Equal 'Intern' $v.sensitivityLabel
}
Test-Case 'legt fehlende Kanäle an und überspringt vorhandene' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g1'; Vorlage = $vorlage }
    Assert-Equal @('Channel.Create', 'ChannelSettings.Read.All') (Get-Scopes)
    $neu = @(Get-Aufruf 'New-MgTeamChannel')
    Assert-Equal 2 $neu.Count
    Assert-Equal @('Dokumentation', 'Abstimmung') @($neu | ForEach-Object { $_.Parameter.DisplayName })
    Assert-Equal 'Ergebnisse und Protokolle' $neu[0].Parameter.Description
    Assert-Equal 'g1' $neu[0].Parameter.TeamId
    Assert-True ($r.Info -contains 'Kanal vorhanden, uebersprungen: Planung')
    Assert-True ($r.Info -contains 'Kanal angelegt: Dokumentation')
    Assert-True ($r.Info -contains 'Kanal angelegt: Abstimmung')
}
Test-Case 'ein zweiter Lauf legt nichts mehr an' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g1'; Vorlage = $vorlage }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g1'; Vorlage = $vorlage }
    Assert-Equal 0 @(Get-Aufruf 'New-MgTeamChannel').Count
    Assert-Equal 3 @($r.Info | Where-Object { $_ -like 'Kanal vorhanden*' }).Count
}
Test-Case 'ein Team ohne Kanäle bekommt alle drei' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g3'; Vorlage = $vorlage }
    Assert-Equal 3 @(Get-Aufruf 'New-MgTeamChannel').Count
}
Test-Case 'Hinweis: der Vergleich der Kanalnamen ignoriert Groß- und Kleinschreibung' {
    Start-Test
    Use-Arbeitsordner {
        Set-Content -LiteralPath 'v.json' -Encoding UTF8 -Value '{ "kanaele": [ { "name": "planung", "beschreibung": "x" } ] }'
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g1'; Vorlage = '.\v.json' }
        Assert-Equal 0 @(Get-Aufruf 'New-MgTeamChannel').Count
    }
}
Test-Case 'bricht ab bei einer Vorlage ohne Kanäle; beide Parameter sind Pflicht' {
    Start-Test
    Use-Arbeitsordner {
        Set-Content -LiteralPath 'leer.json' -Encoding UTF8 -Value '{ "beschreibung": "nichts" }'
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Apply-TeamTemplate.ps1') @{ TeamId = 'g1'; Vorlage = '.\leer.json' } } 'keine Kanaele'
        Assert-Equal 0 @(Get-Aufruf 'Get-MgTeamChannel').Count 'vor dem Abruf der Kanäle'
    }
    Assert-Mandatory (Join-Path $skripte 'Apply-TeamTemplate.ps1') @('TeamId', 'Vorlage')
}

Write-Host 'Listing 116: New-GovernedWorkspace.ps1'
$ws = Join-Path $skripte 'New-GovernedWorkspace.ps1'
$wsArgs = { @{ Name = 'PRJ-VER-Neu'; Nickname = 'prj-ver-neu'; Besitzer = @('anna@example.com', 'ben@example.com') } }
Test-Case 'legt eine Microsoft-365-Gruppe mit beiden Besitzern an und erzeugt dann das Team' {
    Start-Test
    $r = Invoke-ScriptUnderTest $ws (& $wsArgs)
    Assert-Equal @('Group.ReadWrite.All', 'User.Read.All') (Get-Scopes)
    Assert-Equal 2 @(Get-Aufruf 'Get-MgUser').Count
    $g = @(Get-Aufruf 'New-MgGroup')
    Assert-Equal 1 $g.Count
    $p = $g[0].Parameter
    Assert-Equal 'PRJ-VER-Neu' $p.DisplayName
    Assert-Equal 'prj-ver-neu' $p.MailNickname
    Assert-Equal @('Unified') @($p.GroupTypes)
    Assert-True ($p.MailEnabled -eq $true -and $p.SecurityEnabled -eq $false) 'Mail an, Sicherheit aus'
    Assert-Equal 'Private' $p.Visibility
    Assert-Equal '' $p.Description
    Assert-Equal @('https://graph.microsoft.com/v1.0/users/u1', 'https://graph.microsoft.com/v1.0/users/u2') @($p.AdditionalProperties['owners@odata.bind'])
    $put = @(Get-Aufruf 'Invoke-MgGraphRequest')
    Assert-Equal 1 $put.Count
    Assert-Equal 'PUT' $put[0].Parameter.Method
    Assert-Equal 'https://graph.microsoft.com/v1.0/groups/g-neu-10/team' $put[0].Parameter.Uri
    Assert-Equal 'application/json' $put[0].Parameter.ContentType
    Assert-True (($put[0].Parameter.Body | ConvertFrom-Json).memberSettings.allowCreatePrivateChannels -eq $true) 'private Kanäle erlaubt'
    Assert-True ($r.Info -contains 'Gruppe angelegt: g-neu-10')
    $o = @($r.Output)
    Assert-Equal 1 $o.Count
    Assert-Equal 'g-neu-10' $o[0].GruppenId
    Assert-Equal 'PRJ-VER-Neu' $o[0].Name
    Assert-Equal 'anna@example.com; ben@example.com' $o[0].Besitzer
    Assert-Match $o[0].Zeit '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
}
Test-Case 'Beschreibung und Sichtbarkeit werden übernommen; ungültige Sichtbarkeit wird abgelehnt' {
    Start-Test
    $a = & $wsArgs; $a.Beschreibung = 'Eine Beschreibung'; $a.Sichtbarkeit = 'Public'
    $null = Invoke-ScriptUnderTest $ws $a
    $p = (Get-Aufruf 'New-MgGroup')[0].Parameter
    Assert-Equal 'Eine Beschreibung' $p.Description
    Assert-Equal 'Public' $p.Visibility
    $a.Sichtbarkeit = 'Geheim'
    Assert-Throws { Invoke-ScriptUnderTest $ws $a }
}
Test-Case 'weniger als zwei Besitzer: Abbruch vor der Anmeldung; unbekannter Besitzer: keine Gruppe' {
    Start-Test
    $a = & $wsArgs; $a.Besitzer = @('anna@example.com')
    Assert-Throws { Invoke-ScriptUnderTest $ws $a } 'Mindestens zwei Besitzer'
    Assert-Equal 0 @(Get-Aufruf 'Connect-MgGraph').Count
    $a.Besitzer = @('anna@example.com', 'niemand@example.com')
    Assert-Throws { Invoke-ScriptUnderTest $ws $a } 'nicht gefunden'
    Assert-Equal 0 @(Get-Aufruf 'New-MgGroup').Count
}
Test-Case 'Hinweis: das Skript prüft den Nickname nicht vorab (die Prüfung wäre Sache von New-WorkspaceName)' {
    Start-Test
    $null = Invoke-ScriptUnderTest $ws (& $wsArgs)
    Assert-Equal 0 @(Get-Aufruf 'Get-MgGroup').Count
}
Test-Case 'wiederholt das Erzeugen des Teams bis zu dreimal im Abstand von 10 Sekunden' {
    Start-Test
    $global:MockProv.options.teamFailures = 2
    $r = Invoke-ScriptUnderTest $ws (& $wsArgs)
    Assert-Equal 3 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
    Assert-Equal @(10, 10) (Get-Pausen)
    Assert-Equal @('Team noch nicht moeglich, neuer Versuch in 10 Sekunden (1/3).', 'Team noch nicht moeglich, neuer Versuch in 10 Sekunden (2/3).') @($r.Warnings)
    Assert-Equal 1 @($r.Output).Count
}
Test-Case 'Hinweis: nach drei Fehlern bricht das Skript ab, die Gruppe bleibt aber bestehen' {
    Start-Test
    $global:MockProv.options.teamFailures = 3
    Assert-Throws { Invoke-ScriptUnderTest $ws (& $wsArgs) } 'Team konnte nicht erzeugt werden'
    Assert-Equal 3 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
    Assert-Equal 1 @($global:MockProv.groups | Where-Object { $_.name -eq 'PRJ-VER-Neu' }).Count 'halbfertige Gruppe ohne Team'
}
Test-Case 'Hinweis: auch 429 wird nur mit fester Wartezeit von 10 Sekunden wiederholt (Retry-After bleibt unbeachtet)' {
    Start-Test
    $global:MockProv.options.teamFailures = 1
    $global:MockProv.options.teamFailureStatus = 429
    $global:MockProv.options.teamFailureRetryAfter = 60
    $null = Invoke-ScriptUnderTest $ws (& $wsArgs)
    Assert-Equal @(10) (Get-Pausen)
}
Test-Case 'Hinweis: derselbe Besitzer zweimal wird nicht abgelehnt' {
    Start-Test
    $a = & $wsArgs; $a.Besitzer = @('anna@example.com', 'anna@example.com')
    $null = Invoke-ScriptUnderTest $ws $a
    Assert-Equal 1 @(Get-Aufruf 'New-MgGroup').Count
    Assert-Mandatory $ws @('Name', 'Nickname', 'Besitzer')
}

Write-Host 'Listing 118: Test-WorkspaceRequest.ps1'
$antragSkript = Join-Path $skripte 'Test-WorkspaceRequest.ps1'
function New-Antrag {
    param([hashtable]$Aenderung = @{})
    $a = [ordered]@{ Name = 'Projekt Phoenix'; Zweck = 'Produktlaunch'; Besitzer1 = 'anna@example.com'; Besitzer2 = 'ben@example.com'
                     Abteilung = 'Vertrieb'; Vertraulichkeit = 'Intern'; Gaeste = $false; Groesse = 12 }
    foreach ($k in $Aenderung.Keys) { $a[$k] = $Aenderung[$k] }
    [pscustomobject]$a
}
Test-Case 'ein vollständiger interner Antrag ist gültig und bekommt Stufe 1' {
    . ([scriptblock]::Create((Get-Funktionsteil $antragSkript)))
    $r = Test-WorkspaceRequest -Antrag (New-Antrag)
    Assert-True ($r.Gueltig -eq $true)
    Assert-Equal 0 @($r.Fehler).Count
    Assert-Equal 1 $r.Stufe
}
Test-Case 'jedes fehlende Pflichtfeld wird genannt; der Antrag ist ungültig ohne Stufe' {
    . ([scriptblock]::Create((Get-Funktionsteil $antragSkript)))
    foreach ($feld in 'Name', 'Zweck', 'Besitzer1', 'Besitzer2', 'Abteilung', 'Vertraulichkeit') {
        $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ $feld = '  ' })
        Assert-True ($r.Gueltig -eq $false) "$feld leer"
        Assert-Equal @("Pflichtfeld fehlt: $feld") @($r.Fehler) "Meldung für $feld"
        Assert-True ($null -eq $r.Stufe) 'keine Stufe'
    }
    $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ Name = ''; Zweck = ''; Besitzer1 = ''; Besitzer2 = '' })
    Assert-Equal @('Pflichtfeld fehlt: Name', 'Pflichtfeld fehlt: Zweck', 'Pflichtfeld fehlt: Besitzer1', 'Pflichtfeld fehlt: Besitzer2') @($r.Fehler) 'Reihenfolge der Felder'
}
Test-Case 'zwei gleiche Besitzer (auch in anderer Schreibweise) und zu lange Namen werden abgelehnt' {
    . ([scriptblock]::Create((Get-Funktionsteil $antragSkript)))
    $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ Besitzer2 = 'ANNA@example.com' })
    Assert-Equal @('Die beiden Besitzer muessen verschiedene Personen sein.') @($r.Fehler)
    $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ Name = ('x' * 41) })
    Assert-Equal @('Name laenger als 40 Zeichen.') @($r.Fehler)
    $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ Name = ('x' * 40) })
    Assert-True ($r.Gueltig -eq $true) '40 Zeichen sind erlaubt'
    $r = Test-WorkspaceRequest -Antrag (New-Antrag @{ Besitzer1 = ''; Besitzer2 = '' })
    Assert-Equal 2 @($r.Fehler).Count 'zwei leere Besitzer: nur die Pflichtfeld-Meldungen'
}
Test-Case 'die Stufe ergibt sich aus Gästen, Vertraulichkeit und Größe' {
    . ([scriptblock]::Create((Get-Funktionsteil $antragSkript)))
    Assert-Equal 3 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Gaeste = $true })).Stufe 'Gäste'
    Assert-Equal 3 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Vertraulichkeit = 'Vertraulich' })).Stufe 'Vertraulich'
    Assert-Equal 3 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Vertraulichkeit = 'Streng' })).Stufe 'Streng'
    Assert-Equal 3 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Vertraulichkeit = 'Vertraulich'; Groesse = 500 })).Stufe 'vertraulich schlägt groß'
    Assert-Equal 2 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Groesse = 201 })).Stufe 'intern und groß'
    Assert-Equal 1 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Groesse = 200 })).Stufe 'genau 200 ist noch Stufe 1'
    Assert-Equal 1 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Vertraulichkeit = 'Oeffentlich'; Groesse = 900 })).Stufe 'nur "Intern" wird nach Größe gestuft'
}
Test-Case 'Hinweis: "Streng vertraulich", Gaeste = "ja" und fehlende Größe ergeben Stufe 1' {
    . ([scriptblock]::Create((Get-Funktionsteil $antragSkript)))
    Assert-Equal 1 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Vertraulichkeit = 'Streng vertraulich' })).Stufe
    Assert-Equal 1 (Test-WorkspaceRequest -Antrag (New-Antrag @{ Gaeste = 'ja' })).Stufe
    $ohneGroesse = New-Antrag; $ohneGroesse.PSObject.Properties.Remove('Groesse')
    Assert-Equal 1 (Test-WorkspaceRequest -Antrag $ohneGroesse).Stufe
}
Test-Case 'das Skript als Ganzes zeigt den Beispielantrag: gültig, Stufe 1' {
    $r = Invoke-ScriptUnderTest $antragSkript
    Assert-Match $r.OutputText 'Gueltig\s*:\s*True'
    Assert-Match $r.OutputText 'Stufe\s*:\s*1'
}

Write-Host 'Listing 123: New-WorkspaceName.ps1'
$nameSkript = Join-Path $skripte 'New-WorkspaceName.ps1'
Test-Case 'ConvertTo-Slug ersetzt Umlaute und Sonderzeichen und trimmt Bindestriche' {
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    Assert-Equal 'produktlaunch-fruehjahr' (ConvertTo-Slug 'Produktlaunch Frühjahr')
    Assert-Equal 'groesse-uebung-2026' (ConvertTo-Slug 'Größe & Übung (2026)!')
    Assert-Equal 'aeoeuess' (ConvertTo-Slug 'ÄÖÜß')
    Assert-Equal 'a-b' (ConvertTo-Slug 'a   b')
    Assert-Equal 'test' (ConvertTo-Slug '--Test--')
    Assert-Equal '' (ConvertTo-Slug 'é')
}
Test-Case 'baut Anzeigename und Nickname aus Typ, Abteilung und Freitext' {
    Start-Test
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    $r = New-WorkspaceName -Typ PRJ -Abteilung ver -Freitext 'Produktlaunch Frühjahr'
    Assert-Equal 'PRJ-VER-produktlaunch-fruehjahr' $r.Anzeigename
    Assert-Equal 'prj-ver-produktlaunch-fruehjahr' $r.Nickname
    Assert-Equal "mailNickname eq 'prj-ver-produktlaunch-fruehjahr'" ((Get-Aufruf 'Get-MgGroup')[0].Parameter.Filter)
}
Test-Case 'bei einem vergebenen Nickname wird hochgezählt (-2, -3)' {
    Start-Test
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    $r = New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext 'Messe'
    Assert-Equal 'PRJ-VER-messe-2' $r.Anzeigename
    Assert-Equal 'prj-ver-messe-2' $r.Nickname
    $null = New-MgGroup -DisplayName $r.Anzeigename -MailNickname $r.Nickname -GroupTypes @('Unified')
    $r = New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext 'Messe'
    Assert-Equal 'PRJ-VER-messe-3' $r.Anzeigename
}
Test-Case 'kürzt auf die Höchstlänge, auch mit Zähler, ohne Bindestrich am Ende' {
    Start-Test
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    $r = New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext ('lang ' * 30)
    Assert-True ($r.Anzeigename.Length -le 50 -and -not $r.Anzeigename.EndsWith('-')) "Länge $($r.Anzeigename.Length)"
    Assert-Equal 'PRJ-VER-prod' (New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext 'Produktlaunch' -MaxLaenge 12).Anzeigename
    Assert-Equal 'PRJ-VER-mes-2' (New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext 'Messe' -MaxLaenge 13).Anzeigename 'Zähler passt noch in die Höchstlänge'
    Assert-Equal 'PRJ-VER-abc' (New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext 'abc-defghij' -MaxLaenge 12).Anzeigename 'Bindestrich am Ende wird entfernt'
}
Test-Case 'prüft Typ, Länge der Abteilung und Pflichtfelder' {
    Start-Test
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    Assert-Throws { New-WorkspaceName -Typ XXX -Abteilung VER -Freitext 'a' }
    Assert-Throws { New-WorkspaceName -Typ PRJ -Abteilung V -Freitext 'a' }
    Assert-Throws { New-WorkspaceName -Typ PRJ -Abteilung ABCDEF -Freitext 'a' }
    $null = New-WorkspaceName -Typ ABT -Abteilung AB -Freitext 'a'
    $null = New-WorkspaceName -Typ GRM -Abteilung ABCDE -Freitext 'a'
    $null = New-WorkspaceName -Typ KND -Abteilung ABC -Freitext 'a'
}
Test-Case 'Hinweis: besteht der Freitext nur aus Sonderzeichen, endet der Name auf einen Bindestrich' {
    Start-Test
    . ([scriptblock]::Create((Get-Funktionsteil $nameSkript)))
    $r = New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext '!!!'
    Assert-Equal 'PRJ-VER-' $r.Anzeigename
    Assert-Equal 'prj-ver' $r.Nickname
}
Test-Case 'das Skript als Ganzes zeigt den Namen aus dem Beispielaufruf' {
    Start-Test
    $r = Invoke-ScriptUnderTest $nameSkript
    Assert-Match $r.OutputText 'PRJ-VER-produktlaunch-fruehjahr\s+prj-ver-produktlaunch-fruehjahr'
}

Write-Host 'Listing 125: Test-MetadataStandard.ps1'
$metaSkript = Join-Path $skripte 'Test-MetadataStandard.ps1'
function Get-Befunde { @(Import-Csv -LiteralPath '.\metadaten-befunde.csv') }
Test-Case 'zählt konforme Microsoft-365-Gruppen (Sicherheitsgruppen und gelöschte zählen nicht)' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $metaSkript
        Assert-Equal @('Group.Read.All') (Get-Scopes)
        $g = (Get-Aufruf 'Get-MgGroup')[0].Parameter
        Assert-Equal "groupTypes/any(c:c eq 'Unified')" $g.Filter
        Assert-Equal @('Id', 'DisplayName', 'Description', 'Visibility', 'CreatedDateTime') @($g.Property)
        Assert-Equal 7 @(Get-Aufruf 'Get-MgGroupOwner').Count 'je Gruppe eine Besitzerabfrage'
        Assert-True (Test-Zeile $r.Output '^2 von 7 Gruppen konform \(29\s?%\)$')
    }
}
Test-Case 'schreibt die Befunde je Gruppe mit allen Gründen, nach Name sortiert' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $metaSkript
        $b = Get-Befunde
        Assert-Equal @('Gruppe', 'Id', 'Befund') @($b[0].PSObject.Properties.Name)
        Assert-Equal @('GRM-BR-Rat', 'KND-XY-Alt', 'Marketing Team', 'PRJ-IT-Server', 'xyz') @($b | ForEach-Object { $_.Gruppe })
        $nach = @{}; foreach ($z in $b) { $nach[$z.Gruppe] = $z.Befund }
        Assert-Equal 'weniger als zwei Besitzer (1)' $nach['GRM-BR-Rat']
        Assert-Equal 'weniger als zwei Besitzer (0)' $nach['KND-XY-Alt']
        Assert-Equal 'Name entspricht nicht der Konvention' $nach['Marketing Team']
        Assert-Equal 'Beschreibung fehlt' $nach['PRJ-IT-Server']
        Assert-Equal 'Name entspricht nicht der Konvention; Beschreibung fehlt; weniger als zwei Besitzer (0)' $nach['xyz']
        Assert-Equal 'g5' (@($b | Where-Object { $_.Gruppe -eq 'GRM-BR-Rat' })[0].Id)
    }
}
Test-Case 'Namenskonvention: 2 bis 5 Buchstaben für die Abteilung, danach ein Bindestrich' {
    Start-Test
    Use-Arbeitsordner {
        Set-Gruppe 'g3' 'name' 'PRJ-ABCDE-Test'       # fünf Buchstaben: gültig
        Set-Gruppe 'g4' 'name' 'PRJ-ABCDEF-Test'      # sechs: ungültig
        Set-Gruppe 'g5' 'name' 'PRJ-X-Test'           # einer: ungültig
        Set-Gruppe 'g6' 'name' 'PRJ-A1-Test'          # Ziffer: ungültig
        Set-Gruppe 'g7' 'name' 'ABT-AB-'              # gültig (Beschreibung fehlt trotzdem)
        $null = Invoke-ScriptUnderTest $metaSkript
        $b = @{}; foreach ($z in Get-Befunde) { $b[$z.Id] = $z.Befund }
        Assert-True (-not $b.ContainsKey('g3')) 'fünf Buchstaben'
        Assert-Match $b['g4'] 'Name entspricht nicht der Konvention'
        Assert-Match $b['g5'] 'Name entspricht nicht der Konvention'
        Assert-Match $b['g6'] 'Name entspricht nicht der Konvention'
        Assert-NotMatch $b['g7'] 'Name entspricht'
    }
}
Test-Case 'eine Beschreibung nur aus Leerzeichen gilt als fehlend' {
    Start-Test
    Use-Arbeitsordner {
        Set-Gruppe 'g1' 'description' '   '
        $null = Invoke-ScriptUnderTest $metaSkript
        $b = @{}; foreach ($z in Get-Befunde) { $b[$z.Id] = $z.Befund }
        Assert-Equal 'Beschreibung fehlt' $b['g1']
    }
}
Test-Case 'Hinweis: klein geschriebene Namen gelten als konform (-notmatch unterscheidet nicht nach Schreibweise)' {
    Start-Test
    Use-Arbeitsordner {
        Set-Gruppe 'g3' 'name' 'prj-it-klein'
        $r = Invoke-ScriptUnderTest $metaSkript
        Assert-True (Test-Zeile $r.Output '^3 von 7 Gruppen konform')
    }
}
Test-Case 'ohne Microsoft-365-Gruppen: Hinweis und keine Datei' {
    Start-Test
    $global:MockProv.groups = @($global:MockProv.groups | Where-Object { -not $_.unified })
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $metaSkript
        Assert-Match $r.Text 'Keine Microsoft-365-Gruppen gefunden'
        Assert-True (-not (Test-Path '.\metadaten-befunde.csv'))
    }
}
Test-Case 'Hinweis: sind alle Gruppen konform, enthält die Befunddatei höchstens eine leere Datei' {
    Start-Test
    $global:MockProv.groups = @($global:MockProv.groups | Where-Object { $_.id -in 'g1', 'g2' })
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $metaSkript
        Assert-True (Test-Zeile $r.Output '^2 von 2 Gruppen konform \(100\s?%\)$')
        $zeilen = if (Test-Path '.\metadaten-befunde.csv') { @(Get-Content -LiteralPath '.\metadaten-befunde.csv' | Where-Object { $_ -match 'g\d' }) } else { @() }
        Assert-Equal 0 $zeilen.Count 'keine Befundzeilen'
    }
}

Write-Host 'Listing 127: New-GroupExpirationPolicy.ps1'
$ablauf = Join-Path $skripte 'New-GroupExpirationPolicy.ps1'
$ablaufArgs = { @{ AdresseOhneBesitzer = 'it-betrieb@example.com'; TestgruppeId = 'g1' } }
Test-Case 'legt die Ablaufrichtlinie für ausgewählte Gruppen an und trägt die Testgruppe ein' {
    Start-Test
    $r = Invoke-ScriptUnderTest $ablauf (& $ablaufArgs)
    Assert-Equal @('Directory.ReadWrite.All') (Get-Scopes)
    $n = (Get-Aufruf 'New-MgGroupLifecyclePolicy')[0].Parameter
    Assert-Equal 365 $n.GroupLifetimeInDays
    Assert-Equal 'Selected' $n.ManagedGroupTypes
    Assert-Equal 'it-betrieb@example.com' $n.AlternateNotificationEmails
    $a = (Get-Aufruf 'Add-MgGroupLifecyclePolicyGroup')[0].Parameter
    Assert-Equal 'lp-1' $a.GroupLifecyclePolicyId
    Assert-Equal 'g1' $a.GroupId
    Assert-Match $r.OutputText 'GroupLifetimeInDays\s*:\s*365'
    Assert-Match $r.OutputText 'ManagedGroupTypes\s*:\s*Selected'
}
Test-Case 'die Lebensdauer muss mindestens 30 Tage betragen (vor der Anmeldung geprüft)' {
    Start-Test
    Assert-Throws { Invoke-ScriptUnderTest $ablauf ((& $ablaufArgs) + @{ Lebensdauer = 29 }) } 'mindestens 30 Tage'
    Assert-Equal 0 @(Get-Aufruf 'Connect-MgGraph').Count
    $null = Invoke-ScriptUnderTest $ablauf ((& $ablaufArgs) + @{ Lebensdauer = 30 })
    Assert-Equal 30 (Get-Aufruf 'New-MgGroupLifecyclePolicy')[0].Parameter.GroupLifetimeInDays
}
Test-Case 'eine vorhandene Ablaufrichtlinie verhindert das Anlegen einer zweiten' {
    Start-Test
    $null = Invoke-ScriptUnderTest $ablauf (& $ablaufArgs)
    Assert-Throws { Invoke-ScriptUnderTest $ablauf (& $ablaufArgs) } 'existiert bereits'
    Assert-Equal 0 @(Get-Aufruf 'New-MgGroupLifecyclePolicy').Count
}
Test-Case 'Hinweis: eine unbekannte Testgruppe wird erst nach dem Anlegen der Richtlinie bemerkt' {
    Start-Test
    $r = Invoke-ScriptUnderTest $ablauf @{ AdresseOhneBesitzer = 'a@example.com'; TestgruppeId = 'g-fehlt' }
    Assert-Equal 1 @($global:MockProv.lifecyclePolicies).Count
    Assert-Equal 1 @($r.Errors | Where-Object { $_ -like '*nicht gefunden*' }).Count
    Assert-Mandatory $ablauf @('AdresseOhneBesitzer', 'TestgruppeId')
}

Write-Host 'Listing 129: Archive-InactiveTeams.ps1'
$archiv = Join-Path $skripte 'Archive-InactiveTeams.ps1'
function New-Liste { param([string[]]$Ids) Set-Content -LiteralPath '.\liste.csv' -Encoding UTF8 -Value (@('GruppenId') + $Ids) }
function Get-Protokoll { @(Import-Csv -LiteralPath '.\archiv-protokoll.csv') }
Test-Case 'Probelauf: meldet je Gruppe den Status und archiviert nichts, schreibt aber das Protokoll' {
    Start-Test
    Use-Arbeitsordner {
        New-Liste 'g1', 'g6', 'g-fehlt'
        $r = Invoke-ScriptUnderTest $archiv @{ Liste = '.\liste.csv' }
        Assert-Equal @('TeamSettings.ReadWrite.All', 'Group.Read.All') (Get-Scopes)
        Assert-Equal 0 @(Get-Aufruf 'Invoke-MgArchiveTeam').Count
        $p = Get-Protokoll
        Assert-Equal 3 $p.Count
        Assert-Equal @('GruppenId', 'Status', 'Zeit') @($p[0].PSObject.Properties.Name)
        Assert-Equal 'Probelauf: wuerde archivieren' $p[0].Status
        Assert-Equal 'kein Besitzer - manuell klaeren' $p[1].Status
        Assert-Equal "Fehler: Mock: Gruppe 'g-fehlt' nicht gefunden." $p[2].Status
        Assert-Match $p[0].Zeit '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
        Assert-Match $r.OutputText 'g1\s+Probelauf'
    }
}
Test-Case 'mit -Ausfuehren werden nur Gruppen mit Besitzer archiviert' {
    Start-Test
    Use-Arbeitsordner {
        New-Liste 'g1', 'g6', 'g2', 'g5'
        $null = Invoke-ScriptUnderTest $archiv @{ Liste = '.\liste.csv'; Ausfuehren = $true }
        Assert-Equal @('g1', 'g2', 'g5') @(Get-Aufruf 'Invoke-MgArchiveTeam' | ForEach-Object { $_.Parameter.TeamId }) 'ein einzelner Besitzer genügt'
        $p = Get-Protokoll
        Assert-Equal @('Archivierung angestossen', 'kein Besitzer - manuell klaeren', 'Archivierung angestossen', 'Archivierung angestossen') @($p | ForEach-Object { $_.Status })
    }
}
Test-Case 'ein Fehler beim Archivieren wird protokolliert, die übrigen Zeilen laufen weiter' {
    Start-Test
    $global:MockProv.options.archiveFailIds = @('g1')
    Use-Arbeitsordner {
        New-Liste 'g1', 'g2'
        $null = Invoke-ScriptUnderTest $archiv @{ Liste = '.\liste.csv'; Ausfuehren = $true }
        $p = Get-Protokoll
        Assert-Match $p[0].Status '^Fehler: Mock: Team .g1. kann nicht archiviert werden'
        Assert-Equal 'Archivierung angestossen' $p[1].Status
    }
}
Test-Case 'eigener Protokollpfad; leere Liste bricht ab; Liste ist Pflicht' {
    Start-Test
    Use-Arbeitsordner {
        New-Liste 'g1'
        $null = Invoke-ScriptUnderTest $archiv @{ Liste = '.\liste.csv'; Protokoll = '.\mein-protokoll.csv' }
        Assert-True (Test-Path '.\mein-protokoll.csv')
        Assert-True (-not (Test-Path '.\archiv-protokoll.csv'))
        New-Liste @()
        Assert-Throws { Invoke-ScriptUnderTest $archiv @{ Liste = '.\liste.csv' } } 'Die Liste ist leer'
    }
    Assert-Mandatory $archiv @('Liste')
}

Write-Host 'Listing 130: Loeschen-und-Wiederherstellen.ps1'
$loeschen = Join-Path $skripte 'Loeschen-und-Wiederherstellen.ps1'
Test-Case 'löscht die Gruppe, zeigt gelöschte Gruppen und stellt sie sofort wieder her' {
    Start-Test
    $gruppenId = 'g1'
    $r = Invoke-ScriptUnderTest $loeschen
    Assert-Equal @('Group.ReadWrite.All', 'Directory.ReadWrite.All') (Get-Scopes)
    $namen = @($global:MockCalls | ForEach-Object { $_.Name })
    Assert-Equal @('Connect-MgGraph', 'Remove-MgGroup', 'Get-MgDirectoryDeletedItemAsGroup', 'Restore-MgDirectoryDeletedItem') $namen 'Reihenfolge der Aufrufe'
    Assert-Equal 'g1' (Get-Aufruf 'Remove-MgGroup')[0].Parameter.GroupId
    Assert-Equal 'g1' (Get-Aufruf 'Restore-MgDirectoryDeletedItem')[0].Parameter.DirectoryObjectId
    Assert-Match $r.OutputText 'g1\s+PRJ-VER-Messe'
    Assert-Match $r.OutputText 'g9\s+PRJ-OLD-Alt'
    Assert-True (-not (@($global:MockProv.groups | Where-Object { $_.id -eq 'g1' })[0].deleted)) 'am Ende wiederhergestellt'
}
Test-Case 'Hinweis: bei einer unbekannten Gruppe läuft das Skript trotz Fehler weiter und versucht die Wiederherstellung' {
    Start-Test
    $gruppenId = 'g-fehlt'
    $r = Invoke-ScriptUnderTest $loeschen
    Assert-True (@($r.Errors | Where-Object { $_ -like '*nicht gefunden*' }).Count -ge 1) 'Fehler gemeldet'
    Assert-Equal 1 @(Get-Aufruf 'Restore-MgDirectoryDeletedItem').Count
}

Write-Host 'Listing 132: Invoke-WithRetry.ps1'
$retrySkript = Join-Path $skripte 'Invoke-WithRetry.ps1'
$retryCode = [scriptblock]::Create((Get-Funktionsteil $retrySkript))
Test-Case 'liefert das Ergebnis der Aktion, ohne zu warten' {
    Start-Test
    . $retryCode
    Assert-Equal 42 (Invoke-WithRetry -Aktion { 42 })
    Assert-Equal 0 @(Get-Pausen).Count
}
Test-Case 'bei 429 wartet die Funktion die Zeit aus Retry-After, ohne Angabe 30 Sekunden' {
    Start-Test
    . $retryCode
    $z = @{ n = 0 }
    $r = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 2) { throw (New-ProvHttpException 429 'zu viele Anfragen' 7) }; 'ok' } 3>&1
    Assert-Equal @(7) (Get-Pausen)
    Assert-True (@($r | Where-Object { $_ -is [System.Management.Automation.WarningRecord] -and $_.Message -eq 'Gedrosselt (429), warte 7 Sekunden.' }).Count -eq 1) 'Warnung'
    $global:MockCalls.Clear()
    $z.n = 0
    $null = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 2) { throw (New-ProvHttpException 429 'zu viele Anfragen' $null) }; 'ok' } 3>&1
    Assert-Equal @(30) (Get-Pausen)
}
Test-Case 'bei 404 oder "NotFound" wartet sie die feste Zeit (Standard 10, einstellbar)' {
    Start-Test
    . $retryCode
    $z = @{ n = 0 }
    $null = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 3) { throw (New-ProvHttpException 404 'nicht gefunden' $null) }; 'ok' } 3>&1
    Assert-Equal @(10, 10) (Get-Pausen)
    $global:MockCalls.Clear(); $z.n = 0
    $null = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 2) { throw (New-ProvHttpException 404 'x' $null) }; 'ok' } -FesteWartezeit 3 3>&1
    Assert-Equal @(3) (Get-Pausen)
    $global:MockCalls.Clear(); $z.n = 0
    $r = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 2) { throw 'Request_ResourceNotFound: Gruppe' }; 'gefunden' } 3>&1
    Assert-Equal @(10) (Get-Pausen) 'Text mit ResourceNotFound ohne Statuscode'
    Assert-True ($r -contains 'gefunden')
    $global:MockCalls.Clear(); $z.n = 0
    $null = Invoke-WithRetry -Aktion { $z.n++; if ($z.n -lt 2) { throw 'NotFound' }; 'ok' } 3>&1
    Assert-Equal @(10) (Get-Pausen) 'nur "NotFound" im Text'
}
Test-Case 'andere Fehler werden sofort weitergereicht, ohne Wartezeit' {
    Start-Test
    . $retryCode
    Assert-Throws { Invoke-WithRetry -Aktion { throw (New-ProvHttpException 500 'Serverfehler' $null) } } 'Serverfehler'
    Assert-Throws { Invoke-WithRetry -Aktion { throw 'irgendein Fehler' } } 'irgendein Fehler'
    Assert-Equal 0 @(Get-Pausen).Count
}
Test-Case 'gibt nach MaxVersuche auf; die letzte Meldung steht im Text' {
    Start-Test
    . $retryCode
    $z = @{ n = 0 }
    Assert-Throws { Invoke-WithRetry -Aktion { $z.n++; throw (New-ProvHttpException 404 'noch nicht da' $null) } 3>$null } 'Aufgegeben nach 4 Versuchen: noch nicht da'
    Assert-Equal 4 $z.n
    Assert-Equal @(10, 10, 10) (Get-Pausen) 'nach dem letzten Versuch wird nicht mehr gewartet'
    $global:MockCalls.Clear(); $z.n = 0
    Assert-Throws { Invoke-WithRetry -Aktion { $z.n++; throw (New-ProvHttpException 404 'noch nicht da' $null) } -MaxVersuche 1 } 'Aufgegeben nach 1 Versuchen'
    Assert-Equal 1 $z.n
}
Test-Case 'das Skript als Ganzes erzeugt das Team der Gruppe $gruppenId, bei Verzögerung nach Wartezeit' {
    Start-Test
    $gruppenId = 'g1'
    $global:MockProv.options.teamFailures = 2
    $r = Invoke-ScriptUnderTest $retrySkript
    $c = @(Get-Aufruf 'Invoke-MgGraphRequest')
    Assert-Equal 3 $c.Count
    Assert-Equal 'https://graph.microsoft.com/v1.0/groups/g1/team' $c[0].Parameter.Uri
    Assert-Equal 'PUT' $c[0].Parameter.Method
    Assert-Equal '{}' $c[0].Parameter.Body
    Assert-Equal @(10, 10) (Get-Pausen)
    Assert-Equal 2 @($r.Warnings | Where-Object { $_ -like 'Objekt noch nicht sichtbar (404)*' }).Count
}

Write-Host 'Aufgabe 5: Mail-Nickname aus Freitext'
$nickSkript = Join-Path $loesungen 'aufgabe-05-nickname.ps1'
Test-Case 'ConvertTo-Nickname: Umlaute, Sonderzeichen, Ränder und Länge' {
    . ([scriptblock]::Create((Get-Funktionsteil $nickSkript 'ConvertTo-Nickname "')))
    Assert-Equal 'groesse-uebung-2026' (ConvertTo-Nickname 'Größe & Übung (2026)!')
    Assert-Equal 'test' (ConvertTo-Nickname '   --Test--   ')
    Assert-Equal ('a' * 40) (ConvertTo-Nickname ('a' * 100))
    Assert-Equal 'aeoeuess' (ConvertTo-Nickname 'ÄÖÜß')
    Assert-Equal 'abc' (ConvertTo-Nickname 'abcdef' -Max 3)
    Assert-Equal 'ab' (ConvertTo-Nickname 'ab-cd' -Max 3) 'Bindestrich am Ende nach dem Kürzen entfernt'
}
Test-Case 'ConvertTo-Nickname: ohne gültiges Zeichen oder ohne Text gibt es einen Fehler' {
    . ([scriptblock]::Create((Get-Funktionsteil $nickSkript 'ConvertTo-Nickname "')))
    Assert-Throws { ConvertTo-Nickname '!!!' } 'Kein gueltiges Zeichen'
    Assert-Throws { ConvertTo-Nickname '' }
}
Test-Case 'das Skript als Ganzes gibt die drei Beispiele aus' {
    $r = Invoke-ScriptUnderTest $nickSkript
    Assert-Equal @('groesse-uebung-2026', 'test', ('a' * 40)) @($r.Output)
}

Write-Host 'Aufgabe 7: Gruppen ohne aktiven Besitzer je Abteilung'
$ohneBesitzer = Join-Path $loesungen 'aufgabe-07-ohne-aktiven-besitzer.ps1'
Test-Case 'schreibt je Abteilung eine Datei mit den Gruppen ohne aktiven Besitzer' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $ohneBesitzer
        Assert-Equal @('Group.Read.All', 'User.Read.All') (Get-Scopes)
        $dateien = @(Get-ChildItem -Filter 'ohne-aktiven-besitzer-*.csv' | ForEach-Object { $_.Name } | Sort-Object)
        Assert-Equal @('ohne-aktiven-besitzer-IT.csv', 'ohne-aktiven-besitzer-Personal.csv', 'ohne-aktiven-besitzer-unbekannt.csv') $dateien
        $it = @(Import-Csv 'ohne-aktiven-besitzer-IT.csv')
        Assert-Equal @('Abteilung', 'Gruppe', 'Id') @($it[0].PSObject.Properties.Name)
        Assert-Equal 'KND-XY-Alt' $it[0].Gruppe 'g6: Besitzer fehlen, erstes Mitglied ist in der IT'
        Assert-Equal 'GRM-BR-Rat' (@(Import-Csv 'ohne-aktiven-besitzer-Personal.csv'))[0].Gruppe 'g5: Besitzer deaktiviert, erstes Mitglied in Personal'
        Assert-Equal 'xyz' (@(Import-Csv 'ohne-aktiven-besitzer-unbekannt.csv'))[0].Gruppe 'g7: ohne Mitglieder'
        Assert-Equal 3 @(Get-Aufruf 'Get-MgGroupMember').Count 'nur für Gruppen ohne aktiven Besitzer'
        Assert-Equal 1 (Get-Aufruf 'Get-MgGroupMember')[0].Parameter.Top
    }
}
Test-Case 'sind alle Besitzer aktiv, entstehen keine Dateien' {
    Start-Test
    foreach ($id in 'g5', 'g6', 'g7') { Set-Gruppe $id 'owners' @('u1') }
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $ohneBesitzer
        Assert-Equal 0 @(Get-ChildItem -Filter '*.csv').Count
    }
}

Complete-Tests
