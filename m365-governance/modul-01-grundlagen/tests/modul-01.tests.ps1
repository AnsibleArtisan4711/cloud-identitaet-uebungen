# modul-01.tests.ps1 - Offline-Tests für die Skripte aus Modul 01.
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-01-grundlagen/tests/modul-01.tests.ps1
# Die Graph-Cmdlets sind simuliert (tools/Mock-MgGraph.ps1). Geprüft wird die Logik der Skripte, nicht das echte Microsoft Graph.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'tenant-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Assert-ReadOnlyScopes {
    $schreibend = @(Get-MockScopes | Where-Object { $_ -match 'ReadWrite|\.Write' })
    Assert-Equal 0 $schreibend.Count "Schreibende Berechtigungen angefordert: $($schreibend -join ', ')"
    Assert-True (@(Get-MockScopes).Count -gt 0) 'Das Skript hat sich gar nicht angemeldet.'
}

Write-Host 'Listing 1: Get-TenantSnapshot.ps1'
Test-Case 'liefert Name, Benutzer, Gäste und Gruppen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-TenantSnapshot.ps1')
    Assert-Match $r.Text 'Beispiel GmbH'
    Assert-Match $r.Text 'Benutzer\s*:\s*50'
    Assert-Match $r.Text 'Gaeste\s*:\s*12'
    Assert-Match $r.Text 'M365Gruppen\s*:\s*5'
    Assert-ReadOnlyScopes
}

Write-Host 'Listing 2: Find-GroupsWithFewOwners.ps1'
Test-Case 'findet Gruppen mit weniger als 2 Besitzern, sortiert' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory; $csv = Join-Path $tmp 'out.csv'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Find-GroupsWithFewOwners.ps1') @{ OutFile = $csv }
    $zeilen = @(Import-Csv -LiteralPath $csv)
    Assert-Equal 3 $zeilen.Count
    Assert-Equal 'Team Marketing' $zeilen[0].Gruppe 'Besitzer 0 zuerst'
    Assert-Equal 'Projekt Alpha' $zeilen[1].Gruppe
    Assert-Equal 'Team Finanzen' $zeilen[2].Gruppe
    Assert-Match ($r.Info -join ' ') '3 von 5 Gruppen haben weniger als 2 Besitzer'
    Assert-ReadOnlyScopes
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
Test-Case 'Parameter -MinOwners ändert die Schwelle' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory; $csv = Join-Path $tmp 'out.csv'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Find-GroupsWithFewOwners.ps1') @{ OutFile = $csv; MinOwners = 1 }
    Assert-Equal 1 @(Import-Csv -LiteralPath $csv).Count
    Assert-Match ($r.Info -join ' ') '1 von 5 Gruppen haben weniger als 1 Besitzer'
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
Test-Case 'fragt nur Microsoft-365-Gruppen ab und macht je Gruppe einen Besitzer-Aufruf' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory
    Invoke-ScriptUnderTest (Join-Path $skripte 'Find-GroupsWithFewOwners.ps1') @{ OutFile = (Join-Path $tmp 'o.csv') } | Out-Null
    $aufrufe = @($global:MockCalls | Where-Object { $_.Name -eq 'Get-MgGroupOwner' }).Count
    Assert-Equal 5 $aufrufe 'ein Serviceaufruf pro Gruppe (der im Skript beschriebene Engpass bei großen Tenants)'
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Host 'Aufgabe 4: nur Gruppen, die älter als 30 Tage sind'
Test-Case 'überspringt neue Gruppen und spart deren Besitzerabfrage' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory; $csv = Join-Path $tmp 'out.csv'
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'Find-GroupsWithFewOwners.aufgabe-4.ps1') @{ OutFile = $csv }
    $zeilen = @(Import-Csv -LiteralPath $csv)
    Assert-Equal 2 $zeilen.Count 'Projekt Alpha (10 Tage) darf nicht dabei sein'
    Assert-Equal 'Team Marketing' $zeilen[0].Gruppe
    Assert-Equal 'Team Finanzen' $zeilen[1].Gruppe
    $aufrufe = @($global:MockCalls | Where-Object { $_.Name -eq 'Get-MgGroupOwner' }).Count
    Assert-Equal 3 $aufrufe 'zwei junge Gruppen (10 und 5 Tage) werden nicht abgefragt'
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Host 'Listing 3: Get-LicenseOverview.ps1'
Test-Case 'zeigt Lizenzen sortiert mit freien Lizenzen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-LicenseOverview.ps1')
    $t = $r.OutputText
    Assert-True ($t.IndexOf('AAD_PREMIUM') -lt $t.IndexOf('FLOW_FREE')) 'Sortierung nach Name'
    Assert-True ($t.IndexOf('FLOW_FREE') -lt $t.IndexOf('O365_BUSINESS_ESSENTIALS')) 'Sortierung nach Name'
    Assert-Match $t 'O365_BUSINESS_ESSENTIALS\s+25\s+22\s+3\s+9'
    Assert-ReadOnlyScopes
}

Write-Host 'Listing 4: Get-GlobalAdminReport.ps1'
Test-Case 'listet aktive und berechtigte Administratoren, ohne Warnung bei 3' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-GlobalAdminReport.ps1')
    $info = $r.Info -join "`n"
    Assert-Match $info 'Aktive Globale Administratoren \(3\)'
    Assert-Match $info 'Berechtigte Globale Administratoren \(1\)'
    Assert-Match $r.OutputText 'admin\.eins@example\.com'
    Assert-Equal 0 $r.Warnings.Count
    Assert-ReadOnlyScopes
}
Test-Case 'warnt ab 5 aktiven Globalen Administratoren' {
    Initialize-MockTenant $fixture
    $global:MockTenant.activeGlobalAdmins += [pscustomobject]@{ upn = 'x1@example.com'; name = 'X1' }
    $global:MockTenant.activeGlobalAdmins += [pscustomobject]@{ upn = 'x2@example.com'; name = 'X2' }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-GlobalAdminReport.ps1')
    Assert-Equal 1 $r.Warnings.Count
    Assert-Match $r.Warnings[0] 'weniger als 5'
}

Write-Host 'Listing 6: Test-PolicyCompliance.ps1'
Test-Case 'meldet OK bei 3 von höchstens 4 Globalen Administratoren' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PolicyCompliance.ps1') @{ PolicyFile = (Join-Path $skripte 'policy-tenant.json') }
    $e = @($r.Output)[0]
    Assert-Equal 'maxGlobalAdmins' $e.Regel
    Assert-Equal '<= 4' $e.Soll
    Assert-Equal 3 $e.Ist
    Assert-Equal 'OK' $e.Ergebnis
    Assert-ReadOnlyScopes
}
Test-Case 'meldet ABWEICHUNG bei 5 Globalen Administratoren' {
    Initialize-MockTenant $fixture
    $global:MockTenant.activeGlobalAdmins += [pscustomobject]@{ upn = 'x1@example.com'; name = 'X1' }
    $global:MockTenant.activeGlobalAdmins += [pscustomobject]@{ upn = 'x2@example.com'; name = 'X2' }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PolicyCompliance.ps1') @{ PolicyFile = (Join-Path $skripte 'policy-tenant.json') }
    Assert-Equal 'ABWEICHUNG' @($r.Output)[0].Ergebnis
}

Test-Case 'meldet OK bei genau 4 Globalen Administratoren (Grenze ist "höchstens 4")' {
    Initialize-MockTenant $fixture
    $global:MockTenant.activeGlobalAdmins += [pscustomobject]@{ upn = 'x1@example.com'; name = 'X1' }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PolicyCompliance.ps1') @{ PolicyFile = (Join-Path $skripte 'policy-tenant.json') }
    Assert-Equal 4 @($r.Output)[0].Ist
    Assert-Equal 'OK' @($r.Output)[0].Ergebnis
}

Write-Host 'Aufgabe 5: Regel maxGuestShare'
$p5 = Join-Path $loesungen 'policy-tenant.aufgabe-5.json'
$s5 = Join-Path $loesungen 'Test-PolicyCompliance.aufgabe-5.ps1'
Test-Case 'JSON enthält die neue Regel und bleibt lesbar' {
    $p = Get-Content -LiteralPath $p5 -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Equal 0.2 $p.rules.maxGuestShare
    Assert-Equal 4 $p.rules.maxGlobalAdmins
}
Test-Case 'Gästeanteil 12 von 50 (0,24) liegt über 0,2: ABWEICHUNG' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest $s5 @{ PolicyFile = $p5 }
    $erg = @($r.Output)
    Assert-Equal 2 $erg.Count 'beide Regeln werden geprüft'
    $g = $erg | Where-Object { $_.Regel -eq 'maxGuestShare' }
    Assert-Equal '<= 0.2' $g.Soll
    Assert-Equal 0.24 $g.Ist
    Assert-Equal 'ABWEICHUNG' $g.Ergebnis
    Assert-ReadOnlyScopes
    Assert-True ((Get-MockScopes) -contains 'User.Read.All') 'User.Read.All wird für die Zählabfrage gebraucht'
}
Test-Case 'Gästeanteil 5 von 50 (0,1): OK' {
    Initialize-MockTenant $fixture
    $global:MockTenant.guestCount = 5
    $r = Invoke-ScriptUnderTest $s5 @{ PolicyFile = $p5 }
    Assert-Equal 'OK' (@($r.Output) | Where-Object { $_.Regel -eq 'maxGuestShare' }).Ergebnis
}
Test-Case 'Gästeanteil genau 0,2 (2 von 10) ist erlaubt: OK' {
    Initialize-MockTenant $fixture
    $global:MockTenant.userCount = 10
    $global:MockTenant.guestCount = 2
    $r = Invoke-ScriptUnderTest $s5 @{ PolicyFile = $p5 }
    Assert-Equal 'OK' (@($r.Output) | Where-Object { $_.Regel -eq 'maxGuestShare' }).Ergebnis
}
Test-Case 'kleiner Tenant (4 Benutzer, 1 Gast = 0,25): ABWEICHUNG' {
    Initialize-MockTenant $fixture
    $global:MockTenant.userCount = 4
    $global:MockTenant.guestCount = 1
    $r = Invoke-ScriptUnderTest $s5 @{ PolicyFile = $p5 }
    $g = @($r.Output) | Where-Object { $_.Regel -eq 'maxGuestShare' }
    Assert-Equal 0.25 $g.Ist
    Assert-Equal 'ABWEICHUNG' $g.Ergebnis
}
Test-Case 'leerer Tenant (0 Benutzer): keine Division durch null' {
    Initialize-MockTenant $fixture
    $global:MockTenant.userCount = 0
    $global:MockTenant.guestCount = 0
    $r = Invoke-ScriptUnderTest $s5 @{ PolicyFile = $p5 }
    $g = @($r.Output) | Where-Object { $_.Regel -eq 'maxGuestShare' }
    Assert-Equal 0 $g.Ist
    Assert-Equal 'OK' $g.Ergebnis
    Assert-Equal 0 $r.Errors.Count
}

Write-Host 'Listing 7: Test-TenantBaseline.ps1'
Test-Case 'bewertet Fixture: Security Defaults INFO, Conditional Access OK, Notfallkonten MANUELL' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TenantBaseline.ps1')
    $t = $r.OutputText
    Assert-Match $t 'Security Defaults\s+INFO\s+aktiv: False'
    Assert-Match $t 'Conditional Access\s+OK\s+1 von 3 Richtlinien aktiv'
    Assert-Match $t 'Globale Administratoren\s+OK\s+3 aktive Zuweisungen'
    Assert-Match $t 'MANUELL'
    Assert-ReadOnlyScopes
}
Test-Case 'ohne Conditional Access und ohne Security Defaults: ABWEICHUNG' {
    Initialize-MockTenant $fixture
    $global:MockTenant.conditionalAccessPolicies = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TenantBaseline.ps1')
    Assert-Match $r.OutputText 'Conditional Access\s+ABWEICHUNG\s+0 von 0'
}
Test-Case 'ohne Conditional Access, aber mit Security Defaults: PRUEFEN' {
    Initialize-MockTenant $fixture
    $global:MockTenant.conditionalAccessPolicies = @()
    $global:MockTenant.securityDefaultsEnabled = $true
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-TenantBaseline.ps1')
    Assert-Match $r.OutputText 'Conditional Access\s+PRUEFEN'
}

Write-Host 'Listing 8: New-GovernanceBacklog.ps1'
function Assert-Reihenfolge {
    param([string]$Text, [string[]]$Namen)
    $letzte = -1
    foreach ($n in $Namen) {
        $pos = $Text.IndexOf($n)
        Assert-True ($pos -ge 0) "'$n' fehlt in der Ausgabe."
        Assert-True ($pos -gt $letzte) "'$n' steht an der falschen Stelle."
        $letzte = $pos
    }
}
Test-Case 'sortiert nach Welle, dann nach Priorität absteigend' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-GovernanceBacklog.ps1')
    Assert-Reihenfolge $r.OutputText @('Notfallzugriffskonten', 'Besitzerpflicht', 'Namensrichtlinie', 'Gaeste-Rezertifizierung', 'Vertraulichkeitsbezeichnungen', 'Provisioning-Prozess')
    Assert-Match $r.OutputText '1\s+9([.,]00)?\s+4\s+5\s+1\s+Notfallzugriffskonten'
    Assert-Match $r.OutputText '1\s+3[.,]50?\s+4\s+3\s+2\s+Besitzerpflicht'
}

Write-Host 'Aufgabe 8: Gewichte und Fehlerbehandlung'
$s8 = Join-Path $loesungen 'New-GovernanceBacklog.aufgabe-8.ps1'
Test-Case 'Standardgewichte 1 und 1 ergeben dieselben Werte wie Listing 8' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest $s8
    Assert-Match $r.OutputText '1\s+9([.,]00)?\s+4\s+5\s+1\s+Notfallzugriffskonten'
    Assert-Equal 0 $r.Warnings.Count
}
Test-Case '-WeightRisk 2 wirkt auf die Priorität' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest $s8 @{ WeightRisk = 2 }
    Assert-Match $r.OutputText '1\s+14([.,]00)?\s+4\s+5\s+1\s+Notfallzugriffskonten'
}
Test-Case 'Aufwand 0 oder Text ergibt eine Warnung, das Skript läuft weiter' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory
    $kopie = Join-Path $tmp 'backlog-fehler.ps1'
    $text = Get-Content -LiteralPath $s8 -Raw -Encoding UTF8
    $text = $text.Replace('Gaeste-Rezertifizierung einfuehren,4,4,3,2', 'Gaeste-Rezertifizierung einfuehren,4,4,0,2')
    $text = $text.Replace('Provisioning-Prozess automatisieren,4,2,5,3', 'Provisioning-Prozess automatisieren,4,2,abc,3')
    Assert-True ($text.Contains(',4,4,0,2') -and $text.Contains(',4,2,abc,3')) 'Testdaten wurden nicht eingesetzt'
    Set-Content -LiteralPath $kopie -Value $text -Encoding UTF8
    $r = Invoke-ScriptUnderTest $kopie
    Assert-Equal 2 $r.Warnings.Count
    Assert-Match ($r.Warnings -join ' ') 'Gaeste-Rezertifizierung'
    Assert-Match ($r.Warnings -join ' ') 'Provisioning-Prozess'
    Assert-Equal 0 $r.Errors.Count
    Assert-Match $r.OutputText 'Notfallzugriffskonten'
    Assert-NotMatch $r.OutputText 'Gaeste-Rezertifizierung'
    Assert-NotMatch $r.OutputText 'Provisioning-Prozess'
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Host 'Listing 9: Export-GroupArchitecture.ps1'
Test-Case 'zählt Gruppen nach Typ und Dynamik und schreibt die Markdown-Tabelle' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory
    Push-Location $tmp
    try {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Export-GroupArchitecture.ps1')
        $datei = Join-Path $tmp 'ist-architektur-gruppen.md'
        Assert-True (Test-Path -LiteralPath $datei) 'Datei wurde nicht geschrieben'
        $zeilen = @(Get-Content -LiteralPath $datei -Encoding UTF8)
        $erwartet = @('| Typ | Dynamisch | Anzahl |', '|---|---|---|',
            '| Microsoft 365 | False | 4 |', '| Microsoft 365 | True | 1 |',
            '| Sicherheitsgruppe | False | 1 |', '| Sicherheitsgruppe | True | 1 |',
            '| Verteiler | False | 1 |')
        Assert-Equal ($erwartet -join "`n") ($zeilen -join "`n")
        Assert-ReadOnlyScopes
    } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}

Complete-Tests
