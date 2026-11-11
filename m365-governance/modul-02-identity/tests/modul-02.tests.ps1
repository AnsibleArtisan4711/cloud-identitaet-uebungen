# modul-02.tests.ps1 - Offline-Tests für die Skripte aus Modul 02 (Identity Governance).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-02-identity/tests/modul-02.tests.ps1
# Die Graph-Cmdlets sind simuliert (tools/Mock-MgGraph.ps1). Geprüft wird die Logik der Skripte, nicht das echte Microsoft Graph.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'identitaet-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Assert-ReadOnly {
    $schreibend = @(Get-MockScopes | Where-Object { $_ -match 'ReadWrite|\.Write' })
    Assert-Equal 0 $schreibend.Count "Schreibende Berechtigungen: $($schreibend -join ', ')"
}

function Get-Body { param([string]$Name) (Get-MockCall $Name)[0].Parameter.Body }

Write-Host 'Listing 16: Gast-Verwaltung.ps1'
Test-Case 'lädt ein, findet alte offene Einladungen (> 30 Tage) und Gäste ohne Anmeldung (> 90 Tage)' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Gast-Verwaltung.ps1')
    $einl = @(Get-MockCall 'New-MgInvitation')
    Assert-Equal 1 $einl.Count
    Assert-Equal 'partner@fabrikam.example' $einl[0].Parameter.Mail
    Assert-Equal $true $einl[0].Parameter.Mitteilung
    $offen = @($r.Output | Where-Object { $_.PSObject.Properties.Name -contains 'CreatedDateTime' })
    Assert-Equal 2 $offen.Count 'offen seit 60 und 40 Tagen, nicht die Einladungen von vor 25 und 10 Tagen'
    $inaktiv = @($r.Output | Where-Object { $_.PSObject.Properties.Name -contains 'LetzteAnmeldung' })
    Assert-Equal 7 $inaktiv.Count 'drei angenommene ohne neue Anmeldung (100, 200 Tage, nie) plus vier mit offener Einladung; Gast mit 75 Tagen zählt nicht'
    Assert-True (-not ($inaktiv | Where-Object { $_.DisplayName -eq 'Gast Aktiv' })) 'aktiver Gast (10 Tage) darf nicht auftauchen'
}

Write-Host 'Listing 15: Gruppen-Governance.ps1'
Test-Case 'legt Ablaufrichtlinie und dynamische Gruppe an und listet Gruppen mit zu wenigen Besitzern' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Gruppen-Governance.ps1')
    $p = (Get-MockCall 'New-MgGroupLifecyclePolicy')[0].Parameter
    Assert-Equal 365 $p.Tage
    Assert-Equal 'All' $p.Typen
    $g = (Get-MockCall 'New-MgGroup')[0].Parameter
    Assert-Equal 'GRP_Vertrieb_Alle' $g.Name
    Assert-True (@($g.Typen) -contains 'DynamicMembership') 'dynamische Mitgliedschaft'
    Assert-Match $g.Regel 'user\.department -eq "Vertrieb"'
    Assert-Match $g.Regel 'user\.accountEnabled -eq true' 'Leerzeichen vor true (Zeilenumbruch im Skript)'
    Assert-Equal 'On' $g.Verarbeitung
    Assert-Match $r.OutputText 'Richtlinie angelegt: richtlinie-1'
    Assert-Match $r.OutputText 'Gruppe angelegt: gruppe-neu-1'
    $t = $r.OutputText
    Assert-True ($t.IndexOf('Team Marketing') -lt $t.IndexOf('Projekt Alpha')) 'Besitzer 0 vor Besitzer 1'
    Assert-Match $t 'Team Finanzen'
    Assert-NotMatch $t 'Team Vertrieb\s+2' 'Gruppe mit 2 Besitzern darf nicht erscheinen'
}

Write-Host 'Listing 10: Get-GovernanceInventory.ps1'
Test-Case 'zählt Funktionen und meldet fehlende Lizenz als Hinweis statt abzubrechen' {
    Initialize-MockTenant $fixture
    $global:MockTenant.fehlendeLizenz = @('Lifecycle Workflows')
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-GovernanceInventory.ps1')
    Assert-Equal 0 $r.Errors.Count
    Assert-Match $r.OutputText 'Kataloge\s+2'
    Assert-Match $r.OutputText 'Zugriffspakete\s+3'
    Assert-Match $r.OutputText 'Lifecycle Workflows\s+keine Lizenz|Lifecycle Workflows\s+.*keine Lizenz'
    Assert-NotMatch $r.OutputText 'Zweite Zeile' 'nur die erste Zeile der Fehlermeldung'
}
Test-Case 'ohne Lizenzprobleme bleibt der Hinweis leer' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-GovernanceInventory.ps1')
    Assert-NotMatch $r.OutputText 'Lizenz'
    Assert-Match $r.OutputText 'Zugriffsueberpruefungen\s+1'
    Assert-Match $r.OutputText 'Lifecycle Workflows\s+0'
}

Write-Host 'Listing 17: Get-IdentitySupportReport.ps1'
Test-Case 'zeigt Anmeldungen mit Status und Verzeichnisänderungen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-IdentitySupportReport.ps1') @{ UserPrincipalName = 'mitarbeiter.eins@example.com' }
    Assert-Match $r.OutputText 'Microsoft Teams\s+OK'
    Assert-Match $r.OutputText 'Outlook\s+Fehler 50074\s+Strong Authentication required'
    Assert-Match $r.OutputText 'Reset password \(by admin\)\s+success\s+admin\.eins@example\.com'
    $f = (Get-MockCall 'Get-MgAuditLogSignIn')[0].Parameter
    Assert-Equal "userPrincipalName eq 'mitarbeiter.eins@example.com'" $f.Filter
    Assert-Equal 15 $f.Top
    Assert-Match ((Get-MockCall 'Get-MgAuditLogDirectoryAudit')[0].Parameter.Filter) "t/id eq 'u-m1'" 'Audit-Filter nutzt die Objekt-ID'
}
Test-Case 'Parameter UserPrincipalName ist Pflicht' {
    Initialize-MockTenant $fixture
    $cmd = Get-Command (Join-Path $skripte 'Get-IdentitySupportReport.ps1')
    Assert-True $cmd.Parameters['UserPrincipalName'].Attributes.Mandatory
}

Write-Host 'Listing 12: New-AccessPackagePolicy.ps1'
Test-Case 'legt die Richtlinie mit 180 Tagen und Genehmigung an und exportiert Zuweisungen' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory
    Push-Location $tmp
    try {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-AccessPackagePolicy.ps1')
        $b = Get-Body 'New-MgEntitlementManagementAssignmentPolicy'
        Assert-Equal 'allMemberUsers' $b.allowedTargetScope
        Assert-Equal 'P180D' $b.expiration.duration
        Assert-Equal $true $b.requestApprovalSettings.isApprovalRequiredForAdd
        Assert-Equal 'P7D' $b.requestApprovalSettings.stages[0].durationBeforeAutomaticDenial
        Assert-Equal 'ap-1' $b.accessPackage.id
        $csv = @(Import-Csv -LiteralPath (Join-Path $tmp 'zuweisungen.csv'))
        Assert-Equal 2 $csv.Count
        Assert-Equal 'mitarbeiter.eins@example.com' $csv[0].UPN
        Assert-Equal 'Mitarbeiter Eins' $csv[0].Benutzer
    } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}
Test-Case 'bricht ab, wenn das Zugriffspaket nicht existiert, und legt nichts an' {
    Initialize-MockTenant $fixture
    $global:MockTenant.accessPackages = @()
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'New-AccessPackagePolicy.ps1') | Out-Null } 'nicht gefunden'
    Assert-Equal 0 @(Get-MockCall 'New-MgEntitlementManagementAssignmentPolicy').Count
}

Write-Host 'Listing 13: New-GuestAccessReview.ps1'
Test-Case 'Zugriffsüberprüfung für Gäste: Standard Ablehnen, 14 Tage, Anwendung erst nach dem Test' {
    Initialize-MockTenant $fixture
    Invoke-ScriptUnderTest (Join-Path $skripte 'New-GuestAccessReview.ps1') | Out-Null
    $b = Get-Body 'New-MgIdentityGovernanceAccessReviewDefinition'
    Assert-Match $b.scope.query "userType eq 'Guest'"
    Assert-Equal 'Deny' $b.settings.defaultDecision
    Assert-Equal $true $b.settings.defaultDecisionEnabled
    Assert-Equal 14 $b.settings.instanceDurationInDays
    Assert-Equal $false $b.settings.autoApplyDecisionsEnabled 'automatisches Anwenden bleibt aus, bis getestet'
    Assert-Equal $true $b.settings.justificationRequiredOnApproval
    Assert-Equal 'absoluteMonthly' $b.settings.recurrence.pattern.type
    Assert-Equal 3 $b.settings.recurrence.pattern.interval 'vierteljährlich'
    $s = @(Get-MockScopes)
    Assert-Equal 1 $s.Count 'genau eine Berechtigung'
    Assert-Equal 'AccessReview.ReadWrite.All' $s[0]
}

Write-Host 'Listing 11: New-JoinerWorkflow.ps1'
Test-Case 'Eintritts-Workflow startet nicht automatisch und enthält zwei Aufgaben' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-JoinerWorkflow.ps1')
    $b = Get-Body 'New-MgIdentityGovernanceLifecycleWorkflow'
    Assert-Equal 'joiner' $b.category
    Assert-Equal $true $b.isEnabled
    Assert-Equal $false $b.isSchedulingEnabled 'zuerst nur manuell testen'
    Assert-Equal -1 $b.executionConditions.trigger.offsetInDays
    Assert-Equal 'employeeHireDate' $b.executionConditions.trigger.timeBasedAttribute
    Assert-Equal "(department eq 'Marketing')" $b.executionConditions.scope.rule
    Assert-Equal 2 @($b.tasks).Count
    Assert-True (-not (@($b.tasks) | Where-Object { $_.continueOnError })) 'Fehler in einer Aufgabe brechen den Workflow ab'
    Assert-Match $r.OutputText 'Workflow angelegt: wf-1'
    Assert-Equal 'wf-1' (Get-MockCall 'Get-MgIdentityGovernanceLifecycleWorkflowRun')[0].Parameter.WorkflowId
}

Write-Host 'Listing 14: PIM-Beispiel.ps1'
Test-Case 'berechtigt für 365 Tage, aktiviert für 4 Stunden und listet berechtigte Zuweisungen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'PIM-Beispiel.ps1')
    $e = Get-Body 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest'
    Assert-Equal 'adminAssign' $e.action
    Assert-Equal 'P365D' $e.scheduleInfo.expiration.duration
    Assert-Equal 'rolle-Exchange-Administrator' $e.roleDefinitionId
    $a = Get-Body 'New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest'
    Assert-Equal 'selfActivate' $a.action
    Assert-Equal 'PT4H' $a.scheduleInfo.expiration.duration
    Assert-Match $r.OutputText 'Exchange Administrator\s+admin\.drei@example\.com'
}
Test-Case 'enthält noch den Platzhalter für die Objekt-ID (muss vor dem Einsatz ersetzt werden)' {
    Initialize-MockTenant $fixture
    Invoke-ScriptUnderTest (Join-Path $skripte 'PIM-Beispiel.ps1') | Out-Null
    Assert-Match (Get-Body 'New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest').principalId '^<.*>$'
}

Write-Host 'Aufgabe 6: Gruppen ohne ausreichend Besitzer als CSV'
Test-Case 'schreibt gruppen-ohne-besitzer.csv mit drei Gruppen' {
    Initialize-MockTenant $fixture
    $tmp = New-TestDirectory
    Push-Location $tmp
    try {
        Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-06-gruppen-ohne-besitzer.ps1') | Out-Null
        $z = @(Import-Csv -LiteralPath (Join-Path $tmp 'gruppen-ohne-besitzer.csv'))
        Assert-Equal 3 $z.Count
        Assert-Equal 'Team Marketing' ($z | Where-Object { $_.AnzahlBesitzer -eq '0' }).Name
        Assert-True ($z[0].PSObject.Properties.Name -contains 'Erstellt')
        Assert-ReadOnly
    } finally { Pop-Location; Remove-Item -LiteralPath $tmp -Recurse -Force }
}

Write-Host 'Aufgabe 7: inaktive Gäste und lange offene Einladungen getrennt'
Test-Case 'trennt Kategorien: inaktiv über 120 Tage / Einladung über 45 Tage offen' {
    Initialize-MockTenant $fixture
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-gaeste-pruefen.ps1')
    $alle = @($r.Output)
    $i1 = [array]::IndexOf(@($alle | ForEach-Object { [string]$_ }), '--- Inaktiv (>120 Tage) ---')
    $i2 = [array]::IndexOf(@($alle | ForEach-Object { [string]$_ }), '--- Einladung offen (>45 Tage) ---')
    Assert-True ($i1 -ge 0 -and $i2 -gt $i1) 'beide Überschriften in der richtigen Reihenfolge'
    $inaktiv = @($alle[($i1 + 1)..($i2 - 1)])
    $offen = @($alle[($i2 + 1)..($alle.Count - 1)])
    Assert-Equal 2 $inaktiv.Count 'Gast 200 Tage und Gast ohne Anmeldung; 100 Tage reicht nicht'
    Assert-True (@($inaktiv | Where-Object { $_.DisplayName -eq 'Gast Inaktiv 200 Tage' }).Count -eq 1)
    Assert-True (@($inaktiv | Where-Object { $_.DisplayName -eq 'Gast ohne Anmeldung' }).Count -eq 1)
    Assert-Equal 1 $offen.Count 'nur die Einladung von vor 60 Tagen, nicht die von vor 40'
    Assert-Equal 'Gast Einladung offen 60 Tage' $offen[0].DisplayName
    Assert-True (-not ($inaktiv | Where-Object { $_.DisplayName -like 'Gast Einladung*' })) 'offene Einladungen zählen nicht doppelt als inaktiv'
}

Complete-Tests
