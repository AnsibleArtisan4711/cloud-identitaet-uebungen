# modul-04.tests.ps1 - Offline-Tests für die Skripte aus Modul 04 (SharePoint und OneDrive Governance).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-04-sharepoint-onedrive/tests/modul-04.tests.ps1
# Die SharePoint-Cmdlets sind simuliert (tools/Mock-SharePoint.ps1). Geprüft wird die Logik der Skripte, nicht SharePoint Online.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')      # stellt Add-MockCall / Get-MockCall bereit
. (Join-Path (Join-Path $repo 'tools') 'Mock-SharePoint.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'sharepoint-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Get-Website { param([string]$Slug) $global:MockSPO.sites | Where-Object { $_.url -like "*/$Slug" } }
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
$hub = 'https://contoso.sharepoint.com/sites/HUB-Projekte'

Write-Host 'Listing 26: New-GovernedSite.ps1'
Test-Case 'legt die Website an und schaltet danach die externe Freigabe ab' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-GovernedSite.ps1') @{ Tenant = 'contoso'; Name = 'PRJ-Neu'; Titel = 'Neues Projekt'; Besitzer = 'mitarbeiter.eins@example.com' }
    Assert-Equal 'https://contoso-admin.sharepoint.com' (Get-MockCall 'Connect-SPOService')[0].Parameter.Url
    $n = (Get-MockCall 'New-SPOSite')[0].Parameter
    Assert-Equal 'https://contoso.sharepoint.com/sites/PRJ-Neu' $n.Url
    Assert-Equal 'Neues Projekt' $n.Title
    Assert-Equal 'mitarbeiter.eins@example.com' $n.Owner
    Assert-Equal 'SITEPAGEPUBLISHING#0' $n.Template
    Assert-Equal 1024 $n.StorageQuota
    Assert-Equal $true $n.NoWait
    $s = (Get-MockCall 'Set-SPOSite')[0].Parameter
    Assert-Equal 'https://contoso.sharepoint.com/sites/PRJ-Neu' $s.Identity
    Assert-Equal 'Disabled' $s.SharingCapability
    $namen = @($global:MockCalls | ForEach-Object { $_.Name })
    Assert-Equal @('Connect-SPOService','Get-SPOSite','New-SPOSite','Start-Sleep','Set-SPOSite') $namen 'Reihenfolge: erst anlegen, dann warten, dann Freigabe abschalten'
    Assert-Equal 20 (Get-MockCall 'Start-Sleep')[0].Parameter.Seconds
    Assert-Equal 'Website angelegt (oder in Arbeit): https://contoso.sharepoint.com/sites/PRJ-Neu' $r.OutputText
}
Test-Case 'bricht ab, wenn die Website schon existiert, und ändert nichts' {
    Initialize-MockSharePoint $fixture
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'New-GovernedSite.ps1') @{ Tenant = 'contoso'; Name = 'PRJ-Messe'; Titel = 'x'; Besitzer = 'a@example.com' } | Out-Null } 'Website existiert bereits: https://contoso.sharepoint.com/sites/PRJ-Messe'
    Assert-Equal 0 @(Get-MockCall 'New-SPOSite').Count
    Assert-Equal 0 @(Get-MockCall 'Set-SPOSite').Count
}
Test-Case 'alle vier Parameter sind Pflicht' {
    $cmd = Get-Command (Join-Path $skripte 'New-GovernedSite.ps1')
    foreach ($p in 'Tenant','Name','Titel','Besitzer') { Assert-True $cmd.Parameters[$p].Attributes.Mandatory "$p ist nicht Pflicht" }
}

Write-Host 'Listing 27: New-HubStructure.ps1'
Test-Case 'registriert den Hub, benennt ihn und schließt alle vier PRJ-Websites an' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-HubStructure.ps1')
    Assert-Equal $hub (Get-MockCall 'Register-SPOHubSite')[0].Parameter.Site
    Assert-Equal 'Projekte' (Get-MockCall 'Set-SPOHubSite')[0].Parameter.Title
    $a = @(Get-MockCall 'Add-SPOHubSiteAssociation')
    Assert-Equal 4 $a.Count
    Assert-True (-not ($a | Where-Object { $_.Parameter.HubSite -ne $hub })) 'alle an denselben Hub'
    $urls = @($a | ForEach-Object { $_.Parameter.Site } | Sort-Object)
    Assert-Equal @('https://contoso.sharepoint.com/sites/PRJ-Alt-ReadOnly','https://contoso.sharepoint.com/sites/PRJ-Archiv-2019','https://contoso.sharepoint.com/sites/PRJ-Messe','https://contoso.sharepoint.com/sites/PRJ-Relaunch') $urls
    Assert-Match $r.OutputText 'Angeschlossen: https://contoso\.sharepoint\.com/sites/PRJ-Messe'
    Assert-Match $r.OutputText 'Projekte\s+https://contoso\.sharepoint\.com/sites/HUB-Projekte'
    Assert-NotMatch $r.OutputText 'Angeschlossen: .*ABT-'
}
Test-Case 'ist der Hub schon registriert, wird er nicht noch einmal registriert' {
    Initialize-MockSharePoint $fixture
    $global:MockSPO.hubs = @([pscustomobject]@{ title = 'Projekte'; siteUrl = $hub })
    Invoke-ScriptUnderTest (Join-Path $skripte 'New-HubStructure.ps1') | Out-Null
    Assert-Equal 0 @(Get-MockCall 'Register-SPOHubSite').Count
    Assert-Equal 0 @(Get-MockCall 'Set-SPOHubSite').Count
    Assert-Equal 4 @(Get-MockCall 'Add-SPOHubSiteAssociation').Count
}

Write-Host 'Listing 28: Get-SitePermissionReport.ps1'
Test-Case 'ordnet Einträge Gruppe, Einzelperson oder Gast zu und zeigt nur Einzelpersonen und Gäste im Detail' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SitePermissionReport.ps1') @{ SiteUrl = 'https://contoso.sharepoint.com/sites/PRJ-Messe' }
    $t = $r.OutputText
    Assert-Match $t 'Einzelperson\s+2'
    Assert-Match $t 'Gast\s+2'
    Assert-Match $t 'Gruppe\s+2'
    $detail = $t.Substring($t.IndexOf('SharePointGruppe'))
    Assert-Match $detail 'Messe-Besitzer\s+Full Control\s+mitarbeiter\.eins@example\.com\s+Einzelperson'
    Assert-Match $detail 'Messe-Besucher\s+Read, Limited Access\s+gast\.zwei_fabrikam\.example#ext#@beispiel\.onmicrosoft\.com\s+Gast'
    Assert-NotMatch $detail 'c:0t\.c\|tenant' 'Gruppeneinträge stehen nicht in der Detailtabelle'
    Assert-NotMatch $detail 'federateddirectoryclaimprovider'
    Assert-NotMatch $detail 'Messe-Leer' 'leere SharePoint-Gruppe erzeugt keine Zeile'
}
Test-Case 'unbekannte Website: Fehler wird gemeldet, es gibt keine Auswertung' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SitePermissionReport.ps1') @{ SiteUrl = 'https://contoso.sharepoint.com/sites/gibt-es-nicht' }
    Assert-True ($r.Errors.Count -ge 1) 'Fehler erwartet'
    Assert-Match $r.Errors[0] 'Website nicht gefunden'
}

Write-Host 'Listing 29: Set-SharingBaseline.ps1'
Test-Case 'setzt die Tenant-Freigabe mit Ablaufzeiten und zeigt die Verteilung der Websites' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-SharingBaseline.ps1')
    $p = (Get-MockCall 'Set-SPOTenant')[0].Parameter
    Assert-Equal 'ExternalUserSharingOnly' $p.SharingCapability
    Assert-Equal 'Direct' $p.DefaultSharingLinkType
    Assert-Equal 30 $p.RequireAnonymousLinksExpireInDays
    Assert-Equal $true $p.ExternalUserExpirationRequired
    Assert-Equal 60 $p.ExternalUserExpireInDays
    Assert-Match $r.OutputText 'Tenant-Freigabe: ExternalUserSharingOnly'
    $t = $r.OutputText
    Assert-Match $t 'Disabled\s+5'
    Assert-Match $t 'ExternalUserSharingOnly\s+3'
    Assert-Match $t 'ExternalUserAndGuestSharing\s+2'
    Assert-Match $t 'ExistingExternalUserSharingOnly\s+1'
    Assert-Equal 1 @(Get-MockCall 'Set-SPOTenant').Count
}

Write-Host 'Listing 30: Set-SiteLabels.ps1'
$label = '33333333-3333-3333-3333-333333333333'
Test-Case 'Probelauf: nennt die unbeschrifteten PRJ-Websites, ändert nichts' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-SiteLabels.ps1') @{ LabelId = $label }
    Assert-Match $r.OutputText '9 von 11 Websites ohne Label\.'
    foreach ($n in 'PRJ-Relaunch','PRJ-Archiv-2019','PRJ-Alt-ReadOnly') { Assert-Match $r.OutputText "PROBELAUF: https://contoso\.sharepoint\.com/sites/$n" }
    Assert-NotMatch $r.OutputText 'PRJ-Messe' 'hat bereits ein Label'
    Assert-NotMatch $r.OutputText 'ABT-' 'anderes Präfix'
    Assert-Equal 0 @(Get-MockCall 'Set-SPOSite').Count
}
Test-Case 'mit -Ausfuehren wird das Label gesetzt' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-SiteLabels.ps1') @{ LabelId = $label; Ausfuehren = $true }
    $s = @(Get-MockCall 'Set-SPOSite')
    Assert-Equal 3 $s.Count
    Assert-True (-not ($s | Where-Object { $_.Parameter.SensitivityLabel -ne $label }))
    Assert-Match $r.OutputText 'Label gesetzt: https://contoso\.sharepoint\.com/sites/PRJ-Relaunch'
    Assert-NotMatch $r.OutputText 'PROBELAUF'
}
Test-Case 'anderes Präfix über UrlPrefix' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-SiteLabels.ps1') @{ LabelId = $label; UrlPrefix = '/sites/ABT-' }
    $treffer = @([regex]::Matches($r.OutputText, 'PROBELAUF: \S+/sites/(\S+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object)
    Assert-Equal @('ABT-Marketing','ABT-Personal-Intranet','ABT-Vertrieb','ABT-Voll') $treffer 'ABT-Finanzen hat schon ein Label, PRJ-Websites passen nicht zum Präfix'
}
Test-Case 'LabelId ist Pflicht' {
    Assert-True (Get-Command (Join-Path $skripte 'Set-SiteLabels.ps1')).Parameters['LabelId'].Attributes.Mandatory
}

Write-Host 'Listing 31: Get-StorageReport.ps1'
Test-Case 'Bericht: CSV mit allen Websites, Auslastung korrekt, Liste über 80 Prozent ohne Grenzfälle' {
    Initialize-MockSharePoint $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-StorageReport.ps1')
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'speicher-bericht.csv'))
        Assert-Equal 11 $csv.Count 'persönliche Website zählt nicht'
        $m = $csv | Where-Object { $_.Url -like '*PRJ-Messe' }
        Assert-Match $m.GenutztGB '^0[.,]93$'
        Assert-Match $m.QuoteGB '^1([.,]0+)?$'
        Assert-Match $m.Auslastung '^92[.,]8$'
        Assert-Equal '' ($csv | Where-Object { $_.Url -like '*KND-Fabrikam' }).Auslastung 'Quote 0: keine Division durch null'
        $ab = $r.OutputText.Substring($r.OutputText.IndexOf('ueber 80 Prozent'))
        foreach ($n in 'ABT-Voll','PRJ-Messe','ABT-Personal-Intranet','PRJ-Relaunch') { Assert-Match $ab $n }
        Assert-NotMatch $ab 'ABT-Finanzen' 'genau 80.0 Prozent ist nicht über 80'
        Assert-NotMatch $ab 'KND-Fabrikam'
        Assert-Equal 4 ([regex]::Matches($ab, 'https://contoso\.sharepoint\.com/sites/').Count)
    }
}
Test-Case 'Rangliste: größter Verbrauch zuerst' {
    Initialize-MockSharePoint $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-StorageReport.ps1')
        $oben = $r.OutputText.Substring(0, $r.OutputText.IndexOf('ueber 80 Prozent'))
        Assert-True ($oben.IndexOf('PRJ-Relaunch') -lt $oben.IndexOf('ABT-Voll')) '4,2 GB vor 2 GB'
        Assert-True ($oben.IndexOf('ABT-Voll') -lt $oben.IndexOf('ABT-Vertrieb')) '1,95 GB vor 0,98 GB'
    }
}

Write-Host 'Listing 32: Find-InactiveSites.ps1'
Test-Case 'findet Websites ohne Änderung seit 365 Tagen (nur entsperrte), schreibt die CSV und sperrt nichts' {
    Initialize-MockSharePoint $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Find-InactiveSites.ps1')
        Assert-Match $r.OutputText '2 Websites ohne Aenderung seit 365 Tagen\.'
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'inaktive-websites.csv'))
        Assert-Equal 2 $csv.Count
        Assert-Match $csv[0].Url 'PRJ-Archiv-2019$' 'älteste zuerst'
        Assert-Match $csv[1].Url 'ABT-Vertrieb$'
        Assert-NotMatch ($csv.Url -join ' ') 'ReadOnly' 'schon gesperrte Website nicht erneut'
        Assert-NotMatch ($csv.Url -join ' ') 'ABT-Marketing' '364 Tage: noch nicht inaktiv'
        Assert-NotMatch ($csv.Url -join ' ') 'personal' 'persönliche Websites sind ausgeschlossen'
        Assert-Equal 0 @(Get-MockCall 'Set-SPOSite').Count
    }
}
Test-Case 'mit -SchreibschutzSetzen werden genau diese Websites auf ReadOnly gesetzt' {
    Initialize-MockSharePoint $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Find-InactiveSites.ps1') @{ SchreibschutzSetzen = $true }
        $s = @(Get-MockCall 'Set-SPOSite')
        Assert-Equal 2 $s.Count
        Assert-True (-not ($s | Where-Object { $_.Parameter.LockState -ne 'ReadOnly' }))
        Assert-Match $r.OutputText 'Schreibgeschuetzt: https://contoso\.sharepoint\.com/sites/PRJ-Archiv-2019'
    }
}
Test-Case 'Parameter Tage verschiebt die Grenze' {
    Initialize-MockSharePoint $fixture
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Find-InactiveSites.ps1') @{ Tage = 25 }
        Assert-Match $r.OutputText '4 Websites ohne Aenderung seit 25 Tagen\.'
    }
}

Write-Host 'Listing 33: Get-SiteHealth.ps1'
Test-Case 'zeigt Zustand einer Website und ihre SharePoint-Gruppen mit Mitgliederzahl' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SiteHealth.ps1') @{ SiteUrl = 'https://contoso.sharepoint.com/sites/PRJ-Messe' }
    $t = $r.OutputText
    Assert-Match $t 'Titel\s+: Projekt Messe'
    Assert-Match $t 'Vorlage\s+: SITEPAGEPUBLISHING#0'
    Assert-Match $t 'Sperrstatus\s+: Unlock'
    Assert-Match $t 'Freigabe\s+: ExternalUserSharingOnly'
    Assert-Match $t 'Label\s+: 11111111-1111-1111-1111-111111111111'
    Assert-Match $t 'GenutztGB\s+: 0[.,]93'
    Assert-Match $t 'QuoteGB\s+: 1([.,]0+)?\s'
    Assert-Match $t 'Messe-Mitglieder\s+Edit\s+3'
    Assert-Match $t 'Messe-Besucher\s+Read, Limited Access\s+1'
    Assert-Match $t 'Messe-Leer\s+Read\s+0'
    Assert-True (Get-MockCall 'Get-SPOSite')[0].Parameter.Detailed 'Detailed wird verwendet'
}
Test-Case 'Website ohne Label zeigt eine leere Angabe' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SiteHealth.ps1') @{ SiteUrl = 'https://contoso.sharepoint.com/sites/PRJ-Relaunch' }
    Assert-Match $r.OutputText 'Label\s+:\s*\n'
}

Write-Host 'Aufgabe 6: Websites über 90 Prozent Speicherauslastung'
Test-Case 'nennt Websites knapp über 90 Prozent, nicht genau 90 und nicht Websites ohne Quote' {
    Initialize-MockSharePoint $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-06-speicher-ueber-90-prozent.ps1')
    $t = $r.OutputText
    Assert-Match $t 'ABT-Voll'
    Assert-Match $t 'PRJ-Messe'
    Assert-NotMatch $t 'ABT-Personal-Intranet' 'genau 90 Prozent ist nicht über 90'
    Assert-NotMatch $t 'PRJ-Relaunch'
    Assert-NotMatch $t 'KND-Fabrikam' 'Quote 0'
    Assert-True ($t.IndexOf('ABT-Voll') -lt $t.IndexOf('PRJ-Messe')) 'engster Fall zuerst (0,05 GB vor 0,07 GB frei)'
    Assert-Match $t 'ABT-Voll\s+\S+\s+0[.,]05'
    Assert-Match $t 'PRJ-Messe\s+\S+\s+0[.,]07'
}

Complete-Tests
