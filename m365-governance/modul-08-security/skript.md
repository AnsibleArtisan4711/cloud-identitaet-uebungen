# Modul 08 - Security Governance und Secure-by-Design

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 9 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8 Stunden (8 × 1). Als Richtwert für den Umfang wurde der höhere Wert (9 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**             | **Dauer (h)** | **Prio** |
|:--------|:----------------------------|--------------:|---------:|
| 8.1     | Secure Score                |             1 |        1 |
| 8.2     | Conditional Access Baseline |             1 |        1 |
| 8.3     | MFA und Passwordless        |             1 |        1 |
| 8.4     | Defender Integration        |             1 |        1 |
| 8.5     | Device Compliance           |             1 |        1 |
| 8.6     | Privileged Access           |             1 |        2 |
| 8.7     | Security Exceptions         |             1 |        2 |
| 8.8     | Security-Troubleshooting    |             1 |        2 |
|         | **Summe laut Details**      |         **8** |          |
|         | **Dauer laut Modulblatt**   |         **9** |          |

> **Merke: Microsoft Graph PowerShell und Beispielcode**
>
> Die Beispiele dieses Moduls verwenden das Microsoft Graph PowerShell SDK. Verbinden Sie sich mit `Connect-MgGraph` und nennen Sie die benötigten Berechtigungsbereiche (Scopes) ausdrücklich; sie stehen jeweils im Skript. Verwenden Sie für Änderungen an Richtlinien ein Testkonto und einen Testtenant, und legen Sie neue Zugriffsrichtlinien immer zuerst im Modus „nur Bericht“ an. Eine falsch gesetzte Richtlinie für bedingten Zugriff kann alle Administratoren aussperren. Die Beispiele folgen den Mustern der Microsoft-Dokumentation und wurden nicht gegen einen echten Tenant ausgeführt.

Dieses Modul legt fest, wie Sicherheit als Standard in den Betrieb kommt: messbar (Secure Score), durchgesetzt (bedingter Zugriff, starke Anmeldung, Gerätekonformität), überwacht (Defender), kontrolliert für Administratoren und geregelt für Ausnahmen. Rollenmodell und Just-in-Time-Zugriff für Administratoren (Privileged Identity Management) wurden in Modul 2 erklärt; hier werden sie unter dem Sicherheitsblickwinkel wieder aufgegriffen und nicht erneut aufgebaut.

## 8.1 Secure Score

Sicherheit lässt sich schwer steuern, solange man sie nicht messen kann. Der *Microsoft Secure Score* liefert eine Messgröße: Er bewertet die Sicherheitslage des Tenants als Zahl und leitet daraus konkrete *Verbesserungsmaßnahmen* (Improvement Actions) ab. Jede Maßnahme hat einen Punktwert, einen Umsetzungsstatus und eine Beschreibung mit Umsetzungsschritten. Der Score ist der Anteil erreichter Punkte an den erreichbaren Punkten, also eine Quote. Er bezieht Einstellungen aus mehreren Produkten ein, etwa Entra ID, Exchange Online, Defender für Office 365 und Intune.

Der Wert des Scores liegt weniger in der Zahl als in der Liste der Maßnahmen. Sie ist eine priorisierte Arbeitsliste, die Microsoft laufend aktualisiert, wenn neue Bedrohungen oder Funktionen hinzukommen. Jede Maßnahme lässt sich einem Status zuordnen: zu bearbeiten, geplant, Risiko akzeptiert, durch Drittprodukt gelöst oder durch alternative Maßnahme gelöst. Damit wird der Score zum Steuerungsinstrument: Das Security-Team entscheidet bewusst, welche Maßnahmen es umsetzt, welche es verschiebt und welche es mit Begründung ablehnt.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zum Secure Score liegt der Score in der Defender-Oberfläche und wird als Prozentwert der erreichten Punkte dargestellt; Maßnahmen lassen sich nach Produkt, Kategorie und Status filtern. Der Score kann über Microsoft Graph abgerufen werden (Ressourcen für Score und Kontrollprofile), sodass eine Auswertung im Zeitverlauf möglich ist. Die Dokumentation weist darauf hin, dass der Score ein Hilfsmittel zur Verbesserung ist und keine Aussage über absolute Sicherheit. Eine Maßnahme mit hohem Punktwert ist nicht automatisch für jede Organisation sinnvoll. Welche Maßnahmen angeboten werden, hängt von Produkten und Lizenzen ab.

Wie nutzt man den Score richtig? Zuerst legt man Zuständigkeiten fest: Jede Maßnahme hat einen Verantwortlichen im Betrieb. Dann wählt man Maßnahmen nach Wirkung und Aufwand: hohe Punkte bei geringem Benutzeraufwand zuerst (zum Beispiel Altprotokolle blockieren), Maßnahmen mit großem Einfluss auf Benutzer (zum Beispiel Kennwortänderungen erzwingen) erst nach Pilot und Kommunikation. Danach stellt man den Score monatlich fest und bewertet die Entwicklung. Einen Wert unter dem Branchenvergleich lässt man erklären, aber nicht durch bloßes Abhaken von Maßnahmen verbessern.

Das folgende Skript liest den aktuellen Score aus Microsoft Graph und schreibt ihn mit Datum in eine Verlaufsdatei. Es erzeugt dadurch ohne Zusatzwerkzeug eine Zeitreihe, die in Modul 9 als Kennzahl dient. Es liest zuerst den neuesten Eintrag mit `Get-MgSecuritySecureScore -Top 1`, berechnet die Quote und hängt eine Zeile an eine CSV-Datei an. Die erforderliche Berechtigung ist `SecurityEvents.Read.All`.

**Save-SecureScore.ps1**

```powershell
param([string]$Verlauf = ".\SecureScore-Verlauf.csv")

Connect-MgGraph -Scopes "SecurityEvents.Read.All" -NoWelcome

$s = Get-MgSecuritySecureScore -Top 1
if (-not $s) { throw "Kein Secure-Score-Eintrag gefunden." }

$zeile = [pscustomobject]@{
    Datum       = $s.CreatedDateTime.ToString("yyyy-MM-dd")
    Punkte      = $s.CurrentScore
    Maximum     = $s.MaxScore
    ProzentWert = [math]::Round(100 * $s.CurrentScore / $s.MaxScore, 1)
}

if ((Test-Path $Verlauf) -and
    (Import-Csv $Verlauf | Where-Object Datum -eq $zeile.Datum)) {
    Write-Host "Eintrag fuer $($zeile.Datum) existiert bereits."
} else {
    $zeile | Export-Csv -Path $Verlauf -Append -NoTypeInformation -Encoding UTF8
    $zeile | Format-Table -AutoSize
}
```

Die Zeilen im Einzelnen: `Connect-MgGraph` fordert nur den nötigen Lesebereich an (Prinzip der geringsten Rechte). `-Top 1` liefert den jüngsten Eintrag. Die Quote entsteht aus erreichten und möglichen Punkten. Die Prüfung `Where-Object Datum -eq` verhindert doppelte Einträge, wenn das Skript täglich läuft. Als geplante Aufgabe oder in einer Automatisierung (Modul 11) entsteht daraus ein wöchentlicher Verlauf.

### Typische Fehler und Stolperfallen.

Der verbreitetste Fehler ist das Jagen der Zahl: Maßnahmen werden als erledigt markiert, ohne dass sie umgesetzt sind, oder werden gegen den Betrieb durchgesetzt. Zweitens bleibt der Status „Risiko akzeptiert“ ohne Begründung und Frist stehen. Drittens wird der Score nur einmal angesehen. Viertens vergleicht man die eigene Zahl mit fremden Tenants, ohne Größe und Branche zu berücksichtigen.

**Falsch und richtig: Verlauf statt Momentaufnahme**

```powershell
# FALSCH: nur anzeigen, nichts festhalten
(Get-MgSecuritySecureScore -Top 1).CurrentScore

# RICHTIG: Wert mit Datum speichern (Verlauf), Quote berechnen
$s = Get-MgSecuritySecureScore -Top 1
[pscustomobject]@{ Datum = $s.CreatedDateTime; Quote = 100 * $s.CurrentScore / $s.MaxScore } |
    Export-Csv .\score.csv -Append -NoTypeInformation
```

Der Unterschied liegt im Gedächtnis: Erst ein Verlauf zeigt, ob Maßnahmen wirken oder ob eine neue Maßnahme von Microsoft den Score gesenkt hat, obwohl sich nichts verschlechtert hat. Eine Änderung der Bewertungsgrundlage durch Microsoft sollte im Bericht vermerkt werden.

### Praxisbezug.

Der Score wird im Projekt zur gemeinsamen Sprache zwischen IT-Sicherheit und Leitung. Er ist ein einfaches Bild für den Quartalsbericht. Ergänzen Sie ihn stets durch zwei Sätze zu den wichtigsten offenen Maßnahmen und ihrem Plan, denn die Zahl allein beantwortet nicht die Frage „Was tun wir dagegen?“.

## 8.2 Conditional Access Baseline

*Bedingter Zugriff* (Conditional Access, CA) ist die Richtlinienmaschine von Microsoft Entra ID. Sie entscheidet bei jeder Anmeldung anhand von Signalen (wer, von wo, mit welchem Gerät, bei welcher Anwendung, mit welchem Risiko), ob der Zugriff erlaubt, blockiert oder an Bedingungen geknüpft wird (zum Beispiel MFA, konformes Gerät, Nutzungsbedingungen). Eine *Baseline* ist ein Mindestsatz von Richtlinien, den jeder Tenant braucht, unabhängig von Branche und Größe. Sie ist der Boden, auf dem spezielle Richtlinien aufbauen.

Eine übliche Baseline enthält folgende Richtlinien. Erstens: MFA für Administratorrollen, weil kompromittierte Adminkonten den größten Schaden verursachen. Zweitens: MFA für alle Benutzer (mit sinnvollen Ausnahmen). Drittens: Blockieren von Legacy-Authentifizierung (Protokolle wie POP, IMAP und SMTP-Auth mit Basisanmeldung, die keine MFA kennen). Viertens: MFA oder Blockade bei riskanten Anmeldungen (erfordert Entra ID P2 mit Identity Protection). Fünftens: konformes oder verwaltetes Gerät für sensible Anwendungen. Sechstens: besondere Behandlung von Gästen. Dazu kommen zwei Prinzipien: Jede Richtlinie beginnt im Modus „nur Bericht“, und es gibt Notfallkonten (Break Glass), die von allen Richtlinien ausgenommen sind und anderweitig überwacht werden.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zum bedingten Zugriff gibt es für Richtlinien die Zustände „Ein“, „Aus“ und „Nur Bericht“; im Berichtsmodus werden Auswirkungen in den Anmeldeprotokollen sichtbar, ohne durchgesetzt zu werden. Das Werkzeug „What If“ simuliert die Wirkung auf einen Benutzer und eine Situation. Die Dokumentation empfiehlt, Notfallzugriffskonten von Richtlinien auszunehmen und deren Nutzung zu überwachen, und nennt Sicherheitsstandards (Security Defaults) als einfache Alternative für kleine Tenants ohne eigene CA-Richtlinien; beide Ansätze dürfen nicht gleichzeitig genutzt werden. Zudem gibt es von Microsoft verwaltete Richtlinien, die in vielen Tenants automatisch als Vorschlag oder Standard erscheinen. Lizenzbedarf (P1, P2) und aktuelle Namen der Vorlagen sind in der Dokumentation zu prüfen.

Warum der Berichtsmodus so wichtig ist, zeigt ein einfaches Gedankenexperiment: Wenn eine Richtlinie „Alle Benutzer, alle Anwendungen, MFA verlangen“ sofort aktiv wird, sind plötzlich Dienstkonten betroffen, die keine MFA durchführen können, Besprechungsräume mit Konten ohne Smartphone, externe Partner mit eigenem MFA-Verfahren. Im Berichtsmodus sieht man vorab in den Anmeldeprotokollen, welche Anmeldungen betroffen wären, und kann Ausnahmen oder Alternativen planen. Erst danach schaltet man auf „Ein“. Dieses Verfahren (Bericht, Auswertung, Pilotgruppe, Alle) ist das Standardvorgehen für jede Änderung am bedingten Zugriff.

Das folgende Skript legt die Richtlinie „Legacy-Authentifizierung blockieren“ im Berichtsmodus an und nimmt eine Notfallgruppe aus. Es verwendet `New-MgIdentityConditionalAccessPolicy` mit einem Textkörper in Form einer Hashtable. Die Bedingung `clientAppTypes` mit den Werten für Exchange ActiveSync und andere Clients erfasst die Altprotokolle; die Zugriffskontrolle `block` verweigert den Zugriff. Die Gruppen-ID der Notfallkonten wird als Parameter übergeben.

**New-CaBlockLegacy.ps1**

```powershell
param([Parameter(Mandatory)][string]$NotfallGruppeId)

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Application.Read.All" -NoWelcome

$name = "CA001 - Legacy-Authentifizierung blockieren"
if (Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$name'") {
    throw "Richtlinie existiert bereits: $name"
}

$body = @{
    displayName = $name
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        clientAppTypes = @("exchangeActiveSync", "other")
        applications   = @{ includeApplications = @("All") }
        users          = @{
            includeUsers  = @("All")
            excludeGroups = @($NotfallGruppeId)
        }
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("block")
    }
}

$neu = New-MgIdentityConditionalAccessPolicy -BodyParameter $body
"Angelegt: {0} (Zustand: {1})" -f $neu.DisplayName, $neu.State
```

Die wichtigsten Zeilen: Die Existenzprüfung am Anfang macht das Skript wiederholbar. `state = "enabledForReportingButNotEnforced"` ist der Berichtsmodus. Die Bedingung nennt die Clienttypen der Altprotokolle, die Ausnahme `excludeGroups` schützt die Notfallkonten, und `grantControls` setzt die Blockade. Nach einigen Tagen wertet man die Anmeldeprotokolle aus (Lerneinheit 8.8) und schaltet erst dann auf `enabled`.

### Typische Fehler und Stolperfallen.

Der schlimmste Fehler ist die Aussperrung: Eine Richtlinie für alle Benutzer ohne Notfallkonto-Ausnahme, die nicht erfüllbar ist, sperrt auch die Administratoren. Zweitens fehlt oft die Prüfung auf Dienstkonten und Konten für Besprechungsgeräte. Drittens werden Richtlinien überlappend und widersprüchlich angelegt. Viertens fehlt eine Namenskonvention („CA001 – …“), sodass im Troubleshooting niemand mehr durchsieht.

**Falsch und richtig: Zustand und Ausnahme**

```powershell
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

Das Gegenbeispiel zeigt drei Verbesserungen: Berichtsmodus, Ausnahme und Namenskonvention. Zusätzlich lohnt ein Alarm bei jeder Anmeldung eines Notfallkontos, damit deren Nutzung auffällt.

### Praxisbezug.

Jedes Projekt beginnt mit der Bestandsaufnahme: Welche CA-Richtlinien gibt es heute? Sind welche vorhanden, die niemand kennt? Die Baseline wird dann als Zielbild mit Reihenfolge und Zeitplan dokumentiert. Änderungen laufen über den Änderungsprozess (Modul 11, Policy-as-Code), und die Richtlinien werden als Konfiguration exportiert und versioniert.

> **Praxisbeispiel**
>
> Ein Handelsunternehmen aktiviert „MFA für alle“ am Freitagnachmittag ohne Berichtsmodus. Am Montag stehen Lagerscanner, die sich mit einem gemeinsamen Konto anmelden, still. Der Berichtsmodus hätte die Anmeldungen schon in der Woche davor als „würde MFA verlangen“ gezeigt. Die Lösung: Scanner erhalten verwaltete Identitäten beziehungsweise eine Ausnahme mit standortbasierter Bedingung und Befristung, und die Richtlinie wird erneut geplant.

## 8.3 MFA und Passwordless

Ein Kennwort ist ein Geheimnis, das gestohlen, erraten oder auf einer gefälschten Anmeldeseite abgegriffen werden kann. *Multi-Faktor-Authentifizierung* (MFA) verlangt zusätzlich einen zweiten, unabhängigen Nachweis: etwas, das man hat (Smartphone, Sicherheitsschlüssel) oder ist (Fingerabdruck, Gesicht). MFA verhindert den größten Teil der Angriffe, bei denen nur ein Kennwort erbeutet wurde. Nicht alle Faktoren sind gleich stark: SMS und Sprachanruf können abgefangen oder umgeleitet werden, Push-Bestätigungen können durch ständige Wiederholung erzwungen werden („MFA-Ermüdung“), und Eingabe von Codes auf gefälschten Seiten lässt sich abfangen (Phishing). *Phishing-resistente* Verfahren wie FIDO2-Sicherheitsschlüssel, Passkeys und Windows Hello for Business binden die Anmeldung kryptografisch an die echte Adresse der Seite und widerstehen deshalb auch Angriffen auf gefälschten Seiten.

*Passwordless* (kennwortlos) geht noch einen Schritt weiter und ersetzt das Kennwort ganz: Der Benutzer meldet sich mit Gerät und biometrischem Merkmal oder PIN an, die lokal im Gerät gespeichert sind. Das beseitigt Kennwortdiebstahl, Wiederverwendung und das Kennwort-Reset-Aufkommen im Support. Microsoft bietet dafür Windows Hello for Business, den Microsoft Authenticator im kennwortlosen Modus, Passkeys und FIDO2-Schlüssel. Als Einstieg dient oft das *Temporary Access Pass* (befristeter Zugangscode), mit dem sich Benutzer erstmals anmelden und starke Verfahren registrieren können, ohne ein Kennwort zu brauchen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Authentifizierungsmethoden beschreibt die Richtlinie für Authentifizierungsmethoden als zentralen Ort, an dem man Verfahren pro Benutzergruppe aktiviert, und die *Authentifizierungsstärken* (Authentication Strengths), mit denen man im bedingten Zugriff nicht nur „MFA“ verlangen kann, sondern eine Verfahrensklasse, zum Beispiel „Phishing-resistente MFA“. Außerdem gibt es eine Registrierungskampagne, die Benutzer zur Registrierung stärkerer Verfahren anhält, sowie Berichte über Registrierungen und Nutzung. Welche Verfahren verfügbar sind, bezeichnet sich laufend neu (Passkeys, synchronisierte Passkeys); lesen Sie die aktuelle Liste in der Dokumentation.

Die Governance-Entscheidungen sind folgende. Welche Verfahren sind erlaubt (und welche nicht mehr: SMS und Sprachanruf als Auslaufmodell)? Für wen gilt welche Stärke (Administratoren phishing-resistent, alle anderen mindestens Authenticator mit Nummernabgleich)? Wie läuft die Registrierung (kontrolliert, nicht aus dem Gästenetz), wie die Wiederherstellung bei Geräteverlust (Helpdesk-Prozess mit Identitätsprüfung, denn er ist ein bevorzugtes Angriffsziel), und wie wird der Fortschritt gemessen? Die wichtigste Kennzahl ist die Abdeckung: Welcher Anteil der Benutzer hat MFA registriert, welcher Anteil kann sich kennwortlos anmelden?

Das Skript liest die Registrierungsdetails aus Microsoft Graph und berechnet die Abdeckung insgesamt sowie für Konten mit Adminrollen. Es verwendet `Get-MgReportAuthenticationMethodUserRegistrationDetail`, das je Benutzer die Eigenschaften `IsMfaRegistered`, `IsPasswordlessCapable` und `MethodsRegistered` liefert. Die Berechtigung `AuditLog.Read.All` ist erforderlich.

**Get-MfaCoverage.ps1**

```powershell
Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome

$alle = Get-MgReportAuthenticationMethodUserRegistrationDetail -All
if (-not $alle) { throw "Keine Registrierungsdaten erhalten." }

function Quote($menge, $filter) {
    $n = @($menge | Where-Object $filter).Count
    "{0} von {1} ({2:P0})" -f $n, @($menge).Count, ($n / [math]::Max(1, @($menge).Count))
}

"MFA registriert:            " + (Quote $alle { $_.IsMfaRegistered })
"Kennwortlos moeglich:       " + (Quote $alle { $_.IsPasswordlessCapable })
"Administratoren mit MFA:    " + (Quote ($alle | Where-Object IsAdmin) { $_.IsMfaRegistered })

"--- Benutzer ohne MFA (erste 20) ---"
$alle | Where-Object { -not $_.IsMfaRegistered } |
    Select-Object -First 20 UserPrincipalName, IsAdmin, DefaultMfaMethod |
    Format-Table -AutoSize
```

Die Hilfsfunktion `Quote` berechnet eine Anzahl und einen Prozentwert, wobei `[math]::Max(1, ...)` eine Division durch null vermeidet. Die drei Kennzahlen stehen bewusst getrennt, denn die Abdeckung der Administratoren ist wichtiger als der Durchschnitt. Die Liste der ersten 20 Benutzer ohne MFA ist Arbeitsmaterial für die Registrierungskampagne. Ob Eigenschaften wie `IsAdmin` im verwendeten Modul vorhanden sind, prüfen Sie mit `Get-Member`.

### Typische Fehler und Stolperfallen.

Ein Fehler ist, MFA mit „irgendein zweiter Faktor“ gleichzusetzen und SMS für Administratoren zuzulassen. Zweitens wird das Helpdesk-Verfahren zur Schwachstelle: Wer den Support überzeugt, einen neuen Faktor zu registrieren, umgeht jede Technik. Drittens werden Dienstkonten und Notfallkonten nicht bedacht. Viertens wird die Registrierung nicht überwacht, sodass Angreifer mit einem erbeuteten Kennwort ihren eigenen zweiten Faktor eintragen können.

**Falsch und richtig: Registrierung schuetzen**

```powershell
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

Die richtige Variante nutzt die Benutzeraktion „Sicherheitsinformationen registrieren“ und blockiert sie außerhalb vertrauter Orte, wobei neue Mitarbeitende über ein Temporary Access Pass im Büro registrieren. Das Beispiel ist zur Veranschaulichung gedacht; prüfen Sie die genaue Zusammenstellung der Bedingungen im Testtenant.

### Praxisbezug.

Die Einführung läuft in Wellen: Administratoren zuerst (phishing-resistent), dann sensible Gruppen, dann alle. Parallel wird der Helpdesk geschult. Messen Sie monatlich Abdeckung und Anmeldeprobleme. Die Ergebnisse gehören in die Governance-Kennzahlen (Modul 9). Kommunizieren Sie früh, denn MFA ist für Beschäftigte die sichtbarste Sicherheitsmaßnahme.

## 8.4 Defender Integration

*Microsoft Defender* ist kein einzelnes Produkt, sondern eine Familie, die in der Defender-XDR-Plattform (Extended Detection and Response) zusammenläuft. Für die M365-Governance sind vier Teile besonders wichtig. *Defender für Office 365* schützt E-Mail und Zusammenarbeit vor Phishing, Schadsoftware und gefährlichen Links (Safe Links, Safe Attachments, Anti-Phishing). *Defender für Endpoint* schützt und überwacht Geräte. *Defender für Identity* erkennt Angriffe auf lokale Verzeichnisdienste, und *Defender für Cloud Apps* macht Cloud-Anwendungen sichtbar und steuerbar. Die Plattform korreliert Warnungen aus allen Quellen zu *Vorfällen* (Incidents), sodass ein Angriff als zusammenhängende Geschichte sichtbar wird, statt als Dutzende Einzelwarnungen.

Für die Governance steht nicht die Jagd auf Angreifer im Vordergrund, sondern die Frage, wie die Schutzfunktionen konfiguriert, betrieben und nachgewiesen werden. Wer bearbeitet Vorfälle, in welcher Zeit, nach welchem Ablauf? Welche Voreinstellungen gelten für den Schutz der E-Mail? Wie hängen Defender und Entra zusammen (Signale aus Defender fließen in Richtlinien für bedingten Zugriff, etwa über Gerätezustand und Benutzerrisiko)? Und wie werden die Berechtigungen im Sicherheitsportal vergeben, die viele sensible Daten sichtbar machen?

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Schutz von E-Mail nennt *voreingestellte Sicherheitsrichtlinien* (Preset Security Policies) in den Stufen „Standard“ und „Strict“. Sie bündeln empfohlene Einstellungen für Anti-Spam, Anti-Malware, Anti-Phishing und (mit Defender für Office 365) Safe Links und Safe Attachments, sodass nicht jede Einzeleinstellung selbst gepflegt werden muss. Dazu kommen die integrierte Schutzstufe und Konfigurationsanalysen, die Abweichungen vom empfohlenen Stand anzeigen. Lizenzen bestimmen, welche Teile verfügbar sind; prüfen Sie dies vor der Zusage an Fachbereiche.

Der Governance-Ansatz lautet daher: Standardstufe für alle, strengere Stufe für definierte Benutzergruppen (zum Beispiel Geschäftsleitung, Finanzen, Personalwesen als bevorzugte Angriffsziele), Priority Accounts zur besseren Überwachung dieser Personen, und eine klare Zuordnung der Vorfallsbearbeitung (Security Operations im Haus oder externer Dienstleister). Die Verknüpfung zu den Aufbewahrungsfristen ist zu bedenken: Wie lange bleiben Vorfälle, Warnungen und Untersuchungsdaten verfügbar?

Das Skript liest die letzten neuen Warnungen über die Sicherheitsschnittstelle von Microsoft Graph und fasst sie nach Schweregrad und Dienstquelle zusammen. Das ergibt ein Bild für die tägliche Übergabe im Betrieb und zeigt, ob eine Quelle plötzlich still ist oder überraschend viel meldet. Die Abfrage verwendet `Get-MgSecurityAlertV2` mit dem Filter auf Status und Erstellungsdatum. Erforderlich ist die Berechtigung `SecurityAlert.Read.All`.

**Get-DefenderAlertSummary.ps1**

```powershell
param([int]$Tage = 7)

Connect-MgGraph -Scopes "SecurityAlert.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddDays(-$Tage).ToString("yyyy-MM-ddTHH:mm:ssZ")
$alarme = Get-MgSecurityAlertV2 -Filter "createdDateTime ge $seit" -All

if (-not $alarme) { Write-Host "Keine Warnungen im Zeitraum."; return }

"--- Nach Schweregrad ---"
$alarme | Group-Object Severity | Sort-Object Name |
    Select-Object Name, Count | Format-Table -AutoSize

"--- Nach Quelle und Status ---"
$alarme | Group-Object ServiceSource, Status |
    Select-Object Name, Count | Sort-Object Count -Descending | Format-Table -AutoSize

"--- Hoch/Kritisch und noch nicht geloest ---"
$alarme | Where-Object { $_.Severity -in "high","critical" -and $_.Status -ne "resolved" } |
    Select-Object CreatedDateTime, ServiceSource, Title, Status |
    Sort-Object CreatedDateTime | Format-Table -AutoSize -Wrap
```

Der Filter nutzt UTC im ISO-Format. Die Gruppierung nach Schweregrad liefert die Verteilung; nach Quelle und Status zeigt sie, welcher Dienst Warnungen liefert und was offen ist. Der letzte Block ist die Arbeitsliste: schwerwiegende Warnungen, die nicht gelöst sind. Eine wachsende Liste in diesem Block ist ein Hinweis auf Kapazitätsprobleme im Betrieb.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler: Schutzfunktionen sind lizenziert, aber nicht aktiviert oder nicht auf alle Benutzer angewendet. Zweitens bleiben benutzerdefinierte Ausnahmen (Allow-Listen für Absender) jahrelang stehen. Drittens liest niemand die Warnungen, weil die Menge zu groß ist; dann sollte man Regeln feiner stellen und Automatisierungen nutzen. Viertens fehlt die Rollenzuordnung im Sicherheitsportal, und alle Administratoren sehen alles.

**Falsch und richtig: Schutz fuer alle Benutzer pruefen**

```powershell
# FALSCH: annehmen, dass der Schutz "irgendwie" gilt
# (kein Nachweis, welche Benutzer unter welcher Richtlinie stehen)

# RICHTIG: Voreingestellte Richtlinien und ihre Regeln lesen
Connect-ExchangeOnline
Get-EOPProtectionPolicyRule | Select-Object Name, State, Priority, SentTo, SentToMemberOf
Get-ATPProtectionPolicyRule | Select-Object Name, State, Priority
```

Die Abfragen zeigen, welche voreingestellten Richtlinien aktiv sind und für welche Empfänger sie gelten. Für den Nachweis speichert man das Ergebnis mit Datum. Die genauen Namen der Regeln in Ihrem Tenant können abweichen.

### Praxisbezug.

In Projekten wird oft gefragt: „Haben wir Defender, und schützt es uns?“ Beantworten Sie die Frage mit einer Liste: Welche Produkte sind lizenziert, aktiviert, für welche Benutzer und Geräte konfiguriert, wer sieht die Vorfälle? Das Ergebnis ist die Grundlage für die Defender-Berichte in Modul 9.

## 8.5 Device Compliance

Die stärkste Anmeldung hilft wenig, wenn das Gerät, auf dem sie stattfindet, mit Schadsoftware infiziert oder ungeschützt ist. *Gerätekonformität* (Device Compliance) bewertet deshalb Geräte anhand von Regeln und macht das Ergebnis für Zugriffsentscheidungen nutzbar. Verwaltet wird dies in Microsoft Intune: Eine *Konformitätsrichtlinie* (Compliance Policy) beschreibt Anforderungen an ein Gerät, zum Beispiel Festplattenverschlüsselung, aktivierter Virenschutz, Mindestversion des Betriebssystems, Gerätesperre mit PIN, Jailbreak-Erkennung bei Mobilgeräten. Das Gerät meldet seinen Zustand, Intune bewertet ihn und setzt den Status auf konform oder nicht konform. Der bedingte Zugriff kann dann verlangen, dass nur konforme Geräte auf bestimmte Anwendungen zugreifen.

Dazu gehört ein Konzept für Abweichungen. Wenn ein Gerät nicht konform wird, geschieht nicht sofort ein Zugriffsentzug, sondern eine Abfolge von Aktionen: sofort Benachrichtigung des Benutzers, nach einer Karenzfrist (Grace Period) Markierung als nicht konform, nach weiterer Frist Sperre des Zugriffs oder Zurücksetzen des Geräts. Die Karenzfrist verhindert, dass ein vorübergehender Zustand (laufende Aktualisierung) einen Produktivitätsausfall erzeugt. Konformität und Konfiguration unterscheiden sich: Konfigurationsprofile setzen Einstellungen, Konformitätsrichtlinien prüfen sie und bewerten das Ergebnis.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu Intune-Konformitätsrichtlinien erfolgt die Bewertung je Plattform (Windows, macOS, iOS, Android) mit eigenen Einstellungsgruppen, und eine Richtlinie ohne Zuweisung wirkt nicht. Ein Gerät ohne zugewiesene Konformitätsrichtlinie wird nach einer tenantweiten Einstellung entweder als konform oder als nicht konform behandelt, was ein häufig übersehener Schalter ist. Die Dokumentation beschreibt Aktionen bei Nichtkonformität (E-Mail, Markierung, Zurückziehen) mit Fristen und die Verbindung zum bedingten Zugriff. Für die Berichtsansicht stehen Auswertungen im Intune-Portal und über Microsoft Graph zur Verfügung.

Das Governance-Konzept gliedert sich in drei Entscheidungen. Welche Gerätearten gibt es (firmeneigen, privat mit Registrierung, nicht verwaltet), und welcher Zugriff ist für jede erlaubt? Welche Mindestanforderungen gelten, und wie werden sie begründet (Verschlüsselung und aktuelle Betriebssystemversion sind fast überall vertretbar)? Und wie verläuft die Eskalation bei Nichtkonformität, einschließlich der Unterstützung der Benutzer? Ohne das letzte Element entsteht Ärger, denn Benutzer ohne Hilfe empfinden Sperren als Willkür.

Das Skript legt eine Konformitätsrichtlinie für Windows an und liest anschließend nicht konforme Geräte aus. Es nutzt die Graph-Schnittstelle direkt (`Invoke-MgGraphRequest`), weil sich der Objekttyp der Richtlinie über den Typhinweis `@odata.type` bestimmt. Die Richtlinie verlangt Verschlüsselung (BitLocker), sicheren Start, Kennwort und eine Mindestversion. Nach 24 Stunden Karenz wird das Gerät als nicht konform markiert. Berechtigungen: `DeviceManagementConfiguration.ReadWrite.All` und `DeviceManagementManagedDevices.Read.All`.

**New-WindowsCompliance.ps1**

```powershell
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All",
                        "DeviceManagementManagedDevices.Read.All" -NoWelcome

$body = @{
    "@odata.type"        = "#microsoft.graph.windows10CompliancePolicy"
    displayName          = "Windows Basis-Konformitaet"
    description          = "BitLocker, Secure Boot, Kennwort, Mindest-OS"
    passwordRequired     = $true
    bitLockerEnabled     = $true
    secureBootEnabled    = $true
    osMinimumVersion     = "10.0.19045"
    scheduledActionsForRule = @(
        @{
            ruleName = "PasswordRequired"
            scheduledActionConfigurations = @(
                @{ actionType = "block"; gracePeriodHours = 24 }
            )
        }
    )
}

$neu = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" `
    -Body ($body | ConvertTo-Json -Depth 6) -ContentType "application/json"
"Angelegt: $($neu.displayName) ($($neu.id))"

"--- Nicht konforme Geraete ---"
$geraete = Get-MgDeviceManagementManagedDevice -Filter "complianceState eq 'noncompliant'" -All
$geraete | Select-Object DeviceName, UserPrincipalName, OperatingSystem, OsVersion, LastSyncDateTime |
    Sort-Object LastSyncDateTime | Format-Table -AutoSize
"Anzahl: {0}" -f @($geraete).Count
```

Die Richtlinie wird als Hashtable aufgebaut und mit `ConvertTo-Json -Depth 6` umgewandelt, wobei die Tiefe wichtig ist, weil verschachtelte Objekte sonst abgeschnitten werden. Der Block `scheduledActionsForRule` legt fest, dass nach 24 Stunden Karenz die Markierung als nicht konform erfolgt. Die Mindestversion ist ein Beispielwert, den Sie anpassen. Nach dem Anlegen muss die Richtlinie noch einer Gruppe zugewiesen werden, sonst wirkt sie nicht; diesen Schritt führt man im Portal oder per Zuweisungsaufruf durch. Die Abfrage am Ende listet Geräte, die nicht konform sind.

### Typische Fehler und Stolperfallen.

Typische Fehler: Richtlinien ohne Zuweisung, Karenzfristen auf null (Sofortsperre), zu strenge Mindestversionen, die den Betrieb stören, und der Tenant-Schalter für Geräte ohne Richtlinie. Außerdem werden Konformität und bedingter Zugriff nicht gemeinsam getestet: Die Anforderung „konformes Gerät“ in einer CA-Richtlinie sperrt alle Benutzer mit nicht registrierten Geräten.

**Falsch und richtig: Karenz und Zuweisung**

```powershell
# FALSCH: Sofortsperre und keine Zuweisung
@{ ruleName = "PasswordRequired"
   scheduledActionConfigurations = @(@{ actionType = "block"; gracePeriodHours = 0 }) }

# RICHTIG: Karenz, dann Zuweisung an eine Pilotgruppe pruefen
@{ ruleName = "PasswordRequired"
   scheduledActionConfigurations = @(@{ actionType = "block"; gracePeriodHours = 24 }) }
# Zuweisung im Portal (Intune > Geraete > Konformitaet > Zuweisungen) pruefen
```

Der Vergleich zeigt: Eine kleine Karenzfrist reicht oft, um die meisten harmlosen Zustände zu überbrücken. Die Zuweisung an eine Pilotgruppe ist eine bewusste Entscheidung, nicht ein Nachtrag.

### Praxisbezug.

In der Praxis führt man Gerätekonformität in Stufen ein: erst Bericht über Konformität, dann CA für sensible Anwendungen, dann breiter. Parallel wird ein Prozess für private Geräte (BYOD) mit Mobile Application Management definiert. Berichtszahlen (Konformitätsquote) gehören in die Monatsberichte (Modul 9).

## 8.6 Privileged Access

Privilegierter Zugriff ist der Zugriff mit Rechten, die große Wirkung haben: Globale Administratoren, Exchange-Administratoren, Rollen für Richtlinien, Vorgaben und Schlüsselmaterial. Ein kompromittiertes Adminkonto ist das Ziel fast jedes ernsthaften Angriffs. Die Grundlagen (Rollen, Rollenmodell, Privileged Identity Management mit Just-in-Time-Aktivierung, Zugriffsüberprüfungen) wurden in Modul 2 erklärt und werden hier nicht wiederholt. Diese Lerneinheit ergänzt den Sicherheitsblickwinkel: Wie reduziert man die Angriffsfläche privilegierter Konten, wie schützt man sie, und wie erkennt man Missbrauch?

Die wichtigsten Bausteine sind folgende. Erstens *getrennte Administratorkonten*: Ein Administrator hat ein normales Konto für E-Mail und Surfen und ein separates Konto für Verwaltungsaufgaben, das keine Postfachlizenz hat. Zweitens *geringste Rechte*: Jede Person erhält die schwächste Rolle, mit der ihre Aufgabe zu lösen ist, nicht den Globalen Administrator, weil das einfacher ist. Drittens *zeitlich begrenzte Rechte* durch Privileged Identity Management. Viertens *starke Anmeldung*: phishing-resistente MFA für alle Rollen mit Privilegien, per CA-Richtlinie erzwungen. Fünftens *geschützte Arbeitsumgebung*: Verwaltung nur von verwalteten, gehärteten Geräten (Privileged Access Workstations, mindestens aber konforme Geräte). Sechstens *Notfallkonten* (Break Glass) mit sehr langen Kennwörtern, dokumentierter Verwahrung und Alarm bei jeder Nutzung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu privilegiertem Zugriff und zum Schutz von Administratorkonten empfiehlt unter anderem, die Zahl der Konten mit der Rolle „Globaler Administrator“ gering zu halten, Rollen mit geringsten Rechten zu verwenden und Administratoren mit phishing-resistenter MFA zu schützen. Die Dokumentation zu Notfallzugriffskonten rät, diese ausdrücklich von Richtlinien für bedingten Zugriff auszunehmen, Anmeldungen zu überwachen und die Zugangsdaten sicher getrennt aufzubewahren. Die genaue Empfehlung zur Höchstzahl und die Namen der Rollen entnehmen Sie der aktuellen Dokumentation.

Zur Governance gehört, regelmäßig zu prüfen, ob die Regeln eingehalten werden. Das Skript listet Mitglieder der Rolle Globaler Administrator auf, zeigt ob sie MFA registriert haben und markiert Auffälligkeiten: zu viele Konten, Konten ohne MFA, Gastkonten und Konten, die erkennbar normale Benutzerkonten sind. Es nutzt `Get-MgDirectoryRole` und `Get-MgDirectoryRoleMember` sowie den Registrierungsbericht. Berechtigungen: `RoleManagement.Read.Directory`, `User.Read.All`, `AuditLog.Read.All`.

**Test-GlobalAdmins.ps1**

```powershell
param([int]$Maximum = 5)

Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All","AuditLog.Read.All" -NoWelcome

$rolle = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'"
if (-not $rolle) { throw "Rolle nicht aktiviert oder nicht gefunden." }

$mitglieder = Get-MgDirectoryRoleMember -DirectoryRoleId $rolle.Id -All
$reg = @{}
Get-MgReportAuthenticationMethodUserRegistrationDetail -All |
    ForEach-Object { $reg[$_.Id] = $_ }

$bericht = foreach ($m in $mitglieder) {
    $u = Get-MgUser -UserId $m.Id -Property DisplayName,UserPrincipalName,UserType,AccountEnabled,Mail
    $r = $reg[$m.Id]
    [pscustomobject]@{
        Konto      = $u.UserPrincipalName
        Typ        = $u.UserType
        Aktiv      = $u.AccountEnabled
        MfaRegistr = if ($r) { $r.IsMfaRegistered } else { "unbekannt" }
        HatPostfach = [bool]$u.Mail
    }
}

$bericht | Format-Table -AutoSize
if (@($bericht).Count -gt $Maximum) { Write-Warning "Mehr als $Maximum Globale Administratoren: $(@($bericht).Count)" }
$bericht | Where-Object { $_.MfaRegistr -ne $true }       | ForEach-Object { Write-Warning "Keine MFA: $($_.Konto)" }
$bericht | Where-Object { $_.Typ -eq "Guest" }            | ForEach-Object { Write-Warning "Gastkonto: $($_.Konto)" }
$bericht | Where-Object { $_.HatPostfach }                | ForEach-Object { Write-Warning "Admin mit Postfach: $($_.Konto)" }
```

Das Skript baut zuerst einen Nachschlagetisch der Registrierungen auf, damit es nicht für jedes Konto eine eigene Abfrage braucht. Danach bildet es pro Mitglied eine Zeile und gibt Warnungen für die vier Auffälligkeiten aus. Beachten Sie: Es zeigt nur aktive Rollenzuweisungen, berechtigte Zuweisungen in PIM erscheinen dort nicht; dafür gibt es eigene Abfragen (siehe Modul 2).

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Gewohnheit: Man arbeitet täglich mit dem Adminkonto, liest damit E-Mails und öffnet Links. Zweitens werden Rollen dauerhaft zugewiesen, obwohl sie selten gebraucht werden. Drittens fehlt die Aufsicht über Dienstprinzipale und Anwendungen mit Administratorberechtigungen, die ebenso privilegiert sind. Viertens ist das Notfallkonto vergessen oder dessen Zugangsdaten sind nicht auffindbar.

**Falsch und richtig: Rollen und Konten**

```powershell
# FALSCH: eigenes Alltagskonto zum Globalen Administrator machen
New-MgDirectoryRoleMemberByRef -DirectoryRoleId $rolle.Id `
    -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($alltagskonto.Id)" }

# RICHTIG: dediziertes Adminkonto, geringste Rolle, ueber PIM berechtigt (siehe Modul 2)
# z. B. Exchange-Administrator statt Globaler Administrator, zeitlich begrenzt aktivierbar
```

Die korrekte Variante beschreibt das Prinzip: dediziertes Konto, geringstmögliche Rolle, zeitlich begrenzte Aktivierung. Das Zuweisungsbeispiel oben soll nicht ausgeführt werden; es zeigt nur, wie leicht der Fehler zu machen ist.

### Praxisbezug.

In Audits ist die Liste der privilegierten Konten fast immer der erste Prüfpunkt. Halten Sie sie aktuell, dokumentieren Sie den Zweck jedes Kontos, und überprüfen Sie sie vierteljährlich mit einer Zugriffsüberprüfung. Prüfen Sie auch das Verfahren im Ernstfall: Wer holt die Notfallkonto-Zugangsdaten aus dem Tresor, und wann wurde das zuletzt geübt?

## 8.7 Security Exceptions

Keine Sicherheitsregel gilt ohne Ausnahme: das Messgerät, das keine MFA kann, die Dienstanwendung mit altem Protokoll, der Geschäftsführer, der sein privates Gerät nicht registrieren will. Ausnahmen sind nicht an sich schlecht, aber unkontrolliert werden sie zum größten Risiko, weil jede dauerhafte Ausnahme ein Loch in der Baseline bleibt. Eine *Ausnahmenverwaltung* (Exception Management) stellt sicher, dass Ausnahmen bewusst beantragt, begründet, genehmigt, befristet, kompensiert und überprüft werden.

Ein tragfähiger Prozess hat sieben Elemente. Der *Antrag* nennt Betroffene, Regel, Begründung und gewünschte Dauer. Eine *Risikobewertung* schätzt Wahrscheinlichkeit und Schaden ab. Die *Genehmigung* erfolgt durch eine Person mit Risikoverantwortung (nicht durch den Antragsteller und nicht allein durch die IT). *Kompensierende Maßnahmen* verringern das Restrisiko, zum Beispiel Standortbeschränkung, zusätzliche Überwachung, eingeschränkte Rechte. Die *Befristung* legt ein Ablaufdatum fest, spätestens ein Jahr. Die *technische Umsetzung* erfolgt über Ausnahmegruppen mit Namenskonvention, nicht über einzelne Benutzer in Richtlinien. Die *Überprüfung* prüft vor Ablauf, ob die Ausnahme noch gebraucht wird.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum bedingten Zugriff beschreibt Ausschlüsse (Exclusions) von Benutzern, Gruppen und Rollen in jeder Richtlinie und empfiehlt, Ausschlüsse über Gruppen zu verwalten, damit sie überprüfbar bleiben. Zugriffsüberprüfungen in Entra ID Governance können Mitgliedschaften solcher Ausnahmegruppen regelmäßig bestätigen lassen; die Funktion ist lizenzabhängig. Im Secure Score erlaubt der Status „Risiko akzeptiert“ eine dokumentierte Ablehnung einer Maßnahme. Prüfen Sie Details und Lizenzvoraussetzungen in der aktuellen Dokumentation.

Die technische Gestaltung ist einfach, wenn man sie konsequent hält. Für jede Richtlinie gibt es eine Ausnahmegruppe mit sprechendem Namen („SEC-EXC-CA001-LegacyAuth“), deren Besitzer die genehmigende Person ist. Die Gruppe hat Beschreibung und Ablaufdatum im Namen oder in einem Attribut. Die Mitgliedschaft wird per Zugriffsüberprüfung bestätigt. Alle Ausschlüsse in Richtlinien verweisen nur auf diese Gruppen, nie auf einzelne Konten (mit Ausnahme der Notfallkonten). Dadurch beantwortet eine einzige Abfrage die Frage „Wer ist wovon ausgenommen?“.

Das Skript beantwortet genau diese Frage: Es liest alle CA-Richtlinien und listet pro Richtlinie die ausgeschlossenen Benutzer, Gruppen und Rollen, löst Gruppen in Mitgliederzahlen auf und meldet direkte Benutzerausschlüsse als Verstoß gegen die Konvention. Die Berechtigungen sind `Policy.Read.All` und `Group.Read.All`.

**Get-CaExclusions.ps1**

```powershell
Connect-MgGraph -Scopes "Policy.Read.All","Group.Read.All" -NoWelcome

$zeilen = foreach ($p in Get-MgIdentityConditionalAccessPolicy -All) {
    $u = $p.Conditions.Users
    foreach ($id in $u.ExcludeUsers) {
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Benutzer"; Name = $id; Mitglieder = $null }
    }
    foreach ($gid in $u.ExcludeGroups) {
        $g = Get-MgGroup -GroupId $gid -ErrorAction SilentlyContinue
        $n = @(Get-MgGroupMember -GroupId $gid -All -ErrorAction SilentlyContinue).Count
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Gruppe"
                           Name = $(if ($g) { $g.DisplayName } else { $gid }); Mitglieder = $n }
    }
    foreach ($rid in $u.ExcludeRoles) {
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Rolle"; Name = $rid; Mitglieder = $null }
    }
}

$zeilen | Sort-Object Richtlinie, Art | Format-Table -AutoSize

$direkt = $zeilen | Where-Object Art -eq "Benutzer"
if ($direkt) {
    Write-Warning "$(@($direkt).Count) direkte Benutzerausschluesse (Notfallkonten ausgenommen pruefen)."
}
```

Die Schleife geht jede Richtlinie durch und erzeugt je Ausschluss eine Zeile. Gruppen werden in Anzeigenamen und Mitgliederzahl aufgelöst. Direkte Benutzerausschlüsse erhalten eine Warnung, weil sie sich schwer überprüfen lassen. Das Ergebnis gehört vierteljährlich in den Governance-Bericht.

### Typische Fehler und Stolperfallen.

Typisch sind Ausnahmen ohne Ablaufdatum, Ausnahmen aufgrund von Zuruf („nur schnell“), Ausnahmegruppen mit vielen Mitgliedern, die niemand kennt, und Ausnahmen, die ein Vorgesetzter für sich selbst genehmigt. Ebenso gefährlich ist, Ausnahmen für ganze Anwendungen statt für einzelne Benutzer zu gewähren.

**Falsch und richtig: Ausnahme ueber Gruppe**

```powershell
# FALSCH: einzelnes Konto direkt ausgeschlossen, keine Frist, kein Besitzer
$bedingungen.users.excludeUsers = @("a3f1c0de-0000-0000-0000-000000000000")

# RICHTIG: Ausnahmegruppe mit Besitzer und Beschreibung inkl. Ablaufdatum
New-MgGroup -DisplayName "SEC-EXC-CA001-LegacyAuth" `
    -Description "Ausnahme Messgeraet Labor, genehmigt von R. Beispiel, laeuft ab 2027-03-31" `
    -MailEnabled:$false -SecurityEnabled -MailNickname "sec-exc-ca001"
```

Die Gruppe trägt Zweck, Genehmiger und Ablaufdatum in der Beschreibung. Eine Zugriffsüberprüfung auf diese Gruppe und ein Eintrag im Ausnahmenregister vervollständigen das Bild. Das Register kann eine einfache Liste sein, solange sie gepflegt wird.

### Praxisbezug.

Das Thema ist einer der wichtigsten Prüfpunkte in Audits: „Zeigen Sie mir alle Ausnahmen von Ihrer MFA-Richtlinie.“ Wer eine Gruppenstruktur und ein Register hat, antwortet in Minuten. Planen Sie außerdem eine Ablaufkontrolle: Eine monatliche Liste der Ausnahmen, die in den nächsten 30 Tagen ablaufen.

## 8.8 Security-Troubleshooting

Sicherheitsrichtlinien erzeugen zwei Arten von Fehlermeldungen: berechtigte Blockaden („wir wollten, dass das scheitert“) und unerwünschte („das hätte funktionieren sollen“). Das Troubleshooting unterscheidet diese beiden Fälle anhand der Anmeldeprotokolle. Dort steht für jede Anmeldung, welche CA-Richtlinien angewendet wurden und mit welchem Ergebnis: Erfolg, Fehler, nicht angewendet, nur Bericht. Der erste Schritt bei jeder Beschwerde ist daher, die konkrete Anmeldung des Benutzers im Anmeldeprotokoll zu finden (Zeitpunkt, Anwendung), und nicht, Richtlinien zu ändern.

Die häufigsten Fehlerbilder lassen sich in fünf Gruppen ordnen. Erstens: MFA wird verlangt, kann aber nicht erbracht werden (kein registrierter Faktor, Gerät verloren). Zweitens: Der Zugriff wird durch eine CA-Richtlinie blockiert (Standort, Gerät, Altprotokoll). Drittens: Das Gerät gilt als nicht konform, und die Anforderung „konformes Gerät“ greift. Viertens: Das Konto ist durch Risikoerkennung (Identity Protection) blockiert oder muss das Kennwort ändern. Fünftens: Eine Anwendung unterstützt das erforderliche Verfahren nicht (Altprotokoll, alte Clients, Dienstkonto). Jede Gruppe hat andere Prüfpunkte und Lösungswege.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Fehlersuche bei bedingtem Zugriff empfiehlt, im Anmeldeprotokoll den Reiter zum bedingten Zugriff zu öffnen, der alle ausgewerteten Richtlinien und deren Ergebnis zeigt, und das Werkzeug „What If“ zur Simulation zu nutzen. Außerdem beschreibt sie die Arbeitsmappen (Workbooks) zur Wirkungsanalyse von Richtlinien. Fehlercodes in den Anmeldeprotokollen (zum Beispiel für unterbrochene Anmeldung durch MFA-Anforderung oder durch Blockade) sind in der Dokumentation der Fehlercodes nachzuschlagen; Zuordnungen von Codes zu Ursachen werden hier bewusst nicht aus dem Gedächtnis wiedergegeben.

Die Methode lautet: Erwartung klären (Welche Anwendung, welches Gerät, welcher Ort, welche Uhrzeit?), Anmeldung finden, Ergebnis der Richtlinien lesen, Ursache zuordnen, genau eine Änderung vornehmen, erneut testen. Bei unerklärlichen Fällen hilft die Simulation mit „What If“: Man gibt Benutzer, Anwendung, Gerät, Ort ein und sieht, welche Richtlinien greifen würden. Wenn mehrere Richtlinien greifen, gilt, dass die Anforderungen sich addieren: Blockade gewinnt immer gegen Erlaubnis, und alle verlangten Kontrollen müssen erfüllt sein.

Das Skript sucht die letzten Anmeldungen eines Benutzers und zeigt, welche CA-Richtlinien mit welchem Ergebnis angewendet wurden. Es nutzt `Get-MgAuditLogSignIn` und gibt je Anmeldung die Anwendung, den Status und die Liste der Richtlinienergebnisse aus. Erforderlich ist `AuditLog.Read.All`; für Anmeldeprotokolle ist zusätzlich eine passende Rolle nötig (zum Beispiel Berichtsleser).

**Get-SignInCaDetails.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Benutzer,
    [int]$Stunden = 24
)

Connect-MgGraph -Scopes "AuditLog.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddHours(-$Stunden).ToString("yyyy-MM-ddTHH:mm:ssZ")
$logs = Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$Benutzer' and createdDateTime ge $seit" -Top 25

if (-not $logs) { Write-Host "Keine Anmeldungen im Zeitraum."; return }

foreach ($l in $logs | Sort-Object CreatedDateTime) {
    "{0:u}  {1}  CA-Status: {2}  Fehlercode: {3}" -f $l.CreatedDateTime, $l.AppDisplayName,
        $l.ConditionalAccessStatus, $l.Status.ErrorCode
    foreach ($p in $l.AppliedConditionalAccessPolicies) {
        "      - {0}: {1}" -f $p.DisplayName, $p.Result
    }
    if ($l.Status.FailureReason) { "      Grund: " + $l.Status.FailureReason }
}
```

Das Skript filtert nach Benutzer und Zeitraum, begrenzt die Menge und zeigt je Anmeldung Kopfzeile, Richtlinienergebnisse und Fehlergrund. Das Ergebnis lässt sich direkt in ein Ticket übernehmen. Ergebnisse wie „success“, „failure“, „notApplied“ und „reportOnlySuccess“ zeigen, ob eine Richtlinie gewirkt hat oder im Berichtsmodus nur gemeldet hat.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Richtlinien auf Verdacht auszuschalten, um das Problem zu lösen. Das beseitigt den Schutz für alle und lässt die Ursache offen. Zweitens wird nach dem Benutzer gefragt statt in den Anmeldeprotokollen nachgesehen. Drittens wird die Verzögerung übersehen: Neue Richtlinien und Gerätezustand wirken zeitverzögert, und Tests unmittelbar nach der Änderung täuschen. Viertens wird mit einem Administratorkonto getestet, für das andere Richtlinien gelten.

**Falsch und richtig: Ursache vor Aenderung**

```powershell
# FALSCH: Richtlinie abschalten, "damit es geht"
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $id -State "disabled"

# RICHTIG: erst die Anmeldung lesen, dann gezielt eine Ausnahme oder Korrektur planen
.\Get-SignInCaDetails.ps1 -Benutzer "anna@contoso.com" -Stunden 4
# ... Ursache zuordnen (Gerät? Standort? Altprotokoll?) und im Ausnahmeprozess behandeln
```

Die richtige Variante liest das Anmeldeprotokoll, bevor sie handelt. Wenn eine Ausnahme nötig ist, läuft sie durch den Prozess aus Lerneinheit 8.7.

### Praxisbezug.

Servicedesk und Sicherheit brauchen eine gemeinsame Checkliste mit fünf Fragen und dem Verweis auf die Anmeldeprotokolle. Legen Sie fest, wer Anmeldeprotokolle lesen darf, denn sie enthalten personenbezogene Daten (Datenschutz). Eine Auswertung der häufigsten Blockadegründe pro Monat zeigt, wo Dokumentation, Schulung oder Richtlinie zu verbessern sind.

> **Merke**
>
> Sicherheit ist dann Governance, wenn sie gemessen (Secure Score, Abdeckung), durchgesetzt (bedingter Zugriff, Gerätekonformität), geschützt (privilegierte Konten) und kontrolliert abweichend (Ausnahmen mit Frist) ist. Fehlt eines davon, entsteht entweder Schein-Sicherheit oder dauerhafter Ärger.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Was misst der Secure Score, und warum ist ein Verlauf aussagekräftiger als ein einzelner Wert?

**Aufgabe 2 (leicht).** Nennen Sie fünf Richtlinien einer Conditional-Access-Baseline und erklären Sie, warum Notfallkonten ausgenommen werden.

**Aufgabe 3 (leicht).** Erklären Sie den Unterschied zwischen MFA und phishing-resistenter MFA. Welche der Verfahren SMS, Authenticator-Push, FIDO2-Schlüssel gehören zur zweiten Gruppe?

**Aufgabe 4 (mittel).** Schreiben Sie ein Skript, das alle Conditional-Access-Richtlinien mit Name und Zustand auflistet und diejenigen hervorhebt, die im Berichtsmodus sind.

**Aufgabe 5 (mittel).** Entwerfen Sie eine Konformitätsrichtlinie für Smartphones (Anforderungen, Karenzfrist, Aktionen bei Nichtkonformität) und begründen Sie jede Anforderung kurz.

**Aufgabe 6 (mittel).** Beschreiben Sie in fünf Schritten einen Ausnahmeprozess für eine Messgerätekonto, das keine MFA kann. Welche kompensierenden Maßnahmen schlagen Sie vor?

**Aufgabe 7 (schwer).** Schreiben Sie ein Skript, das Mitglieder aller Ausnahmegruppen (Namen beginnen mit SEC-EXC-) ausliest und Konten meldet, die in mehr als zwei Ausnahmegruppen sind.

**Aufgabe 8 (schwer).** Ein Vertriebsmitarbeiter kann sich nicht mehr in Teams anmelden. Beschreiben Sie das Vorgehen mit den Anmeldeprotokollen, nennen Sie vier mögliche Ursachen und wie Sie jeweils entscheiden, ob eine Ausnahme angemessen ist.

## Lösungen

**Lösung 1.** Der Secure Score misst den Anteil umgesetzter Sicherheitsmaßnahmen an den möglichen Maßnahmen als Prozentwert. Ein Verlauf zeigt die Wirkung von Maßnahmen und macht Veränderungen sichtbar, die durch neue Maßnahmen von Microsoft entstehen. Ein Einzelwert ohne Vergleich sagt wenig über Fortschritt oder Rückschritt.

**Lösung 2.** Beispiele: MFA für Administratoren, MFA für alle Benutzer, Legacy-Authentifizierung blockieren, MFA bei Anmelderisiko, konformes Gerät für sensible Anwendungen, Registrierung der Sicherheitsinformationen schützen. Notfallkonten werden ausgenommen, damit bei einer Fehlkonfiguration oder einem Ausfall des zweiten Faktors immer noch ein Administratorzugang bleibt. Ihre Nutzung wird dafür besonders überwacht.

**Lösung 3.** MFA verlangt mindestens zwei Faktoren; phishing-resistente MFA bindet die Anmeldung zusätzlich kryptografisch an die echte Seite, sodass gefälschte Seiten keine nutzbaren Antworten erhalten. Zur zweiten Gruppe gehört der FIDO2-Schlüssel. SMS und Push-Bestätigung sind nicht phishing-resistent.

**Lösung 4.** Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
Get-MgIdentityConditionalAccessPolicy -All |
  Select-Object DisplayName, State,
    @{n='NurBericht'; e={ $_.State -eq 'enabledForReportingButNotEnforced' }} |
  Sort-Object NurBericht -Descending | Format-Table -AutoSize
```

Das Skript liest alle Richtlinien, berechnet eine Spalte für den Berichtsmodus und sortiert Richtlinien im Berichtsmodus nach oben.

**Lösung 5.** Beispiel: Geräte-PIN mit Mindestlänge (Schutz vor Fremdzugriff), Gerätespeicher verschlüsselt (Schutz bei Verlust), keine Jailbreak- oder Root-Erkennung (Integrität), Mindestversion des Betriebssystems (Sicherheitsupdates). Karenzfrist 24 Stunden, danach Markierung als nicht konform und E-Mail an den Benutzer, nach sieben Tagen Zugriffssperre über bedingten Zugriff. Wichtig ist die Zuweisung an eine Pilotgruppe vor dem breiten Einsatz.

**Lösung 6.** Schritte: (1) Antrag mit Gerät, Zweck, Dauer. (2) Risikobewertung (Konto mit Kennwort ohne MFA). (3) Genehmigung durch die Fachbereichsleitung und Security. (4) Umsetzung über Ausnahmegruppe mit Ablaufdatum. (5) Überprüfung vor Ablauf. Kompensierend: Zugriff nur von der festen IP-Adresse des Labors, minimale Rechte (nur eine Anwendung), erhöhte Überwachung der Anmeldungen, langes zufälliges Kennwort im Tresor, Austausch des Geräts im Plan.

**Lösung 7.** Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "startswith(displayName,'SEC-EXC-')" -All
$zeilen = foreach ($g in $gruppen) {
  Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object {
    [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $_.Id }
  }
}
$zeilen | Group-Object Id | Where-Object Count -gt 2 |
  ForEach-Object { [pscustomobject]@{ Id = $_.Name; Gruppen = ($_.Group.Gruppe -join ', ') } }
```

Das Skript sammelt alle Mitgliedschaften, gruppiert nach Konto-ID und zeigt Konten mit mehr als zwei Gruppen samt Gruppennamen.

**Lösung 8.** Vorgehen: Zeitpunkt und Anwendung erfragen, Anmeldungen der betroffenen Person im Protokoll suchen, Ergebnis jeder angewendeten Richtlinie lesen, Ursache zuordnen, einzeln beheben und testen. Mögliche Ursachen: (1) Kein registrierter zweiter Faktor, Lösung durch kontrollierte Registrierung mit Temporary Access Pass, keine Ausnahme. (2) Gerät nicht konform, Lösung durch Behebung (Update, Verschlüsselung), keine Ausnahme, höchstens kurze Karenz. (3) Zugriff aus gesperrtem Land auf Dienstreise, Lösung durch befristete, genehmigte Standortausnahme. (4) Altes Mail-Programm mit Altprotokoll, Lösung durch Umstellung auf moderne Anwendung, keine Dauerausnahme. Eine Ausnahme ist angemessen, wenn kein anderer Weg besteht, das Risiko bewertet ist, kompensierende Maßnahmen gelten und eine Frist gesetzt wird.
