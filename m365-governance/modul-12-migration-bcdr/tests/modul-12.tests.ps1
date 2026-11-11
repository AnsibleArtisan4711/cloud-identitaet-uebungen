# modul-12.tests.ps1 - Offline-Tests für die Skripte aus Modul 12 (Migration, Kosten, Adoption und BCDR).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-12-migration-bcdr/tests/modul-12.tests.ps1
# Graph-Aufrufe sind simuliert (tools/Mock-Betrieb.ps1, erfundene Daten in tools/fixtures/betrieb-klein.json);
# alle anderen Skripte laufen mit erfundenen Dateien in einem Wegwerf-Ordner.
# Geprüft wird die Logik der Skripte, nicht das Verhalten eines echten Tenants.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Betrieb.ps1')   # überschreibt mehrere Funktionen anderer Mocks
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'betrieb-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test { Initialize-MockBetrieb $fixture }
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
function Get-Scopes { @((Get-Aufruf 'Connect-MgGraph')[0].Parameter.Scopes) }
function Test-Zeile { param($Ausgabe, [string]$Muster) @($Ausgabe | Where-Object { $_ -match $Muster }).Count -gt 0 }
function Write-Datei { param([string]$Pfad, [string[]]$Zeilen) Set-Content -LiteralPath $Pfad -Value ($Zeilen -join "`n") -Encoding UTF8 }
function Get-ExitCode { $global:LASTEXITCODE }
function Invoke-MitExit { param([string]$Pfad, [hashtable]$Arg = @{}) $global:LASTEXITCODE = $null; Invoke-ScriptUnderTest $Pfad $Arg }
function Get-Tag { param([int]$VorTagen) (Get-Date).AddDays(-$VorTagen).ToString('yyyy-MM-dd') }
function Get-Pos { param([string]$Text, [string]$Teil) $Text.IndexOf($Teil, [System.StringComparison]::Ordinal) }

# ---------------------------------------------------------------- Listing 151
Write-Host 'Listing 151: Get-TenantBaseline.ps1'
$basis = Join-Path $skripte 'Get-TenantBaseline.ps1'
Test-Case 'schreibt die Ist-Analyse als Markdown-Tabelle und gibt sie aus' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $basis @{ Ausgabe = '.\ist.md' }
        Assert-Equal @('User.Read.All', 'Group.Read.All') (Get-Scopes)
        $z = @(Get-Content -LiteralPath '.\ist.md' -Encoding UTF8)
        Assert-Equal 8 $z.Count
        Assert-Match $z[0] '^# Ist-Analyse \(Bestand\) vom \d{4}-\d{2}-\d{2}$'
        Assert-Equal '| Kennzahl | Wert |' $z[2]
        Assert-Equal '| Benutzer | 8 |' $z[4]
        Assert-Equal '| Gaeste | 1 |' $z[5]
        Assert-Equal '| Microsoft-365-Gruppen | 5 |' $z[6]
        Assert-Match $z[7] '^\| Gruppen ohne Besitzer \| 2 \(40\s?%\) \|$'
        Assert-Equal 8 @($r.Output).Count 'die Datei wird zusätzlich ausgegeben'
    }
}
Test-Case 'zählt über Graph mit -ConsistencyLevel eventual; Gäste über den Filter userType' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $basis @{ Ausgabe = '.\ist.md' }
        $c = @(Get-Aufruf 'Get-MgUserCount')
        Assert-Equal 2 $c.Count
        Assert-Equal 'eventual' $c[0].Parameter.ConsistencyLevel
        Assert-Equal "userType eq 'Guest'" $c[1].Parameter.Filter
        Assert-Equal 5 @(Get-Aufruf 'Get-MgGroupOwner').Count 'je Microsoft-365-Gruppe eine Besitzerabfrage'
    }
}
Test-Case 'ohne -Ausgabe heißt die Datei ist-analyse-<Datum>.md' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $basis
        $d = @(Get-ChildItem -Filter 'ist-analyse-*.md')
        Assert-Equal 1 $d.Count
        Assert-Equal ('ist-analyse-{0}.md' -f (Get-Date -Format 'yyyy-MM-dd')) $d[0].Name
    }
}
Test-Case 'ohne Gruppen steht 0 (0 %), ohne Division durch null' {
    Start-Test
    $global:MockBet.groups = @()
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $basis @{ Ausgabe = '.\ist.md' }
        $z = @(Get-Content -LiteralPath '.\ist.md' -Encoding UTF8)
        Assert-Equal '| Microsoft-365-Gruppen | 0 |' $z[6]
        Assert-Match $z[7] '^\| Gruppen ohne Besitzer \| 0 \(0\s?%\) \|$'
    }
}
Test-Case 'Hinweis: bei genau einer Gruppe ist die Zahl der Gruppen in Windows PowerShell 5.1 vermutlich leer' {
    Start-Test
    $global:MockBet.groups = @($global:MockBet.groups | Where-Object { $_.id -eq 'g2' })
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest $basis @{ Ausgabe = '.\ist.md' }
        $z = @(Get-Content -LiteralPath '.\ist.md' -Encoding UTF8)
        Assert-Match $z[6] '^\| Microsoft-365-Gruppen \| 1? ?\|$' 'PowerShell 7: 1; Windows PowerShell 5.1: leer (ein einzelnes Objekt hat dort keine Eigenschaft Count)'
        Assert-Match $z[7] '^\| Gruppen ohne Besitzer \| 1 \(' 'die Zahl ohne Besitzer stimmt'
    }
}

# ---------------------------------------------------------------- Listing 153
Write-Host 'Listing 153: Get-MaturityPriorities.ps1'
$reife = Join-Path $skripte 'Get-MaturityPriorities.ps1'
$reifeKopf = 'Bereich;Ist;Ziel;Gewicht'
function New-Reife { param([string[]]$Zeilen) Write-Datei '.\reife.csv' (@($reifeKopf) + $Zeilen); '.\reife.csv' }
Test-Case 'Priorität = Lücke mal Gewicht, größte zuerst; Durchschnitt der Ist-Stufen' {
    Use-Arbeitsordner {
        $d = New-Reife 'Identitaet;2;4;3', 'Teams;3;3;2', 'Sicherheit;1;5;2'
        $r = Invoke-ScriptUnderTest $reife @{ Datei = $d }
        Assert-Match $r.OutputText 'Sicherheit\s+1\s+5\s+4\s+8'
        Assert-Match $r.OutputText 'Identitaet\s+2\s+4\s+2\s+6'
        Assert-Match $r.OutputText 'Teams\s+3\s+3\s+0\s+0'
        $s = Get-Pos $r.OutputText 'Sicherheit'; $i = Get-Pos $r.OutputText 'Identitaet'; $t = Get-Pos $r.OutputText 'Teams'
        Assert-True ($s -ge 0 -and $s -lt $i -and $i -lt $t) 'absteigend nach Priorität'
        Assert-True (Test-Zeile $r.Output '^Durchschnittliche Ist-Stufe: 2[.,]0 ') 'Durchschnitt von 2, 3 und 1'
        Assert-Equal 0 @($r.Warnings).Count 'Ziel gleich Ist ist keine Warnung'
    }
}
Test-Case 'Ziel unter Ist: Warnung, Lücke 0 (keine negative Lücke)' {
    Use-Arbeitsordner {
        $d = New-Reife 'Betrieb;4;2;3', 'Teams;1;2;1'
        $r = Invoke-ScriptUnderTest $reife @{ Datei = $d }
        Assert-Equal @("Ziel unter Ist bei 'Betrieb'.") @($r.Warnings)
        Assert-Match $r.OutputText 'Betrieb\s+4\s+2\s+0\s+0'
    }
}
Test-Case 'Stufen außerhalb von 1 bis 5 brechen ab (Ist und Ziel, beide Grenzen)' {
    Use-Arbeitsordner {
        foreach ($z in '0;3;1', '6;3;1', '2;0;1', '2;6;1') {
            $d = New-Reife "Bereich X;$z"
            Assert-Throws { Invoke-ScriptUnderTest $reife @{ Datei = $d } } "Ungueltige Stufe bei 'Bereich X'"
        }
        foreach ($z in '1;5;1', '5;5;1', '3;1;1') {
            $d = New-Reife "Bereich X;$z"
            $null = Invoke-ScriptUnderTest $reife @{ Datei = $d }
        }
    }
}
Test-Case 'eine Datei ohne Zeilen bricht ab; Datei ist Pflicht' {
    Use-Arbeitsordner {
        Write-Datei '.\leer.csv' @($reifeKopf)
        Assert-Throws { Invoke-ScriptUnderTest $reife @{ Datei = '.\leer.csv' } } 'enthaelt keine Zeilen'
    }
    Assert-Mandatory $reife @('Datei')
}
Test-Case 'Hinweis: fehlt die Spalte Gewicht, ist jede Priorität 0; ein Text als Stufe bricht mit einer Umwandlungsfehlermeldung ab' {
    Use-Arbeitsordner {
        Write-Datei '.\o.csv' @('Bereich;Ist;Ziel', 'Teams;1;5')
        $r = Invoke-ScriptUnderTest $reife @{ Datei = '.\o.csv' }
        Assert-Match $r.OutputText 'Teams\s+1\s+5\s+4\s+0'
        Write-Datei '.\t.csv' @($reifeKopf, 'Teams;abc;5;1')
        Assert-Throws { Invoke-ScriptUnderTest $reife @{ Datei = '.\t.csv' } }
    }
}

# ---------------------------------------------------------------- Listing 155
function ConvertTo-Dez {
    # Export-Csv schreibt Zahlen in Windows PowerShell 5.1 mit dem Dezimalzeichen der Systemsprache (12,00), in PowerShell 7 mit Punkt.
    param([string]$Text)
    [decimal]::Parse(($Text -replace ',', '.'), [System.Globalization.CultureInfo]::InvariantCulture)
}
Write-Host 'Listing 155: New-ShowbackReport.ps1'
$showback = Join-Path $skripte 'New-ShowbackReport.ps1'
function New-Verbrauch { param([string[]]$Zeilen) Write-Datei '.\v.csv' (@('Abteilung;SpeicherGB;SicherungGB') + $Zeilen); '.\v.csv' }
function Get-ShowbackArgs { param([string]$Datei, [decimal]$Frei = 800) @{ Verbrauch = $Datei; FreiesKontingentGB = $Frei; PreisSpeicherProGBMonat = 0.1; PreisSicherungProGBMonat = 0.05; Ausgabe = '.\sb.csv' } }
Test-Case 'verteilt den Mehrverbrauch an Speicher anteilig, Sicherung nach eigenem Verbrauch' {
    Use-Arbeitsordner {
        $d = New-Verbrauch 'Vertrieb;400;100', 'IT;600;200', 'HR;0;50'
        $r = Invoke-ScriptUnderTest $showback (Get-ShowbackArgs $d)
        $c = @(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';')
        Assert-Equal @('Abteilung', 'SpeicherGB', 'SicherungGB', 'KostenSpeicher', 'KostenSicherung', 'Summe') @($c[0].PSObject.Properties.Name)
        Assert-Equal @('IT', 'Vertrieb', 'HR') @($c | ForEach-Object { $_.Abteilung }) 'größte Summe zuerst'
        $it = $c[0]
        Assert-Equal 12 (ConvertTo-Dez $it.KostenSpeicher) '600 GB mal 20 % Mehrverbrauch mal 0,10'
        Assert-Equal 10 (ConvertTo-Dez $it.KostenSicherung) '200 GB mal 0,05'
        Assert-Equal 22 (ConvertTo-Dez $it.Summe)
        Assert-Equal 8 (ConvertTo-Dez $c[1].KostenSpeicher)
        Assert-Equal 2.5 (ConvertTo-Dez $c[2].Summe) 'HR: nur Sicherung'
        Assert-True (Test-Zeile $r.Output '^Gesamt pro Monat: 37[.,]50$')
    }
}
Test-Case 'unter dem freien Kontingent entstehen keine Speicherkosten; bei null Verbrauch keine Division durch null' {
    Use-Arbeitsordner {
        $d = New-Verbrauch 'A;100;10', 'B;200;0'
        $r = Invoke-ScriptUnderTest $showback (Get-ShowbackArgs $d 5000)
        $c = @(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';')
        Assert-Equal @(0, 0) @($c | ForEach-Object { ConvertTo-Dez $_.KostenSpeicher })
        Assert-True (Test-Zeile $r.Output '^Gesamt pro Monat: 0[.,]50$')
        $d = New-Verbrauch 'A;0;10'
        $r = Invoke-ScriptUnderTest $showback (Get-ShowbackArgs $d 0)
        Assert-True (Test-Zeile $r.Output '^Gesamt pro Monat: 0[.,]50$')
    }
}
Test-Case 'genau am Kontingent: kein Mehrverbrauch, ein GB darüber: alle Kosten beim einzigen Verbraucher' {
    Use-Arbeitsordner {
        $d = New-Verbrauch 'A;800;0'
        $null = Invoke-ScriptUnderTest $showback (Get-ShowbackArgs $d 800)
        Assert-Equal 0 (ConvertTo-Dez (@(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';'))[0].Summe)
        $d = New-Verbrauch 'A;801;0'
        $null = Invoke-ScriptUnderTest $showback (Get-ShowbackArgs $d 800)
        Assert-Equal 0.1 (ConvertTo-Dez (@(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';'))[0].Summe)
    }
}
Test-Case 'Beträge werden auf zwei Nachkommastellen gerundet (Speicher und Sicherung)' {
    Use-Arbeitsordner {
        $d = New-Verbrauch 'A;10;10'
        $a = Get-ShowbackArgs $d 0; $a.PreisSpeicherProGBMonat = 0.123; $a.PreisSicherungProGBMonat = 0.0123
        $null = Invoke-ScriptUnderTest $showback $a
        $z = @(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';')[0]
        Assert-Equal 1.23 (ConvertTo-Dez $z.KostenSpeicher)
        Assert-Equal 0.12 (ConvertTo-Dez $z.KostenSicherung)
        Assert-Equal 1.35 (ConvertTo-Dez $z.Summe)
    }
}
Test-Case 'leere Verbrauchsdatei bricht ab; alle Parameter außer Ausgabe sind Pflicht' {
    Use-Arbeitsordner {
        Write-Datei '.\leer.csv' @('Abteilung;SpeicherGB;SicherungGB')
        Assert-Throws { Invoke-ScriptUnderTest $showback (Get-ShowbackArgs '.\leer.csv') } 'Keine Verbrauchsdaten'
    }
    Assert-Mandatory $showback @('Verbrauch', 'FreiesKontingentGB', 'PreisSpeicherProGBMonat', 'PreisSicherungProGBMonat')
}
Test-Case 'Hinweis: gerundet wird auf gerade Zahlen (0,125 ergibt 0,12), und "400,5" wird als 4005 gelesen' {
    Use-Arbeitsordner {
        $d = New-Verbrauch 'A;0;2,5'
        $a = Get-ShowbackArgs $d; $a.PreisSicherungProGBMonat = 0.05
        $null = Invoke-ScriptUnderTest $showback $a
        Assert-Equal 25 (ConvertTo-Dez (@(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';'))[0].SicherungGB) '2,5 wurde als 25 gelesen (Tausendertrenner)'
        $d = New-Verbrauch 'A;0;2.5'
        $a = Get-ShowbackArgs $d; $a.PreisSicherungProGBMonat = 0.05
        $null = Invoke-ScriptUnderTest $showback $a
        Assert-Equal 0.12 (ConvertTo-Dez (@(Import-Csv -LiteralPath '.\sb.csv' -Delimiter ';'))[0].KostenSicherung) '2,5 mal 0,05 = 0,125, gerundet auf 0,12'
    }
}

# ---------------------------------------------------------------- Listing 157
Write-Host 'Listing 157: Get-AdoptionByDepartment.ps1'
$adoption = Join-Path $skripte 'Get-AdoptionByDepartment.ps1'
function Invoke-Kopie {
    # Das Skript setzt $d = $null und ruft [datetime]::TryParse(..., [ref]$d) auf. Das scheitert (siehe Test "Original scheitert").
    # Die Logik wird deshalb an einer Kopie mit Anfangswert MinValue geprüft.
    param([string]$Pfad, [hashtable]$Argumente = @{})
    $text = Get-Content -LiteralPath $Pfad -Raw -Encoding UTF8
    $neu = $text.Replace('$d = $null', '$d = [datetime]::MinValue')
    if ($neu -eq $text) { throw 'Anfangswert $d = $null nicht gefunden' }
    $kopie = Join-Path (Get-Location).Path 'kopie.ps1'
    Set-Content -LiteralPath $kopie -Value $neu -Encoding UTF8
    Invoke-ScriptUnderTest $kopie $Argumente
}
$aKopf = 'User Principal Name,Is Deleted,Teams Last Activity Date,Exchange Last Activity Date'
function New-Aktivitaet { param([string[]]$Zeilen) Write-Datei '.\akt.csv' (@($aKopf) + $Zeilen); '.\akt.csv' }
function New-StandardAktivitaet {
    New-Aktivitaet @(
        ('anna@example.com,False,{0},{1}' -f (Get-Tag 5), (Get-Tag 60)),
        ('ben@example.com,False,{0},{1}' -f (Get-Tag 40), (Get-Tag 3)),
        'hans@example.com,False,,',
        ('carla@example.com,False,{0},{1}' -f (Get-Tag 1), (Get-Tag 2)),
        ('dora@example.com,False,{0},{0}' -f (Get-Tag 1)),
        ('gina@example.com,True,{0},{0}' -f (Get-Tag 1)),
        'emil@example.com,False,,',
        ('unbekannt@fremd.example.org,False,{0},{0}' -f (Get-Tag 1)))
}
Test-Case 'Aktivitätsanteil je Abteilung aus Verzeichnis und Bericht (an einer Kopie)' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-StandardAktivitaet
        $r = Invoke-Kopie $adoption @{ Bericht = $d }
        Assert-Equal @('User.Read.All') (Get-Scopes)
        Assert-Match $r.OutputText 'Vertrieb\s+3\s+33\s?%\s+33\s?%'
        Assert-Match $r.OutputText 'IT\s+1\s+100\s?%\s+100\s?%'
        Assert-Match $r.OutputText '\(ohne Abteilung\)\s+1\s+0\s?%\s+0\s?%'
        Assert-NotMatch $r.OutputText 'HR' 'gelöschtes Konto (Is Deleted) zählt nicht'
        Assert-NotMatch $r.OutputText 'fremd' 'Konto außerhalb des Verzeichnisses zählt nicht'
    }
}
Test-Case 'deaktivierte Konten des Verzeichnisses zählen nicht; die Tabelle ist nach Abteilung sortiert' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-StandardAktivitaet
        $r = Invoke-Kopie $adoption @{ Bericht = $d }
        Assert-Equal 1 @(([regex]::Matches($r.OutputText, 'IT\s+1\s+')).Value).Count 'dora (deaktiviert) fehlt in der Zahl 1'
        $o = Get-Pos $r.OutputText '(ohne Abteilung)'; $i = Get-Pos $r.OutputText 'IT '; $v = Get-Pos $r.OutputText 'Vertrieb'
        Assert-True ($o -ge 0 -and $o -lt $i -and $i -lt $v) 'alphabetisch'
    }
}
Test-Case 'eine Abteilung nur aus Leerzeichen zählt als "(ohne Abteilung)"' {
    Start-Test
    ($global:MockBet.users | Where-Object { $_.upn -eq 'emil@example.com' }).dept = '   '
    Use-Arbeitsordner {
        $d = New-StandardAktivitaet
        $r = Invoke-Kopie $adoption @{ Bericht = $d }
        Assert-Match $r.OutputText '\(ohne Abteilung\)\s+1\s+'
    }
}
Test-Case 'der Zeitraum: genau -Tage zurück zählt als aktiv, einen Tag davor nicht' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Aktivitaet @(
            ('anna@example.com,False,{0},{1}' -f (Get-Tag 30), (Get-Tag 31)))
        $r = Invoke-Kopie $adoption @{ Bericht = $d }
        Assert-Match $r.OutputText 'Vertrieb\s+1\s+100\s?%\s+0\s?%'
        $r = Invoke-Kopie $adoption @{ Bericht = $d; Tage = 60 }
        Assert-Match $r.OutputText 'Vertrieb\s+1\s+100\s?%\s+100\s?%'
    }
}
Test-Case 'Fehler: leerer Bericht, fehlende Spalte, verborgene Benutzernamen' {
    Start-Test
    Use-Arbeitsordner {
        Write-Datei '.\leer.csv' @($aKopf)
        Assert-Throws { Invoke-Kopie $adoption @{ Bericht = '.\leer.csv' } } 'Der Bericht ist leer'
        Write-Datei '.\spalte.csv' @('Name,Is Deleted', 'anna,False')
        Assert-Throws { Invoke-Kopie $adoption @{ Bericht = '.\spalte.csv' } } "Spalte 'User Principal Name' fehlt"
        $d = New-Aktivitaet @('A1B2C3,False,2026-01-01,2026-01-01')
        Assert-Throws { Invoke-Kopie $adoption @{ Bericht = $d } } 'Kein Benutzername aus dem Bericht im Verzeichnis gefunden'
    }
    Assert-Mandatory $adoption @('Bericht')
}
Test-Case 'Original scheitert an [datetime]::TryParse mit $null als Anfangswert' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-StandardAktivitaet
        $fehler = $null
        try { $null = Invoke-ScriptUnderTest $adoption @{ Bericht = $d } } catch { $fehler = $_ }
        Assert-True ($null -ne $fehler) 'Original scheitert'
        Assert-Match $fehler.Exception.Message 'TryParse'
    }
}

# ---------------------------------------------------------------- Listing 159
Write-Host 'Listing 159: Test-ChampionCoverage.ps1'
$champ = Join-Path $skripte 'Test-ChampionCoverage.ps1'
function New-Champions { param([string[]]$Zeilen) Write-Datei '.\champ.csv' (@('Name;Abteilung') + $Zeilen); '.\champ.csv' }
Test-Case 'nennt Abteilungen ohne Champion (Gäste, deaktivierte Konten und Konten ohne Abteilung zählen nicht)' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Champions 'Paula;Vertrieb'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d }
        Assert-Equal @('User.Read.All') (Get-Scopes)
        Assert-Match $r.OutputText 'IT\s+1\s+0\s+1\s+1'
        Assert-Match $r.OutputText 'HR\s+1\s+0\s+1\s+1'
        Assert-NotMatch $r.OutputText 'Vertrieb' 'Vertrieb hat 3 Mitglieder (der Gast zählt nicht) und einen Champion'
    }
}
Test-Case 'Soll = Beschäftigte geteilt durch Beschäftigte je Champion, aufgerundet, mindestens 1' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Champions 'Paula;Vertrieb'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d; BeschaeftigtePorChampion = 2 }
        Assert-Match $r.OutputText 'Vertrieb\s+3\s+1\s+2\s+1' '3 durch 2 = 1,5, aufgerundet 2'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d; BeschaeftigtePorChampion = 3 }
        Assert-NotMatch $r.OutputText 'Vertrieb' '3 durch 3 = genau 1'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d; BeschaeftigtePorChampion = 1 }
        Assert-Match $r.OutputText 'Vertrieb\s+3\s+1\s+3\s+2'
        $s = Get-Pos $r.OutputText 'Vertrieb'; $i = Get-Pos $r.OutputText 'IT '
        Assert-True ($s -ge 0 -and $s -lt $i) 'größte Lücke zuerst'
    }
}
Test-Case 'sind alle Abteilungen abgedeckt, erscheint die Erfolgsmeldung' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Champions 'Paula;Vertrieb', 'Karl;IT', 'Heidi;HR'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d }
        Assert-True ($r.Output -contains 'Alle Abteilungen erreichen die Zielabdeckung.')
    }
}
Test-Case 'eine Champion-Liste ohne Einträge: jede Abteilung hat eine Lücke' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Champions
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d }
        foreach ($a in 'Vertrieb', 'IT', 'HR') { Assert-Match $r.OutputText "$a\s+\d+\s+0\s+1\s+1" }
    }
    Assert-Mandatory $champ @('Champions')
}
Test-Case 'Hinweis: Groß-/Kleinschreibung zählt nicht, ein Leerzeichen am Ende des Abteilungsnamens schon; unbekannte Abteilungen werden ignoriert' {
    Start-Test
    Use-Arbeitsordner {
        $d = New-Champions 'Paula;vertrieb', 'Karl;IT ', 'Zoe;Marketing'
        $r = Invoke-ScriptUnderTest $champ @{ Champions = $d }
        Assert-NotMatch $r.OutputText 'Vertrieb' 'klein geschrieben genügt'
        Assert-Match $r.OutputText 'IT\s+1\s+0\s+1\s+1' '"IT " mit Leerzeichen passt nicht zu "IT"'
        Assert-NotMatch $r.OutputText 'Marketing'
    }
}

# ---------------------------------------------------------------- Listing 161
Write-Host 'Listing 161: Get-SoftDeletedObjects.ps1'
$weich = Join-Path $skripte 'Get-SoftDeletedObjects.ps1'
Test-Case 'zeigt Benutzer und Gruppen mit Rest-Tagen, kleinste Frist zuerst; Warnung ab 7 Tagen' {
    Start-Test
    $r = Invoke-ScriptUnderTest $weich
    Assert-Equal @('Directory.Read.All') (Get-Scopes)
    Assert-Match $r.OutputText 'Benutzer\s+Aelterer Benutzer\s+\d{4}-\d{2}-\d{2}\s+5\s+Frist endet bald'
    Assert-Match $r.OutputText 'Gruppe\s+PRJ-Alt\s+\d{4}-\d{2}-\d{2}\s+20\s*\r?\n'
    Assert-Match $r.OutputText 'Benutzer\s+Alt Benutzer\s+\d{4}-\d{2}-\d{2}\s+27\s*(\r?\n|$)'
    $a = Get-Pos $r.OutputText 'Aelterer'; $g = Get-Pos $r.OutputText 'PRJ-Alt'; $b = Get-Pos $r.OutputText 'Alt Benutzer'
    Assert-True ($a -ge 0 -and $a -lt $g -and $g -lt $b) 'aufsteigend nach Rest-Tagen'
    Assert-Equal 1 @(([regex]::Matches($r.OutputText, 'Frist endet bald')).Value).Count
}
Test-Case '-Frist und -Warnschwelle verschieben die Werte; die Schwelle selbst gilt noch als Warnung' {
    Start-Test
    $r = Invoke-ScriptUnderTest $weich @{ Frist = 60 }
    Assert-Match $r.OutputText 'Aelterer Benutzer\s+\d{4}-\d{2}-\d{2}\s+35\s*(\r?\n|$)'
    Start-Test
    $r = Invoke-ScriptUnderTest $weich @{ Warnschwelle = 20 }
    Assert-Match $r.OutputText 'PRJ-Alt\s+\d{4}-\d{2}-\d{2}\s+20\s+Frist endet bald' 'genau 20 Rest-Tage bei Schwelle 20'
    Assert-Equal 2 @(([regex]::Matches($r.OutputText, 'Frist endet bald')).Value).Count
}
Test-Case 'Hinweis: liefert die SDK-Version den Löschzeitpunkt als DateTimeOffset, scheitert die Subtraktion (Get-Date) minus DeletedDateTime' {
    Start-Test
    $global:MockBet.options.deletedAsDateTime = $false
    $fehler = $null
    try { $null = Invoke-ScriptUnderTest $weich } catch { $fehler = $_ }
    Assert-True ($null -ne $fehler) 'Skript bricht ab'
    Assert-Match $fehler.Exception.Message 'op_Subtraction'
}
Test-Case 'nur Benutzer oder nur Gruppen genügen; ohne gelöschte Objekte erscheint der Hinweis' {
    Start-Test
    $global:MockBet.deletedGroups = @()
    $r = Invoke-ScriptUnderTest $weich
    Assert-NotMatch $r.OutputText 'Gruppe'
    Assert-Match $r.OutputText 'Benutzer'
    $global:MockBet.deletedUsers = @()
    $r = Invoke-ScriptUnderTest $weich
    Assert-True ($r.Output -contains 'Keine vorlaeufig geloeschten Objekte.')
}
Test-Case 'Hinweis: die Rest-Tage werden aus der gerundeten Zahl der vergangenen Tage berechnet (5,6 Tage ergeben 6, nicht 5)' {
    Start-Test
    $global:MockBet.deletedUsers = @([pscustomobject]@{ name = 'Gerundet'; daysAgo = 5.6 })
    $global:MockBet.deletedGroups = @()
    $r = Invoke-ScriptUnderTest $weich
    Assert-Match $r.OutputText 'Gerundet\s+\d{4}-\d{2}-\d{2}\s+24\s*(\r?\n|$)' 'tatsächlich bleiben rund 24,4 Tage; 30 minus aufgerundete 6 ergibt 24'
    $global:MockBet.deletedUsers = @([pscustomobject]@{ name = 'Gerundet'; daysAgo = 5.4 })
    $r = Invoke-ScriptUnderTest $weich
    Assert-Match $r.OutputText 'Gerundet\s+\d{4}-\d{2}-\d{2}\s+25\s*(\r?\n|$)'
}

# ---------------------------------------------------------------- Listing 163
Write-Host 'Listing 163: Find-KpiTrends.ps1'
$kpi = Join-Path $skripte 'Find-KpiTrends.ps1'
function New-KpiDatei {
    param([string[]]$Zeilen)
    Write-Datei '.\kpi.csv' (@('Kennzahl;Datum;Wert;Ziel;BesserWenn') + $Zeilen); '.\kpi.csv'
}
function New-Reihe {
    # Werte der Reihe nach, ein Monat Abstand; Ziel und Richtung gelten für die ganze Reihe
    param([string]$Name, [double[]]$Werte, [double]$Ziel, [string]$Richtung = 'hoeher')
    for ($i = 0; $i -lt $Werte.Count; $i++) { '{0};2026-{1:00}-01;{2};{3};{4}' -f $Name, ($i + 1), $Werte[$i], $Ziel, $Richtung }
}
Test-Case 'meldet verfehlte Ziele in beide Richtungen; das Ziel selbst gilt als erreicht' {
    Use-Arbeitsordner {
        $z = @(New-Reihe 'Hoch' @(95, 94, 89) 90) + @(New-Reihe 'Niedrig' @(10, 12, 18) 15 'niedriger') + @(New-Reihe 'GenauHoch' @(90) 90) + @(New-Reihe 'GenauNiedrig' @(15) 15 'niedriger')
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei $z) }
        Assert-Match $r.OutputText 'Hoch\s+89([.,]00)?\s+90([.,]00)?\s+Ziel verfehlt'
        Assert-Match $r.OutputText 'Niedrig\s+18([.,]00)?\s+15([.,]00)?\s+Ziel verfehlt'
        Assert-NotMatch $r.OutputText 'Genau'
    }
}
Test-Case 'erkennt eine Verschlechterung über mehrere Perioden, aber nur bei strenger Verschlechterung' {
    Use-Arbeitsordner {
        $z = @(New-Reihe 'Tickets' @(40, 42, 45, 47) 50 'niedriger') + @(New-Reihe 'Gleich' @(92, 92, 92, 92) 90) + @(New-Reihe 'Besser' @(80, 85, 90, 95) 70)
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei $z) }
        Assert-Match $r.OutputText 'Tickets\s+47([.,]00)?\s+50([.,]00)?\s+3 Perioden schlechter'
        Assert-NotMatch $r.OutputText 'Gleich'
        Assert-NotMatch $r.OutputText 'Besser'
    }
}
Test-Case 'Ziel verfehlt und Verschlechterung stehen zusammen im Befund' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei @(New-Reihe 'Beides' @(95, 93, 91, 89) 90)) }
        Assert-Match $r.OutputText 'Beides\s+89([.,]00)?\s+90([.,]00)?\s+Ziel verfehlt; 3 Perioden schlechter'
    }
}
Test-Case '-Perioden bestimmt, wie viele Werte schlechter werden müssen; zu kurze Reihen werden nicht bewertet' {
    Use-Arbeitsordner {
        $d = New-KpiDatei (New-Reihe 'Trend' @(95, 94, 93) 80)
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = $d }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.') 'drei Werte: nicht mehr als 3 Perioden'
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = $d; Perioden = 2 }
        Assert-Match $r.OutputText 'Trend\s+93([.,]00)?\s+80([.,]00)?\s+2 Perioden schlechter'
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'Trend' @(95, 94, 93, 92) 80)); Perioden = 4 }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.') 'vier Werte reichen für 4 Perioden nicht'
    }
}
Test-Case 'die Reihe wird nach Datum sortiert, nicht nach der Reihenfolge in der Datei' {
    Use-Arbeitsordner {
        $z = @(New-Reihe 'Umgekehrt' @(80, 85, 90, 95) 70)
        [array]::Reverse($z)
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei $z) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.')
    }
}
Test-Case 'nur der letzte Abschnitt zählt: erst besser, dann zweimal schlechter reicht nicht für 3 Perioden' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'Erst' @(90, 95, 94, 93) 80)) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.')
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'Erst' @(90, 95, 94, 93) 80)); Perioden = 2 }
        Assert-Match $r.OutputText 'Erst\s+93([.,]00)?\s+80([.,]00)?\s+2 Perioden schlechter'
    }
}
Test-Case 'bei "niedriger" ist ein gleichbleibender Wert keine Verschlechterung' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'GleichNiedrig' @(40, 45, 45, 45) 50 'niedriger')) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.')
    }
}
Test-Case 'die Sortierung nach Datum arbeitet mit echten Datumswerten (2026-9-1 liegt vor 2026-10-1)' {
    Use-Arbeitsordner {
        $z = @('Spaet;2026-9-1;40;50;niedriger', 'Spaet;2026-10-1;42;50;niedriger', 'Spaet;2026-11-1;45;50;niedriger', 'Spaet;2026-12-1;47;50;niedriger')
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei $z) }
        Assert-Match $r.OutputText 'Spaet\s+47([.,]00)?\s+50([.,]00)?\s+3 Perioden schlechter'
    }
}
Test-Case 'leere Datei bricht ab; Datei ist Pflicht' {
    Use-Arbeitsordner {
        Write-Datei '.\leer.csv' @('Kennzahl;Datum;Wert;Ziel;BesserWenn')
        Assert-Throws { Invoke-ScriptUnderTest $kpi @{ Datei = '.\leer.csv' } } 'Keine Daten'
    }
    Assert-Mandatory $kpi @('Datei')
}
Test-Case 'Hinweis: nur das genaue Wort "hoeher" gilt als höher-ist-besser; "höher" wird wie "niedriger" behandelt' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'Umlaut' @(95) 90 'höher')) }
        Assert-Match $r.OutputText 'Umlaut\s+95([.,]00)?\s+90([.,]00)?\s+Ziel verfehlt' '95 bei Ziel 90 gilt als verfehlt, weil größere Werte als schlechter angesehen werden'
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei (New-Reihe 'Gross' @(95) 90 'Hoeher')) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.') 'die Schreibweise spielt keine Rolle'
    }
}
Test-Case 'Hinweis: ein Komma als Dezimalzeichen wird als Tausendertrenner gelesen (98,5 wird 985)' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei @('Komma;2026-01-01;98,5;90;hoeher')) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.') '985 liegt über dem Ziel 90 (gemeint war 98,5)'
        $r = Invoke-ScriptUnderTest $kpi @{ Datei = (New-KpiDatei @('Komma;2026-01-01;9,5;90;hoeher')) }
        Assert-True ($r.Output -contains 'Keine auffaelligen Kennzahlen.') '9,5 wird 95 und liegt damit über dem Ziel 90'
    }
}

# ---------------------------------------------------------------- Listing 165/166
Write-Host 'Listing 165/166: roadmap.json und Test-Roadmap.ps1'
$roadmapSkript = Join-Path $skripte 'Test-Roadmap.ps1'
$roadmapJson = Join-Path $skripte 'roadmap.json'
function New-Aufgabe {
    param([string]$Id, [int]$Von, [int]$Bis, [string]$Wer = 'Anna', [int]$Stunden = 10, [string[]]$Nach = @(), [string]$Name = 'Aufgabe')
    [pscustomobject]@{ id = $Id; name = "$Name $Id"; von = $Von; bis = $Bis; wer = $Wer; stunden = $Stunden; nach = @($Nach) }
}
function New-Roadmap {
    param($Aufgaben, [int]$Stunden = 40)
    $o = [ordered]@{ start = '2026-11-02'; stundenProPersonUndPhase = $Stunden; aufgaben = @($Aufgaben) }
    Set-Content -LiteralPath '.\r.json' -Value ($o | ConvertTo-Json -Depth 5) -Encoding UTF8
    '.\r.json'
}
function Get-Probleme { param($Ergebnis) @($Ergebnis.Info | Where-Object { $_ -like 'PROBLEM:*' }) }
Test-Case 'die mitgelieferte roadmap.json ist ein Auszug mit einem Konflikt: B2 beginnt vor dem Ende von B1' {
    Use-Arbeitsordner {
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $roadmapJson }
        Assert-Equal 2 (Get-ExitCode)
        Assert-Equal @('PROBLEM: B2 beginnt an Tag 40, Vorgaenger B1 endet erst an Tag 45') (Get-Probleme $r)
        $j = Get-Content -LiteralPath $roadmapJson -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert-Equal 5 @($j.aufgaben).Count
        Assert-Equal 40 $j.stundenProPersonUndPhase
    }
}
Test-Case 'eine stimmige Roadmap: Exit-Code ohne Fehler und Markdown-Tabelle mit echten Datumsangaben' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 20 'Anna' 30 -Name 'Ist-Analyse'), (New-Aufgabe 'B1' 31 45 'Anna' 20 @('A1') -Name 'Standard'))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d; Ausgabe = '.\rm.md' }
        Assert-True ((Get-ExitCode) -ne 2) 'kein Fehlercode'
        Assert-Equal 0 (Get-Probleme $r).Count
        Assert-True ($r.Info -contains 'Roadmap ist konsistent. Ausgabe: .\rm.md')
        $z = @(Get-Content -LiteralPath '.\rm.md' -Encoding UTF8)
        Assert-Equal '| Nr | Aufgabe | Von | Bis | Wer | Stunden |' $z[0]
        Assert-Equal '|---|---|---|---|---|---|' $z[1]
        Assert-Equal '| A1 | Ist-Analyse A1 | 2026-11-02 | 2026-11-21 | Anna | 30 |' $z[2]
        Assert-Equal '| B1 | Standard B1 | 2026-12-02 | 2026-12-16 | Anna | 20 |' $z[3]
    }
}
Test-Case 'die Tabelle ist nach Beginn sortiert und wird auch bei Problemen geschrieben' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'Z9' 50 55 'Ben'), (New-Aufgabe 'A1' 1 5 'Anna'), (New-Aufgabe 'M5' 20 25 'Cem' 10 @('Fehlt')))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d; Ausgabe = '.\rm.md' }
        Assert-Equal 2 (Get-ExitCode)
        $z = @(Get-Content -LiteralPath '.\rm.md' -Encoding UTF8)
        Assert-Equal @('A1', 'M5', 'Z9') @($z[2..4] | ForEach-Object { ($_ -split '\|')[1].Trim() })
    }
}
Test-Case 'Fehler: Ende vor Beginn, unbekannter Vorgänger, Vorgänger noch nicht beendet' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'A1' 10 5), (New-Aufgabe 'B1' 20 25 'Ben' 10 @('X9')), (New-Aufgabe 'C1' 3 8 'Cem' 10 @('A1')))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 2 (Get-ExitCode)
        $p = Get-Probleme $r
        Assert-True ($p -contains 'PROBLEM: A1: Ende vor Beginn')
        Assert-True ($p -contains 'PROBLEM: B1: Vorgaenger X9 existiert nicht')
        Assert-True ($p -contains 'PROBLEM: C1 beginnt an Tag 3, Vorgaenger A1 endet erst an Tag 5')
        Assert-Equal 3 $p.Count
    }
}
Test-Case 'eine Aufgabe von einem Tag (Beginn gleich Ende) ist zulässig' {
    Use-Arbeitsordner {
        $r = Invoke-MitExit $roadmapSkript @{ Datei = (New-Roadmap @((New-Aufgabe 'A1' 5 5))) }
        Assert-Equal 0 (Get-Probleme $r).Count
        Assert-True ((Get-ExitCode) -ne 2)
    }
}
Test-Case 'sortiert wird nach Beginn, nicht nach Ende' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'Lang' 1 100 'Anna' 5), (New-Aufgabe 'Kurz' 2 5 'Ben' 5))
        $null = Invoke-MitExit $roadmapSkript @{ Datei = $d; Ausgabe = '.\rm.md' }
        $z = @(Get-Content -LiteralPath '.\rm.md' -Encoding UTF8)
        Assert-Match $z[2] '^\| Lang \|'
        Assert-Match $z[3] '^\| Kurz \|'
    }
}
Test-Case 'Vorgänger: endet er am Tag des Beginns, ist das ein Problem; am Vortag nicht' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 10), (New-Aufgabe 'B1' 10 20 'Ben' 10 @('A1')))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 2 (Get-ExitCode)
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 10), (New-Aufgabe 'B1' 11 20 'Ben' 10 @('A1')))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 0 (Get-Probleme $r).Count
    }
}
Test-Case 'Überbuchung je Person und Phase; die Grenze selbst ist erlaubt' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 20 'Anna' 30), (New-Aufgabe 'A2' 10 25 'Anna' 11))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal @('PROBLEM: Anna in Phase 1: 41 Stunden geplant, verfuegbar 40') (Get-Probleme $r)
        Assert-Equal 2 (Get-ExitCode)
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 20 'Anna' 30), (New-Aufgabe 'A2' 10 25 'Anna' 10))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 0 (Get-Probleme $r).Count '40 von 40 Stunden'
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 20 'Anna' 30), (New-Aufgabe 'A2' 10 25 'Anna' 10)) 39
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 1 (Get-Probleme $r).Count 'das Stundenkontingent steht in der Datei'
    }
}
Test-Case 'die Phase richtet sich nach dem Beginn: Tag 30 gehört zu Phase 1, 31 zu 2, 60 zu 2, 61 zu 3' {
    Use-Arbeitsordner {
        foreach ($t in @(@(30, 1), @(31, 2), @(60, 2), @(61, 3))) {
            $d = New-Roadmap @((New-Aufgabe 'X' $t[0] ($t[0] + 1) 'Anna' 41))
            $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
            Assert-Equal @("PROBLEM: Anna in Phase $($t[1]): 41 Stunden geplant, verfuegbar 40") (Get-Probleme $r) "Beginn an Tag $($t[0])"
        }
    }
}
Test-Case 'Stunden verschiedener Personen und verschiedener Phasen werden nicht zusammengezählt' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'A1' 1 5 'Anna' 40), (New-Aufgabe 'A2' 2 6 'Ben' 40), (New-Aufgabe 'A3' 31 35 'Anna' 40), (New-Aufgabe 'A4' 61 65 'Anna' 40))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal 0 (Get-Probleme $r).Count
    }
}
Test-Case 'Hinweis: eine Aufgabe zählt mit allen Stunden in der Phase, in der sie beginnt' {
    Use-Arbeitsordner {
        $d = New-Roadmap @((New-Aufgabe 'Lang' 25 90 'Anna' 40), (New-Aufgabe 'Kurz' 26 28 'Anna' 5))
        $r = Invoke-MitExit $roadmapSkript @{ Datei = $d }
        Assert-Equal @('PROBLEM: Anna in Phase 1: 45 Stunden geplant, verfuegbar 40') (Get-Probleme $r)
    }
    Assert-Mandatory $roadmapSkript @('Datei')
}

# ---------------------------------------------------------------- Aufgabe 6
Write-Host 'Aufgabe 6: Nutzungsgrad je Abteilung'
$grad = Join-Path $loesungen 'aufgabe-06-nutzungsgrad.ps1'
function New-Grad { param([string[]]$Zeilen) Write-Datei '.\g.csv' (@('Abteilung;Beschaeftigte;Aktive') + $Zeilen); '.\g.csv' }
Test-Case 'große Abteilungen einzeln, kleine zusammengefasst; Markierung unter 50 Prozent' {
    Use-Arbeitsordner {
        $d = New-Grad 'Vertrieb;20;8', 'IT;10;9', 'Einkauf;5;5', 'Rezeption;4;1', 'Archiv;2;1'
        $r = Invoke-ScriptUnderTest $grad @{ Datei = $d }
        Assert-Match $r.OutputText 'Vertrieb\s+40\s?%\s+unter 50 Prozent'
        Assert-Match $r.OutputText 'IT\s+90\s?%\s*(\r?\n|$)'
        Assert-Match $r.OutputText 'Einkauf\s+100\s?%' 'genau die Mindestgröße 5 zählt als groß'
        Assert-Match $r.OutputText '\(kleine Abteilungen zusammengefasst\)\s+33\s?%\s+unter 50 Prozent' '2 von 6'
        Assert-NotMatch $r.OutputText 'Rezeption|Archiv' 'kleine Abteilungen einzeln nicht erkennbar'
    }
}
Test-Case 'genau 50 Prozent sind nicht markiert; -Mindestgroesse verschiebt die Grenze' {
    Use-Arbeitsordner {
        $d = New-Grad 'Vertrieb;20;10', 'Einkauf;12;6', 'IT;10;9', 'Archiv;2;1'
        $r = Invoke-ScriptUnderTest $grad @{ Datei = $d }
        Assert-NotMatch $r.OutputText 'unter 50' 'genau 50 Prozent ist nicht markiert'
        $r = Invoke-ScriptUnderTest $grad @{ Datei = $d; Mindestgroesse = 11 }
        Assert-NotMatch $r.OutputText 'IT\s+90'
        Assert-Match $r.OutputText '\(kleine Abteilungen zusammengefasst\)\s+83\s?%' '9 plus 1 von 10 plus 2'
    }
}
Test-Case 'nur kleine Abteilungen: eine einzige zusammengefasste Zeile; nur große: keine Sammelzeile' {
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest $grad @{ Datei = (New-Grad 'A;2;1', 'B;3;3') }
        Assert-Match $r.OutputText '\(kleine Abteilungen zusammengefasst\)\s+80\s?%'
        $r = Invoke-ScriptUnderTest $grad @{ Datei = (New-Grad 'A;20;10', 'B;30;30') }
        Assert-NotMatch $r.OutputText 'zusammengefasst'
    }
    Assert-Mandatory $grad @('Datei')
}
Test-Case 'Hinweis: eine große Abteilung allein neben kleinen führt zum Fehler beim Anhängen der Sammelzeile' {
    Use-Arbeitsordner {
        $d = New-Grad 'Vertrieb;20;8', 'Archiv;2;1'
        $fehler = $null
        try { $null = Invoke-ScriptUnderTest $grad @{ Datei = $d } } catch { $fehler = $_ }
        Assert-True ($null -ne $fehler) 'einzelnes Objekt kann nicht mit += erweitert werden'
    }
}
Test-Case 'Hinweis: mit -Mindestgroesse 0 und einer Abteilung ohne Beschäftigte entsteht eine Division durch null' {
    Use-Arbeitsordner {
        $d = New-Grad 'Leer;0;0', 'IT;10;5'
        Assert-Throws { Invoke-ScriptUnderTest $grad @{ Datei = $d; Mindestgroesse = 0 } }
    }
}

Complete-Tests
