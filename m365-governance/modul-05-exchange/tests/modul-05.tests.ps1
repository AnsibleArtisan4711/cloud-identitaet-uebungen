# modul-05.tests.ps1 - Offline-Tests für die Skripte aus Modul 05 (Exchange und Kommunikations-Governance).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-05-exchange/tests/modul-05.tests.ps1
# Exchange-Online- und Graph-Cmdlets sind simuliert (tools/Mock-ExchangeOnline.ps1, tools/Mock-MgGraph.ps1). Geprüft wird die Logik der Skripte.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-ExchangeOnline.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'exchange-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test {      # beide Simulationen aus derselben Beispieldatei laden
    Initialize-MockTenant $fixture
    Initialize-MockExchange $fixture
}
function Use-Arbeitsordner {
    param([scriptblock]$Block)
    $tmp = New-TestDirectory
    Push-Location $tmp
    try { & $Block $tmp } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
function Get-Postfach { param([string]$Adresse) $global:MockEXO.mailboxes | Where-Object { $_.address -eq $Adresse } }

Write-Host 'Listing 34: Export-MailboxInventory.ps1'
Test-Case 'exportiert 7 Postfächer (ohne das inaktive) mit Größe, Hold und Weiterleitung und warnt bei Weiterleitungen' {
    Start-Test
    Use-Arbeitsordner { param($tmp)
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Export-MailboxInventory.ps1')
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'Postfachinventar.csv'))
        Assert-Equal 7 $csv.Count
        $z = $csv | Where-Object { $_.Adresse -eq 'mitarbeiter.zwei@beispiel.example' }
        Assert-Equal '20480' $z.GroesseMB
        Assert-Equal 'True' $z.LitigationHold
        Assert-Equal 'smtp:privat@mail.example' $z.WeiterleitungExtern
        Assert-Equal 'Mailbox' $z.Typ.Substring($z.Typ.Length - 7) 'UserMailbox'.Substring(4)
        Assert-Equal '1500' ($csv | Where-Object { $_.Adresse -eq 'mitarbeiter.eins@beispiel.example' }).GroesseMB
        Assert-Equal '' ($csv | Where-Object { $_.Adresse -eq 'mitarbeiter.fuenf@beispiel.example' }).GroesseMB 'ohne Statistik: leer'
        Assert-Equal 0 $r.Errors.Count 'fehlende Statistik erzeugt keinen Fehler'
        Assert-Match $r.OutputText '7 Postfaecher exportiert nach \.\\Postfachinventar\.csv'
        Assert-Equal 1 $r.Warnings.Count
        Assert-Match $r.Warnings[0] '^3 Postfaecher mit Weiterleitung an eine SMTP-Adresse:'
        Assert-Match $r.OutputText 'smtp:privat@mail\.example'
        Assert-NotMatch $r.OutputText 'ehemalig@' 'inaktives Postfach'
    }
}
Test-Case 'eigener Ausgabepfad über -Ausgabe; ohne Weiterleitungen keine Warnung' {
    Start-Test
    foreach ($a in 'mitarbeiter.zwei@beispiel.example','mitarbeiter.drei@beispiel.example','mitarbeiter.vier@beispiel.example') { (Get-Postfach $a).forwardingSmtp = $null }
    Use-Arbeitsordner { param($tmp)
        $ziel = Join-Path $tmp 'bericht.csv'
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Export-MailboxInventory.ps1') @{ Ausgabe = $ziel }
        Assert-True (Test-Path -LiteralPath $ziel)
        Assert-Equal 0 $r.Warnings.Count
    }
}
Test-Case 'ohne Postfächer: Abbruch mit Meldung' {
    Start-Test
    $global:MockEXO.mailboxes = @()
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Export-MailboxInventory.ps1') | Out-Null } 'Keine Postfaecher gefunden'
}

Write-Host 'Listing 36: Test-DistributionGroups.ps1'
Test-Case 'meldet Besitzer, externe Absender, leere und verschachtelte Gruppen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-DistributionGroups.ps1')
    $t = $r.OutputText
    Assert-Match $t 'vertrieb-liste@beispiel\.example\s+2\s+kein Besitzer; externe Absender erlaubt'
    Assert-Match $t 'leer@beispiel\.example\s+0\s+keine Mitglieder'
    Assert-Match $t 'verschachtelt@beispiel\.example\s+3\s+verschachtelt \(1\)'
    Assert-NotMatch $t 'alle@beispiel\.example' 'Gruppe ohne Befund'
    Assert-Match $t '3 von 4 Verteilergruppen mit Befund\.'
    Assert-True ($t.IndexOf('leer@') -lt $t.IndexOf('verschachtelt@') -and $t.IndexOf('verschachtelt@') -lt $t.IndexOf('vertrieb-liste@')) 'nach Adresse sortiert'
}
Test-Case 'ohne Verteilergruppen: Hinweis und keine Auswertung' {
    Start-Test
    $global:MockEXO.distributionGroups = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-DistributionGroups.ps1')
    Assert-Match ($r.Info -join "`n") 'Keine Verteilergruppen gefunden\.'
    Assert-NotMatch $r.OutputText 'Verteilergruppen mit Befund'
}

Write-Host 'Listing 38: Set-GroupNamingPolicy.ps1'
Test-Case 'setzt Namensmuster und gesperrte Wörter in der vorhandenen Einstellung Group.Unified' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupNamingPolicy.ps1')
    Assert-Equal @('Directory.ReadWrite.All') @(Get-MockScopes)
    $u = @(Get-MockCall 'Update-MgBetaDirectorySetting')
    Assert-Equal 1 $u.Count
    Assert-Equal 'ds-1' $u[0].Parameter.Id
    $w = @{}; foreach ($v in $u[0].Parameter.Body.values) { $w[$v.name] = $v.value }
    Assert-Equal 'GRP_[GroupName]_[Department]' $w['PrefixSuffixNamingRequirement']
    Assert-Equal 'Payroll,CEO,Gehalt' $w['CustomBlockedWordsList']
    Assert-Equal 2 @($u[0].Parameter.Body.values).Count 'nur diese zwei Werte werden gesendet'
    Assert-Match $r.OutputText 'Aktuelle Werte:'
    Assert-NotMatch $r.OutputText 'EnableGroupCreation' 'es werden nur die zwei betroffenen Werte angezeigt'
}
Test-Case 'eigenes Muster und eigene Sperrliste über Parameter' {
    Start-Test
    Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupNamingPolicy.ps1') @{ Muster = 'TEAM-[GroupName]'; Gesperrt = 'Geheim' } | Out-Null
    $w = @{}; foreach ($v in @(Get-MockCall 'Update-MgBetaDirectorySetting')[0].Parameter.Body.values) { $w[$v.name] = $v.value }
    Assert-Equal 'TEAM-[GroupName]' $w['PrefixSuffixNamingRequirement']
    Assert-Equal 'Geheim' $w['CustomBlockedWordsList']
}
Test-Case 'Muster ohne [GroupName]: Abbruch, nichts wird geändert' {
    Start-Test
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupNamingPolicy.ps1') @{ Muster = 'GRP_[Department]' } | Out-Null } 'muss \[GroupName\] enthalten'
    Assert-Equal 0 @(Get-MockCall 'Update-MgBetaDirectorySetting').Count
}
Test-Case 'ohne Einstellung Group.Unified: Abbruch mit Hinweis' {
    Start-Test
    $global:MockTenant.directorySettings = @()
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Set-GroupNamingPolicy.ps1') | Out-Null } "Keine Einstellung 'Group.Unified' vorhanden"
    Assert-Equal 0 @(Get-MockCall 'Update-MgBetaDirectorySetting').Count
}

Write-Host 'Listing 40: New-ImpersonationWarningRule.ps1'
Test-Case 'legt die Warnregel im Testmodus (AuditAndNotify) mit höchster Priorität an' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-ImpersonationWarningRule.ps1')
    $p = @(Get-MockCall 'New-TransportRule')[0].Parameter
    Assert-Equal 'Warnung: Absender imitiert Geschaeftsleitung' $p.Name
    Assert-Equal 'NotInOrganization' $p.FromScope
    Assert-Equal 'From' $p.HeaderMatchesMessageHeader
    Assert-Equal @('Erika Mustermann','Max Beispiel') @($p.HeaderMatchesPatterns)
    Assert-Equal '[EXTERN] ' $p.PrependSubject
    Assert-Equal 'High' $p.SetAuditSeverity
    Assert-Equal 'AuditAndNotify' $p.Mode
    Assert-Equal 0 $p.Priority
    Assert-Match $p.Comments 'Testmodus'
    Assert-Match $r.OutputText 'Mode\s+:\s+AuditAndNotify'
    Assert-Match $r.OutputText 'Priority\s+:\s+0'
}
Test-Case 'existiert die Regel schon, wird nichts angelegt' {
    Start-Test
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'New-ImpersonationWarningRule.ps1') @{ Name = 'Bestehende Regel' } | Out-Null } "Regel 'Bestehende Regel' existiert bereits"
    Assert-Equal 0 @(Get-MockCall 'New-TransportRule').Count
}

Write-Host 'Listing 42: New-SharedMailboxGoverned.ps1'
Test-Case 'legt ein freigegebenes Postfach an, vergibt Rechte an die Gruppe und sperrt die Anmeldung' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-SharedMailboxGoverned.ps1') @{ Name = 'Projekt X'; Adresse = 'projekt-x@beispiel.example'; Berechtigtengruppe = 'GRP-Projekt-X' }
    $n = @(Get-MockCall 'New-Mailbox')[0].Parameter
    Assert-Equal $true $n.Shared
    Assert-Equal 'Projekt X' $n.Name
    Assert-Equal 'projekt-x@beispiel.example' $n.PrimarySmtpAddress
    $f = @(Get-MockCall 'Add-MailboxPermission')[0].Parameter
    Assert-Equal 'GRP-Projekt-X' $f.User
    Assert-Equal 'FullAccess' $f.AccessRights
    Assert-Equal $false $f.AutoMapping 'kein automatisches Einbinden'
    $s = @(Get-MockCall 'Add-RecipientPermission')[0].Parameter
    Assert-Equal 'GRP-Projekt-X' $s.Trustee
    Assert-Equal 'SendAs' $s.AccessRights
    Assert-Equal $false $s.Confirm
    $g = @(Get-MockCall 'Update-MgUser')[0].Parameter
    Assert-Equal 'projekt-x@beispiel.example' $g.UserId
    Assert-Equal $false $g.AccountEnabled
    $namen = @($global:MockCalls | ForEach-Object { $_.Name })
    Assert-True ($namen.IndexOf('New-Mailbox') -lt $namen.IndexOf('Add-MailboxPermission')) 'erst anlegen, dann berechtigen'
    Assert-Equal @('User.ReadWrite.All') @(Get-MockScopes)
    Assert-Match $r.OutputText 'GRP-Projekt-X\s+\{?FullAccess\}?\s+False'
    Assert-NotMatch $r.OutputText 'NT AUTHORITY' 'Selbstberechtigung wird ausgeblendet'
}
Test-Case 'alle drei Parameter sind Pflicht' {
    $cmd = Get-Command (Join-Path $skripte 'New-SharedMailboxGoverned.ps1')
    foreach ($p in 'Name','Adresse','Berechtigtengruppe') { Assert-True $cmd.Parameters[$p].Attributes.Mandatory "$p ist nicht Pflicht" }
}

Write-Host 'Listing 44: Get-MailRetentionOverview.ps1'
Test-Case 'listet Abweichungen bei der Aufbewahrung, Litigation Hold und inaktive Postfächer in getrennten Abschnitten' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MailRetentionOverview.ps1')
    $t = $r.OutputText
    $a = $t.IndexOf('== Aufbewahrung'); $b = $t.IndexOf('== Postfaecher mit Litigation Hold'); $c = $t.IndexOf('== Inaktive Postfaecher')
    Assert-True ($a -ge 0 -and $b -gt $a -and $c -gt $b) 'drei Abschnitte in der richtigen Reihenfolge'
    $abschnitt1 = $t.Substring($a, $b - $a); $abschnitt2 = $t.Substring($b, $c - $b); $abschnitt3 = $t.Substring($c)
    Assert-Match $abschnitt1 'mitarbeiter\.drei@beispiel\.example\s+30\.00:00:00'
    Assert-NotMatch $abschnitt1 'mitarbeiter\.eins@' 'Standard 14 Tage'
    Assert-Match $abschnitt2 'mitarbeiter\.zwei@beispiel\.example\s+2555\.00:00:00'
    Assert-NotMatch $abschnitt2 'mitarbeiter\.eins@'
    Assert-Match $abschnitt3 'Ehemaliger Mitarbeiter\s+ehemalig@beispiel\.example'
    Assert-NotMatch $abschnitt3 'mitarbeiter\.'
    Assert-Equal 'LitigationHoldEnabled -eq $true' @(Get-MockCall 'Get-Mailbox')[1].Parameter.Filter
}

Write-Host 'Listing 46: Set-ExternalSenderControls.ps1'
Test-Case 'schaltet die Kennzeichnung externer Absender ein, trägt die Partnerdomäne ein und prüft SPF und DMARC eigener Domänen' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-ExternalSenderControls.ps1')
    $s = @(Get-MockCall 'Set-ExternalInOutlook')
    Assert-Equal 2 $s.Count
    Assert-Equal $true $s[0].Parameter.Enabled
    Assert-Equal 'partner.example.com' $s[1].Parameter.AllowList.Add
    $z = @($r.Output | Where-Object { $_.PSObject.Properties.Name -contains 'SPF' })
    Assert-Equal 2 $z.Count 'nur Domänen vom Typ Authoritative'
    $a = $z | Where-Object { $_.Domain -eq 'beispiel.example' }
    Assert-Equal $true $a.SPF; Assert-Equal $true $a.DMARC
    $b = $z | Where-Object { $_.Domain -eq 'alias.example' }
    Assert-Equal $true $b.SPF; Assert-Equal $false $b.DMARC 'kein DMARC-Eintrag'
    $namen = @(Get-MockCall 'Resolve-DnsName' | ForEach-Object { $_.Parameter.Name })
    Assert-Equal 4 $namen.Count
    foreach ($erwartet in 'alias.example','beispiel.example','_dmarc.alias.example','_dmarc.beispiel.example') { Assert-True ($namen -contains $erwartet) "DNS-Abfrage fehlt: $erwartet" }
    Assert-True (-not ($namen -contains 'relay.example')) 'InternalRelay wird nicht geprüft'
}
Test-Case 'Domäne ohne DNS-Einträge: SPF und DMARC sind falsch, es gibt keinen Fehler' {
    Start-Test
    $global:MockEXO.dns = @()
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Set-ExternalSenderControls.ps1')
    $z = @($r.Output | Where-Object { $_.PSObject.Properties.Name -contains 'SPF' })
    Assert-Equal 2 $z.Count
    Assert-True (-not ($z | Where-Object { $_.SPF -or $_.DMARC }))
    Assert-Equal 0 $r.Errors.Count
}

Write-Host 'Listing 48: Trace-MailProblem.ps1'
Test-Case 'ohne Absender und Empfänger: Abbruch vor der Anmeldung' {
    Start-Test
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Trace-MailProblem.ps1') | Out-Null } 'Absender oder Empfaenger angeben'
    Assert-Equal 0 @(Get-MockCall 'Connect-ExchangeOnline').Count
}
Test-Case 'zeigt Nachrichten der letzten 2 Tage und Details nur für nicht zugestellte' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Trace-MailProblem.ps1') @{ Absender = 'kunde@fabrikam.example' }
    $t = $r.OutputText
    Assert-Match $t 'Angebot'; Assert-Match $t 'Rechnung'
    Assert-NotMatch $t 'Altes Angebot' 'liegt 5 Tage zurück'
    Assert-NotMatch $t 'Anderes' 'anderer Absender'
    Assert-Match $t '--- Details: Rechnung \(Failed\)'
    Assert-Match $t 'Fail\s+Zustellung abgelehnt \(Beispieltext\)'
    Assert-NotMatch $t '--- Details: Angebot' 'zugestellte Nachricht ohne Details'
    Assert-Equal 1 @(Get-MockCall 'Get-MessageTraceDetail').Count
    $p = @(Get-MockCall 'Get-MessageTrace')[0].Parameter
    Assert-Equal 'kunde@fabrikam.example' $p.SenderAddress
    Assert-Equal '' $p.RecipientAddress
    Assert-True ((($p.EndDate - $p.StartDate).TotalDays) -gt 1.99 -and (($p.EndDate - $p.StartDate).TotalDays) -lt 2.01) 'Zeitraum 2 Tage'
}
Test-Case 'Parameter -Tage 7 bezieht die ältere Nachricht ein' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Trace-MailProblem.ps1') @{ Absender = 'kunde@fabrikam.example'; Tage = 7 }
    Assert-Match $r.OutputText 'Altes Angebot'
    Assert-Match $r.OutputText '--- Details: Altes Angebot \(Quarantined\)'
}
Test-Case 'Suche nach Empfänger; keine Treffer ergeben einen Hinweis' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Trace-MailProblem.ps1') @{ Empfaenger = 'mitarbeiter.zwei@beispiel.example' }
    Assert-Match $r.OutputText 'Anderes'
    $r2 = Invoke-ScriptUnderTest (Join-Path $skripte 'Trace-MailProblem.ps1') @{ Empfaenger = 'niemand@beispiel.example' }
    Assert-Match ($r2.Info -join "`n") 'Keine Nachrichten im Zeitraum gefunden\.'
}

Write-Host 'Aufgabe 5: Weiterleitungen an externe Domänen'
Test-Case 'nennt nur Weiterleitungen außerhalb der eigenen Domänen, Ziel in Kleinbuchstaben ohne smtp:' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-05-weiterleitungen-extern.ps1')
    $o = @($r.Output)
    Assert-Equal 2 $o.Count 'alias.example gehört zu den eigenen Domänen'
    Assert-Equal 'privat@mail.example' ($o | Where-Object { $_.Postfach -eq 'mitarbeiter.zwei@beispiel.example' }).Ziel
    Assert-Equal 'extern@partner.example' ($o | Where-Object { $_.Postfach -eq 'mitarbeiter.vier@beispiel.example' }).Ziel
}

Write-Host 'Aufgabe 7: direkt berechtigte Personen an freigegebenen Postfächern'
Test-Case 'findet Einzelpersonen, ignoriert Gruppen, Vererbtes, Verweigerungen und die Selbstberechtigung' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-gemeinsame-postfaecher-direkt.ps1')
    $o = @($r.Output)
    Assert-Equal 1 $o.Count 'Support hat nur eine Gruppe'
    Assert-Equal 'vertrieb@beispiel.example' $o[0].Postfach
    Assert-Equal 'mitarbeiter.eins@beispiel.example' $o[0].DirektBerechtigt
    Assert-Equal @('SharedMailbox') @(Get-MockCall 'Get-Mailbox')[0].Parameter.RecipientTypeDetails
}
Test-Case 'mehrere Einzelpersonen werden mit Semikolon verbunden' {
    Start-Test
    (Get-Postfach 'vertrieb@beispiel.example').permissions += [pscustomobject]@{ user = 'admin.drei@beispiel.example'; rights = @('FullAccess'); inherited = $false; deny = $false }
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-gemeinsame-postfaecher-direkt.ps1')
    Assert-Equal 'mitarbeiter.eins@beispiel.example; admin.drei@beispiel.example' @($r.Output)[0].DirektBerechtigt
}

Complete-Tests
