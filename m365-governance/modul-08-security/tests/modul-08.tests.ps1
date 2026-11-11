# modul-08.tests.ps1 - Offline-Tests für die Skripte aus Modul 08 (Security Governance und Secure-by-Design).
# Aufruf aus dem Repository-Hauptordner:  pwsh -NoProfile -File modul-08-security/tests/modul-08.tests.ps1
# Alle Graph-Cmdlets sind simuliert (tools/Mock-GraphSecurity.ps1, erfundene Daten in tools/fixtures/sicherheit-klein.json).
# Geprüft wird die Logik der Skripte, nicht das Verhalten eines echten Tenants.

$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Join-Path $repo 'tools') 'Test-Helper.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-MgGraph.ps1')
. (Join-Path (Join-Path $repo 'tools') 'Mock-GraphSecurity.ps1')   # überschreibt einzelne Funktionen aus Mock-MgGraph.ps1
$fixture = Join-Path (Join-Path (Join-Path $repo 'tools') 'fixtures') 'sicherheit-klein.json'
$modul = Split-Path -Parent $PSScriptRoot
$skripte = Join-Path $modul 'skripte'
$loesungen = Join-Path $modul 'loesungen-skripte'

function Start-Test { Initialize-MockSecurity $fixture }
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
function Get-FilterStunden {
    # Alter des Zeitstempels "ge yyyy-MM-ddTHH:mm:ssZ" im Filter, in Stunden
    param([string]$Filter)
    $z = [datetime]::ParseExact(($Filter -replace '^.* ge ', ''), 'yyyy-MM-ddTHH:mm:ssZ', [cultureinfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    ([datetime]::UtcNow - $z).TotalHours
}
function Get-Scopes { param([string]$Name = 'Connect-MgGraph') @((Get-Aufruf $Name)[0].Parameter.Scopes) }
function Add-Anmeldungen {
    # fügt $Anzahl Benutzer ohne MFA zu den Registrierungsdaten hinzu
    param([int]$Anzahl)
    $global:MockSec.registration = @(1..$Anzahl | ForEach-Object {
        [pscustomobject]@{ id = "x-$_"; upn = "nomfa$_@example.com"; isAdmin = $false; isMfaRegistered = $false; isPasswordlessCapable = $false; defaultMfaMethod = 'none' } })
}

Write-Host 'Listing 82: Save-SecureScore.ps1'
$heute = [datetime]::UtcNow.ToString('yyyy-MM-dd')
Test-Case 'legt den Verlauf an: Datum, Punkte, Maximum, Prozent (eine Nachkommastelle)' {
    Start-Test
    Use-Arbeitsordner {
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Save-SecureScore.ps1')
        Assert-Equal @('SecurityEvents.Read.All') (Get-Scopes)
        Assert-Equal 1 ((Get-Aufruf 'Get-MgSecuritySecureScore')[0].Parameter.Top) 'es wird nur der neueste Eintrag abgefragt'
        $z = @(Import-Csv '.\SecureScore-Verlauf.csv')
        Assert-Equal 1 $z.Count
        Assert-Equal $heute $z[0].Datum
        Assert-Match $z[0].Punkte '^312[.,]5$'
        Assert-Equal '604' $z[0].Maximum
        Assert-Match $z[0].ProzentWert '^51[.,]7$'
    }
}
Test-Case 'ist idempotent: gleiches Datum wird nicht doppelt eingetragen' {
    Start-Test
    Use-Arbeitsordner {
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Save-SecureScore.ps1')
        $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Save-SecureScore.ps1')
        Assert-Equal 1 @(Import-Csv '.\SecureScore-Verlauf.csv').Count
        Assert-Match $r.Text "Eintrag fuer $heute existiert bereits"
    }
}
Test-Case 'hängt einen neuen Tag an eine bestehende Datei an und akzeptiert -Verlauf' {
    Start-Test
    Use-Arbeitsordner {
        Set-Content -LiteralPath 'verlauf.csv' -Encoding UTF8 -Value @('"Datum","Punkte","Maximum","ProzentWert"', '"2020-01-01","100","604","16,6"')
        $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Save-SecureScore.ps1') @{ Verlauf = '.\verlauf.csv' }
        $z = @(Import-Csv '.\verlauf.csv')
        Assert-Equal 2 $z.Count
        Assert-Equal '2020-01-01' $z[0].Datum
        Assert-Equal $heute $z[1].Datum
        Assert-True (-not (Test-Path '.\SecureScore-Verlauf.csv')) 'Standarddatei wird mit -Verlauf nicht angelegt'
    }
}
Test-Case 'bricht ohne Secure-Score-Eintrag ab und schreibt nichts' {
    Start-Test
    $global:MockSec.secureScores = @()
    Use-Arbeitsordner {
        Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Save-SecureScore.ps1') } 'Kein Secure-Score-Eintrag'
        Assert-True (-not (Test-Path '.\SecureScore-Verlauf.csv'))
    }
}

Write-Host 'Listing 84: New-CaBlockLegacy.ps1'
$caName = 'CA001 - Legacy-Authentifizierung blockieren'
Test-Case 'legt die Richtlinie im Berichtsmodus an, mit Ausnahme-Gruppe und Sperre' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaBlockLegacy.ps1') @{ NotfallGruppeId = 'g-notfall' }
    Assert-Equal @('Policy.ReadWrite.ConditionalAccess', 'Application.Read.All') (Get-Scopes)
    Assert-Equal "displayName eq '$caName'" ((Get-Aufruf 'Get-MgIdentityConditionalAccessPolicy')[0].Parameter.Filter)
    $c = @(Get-Aufruf 'New-MgIdentityConditionalAccessPolicy')
    Assert-Equal 1 $c.Count
    $b = $c[0].Parameter.BodyParameter
    Assert-Equal $caName $b.displayName
    Assert-Equal 'enabledForReportingButNotEnforced' $b.state 'nie sofort erzwingen'
    Assert-Equal @('exchangeActiveSync', 'other') @($b.conditions.clientAppTypes)
    Assert-Equal @('All') @($b.conditions.applications.includeApplications)
    Assert-Equal @('All') @($b.conditions.users.includeUsers)
    Assert-Equal @('g-notfall') @($b.conditions.users.excludeGroups)
    Assert-Equal 'OR' $b.grantControls.operator
    Assert-Equal @('block') @($b.grantControls.builtInControls)
    Assert-True ($r.Output -contains "Angelegt: $caName (Zustand: enabledForReportingButNotEnforced)")
}
Test-Case 'legt nichts an, wenn die Richtlinie schon existiert' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaBlockLegacy.ps1') @{ NotfallGruppeId = 'g-notfall' }
    $global:MockCalls.Clear()
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'New-CaBlockLegacy.ps1') @{ NotfallGruppeId = 'g-notfall' } } 'Richtlinie existiert bereits'
    Assert-Equal 0 @(Get-Aufruf 'New-MgIdentityConditionalAccessPolicy').Count
}
Test-Case 'verlangt die Notfallgruppe als Pflichtparameter' {
    Assert-Mandatory (Join-Path $skripte 'New-CaBlockLegacy.ps1') @('NotfallGruppeId')
}

Write-Host 'Listing 86: Get-MfaCoverage.ps1'
Test-Case 'berechnet die drei Quoten (alle, kennwortlos, Administratoren)' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MfaCoverage.ps1')
    Assert-Equal @('AuditLog.Read.All') (Get-Scopes)
    Assert-True ($r.Output | Where-Object { $_ -match '^MFA registriert:\s+8 von 12 \(67\s?%\)$' }) 'MFA-Quote'
    Assert-True ($r.Output | Where-Object { $_ -match '^Kennwortlos moeglich:\s+3 von 12 \(25\s?%\)$' }) 'kennwortlos'
    Assert-True ($r.Output | Where-Object { $_ -match '^Administratoren mit MFA:\s+3 von 4 \(75\s?%\)$' }) 'Administratoren'
}
Test-Case 'listet die Benutzer ohne MFA mit Admin-Kennzeichen und Methode' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MfaCoverage.ps1')).OutputText
    Assert-Match $t '--- Benutzer ohne MFA \(erste 20\) ---'
    foreach ($u in 'admin2@example.com', 'benutzer06@example.com', 'benutzer07@example.com', 'benutzer08@example.com') { Assert-Match $t ([regex]::Escape($u)) }
    Assert-NotMatch $t 'benutzer01@example\.com' 'Benutzer mit MFA gehören nicht in die Liste'
    Assert-Match $t 'DefaultMfaMethod'
}
Test-Case 'zeigt höchstens 20 Benutzer ohne MFA' {
    Start-Test
    Add-Anmeldungen 25
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MfaCoverage.ps1')).OutputText
    Assert-Equal 20 @([regex]::Matches($t, 'nomfa\d+@example\.com')).Count
    Assert-Match $t 'nomfa1@example\.com'
    Assert-Match $t 'nomfa20@example\.com'
    Assert-NotMatch $t 'nomfa21@example\.com'
    Assert-Match $t '0 von 25 \(0\s?%\)'
}
Test-Case 'Hinweis: ohne Administratoren steht "0 von 1" statt "0 von 0" (@($null).Count ist 1)' {
    Start-Test
    Add-Anmeldungen 3
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MfaCoverage.ps1')
    Assert-True ($r.Output | Where-Object { $_ -match '^Administratoren mit MFA:\s+0 von 1 ' }) 'heutiges Verhalten'
}
Test-Case 'bricht ohne Registrierungsdaten ab' {
    Start-Test
    $global:MockSec.registration = @()
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Get-MfaCoverage.ps1') } 'Keine Registrierungsdaten'
}

Write-Host 'Listing 88: Get-DefenderAlertSummary.ps1'
Test-Case 'fragt Warnungen der letzten 7 Tage in UTC ab' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1')
    Assert-Equal @('SecurityAlert.Read.All') (Get-Scopes)
    $f = ((Get-Aufruf 'Get-MgSecurityAlertV2')[0].Parameter.Filter)
    Assert-Match $f '^createdDateTime ge \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
    $h = Get-FilterStunden $f
    Assert-True ($h -gt 167.9 -and $h -lt 168.1) "Zeitraum 168 Stunden, war $h"
}
Test-Case 'gruppiert nach Schweregrad (high 4, low 1, medium 1)' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1')).OutputText
    $teil = $t.Substring((Get-Pos $t '--- Nach Schweregrad ---'), (Get-Pos $t '--- Nach Quelle und Status ---') - (Get-Pos $t '--- Nach Schweregrad ---'))
    Assert-Match $teil 'high\s+4'
    Assert-Match $teil 'low\s+1'
    Assert-Match $teil 'medium\s+1'
    Assert-True ((Get-Pos $teil 'high') -lt (Get-Pos $teil 'low') -and (Get-Pos $teil 'low') -lt (Get-Pos $teil 'medium')) 'nach Name sortiert'
}
Test-Case 'gruppiert nach Quelle und Status, größte Gruppe zuerst' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1')).OutputText
    $von = Get-Pos $t '--- Nach Quelle und Status ---'
    $teil = $t.Substring($von, (Get-Pos $t '--- Hoch/Kritisch und noch nicht geloest ---') - $von)
    Assert-Match $teil 'microsoftDefenderForOffice365, new\s+2'
    Assert-Match $teil 'microsoftDefenderForEndpoint, resolved\s+1'
    Assert-True ((Get-Pos $teil 'microsoftDefenderForOffice365, new') -lt (Get-Pos $teil 'microsoftDefenderForEndpoint, resolved')) 'Count absteigend'
}
Test-Case 'listet hohe, ungelöste Warnungen ältester zuerst; gelöste und niedrige nicht' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1')).OutputText
    $teil = $t.Substring((Get-Pos $t '--- Hoch/Kritisch und noch nicht geloest ---'))
    $a = Get-Pos $teil 'Link geklickt'; $b = Get-Pos $teil 'Ransomware-Verhalten'; $c = Get-Pos $teil 'Verdaechtiger Prozess'
    Assert-True ($a -ge 0 -and $a -lt $b -and $b -lt $c) 'Reihenfolge nach CreatedDateTime'
    Assert-NotMatch $teil 'Malware blockiert' 'gelöst'
    Assert-NotMatch $teil 'Phishing-Mail' 'mittel'
    Assert-NotMatch $teil 'Alte Warnung' 'außerhalb des Zeitraums'
}
Test-Case 'Parameter -Tage ändert den Zeitraum' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1') @{ Tage = 1 }
    $h = Get-FilterStunden ((Get-Aufruf 'Get-MgSecurityAlertV2')[0].Parameter.Filter)
    Assert-True ($h -gt 23.9 -and $h -lt 24.1) "24 Stunden, war $h"
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1') @{ Tage = 30 }).OutputText
    Assert-Match $t 'Alte Warnung'
}
Test-Case 'meldet einen leeren Zeitraum' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-DefenderAlertSummary.ps1') @{ Tage = 0 }
    Assert-Match $r.Text 'Keine Warnungen im Zeitraum'
    Assert-NotMatch $r.Text 'Nach Schweregrad'
}

Write-Host 'Listing 90: New-WindowsCompliance.ps1'
Test-Case 'sendet die Konformitätsrichtlinie per POST mit JSON-Inhalt' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-WindowsCompliance.ps1')
    Assert-Equal @('DeviceManagementConfiguration.ReadWrite.All', 'DeviceManagementManagedDevices.Read.All') (Get-Scopes)
    $c = @(Get-Aufruf 'Invoke-MgGraphRequest')
    Assert-Equal 1 $c.Count
    Assert-Equal 'POST' $c[0].Parameter.Method
    Assert-Equal 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' $c[0].Parameter.Uri
    Assert-Equal 'application/json' $c[0].Parameter.ContentType
    $b = $c[0].Parameter.Body | ConvertFrom-Json
    Assert-Equal '#microsoft.graph.windows10CompliancePolicy' $b.'@odata.type'
    Assert-Equal 'Windows Basis-Konformitaet' $b.displayName
    Assert-True ($b.passwordRequired -eq $true -and $b.bitLockerEnabled -eq $true -and $b.secureBootEnabled -eq $true) 'drei Schalter an'
    Assert-Equal '10.0.19045' $b.osMinimumVersion
    $regel = @($b.scheduledActionsForRule)
    Assert-Equal 1 $regel.Count
    Assert-Equal 'PasswordRequired' $regel[0].ruleName
    $aktion = @($regel[0].scheduledActionConfigurations)
    Assert-Equal 'block' $aktion[0].actionType
    Assert-Equal 24 $aktion[0].gracePeriodHours
    Assert-True ($r.Output -contains 'Angelegt: Windows Basis-Konformitaet (00000000-0000-0000-0000-00000000c0de)')
}
Test-Case 'listet nicht konforme Geräte, am längsten nicht synchronisierte zuerst, mit Anzahl' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'New-WindowsCompliance.ps1')
    Assert-Equal "complianceState eq 'noncompliant'" ((Get-Aufruf 'Get-MgDeviceManagementManagedDevice')[0].Parameter.Filter)
    $t = $r.OutputText
    $a = Get-Pos $t 'PC-LABOR-02'; $b = Get-Pos $t 'PC-PROJEKT-04'; $c = Get-Pos $t 'PC-VERTRIEB-01'
    Assert-True ($a -ge 0 -and $a -lt $b -and $b -lt $c) 'nach LastSyncDateTime aufsteigend'
    Assert-NotMatch $t 'PC-FINANZ-03' 'konformes Gerät'
    Assert-True ($r.Output -contains 'Anzahl: 3')
}
Test-Case 'Hinweis: das Skript prüft nicht auf eine vorhandene Richtlinie (jeder Lauf sendet einen POST)' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'New-WindowsCompliance.ps1')
    Assert-Equal 1 @(Get-Aufruf 'Invoke-MgGraphRequest').Count
    $quelltext = Get-Content -LiteralPath (Join-Path $skripte 'New-WindowsCompliance.ps1') -Raw
    Assert-NotMatch $quelltext 'Get-MgDeviceManagementDeviceCompliancePolicy' 'keine Abfrage vorhandener Richtlinien vor dem POST'
}

Write-Host 'Listing 92: Test-GlobalAdmins.ps1'
Test-Case 'liest die Mitglieder der Rolle und die Benutzerdetails' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1')
    Assert-Equal @('RoleManagement.Read.Directory', 'User.Read.All', 'AuditLog.Read.All') (Get-Scopes)
    Assert-Equal "displayName eq 'Global Administrator'" ((Get-Aufruf 'Get-MgDirectoryRole')[0].Parameter.Filter)
    $u = @(Get-Aufruf 'Get-MgUser')
    Assert-Equal 5 $u.Count
    Assert-Equal @('DisplayName', 'UserPrincipalName', 'UserType', 'AccountEnabled', 'Mail') @($u[0].Parameter.Property)
}
Test-Case 'warnt bei fehlender MFA (auch bei unbekanntem Status), Gästen und Postfächern' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1')
    Assert-Equal @('Keine MFA: admin2@example.com', 'Keine MFA: admin5@example.com',
                   'Gastkonto: admin3_extern.example.org#EXT#@example.onmicrosoft.com', 'Admin mit Postfach: admin4@example.com') @($r.Warnings)
    Assert-Match $r.OutputText 'unbekannt'
}
Test-Case 'warnt vor zu vielen Globalen Administratoren erst über dem Grenzwert' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1') @{ Maximum = 5 }
    Assert-Equal 0 @($r.Warnings | Where-Object { $_ -like 'Mehr als*' }).Count '5 von 5 ist erlaubt'
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1') @{ Maximum = 4 }
    Assert-Equal 'Mehr als 4 Globale Administratoren: 5' $r.Warnings[0]
}
Test-Case 'zeigt Typ, Status und Postfach in der Tabelle' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1')).OutputText
    Assert-Match $t 'Konto\s+Typ\s+Aktiv\s+MfaRegistr\s+HatPostfach'
    Assert-Match $t 'admin5@example\.com\s+Member\s+False'
    Assert-Match $t 'admin1@example\.com\s+Member\s+True\s+True\s+False'
}
Test-Case 'bricht ab, wenn die Rolle nicht gefunden wird' {
    Start-Test
    $global:MockSec.directoryRole = $null
    Assert-Throws { Invoke-ScriptUnderTest (Join-Path $skripte 'Test-GlobalAdmins.ps1') } 'Rolle nicht aktiviert'
    Assert-Equal 0 @(Get-Aufruf 'Get-MgDirectoryRoleMember').Count
}

Write-Host 'Listing 94: Get-CaExclusions.ps1'
Test-Case 'zeigt Ausschlüsse nach Art: Benutzer, Gruppe (mit Name und Mitgliedern), Rolle' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')
    Assert-Equal @('Policy.Read.All', 'Group.Read.All') (Get-Scopes)
    $t = $r.OutputText
    Assert-Match $t 'CA001 - Legacy blockieren\s+Gruppe\s+SEC-BREAKGLASS\s+2'
    Assert-Match $t 'CA002 - MFA fuer alle\s+Benutzer\s+u-lab1'
    Assert-Match $t 'CA002 - MFA fuer alle\s+Gruppe\s+SEC-EXC-CA001-LegacyAuth\s+1'
    Assert-Match $t 'CA002 - MFA fuer alle\s+Rolle\s+62e90394-69f5-4237-9190-012177145e10'
    Assert-Equal 0 @($r.Errors).Count 'Fehler beim Auflösen werden unterdrückt'
}
Test-Case 'sortiert nach Richtlinie und Art' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')).OutputText
    $p1 = Get-Pos $t 'CA001 - Legacy'; $p2 = Get-Pos $t 'CA002 - MFA fuer alle  '; $p3 = Get-Pos $t 'CA003'
    Assert-True ($p1 -ge 0 -and $p1 -lt $p2 -and $p2 -lt $p3) 'Richtlinien'
    $b = Get-Pos $t 'Benutzer'; $g = Get-Pos $t 'SEC-EXC-CA001-LegacyAuth'; $ro = Get-Pos $t 'Rolle  '
    Assert-True ($b -lt $g -and $g -lt $ro) 'Art: Benutzer vor Gruppe vor Rolle'
}
Test-Case 'sortiert nach Richtlinie, auch wenn die Abfrage sie in anderer Reihenfolge liefert' {
    Start-Test
    $global:MockSec.caPolicies = @($global:MockSec.caPolicies | Sort-Object { $_.name } -Descending)
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')).OutputText
    Assert-True ((Get-Pos $t 'CA001 - Legacy') -lt (Get-Pos $t 'CA002 - MFA fuer alle  ') -and (Get-Pos $t 'CA002 - MFA fuer alle  ') -lt (Get-Pos $t 'CA003')) 'Richtlinien aufsteigend'
}
Test-Case 'zeigt die ID, wenn die Gruppe nicht mehr existiert (Mitglieder 0)' {
    Start-Test
    $t = (Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')).OutputText
    Assert-Match $t 'CA003 - Geraet konform\s+Gruppe\s+g-geloescht\s+0'
}
Test-Case 'warnt vor direkten Benutzerausschlüssen, sonst nicht' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')
    Assert-Equal 1 @($r.Warnings).Count
    Assert-Match $r.Warnings[0] '^1 direkte Benutzerausschluesse'
    $global:MockSec.caPolicies = @($global:MockSec.caPolicies | Where-Object { $_.excludeUsers.Count -eq 0 })
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-CaExclusions.ps1')
    Assert-Equal 0 @($r.Warnings).Count
}

Write-Host 'Listing 96: Get-SignInCaDetails.ps1'
Test-Case 'fragt Anmeldungen des Benutzers der letzten 24 Stunden ab (-Top 25)' {
    Start-Test
    $null = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SignInCaDetails.ps1') @{ Benutzer = 'anna@example.com' }
    Assert-Equal @('AuditLog.Read.All') (Get-Scopes)
    $p = (Get-Aufruf 'Get-MgAuditLogSignIn')[0].Parameter
    Assert-Equal 25 $p.Top
    Assert-Match $p.Filter "^userPrincipalName eq 'anna@example\.com' and createdDateTime ge \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$"
    $h = Get-FilterStunden $p.Filter
    Assert-True ($h -gt 23.9 -and $h -lt 24.1) "24 Stunden, war $h"
}
Test-Case 'zeigt je Anmeldung CA-Status, Fehlercode, Richtlinien und Grund, älteste zuerst' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SignInCaDetails.ps1') @{ Benutzer = 'anna@example.com' }
    $z = @($r.Output)
    Assert-Equal 2 @($z | Where-Object { $_ -match 'CA-Status:' }).Count 'zwei Anmeldungen in 24 Stunden'
    Assert-Match $z[0] '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}Z  Microsoft Teams  CA-Status: failure  Fehlercode: 53003$'
    Assert-Equal '      - CA003 - Geraet konform: failure' $z[1]
    Assert-Equal '      Grund: Access has been blocked by Conditional Access policies.' $z[2]
    Assert-Match $z[3] 'CA-Status: success  Fehlercode: 0$'
    Assert-Equal '      - CA001 - Legacy blockieren: notApplied' $z[4]
    Assert-Equal '      - CA002 - MFA fuer alle: success' $z[5]
    Assert-Equal 6 $z.Count 'erfolgreiche Anmeldungen haben keine Grund-Zeile'
}
Test-Case 'Parameter -Stunden erweitert den Zeitraum' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SignInCaDetails.ps1') @{ Benutzer = 'anna@example.com'; Stunden = 48 }
    Assert-Equal 3 @($r.Output | Where-Object { $_ -match 'CA-Status:' }).Count
    Assert-Match $r.Text 'Outlook'
}
Test-Case 'meldet, wenn es keine Anmeldungen gibt, und verlangt -Benutzer' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $skripte 'Get-SignInCaDetails.ps1') @{ Benutzer = 'niemand@example.com' }
    Assert-Match $r.Text 'Keine Anmeldungen im Zeitraum'
    Assert-Mandatory (Join-Path $skripte 'Get-SignInCaDetails.ps1') @('Benutzer')
}

Write-Host 'Aufgabe 4: CA-Richtlinien im Berichtsmodus'
Test-Case 'zeigt Richtlinien im reinen Berichtsmodus zuerst' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-04-ca-berichtsmodus.ps1')
    Assert-Equal @('Policy.Read.All') (Get-Scopes)
    $t = $r.OutputText
    Assert-Match $t 'CA002 - MFA fuer alle\s+enabledForReportingButNotEnforced\s+True'
    Assert-Match $t 'CA001 - Legacy blockieren\s+enabled\s+False'
    Assert-True ((Get-Pos $t 'CA002') -ge 0 -and (Get-Pos $t 'CA002') -lt (Get-Pos $t 'CA001') -and (Get-Pos $t 'CA002') -lt (Get-Pos $t 'CA003')) 'Berichtsmodus zuerst'
}

Write-Host 'Aufgabe 7: Konten in mehr als zwei Ausnahmegruppen'
Test-Case 'findet das Konto in vier SEC-EXC-Gruppen, nicht das in zwei' {
    Start-Test
    $r = Invoke-ScriptUnderTest (Join-Path $loesungen 'aufgabe-07-ausnahmegruppen.ps1')
    Assert-Equal @('Group.Read.All', 'User.Read.All') (Get-Scopes)
    Assert-Equal "startswith(displayName,'SEC-EXC-')" ((Get-Aufruf 'Get-MgGroup')[0].Parameter.Filter)
    $o = @($r.Output)
    Assert-Equal 1 $o.Count
    Assert-Equal 'u-lab1' $o[0].Id
    Assert-Equal 'SEC-EXC-CA001-LegacyAuth, SEC-EXC-CA002-Reisen, SEC-EXC-CA003-Geraet, SEC-EXC-CA004-Test' $o[0].Gruppen
    Assert-Equal 4 @(Get-Aufruf 'Get-MgGroupMember').Count 'nur SEC-EXC-Gruppen werden gelesen'
}

Complete-Tests
