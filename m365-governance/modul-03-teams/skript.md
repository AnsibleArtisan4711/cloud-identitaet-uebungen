# Modul 03 - Teams Governance und Collaboration Lifecycle

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 9 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8 Stunden. Als Richtwert für den Umfang wurde der höhere Wert (9 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**              | **Dauer (h)** | **Prio** |
|:--------|:-----------------------------|--------------:|---------:|
| 3.1     | Teams Lifecycle              |             1 |        1 |
| 3.2     | Naming und Templates         |             1 |        1 |
| 3.3     | Teams Creation Controls      |             1 |        1 |
| 3.4     | Guest und External Access    |             1 |        1 |
| 3.5     | Channels und Shared Channels |             1 |        1 |
| 3.6     | Apps und Tabs Governance     |             1 |        2 |
| 3.7     | Teams Archiving              |             1 |        2 |
| 3.8     | Teams-Troubleshooting        |             1 |        2 |
|         | **Summe laut Details**       |         **8** |          |
|         | **Dauer laut Modulblatt**    |         **9** |          |

> **Merke: Teams ist nur die Oberfläche**
>
> Ein Team ist kein eigenständiges Objekt, sondern ein Bündel aus Diensten: einer Microsoft-365-Gruppe (Identität und Mitgliedschaft), einer SharePoint-Website (Dateien), einem Gruppenpostfach und Kalender (Exchange), gegebenenfalls Planner, OneNote und Loop. Wer Teams steuert, steuert diese Bausteine. Die Grundlagen zu Gruppen, Gästen und Rollen stehen in Modul 02, auf die dieses Modul aufbaut.

## 3.1 Teams Lifecycle

Jedes Team durchläuft eine Lebensgeschichte. Es wird beantragt oder spontan angelegt, es wird mit Leben gefüllt, es altert, es wird irgendwann nicht mehr gebraucht, und es sollte dann geordnet verschwinden. In ungesteuerten Tenants fehlen die letzten Stationen fast vollständig: Teams werden angelegt und nie wieder angefasst. Nach zwei Jahren liegen Tausende Teams herum, deren Zweck und Besitzer niemand kennt. Das kostet Speicher, verwirrt Benutzer und ist ein Datenschutzproblem, weil dort Daten und Gäste ohne Zweck liegen.

Ein Teams-Lebenszyklus besteht aus fünf Phasen. In der Phase *Beantragung und Anlage* entscheidet sich, ob ein Team die richtigen Eigenschaften bekommt: Name, Besitzer, Klassifizierung, Datenschutzstufe. In der Phase *Nutzung* geschieht die eigentliche Zusammenarbeit; die Governance greift hier mit Besitzerpflege, Zugriffsüberprüfungen und Berichten. In der Phase *Inaktivität* wird erkannt, dass ein Team nicht mehr genutzt wird. In der Phase *Archivierung* wird das Team auf schreibgeschützt gestellt (Lerneinheit 3.7). In der Phase *Löschung* wird es endgültig entfernt, nachdem Aufbewahrungsfristen erfüllt sind. Zwischen allen Phasen sorgen die Ablaufrichtlinie für Microsoft-365-Gruppen (Modul 02, Lerneinheit 2.6) und die Besitzerbenachrichtigungen für Bewegung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Optionen am Ende des Lebenszyklus von Gruppen, Teams und Viva Engage beschreibt, was beim Löschen geschieht: Die zugehörige Microsoft-365-Gruppe wird zunächst *weich gelöscht* und kann 30 Tage lang wiederhergestellt werden. Verbundene Dienste (SharePoint-Website, Postfach, Planner) werden mit der Gruppe behandelt. Wichtig für die Datenschutzbetrachtung: Wird ein Team gelöscht, werden Gäste nicht automatisch aus dem Verzeichnis entfernt. Ihr Gastkonto bleibt bestehen, bis jemand es bereinigt (siehe Modul 02, Lerneinheit 2.7). Aufbewahrungsrichtlinien aus Purview (Modul 06) können das Löschen von Inhalten verhindern oder verzögern.

Warum reicht es nicht, einfach alles dem Besitzer zu überlassen? Weil Besitzer wechseln, das Team vergessen oder das Unternehmen verlassen. Governance heißt hier: Das System erinnert, entscheidet notfalls selbst und lässt eine Wiederherstellung zu. Das Prinzip kann man mit drei Fragen prüfen. Wer wird gefragt, wenn ein Team ablaufen soll? Was passiert, wenn niemand antwortet? Wie kommt man an die Daten, wenn sich die Entscheidung als falsch erweist? Gute Antworten sind: die Besitzer und ein Ersatzkontakt, das Team wird archiviert und nicht gelöscht, und die Wiederherstellung dauert Minuten und ist beschrieben.

Das folgende Skript erstellt einen Bestandsbericht über alle Teams: Anzahl der Besitzer, Mitglieder und Gäste, Datenschutzstufe und Erstellungsdatum. Er zeigt auf einen Blick, wo der Lebenszyklus klemmt, und ist die Grundlage für spätere Entscheidungen. Das Skript nutzt Microsoft Graph und fragt nur Gruppen ab, die zu einem Team gehören.

**Get-TeamsInventory.ps1**

```powershell
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All" -NoWelcome

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
         -Property Id,DisplayName,Visibility,CreatedDateTime,RenewedDateTime

$report = foreach ($t in $teams) {
    $owners  = @(Get-MgGroupOwner  -GroupId $t.Id -All)
    $members = @(Get-MgGroupMember -GroupId $t.Id -All)
    $guests  = @($members | Where-Object {
                   $_.AdditionalProperties.userType -eq 'Guest' })
    [pscustomobject]@{
        Team       = $t.DisplayName
        Sichtbar   = $t.Visibility
        Erstellt   = $t.CreatedDateTime
        Verlaengert= $t.RenewedDateTime
        Besitzer   = $owners.Count
        Mitglieder = $members.Count
        Gaeste     = $guests.Count
    }
}
$report | Sort-Object Besitzer, Erstellt | Export-Csv ".\teams-bestand.csv" -NoTypeInformation -Encoding UTF8
$report | Where-Object { $_.Besitzer -lt 2 } | Format-Table -AutoSize
```

Der Filter `resourceProvisioningOptions/Any(x:x eq 'Team')` wählt aus allen Gruppen die aus, die als Team bereitgestellt sind. Ohne diesen Filter würden auch reine Microsoft-365-Gruppen ohne Team erscheinen. Für jedes Team werden Besitzer und Mitglieder abgefragt, anschließend zählt das Skript die Gäste anhand des Benutzertyps. Die Eigenschaft `RenewedDateTime` zeigt, wann die Ablaufrichtlinie die Gruppe zuletzt verlängert hat, und ist damit ein grober Aktivitätshinweis. Der Bericht wird nach Besitzerzahl und Erstellungsdatum sortiert in eine CSV-Datei geschrieben, und die Teams mit weniger als zwei Besitzern werden am Bildschirm angezeigt. In großen Tenants dauert das Skript lange, weil für jedes Team mehrere Abfragen nötig sind; dort verwendet man Batch-Aufrufe oder die Berichte der Verwaltungsoberfläche.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Löschung ohne Archivierungsphase. Wer ein Team nach 180 Tagen Inaktivität einfach löscht, erzeugt Datenverlust und Ärger. Der zweite Fehler ist das Gegenteil: Es wird nie gelöscht, weil man Angst vor Beschwerden hat. Der dritte Fehler ist die Verwechslung von „inaktiv“ und „leise“: Ein Team, in dem selten geschrieben wird, aber Dateien gepflegt werden, ist nicht tot.

```
FALSCH:  Regel: "Teams ohne Chatnachricht seit 90 Tagen werden geloescht."
          -> Archive mit gepflegten Dokumenten verschwinden.

RICHTIG: Regel: Aktivitaet = Chat, Dateien, Besuche und Besitzerantwort.
          Ohne Aktivitaet und ohne Besitzerantwort: Archivieren (nicht loeschen).
          Loeschen erst nach weiteren 12 Monaten und Freigabe durch die Leitung.
```

### Praxisbezug.

Beginnen Sie mit dem Bestandsbericht und sprechen Sie die Zahlen mit den Verantwortlichen durch. Meist zeigt sich, dass 20 bis 40 Prozent der Teams Kandidaten für Archivierung sind. Daraus entsteht die erste Version der Lebenszyklusregeln, die Sie in Modul 10 als automatisierte Jobs (Lifecycle Jobs, Archive und Delete) umsetzen.

> **Merke**
>
> Der Lebenszyklus eines Teams hat fünf Phasen: Beantragung, Nutzung, Inaktivität, Archivierung, Löschung. Archivieren vor Löschen, Besitzer fragen, Wiederherstellung beschreiben.

## 3.2 Naming und Templates

Namen sind die Navigation von Microsoft Teams. Wer in einem Tenant mit 3000 Teams das Team „Marketing“ sucht, findet vermutlich elf: „Marketing“, „Marketing neu“, „Marketing Team“, „Marketing 2023“, „Marketing intern“. Eine Namenskonvention macht aus dieser Menge eine Struktur, in der Teams am Präfix erkennbar sind, in der sortiert und gefiltert werden kann und in der klar ist, ob ein Team eine Abteilung, ein Projekt, ein Kunde oder ein Gremium ist.

Technisch gibt es zwei Werkzeuge. Die *Namensrichtlinie* der Microsoft-365-Gruppen (Modul 02, Lerneinheit 2.6) setzt Präfix und Suffix automatisch und blockiert Wörter. Sie gilt für alle Dienste, die Gruppen erstellen, und ist damit die Basis. Die *Konvention* selbst ist die organisatorische Regel, die festlegt, wie ein Name aufgebaut ist, zum Beispiel `Typ-Bereich-Name`, etwa `PRJ-Vertrieb-Messe2027`. Wichtig ist, dass die Konvention einfach genug ist, dass man sie ohne Handbuch versteht. Kürzel für Typ (ABT für Abteilung, PRJ für Projekt, KND für Kunde, GRM für Gremium), eventuell Bereich und ein Freitextname genügen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Namensrichtlinie erklärt die technischen Grenzen: Das Präfix und Suffix darf aus Text und Attributen wie `[Department]`, `[Company]`, `[Office]`, `[StateOrProvince]`, `[CountryOrRegion]` und `[Title]` bestehen. Die Gesamtlänge von Gruppenname inklusive Präfix und Suffix ist auf 63 Zeichen begrenzt, und die Liste gesperrter Wörter kann bis zu 5000 Wörter enthalten. Benutzer mit den Rollen Globaler Administrator und Benutzeradministrator sind ausgenommen. Ein Hinweis aus der Praxis: Attribute wie die Abteilung funktionieren nur, wenn sie am Benutzerobjekt gepflegt sind; ist das Feld leer, bleibt der Platzhalter im Namen unvollständig oder wird weggelassen.

*Vorlagen* (Templates) sind die zweite Hälfte. Statt jedes Team leer zu starten, bietet man Vorlagen an, die Kanäle, Registerkarten und Apps vorkonfigurieren. Microsoft liefert Standardvorlagen mit (zum Beispiel für Projektverwaltung oder Veranstaltungen), und Organisationen können eigene Vorlagen definieren und die Erstellung auf diese Vorlagen beschränken. Eine gute Vorlage spart nicht nur Einrichtungszeit, sie schreibt auch Standards fest: ein Kanal „Allgemein“ und ein Kanal „Dokumente“, ein Planner-Tab, ein Hinweis zur Datenklassifizierung im Beschreibungstext. Für automatisierte Anlage (Modul 10) sind Vorlagen unverzichtbar, weil sie dafür sorgen, dass jedes Team gleich aussieht.

Das folgende Skript prüft bestehende Teams auf Einhaltung einer Namenskonvention. Es verwendet einen regulären Ausdruck und gibt die Abweichungen aus. Damit lässt sich der Bestand bereinigen, bevor man die Regel verpflichtend macht.

**Test-TeamNaming.ps1**

```powershell
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

# Konvention: TYP-Bereich-Name, TYP aus ABT, PRJ, KND, GRM
$muster = '^(ABT|PRJ|KND|GRM)-[A-Za-z0-9]+-[A-Za-z0-9 _.\-]{2,40}$'

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
         -Property Id,DisplayName,CreatedDateTime

$ergebnis = $teams | ForEach-Object {
    [pscustomobject]@{
        Name     = $_.DisplayName
        Erstellt = $_.CreatedDateTime
        Konform  = [bool]($_.DisplayName -match $muster)
    }
}

"{0} von {1} Teams entsprechen der Konvention." -f ($ergebnis | Where-Object Konform).Count, $ergebnis.Count
$ergebnis | Where-Object { -not $_.Konform } | Sort-Object Erstellt | Select-Object -First 25 | Format-Table -AutoSize
```

Das Muster in einfachen Anführungszeichen besteht aus einem Anfangsanker, einem von vier Typkürzeln, einem Bindestrich, einem Bereich aus Buchstaben und Ziffern, wieder einem Bindestrich und einem Namen mit zwei bis vierzig erlaubten Zeichen. Der Operator `-match` liefert wahr oder falsch, was mit `[bool]` ausdrücklich in einen Wahrheitswert umgewandelt wird. Die Ausgabe nennt zuerst den Anteil der konformen Teams und zeigt danach die ältesten 25 Abweichungen. Der Bericht zeigt, wie viel Aufräumarbeit vor einer verpflichtenden Regel nötig ist.

### Typische Fehler und Stolperfallen.

Zu komplexe Konventionen werden nicht eingehalten: Wer sieben Pflichtbestandteile verlangt, bekommt Umgehungen. Ebenso problematisch sind Namen, die vertrauliche Informationen enthalten, zum Beispiel einen Kundennamen oder „Restrukturierung 2027“, denn Teamnamen sind für alle sichtbar, die das Team finden können. Ein weiterer Fehler ist das Weglassen des Beschreibungsfelds.

```
FALSCH:  "Entlassungen Standort Linz - streng geheim"
          (Name ist in Suche, E-Mail-Adresse und Links sichtbar)

RICHTIG: "PRJ-HR-Standortprojekt" mit Datenschutzstufe "Privat",
          Beschreibung: "Projektteam, Zugriff nur nach Freigabe"
```

### Praxisbezug.

Eine Konvention funktioniert, wenn sie in den Antragsweg eingebaut ist. In kleineren Organisationen reicht ein Formular mit Auswahlfeldern, in größeren erzeugt die Bereitstellungsfabrik den Namen automatisch (Modul 10, Lerneinheit „Naming Automation“). Vorlagen werden zusammen mit den Fachbereichen entworfen und nicht am Schreibtisch der IT.

> **Merke**
>
> Namensrichtlinie (technisch) und Namenskonvention (organisatorisch) ergänzen sich. Vorlagen legen Struktur und Standards fest. Teamnamen sind öffentlich sichtbar und dürfen nichts Vertrauliches enthalten.

## 3.3 Teams Creation Controls

Wer darf Teams erstellen? Die Antwort bestimmt, wie viel Chaos entsteht und wie viel Bürokratie. Im Standard darf jede Person in der Organisation jederzeit Teams anlegen, was die Einführung beschleunigt, aber den Tenant schnell überfüllt. Das andere Extrem, nur die IT darf Teams anlegen, bremst die Zusammenarbeit und fördert Ausweichlösungen. Die Lösung liegt in einer abgestuften Steuerung, die man *Creation Controls* nennt.

Technisch steuert man die Erstellung auf der Ebene der Microsoft-365-Gruppen. Wie Modul 02 (Lerneinheit 2.6) beschreibt, begrenzt die Verzeichniseinstellung `EnableGroupCreation` zusammen mit `GroupCreationAllowedGroupId` die Erstellung auf Mitglieder einer Sicherheitsgruppe. Die Dokumentation weist darauf hin, dass Administratorrollen ausgenommen sind und Änderungen bis zu 30 Minuten oder länger brauchen. Auf der Dienstebene gibt es weitere Stellschrauben: In SharePoint kann man die Erstellung von Websites durch Benutzer steuern, in Planner die Erstellung von Plänen, und in Outlook im Web die Erstellung von Gruppen über die Postfachrichtlinie. Eine unvollständige Absicherung ist die häufigste Fehlerquelle.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation „Manage who can create Microsoft 365 Groups“ nennt als Voraussetzung eine Lizenz Microsoft Entra ID P1 oder P2 für die Mitglieder der Gruppe, die Gruppen erstellen darf. Das Skript der Dokumentation verwendet die Vorlage mit der Kennung `62375ab9-6b52-47ed-826b-58e47e0e304b` (Group.Unified). Für Outlook im Web ist ein zusätzlicher Schritt notwendig: Die Postfachrichtlinie `OwaMailboxPolicy` muss mit dem Parameter `GroupCreationEnabled` auf `$false` gesetzt werden, damit die Einschränkung auch dort gilt. Detailfragen ändern sich; prüfen Sie vor dem Rollout die aktuelle Seite.

Ein praxistaugliches Modell hat drei Stufen. Auf der ersten Stufe dürfen alle Mitarbeitenden Teams aus einem Katalog von Vorlagen anlegen, wobei Name, Besitzer und Klassifizierung vorgegeben werden. Auf der zweiten Stufe dürfen ausgewählte Personen („Kanalmanager“, Projektbüros, Champions) freie Teams anlegen. Auf der dritten Stufe sind Sonderfälle wie Teams mit Gästen oder mit hoher Vertraulichkeit nur über einen Antrag mit Genehmigung möglich. Die Stufen entsprechen der Realität der meisten Organisationen: 80 Prozent der Anfragen sind Standard, 15 Prozent brauchen Freiheit, 5 Prozent brauchen Prüfung.

Das nächste Skript setzt die Einschränkung gemäß Dokumentation um. Es legt (falls nötig) die Verzeichniseinstellung an und trägt die Sicherheitsgruppe der „Team-Ersteller“ ein. Das Skript ist bewusst einfach und prüft vorab, ob die Gruppe existiert, weil ein Fehler hier alle Benutzer aussperren würde.

**Set-GroupCreationControl.ps1**

```powershell
param([Parameter(Mandatory)][string]$GroupName)   # z. B. "SEC-Team-Ersteller"

Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.Read.All" -NoWelcome

$gruppe = Get-MgGroup -Filter "displayName eq '$GroupName'"
if (-not $gruppe) { throw "Sicherheitsgruppe '$GroupName' nicht gefunden - Abbruch." }
if (@($gruppe).Count -gt 1) { throw "Name nicht eindeutig - Abbruch." }

$vorlage = Get-MgBetaDirectorySettingTemplate | Where-Object { $_.DisplayName -eq "Group.Unified" }
$einst   = Get-MgBetaDirectorySetting | Where-Object { $_.TemplateId -eq $vorlage.Id }

$werte = @(
    @{ Name = "EnableGroupCreation";        Value = "false" },
    @{ Name = "GroupCreationAllowedGroupId"; Value = $gruppe.Id }
)

if (-not $einst) {
    $params = @{ TemplateId = $vorlage.Id; Values = $werte }
    New-MgBetaDirectorySetting -BodyParameter $params | Out-Null
    "Einstellung neu angelegt."
} else {
    Update-MgBetaDirectorySetting -DirectorySettingId $einst.Id -Values $werte
    "Einstellung aktualisiert."
}
"Hinweis: Die Aenderung kann 30 Minuten und laenger bis zur Wirkung brauchen."
```

Die ersten drei Zeilen nach der Anmeldung schützen vor Fehlern: Das Skript bricht ab, wenn die Gruppe fehlt oder nicht eindeutig ist. Danach wird die Vorlage `Group.Unified` gesucht und geprüft, ob im Tenant schon eine Einstellung auf Basis der Vorlage existiert. Die beiden Werte sind `EnableGroupCreation` mit dem Wert false (nur Berechtigte dürfen) und die Objekt-ID der erlaubten Gruppe. Existiert die Einstellung nicht, wird sie neu angelegt, sonst aktualisiert. Beachten Sie, dass bei `Update-MgBetaDirectorySetting` die gesamte Werteliste ersetzt wird; andere Werte der Einstellung (zum Beispiel die Namensrichtlinie, die in derselben Einstellung steckt) würden dabei verloren gehen. Deshalb sollte man in produktiven Tenants zuerst die vorhandenen Werte auslesen und die geänderten Werte hineinmischen.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist, die Einschränkung zu aktivieren und dabei die Namensrichtlinie oder andere Gruppeneinstellungen zu überschreiben. Der zweite Fehler: Die Einschränkung gilt, aber niemand weiß, wie man ein Team bekommt. Der dritte Fehler: Teams lassen sich weiterhin über einen anderen Weg erstellen, etwa über Outlook im Web oder Planner.

```
FALSCH:  Update-MgBetaDirectorySetting mit nur zwei Werten
          -> PrefixSuffixNamingRequirement und CustomBlockedWordsList
             in derselben Einstellung gehen verloren.

RICHTIG: $einst.Values auslesen, die zwei Werte darin aendern,
          die gesamte Liste zurueckschreiben.
```

### Praxisbezug.

Legen Sie parallel zur Einschränkung den Antragsweg fest: ein Formular, ein Katalog von Vorlagen, eine feste Bearbeitungszeit (zum Beispiel ein Arbeitstag). Messen Sie nach vier Wochen, wie viele Anträge gestellt wurden und wie viele abgelehnt wurden. Eine hohe Ablehnungsquote zeigt, dass die Vorlagen nicht zum Bedarf passen.

> **Merke**
>
> Die Erstellung von Teams wird über die Gruppenerstellung gesteuert. Dienste außerhalb von Teams (Outlook im Web, Planner, SharePoint) müssen mitgedacht werden. Administratorrollen sind ausgenommen, Änderungen brauchen Zeit, und beim Schreiben der Einstellung dürfen vorhandene Werte nicht verloren gehen.

## 3.4 Guest und External Access

Microsoft Teams kennt zwei Arten externer Zusammenarbeit, die man klar unterscheiden muss. Beim *Gastzugriff* (Guest Access) wird eine externe Person als Gastbenutzer ins eigene Verzeichnis aufgenommen und einem Team hinzugefügt. Sie sieht dann die Kanäle, Dateien und Chats dieses Teams, jedoch nur dort. Beim *externen Zugriff* (External Access, früher „Federation“) können Personen aus einer anderen Organisation mit eigenen Konten per Chat, Anruf und Besprechung kommunizieren, ohne Mitglied eines Teams oder Gast im Verzeichnis zu werden. Dabei gibt es keinen Zugriff auf Teams-Inhalte. Die Grundlagen zu Gästen als Identitäten (Einladung, Überprüfung, Lebenszyklus) stehen in Modul 02, Lerneinheit 2.7. Hier geht es um die Teams-spezifischen Einstellungen.

Ein Gastzugriff muss auf mehreren Ebenen erlaubt sein, damit er funktioniert. Die Dokumentation „Microsoft 365 guest settings“ fasst zusammen, dass Entra-Zusammenarbeitseinstellungen, Cross-Tenant-Einstellungen, Teams-Gasteinstellungen, SharePoint-Freigabeeinstellungen und Gruppeneinstellungen zusammenspielen. Ist eine Ebene gesperrt, ist der Zugriff gesperrt. Das erklärt viele Supportfälle: Der Gast ist eingeladen und hat im Team einen Platz, aber das Team zeigt „Sie haben keinen Zugriff“, weil die Website die externe Freigabe nicht erlaubt oder weil eine Richtlinie für bedingten Zugriff die Anmeldung blockiert.

> **Ergänzung aus der Nachrecherche**
>
> Laut der Referenzseite zu Gasteinstellungen ist in den Cross-Tenant-Zugriffseinstellungen von Microsoft Entra die B2B-Zusammenarbeit standardmäßig erlaubt, die B2B-Direktverbindung für Shared Channels dagegen standardmäßig blockiert. Wer Shared Channels mit anderen Organisationen nutzen will, muss die Direktverbindung also bewusst konfigurieren und kann dies je Organisation tun. Die Sensitivity Labels für Container (Modul 06, Modul 04) können den Gastzugriff pro Team steuern: Ein Label wie „Vertraulich ohne Externe“ verhindert das Hinzufügen von Gästen zu allen Teams, die dieses Label tragen. Rechtliche Fragen zum Austausch von Daten mit Externen (Auftragsverarbeitung, Drittländer) klären Sie mit Ihrer Datenschutzbeauftragten; das hier ist keine Rechtsberatung.

Wie entscheidet man, ob Gastzugriff erlaubt wird? Eine praxistaugliche Regel unterscheidet nach Schutzbedarf. Teams für interne Themen ohne Externe (Personalwesen, Geschäftsleitung) schließen Gäste über ein Label aus. Teams für Projekte mit Partnern erlauben Gäste, aber nur mit einem benannten Besitzer, der Gäste einlädt und regelmäßig prüft. Öffentliche Gremien oder Communities können Gäste großzügig zulassen, enthalten aber keine vertraulichen Daten. Diese Dreiteilung lässt sich in drei Labels übersetzen und ist leicht zu erklären.

Das folgende Skript erstellt einen Bericht, welche Teams Gäste enthalten, wer sie eingeladen hat (soweit im Gastobjekt vermerkt) und wie viele Gäste je Team vorhanden sind. Außerdem listet es die Gäste, die in mehr als fünf Teams Mitglied sind, denn diese Konten sind besonders interessant für eine Überprüfung.

**Get-TeamsGuestReport.ps1**

```powershell
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All","User.Read.All" -NoWelcome

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All -Property Id,DisplayName

$zeilen = foreach ($t in $teams) {
    Get-MgGroupMember -GroupId $t.Id -All |
        Where-Object { $_.AdditionalProperties.userType -eq 'Guest' } |
        ForEach-Object {
            [pscustomobject]@{
                Team  = $t.DisplayName
                Gast  = $_.AdditionalProperties.displayName
                Mail  = $_.AdditionalProperties.mail
                GastId= $_.Id
            }
        }
}

"Teams mit Gaesten: {0}" -f ($zeilen | Select-Object -ExpandProperty Team -Unique).Count
$zeilen | Export-Csv ".\teams-gaeste.csv" -NoTypeInformation -Encoding UTF8

"`nGaeste in mehr als 5 Teams:"
$zeilen | Group-Object GastId | Where-Object Count -gt 5 |
    Select-Object Count, @{n='Gast';e={$_.Group[0].Gast}}, @{n='Mail';e={$_.Group[0].Mail}} |
    Sort-Object Count -Descending | Format-Table -AutoSize
```

Das Skript durchläuft alle Teams und holt die Mitglieder, filtert dabei nach Benutzertyp Gast und baut für jeden Treffer eine Zeile. Die Auswertung am Ende gruppiert die Zeilen nach der Gast-ID, zählt, in wie vielen Teams jeder Gast vorkommt, und zeigt diejenigen mit mehr als fünf Teams. Dahinter steckt die Überlegung, dass Gäste mit vielen Mitgliedschaften entweder Dienstleister mit großer Bedeutung oder verwaiste Konten mit unkontrolliert gewachsenen Rechten sind. Die CSV-Datei enthält die Rohdaten für weitere Auswertungen, zum Beispiel in Excel.

### Typische Fehler und Stolperfallen.

Ein verbreiteter Fehler ist, Gastzugriff in Teams global zu erlauben, aber Dateien in SharePoint oder OneDrive nicht mitzudenken. Dann können Gäste im Team nicht auf Dateien zugreifen und der Support zählt wieder auf die IT. Der zweite Fehler ist ein Team ohne Gastlabel, in das später ein Gast zufällig gerät. Der dritte: Gäste, die über Chats Dateien teilen und dadurch Zugriff auf Orte erhalten, die niemand zugeordnet hat.

```
FALSCH:  Gast im Team "Geschaeftsleitung" hinzugefuegt, weil es technisch geht.

RICHTIG: Label "Vertraulich - ohne Externe" auf dem Team:
          Gaeste koennen nicht hinzugefuegt werden, die Sperre gilt auch
          fuer die verbundene SharePoint-Website.
```

### Praxisbezug.

Beim Kunden wird das Thema fast immer durch einen Vorfall ausgelöst („ein Berater hatte Zugriff auf das falsche Team“). Gehen Sie in dieser Reihenfolge vor: Bestandsbericht, Dreiteilung nach Schutzbedarf, Labels, dann erst die Einstellungen verschärfen. Kommunizieren Sie die Änderung vorab an die Teambesitzer.

> **Merke**
>
> Gastzugriff (Mitglied im Team) und externer Zugriff (Chat und Besprechung) sind verschiedene Dinge. Gastzugriff funktioniert nur, wenn alle Ebenen ihn erlauben. Labels auf Teams-Ebene machen die Regel sichtbar und durchsetzbar.

## 3.5 Channels und Shared Channels

Kanäle gliedern ein Team in Themen. Es gibt drei Arten. *Standardkanäle* sind für alle Teammitglieder sichtbar und teilen sich die SharePoint-Website des Teams. *Private Kanäle* sind nur für eine ausgewählte Teilmenge der Mitglieder sichtbar und haben eine eigene SharePoint-Website. *Freigegebene Kanäle* (Shared Channels) lassen sich auch Personen außerhalb des Teams und sogar außerhalb der Organisation zuweisen, ohne dass diese Mitglied des Teams werden. Für jeden Kanaltyp gelten andere Regeln für Speicherort, Mitgliedschaft und Governance.

Freigegebene Kanäle sind für die Governance besonders interessant, weil sie das Gastmodell verändern. Statt einen Externen als Gast ins Verzeichnis aufzunehmen, nutzt der Kanal die *B2B-Direktverbindung*: Die externe Person meldet sich in ihrem eigenen Tenant an und greift auf den Kanal zu. Sie ist weiterhin eine Person im eigenen Verzeichnis, nicht im fremden. Dadurch entfallen Gastkonten, und mit ihnen entfallen auch die Bereinigungsaufgaben für Gäste. Dafür müssen beide Organisationen die Direktverbindung in ihren Cross-Tenant-Einstellungen freigeben, und das Berechtigungsmodell des Kanals gilt.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zu freigegebenen Kanälen nennt folgende Eigenschaften: Jeder freigegebene Kanal hat eine eigene SharePoint-Website (Vorlage `TEAMCHANNEL#1`), und nur Teambesitzer dürfen freigegebene Kanäle erstellen. Zugriff durch Externe benötigt die B2B-Direktverbindung. Gelöschte Kanäle können 30 Tage lang wiederhergestellt werden. Sensitivity Labels des übergeordneten Teams werden an die Kanalwebsite vererbt. Archiviert man ein Team, werden die zugehörigen Kanäle ebenfalls schreibgeschützt. Die genauen Randbedingungen (zum Beispiel unterstützte Apps) ändern sich; prüfen Sie die aktuelle Seite.

Governance-relevant ist die Frage, wer Kanäle anlegen darf und wo die Dateien liegen. Der Teambesitzer kann in den Teameinstellungen festlegen, ob Mitglieder Standardkanäle, private Kanäle oder freigegebene Kanäle erstellen dürfen. Für die meisten Organisationen ist es sinnvoll, die Erstellung privater und freigegebener Kanäle auf Besitzer zu beschränken. Der Grund: Jeder private Kanal erzeugt eine eigene SharePoint-Website, die bei Berichten und Überprüfungen als eigenes Objekt auftaucht. Ein Team mit 30 privaten Kanälen kann somit 31 Websites haben. Die Besitzer dieser Kanäle sind nicht zwingend die des Teams, und gruppenbezogene Überprüfungen erfassen sie nicht automatisch. Bei SharePoint Advanced Management (Modul 04) taucht dieser Aspekt wieder auf.

Das Skript listet alle Teams mit privaten und freigegebenen Kanälen, damit man einschätzen kann, wie stark diese Kanaltypen genutzt werden. Es verwendet die Graph-Cmdlets für Teams und kapselt die Fehlerbehandlung, damit ein einzelnes Team den Lauf nicht stoppt.

**Get-TeamsChannelReport.ps1**

```powershell
Connect-MgGraph -Scopes "Channel.ReadBasic.All","Team.ReadBasic.All" -NoWelcome

$teams = Get-MgTeam -All

$zeilen = foreach ($t in $teams) {
    try {
        $kanaele = Get-MgTeamChannel -TeamId $t.Id -All
        [pscustomobject]@{
            Team          = $t.DisplayName
            Standard      = @($kanaele | Where-Object MembershipType -eq 'standard').Count
            Privat        = @($kanaele | Where-Object MembershipType -eq 'private').Count
            Freigegeben   = @($kanaele | Where-Object MembershipType -eq 'shared').Count
        }
    } catch {
        Write-Warning "Team '$($t.DisplayName)': $($_.Exception.Message.Split("`n")[0])"
    }
}
$zeilen | Where-Object { $_.Privat -gt 0 -or $_.Freigegeben -gt 0 } |
    Sort-Object Privat -Descending | Format-Table -AutoSize
"Summe private Kanaele: {0}, freigegebene Kanaele: {1}" -f
    ($zeilen | Measure-Object Privat -Sum).Sum, ($zeilen | Measure-Object Freigegeben -Sum).Sum
```

Die Eigenschaft `MembershipType` unterscheidet die drei Kanalarten: standard, private und shared. Das Skript holt für jedes Team die Kanäle und zählt sie nach Art. Der `try`-Block fängt Fehler pro Team ab, sodass etwa ein archiviertes oder gesperrtes Team den Lauf nicht beendet. Ausgegeben werden nur die Teams, die private oder freigegebene Kanäle besitzen, sortiert nach der Zahl der privaten Kanäle. Die Summen am Ende geben einen schnellen Überblick darüber, wie viele zusätzliche Websites durch Kanäle im Tenant existieren.

### Typische Fehler und Stolperfallen.

Ein häufiger Irrtum ist die Annahme, in privaten Kanälen sei „alles privater“. Teambesitzer und Administratoren können jedoch Inhalte der Kanalwebsite einsehen, und auch Aufbewahrung und eDiscovery greifen. Ein zweiter Fehler: freigegebene Kanäle ohne Abstimmung der Cross-Tenant-Einstellungen planen. Ein dritter: Kanäle als Ersatz für Teams missbrauchen und dann Rollen nicht mehr trennen können.

```
FALSCH:  "Fuer das Projekt mit dem Partner machen wir einen privaten Kanal
          und laden die Partner als Gaeste in das ganze Team ein."

RICHTIG: Freigegebener Kanal mit B2B-Direktverbindung zum Partner:
          Die Partner sehen nur den Kanal, nicht das restliche Team.
```

### Praxisbezug.

Zur Faustregel bei der Wahl: Reicht ein Standardkanal, nehmen Sie ihn. Brauchen nur wenige Teammitglieder Zugriff, nutzen Sie einen privaten Kanal. Müssen Externe oder Personen anderer Teams mitarbeiten, ohne das ganze Team zu sehen, ist ein freigegebener Kanal oft besser als Gastkonten. Dokumentieren Sie die Regel in einem Entscheidungsbaum für Teambesitzer.

> **Merke**
>
> Standard-, private und freigegebene Kanäle unterscheiden sich in Sichtbarkeit und Speicherort. Private und freigegebene Kanäle haben eigene Websites. Freigegebene Kanäle nutzen B2B-Direktverbindung statt Gastkonten.

## 3.6 Apps und Tabs Governance

Apps machen Teams zur Plattform: Registerkarten (Tabs) zeigen Planner, Power BI oder SharePoint-Seiten, Bots beantworten Fragen, Nachrichtenerweiterungen holen Inhalte in den Chat. Dieselbe Offenheit ist ein Risiko, wenn jede Person jede App installieren darf. Eine App kann Daten lesen, Nachrichten schreiben und sich mit externen Diensten verbinden. Apps-Governance beantwortet deshalb drei Fragen: Welche Apps sind erlaubt? Wer darf sie installieren? Wer prüft ihre Berechtigungen?

Die Steuerung liegt im Teams Admin Center. Dort kann man Apps global zulassen oder blockieren und mit *App-Berechtigungsrichtlinien* festlegen, welche Benutzergruppen welche Apps nutzen dürfen. Mit *App-Setuprichtlinien* legt man fest, welche Apps vorinstalliert und angeheftet werden, damit Benutzer die wichtigsten Werkzeuge sofort finden. Ergänzend gibt es die Möglichkeit, benutzerdefinierte Apps (eigene Entwicklungen) für die Organisation hochzuladen oder zu sperren. Hinter vielen Apps steht außerdem eine *Zustimmung* (Consent) in Microsoft Entra: Die App fordert Berechtigungen an, die ein Administrator oder der Benutzer erteilen muss. Wie diese Zustimmung geregelt ist, entscheidet über das Risiko, denn eine App mit weitreichenden Rechten ist ein Angriffsweg.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Verwaltung von Apps im Teams Admin Center beschreibt, dass App-Berechtigungsrichtlinien auf Benutzergruppen angewendet werden und Richtlinien einige Zeit bis zur Wirkung brauchen. Für das Entra-Consent-Modell empfiehlt Microsoft allgemein, Benutzerzustimmung auf überprüfte Herausgeber und niedrige Berechtigungen zu begrenzen und für weitergehende Anfragen einen Administratorzustimmungs-Workflow einzurichten. Die konkrete Konfiguration und die Bezeichnungen im Portal ändern sich gelegentlich; planen Sie hier eine Prüfung der aktuellen Dokumentation ein.

Der pragmatische Ansatz lautet: erst erlauben, dann einschränken, aber mit Bedacht. Beginnen Sie mit der Liste der tatsächlich installierten Apps und ihrer Nutzer. Sortieren Sie in drei Gruppen: Standard-Apps von Microsoft (erlaubt), geprüfte Drittanbieter-Apps mit Geschäftsnutzen (erlaubt, nach Prüfung), alles andere (gesperrt, mit Ausnahmeprozess). Für die Tabs gilt: Ein Tab zeigt Inhalte aus einer anderen Quelle; Governance bedeutet hier, dass die Quelle selbst (SharePoint, Power BI) den Zugriff regelt. Ein Tab öffnet keinen Zugriff, den die Quelle nicht erlaubt, er macht ihn nur sichtbar. Das ist eine wichtige Botschaft an Teambesitzer, die Tabs für „Freigaben“ halten.

Das folgende Skript listet die Berechtigungen auf, die Anwendungen im Tenant erhalten haben: Für jede Unternehmensanwendung werden die delegierten Berechtigungsvergaben ausgegeben, die weitreichende Bereiche enthalten. Es hilft, riskante Zustimmungen zu finden, die über Teams-Apps oder andere Wege entstanden sind.

**Get-RiskyConsents.ps1**

```powershell
Connect-MgGraph -Scopes "DelegatedPermissionGrant.Read.All","Application.Read.All" -NoWelcome

$riskant = "Files.ReadWrite.All","Mail.ReadWrite","Mail.Send","Sites.ReadWrite.All","Directory.ReadWrite.All"

$sp = @{}
Get-MgServicePrincipal -All -Property Id,DisplayName | ForEach-Object { $sp[$_.Id] = $_.DisplayName }

Get-MgOauth2PermissionGrant -All |
    ForEach-Object {
        $scopes = $_.Scope -split ' ' | Where-Object { $_ }
        $treffer = $scopes | Where-Object { $_ -in $riskant }
        if ($treffer) {
            [pscustomobject]@{
                Anwendung = $sp[$_.ClientId]
                Art       = $_.ConsentType      # AllPrincipals = Administratorzustimmung
                Rechte    = ($treffer -join ', ')
            }
        }
    } | Sort-Object Anwendung | Format-Table -AutoSize
```

Zuerst baut das Skript eine Tabelle, die Objekt-IDs von Dienstprinzipalen in Anzeigenamen übersetzt, weil die Zustimmungen nur die ID enthalten. Danach liest es alle delegierten Berechtigungsvergaben. Jede Vergabe enthält eine durch Leerzeichen getrennte Liste von Bereichen (Scopes); das Skript zerlegt sie und vergleicht sie mit einer Liste riskanter Bereiche. Der Wert `AllPrincipals` im Feld `ConsentType` zeigt, dass ein Administrator die Zustimmung für die gesamte Organisation erteilt hat; `Principal` bedeutet Zustimmung durch einen einzelnen Benutzer. Die Liste der riskanten Bereiche ist ein Beispiel und sollte zu Ihrer Risikobewertung passen.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, Apps nach Namen zu bewerten statt nach Berechtigungen. Eine harmlos klingende App mit der Berechtigung, alle Postfächer zu lesen, ist gefährlicher als eine sperrige App mit schmalen Rechten. Der zweite Fehler: Apps sperren, ohne dass es einen Weg für Ausnahmen gibt; Benutzer weichen dann auf private Konten aus. Der dritte: Ein Administrator erteilt Zustimmung „für die ganze Organisation“, um ein Problem schnell zu beheben, und vergisst es.

```
FALSCH:  Support klickt "Administratorzustimmung erteilen" fuer eine App,
          damit der Benutzer weiterarbeiten kann. Rechte: Mail.ReadWrite.

RICHTIG: Antrag mit Begruendung -> Pruefung der Rechte und des Herausgebers
          -> Entscheidung dokumentieren -> Zustimmung nur fuer noetige Rechte.
```

### Praxisbezug.

Richten Sie einen leichten Antragsweg ein: ein Formular, eine Prüfliste (Herausgeber, Datenschutz, Berechtigungen, Lizenz) und eine Frist. Legen Sie fest, wer entscheidet. Ergebnis ist eine gepflegte Liste freigegebener Apps, die Sie im Teams Admin Center umsetzen und halbjährlich überprüfen.

> **Merke**
>
> Apps-Governance regelt Zulassung, Installation und Berechtigungen. Entscheidend sind die Berechtigungen, nicht der Name. Tabs machen Inhalte sichtbar, ändern aber nicht die Zugriffsrechte der Quelle.

## 3.7 Teams Archiving

Archivieren heißt: Ein Team bleibt erhalten, ist aber schreibgeschützt. Niemand kann mehr Nachrichten schreiben, Dateien hochladen oder Kanäle verwalten. Das Team verschwindet aus der aktiven Liste der Mitglieder, bleibt aber auffindbar und lesbar. Archivierung ist die richtige Antwort auf die Frage „Wir brauchen es nicht mehr, aber wir dürfen oder wollen es nicht löschen“. Typische Fälle sind abgeschlossene Projekte, beendete Kampagnen oder aufgelöste Gremien.

Technisch hat die Archivierung einen Teams-Teil und einen SharePoint-Teil. Archiviert der Besitzer das Team in Teams, wird das Team schreibgeschützt, und die zugehörige SharePoint-Website kann wahlweise ebenfalls auf schreibgeschützt gesetzt werden. Der Besitzer legt dafür fest, ob die Website schreibgeschützt wird. Eine Archivierung lässt sich umkehren, indem das Team reaktiviert wird. Besitzer können weiterhin Einstellungen ändern, doch Mitglieder verlieren ihre Schreibrechte. Bei der Archivierung eines Teams mit freigegebenen Kanälen werden diese ebenfalls schreibgeschützt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation unterscheidet zwei Dinge, die oft verwechselt werden: das Archivieren eines Teams in Teams und die *Archivierung einer SharePoint-Website* mit Microsoft 365 Archive, einem kostengünstigeren Speicherniveau für selten genutzte Websites. Letzteres gehört zu SharePoint Advanced Management (siehe Modul 04, Lerneinheit „Site Lifecycle“) und hat eigene Lizenz- und Preisregeln. Für die Verwaltung per Skript stehen im Teams-Modul `Set-TeamArchivedState` und für Graph `Invoke-MgArchiveTeam` zur Verfügung; für die SharePoint-Seite gibt es `Set-SPOSiteArchiveState`.

Warum nicht einfach löschen? Weil Löschen unwiderruflich nach 30 Tagen wird und weil Aufbewahrungspflichten gelten können. Eine Archivierung kostet kaum etwas, bewahrt den Kontext (wer hat was entschieden?) und ermöglicht Wiederherstellung durch Reaktivierung. Warum nicht alles archivieren? Weil ein archiviertes Team immer noch Speicher belegt und in Berichten auftaucht, und weil die Gäste im Team ihre Mitgliedschaft behalten. Der sauberste Weg ist deshalb eine Kombination: erst Zugriffe aufräumen (Gäste entfernen), dann archivieren, später löschen oder in das günstige Archiv verschieben.

Das folgende Skript archiviert eine Liste von Teams und prüft vorher, ob sie noch Gäste enthalten. Es dient als Vorlage für einen automatisierten Archivierungsjob. Die Liste der Teams wird aus einer CSV-Datei gelesen, damit ein Mensch das Ergebnis vorab freigeben kann.

**Invoke-TeamArchive.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$CsvPfad,        # Spalte: TeamId
    [switch]$Ausfuehren                             # ohne Schalter nur Probelauf
)
Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","GroupMember.Read.All" -NoWelcome

foreach ($zeile in Import-Csv $CsvPfad) {
    $id = $zeile.TeamId
    $team = Get-MgTeam -TeamId $id
    $gaeste = @(Get-MgGroupMember -GroupId $id -All |
                Where-Object { $_.AdditionalProperties.userType -eq 'Guest' })

    if ($gaeste.Count -gt 0) {
        Write-Warning "'$($team.DisplayName)': $($gaeste.Count) Gaeste - zuerst bereinigen."
        continue
    }
    if (-not $Ausfuehren) { "PROBELAUF: wuerde archivieren: $($team.DisplayName)"; continue }

    Invoke-MgArchiveTeam -TeamId $id
    "Archivierung angestossen: $($team.DisplayName)"
}
```

Der Schalter `Ausfuehren` verhindert versehentliche Änderungen: Ohne ihn gibt das Skript nur aus, was es tun würde. Für jedes Team in der CSV-Datei liest es die Gäste. Hat das Team Gäste, wird eine Warnung ausgegeben und das Team übersprungen (`continue`), weil zuerst die Zugriffe bereinigt werden sollen. Nur wenn der Schalter gesetzt ist, ruft das Skript `Invoke-MgArchiveTeam` auf. Die Archivierung ist ein asynchroner Vorgang: Der Aufruf stößt sie an, und das Ergebnis erscheint nach kurzer Zeit. Bei Fehlern lohnt sich ein Blick in die Protokolle.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist, archivierte Teams mit Gästen zu hinterlassen. Das Team ist schreibgeschützt, aber Externe haben weiterhin Leserechte. Der zweite Fehler: Archivierte Teams werden vergessen, und Jahre später sammeln sich Tausende. Dritter Fehler: Archivierung als Ersatz für Datenschutzlöschung verstehen.

```
FALSCH:  Team archivieren, 14 Gaeste bleiben Mitglied, keine Ueberpruefung.

RICHTIG: 1) Gaeste entfernen oder per Ueberpruefung bestaetigen lassen
          2) Team archivieren und Website schreibgeschuetzt setzen
          3) Nach 12 Monaten: Entscheidung Loeschen / Archiv-Speicherebene
```

### Praxisbezug.

Definieren Sie eine einfache Verweildauer: 12 Monate archiviert, dann Entscheidung. Teams mit Aufbewahrungspflichten werden über Purview-Richtlinien geschützt (Modul 06), nicht durch Liegenlassen. Die Zahlen aus dem Bestandsbericht (Lerneinheit 3.1) zeigen, wie viele Teams im ersten Durchlauf anfallen.

> **Merke**
>
> Archivieren macht ein Team schreibgeschützt und reversibel. Vor der Archivierung die Gäste bereinigen. Archivierung in Teams und Archivierung der Website (Microsoft 365 Archive) sind verschiedene Dinge.

## 3.8 Teams-Troubleshooting

Teams-Probleme erscheinen für Benutzer immer gleich: „Es geht nicht.“ Die Ursachen liegen aber in sehr verschiedenen Schichten. Eine bewährte Methode ist, das Problem einer Schicht zuzuordnen: Identität (Anmeldung, Lizenz, Gastkonto), Teams-Dienst (Richtlinien, Erstellung, Mitgliedschaft), Speicher (SharePoint, OneDrive, Berechtigungen), Postfach (Kalender, Besprechungen) oder Client (Version, Cache, Netzwerk). Wer die Schicht kennt, weiß, wo er suchen muss und wer zuständig ist.

Die häufigsten Governance-bedingten Fehlerbilder sind gut bekannt. Ein neues Team lässt sich nicht erstellen: Ursache ist meist die Einschränkung der Gruppenerstellung oder die Namensrichtlinie. Ein Gast kommt nicht ins Team: Einladung nicht angenommen, Gastzugriff auf einer Ebene gesperrt, Label verbietet Gäste oder bedingter Zugriff blockiert. Ein Mitglied sieht keine Dateien: SharePoint-Berechtigungen weichen von der Teammitgliedschaft ab, etwa weil jemand in der Website Rechte gebrochen hat. Eine App ist verschwunden oder nicht installierbar: App-Berechtigungsrichtlinie. Ein Team ist plötzlich schreibgeschützt: Archivierung. Ein Team ist weg: Ablaufrichtlinie und Löschung, Wiederherstellung innerhalb von 30 Tagen möglich.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zum Ende des Lebenszyklus nennt die 30-tägige Wiederherstellungsfrist für gelöschte Gruppen. Für gelöschte Kanäle gilt laut Dokumentation zu freigegebenen Kanälen ebenfalls eine 30-tägige Frist. In der Praxis lohnt es sich, zuerst im Entra Admin Center nach gelöschten Gruppen zu suchen, weil diese dort mit einem Klick wiederherstellbar sind. Wichtig: Änderungen an Richtlinien brauchen Zeit, bei der Gruppenerstellung mindestens 30 Minuten; wiederholtes Umschalten verschlimmert Verwirrung. Dokumentieren Sie Änderungen mit Uhrzeit.

Wie geht man strukturiert vor? Das Vorgehen besteht aus fünf Schritten. Zuerst das Symptom präzisieren: wer, was, seit wann, auf welchem Gerät, mit welcher Fehlermeldung. Dann die Schicht bestimmen. Dann die Daten holen: Anmeldeprotokolle, Überwachungsprotokolle, Zustand des Teams. Dann eine Hypothese prüfen, ohne sofort zu ändern. Zuletzt die Lösung umsetzen und dokumentieren. Ein kurzes Skript für den Servicedesk kann Schritt drei beschleunigen.

Das Skript zeigt zu einem Team die wichtigsten Zustandsdaten: ob es archiviert ist, wer Besitzer ist, wie viele Mitglieder und Gäste es hat, welche Kanäle es gibt und wann es zuletzt verlängert wurde. Es antwortet damit auf die erste Frage des Supports: Wie sieht das Team gerade aus?

**Get-TeamStatus.ps1**

```powershell
param([Parameter(Mandatory)][string]$TeamName)

Connect-MgGraph -Scopes "Group.Read.All","Team.ReadBasic.All","TeamSettings.Read.All","Channel.ReadBasic.All" -NoWelcome

$gruppe = @(Get-MgGroup -Filter "displayName eq '$TeamName'" `
            -Property Id,DisplayName,Visibility,CreatedDateTime,RenewedDateTime,DeletedDateTime)
if ($gruppe.Count -eq 0) {
    Write-Warning "Keine aktive Gruppe gefunden. Pruefen Sie geloeschte Gruppen (30 Tage Wiederherstellung)."
    return
}
$g = $gruppe[0]
$team = Get-MgTeam -TeamId $g.Id
$owner = @(Get-MgGroupOwner -GroupId $g.Id) | ForEach-Object { $_.AdditionalProperties.userPrincipalName }
$mem   = @(Get-MgGroupMember -GroupId $g.Id -All)
$gast  = @($mem | Where-Object { $_.AdditionalProperties.userType -eq 'Guest' })
$kan   = @(Get-MgTeamChannel -TeamId $g.Id -All)

[pscustomobject]@{
    Name          = $g.DisplayName
    Archiviert    = $team.IsArchived
    Sichtbarkeit  = $g.Visibility
    Besitzer      = ($owner -join '; ')
    Mitglieder    = $mem.Count
    Gaeste        = $gast.Count
    Kanaele       = $kan.Count
    Erstellt      = $g.CreatedDateTime
    Verlaengert   = $g.RenewedDateTime
} | Format-List
```

Der erste Abschnitt sucht die Gruppe nach dem Namen. Findet er keine, gibt er einen Hinweis auf gelöschte Gruppen aus, denn „Das Team ist weg“ ist ein typischer Fall. Danach werden Teamdetails, Besitzer, Mitglieder, Gäste und Kanäle abgefragt. Die Eigenschaft `IsArchived` verrät, ob ein Team schreibgeschützt ist. Am Ende entsteht ein einzelnes Objekt, das als Liste ausgegeben wird. Die Abfrage nach dem Anzeigenamen kann bei doppelten Namen mehrere Treffer liefern; hier wird der erste verwendet, ein produktives Skript sollte bei Mehrdeutigkeit abbrechen.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist, bei Teams-Problemen den Client neu zu installieren, bevor die Ursache bekannt ist. Der zweite: nur das Team ansehen und nicht die SharePoint-Website, obwohl das Dateiproblem dort liegt. Der dritte: Änderungen an Richtlinien ohne Wartezeit zu wiederholen.

```
FALSCH:  "Kann Datei nicht oeffnen" -> Teams-Cache loeschen, Client neu installieren.

RICHTIG: 1) Ist der Benutzer Mitglied? (Get-TeamStatus)
          2) Hat er Zugriff auf die Website? (Berechtigungen, unterbrochene Vererbung)
          3) Betrifft es nur ihn oder alle? 4) Erst dann Client pruefen.
```

### Praxisbezug.

Bauen Sie einen Entscheidungsbaum für die zehn häufigsten Fälle und hinterlegen Sie ihn im Betriebshandbuch (Modul 09). Zählen Sie die Tickets eine Zeit lang nach Ursache; die Auswertung zeigt, welche Governance-Entscheidung zu viel Rückfragen erzeugt und angepasst werden sollte.

> **Merke**
>
> Erst die Schicht bestimmen (Identität, Teams, Speicher, Postfach, Client), dann messen, dann ändern. Gelöschte Gruppen sind 30 Tage wiederherstellbar; Richtlinienänderungen brauchen Zeit.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Nennen Sie die fünf Phasen des Teams-Lebenszyklus und erklären Sie, warum die Archivierung vor der Löschung steht.

**Aufgabe 2 (leicht).** Worin unterscheiden sich Gastzugriff und externer Zugriff in Teams? Nennen Sie je ein Beispiel.

**Aufgabe 3 (leicht).** Welche drei Kanalarten gibt es, und welche hat keine eigene SharePoint-Website?

**Aufgabe 4 (mittel).** Entwerfen Sie eine Namenskonvention für Teams mit vier Typen. Geben Sie je ein Beispiel, begründen Sie die Länge und beschreiben Sie, wie die technische Namensrichtlinie die Konvention unterstützt.

**Aufgabe 5 (mittel).** Entwerfen Sie ein dreistufiges Modell für die Teams-Erstellung. Beschreiben Sie, wer jeweils Teams erstellen darf, wie die Vorlagen aussehen und was bei Gästen gilt.

**Aufgabe 6 (mittel).** Schreiben Sie ein PowerShell-Skript, das alle Teams ausgibt, die weniger als zwei Besitzer haben und mindestens einen Gast enthalten.

**Aufgabe 7 (schwer).** Ein Partnerprojekt braucht Zusammenarbeit mit 15 Personen einer anderen Firma. Vergleichen Sie Gastkonten im Team, einen privaten Kanal mit Gästen und einen freigegebenen Kanal mit B2B-Direktverbindung. Empfehlen Sie eine Lösung und begründen Sie sie.

**Aufgabe 8 (schwer).** Erweitern Sie das Archivierungsskript so, dass nur Teams archiviert werden, deren Gruppe seit mehr als 365 Tagen nicht verlängert wurde, und dass die Entscheidung in einer Protokolldatei festgehalten wird.

## Lösungen

**Lösung 1.** Die Phasen sind Beantragung und Anlage, Nutzung, Inaktivität, Archivierung und Löschung. Die Archivierung steht vor der Löschung, weil sie reversibel ist: Das Team bleibt lesbar und lässt sich reaktivieren, während die Löschung nach 30 Tagen endgültig wird. So kann man Fehlentscheidungen korrigieren und Aufbewahrungspflichten erfüllen.

**Lösung 2.** Beim Gastzugriff wird eine externe Person als Gastbenutzer im Verzeichnis geführt und einem Team zugeordnet, etwa eine Beraterin, die im Projektteam Dateien bearbeitet. Beim externen Zugriff chattet oder telefoniert eine Person mit eigenem Konto aus einer anderen Organisation, ohne Mitglied eines Teams zu sein, etwa bei einer Besprechung mit einem Lieferanten. Nur der Gastzugriff gewährt Zugriff auf Inhalte des Teams.

**Lösung 3.** Es gibt Standardkanäle, private Kanäle und freigegebene Kanäle. Standardkanäle haben keine eigene SharePoint-Website, sie nutzen die des Teams. Private und freigegebene Kanäle haben jeweils eine eigene Website.

**Lösung 4.** Ein Beispiel: Typkürzel ABT (Abteilung), PRJ (Projekt), KND (Kunde), GRM (Gremium), gefolgt von Bereich und Name, also etwa `PRJ-Vertrieb-Messe2027`. Das Typkürzel erlaubt Sortieren und Filtern, der Bereich ordnet zu, der Name bleibt kurz, damit die Gesamtlänge unter dem technischen Limit von 63 Zeichen bleibt. Die Namensrichtlinie kann ein Präfix wie `[Department]-` automatisch setzen und Wörter wie „test“ oder „admin“ sperren. Sie ersetzt die Konvention nicht, sondern erzwingt den Teil, der sich technisch abbilden lässt. Der Rest wird durch Antragsformular und Bestandsberichte unterstützt.

**Lösung 5.** Stufe 1: Alle Mitarbeitenden erstellen Teams aus drei bis fünf freigegebenen Vorlagen (Abteilung, Projekt, Gremium) über ein Formular oder die Bereitstellungsfabrik, mit automatischem Namen, zwei Besitzern, Standardlabel ohne Gäste. Stufe 2: Eine Gruppe von Champions darf freie Teams erstellen (Sicherheitsgruppe als erlaubte Erstellergruppe). Stufe 3: Teams mit Gästen oder hoher Vertraulichkeit nur über einen Antrag mit Genehmigung durch Datenschutz oder Sicherheitsbeauftragte, mit Label und Zugriffsüberprüfung.

**Lösung 6.** Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All" -NoWelcome
Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All -Property Id,DisplayName |
  ForEach-Object {
    $o = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($o -lt 2) {
      $g = @(Get-MgGroupMember -GroupId $_.Id -All |
             Where-Object { $_.AdditionalProperties.userType -eq 'Guest' }).Count
      if ($g -ge 1) { [pscustomobject]@{ Team = $_.DisplayName; Besitzer = $o; Gaeste = $g } }
    }
  } | Format-Table -AutoSize
```

Das Skript zählt zuerst die Besitzer und fragt die Gäste nur dann ab, wenn die Besitzerbedingung erfüllt ist. Das spart Abfragen und beschleunigt den Lauf in großen Tenants. Die Kombination ist ein typischer Risikoindikator: Gäste ohne ausreichende Aufsicht.

**Lösung 7.** Gastkonten im Team geben den 15 Personen Zugriff auf das gesamte Team und erzeugen 15 Gastobjekte, die bereinigt werden müssen. Ein privater Kanal mit Gästen verlangt trotzdem, dass die Gäste zuerst Teammitglieder sind, und schränkt nur die Sicht im Team ein; die Gäste bleiben im Verzeichnis. Ein freigegebener Kanal mit B2B-Direktverbindung gibt den Partnern nur Zugriff auf den Kanal, sie melden sich mit dem eigenen Konto an, und es entstehen keine Gastobjekte. Empfehlung: freigegebener Kanal, sofern die Partnerorganisation die Direktverbindung zulässt und die benötigten Funktionen unterstützt sind. Voraussetzung ist die gegenseitige Freigabe der Cross-Tenant-Einstellungen. Ansonsten ist der Gastzugriff mit einem dedizierten Projektteam, Befristung über Zugriffspaket und Überprüfung die Rückfalllösung.

**Lösung 8.** Ein mögliches Vorgehen: Die Eigenschaft `RenewedDateTime` der Gruppe mit dem Grenzdatum vergleichen und jede Entscheidung mit Zeitstempel in eine Datei schreiben.

```powershell
param([Parameter(Mandatory)][string]$CsvPfad, [switch]$Ausfuehren)
Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","Group.Read.All" -NoWelcome
$grenze = (Get-Date).AddDays(-365)
$log = ".\archivierung-$(Get-Date -Format yyyyMMdd).log"
foreach ($z in Import-Csv $CsvPfad) {
  $g = Get-MgGroup -GroupId $z.TeamId -Property Id,DisplayName,RenewedDateTime
  if ($g.RenewedDateTime -gt $grenze) {
    Add-Content $log "$(Get-Date -Format s) UEBERSPRUNGEN $($g.DisplayName) (juenger als 365 Tage)"
    continue
  }
  if ($Ausfuehren) { Invoke-MgArchiveTeam -TeamId $g.Id }
  Add-Content $log "$(Get-Date -Format s) $(if($Ausfuehren){'ARCHIVIERT'}else{'PROBELAUF'}) $($g.DisplayName)"
}
```

Das Skript schreibt für jede Entscheidung eine Zeile mit Zeitstempel. Dadurch ist nachvollziehbar, warum ein Team archiviert oder übersprungen wurde. Der Probelauf wird ebenfalls protokolliert, sodass ein Mensch die Liste vor dem eigentlichen Lauf prüfen kann.
