# Modul 01 - Grundlagen, Governance-Modell und Zielarchitektur

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 8 Stunden (Blatt „Lehrplan in Modulen“; die Summe der acht Lerneinheiten im Blatt „Lehrplan in Details“ beträgt ebenfalls 8 Stunden)  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**                 | **Dauer (h)** | **Prio** |
|:--------|:--------------------------------|--------------:|---------:|
| 1.1     | Governance-Grundlagen           |             1 |        3 |
| 1.2     | Operating Model                 |             1 |        1 |
| 1.3     | M365 Workload Landscape         |             1 |        1 |
| 1.4     | Rollen und Verantwortlichkeiten |             1 |        1 |
| 1.5     | Policy Framework                |             1 |        1 |
| 1.6     | Tenant Baseline                 |             1 |        2 |
| 1.7     | Governance Roadmap              |             1 |        2 |
| 1.8     | Zielarchitektur                 |             1 |        2 |
|         | **Summe**                       |         **8** |          |

> **Merke: Was dieses Skript ist**
>
> Dieses Skript ist für Menschen geschrieben, die das Thema von Grund auf verstehen wollen. Die Fachinhalte stammen aus dem Lehrplan und aus einer Nachrecherche in der offiziellen Microsoft-Dokumentation (Microsoft Learn). Die PowerShell-Beispiele orientieren sich an den dort veröffentlichten Cmdlets und Mustern. Sie wurden für dieses Skript *nicht* gegen einen echten Tenant ausgeführt. Bevor Sie ein Skript produktiv einsetzen, testen Sie es deshalb in einem Testtenant und lesen Sie jede Zeile.

## 1.1 Governance-Grundlagen

Wer zum ersten Mal mit dem Wort „Governance“ im Zusammenhang mit Microsoft 365 konfrontiert wird, denkt oft an Verbote, Formulare und Gremien. Das ist ein Missverständnis, und es lohnt sich, es gleich am Anfang auszuräumen. Governance bedeutet zunächst nur, dass eine Organisation *bewusst* entscheidet, wie sie eine Plattform nutzt, wer dafür verantwortlich ist und wie sie überprüft, dass die Entscheidungen tatsächlich eingehalten werden. Ein Tenant ohne Governance funktioniert technisch ebenfalls. Er funktioniert nur nach den Voreinstellungen des Herstellers und nach den Gewohnheiten der jeweils aktivsten Benutzer, nicht nach den Zielen der Organisation.

Um zu verstehen, warum diese Unterscheidung so wichtig ist, muss man die Voreinstellungen von Microsoft 365 kennen. Ein Tenant ist die organisatorische Instanz, in der alle Dienste einer Organisation zusammenlaufen: Das Verzeichnis (Microsoft Entra ID), die Postfächer (Exchange Online), die Teamwebsites und Dokumentablagen (SharePoint Online und OneDrive), die Zusammenarbeit (Teams) sowie die Schutz- und Nachweisfunktionen (Microsoft Purview und Microsoft Defender). Alle diese Dienste greifen auf dieselben Identitäten und Gruppen zu. Die Microsoft-Dokumentation hält zu den Voreinstellungen zwei Dinge fest, die für jede Governance-Diskussion zentral sind: Standardmäßig dürfen *alle* Benutzer Microsoft-365-Gruppen erstellen, und diese Voreinstellung wird von Microsoft sogar ausdrücklich als empfohlene Ausgangslage bezeichnet, weil Benutzer so ohne Hilfe der IT mit der Zusammenarbeit beginnen können. Außerdem ist externes Teilen in SharePoint und OneDrive zunächst für die gesamte Umgebung eingeschaltet. Die Plattform ist also auf Selbstbedienung und Offenheit ausgelegt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „Manage who can create Microsoft 365 Groups“ nennt als Voreinstellung, dass alle Benutzer Gruppen erstellen können, und empfiehlt dies ausdrücklich als Ausgangspunkt. Zugleich weist sie darauf hin, dass sich eine Einschränkung auf alle Dienste auswirkt, die Gruppen verwenden (Outlook, SharePoint, Viva Engage, Teams, Planner und weitere). Die Dokumentation „Overview of external sharing in SharePoint and OneDrive“ hält fest, dass externes Teilen standardmäßig für die gesamte Umgebung eingeschaltet ist. Beides sind Fakten, auf die jede Governance-Entscheidung aufbaut.

Aus dieser Ausgangslage entsteht das typische Spannungsfeld, das jede Governance auflösen muss: Produktivität gegen Kontrolle. Die Entra-ID-Governance-Dokumentation beschreibt es sehr klar am Beispiel der Identitäten. Es geht darum, wie schnell eine Person Zugriff auf die Ressourcen bekommt, die sie braucht, und gleichzeitig darum, wie sich dieser Zugriff über die Zeit verändern soll, etwa wenn sich der Beschäftigungsstatus ändert. Wer nur auf Geschwindigkeit optimiert, bekommt Wildwuchs: verwaiste Teams, vergessene Gäste, Freigabelinks, die niemand mehr kennt. Wer nur auf Kontrolle optimiert, bekommt Schatten-IT: Mitarbeiter weichen auf private Cloud-Dienste oder E-Mail-Anhänge aus, weil der offizielle Weg zu zäh ist. Gute Governance sucht den Punkt dazwischen, und sie formuliert ihn nicht als Gefühl, sondern als überprüfbare Regel.

Als gedankliches Gerüst helfen vier Fragen, die in der Dokumentation zu Microsoft Entra ID Governance gestellt werden und die sich auf den gesamten Tenant verallgemeinern lassen. Erstens: Welche Identitäten sollten Zugriff auf welche Ressourcen haben? Zweitens: Was tun diese Identitäten mit ihrem Zugriff? Drittens: Gibt es organisatorische Kontrollen, die den Zugriff steuern? Viertens: Können Prüfer nachvollziehen, dass diese Kontrollen wirksam sind? Die erste Frage verlangt Regeln, die zweite Monitoring, die dritte Durchsetzung und die vierte Nachweisfähigkeit. Diese vier Bausteine, Regel, Beobachtung, Durchsetzung und Nachweis, kehren in jedem späteren Modul dieses Kurses wieder.

Die Durchsetzung erfolgt über *Kontrollen* (englisch Controls). Man unterscheidet drei Arten. Eine *vorbeugende* Kontrolle verhindert den Regelverstoß, bevor er passiert, zum Beispiel eine Namensrichtlinie, die unerwünschte Gruppennamen ablehnt. Eine *aufdeckende* Kontrolle findet Verstöße nach dem Ereignis, zum Beispiel ein Bericht über Gruppen ohne Besitzer. Eine *korrigierende* Kontrolle stellt den gewünschten Zustand wieder her, zum Beispiel das Wiederherstellen einer versehentlich gelöschten Gruppe, was laut Dokumentation innerhalb von 30 Tagen nach dem Löschen möglich ist. Ein belastbares Governance-Modell verwendet alle drei Arten, weil keine einzelne ausreicht: Vorbeugende Kontrollen sind bequem für die IT, aber starr. Aufdeckende Kontrollen sind flexibel, kommen aber zu spät. Korrigierende Kontrollen begrenzen den Schaden, setzen jedoch voraus, dass man ihn überhaupt bemerkt.

Zum Abschluss der Begriffe noch eine Abgrenzung, die in der Praxis ständig verwechselt wird. *Governance* legt fest, wer was entscheiden darf und nach welchen Regeln. *Management* organisiert die Umsetzung dieser Regeln mit Ressourcen und Terminen. *Administration* ist das tägliche technische Ausführen, etwa das Anlegen eines Benutzers. Ein Administrator, der aus eigenem Ermessen entscheidet, ob ein Team externe Gäste haben darf, übt faktisch Governance aus, ohne dazu legitimiert zu sein. Genau das soll ein Governance-Modell vermeiden: Entscheidungen sollen an der richtigen Stelle getroffen und nachvollziehbar dokumentiert werden.

Das folgende Beispiel macht den Einstieg praktisch. Bevor man über Regeln spricht, braucht man ein Bild vom Ist-Zustand. Das Skript erstellt einen „Schnappschuss“ des Tenants: Name, Anzahl der Benutzer, Gäste und Microsoft-365-Gruppen. Es ist bewusst klein gehalten und liest ausschließlich. Es verwendet das Microsoft Graph PowerShell SDK, mit dem sich nahezu alle Tenant-Daten abfragen lassen, und es nutzt die Zählfunktionen von Graph, die einen sogenannten erweiterten Abfragemodus (`ConsistencyLevel eventual`) verlangen.

**Get-TenantSnapshot.ps1 - der Ist-Zustand in zehn Zeilen**

```powershell
# Voraussetzung: Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "Organization.Read.All","User.Read.All","Group.Read.All"

$org      = Get-MgOrganization
$users    = Get-MgUserCount  -ConsistencyLevel eventual
$guests   = Get-MgUserCount  -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$m365Grp  = Get-MgGroupCount -Filter "groupTypes/any(c:c eq 'Unified')" -ConsistencyLevel eventual

[pscustomobject]@{
    Tenant          = $org.DisplayName
    Benutzer        = $users
    Gaeste          = $guests
    M365Gruppen     = $m365Grp
    Erstellt        = Get-Date -Format "yyyy-MM-dd HH:mm"
} | Format-List

Disconnect-MgGraph
```

Die erste Zeile meldet sich mit genau den Berechtigungen an, die das Skript braucht, und nicht mit mehr. Das ist bereits gelebte Governance im Kleinen, das Prinzip der geringsten Rechte. `Get-MgOrganization` liefert die Stammdaten des Tenants. Die drei `Get-Mg...Count`-Aufrufe zählen serverseitig, statt tausende Objekte herunterzuladen und lokal zu zählen. Der Filter `userType eq 'Guest'` trennt Mitglieder von Gästen, und `groupTypes/any(c:c eq 'Unified')` wählt genau die Microsoft-365-Gruppen aus, im Unterschied zu reinen Sicherheitsgruppen. Das Ergebnis wird als Objekt ausgegeben und kann später in eine Datei geschrieben und über die Zeit verglichen werden. Genau diese Verlaufssicht ist wertvoll: Wächst die Zahl der Gäste schneller als die Zahl der Mitarbeiter, ist das ein Signal für die Governance, bevor ein Vorfall es erzwingt.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Governance mit einer einmaligen Einführung eines Werkzeugs gleichzusetzen. Wer im Projekt eine Namensrichtlinie und eine Ablaufrichtlinie aktiviert und danach das Thema abhakt, hat Kontrollen, aber keinen Regelkreis: Niemand prüft, ob die Richtlinien noch zur Organisation passen. Der zweite Fehler ist die pauschale Sperre. Das folgende Beispiel zeigt den Unterschied am Fall „Gruppenerstellung“.

```powershell
# FALSCH: Gruppenerstellung fuer alle sperren, ohne Ersatzprozess
#   -> Mitarbeiter legen Teams ueber private Tools an (Schatten-IT),
#      die IT wird mit Einzelwuenschen ueberlastet.

# RICHTIG: Erstellung an eine Berechtigungsgruppe koppeln
#   1. Sicherheitsgruppe "GRP-Creators" anlegen
#   2. Mitglied wird, wer eine kurze Schulung absolviert hat
#   3. Erstellung nur fuer diese Gruppe erlauben (siehe Modul 03)
#   4. Quartalsweise pruefen, ob die Mitglieder noch gebraucht werden
```

Die Microsoft-Dokumentation schlägt genau diesen Mittelweg selbst vor: Wer verhindern möchte, dass Teams oder Gruppen entstehen, die nicht den Unternehmensstandards entsprechen, kann Benutzer zuerst eine Schulung absolvieren lassen und sie danach der Gruppe der erlaubten Ersteller hinzufügen. Ein dritter Stolperstein ist die Verwechslung von Berechtigung und Verantwortung: Dass ein Administrator technisch etwas ändern *kann*, heißt nicht, dass er es entscheiden *darf*. Dieser Unterschied wird in der Lerneinheit „Rollen und Verantwortlichkeiten“ noch einmal aufgegriffen.

### Praxisbezug.

In jedem Projekt begegnet Ihnen Governance zuerst als Frage, die der Kunde oder die Geschäftsleitung stellt: „Wer darf bei uns eigentlich Teams anlegen?“, „Warum hat dieser externe Berater noch Zugriff?“ oder „Können wir einem Auditor zeigen, dass nur berechtigte Personen Zugriff auf die Personalablage haben?“ Wer diese Fragen mit dem Vier-Bausteine-Denken (Regel, Beobachtung, Durchsetzung, Nachweis) beantwortet, liefert strukturierte Antworten statt Einzelfallerklärungen. Das Tenant-Schnappschuss-Skript ist in vielen Beratungsprojekten der erste Schritt, weil es ohne großen Aufwand ein gemeinsames Faktenfundament schafft.

> **Merke**
>
> Governance ist ein Regelkreis aus Regel, Beobachtung, Durchsetzung und Nachweis. Sie löst das Spannungsfeld zwischen Produktivität und Kontrolle nicht durch Verbote, sondern durch Leitplanken. Vorbeugende, aufdeckende und korrigierende Kontrollen ergänzen sich.

## 1.2 Operating Model

Ein Governance-Modell auf dem Papier nützt nichts, wenn niemand weiß, wer es betreibt. Das *Operating Model* (deutsch: Betriebsmodell) beantwortet die Frage, wie die Governance im Alltag organisiert ist: Welche Teams sind beteiligt, welche Prozesse laufen regelmäßig, welche Entscheidungen werden wo getroffen und wie werden Ausnahmen behandelt. Man kann sich das Operating Model als die „Betriebsanleitung der Organisation“ für die Plattform vorstellen. Es verbindet die strategischen Regeln aus der Governance mit den technischen Tätigkeiten der Administratoren.

Ein tragfähiges Operating Model besteht aus fünf Bausteinen. Der erste Baustein ist die *Organisation*: Wer gehört zum Kernteam, wer ist Fachverantwortlicher, wer entscheidet bei Konflikten? Der zweite Baustein sind die *Prozesse*: Wie läuft eine Teamanfrage, eine Gastfreigabe, eine Ausnahmegenehmigung oder eine Änderung an einer Richtlinie ab? Der dritte Baustein sind die *Werkzeuge*: Welche Portale, Skripte und Automatisierungen werden eingesetzt, und wo ist der „Master“ der Konfiguration? Der vierte Baustein ist das *Reporting*: Welche Kennzahlen werden wem in welchem Rhythmus gezeigt? Der fünfte Baustein ist die *Verbesserung*: Wie fließen Erkenntnisse aus Vorfällen und Audits zurück in die Regeln?

Besonders wichtig ist das *Ownership-Prinzip*: Jedes Objekt in der Plattform hat einen benannten Verantwortlichen. Ein Team hat Besitzer, eine Website hat Administratoren, ein Zugriffspaket hat einen Manager, eine Richtlinie hat einen Policy Owner. Die Dokumentation zu den Ablaufrichtlinien zeigt, warum: Ablaufbenachrichtigungen werden an die Gruppenbesitzer gesendet, und eine Gruppe, die nicht erneuert wird, läuft ab und wird gelöscht. Gibt es keinen Besitzer, geht die Mail an eine vom Administrator hinterlegte Ersatzadresse. Ownership ist also kein Formalismus. Es entscheidet darüber, ob Lebenszyklusprozesse überhaupt funktionieren. Aus diesem Grund bilden viele Betriebsmodelle eine Regel wie „Jede Gruppe hat mindestens zwei Besitzer“, weil ein einzelner Besitzer, der die Firma verlässt, das Objekt sonst verwaist zurücklässt.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation zur Ablaufrichtlinie für Microsoft-365-Gruppen erhalten Besitzer 30 Tage vor dem Ablauf eine E-Mail zur Erneuerung, danach 15 Tage vorher eine weitere und einen Tag vorher eine letzte Benachrichtigung. Aktiv genutzte Gruppen werden etwa 35 Tage vor Ablauf automatisch verlängert. Nach dem Ablauf bleibt die Gruppe 30 Tage lang wiederherstellbar. Die Ablaufrichtlinie ist standardmäßig ausgeschaltet und setzt Microsoft-Entra-ID-P1- oder -P2-Lizenzen voraus.

Ein weiteres Element des Operating Models ist die Entscheidung zwischen *zentralem* und *föderiertem* Betrieb. Beim zentralen Modell entscheidet und konfiguriert ein Kernteam alles. Das ist konsistent, aber es skaliert schlecht und erzeugt Wartezeiten. Beim föderierten Modell werden Entscheidungen an die Fachbereiche delegiert, innerhalb vorgegebener Leitplanken. Die Entra-Dokumentation beschreibt dieses Prinzip für Zugriffspakete: Administratoren können nicht administrative Personen berechtigen, eigene Zugriffspakete zu erstellen, die Ressourcen bündeln, die Identitäten anfordern können, und die delegierten Paketmanager legen die Regeln fest, wer anfragen darf, wer genehmigt und wann der Zugriff abläuft. Das ist ein gutes Beispiel für ein föderiertes Modell mit zentralen Leitplanken. In den meisten Organisationen entsteht eine Mischform: zentrale Standards (Namensregeln, Basissicherheit), dezentrale Entscheidungen im Rahmen dieser Standards (wer ist im Team).

Auch das *Ausnahmemanagement* gehört in das Betriebsmodell. Es wird immer Fälle geben, in denen eine Regel nicht passt: ein Projekt mit einem Dutzend externer Partner, ein Labor mit besonderen Geräten. Ohne definierten Weg entstehen Ausnahmen informell, ohne Ablaufdatum und ohne Dokumentation, und sie werden zur größten Sicherheitslücke im Regelwerk. Ein reifes Betriebsmodell verlangt für jede Ausnahme eine Begründung, einen Genehmiger, ein Ablaufdatum und eine regelmäßige Überprüfung. Genau dafür sind die Access Reviews gedacht, die Sie im Modul 02 kennenlernen: Die Entra-Dokumentation nennt ausdrücklich den Anwendungsfall, die Ausnahmeliste einer Richtlinie zu pflegen und Prüfern den Nachweis zu liefern, dass diese Ausnahmen regelmäßig überprüft werden.

Das folgende Skript setzt das Ownership-Prinzip als aufdeckende Kontrolle um. Es sucht alle Microsoft-365-Gruppen, die weniger als zwei Besitzer haben, und schreibt sie in eine CSV-Datei, die als Arbeitsliste für das Governance-Team dient. Die Eingabe ist ein Parameter für die Mindestzahl an Besitzern, damit das Skript an die eigene Regel angepasst werden kann.

**Find-GroupsWithFewOwners.ps1**

```powershell
param(
    [int]$MinOwners = 2,
    [string]$OutFile = ".\gruppen-ohne-ausreichend-besitzer.csv"
)

Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
          -Property Id,DisplayName,CreatedDateTime

$result = foreach ($g in $groups) {
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All)
    if ($owners.Count -lt $MinOwners) {
        [pscustomobject]@{
            Gruppe      = $g.DisplayName
            GruppenId   = $g.Id
            Besitzer    = $owners.Count
            Erstellt    = $g.CreatedDateTime
        }
    }
}

$result | Sort-Object Besitzer, Gruppe | Export-Csv $OutFile -NoTypeInformation -Encoding UTF8
Write-Host ("{0} von {1} Gruppen haben weniger als {2} Besitzer." -f @($result).Count, @($groups).Count, $MinOwners)
```

Im Kopf des Skripts legt der `param`-Block zwei Eingaben fest, die den Wert der Regel und den Ausgabepfad steuern. Die Anmeldung verlangt nur lesende Gruppenrechte. Die erste Abfrage lädt alle Microsoft-365-Gruppen mit nur drei Eigenschaften, was bei großen Tenants Zeit und Datenvolumen spart. Die `foreach`-Schleife fragt für jede Gruppe die Besitzer ab und merkt sich die Gruppen, die unter dem Mindestwert liegen. Das Umhüllen mit `@(...)` stellt sicher, dass auch bei genau einem oder keinem Besitzer eine Liste vorliegt, deren Anzahl man zählen kann. Zum Schluss wird sortiert, exportiert und eine Zusammenfassung ausgegeben. Beachten Sie, dass die Schleife pro Gruppe einen Serviceaufruf macht. In einem Tenant mit zehntausenden Gruppen dauert das lange und kann gedrosselt werden. Für den Dauerbetrieb nutzt man dann Stapelabfragen oder Berichte, Thema des Moduls 11.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist ein Betriebsmodell, das nur aus einer Person besteht. Fällt diese Person aus, steht die Governance still. Ebenso häufig ist das Gegenstück: ein Gremium, das so viele Mitglieder hat, dass nie jemand entscheidet. Die folgende Gegenüberstellung zeigt, wie ein Ausnahmeprozess aussehen kann, der funktioniert, und wie nicht.

```
FALSCH:  "Marketing darf Gaeste einladen." (Mail vom Admin, kein Datum,
          kein Verantwortlicher, keine Pruefung)

RICHTIG: Ausnahme AUS-2026-014
          Wer:        Abteilung Marketing, Verantwortlich: Frau Beispiel
          Was:        Einladung externer Agenturen in Team "MKT-Kampagnen"
          Genehmigt:  Security-Board, 2026-03-02
          Gueltig bis:2026-09-30 (danach Neubeantragung)
          Pruefung:   Access Review quartalsweise, Pruefer: Teambesitzer
```

### Praxisbezug.

Wenn Sie in ein bestehendes Projekt einsteigen, ist die erste Frage an den Kunden oft einfach: „Wer ist heute dafür zuständig, dass dieses Team aufgeräumt wird?“ Die Antwort „Das macht die IT“ ist meist das Anzeichen dafür, dass es kein Operating Model gibt. Beginnen Sie klein: Benennen Sie pro Prozess einen Verantwortlichen, schreiben Sie den Ablauf auf einer Seite auf und legen Sie einen festen Termin für die Überprüfung fest. Das ist wirksamer als ein vollständiges Betriebshandbuch, das niemand liest.

> **Merke**
>
> Ein Operating Model verbindet Organisation, Prozesse, Werkzeuge, Reporting und Verbesserung. Das Ownership-Prinzip („jedes Objekt hat benannte Verantwortliche“) und ein sauberes Ausnahmemanagement (Begründung, Genehmiger, Ablaufdatum, Prüfung) sind seine wichtigsten Stützen.

## 1.3 M365 Workload Landscape

Bevor man Microsoft 365 regelt, muss man wissen, woraus es besteht. Die Landschaft der Dienste (englisch Workload Landscape) lässt sich in vier Ebenen ordnen, und diese Ordnung hilft in jeder Diskussion, weil sie zeigt, wo eine Einstellung wirkt und welche anderen Dienste davon berührt werden.

Die unterste Ebene ist die *Identitätsebene*: Microsoft Entra ID verwaltet Benutzer, Gruppen, Geräte, Anwendungen und die Anmeldung. Alles andere in Microsoft 365 verlässt sich auf diese Ebene. Sie ist deshalb das Fundament der Governance. Darauf sitzt die *Arbeitsebene* mit den Diensten, die Benutzer täglich sehen: Exchange Online für E-Mail und Kalender, SharePoint Online und OneDrive für Dateien und Websites, Teams für Chat, Besprechungen und Kanäle, daneben Planner, Forms, Loop und Viva Engage. Eine dritte Ebene bilden die *Schutz- und Nachweisdienste*: Microsoft Purview für Informationsschutz, Aufbewahrung, Audit und eDiscovery sowie Microsoft Defender für Bedrohungsabwehr. Als vierte Ebene kommen die *Verwaltungs- und Automatisierungsschnittstellen* hinzu: die Administrationsportale, PowerShell-Module, Microsoft Graph und angebundene Werkzeuge wie Power Automate.

Wichtig ist das Verständnis, wie die Dienste miteinander verknüpft sind. Die Dokumentation zum Lebensende von Gruppen und Teams beschreibt es anschaulich: Eine Microsoft-365-Gruppe ist die gemeinsame Klammer. Ein Team besitzt eine Gruppe, ein Postfach, eine SharePoint-Website, ein OneNote-Notizbuch und häufig Planner-Pläne, Forms und Power-BI-Inhalte. Wird die Gruppe gelöscht, werden die meisten dieser Ressourcen mit gelöscht. Ausnahmen sind etwa Videos in Stream oder Flows in Power Automate, die ihrem Ersteller gehören und deshalb bestehen bleiben. Diese Verknüpfung hat zwei Folgen für die Governance. Eine Einstellung an einer Stelle wirkt oft auf mehrere Dienste, zum Beispiel die Einschränkung der Gruppenerstellung, die laut Dokumentation Outlook, SharePoint, Viva Engage, Teams, Planner und weitere Dienste betrifft. Und eine Entscheidung zum Lebenszyklus muss immer den gesamten Gruppenverbund berücksichtigen, nicht nur den Dienst, den der Benutzer gerade sieht.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „End of lifecycle options for groups, teams, and Viva Engage“ listet die mit einer Gruppe verbundenen Dienste auf: Teams (Kanalunterhaltungen und Dateien), Forms, OneNote, Outlook (Postfach und Kalender), Planner, Power Automate, Power BI, Project for the web, Roadmap, SharePoint, Stream und Viva Engage. Gruppen und Teams bleiben nach dem Löschen 30 Tage im Zustand „vorläufig gelöscht“ und können in dieser Zeit wiederhergestellt werden. Danach werden sie samt zugehörigen Ressourcen endgültig entfernt. Inhalte, die durch eine Aufbewahrungsrichtlinie geschützt sind, bleiben über eDiscovery auffindbar.

Eine Landkarte der Lizenzierung gehört ebenfalls dazu, denn Lizenzen bestimmen, welche Governance-Funktionen überhaupt verfügbar sind. Das Beispiel aus der Dokumentation: Die Namensrichtlinie, die Ablaufrichtlinie und die Einschränkung der Gruppenerstellung setzen Microsoft Entra ID P1 (beziehungsweise P2 oder die Bildungsvariante Basic EDU) voraus, und die Funktionen für Zugriffspakete, Zugriffsüberprüfungen und Lifecycle Workflows verlangen Microsoft Entra ID Governance oder Microsoft Entra Suite, wobei einzelne Funktionen auch mit P2 funktionieren. Ein gutes Governance-Konzept beginnt daher mit der Frage, welche Lizenz die Organisation hat, bevor es Funktionen verspricht, die nicht verfügbar sind. Das Beispielskript liest die abonnierten Lizenzen aus dem Tenant aus und zeigt, wie viele Einheiten gekauft und verbraucht sind.

**Get-LicenseOverview.ps1**

```powershell
Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome

Get-MgSubscribedSku |
    Select-Object @{n='Lizenz';e={$_.SkuPartNumber}},
                  @{n='Gekauft';e={$_.PrepaidUnits.Enabled}},
                  @{n='Zugewiesen';e={$_.ConsumedUnits}},
                  @{n='Frei';e={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}},
                  @{n='Dienstplaene';e={$_.ServicePlans.Count}} |
    Sort-Object Lizenz |
    Format-Table -AutoSize
```

Das Skript liest mit einem einzigen Aufruf alle Abonnements des Tenants. Die berechneten Spalten (Hashtabellen mit `n` für den Namen und `e` für den Ausdruck) benennen die Felder verständlich um und rechnen die freien Einheiten aus. Die Spalte „Dienstplaene“ zeigt, wie viele einzelne Dienstkomponenten in einer Lizenz stecken: Eine Lizenz ist ein Bündel aus vielen Dienstplänen, und genau diese Dienstpläne entscheiden, ob zum Beispiel Exchange Online, Teams oder eine bestimmte Purview-Funktion verfügbar ist. Wer die Landschaft verstehen will, sollte einmal die Dienstpläne einer Lizenz im Detail ansehen. Das geht mit `(Get-MgSubscribedSku | Select-Object -First 1).ServicePlans`.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, Dienste isoliert zu betrachten. Wer in SharePoint das externe Teilen abschaltet, aber in Teams Gastzugriff erlaubt, erzeugt Frust: Gäste können dem Team beitreten, sehen aber den Dateien-Tab nicht, weil Teams-Dateien in SharePoint liegen. Die Microsoft-Dokumentation zu Gasteinstellungen weist genau auf diese Wechselwirkung hin und empfiehlt, die Einstellungen aufeinander abzustimmen. Ein zweiter Fehler ist die Annahme, jede im Portal sichtbare Funktion sei lizenziert und verfügbar. Das Gegenbeispiel zeigt, wie man die Lizenzfrage vor dem Konzept klärt.

```
FALSCH:  Konzept verspricht "automatische Gaeste-Rezertifizierung
          alle 90 Tage" - Lizenzlage wurde nicht geprueft.

RICHTIG: Schritt 1: Get-LicenseOverview.ps1 ausfuehren
          Schritt 2: Funktionsmatrix gegen Lizenzen abgleichen
                     (Entra ID Governance / P2 vorhanden?)
          Schritt 3: Konzept nur mit verfuegbaren Funktionen planen,
                     Luecken als Budgetposten ausweisen
```

### Praxisbezug.

In Workshops mit Kunden zeichnet man die Workload Landscape oft an ein Whiteboard: eine Spalte pro Dienst, darunter die Verantwortlichen, Richtlinien und Lizenzen. Dabei fällt fast immer auf, dass für einzelne Dienste niemand zuständig ist, etwa für Planner, Loop oder Forms, die Benutzer nutzen, ohne dass die IT sie je bewusst freigegeben hat. Diese Lücken zu finden ist der Mehrwert der Übung. Das Lizenzskript liefert die Fakten dazu in Minuten.

> **Merke**
>
> Microsoft 365 besteht aus Identität, Arbeitsdiensten, Schutz- und Nachweisdiensten sowie Schnittstellen. Die Microsoft-365-Gruppe verbindet viele Dienste. Governance-Einstellungen wirken deshalb dienstübergreifend, und Lizenzen entscheiden, welche Kontrollen überhaupt verfügbar sind.

## 1.4 Rollen und Verantwortlichkeiten

Mit der Landkarte der Dienste im Kopf stellt sich die nächste Frage: Wer ist wofür verantwortlich? In Microsoft 365 gibt es dazu zwei verschiedene Ebenen, die man sauber trennen muss. Die erste Ebene sind die *organisatorischen* Rollen, also die Verantwortlichkeiten innerhalb der Governance, zum Beispiel Sponsor, Policy Owner oder Datenverantwortlicher. Die zweite Ebene sind die *technischen* Rollen, also Berechtigungen im System, zum Beispiel Globaler Administrator oder SharePoint-Administrator. Eine organisatorische Verantwortung führt nicht automatisch zu einer technischen Berechtigung, und eine technische Berechtigung begründet keine fachliche Entscheidungsbefugnis. Die Trennung zu pflegen ist eine der wirksamsten Maßnahmen der gesamten Governance.

Auf organisatorischer Ebene hat sich eine Reihe von Rollen bewährt. Der *Sponsor* (häufig ein Mitglied der Geschäftsleitung) gibt dem Governance-Programm Rückhalt und Budget. Der *Governance-Verantwortliche* (Governance Lead) hält das Regelwerk zusammen und führt das Governance-Gremium. Die *Policy Owner* sind für einzelne Richtlinien zuständig, etwa für die Gastzugriffs-Richtlinie. Die *Service Owner* verantworten je einen Dienst wie Teams oder SharePoint. Die *Datenverantwortlichen* (Data Owner) entscheiden, wie sensibel Informationen sind. Dazu kommen die *Besitzer* von Teams, Gruppen und Websites, die im Tagesgeschäft Mitglieder verwalten und Erneuerungen bestätigen, sowie die *Champions* in den Fachbereichen, die Kolleginnen und Kollegen unterstützen. Eine bewährte Darstellung ist die RACI-Matrix: Für jede Aufgabe wird festgelegt, wer *Responsible* (führt aus), *Accountable* (trägt die Gesamtverantwortung, genau eine Person), *Consulted* (wird befragt) und *Informed* (wird informiert) ist.

| **Aufgabe**                     | **Governance Lead** | **Service Owner** | **Teambesitzer** | **Datenschutz** |
|:--------------------------------|:--------------------|:------------------|:-----------------|:----------------|
| Namensrichtlinie festlegen      | A                   | R                 | I                | C               |
| Gastzugriff im Team verlängern  | I                   | C                 | A/R              | C               |
| Aufbewahrungsfristen definieren | C                   | C                 | I                | A/R             |

Beispiel einer RACI-Matrix für drei Governance-Aufgaben

Auf technischer Ebene arbeitet Microsoft 365 mit rollenbasierter Zugriffssteuerung (RBAC). Die Microsoft-Dokumentation zu den Best Practices für Entra-Rollen formuliert den Kern als *Prinzip der geringsten Rechte*: Jeder Administrator erhält genau die Berechtigungen, die er für seine Aufgabe braucht, für den Bereich, den er verantwortet, und für den Zeitraum, in dem er sie benötigt. Es gibt über 65 integrierte Rollen, und wenn keine passt, lassen sich eigene Rollen definieren. Ergänzend ermöglichen administrative Einheiten, eine Rolle auf einen Teil des Verzeichnisses zu begrenzen, etwa einen Standort. Wichtig ist, dass der Globale Administrator nicht als Alltagsrolle gedacht ist, sondern für Notfälle reserviert bleibt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „Best practices for Microsoft Entra roles“ empfiehlt unter anderem: weniger als fünf Personen mit der Rolle Globaler Administrator, weniger als zehn privilegierte Rollenzuweisungen insgesamt, Multifaktor-Authentifizierung für alle Administratorkonten, Just-in-Time-Zugriff über Privileged Identity Management (PIM), wiederkehrende Zugriffsüberprüfungen für privilegierte Rollen sowie cloud-native Konten statt synchronisierter Konten für Rollenzuweisungen. Zusätzlich sollen zwei cloud-only Notfallzugriffskonten dauerhaft mit der Rolle Globaler Administrator versehen sein. Sie sollen nicht an Einzelpersonen gebunden sein, phishing-resistente Anmeldeverfahren wie FIDO2-Schlüssel nutzen, von blockierenden Conditional-Access-Richtlinien ausgenommen sein und mindestens alle 90 Tage getestet werden („Manage emergency access accounts in Microsoft Entra ID“).

Eine weitere organisatorische Besonderheit ist die Frage, wer eigentlich die Besitzer von Teams und Gruppen ist. Auf Teamebene unterscheidet Microsoft Besitzer (Owner), Mitglieder (Member) und Gäste (Guest). Bei Teams lassen sich laut Dokumentation bis zu 100 Besitzer pro Team festlegen. Bei einer gruppenverbundenen SharePoint-Website werden die Gruppenbesitzer automatisch zu Website-Administratoren und die Gruppenmitglieder zu Website-Mitgliedern. Die Dokumentation zu den Website-Berechtigungen rät deshalb, die Berechtigungen über die Gruppen- beziehungsweise Teammitgliedschaft zu verwalten, statt Personen direkt auf der Website zu berechtigen, weil das die Verwaltung vereinfacht und den Zugriff über alle Ressourcen der Gruppe hinweg einheitlich hält.

Das folgende Skript prüft eine der zentralen technischen Governance-Regeln, nämlich wie viele Personen die Rolle Globaler Administrator tatsächlich haben. Es zählt getrennt die *aktiven* Zuweisungen (Person hat die Rolle jederzeit) und die *berechtigten* Zuweisungen (Person kann sie über PIM aktivieren). Die Unterscheidung ist wichtig, denn ein häufiger Auswertungsfehler besteht darin, nur die aktiven Zuweisungen zu betrachten und die berechtigten zu übersehen, oder umgekehrt.

**Get-GlobalAdminReport.ps1**

```powershell
# Rollen-ID "Global Administrator" (fuer alle Tenants gleich)
$gaRoleId = "62e90394-69f5-4237-9190-012177145e10"

Connect-MgGraph -Scopes "RoleManagement.Read.Directory","Directory.Read.All" -NoWelcome

$active = Get-MgRoleManagementDirectoryRoleAssignment `
            -Filter "roleDefinitionId eq '$gaRoleId'" -ExpandProperty principal -All

$eligible = Get-MgRoleManagementDirectoryRoleEligibilitySchedule `
            -Filter "roleDefinitionId eq '$gaRoleId'" -ExpandProperty principal -All

function Show-Principals($label, $items) {
    Write-Host "`n$label ($(@($items).Count))" -ForegroundColor Cyan
    foreach ($i in $items) {
        $p = $i.Principal.AdditionalProperties
        "{0,-40} {1}" -f $p.userPrincipalName, $p.displayName
    }
}

Show-Principals "Aktive Globale Administratoren"       $active
Show-Principals "Berechtigte Globale Administratoren"   $eligible

if (@($active).Count -ge 5) {
    Write-Warning "Empfehlung ueberschritten: weniger als 5 Globale Administratoren."
}
```

Die Rollen-ID des Globalen Administrators ist in jedem Tenant dieselbe, weil es sich um eine Rollenvorlage handelt. Die zwei Abfragen verwenden die moderne Rollenverwaltungs-Schnittstelle von Graph: `RoleAssignment` liefert die aktiven Zuweisungen und `RoleEligibilitySchedule` die PIM-berechtigten. Mit `-ExpandProperty principal` wird gleich das Zielobjekt (Benutzer oder Gruppe) mitgeladen, sodass keine zweite Abfrage nötig ist. Die Hilfsfunktion gibt Name und Anmeldename in Spalten aus. Handelt es sich bei einer Zuweisung um eine Gruppe, hat `userPrincipalName` keinen Wert, und die Zeile bleibt leer. In diesem Fall lohnt sich ein genauerer Blick, denn Rollenzuweisungen an Gruppen sind ein legitimer, aber prüfungsbedürftiger Weg. Die abschließende Warnung setzt die Faustregel aus der Dokumentation in eine automatische Prüfung um.

### Typische Fehler und Stolperfallen.

Der Klassiker ist der „Alleskönner-Administrator“: Eine Person mit der Rolle Globaler Administrator erledigt alle Aufgaben, weil das bequem ist. Das erhöht die Angriffsfläche und vermischt Verantwortlichkeiten. Der zweite Klassiker sind verwaiste Rollen: Ein Projektmitarbeiter wird zum Administrator, das Projekt endet, die Rolle bleibt. Dagegen helfen zeitlich befristete, berechtigte Zuweisungen, wie das folgende Beispiel aus den Microsoft-Beispielen zeigt (verkürzt und angepasst).

```powershell
# FALSCH: dauerhafte, aktive Zuweisung ohne Ablauf
#   -> Rolle bleibt bestehen, auch wenn die Aufgabe laengst beendet ist.

# RICHTIG: PIM-berechtigte Zuweisung (eligible) mit Ablaufdatum
$params = @{
    Action           = "AdminAssign"
    Justification    = "Projekt Teams-Migration bis 31.03."
    RoleDefinitionId = "fe930be7-5e62-47db-91af-98c3a49a38b1"   # User Administrator
    DirectoryScopeId = "/"
    PrincipalId      = "<Objekt-ID der Person>"
    ScheduleInfo     = @{
        StartDateTime = Get-Date
        Expiration    = @{ Type = "AfterDateTime"; EndDateTime = (Get-Date).AddDays(60) }
    }
}
New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params
```

Hier wird die Rolle „Benutzeradministrator“ nicht dauerhaft vergeben, sondern als berechtigte Zuweisung mit Begründung und einem Ende nach 60 Tagen. Die Person muss die Rolle bei Bedarf aktivieren, wodurch je nach PIM-Einstellung eine Multifaktor-Prüfung, eine Begründung oder eine Genehmigung verlangt wird. PIM wird im Modul 02 vertieft. Ein dritter Stolperstein ist die Rollenmischung auf einem Konto: Wer mit seinem Alltagskonto auch administriert, nutzt das Postfach und den Browser mit Rechten, die ein Phishing-Angriff sofort ausnutzen kann. Getrennte Administratorkonten sind deshalb eine verbreitete Maßnahme.

### Praxisbezug.

Eine RACI-Matrix zu erstellen, ist in Projekten oft die erste Governance-Übung mit echtem Konfliktpotenzial: Plötzlich muss jemand die Rolle „Accountable“ für die Gästerichtlinie übernehmen. Planen Sie dafür einen Workshop mit der Geschäftsleitung ein und halten Sie die Ergebnisse schriftlich fest. Auf der technischen Seite gehört der Bericht über Globale Administratoren in fast jedes Audit. Auditoren fragen als Erstes nach Zahl und Art der privilegierten Konten.

> **Merke**
>
> Trennen Sie organisatorische Verantwortung und technische Berechtigung. Nutzen Sie RACI für die erste und das Prinzip der geringsten Rechte mit PIM, Notfallkonten und Überprüfungen für die zweite. Eine Rolle ohne Ablaufdatum ist ein Risiko.

## 1.5 Policy Framework

Eine Governance ohne schriftliche Regeln ist Hörensagen. Das *Policy Framework* (Richtlinienrahmen) ist die Struktur, in der diese Regeln geordnet, verabschiedet und gepflegt werden. Der Begriff Richtlinie ist dabei doppeldeutig, und genau das führt zu Verwirrung. In Microsoft 365 gibt es technische Richtlinien: die Namensrichtlinie, die Ablaufrichtlinie, die Conditional-Access-Richtlinie, die DLP-Richtlinie. In der Organisation gibt es Richtliniendokumente, in denen Sollzustände beschrieben werden. Ein gutes Policy Framework verbindet beide Welten: Das Dokument sagt, was gelten soll und warum, und die technische Richtlinie setzt es durch.

Üblicherweise besteht ein Policy Framework aus vier Dokumentebenen. Die *Richtlinie* (Policy) legt Grundsätze auf hoher Ebene fest, etwa „Informationen werden nach ihrer Schutzbedürftigkeit klassifiziert und geschützt“. Sie ist kurz, stabil und wird von der Geschäftsleitung verabschiedet. Der *Standard* (Standard) konkretisiert verbindlich, was erreicht werden muss, etwa „Dokumente mit der Klassifizierung ‚Vertraulich‘ dürfen nicht an externe Personen freigegeben werden“. Die *Verfahrensanweisung* (Procedure oder Runbook) beschreibt Schritt für Schritt, wie eine Aufgabe ausgeführt wird. Die *Leitlinie* (Guideline) gibt empfehlende Hinweise, die nicht verbindlich sind. Die Ebenen unterscheiden sich in Änderungshäufigkeit und Verbindlichkeit: Oben stehen langlebige Grundsätze, unten stehen schnell veränderliche Arbeitsanweisungen.

Zu jeder Richtlinie gehört ein Steckbrief mit festen Angaben: Titel, Zweck, Geltungsbereich, Verantwortlicher (Policy Owner), Genehmiger, Version, Gültigkeitsdatum, Überprüfungsintervall und Verweise auf technische Umsetzungen. Dieser Steckbrief macht Richtlinien prüfbar. Eine Richtlinie ohne Verantwortlichen und ohne Überprüfungsdatum veraltet unbemerkt. Nützlich ist außerdem eine Zuordnung von Richtlinie zu Kontrolle: Zu jeder Regel wird die technische Maßnahme benannt, die sie umsetzt, und die Messgröße, mit der man die Einhaltung überprüft. Aus dieser Zuordnung ergibt sich später der Nachweis für Audits.

> **Ergänzung aus der Nachrecherche**
>
> Für die technische Umsetzung nennt die Microsoft-Dokumentation zur Planung von Teams-Governance konkrete Entscheidungspunkte, die jede Organisation vorab klären sollte: ob eine Namenskonvention nötig ist, ob Teams klassifiziert werden sollen, ob Gäste pro Team eingeschränkt werden sollen, wer Teams erstellen darf, ob ein Ablaufdatum verlangt wird, welche Aufbewahrungsrichtlinien gelten und ob inaktive Teams archiviert werden sollen. Sie empfiehlt, die Anforderungen zu dokumentieren, sie bei der Einführung umzusetzen und den Benutzern bekannt zu machen. Besonders betont wird, dass sich Governance-Anforderungen leichter einführen lassen, bevor die Nutzung im Unternehmen skaliert.

Der moderne Ansatz, Richtlinien zugleich lesbar und prüfbar zu machen, ist *Policy as Code*. Dabei wird die Regel in einem strukturierten, maschinenlesbaren Format abgelegt, zum Beispiel in einer JSON-Datei, und ein Skript vergleicht den Tenant-Zustand mit dieser Datei. Das ist die Brücke zwischen Dokument und Technik, und sie wird im Modul 11 ausgebaut. Schon jetzt lässt sich das Prinzip an einem kleinen Beispiel zeigen. Die JSON-Datei beschreibt vier Sollwerte, das Skript liest sie und prüft den ersten.

**policy-tenant.json**

```json
{
  "version": "1.0",
  "owner": "Governance Lead",
  "reviewIntervalDays": 180,
  "rules": {
    "maxGlobalAdmins": 4,
    "minGroupOwners": 2,
    "guestsAllowed": true,
    "groupExpirationDays": 365
  }
}
```

**Test-PolicyCompliance.ps1**

```powershell
param([string]$PolicyFile = ".\policy-tenant.json")

$policy = Get-Content $PolicyFile -Raw | ConvertFrom-Json
Connect-MgGraph -Scopes "RoleManagement.Read.Directory" -NoWelcome

$gaRoleId = "62e90394-69f5-4237-9190-012177145e10"
$gaCount  = @(Get-MgRoleManagementDirectoryRoleAssignment `
              -Filter "roleDefinitionId eq '$gaRoleId'" -All).Count

$ok = $gaCount -le $policy.rules.maxGlobalAdmins

[pscustomobject]@{
    Regel   = "maxGlobalAdmins"
    Soll    = "<= $($policy.rules.maxGlobalAdmins)"
    Ist     = $gaCount
    Ergebnis= if ($ok) { "OK" } else { "ABWEICHUNG" }
}
```

Die JSON-Datei hält Version, Verantwortlichen und Prüfintervall im Kopf fest, so wie der Steckbrief es verlangt, und die Sollwerte im Abschnitt `rules`. Das Skript liest die Datei als Objekt, zählt die aktiven Zuweisungen des Globalen Administrators und vergleicht den Ist-Wert mit dem Sollwert. Das Ergebnis ist ein Objekt mit den Feldern Regel, Soll, Ist und Ergebnis und kann gesammelt, gespeichert und ausgewertet werden. Wichtig ist der Gedanke dahinter: Eine Änderung der Regel erfolgt in einer versionierbaren Datei (die in einem Repository mit Änderungsverlauf liegen kann), nicht in der Erinnerung eines Administrators. Bei den weiteren drei Regeln im Beispiel würde man analog vorgehen; sie sind als Übung am Modulende vorgesehen.

### Typische Fehler und Stolperfallen.

Zu den häufigsten Fehlern zählen Richtlinien, die nur beschreiben, aber nicht durchgesetzt werden („Papiertiger“), und Richtlinien, die so detailliert sind, dass sie bei der nächsten Produktänderung falsch werden. Das Gegenmittel ist die Schichtung: Grundsätze bleiben stabil, Details stehen in Standards und Verfahren, die häufiger aktualisiert werden. Ein weiterer Fehler ist der fehlende Bezug zwischen Richtlinie und Messung.

```
FALSCH:  "Gaeste duerfen nur bei Bedarf Zugriff erhalten."
          (nicht messbar: was ist "Bedarf", wer prueft, wann?)

RICHTIG: "Gastzugriff wird je Team auf maximal 180 Tage befristet.
          Teambesitzer bestaetigen die Notwendigkeit halbjaehrlich
          in einer Zugriffsueberpruefung. Nicht bestaetigte Gaeste werden
          automatisch entfernt. Kennzahl: Anteil der Gaeste mit
          bestaetigter Pruefung (Ziel: 100 Prozent)."
```

### Praxisbezug.

Kunden besitzen häufig bereits eine IT-Sicherheitsrichtlinie, die aber nichts über Microsoft 365 aussagt. Statt ein zweites Dokument daneben zu stellen, ist es effizienter, einen Anhang „M365-Standards“ anzulegen, der auf die vorhandene Richtlinie verweist. Beginnen Sie mit den Themen, die den Betrieb am meisten schmerzen: Teams-Erstellung, Gastzugriff, Freigabe von Dateien, Aufbewahrung.

> **Merke**
>
> Ein Policy Framework schichtet Grundsatz (Policy), verbindlichen Standard, Verfahren und Leitlinie. Jede Richtlinie braucht Verantwortlichen, Version, Prüfintervall und eine messbare Kontrolle. Policy as Code macht Regeln prüfbar.

## 1.6 Tenant Baseline

Eine *Tenant Baseline* ist die Mindestkonfiguration, die jeder Tenant der Organisation erfüllen muss, bevor weitere Funktionen freigegeben werden. Man kann sie sich als Fundament vorstellen: Sie ist weder besonders aufregend noch besonders individuell, aber ohne sie hängt jede weitere Regel in der Luft. Die Baseline bündelt die wichtigsten Einstellungen aus Identität, Zusammenarbeit, Schutz und Betrieb und hält sie als überprüfbare Checkliste fest.

Der Aufbau der Baseline folgt zweckmäßig den Ebenen der Landschaft. Auf der *Identitätsebene* gehören dazu Multifaktor-Authentifizierung für alle Benutzer, besonders streng für Administratoren, eine Conditional-Access-Grundkonfiguration anstelle der pauschalen Sicherheitsstandards, die Begrenzung der Zahl privilegierter Konten, zwei Notfallzugriffskonten und die Einstellung, wer Gäste einladen darf. Die Dokumentation zu den externen Zusammenarbeitseinstellungen nennt als Voreinstellung, dass jeder im Unternehmen, einschließlich Gästen und Nicht-Administratoren, Gäste einladen kann. Genau diese Voreinstellung sollte bewusst hinterfragt werden. Auf der *Zusammenarbeitsebene* gehören dazu die Entscheidung über die Erstellung von Gruppen und Teams, die Namensrichtlinie, die Ablaufrichtlinie, die Standardeinstellungen für das Teilen in SharePoint und OneDrive sowie die Gastzugriffseinstellungen in Teams. Auf der *Schutzebene* gehören dazu eine erste Taxonomie an Vertraulichkeitsbezeichnungen, Aufbewahrungsrichtlinien und die Aktivierung des Audit-Protokolls. Auf der *Betriebsebene* gehören dazu Benachrichtigungen, Zuständigkeiten für Servicemeldungen und ein Konzept für Änderungen.

Wichtig ist, die Baseline *messbar* zu formulieren. „MFA ist aktiv“ ist eine Behauptung, „Es gibt mindestens eine aktivierte Conditional-Access-Richtlinie, die MFA für alle Benutzer verlangt“ ist eine Prüfung. Für manche Punkte lässt sich die Prüfung automatisieren, für andere nicht: Ob ein Notfallkonto in einem Tresor liegt, kann nur ein Mensch bestätigen. Eine gute Baseline kennzeichnet deshalb für jeden Punkt, ob er automatisiert oder manuell geprüft wird, und wer die Prüfung durchführt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Gasteinstellungen nennt wichtige Standardwerte, die in die Baseline einfließen sollten: In Microsoft Entra ID dürfen standardmäßig alle Benutzer inklusive Gäste Gäste einladen, Zusammenarbeitseinschränkungen sind nicht gesetzt (Einladungen an jede Domäne sind erlaubt), das Teilen in SharePoint ist auf die Stufe „Anyone“ eingestellt, und die Standardfreigabeeinstellung für gruppenverbundene Websites ist „Neue und vorhandene Gäste“, wenn Gruppenbesitzer Personen von außerhalb hinzufügen dürfen. Bei den grenzüberschreitenden Zugriffseinstellungen sind B2B-Direct-Connect-Zugriffe standardmäßig blockiert, B2B-Zusammenarbeit dagegen erlaubt. Ob diese Voreinstellungen zur Organisation passen, ist eine bewusste Entscheidung der Baseline.

Das folgende Skript prüft drei automatisierbare Baseline-Punkte: ob die Sicherheitsstandards (Security Defaults) eingeschaltet sind, wie viele Conditional-Access-Richtlinien existieren und in welchem Zustand sie sind, und wie viele Globale Administratoren es gibt. Es gibt für jede Prüfung ein Objekt mit Ergebnis zurück. Die Ausgabe unterscheidet bewusst zwischen „OK“, „PRUEFEN“ und „MANUELL“, weil nicht jede Abweichung ein Fehler ist.

**Test-TenantBaseline.ps1**

```powershell
Connect-MgGraph -Scopes "Policy.Read.All","RoleManagement.Read.Directory" -NoWelcome

$results = New-Object System.Collections.Generic.List[object]
function Add-Result($Check, $Status, $Detail) {
    $results.Add([pscustomobject]@{ Pruefung=$Check; Status=$Status; Detail=$Detail })
}

# 1. Security Defaults
$sd = Get-MgPolicyIdentitySecurityDefaultEnforcementPolicy
Add-Result "Security Defaults" "INFO" ("aktiv: " + $sd.IsEnabled)

# 2. Conditional Access
$ca = @(Get-MgIdentityConditionalAccessPolicy -All)
$enabled = @($ca | Where-Object State -eq "enabled").Count
$status = if ($enabled -ge 1) { "OK" } elseif ($sd.IsEnabled) { "PRUEFEN" } else { "ABWEICHUNG" }
Add-Result "Conditional Access" $status "$enabled von $($ca.Count) Richtlinien aktiv"

# 3. Globale Administratoren
$gaId = "62e90394-69f5-4237-9190-012177145e10"
$ga = @(Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$gaId'" -All).Count
Add-Result "Globale Administratoren" $(if ($ga -lt 5) {"OK"} else {"PRUEFEN"}) "$ga aktive Zuweisungen"

# 4. Nicht automatisierbar
Add-Result "Notfallkonten (2 Stueck, getestet)" "MANUELL" "Nachweis im Betriebshandbuch"

$results | Format-Table -AutoSize
```

Die lokale Hilfsfunktion `Add-Result` sammelt die Ergebnisse in einer Liste, damit der Hauptteil lesbar bleibt. Die erste Prüfung liest die Richtlinie der Sicherheitsstandards und gibt ihren Zustand nur informativ aus. Die zweite zählt die aktivierten Richtlinien für den bedingten Zugriff und bewertet sie im Zusammenhang mit den Sicherheitsstandards: Sind keine Richtlinien aktiv, aber die Sicherheitsstandards eingeschaltet, ist das ein Prüffall, kein Fehler. Sind weder Richtlinien noch Sicherheitsstandards aktiv, ist das eine Abweichung. Die dritte Prüfung wiederholt die Zählung der Globalen Administratoren. Die vierte kann nicht automatisiert werden und wird als „MANUELL“ geführt. Dadurch entsteht eine ehrliche Baseline: Sie täuscht keine Vollautomatik vor.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist die Baseline als Einmalaktion: Nach der Einführung driftet der Tenant, weil Einstellungen im Alltag geändert werden. Die Baseline muss regelmäßig geprüft werden; Abweichungen werden dokumentiert und entweder korrigiert oder als Ausnahme geführt. Ein anderer Fehler ist, die Baseline mit „allen Einstellungen“ gleichzusetzen. Eine Baseline soll klein genug sein, dass sie jemand pflegen kann.

```
FALSCH:  Baseline mit 400 Einzelpunkten, die niemand liest.
RICHTIG: 25 bis 40 Punkte, jeder mit
          - Soll-Wert
          - Pruefmethode (automatisch / manuell)
          - Verantwortlichem
          - Pruefintervall
```

### Praxisbezug.

Bei jeder Tenant-Übernahme, zum Beispiel nach einer Fusion, ist der Baseline-Check das erste Werkzeug: Er zeigt in einer halben Stunde, wie weit der Tenant vom Standard entfernt ist, und liefert die Priorisierung für die Roadmap. Vergleichen Sie die Ergebnisse mit den Vorgaben der Organisation und mit den Empfehlungen von Microsoft.

> **Merke**
>
> Die Tenant Baseline ist die messbare Mindestkonfiguration. Sie umfasst Identität, Zusammenarbeit, Schutz und Betrieb, kennzeichnet automatisierbare und manuelle Prüfungen und wird regelmäßig kontrolliert, damit der Tenant nicht driftet.

## 1.7 Governance Roadmap

Die Baseline zeigt, wo die Organisation steht, die Policy-Struktur zeigt, wohin sie will. Die *Governance Roadmap* beschreibt den Weg dazwischen. Sie beantwortet die Frage, was in welcher Reihenfolge, mit welchem Aufwand und mit welchem Nutzen umgesetzt wird. Eine Roadmap ist kein Terminplan im engen Sinn, sondern eine begründete Reihenfolge von Maßnahmen, die den Betrieb nicht überfordert und früh sichtbare Ergebnisse liefert.

Der Weg zur Roadmap besteht aus fünf Schritten. Zuerst wird der *Ist-Zustand* erfasst, mit Schnappschuss, Lizenzübersicht, Baseline-Prüfung und Gesprächen mit den Beteiligten. Dann wird der *Soll-Zustand* beschrieben, im Idealfall als Zielarchitektur (siehe die letzte Lerneinheit dieses Moduls). Aus der Differenz entsteht die *Lückenliste* (Gap-Analyse). Die Lücken werden dann *bewertet* und in einen priorisierten Rückstand (Backlog) übersetzt. Zuletzt wird der Backlog in *Wellen* geschnitten, die nacheinander umgesetzt werden. Der Begriff „Welle“ ist nützlich, weil er ausdrückt, dass nach jeder Umsetzung eine Phase des Beobachtens und Lernens folgt.

Für die Bewertung genügt ein einfaches Modell. Jede Maßnahme erhält Punkte für den *Nutzen* (wie stark verbessert sie Sicherheit, Compliance oder Betrieb), für das *Risiko, das sie beseitigt* und für den *Aufwand*. Aus diesen Werten lässt sich ein Prioritätswert berechnen, zum Beispiel (Nutzen plus Risiko) geteilt durch Aufwand. Maßnahmen mit hohem Nutzen und geringem Aufwand sind die sogenannten Quick Wins. Sie sind politisch wertvoll, weil sie das Programm früh sichtbar machen, aber sie dürfen nicht die einzigen Maßnahmen bleiben. Daneben gibt es *Fundamentmaßnahmen*, die selbst wenig sichtbar sind, aber andere erst ermöglichen. Ein Beispiel ist die Klärung der Besitzerschaft von Teams: Ohne sie funktionieren weder Ablaufrichtlinien noch Zugriffsüberprüfungen sinnvoll.

Außerdem müssen *Abhängigkeiten* beachtet werden. Eine sinnvolle Grundordnung lautet: erst Identität und Rollen, dann Zusammenarbeit und Lebenszyklus, dann Datenschutz und Compliance, dann Automatisierung und Optimierung. Die Datenschutzklassifizierung bringt wenig, wenn niemand weiß, wer auf die Daten zugreifen darf. Die Automatisierung der Teamerstellung bringt wenig, wenn die Regeln für Namen, Besitzer und Gäste noch nicht beschlossen sind. Für die Gliederung in diesem Kurs ist diese Grundordnung bereits hinterlegt: Die Module 02 bis 04 behandeln Identität, Teams und SharePoint, die Module 06 bis 08 Daten, Compliance und Sicherheit, die Module 10 und 11 die Automatisierung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Teams-Lebenszyklus hält fest, dass sich Governance-Anforderungen wie Namenskonventionen, Ablauf- und Aufbewahrungsrichtlinien deutlich leichter einführen lassen, bevor die Nutzung im Unternehmen skaliert. Für SharePoint stellt Microsoft mit „SharePoint Advanced Management“ unter anderem Richtlinien für den Lebenszyklus von Websites bereit (Besitzer-, Inaktivitäts- und Bestätigungsrichtlinien). Diese Richtlinien löschen Websites laut Dokumentation nicht direkt, sondern benachrichtigen Besitzer und führen konfigurierbare Maßnahmen aus. Sie sind außerdem ein typischer Treiber, wenn eine Organisation ihre Inhalte für den Einsatz von Microsoft 365 Copilot und Agenten vorbereitet.

Das folgende Skript zeigt, wie sich die Bewertung mit wenigen Zeilen automatisieren lässt. Es nimmt eine kleine Maßnahmenliste im CSV-Format entgegen (hier direkt im Skript eingebettet, damit es ohne weitere Dateien läuft), berechnet den Prioritätswert und sortiert den Backlog. Das Beispiel nutzt erfundene, aber realistische Maßnahmen, die Werte sind Schätzungen auf einer Skala von 1 bis 5.

**New-GovernanceBacklog.ps1**

```powershell
$csv = @"
Massnahme,Nutzen,Risiko,Aufwand,Welle
Notfallzugriffskonten einrichten und testen,4,5,1,1
Besitzerpflicht fuer alle Gruppen durchsetzen,4,3,2,1
Namensrichtlinie aktivieren,2,1,1,1
Gaeste-Rezertifizierung einfuehren,4,4,3,2
Vertraulichkeitsbezeichnungen ausrollen,5,4,5,3
Provisioning-Prozess automatisieren,4,2,5,3
"@

$backlog = $csv | ConvertFrom-Csv | ForEach-Object {
    $score = ([int]$_.Nutzen + [int]$_.Risiko) / [int]$_.Aufwand
    $_ | Add-Member -NotePropertyName Prioritaet -NotePropertyValue ([math]::Round($score,2)) -PassThru
}

$backlog | Sort-Object Welle, @{Expression='Prioritaet';Descending=$true} |
    Format-Table Welle, Prioritaet, Nutzen, Risiko, Aufwand, Massnahme -AutoSize
```

Der Text zwischen `@"` und `"@` ist ein sogenannter Here-String, der mehrzeiligen Text unverändert übernimmt. `ConvertFrom-Csv` wandelt ihn in Objekte um, die Spaltennamen werden zu Eigenschaften. In der Schleife wird für jede Zeile der Prioritätswert nach der Formel berechnet und als neue Eigenschaft angehängt. Die Typumwandlung `[int]` ist notwendig, weil CSV alle Werte zunächst als Text liefert. Ohne sie würde die Division mit Texten fehlschlagen. Zuletzt wird nach Welle aufsteigend und innerhalb der Welle nach Priorität absteigend sortiert. Die Ausgabe ist eine Tabelle, die man direkt in ein Steuerungsgespräch mitnehmen kann.

### Typische Fehler und Stolperfallen.

Typisch ist die Roadmap, die alles gleichzeitig will. Wer im ersten Quartal Namensrichtlinie, Klassifizierung, Provisioning und Gästeprozess startet, überlastet die Fachbereiche und liefert nichts fertig. Ein weiterer Fehler ist das Weglassen der Kommunikation: Maßnahmen, die Benutzer spüren (zum Beispiel eine eingeschränkte Gruppenerstellung), brauchen vorher Ankündigung und danach Unterstützung. Ein dritter Fehler ist die starre Planung ohne Rückkopplung.

```
FALSCH:  Roadmap als Jahresplan mit fixen Terminen fuer 40 Massnahmen.
RICHTIG: Drei Wellen mit je 4 bis 8 Massnahmen. Nach jeder Welle:
          Wirkung messen (Kennzahlen), Rueckmeldungen einholen,
          Backlog neu bewerten.
```

### Praxisbezug.

In Beratungsprojekten wird die Roadmap meist dem Lenkungskreis vorgestellt. Dort entscheiden nicht Techniker, sondern Budgetverantwortliche. Übersetzen Sie die Maßnahmen deshalb in deren Sprache: Risiko, Kosten, Nutzen, Zeitpunkt. Das Bewertungsskript liefert die Begründung für die Reihenfolge. Das Modul 12 baut darauf auf und führt eine 30-60-90-Tage-Planung für die ersten Monate ein.

> **Merke**
>
> Eine Roadmap ist eine begründete Reihenfolge: Ist erfassen, Soll beschreiben, Lücken bewerten, in Wellen umsetzen, messen und neu bewerten. Quick Wins schaffen Sichtbarkeit, Fundamentmaßnahmen schaffen Wirkung.

## 1.8 Zielarchitektur

Die *Zielarchitektur* beschreibt, wie der Tenant in einem gewünschten Endzustand aufgebaut ist: Welche Bausteine gibt es, wie hängen sie zusammen, nach welchen Grundsätzen wurden sie entworfen. Sie ist die Brücke zwischen den Regeln der Governance und der konkreten Konfiguration. Man kann Governance ohne Zielarchitektur betreiben, aber dann fällt jede Einzelentscheidung neu, und der Tenant wächst nach Zufall.

Ein bewährtes Schichtenmodell für die Zielarchitektur unterscheidet fünf Schichten. Die *Steuerungsschicht* enthält Strategie, Richtlinien, Rollen und Entscheidungsgremien, also alles, was in diesem Modul bisher besprochen wurde. Die *Identitäts- und Zugriffsschicht* enthält Entra ID mit Gruppen, Rollen, Gästen, bedingtem Zugriff und Zugriffsverwaltung (Modul 02 und 08). Die *Arbeitsschicht* enthält die Dienste Teams, SharePoint, OneDrive und Exchange mit ihren Standards (Modul 03 bis 05). Die *Schutz- und Nachweisschicht* enthält Informationsschutz, Aufbewahrung, Audit und Untersuchung (Modul 06 und 07). Die *Betriebs- und Automatisierungsschicht* enthält Monitoring, Berichte, Bereitstellungsprozesse und Policy as Code (Modul 09 bis 11). Quer dazu liegen Themen wie Kosten, Akzeptanz und Notfallplanung (Modul 12).

| **Schicht**            | **Inhalt (Beispiele)**                              | **Module** |
|:-----------------------|:----------------------------------------------------|:-----------|
| Steuerung              | Strategie, Richtlinien, Rollen, Gremien             | 01         |
| Identität und Zugriff  | Gruppen, Rollen, Gäste, Conditional Access, Reviews | 02, 08     |
| Arbeit                 | Teams, SharePoint, OneDrive, Exchange               | 03, 04, 05 |
| Schutz und Nachweis    | Labels, DLP, Retention, Audit, eDiscovery           | 06, 07     |
| Betrieb und Automation | Reports, Provisioning, Graph, Policy as Code        | 09, 10, 11 |
| Querschnitt            | Migration, Kosten, Adoption, BCDR                   | 12         |

Schichtenmodell der Zielarchitektur und Zuordnung zu den Modulen dieses Kurses

Eine Architektur ist mehr als ein Bild. Sie beruht auf *Entwurfsprinzipien*, die erklären, warum sie so aussieht. Typische Prinzipien für Microsoft 365 sind: sicher von Anfang an (Secure by Default), geringste Rechte, Selbstbedienung innerhalb von Leitplanken, Automatisierung vor Handarbeit, Nachvollziehbarkeit jeder Änderung und Betriebsfähigkeit im Notfall. Aus dem letzten Prinzip folgt zum Beispiel die Anforderung an die Notfallzugriffskonten. Die Entra-Dokumentation nennt dafür ausdrücklich Szenarien wie einen Ausfall der Föderation oder den Verlust aller Geräte für die Multifaktor-Authentifizierung.

Wichtige Architekturentscheidungen sollten festgehalten werden, und zwar zusammen mit ihrem Grund. Dafür hat sich das Format der *Architecture Decision Records* (ADR) bewährt: eine kurze Seite mit Kontext, Entscheidung, Alternativen und Folgen. Wenn später jemand fragt, warum Gäste nur über Zugriffspakete eingeladen werden dürfen, liegt die Begründung vor, und eine Änderung kann bewusst entschieden werden, statt zufällig zu entstehen.

> **Ergänzung aus der Nachrecherche**
>
> Die Entra-Dokumentation beschreibt drei Lebenszyklen, die sich als Bausteine der Identitätsschicht eignen: den *Identitätslebenszyklus* (Joiner, Mover, Leaver, automatisiert über Lifecycle Workflows und HR-gesteuerte Bereitstellung), den *Zugriffslebenszyklus* (Zugriffspakete, automatische Zuweisung, Zugriffsüberprüfungen) und den *Lebenszyklus privilegierter Zugriffe* (PIM, Just-in-Time-Aktivierung). Ebenfalls erwähnt wird, dass Microsoft Entra ID Governance inzwischen auch Agentenidentitäten (Vorschau) einschließt, die wie Personen über Zugriffspakete verwaltet werden und einen menschlichen Sponsor benötigen. Wer eine Zielarchitektur plant, sollte diese Entwicklung in der Steuerungsschicht berücksichtigen.

Die Zielarchitektur wird nur dann nützlich, wenn man sie mit dem Ist-Zustand vergleichen kann. Das folgende Skript dokumentiert einen Teil der Ist-Architektur automatisch: Es zählt die Gruppen nach Typ und schreibt das Ergebnis als Markdown-Tabelle in eine Datei, die in ein Architekturdokument übernommen werden kann. Gruppen sind ein guter Startpunkt, weil sie Teams, Websites und Berechtigungen zusammenhalten.

**Export-GroupArchitecture.ps1**

```powershell
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$groups = Get-MgGroup -All -Property Id,DisplayName,GroupTypes,SecurityEnabled,MailEnabled,MembershipRule

$typed = $groups | ForEach-Object {
    $typ = if ($_.GroupTypes -contains "Unified") { "Microsoft 365" }
           elseif ($_.SecurityEnabled -and -not $_.MailEnabled) { "Sicherheitsgruppe" }
           elseif ($_.MailEnabled -and -not $_.SecurityEnabled) { "Verteiler" }
           else { "Sonstige" }
    $dyn = [bool]$_.MembershipRule
    [pscustomobject]@{ Typ = $typ; Dynamisch = $dyn }
}

$lines = @("| Typ | Dynamisch | Anzahl |", "|---|---|---|")
$typed | Group-Object Typ, Dynamisch | Sort-Object Name | ForEach-Object {
    $lines += "| {0} | {1} | {2} |" -f $_.Group[0].Typ, $_.Group[0].Dynamisch, $_.Count
}
$lines | Set-Content ".\ist-architektur-gruppen.md" -Encoding UTF8
$lines
```

Die Abfrage lädt alle Gruppen, aber nur fünf Eigenschaften. In der Schleife wird jede Gruppe einem Typ zugeordnet: Eine Gruppe mit dem Typ „Unified“ ist eine Microsoft-365-Gruppe. Eine reine Sicherheitsgruppe ist sicherheitsfähig, aber nicht mit E-Mail verbunden. Ein Verteiler ist mit E-Mail verbunden, aber nicht sicherheitsfähig. Alles andere landet in „Sonstige“. Eine Gruppe mit einer Mitgliedschaftsregel ist dynamisch, ihre Mitglieder ergeben sich automatisch aus Benutzereigenschaften. Danach gruppiert `Group-Object` nach der Kombination aus Typ und dynamischem Verhalten und baut zeilenweise eine Markdown-Tabelle. Der Aufruf von `Set-Content` schreibt sie in eine Datei und die letzte Zeile zeigt sie an.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die „Wunscharchitektur ohne Bezug zum Betrieb“: ein schönes Zielbild, das niemand pflegen kann. Der zweite Fehler ist das Gegenteil, die dokumentierte Ist-Architektur, die als Ziel ausgegeben wird, obwohl sie aus Zufall entstanden ist. Ein dritter Fehler ist die fehlende Testumgebung. Änderungen an Richtlinien, die sich auf alle Benutzer auswirken, sollten zuerst in einem Testtenant oder an einer Pilotgruppe erprobt werden. Für die Architektur heißt das, dass der Weg der Änderung (Test, Pilot, Produktion) mitgedacht wird.

```
FALSCH:  "Wir aendern die Gaesteregel direkt im Produktivtenant,
          morgens um 9 Uhr, ohne Ankuendigung."
RICHTIG: 1. Aenderung als ADR/Aenderungsantrag beschreiben
          2. Test im Testtenant oder an einer Pilotgruppe
          3. Ankuendigung an Teambesitzer
          4. Umsetzung ausserhalb der Kernzeiten
          5. Ergebnis pruefen, Rueckfallplan bereithalten
```

### Praxisbezug.

Eine einseitige Übersicht der Zielarchitektur mit den fünf Schichten ist in jedem Kundenprojekt ein hilfreiches Kommunikationsmittel. Sie macht für Nicht-Techniker sichtbar, wie die Bausteine zusammenhängen, und liefert eine Gliederung für Workshops. Die Zuordnung der Kursmodule zu den Schichten, wie in der Tabelle gezeigt, ist ein guter Ausgangspunkt für einen Projektplan.

> **Merke**
>
> Die Zielarchitektur beschreibt Bausteine, Zusammenhänge und Entwurfsprinzipien. Entscheidungen werden mit Begründung festgehalten (ADR), und der Weg einer Änderung (Test, Pilot, Produktion) gehört zur Architektur.

## Übungsaufgaben

**Aufgabe 1 (leicht, Wissen).** Ordnen Sie die folgenden Maßnahmen den Kontrolltypen *vorbeugend*, *aufdeckend* oder *korrigierend* zu und begründen Sie kurz: (a) Namensrichtlinie für Gruppen, (b) monatlicher Bericht über Gruppen ohne Besitzer, (c) Wiederherstellen einer gelöschten Gruppe, (d) Einschränkung der Gruppenerstellung auf eine Sicherheitsgruppe.

**Aufgabe 2 (leicht, Wissen).** Erklären Sie in je einem Satz den Unterschied zwischen Governance, Management und Administration. Ordnen Sie dann zu: „Der Teamverantwortliche legt fest, dass Gäste nach 180 Tagen ablaufen.“, „Ein Administrator legt ein Team an.“, „Die IT-Leitung plant die Einführung der Ablaufrichtlinie bis Ende des Quartals.“

**Aufgabe 3 (mittel, Konzept).** Die folgende RACI-Zeile ist fehlerhaft: Aufgabe „Gastzugriff verlängern“, Teambesitzer = A, Governance Lead = A, Service Owner = R. Beschreiben Sie den Fehler und korrigieren Sie die Zeile begründet.

**Aufgabe 4 (mittel, Praxis).** Erweitern Sie das Skript `Find-GroupsWithFewOwners.ps1` so, dass nur Gruppen berücksichtigt werden, die älter als 30 Tage sind (neue Gruppen werden häufig erst nach der Erstellung vollständig eingerichtet). Verwenden Sie die Eigenschaft `CreatedDateTime`.

**Aufgabe 5 (mittel, Praxis).** Ergänzen Sie die Datei `policy-tenant.json` um die Regel `maxGuestShare` (maximaler Anteil der Gäste an allen Benutzern, Wert 0.2) und erweitern Sie `Test-PolicyCompliance.ps1` um die Prüfung dieser Regel. Verwenden Sie `Get-MgUserCount`.

**Aufgabe 6 (mittel, Konzept).** Formulieren Sie die vage Aussage „Die Zusammenarbeit mit Externen ist sicher“ als messbaren Baseline-Punkt mit Soll-Wert, Prüfmethode (automatisch oder manuell), Verantwortlichem und Prüfintervall.

**Aufgabe 7 (schwer, Konzept).** Ein Mittelständler mit 800 Beschäftigten, einer IT-Abteilung von sechs Personen und starker Nutzung von Teams möchte ein Operating Model einführen. Entwerfen Sie auf einer Seite die Rollen, die drei wichtigsten Prozesse und die Kennzahlen. Begründen Sie, ob Sie ein zentrales oder föderiertes Modell wählen.

**Aufgabe 8 (schwer, Praxis).** Erweitern Sie `New-GovernanceBacklog.ps1` so, dass Nutzen und Risiko unterschiedlich gewichtet werden können (Parameter `-WeightBenefit` und `-WeightRisk`, Standardwert 1) und dass Maßnahmen mit Aufwand 0 oder einem nicht numerischen Wert eine verständliche Fehlermeldung erzeugen, statt das Skript abstürzen zu lassen.

## Lösungen

**Lösung zu Aufgabe 1.** (a) vorbeugend: Die Richtlinie greift bei der Erstellung und verhindert unerwünschte Namen. (b) aufdeckend: Der Bericht findet bestehende Verstöße nach dem Ereignis. (c) korrigierend: Der gewünschte Zustand wird wiederhergestellt, nachdem ein Fehler passiert ist. (d) vorbeugend: Nur Mitglieder der Erstellergruppe können überhaupt Gruppen anlegen. Wichtig ist die Begründung: Der Zeitpunkt der Wirkung (vor, nach oder bei der Korrektur eines Ereignisses) entscheidet.

**Lösung zu Aufgabe 2.** Governance legt fest, wer nach welchen Regeln entscheidet. Management organisiert die Umsetzung mit Ressourcen und Terminen. Administration führt die technischen Tätigkeiten im Alltag aus. Zuordnung: Die 180-Tage-Regel ist Governance (Regelsetzung). Das Anlegen des Teams ist Administration. Die Planung der Einführung bis Quartalsende ist Management.

**Lösung zu Aufgabe 3.** Pro Aufgabe darf es nur einen Accountable (Gesamtverantwortlichen) geben. Zwei A bedeuten, dass im Konfliktfall niemand entscheidet. Korrekt ist: Teambesitzer = A/R (er kennt die Notwendigkeit und führt die Verlängerung aus), Service Owner = C (berät zur Technik), Governance Lead = I (wird informiert, prüft die Einhaltung des Standards). Die Zeile bildet damit das föderierte Prinzip ab: Die Entscheidung liegt bei dem, der den Bedarf kennt.

**Lösung zu Aufgabe 4.** Das Filtern geschieht nach dem Laden der Gruppen in der Schleife, weil `CreatedDateTime` bereits im Property-Auswahlsatz enthalten ist:

```powershell
$cutoff = (Get-Date).AddDays(-30)
$result = foreach ($g in $groups) {
    if ($g.CreatedDateTime -gt $cutoff) { continue }   # zu neu, ueberspringen
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All)
    if ($owners.Count -lt $MinOwners) {
        [pscustomobject]@{ Gruppe=$g.DisplayName; GruppenId=$g.Id
                           Besitzer=$owners.Count; Erstellt=$g.CreatedDateTime }
    }
}
```

Die Schleife überspringt mit `continue` jede Gruppe, die nach dem Stichtag erstellt wurde, und spart damit auch die Besitzerabfrage. Als Verbesserung könnten Sie den Wert 30 als Parameter `-MinAgeDays` anbieten.

**Lösung zu Aufgabe 5.** In der JSON-Datei wird unter `rules` die Zeile `"maxGuestShare": 0.2` ergänzt. Im Skript kommt hinzu:

```powershell
Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All" -NoWelcome
$all    = Get-MgUserCount -ConsistencyLevel eventual
$guests = Get-MgUserCount -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$share  = if ($all -gt 0) { [math]::Round($guests / $all, 3) } else { 0 }

[pscustomobject]@{
    Regel    = "maxGuestShare"
    Soll     = "<= $($policy.rules.maxGuestShare)"
    Ist      = $share
    Ergebnis = if ($share -le $policy.rules.maxGuestShare) { "OK" } else { "ABWEICHUNG" }
}
```

Wichtig sind der erweiterte Abfragemodus (`ConsistencyLevel eventual`), den die Zählabfragen für Filter benötigen, und die Absicherung gegen eine Division durch null in leeren Testtenants.

**Lösung zu Aufgabe 6.** Beispiel: „Jeder Gast ist einem Team zugeordnet und hat eine bestätigte Zugriffsüberprüfung, die nicht älter als 180 Tage ist.“ Soll: 100 Prozent der Gäste. Prüfmethode: automatisch über einen Bericht der Zugriffsüberprüfungen, ergänzt durch eine manuelle Stichprobe von zehn Gästen. Verantwortlicher: Governance Lead (Auswertung), Teambesitzer (Bestätigung). Prüfintervall: vierteljährlich. Eine gute Antwort enthält alle vier Angaben und eine Messgröße, nicht nur eine Absichtserklärung.

**Lösung zu Aufgabe 7.** Eine mögliche Lösung: Mit sechs IT-Mitarbeitern und 800 Beschäftigten ist ein föderiertes Modell mit zentralen Leitplanken sinnvoll, weil das Kernteam die Einzelanfragen nicht allein bewältigen kann. Rollen: ein Governance Lead (Teilzeit in der IT), ein Sponsor aus der Geschäftsführung, Service Owner für Teams/SharePoint und Identität, benannte Besitzer in den Fachbereichen, Champions je Abteilung. Prozesse: (1) Teamanfrage mit Namensstandard und zwei Besitzern, (2) Gastfreigabe mit Befristung und Überprüfung, (3) Ausnahmegenehmigung mit Ablaufdatum. Kennzahlen: Anteil der Gruppen mit mindestens zwei Besitzern, Anteil der Gäste mit gültiger Überprüfung, Anzahl der offenen Ausnahmen. Eine Begründung für die Wahl, die Vor- und Nachteile abwägt, ist wichtiger als die konkrete Auswahl.

**Lösung zu Aufgabe 8.** Ein möglicher Ansatz:

```powershell
param([double]$WeightBenefit = 1, [double]$WeightRisk = 1)

$backlog = $csv | ConvertFrom-Csv | ForEach-Object {
    $aufwand = 0
    if (-not [int]::TryParse($_.Aufwand, [ref]$aufwand) -or $aufwand -le 0) {
        Write-Warning "Massnahme '$($_.Massnahme)': Aufwand muss eine Zahl groesser 0 sein."
        return    # Zeile ueberspringen
    }
    $score = ($WeightBenefit * [int]$_.Nutzen + $WeightRisk * [int]$_.Risiko) / $aufwand
    $_ | Add-Member -NotePropertyName Prioritaet -NotePropertyValue ([math]::Round($score,2)) -PassThru
}
```

`TryParse` wandelt Text sicher in eine Zahl um und liefert bei Misserfolg `false`, statt eine Ausnahme auszulösen. Mit `return` innerhalb von `ForEach-Object` wird nur die aktuelle Zeile verlassen, nicht das ganze Skript. Die Gewichte gehen als Faktoren in die Formel ein. Mit `-WeightRisk 2` bevorzugt man Maßnahmen, die Risiken senken.
