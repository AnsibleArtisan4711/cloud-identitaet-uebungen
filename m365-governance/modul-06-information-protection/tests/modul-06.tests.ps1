# modul-06.tests.ps1 - Offline-Tests für die Skripte aus Modul 06 (Information Protection und Data Governance).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-06-information-protection/tests/modul-06.tests.ps1
# Die Purview- und SharePoint-Cmdlets sind simuliert (tools/Mock-Purview.ps1, tools/Mock-SharePoint.ps1). Geprüft wird die Logik der Skripte.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-SharePoint.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-Purview.ps1')
$fixtureP = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'purview-klein.json'
$fixtureS = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'sharepoint-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'
$istPs7 = $PSVersionTable.PSVersion.Major -ge 6

function Start-Test { Initialize-MockSharePoint $fixtureS; Initialize-MockPurview $fixtureP }
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
function Get-Aufruf { param([string]$Name) @(Get-MockCall $Name) }
function Get-Position {
    # Index des ersten/letzten Aufrufs mit diesem Namen in $global:MockCalls (-1, wenn nicht vorhanden)
    param([string]$Name, [switch]$Letzte)
    $pos = -1; $i = 0
    foreach ($c in $global:MockCalls) { if ($c.Name -eq $Name -and ($Letzte -or $pos -lt 0)) { $pos = $i }; $i++ }
    $pos
}
function Invoke-MitFehler {
    # Bindungsfehler (unbekannter Parameter, Parametersatz) beenden das Skript mit einer Ausnahme; sie wird hier eingesammelt.
    param([string]$Pfad)
    try { Invoke-ScriptUnderTest $Pfad | Out-Null; '' } catch { $_.Exception.Message }
}

Write-Host 'Listing 50: New-LabelStructure.ps1'
Test-Case 'legt zwei Labels mit Fußzeile und eine Labelrichtlinie an, Herabstufen nur mit Begründung' {
    Start-Test
    $global:MockPurview.labels = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-LabelStructure.ps1')
    $l = @(Get-Aufruf 'New-Label')
    Assert-Equal 2 $l.Count
    Assert-Equal @('Intern','Vertraulich') @($l | ForEach-Object { $_.Parameter.Name })
    foreach ($x in $l) {
        Assert-Equal 'File, Email' $x.Parameter.ContentType
        Assert-Equal $true $x.Parameter.ApplyContentMarkingFooterEnabled
        Assert-Equal $x.Parameter.Name $x.Parameter.ApplyContentMarkingFooterText 'Fußzeile = Labelname'
        Assert-Equal 9 $x.Parameter.ApplyContentMarkingFooterFontSize
    }
    $p = (Get-Aufruf 'New-LabelPolicy')[0].Parameter
    Assert-Equal 'Standard-Labelrichtlinie' $p.Name
    Assert-Equal @('Intern','Vertraulich') @($p.Labels)
    Assert-Equal 'All' (@($p.ExchangeLocation))[0]
    Assert-Equal 'true' $p.AdvancedSettings['requiredowngradejustification']
    Assert-True ((Get-Position 'New-Label' -Letzte) -lt (Get-Position 'New-LabelPolicy')) 'erst Labels, dann Richtlinie'
    Assert-Match $r.OutputText 'Intern\s+0\s+File, Email'
    Assert-Match $r.OutputText 'Vertraulich\s+1\s+File, Email'
}
Test-Case 'Hinweis: ein zweiter Lauf erzeugt Fehler, weil die Labels schon existieren (nicht wiederholbar)' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-LabelStructure.ps1')
    Assert-Equal 2 $r.Errors.Count
    Assert-Match $r.Errors[0] "Label 'Intern' existiert bereits"
}

Write-Host 'Listing 52: New-DlpPolicy.ps1'
Test-Case 'legt die Richtlinie im Testmodus mit zwei Regeln an' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-DlpPolicy.ps1')
    $p = (Get-Aufruf 'New-DlpCompliancePolicy')[0].Parameter
    Assert-Equal 'DLP Finanzdaten' $p.Name
    Assert-Equal 'TestWithNotifications' $p.Mode
    foreach ($ort in 'ExchangeLocation','SharePointLocation','OneDriveLocation') { Assert-Equal 'All' (@($p[$ort]))[0] "$ort" }
    $regeln = @(Get-Aufruf 'New-DlpComplianceRule')
    Assert-Equal 2 $regeln.Count
    $k = $regeln[0].Parameter
    Assert-Equal 'Kreditkarte extern blockieren' $k.Name
    Assert-Equal 'DLP Finanzdaten' $k.Policy
    Assert-Equal 'Credit Card Number' $k.ContentContainsSensitiveInformation.Name
    Assert-Equal '1' $k.ContentContainsSensitiveInformation.minCount
    Assert-Equal 'NotInOrganization' $k.AccessScope
    Assert-Equal $true $k.BlockAccess
    Assert-Equal 'Owner' $k.NotifyUser
    Assert-Equal 'SiteAdmin' $k.GenerateAlert
    $i = $regeln[1].Parameter
    Assert-Equal 'International Banking Account Number (IBAN)' $i.ContentContainsSensitiveInformation.Name
    Assert-Equal '5' $i.ContentContainsSensitiveInformation.minCount
    Assert-True (-not $i.ContainsKey('BlockAccess')) 'IBAN-Regel blockiert nicht'
    Assert-Equal 'SiteAdmin' $i.GenerateIncidentReport
    Assert-Equal 0 $r.Errors.Count
    Assert-Match $r.OutputText 'DLP Finanzdaten\s+TestWithNotifications\s+Pending'
}

Write-Host 'Listing 54: New-RetentionPolicy.ps1 (laut Dokumentation vermutlich nicht lauffähig)'
Test-Case 'Hinweis: die dokumentierte Parameterliste kennt -TeamsChatLocation nicht, die Simulation lehnt den Aufruf ab' {
    Start-Test
    $fehler = Invoke-MitFehler (Join-Path $skripte 'New-RetentionPolicy.ps1')
    Assert-Match $fehler 'TeamsChatLocation'
    Assert-Equal 0 (@(Get-Aufruf 'New-RetentionCompliancePolicy').Count) 'Richtlinie wurde nicht angelegt'
}

Write-Host 'Listing 56: New-RecordLabel.ps1'
Test-Case 'legt ein Record-Label mit 3650 Tagen an und veröffentlicht es über eine Richtlinie für SharePoint' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-RecordLabel.ps1')
    $t = (Get-Aufruf 'New-ComplianceTag')[0].Parameter
    Assert-Equal 'Vertrag 10 Jahre' $t.Name
    Assert-Equal $true $t.IsRecordLabel
    Assert-Equal $false $t.Regulatory 'kein regulatorisches Label'
    Assert-Equal 'KeepAndDelete' $t.RetentionAction
    Assert-Equal 3650 $t.RetentionDuration
    Assert-Equal 'CreationAgeInDays' $t.RetentionType
    $p = (Get-Aufruf 'New-RetentionCompliancePolicy')[0].Parameter
    Assert-Equal 'Veroeffentlichung Vertragslabel' $p.Name
    Assert-Equal 'All' (@($p.SharePointLocation))[0]
    Assert-Equal $true $p.Enabled
    $regel = (Get-Aufruf 'New-RetentionComplianceRule')[0].Parameter
    Assert-Equal 'Veroeffentlichung Vertragslabel' $regel.Policy
    Assert-Equal 'Vertrag 10 Jahre' $regel.PublishComplianceTag
    Assert-Equal 0 $r.Errors.Count
    Assert-Match $r.OutputText 'Vertrag 10 Jahre\s+True\s+False\s+3650'
}

Write-Host 'Listing 58: New-AdaptiveRetention.ps1 (laut Dokumentation vermutlich nicht lauffähig)'
Test-Case 'Hinweis: adaptiver Bereich und -ExchangeLocation liegen in verschiedenen Parametersätzen, die Simulation lehnt den Aufruf ab' {
    Start-Test
    $fehler = Invoke-MitFehler (Join-Path $skripte 'New-AdaptiveRetention.ps1')
    $scope = (Get-Aufruf 'New-AdaptiveScope')[0].Parameter
    Assert-Equal 'Abteilung Personal' $scope.Name
    Assert-Equal 'User' $scope.LocationType
    Assert-Equal "Department -eq 'Personal'" $scope.RawQuery
    Assert-Match $fehler 'Parameter set cannot be resolved|ParameterSet|Parametersatz'
    Assert-Equal 0 (@(Get-Aufruf 'New-RetentionCompliancePolicy').Count)
}

Write-Host 'Listing 60: New-InformationBarrier.ps1'
Test-Case 'legt Segmente und zwei inaktive Richtlinien an, aktiviert dann ALLE vorhandenen und startet die Anwendung' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-InformationBarrier.ps1')
    $s = @(Get-Aufruf 'New-OrganizationSegment')
    Assert-Equal @('Handel','Beratung') @($s | ForEach-Object { $_.Parameter.Name })
    Assert-Equal "Department -eq 'Handel'" $s[0].Parameter.UserGroupFilter
    Assert-Equal "Department -eq 'Beratung'" $s[1].Parameter.UserGroupFilter
    $p = @(Get-Aufruf 'New-InformationBarrierPolicy')
    Assert-Equal 2 $p.Count
    Assert-Equal 'Handel' $p[0].Parameter.AssignedSegment; Assert-Equal 'Beratung' $p[0].Parameter.SegmentsBlocked
    Assert-Equal 'Beratung' $p[1].Parameter.AssignedSegment; Assert-Equal 'Handel' $p[1].Parameter.SegmentsBlocked
    Assert-Equal 'Inactive' $p[0].Parameter.State 'bei der Anlage inaktiv'
    $a = @(Get-Aufruf 'Set-InformationBarrierPolicy')
    Assert-Equal 3 $a.Count 'auch die schon vorhandene Richtlinie "ib-bestand" wird aktiviert'
    Assert-True (-not ($a | Where-Object { $_.Parameter.State -ne 'Active' }))
    Assert-True (@($a | ForEach-Object { $_.Parameter.Identity }) -contains 'ib-bestand')
    Assert-True ((Get-Position 'Start-InformationBarrierPoliciesApplication') -gt (Get-Position 'Set-InformationBarrierPolicy' -Letzte)) 'Anwendung startet nach der Aktivierung'
    Assert-Equal 1 (@(Get-Aufruf 'Get-InformationBarrierPoliciesApplicationStatus').Count)
}

Write-Host 'Listing 62: Export-SiteInventory.ps1'
Test-Case 'schreibt das Standortinventar mit Labelnamen, sortiert nach Größe' {
    Start-Test
    Use-Arbeitsordner { param($tmp)
        Invoke-ScriptUnderTest (Join-Path $skripte 'Export-SiteInventory.ps1') @{ Tenant = 'contoso' } | Out-Null
        Assert-Equal 'https://contoso-admin.sharepoint.com' (Get-Aufruf 'Connect-SPOService')[0].Parameter.Url
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'Standortinventar.csv'))
        Assert-Equal 11 $csv.Count 'persönliche Website zählt nicht'
        Assert-Match $csv[0].Url 'PRJ-Relaunch$' 'größte zuerst (4,2 GB)'
        Assert-Equal 'Intern' ($csv | Where-Object { $_.Url -like '*PRJ-Messe' }).Label
        Assert-Equal 'Vertraulich' ($csv | Where-Object { $_.Url -like '*ABT-Finanzen' }).Label
        Assert-Equal '(kein Label)' ($csv | Where-Object { $_.Url -like '*ABT-Vertrieb' }).Label
        Assert-Equal 9 @($csv | Where-Object { $_.Label -eq '(kein Label)' }).Count
    }
}
Test-Case 'Label mit unbekannter ID ergibt eine leere Angabe (nicht "kein Label")' {
    Start-Test
    ($global:MockSPO.sites | Where-Object { $_.url -like '*ABT-Vertrieb' }).sensitivityLabel = '99999999-9999-9999-9999-999999999999'
    Use-Arbeitsordner { param($tmp)
        Invoke-ScriptUnderTest (Join-Path $skripte 'Export-SiteInventory.ps1') @{ Tenant = 'contoso' } | Out-Null
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'Standortinventar.csv'))
        Assert-Equal '' ($csv | Where-Object { $_.Url -like '*ABT-Vertrieb' }).Label
    }
}
Test-Case 'Parameter Tenant ist Pflicht' {
    Assert-True (Get-Command (Join-Path $skripte 'Export-SiteInventory.ps1')).Parameters['Tenant'].Attributes.Mandatory
}

Write-Host 'Listing 64: Test-PurviewDistribution.ps1'
Test-Case 'prüft DLP-, Aufbewahrungs- und Labelrichtlinien und nennt die drei auffälligen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PurviewDistribution.ps1')
    $t = $r.OutputText + "`n" + ($r.Info -join "`n")
    Assert-Match $t 'DLP\s+DLP Bestand B\s+TestWithNotifications\s+Pending'
    Assert-Match $t 'Aufbewahrung\s+Aufbewahrung E\s+Enabled\s+Error'
    Assert-Match $t 'Label\s+Labelrichtlinie G\s+-\s+Pending'
    Assert-NotMatch $t 'DLP Bestand A' 'Success wird nicht aufgelistet'
    Assert-NotMatch $t 'Aufbewahrung D' 'ausgeschaltet, aber Verteilung Success'
    Assert-Match $t 'Geprueft: 7 Richtlinien, davon auffaellig: 3'
}
Test-Case 'genau eine auffällige Richtlinie (unter Windows PowerShell 5.1 fehlt dort vermutlich die Zahl)' {
    Start-Test
    ($global:MockPurview.dlpPolicies | Where-Object { $_.name -eq 'DLP Bestand B' }).status = 'Success'
    ($global:MockPurview.retentionPolicies | Where-Object { $_.name -eq 'Aufbewahrung E' }).status = 'Success'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PurviewDistribution.ps1')
    $t = $r.OutputText + "`n" + ($r.Info -join "`n")
    if ($istPs7) { Assert-Match $t 'Geprueft: 7 Richtlinien, davon auffaellig: 1' }
    else { Assert-Match $t 'Geprueft: 7 Richtlinien, davon auffaellig:' 'Zahl hier nicht geprüft, siehe README' }
}
Test-Case 'alles in Ordnung: null auffällige Richtlinien' {
    Start-Test
    foreach ($l in 'dlpPolicies','retentionPolicies','labelPolicies') { foreach ($p in $global:MockPurview.$l) { $p.status = 'Success' } }
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-PurviewDistribution.ps1')
    Assert-Match ($r.OutputText + ($r.Info -join "`n")) 'Geprueft: 7 Richtlinien, davon auffaellig: 0'
}

Write-Host 'Aufgabe 5: DLP-Richtlinie für IBAN in Exchange im Testmodus'
Test-Case 'Richtlinie im Testmodus, Regel ab drei IBAN-Treffern' {
    Start-Test
    Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-05-dlp-iban-mail.ps1') | Out-Null
    $p = (Get-Aufruf 'New-DlpCompliancePolicy')[0].Parameter
    Assert-Equal 'DLP IBAN Mail' $p.Name
    Assert-Equal 'TestWithNotifications' $p.Mode
    Assert-Equal 'All' (@($p.ExchangeLocation))[0]
    Assert-True (-not $p.ContainsKey('SharePointLocation')) 'nur Exchange'
    $r = (Get-Aufruf 'New-DlpComplianceRule')[0].Parameter
    Assert-Equal 'DLP IBAN Mail' $r.Policy
    Assert-Equal '3' $r.ContentContainsSensitiveInformation.minCount
    Assert-Equal 'International Banking Account Number (IBAN)' $r.ContentContainsSensitiveInformation.Name
    Assert-Equal 'Owner' $r.NotifyUser
}

Write-Host 'Aufgabe 7: Aufbewahrungsrichtlinien, die nicht aktiv oder nicht verteilt sind'
Test-Case 'nennt ausgeschaltete und fehlerhaft verteilte Richtlinien' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-aufbewahrung-nicht-aktiv.ps1')
    Assert-Match $r.OutputText 'Aufbewahrung D \(aus\)\s+False\s+Success'
    Assert-Match $r.OutputText 'Aufbewahrung E\s+True\s+Error'
    Assert-NotMatch $r.OutputText 'Aufbewahrung C'
    Assert-Equal $true (Get-Aufruf 'Get-RetentionCompliancePolicy')[0].Parameter.DistributionDetail
}

Complete-Tests
