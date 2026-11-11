# Falsch und richtig – Modul 08

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 83: Verlauf statt Momentaufnahme

```text
# FALSCH: nur anzeigen, nichts festhalten
(Get-MgSecuritySecureScore -Top 1).CurrentScore

# RICHTIG: Wert mit Datum speichern (Verlauf), Quote berechnen
$s = Get-MgSecuritySecureScore -Top 1
[pscustomobject]@{ Datum = $s.CreatedDateTime; Quote = 100 * $s.CurrentScore / $s.MaxScore } |
    Export-Csv .\score.csv -Append -NoTypeInformation
```

## Listing 85: Zustand und Ausnahme

```text
# FALSCH: sofort aktiv, keine Notfallkonten ausgenommen
$body = @{ displayName = "MFA fuer alle"; state = "enabled"
  conditions = @{ applications = @{ includeApplications = @("All") }
                  users = @{ includeUsers = @("All") } }
  grantControls = @{ operator = "OR"; builtInControls = @("mfa") } }

# RICHTIG: Berichtsmodus und Ausnahme fuer die Notfallgruppe
$body = @{ displayName = "CA002 - MFA fuer alle"
  state = "enabledForReportingButNotEnforced"
  conditions = @{ applications = @{ includeApplications = @("All") }
                  users = @{ includeUsers = @("All"); excludeGroups = @($NotfallGruppeId) } }
  grantControls = @{ operator = "OR"; builtInControls = @("mfa") } }
```

## Listing 87: Registrierung schuetzen

```text
# FALSCH: Registrierung von beliebigem Ort und Geraet erlaubt (keine Richtlinie)
# -> ein Angreifer mit Kennwort registriert seinen eigenen Faktor

# RICHTIG: CA-Richtlinie fuer die Aktion "Sicherheitsinformationen registrieren":
$body = @{ displayName = "CA010 - Registrierung nur von vertrauten Orten"
  state = "enabledForReportingButNotEnforced"
  conditions = @{ applications = @{ includeUserActions = @("urn:user:registersecurityinfo") }
                  users = @{ includeUsers = @("All"); excludeGroups = @($NotfallGruppeId) }
                  locations = @{ includeLocations = @("All"); excludeLocations = @("AllTrusted") } }
  grantControls = @{ operator = "OR"; builtInControls = @("block") } }
```

## Listing 89: Schutz fuer alle Benutzer pruefen

```text
# FALSCH: annehmen, dass der Schutz "irgendwie" gilt
# (kein Nachweis, welche Benutzer unter welcher Richtlinie stehen)

# RICHTIG: Voreingestellte Richtlinien und ihre Regeln lesen
Connect-ExchangeOnline
Get-EOPProtectionPolicyRule | Select-Object Name, State, Priority, SentTo, SentToMemberOf
Get-ATPProtectionPolicyRule | Select-Object Name, State, Priority
```

## Listing 91: Karenz und Zuweisung

```text
# FALSCH: Sofortsperre und keine Zuweisung
@{ ruleName = "PasswordRequired"
   scheduledActionConfigurations = @(@{ actionType = "block"; gracePeriodHours = 0 }) }

# RICHTIG: Karenz, dann Zuweisung an eine Pilotgruppe pruefen
@{ ruleName = "PasswordRequired"
   scheduledActionConfigurations = @(@{ actionType = "block"; gracePeriodHours = 24 }) }
# Zuweisung im Portal (Intune > Geraete > Konformitaet > Zuweisungen) pruefen
```

## Listing 93: Rollen und Konten

```text
# FALSCH: eigenes Alltagskonto zum Globalen Administrator machen
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $rolle.Id `
    -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($alltagskonto.Id)" }

# RICHTIG: dediziertes Adminkonto, geringste Rolle, ueber PIM berechtigt (siehe Modul 2)
# z. B. Exchange-Administrator statt Globaler Administrator, zeitlich begrenzt aktivierbar
```

## Listing 95: Ausnahme ueber Gruppe

```text
# FALSCH: einzelnes Konto direkt ausgeschlossen, keine Frist, kein Besitzer
$bedingungen.users.excludeUsers = @("a3f1c0de-0000-0000-0000-000000000000")

# RICHTIG: Ausnahmegruppe mit Besitzer und Beschreibung inkl. Ablaufdatum
New-MgGroup -DisplayName "SEC-EXC-CA001-LegacyAuth" `
    -Description "Ausnahme Messgeraet Labor, genehmigt von R. Beispiel, laeuft ab 2027-03-31" `
    -MailEnabled:$false -SecurityEnabled -MailNickname "sec-exc-ca001"
```

## Listing 97: Ursache vor Aenderung

```text
# FALSCH: Richtlinie abschalten, "damit es geht"
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $id -State "disabled"

# RICHTIG: erst die Anmeldung lesen, dann gezielt eine Ausnahme oder Korrektur planen
.\Get-SignInCaDetails.ps1 -Benutzer "anna@contoso.com" -Stunden 4
# ... Ursache zuordnen (Gerät? Standort? Altprotokoll?) und im Ausnahmeprozess behandeln
```
