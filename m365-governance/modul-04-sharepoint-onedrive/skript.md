# Modul 04 - SharePoint und OneDrive Governance

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 10 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8,75 Stunden (3 × 1,25 plus 5 × 1). Als Richtwert für den Umfang wurde der höhere Wert (10 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**              | **Dauer (h)** | **Prio** |
|:--------|:-----------------------------|--------------:|---------:|
| 4.1     | Site Provisioning            |          1,25 |        1 |
| 4.2     | Hub Sites und IA             |          1,25 |        1 |
| 4.3     | Permission Model             |             1 |        1 |
| 4.4     | Sharing Controls             |             1 |        1 |
| 4.5     | Sensitivity Labels for Sites |             1 |        1 |
| 4.6     | Storage und Quotas           |             1 |        2 |
| 4.7     | Site Lifecycle               |             1 |        2 |
| 4.8     | SharePoint-Troubleshooting   |          1,25 |        2 |
|         | **Summe laut Details**       |      **8,75** |          |
|         | **Dauer laut Modulblatt**    |        **10** |          |

> **Merke: Schreibweise der Cmdlets**
>
> Die SharePoint-Beispiele verwenden das SharePoint-Online-Verwaltungsmodul (Cmdlets mit `SPO` im Namen) und stellenweise Microsoft Graph. Verbinden Sie sich für die SPO-Cmdlets zuerst mit `Connect-SPOService` und der Adresse des SharePoint Admin Centers Ihres Tenants. Auch hier gilt: Die Beispiele folgen der Microsoft-Dokumentation, wurden aber nicht gegen einen echten Tenant ausgeführt. Testen Sie jedes Skript zuerst in einem Testtenant.

## 4.1 Site Provisioning

Eine SharePoint-Website (Site) ist der Ort, an dem Organisationen Dokumente, Seiten, Listen und Wissen ablegen. Jedes Team in Microsoft Teams hat eine, jedes Intranet besteht aus mehreren davon, und jeder Mitarbeitende hat zusätzlich eine persönliche OneDrive-Website. Wie Websites entstehen, entscheidet darüber, ob ein Tenant zehn Jahre später noch verständlich ist. Der Fachbegriff für das Anlegen heißt *Provisioning*. Gemeint ist nicht nur das technische Erzeugen, sondern auch die Frage, mit welchen Eigenschaften eine Website entsteht: Typ, Besitzer, Sprache, Klassifizierung, Navigation, Berechtigungen.

SharePoint kennt drei Websitetypen, die man auseinanderhalten muss. Eine *Teamwebsite* ist für die Zusammenarbeit in einem Kreis gedacht und gehört meist zu einer Microsoft-365-Gruppe (dann heißt sie *gruppenverbunden*). Ihre Mitgliedschaft folgt der Gruppe. Eine *Kommunikationswebsite* ist für das Veröffentlichen von Informationen gedacht: wenige Personen schreiben, viele lesen. Sie ist nicht mit einer Gruppe verbunden, und ihre Berechtigungen werden direkt in SharePoint gepflegt. Die dritte Art sind *Websites ohne Gruppe* (Teamwebsites der klassischen Art) und die persönlichen Websites in OneDrive. Die Entscheidung zwischen diesen Typen ist eine der wichtigsten Governance-Entscheidungen: Sie bestimmt, wer Besitzer ist, wie Mitgliedschaften gepflegt werden und welche Lebenszyklus-Regeln greifen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Websiteberechtigungen beschreibt, dass bei gruppenverbundenen Teamwebsites die Mitglieder und Besitzer der Microsoft-365-Gruppe automatisch den SharePoint-Gruppen *Mitglieder* und *Besitzer* der Website zugeordnet werden. Bei Kommunikationswebsites und klassischen Teamwebsites pflegt man diese SharePoint-Gruppen direkt. Die Steuerung der Websiteerstellung durch Benutzer (Self-Service) lässt sich im SharePoint Admin Center auf Organisationsebene ein- oder ausschalten. Wer die Erstellung durch Benutzer abschaltet, muss einen Antragsweg anbieten.

Warum ist die Anlage so wichtig? Weil alles, was später korrigiert werden muss, teurer ist als das, was von Anfang an stimmt. Eine Website ohne zweiten Besitzer ist in der Anlage eine Sekunde Arbeit und später ein Suchprojekt. Eine Website mit falschem Typ kann nachträglich kaum geändert werden. Ein sauberer Provisioning-Prozess legt deshalb fest: Welche Typen werden angeboten (Intranet, Team, Projekt, Kunde)? Wer darf anfragen? Welche Pflichtangaben gibt es (Zweck, zwei Besitzer, Klassifizierung, voraussichtliche Laufzeit)? Welche Voreinstellungen sind fix (Sprache, Zeitzone, Freigabe, Speicherquote)? Und wer oder was legt die Website tatsächlich an: Ein Mensch im Admin Center, ein Skript, Power Automate oder eine Bereitstellungsfabrik (Modul 10)?

Das folgende Skript legt eine Kommunikationswebsite mit festen Voreinstellungen an und setzt gleich die Freigabe so, dass keine externe Freigabe möglich ist. Es verwendet `New-SPOSite` mit dem Websitevorlagen-Code für Kommunikationswebsites und wartet nicht auf die Fertigstellung, weil die Anlage im Hintergrund läuft. Danach prüft es, ob die Website erreichbar ist.

**New-GovernedSite.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Tenant,       # z. B. "contoso"
    [Parameter(Mandatory)][string]$Name,         # URL-Teil, z. B. "ABT-Personal-Intranet"
    [Parameter(Mandatory)][string]$Titel,
    [Parameter(Mandatory)][string]$Besitzer      # UPN des Besitzers
)

Connect-SPOService -Url "https://$Tenant-admin.sharepoint.com"

$url = "https://$Tenant.sharepoint.com/sites/$Name"
if (Get-SPOSite -Identity $url -ErrorAction SilentlyContinue) {
    throw "Website existiert bereits: $url"
}

New-SPOSite -Url $url -Title $Titel -Owner $Besitzer `
            -Template "SITEPAGEPUBLISHING#0" -StorageQuota 1024 -NoWait

# Voreinstellung: keine externe Freigabe
Start-Sleep -Seconds 20
Set-SPOSite -Identity $url -SharingCapability Disabled
"Website angelegt (oder in Arbeit): $url"
```

Das Skript prüft zuerst, ob die Adresse schon vergeben ist, und bricht dann ab, damit nichts überschrieben wird. Mit `New-SPOSite` wird eine Website mit der Vorlage `SITEPAGEPUBLISHING#0` angelegt; das ist die Kommunikationswebsite. Der Parameter `-StorageQuota 1024` gibt die Quote in Megabyte an, und `-NoWait` sorgt dafür, dass der Befehl nicht auf das Ende der Anlage wartet. Weil die Anlage eine Weile dauert, wartet das Skript kurz und setzt dann `SharingCapability` auf `Disabled`, was externe Freigabe ausschließt. In einem produktiven Skript würde man statt einer festen Wartezeit in einer Schleife abfragen, ob die Website bereit ist. Außerdem ersetzt dieses Skript keine Prüfung, ob der Name einer Konvention entspricht (siehe Modul 03, Lerneinheit 3.2).

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, dass jede Anfrage eine neue Website erzeugt, obwohl eine Bibliothek in einer bestehenden Website genügt. Das führt zu einer Vielzahl kleiner Websites mit unterschiedlichen Berechtigungen. Der zweite Fehler sind Unterwebsites (Subsites) in neuen Projekten: Sie lassen sich nicht einzeln archivieren oder verschieben und gelten in der modernen Architektur als überholt. Der dritte: Websites ohne Besitzer.

```
FALSCH:  Eine Website pro Teilprojekt mit je eigenem Berechtigungsmodell,
          dazu Unterwebsites fuer jedes Gewerk.

RICHTIG: Eine Website pro Projekt, Bibliotheken pro Gewerk,
          Berechtigungen auf Websiteebene ueber Gruppen,
          viele Projektwebsites ueber eine Hubwebsite verbunden
```

### Praxisbezug.

Beim Kunden beginnt man mit einem Websitekatalog: Welche Typen gibt es, welche sollen künftig angeboten werden? Üblich sind vier bis sechs Typen. Jeder Typ bekommt ein Datenblatt (Zweck, Besitzer, Standardfreigabe, Label, Lebensdauer). Die Datenblätter sind die Grundlage für die Bereitstellungsfabrik und für die Schulung der Besitzer.

> **Merke**
>
> Provisioning legt Typ, Besitzer, Klassifizierung und Voreinstellungen einer Website fest. Der Typ ist schwer nachträglich zu ändern. Pro Websitetyp gibt es ein Datenblatt und einen Antragsweg.

## 4.2 Hub Sites und IA

Die *Informationsarchitektur* (Information Architecture, kurz IA) beschreibt, wie Inhalte gegliedert, benannt und miteinander verbunden sind. In SharePoint gibt es dafür zwei Ebenen: die Struktur innerhalb einer Website (Bibliotheken, Ordner, Metadaten, Navigation) und die Struktur zwischen Websites. Früher bildete man die Struktur zwischen Websites mit Unterwebsites ab, eine feste Hierarchie, bei der der Pfad der Struktur folgt. Heute nutzt man dafür *Hubwebsites*. Eine Hubwebsite ist keine übergeordnete Website, sondern eine Website, an die andere Websites *angeschlossen* werden. Der Hub liefert gemeinsame Navigation, ein gemeinsames Erscheinungsbild und eine übergreifende Suche und Nachrichtenaggregation.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation „Planning hub sites“ nennt folgende Orientierungswerte: Ein Tenant kann bis zu 2000 Hubwebsites haben. Die Hubnavigation kann bis zu drei Ebenen tief sein. Praktische Grenzen sind etwa 100 Navigationslinks, 99 Websites in der Sites-Webpart und ungefähr 2000 Websites für die Suchaggregation. Die Dokumentation rät, Unterwebsites in neuen Projekten zu vermeiden und stattdessen Hubs zu verwenden. Eine Website kann nur zu einem Hub gehören. Bei Hubwebsites gilt: Sie ändern die Berechtigungen der angeschlossenen Websites nicht. Der Hub verbindet, er vererbt keine Rechte.

Das Wichtigste, das man über Hubs wissen muss, ist der Satz aus der Ergänzung: *Hubs verbinden, vererben aber keine Berechtigungen.* Wer eine Website an einen Hub anschließt, ändert nicht, wer sie sehen darf. Er ändert nur die Navigation, das Design und die Suche. Allerdings kann ein Hub über die Suche und Nachrichten Inhalte aus angeschlossenen Websites zeigen, und zwar nur denen, die der Benutzer ohnehin sehen darf. Der Hub ist daher ein Instrument der Auffindbarkeit und nicht der Sicherheit.

Wie plant man eine Hubstruktur? Ein bewährter Ansatz geht von den Fragen der Benutzer aus: In welchem Kontext suchen sie? Nach Bereichen (Personal, Finanzen, Vertrieb), nach Standorten oder nach Projekten? Meist reichen drei bis fünf Hubs auf der ersten Ebene. Mehr als ein Hub für eine Website ist nicht möglich, daher muss die Entscheidung nach dem wichtigsten Kontext fallen. Zusätzlich plant man eine Namenskonvention und die Navigation: Die Hubnavigation zeigt maximal drei Ebenen, und sie sollte aus den Sprachen und Begriffen der Benutzer bestehen und nicht aus Abteilungskürzeln.

Das nächste Skript registriert eine Hubwebsite, schließt mehrere Websites an und gibt zum Schluss eine Übersicht aus. Es eignet sich, um ein Projektportfolio zu gliedern.

**New-HubStructure.ps1**

```powershell
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$hub = "https://contoso.sharepoint.com/sites/HUB-Projekte"

# 1) Hub registrieren (falls noch nicht geschehen)
if (-not (Get-SPOHubSite -Identity $hub -ErrorAction SilentlyContinue)) {
    Register-SPOHubSite -Site $hub | Out-Null
    Set-SPOHubSite -Identity $hub -Title "Projekte" | Out-Null
}

# 2) Websites anschliessen
$kandidaten = Get-SPOSite -Limit All -Filter "Url -like '/sites/PRJ-'"
foreach ($s in $kandidaten) {
    Add-SPOHubSiteAssociation -Site $s.Url -HubSite $hub
    "Angeschlossen: $($s.Url)"
}

# 3) Uebersicht
Get-SPOHubSite | Select-Object Title, SiteUrl | Format-Table -AutoSize
```

Der Ablauf besteht aus drei Schritten. Zuerst wird die Website als Hub registriert, sofern sie noch kein Hub ist; `Register-SPOHubSite` macht aus einer normalen Website einen Hub. Der Titel des Hubs erscheint später in der Navigation. Danach sucht das Skript alle Websites, deren Adresse mit `/sites/PRJ-` beginnt, und schließt jede davon mit `Add-SPOHubSiteAssociation` an den Hub an. Dass das Skript auf die Namenskonvention aufbaut, ist kein Zufall: Ohne eine einheitliche Benennung lassen sich Websites nicht zuverlässig automatisch zuordnen. Zum Schluss gibt `Get-SPOHubSite` eine Übersicht aller Hubs aus. Die Filtersyntax von `Get-SPOSite -Filter` sollte vor dem Einsatz an einer Testumgebung geprüft werden.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Annahme, ein Hub vererbe Berechtigungen. Das führt dazu, dass jemand eine vertrauliche Website an einen öffentlichen Hub hängt und erwartet, sie sei nun „im Intranet“. Der zweite Fehler: eine Hubstruktur, die die Organisationsstruktur abbildet und mit der nächsten Umorganisation veraltet. Der dritte: zu viele Navigationsebenen und Links.

```
FALSCH:  Hub-Struktur = Organigramm (Bereich/Abteilung/Gruppe/Team),
          Umorganisation -> Struktur falsch -> Navigation veraltet.

RICHTIG: Hubs nach Themen und Aufgaben (Projekte, Kunden, Wissen, Personal),
          Zuordnung der Organisation ueber Metadaten und Gruppen
```

### Praxisbezug.

Planen Sie die IA zusammen mit Menschen, die täglich suchen: Fragen Sie nach den zehn häufigsten Aufgaben („Ich suche die Vorlage für ...“). Ordnen Sie diese Aufgaben den Hubs zu und bauen Sie die Navigation daraus. Prüfen Sie nach drei Monaten mit Suchprotokollen, was nicht gefunden wurde.

> **Merke**
>
> Hubs verbinden Websites (Navigation, Design, Suche), vererben aber keine Berechtigungen. Eine Website gehört zu höchstens einem Hub. Unterwebsites vermeidet man in neuen Projekten.

## 4.3 Permission Model

Das SharePoint-Berechtigungsmodell wirkt auf den ersten Blick einfach und ist in der Praxis die häufigste Quelle von Datenabflüssen. Grundlage sind *Berechtigungsstufen* (Permission Levels), etwa „Lesen“, „Bearbeiten“ und „Vollzugriff“, die Rechte bündeln. Sie werden *SharePoint-Gruppen* zugewiesen, und Benutzer (oder Entra-Gruppen) sind Mitglied dieser Gruppen. Jede Website hat drei Standardgruppen: *Besitzer* mit Vollzugriff, *Mitglieder* mit Bearbeitungsrechten und *Besucher* mit Leserechten. Dazu kommen die Websitesammlungsadministratoren, die unabhängig von allen Gruppen alles dürfen.

Das Wichtigste ist das Prinzip der *Vererbung*. Standardmäßig erben Bibliotheken, Ordner und Dateien die Berechtigungen der Website. Wer Zugriff auf die Website hat, hat ihn auf alles darin. Man kann die Vererbung unterbrechen und einem Ordner oder einer Datei eigene Berechtigungen geben. Das ist der Moment, in dem das Modell komplex wird: Jede Unterbrechung ist eine Ausnahme, die man dokumentieren und später prüfen muss. Außerdem entstehen durch Freigabelinks stillschweigend eindeutige Berechtigungen, die in keiner Gruppe sichtbar sind. Wer das nicht weiß, wundert sich, wer alles „irgendwie“ Zugriff hat.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „Site permissions reference“ beschreibt die Zuordnung bei gruppenverbundenen Websites: Die Besitzer der Microsoft-365-Gruppe sind Besitzer der Website, die Mitglieder der Gruppe Mitglieder der Website. Es wird davon abgeraten, einzelne Personen direkt in die SharePoint-Gruppen einer gruppenverbundenen Website aufzunehmen, weil sie dadurch von der Gruppenmitgliedschaft (und von Ablauf, Überprüfung und Teams) abweicht. Mit *Restricted Access Control* (Teil von SharePoint Advanced Management) kann man den Zugriff auf eine Website zusätzlich auf Mitglieder bestimmter Gruppen begrenzen. Laut Dokumentation lassen sich bis zu zehn Gruppen eintragen, und Kanalwebsites von Teams werden getrennt betrachtet.

Aus Governance-Sicht gelten fünf Regeln. Erstens Berechtigungen immer an Gruppen vergeben, nie an Einzelpersonen. Zweitens bei gruppenverbundenen Websites die Mitgliedschaft in der Microsoft-365-Gruppe pflegen und nicht in SharePoint. Drittens Vererbung unterbrechen nur, wenn es einen echten Grund gibt, und dann auf Ordnerebene, nicht auf Dateiebene. Viertens die Zahl der Besitzer klein halten (zwei bis drei) und die Zahl der Mitglieder durch Gruppen steuern. Fünftens regelmäßig prüfen: Wer hat Zugriff, und wie ist er zustande gekommen?

Das folgende Skript erstellt für eine Website einen Bericht über die SharePoint-Gruppen und deren Mitglieder. Es zeigt, ob einzelne Benutzer statt Gruppen eingetragen sind. Dieses Muster nutzt man, um verstreute Einzelzuweisungen zu finden.

**Get-SitePermissionReport.ps1**

```powershell
param([Parameter(Mandatory)][string]$SiteUrl)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$gruppen = Get-SPOSiteGroup -Site $SiteUrl
$zeilen = foreach ($g in $gruppen) {
    foreach ($u in $g.Users) {
        $art = if ($u -like 'c:0t.c|tenant|*' -or $u -like 'c:0o.c|federateddirectoryclaimprovider|*') { 'Gruppe' }
               elseif ($u -like '*#ext#*') { 'Gast' }
               else { 'Einzelperson' }
        [pscustomobject]@{
            SharePointGruppe = $g.Title
            Rolle            = ($g.Roles -join ', ')
            Eintrag          = $u
            Art              = $art
        }
    }
}
$zeilen | Group-Object Art | Select-Object Name, Count | Format-Table -AutoSize
$zeilen | Where-Object Art -in 'Einzelperson','Gast' | Format-Table -AutoSize
```

Das Skript liest alle SharePoint-Gruppen der Website. Für jedes Mitglied bestimmt es die Art des Eintrags anhand des Anmeldenamens: Einträge mit bestimmten Präfixen sind Entra-Gruppen, Einträge mit `#ext#` im Namen sind externe Gäste, alles andere sind Einzelpersonen. Die Präfixe sind die in SharePoint verwendeten Claims-Schreibweisen; welche Variante in Ihrem Tenant vorkommt, sollten Sie an einer Testwebsite prüfen. Danach folgt eine kurze Zusammenfassung nach Art und eine Liste der Einzelpersonen und Gäste. Gibt es dort viele Einträge, ist das ein Hinweis auf gewachsene, schwer prüfbare Berechtigungen.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist das „Teilen an Einzelpersonen“ bei Dateien, weil es schnell geht. Nach einem Jahr hat ein Dokument 40 Berechtigungen, die niemand mehr überblickt. Der zweite Fehler: Für das Entfernen einer Person muss man das Konto löschen, weil man nicht weiß, wo sie überall steht. Der dritte: SharePoint-Gruppen innerhalb von SharePoint-Gruppen, die man nicht verschachteln kann.

```
FALSCH:  Datei "Gehaltsliste.xlsx" an 7 Einzelpersonen geteilt,
          Vererbung auf Dateiebene unterbrochen.

RICHTIG: Eigene Bibliothek "Personal-Vertraulich" mit unterbrochener Vererbung,
          Zugriff nur ueber die Entra-Gruppe "SEC-Personal-Lesen",
          Freigabe an Einzelpersonen in dieser Bibliothek deaktiviert.
```

### Praxisbezug.

Bei Berechtigungsprojekten entsteht fast immer ein Verzeichnis der Ausnahmen: Ordner mit unterbrochener Vererbung, Dateien mit eigenen Berechtigungen, Gäste mit Direktzugriff. Aufwand und Nutzen stehen im Verhältnis, wenn man nach Risiko sortiert: zuerst Websites mit vertraulichen Daten, zuerst Gäste, zuerst Zugriff für „Alle außer externe Benutzer“.

> **Merke**
>
> Berechtigungsstufen werden SharePoint-Gruppen zugewiesen, Benutzer und Entra-Gruppen sind deren Mitglieder. Vererbung ist die Regel, Unterbrechung die dokumentierte Ausnahme. Berechtigungen gehören an Gruppen, nicht an Einzelpersonen.

## 4.4 Sharing Controls

Freigabe (Sharing) bedeutet, dass eine Datei, ein Ordner oder eine Website für Personen zugänglich wird, die vorher keinen Zugriff hatten. Das ist erwünscht und gleichzeitig das größte Risiko für Datenabfluss. Die Steuerung geschieht in mehreren Schichten, und die Dokumentation zur externen Freigabe betont das Grundprinzip: Die strengste Einstellung gewinnt. Eine Organisation legt auf Tenantebene fest, was überhaupt erlaubt ist. Jede Website kann restriktiver sein, aber nie großzügiger.

Auf Tenantebene gibt es vier Stufen für die externe Freigabe. *Beliebige Personen* (Anyone) erlaubt Links, die ohne Anmeldung funktionieren. *Neue und vorhandene Gäste* verlangt Anmeldung, auch für neue Gäste, die per Einladung entstehen. *Vorhandene Gäste* erlaubt Freigabe nur an Personen, die bereits als Gäste im Verzeichnis sind. *Nur Personen in Ihrer Organisation* schaltet die externe Freigabe vollständig ab. In den PowerShell-Cmdlets heißen die Werte `ExternalUserAndGuestSharing`, `ExternalUserSharingOnly`, `ExistingExternalUserSharingOnly` und `Disabled`. Zusätzlich lassen sich Standardlinktypen (intern, bestimmte Personen, beliebige Personen), Ablaufdaten für Anyone-Links, Domänenbeschränkungen und Berechtigungen für Anyone-Links einstellen.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zur externen Freigabe in SharePoint und OneDrive (Übersicht) erklärt, dass die externe Freigabe im Standard eingeschaltet ist und auf Organisations- und Websiteebene eingeschränkt werden kann. Sie weist auf die Integration mit Microsoft Entra B2B hin: Wird ein Dokument an eine externe Person freigegeben, entsteht ein Gastkonto, sofern kein Anyone-Link verwendet wird. Die Referenzseite zu den Gasteinstellungen listet außerdem die Standardwerte je Websitetyp. Für Anyone-Links gilt in der Praxis: Sie sind nicht an eine Person gebunden, jeder mit dem Link hat Zugriff. Dies ist datenschutzrechtlich in der Regel nur für öffentliche Inhalte geeignet; eine Bewertung im Einzelfall ist keine Rechtsberatung und gehört zur Datenschutzbeauftragten.

Für eine Empfehlung gilt: Der Tenant-Standard sollte „Neue und vorhandene Gäste“ oder „Vorhandene Gäste“ sein, nicht „Beliebige Personen“. Anyone-Links sind nur dann sinnvoll, wenn es wirklich öffentliche Dokumente gibt, und dann idealerweise auf einer Website, die dafür vorgesehen ist. Websites mit sensiblen Daten werden über Labels (Lerneinheit 4.5) oder per Website-Einstellung auf „Nur Personen in Ihrer Organisation“ gesetzt. Standardlinks sollten auf „Bestimmte Personen“ stehen, damit der erste Klick auf „Teilen“ nicht den breitesten Link erzeugt. Zusätzlich empfiehlt sich ein Ablauf für Gastzugriff (zum Beispiel 60 Tage) und die Pflicht zur Anmeldung per Einmalcode oder Konto.

Das Skript setzt vernünftige Standards auf Tenantebene, liest den Zustand zurück und zeigt, wie sich die Websites des Tenants auf die einzelnen Freigabestufen verteilen. Websites können nie großzügiger als der Tenant sein, aber sie können bewusst strenger konfiguriert sein, und genau diese Verteilung ist für die Planung interessant.

**Set-SharingBaseline.ps1**

```powershell
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

# 1) Tenant-Standard setzen
Set-SPOTenant -SharingCapability ExternalUserSharingOnly `
              -DefaultSharingLinkType Direct `
              -RequireAnonymousLinksExpireInDays 30 `
              -ExternalUserExpirationRequired $true `
              -ExternalUserExpireInDays 60

# 2) Aktuellen Zustand lesen
$t = Get-SPOTenant
"Tenant-Freigabe: {0}" -f $t.SharingCapability

# 3) Verteilung der Websites nach eigener Einstellung
Get-SPOSite -Limit All |
    Select-Object Url, Title, SharingCapability, Owner |
    Group-Object SharingCapability |
    Select-Object Name, Count | Format-Table -AutoSize
```

Die erste Anweisung setzt mehrere Eigenschaften in einem Aufruf: Die Freigabe an neue und vorhandene Gäste mit Anmeldung (`ExternalUserSharingOnly`), den Standardlinktyp „Bestimmte Personen“ (`Direct`), den Ablauf von Anyone-Links nach 30 Tagen (nur relevant, wenn Anyone-Links überhaupt erlaubt sind) und eine Befristung des Gastzugriffs auf 60 Tage. Die zweite Anweisung liest den Zustand und gibt die Tenanteinstellung aus. Die dritte gruppiert alle Websites nach ihrer eigenen Einstellung und zählt sie. So sieht man, wie viele Websites die Freigabe bereits abgeschaltet haben oder welche mit der Tenant-Einstellung übereinstimmen. Die Cmdlets und Parameter sind in der Dokumentation zum Modul beschrieben; prüfen Sie vor dem Einsatz, ob die Parameter in Ihrer Modulversion vorhanden sind.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, die Tenantebene zu verschärfen und dann zu wundern, dass bestehende Links nicht mehr funktionieren. Beim Verschärfen sollte man die Auswirkungen auf bestehende Freigaben prüfen und die Benutzer informieren. Der zweite Fehler: nur SharePoint betrachten, obwohl Teams, OneDrive und Loop dieselben Einstellungen nutzen. Der dritte: Anyone-Links als Standardlink.

```
FALSCH:  Standardlink = "Beliebige Personen", kein Ablauf.
          Nach einem Jahr: tausende Links, die jeder kennt, der sie hat.

RICHTIG: Standardlink = "Bestimmte Personen", Gastzugriff 60 Tage,
          Anyone-Links nur auf einer dafuer vorgesehenen Website
```

### Praxisbezug.

Zur Einführung gehört ein Bericht über bestehende Freigabelinks (Datenzugriffsbericht in SharePoint Advanced Management), damit Sie wissen, wie viele Anyone-Links existieren. Erst dann wird verschärft. Kommunizieren Sie in zwei Schritten: Ankündigung, dann Umstellung. Für Ausnahmen gibt es einen Antragsweg mit Frist.

> **Merke**
>
> Freigabe wird in Schichten gesteuert, die strengste gewinnt. Standardlinks sollten auf „Bestimmte Personen“ stehen. Gastzugriff wird befristet und überprüft; Anyone-Links sind die Ausnahme.

## 4.5 Sensitivity Labels for Sites

Vertraulichkeitsbezeichnungen (Sensitivity Labels) sind das Werkzeug, um den Schutzbedarf von Inhalten und Containern sichtbar und durchsetzbar zu machen. Modul 06 behandelt Labels ausführlich, auch für Dateien und E-Mails. Hier geht es um die Variante, die auf *Container* wirkt: Teams, Microsoft-365-Gruppen und SharePoint-Websites. Ein solches Label setzt nicht den Inhalt der Dateien, sondern die Rahmenbedingungen der Website, in der sie liegen. Es steuert Datenschutzstufe (privat oder öffentlich), den Zugriff externer Benutzer, die externe Freigabe, den Zugriff von nicht verwalteten Geräten sowie Regeln für den bedingten Zugriff.

Der Vorteil gegenüber einzelnen Websiteeinstellungen ist die *Verständlichkeit*. Ein Teambesitzer muss nicht wissen, was „ExistingExternalUserSharingOnly“ bedeutet. Er wählt beim Anlegen das Label „Vertraulich“ und bekommt eine konsistente Kombination von Einstellungen. Für die Governance ist das Label außerdem ein Prüfmerkmal: Man kann berichten, wie viele Websites welches Label tragen und welche keines haben.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zu Labels für Container nennt folgende Voraussetzungen und Eigenheiten: Die Funktion muss für Microsoft Entra aktiviert werden (Synchronisation der Labels in das Verzeichnis, Cmdlet `Execute-AzureAdLabelSync`), und Labels müssen im Purview-Portal mit dem Bereich „Gruppen und Websites“ erstellt werden. Nach Aktivierung und Veröffentlichung können je nach Schritt Wartezeiten von bis zu einer Stunde oder bis zu 24 Stunden anfallen. Die Dokumentation beschreibt außerdem, dass Labels auf Websites nachträglich per PowerShell (zum Beispiel mit `Set-SPOSite -SensitivityLabel`) vergeben werden können, dass ein Abgleich zwischen Label und tatsächlicher Einstellung über Audit-Ereignisse („Labelabweichung“) möglich ist und dass beim Löschen eines Labels die Reihenfolge zu beachten ist: erst das Label von allen Containern entfernen, dann aus den Richtlinien, dann löschen. Die genaue Syntax und Wartezeiten sollten Sie vor dem Einsatz in der aktuellen Dokumentation prüfen.

Wie sieht ein vernünftiges Labelmodell für Container aus? Drei bis vier Stufen genügen. „Öffentlich“ für Inhalte, die jeder lesen darf, mit offener Datenschutzstufe und großzügiger Freigabe. „Intern“ als Standard für die normale Zusammenarbeit, nur Mitglieder der Organisation, Gäste nach Genehmigung. „Vertraulich“ mit privater Datenschutzstufe, ohne externe Freigabe und mit eingeschränktem Zugriff von nicht verwalteten Geräten. „Streng vertraulich“ für wenige besonders sensible Bereiche, mit zusätzlichen Auflagen. Mehr Stufen verwirren und werden falsch gewählt. Wichtig ist ein Standardlabel, das beim Anlegen vorgewählt ist, und ein verpflichtendes Label, damit keine Website ohne Einordnung entsteht.

Das nächste Skript prüft, welche Websites kein Label tragen, und weist Websites eines bestimmten Präfixes ein Label zu. Das Label wird über seine GUID angegeben, die man im Purview-Portal oder mit den Security-and-Compliance-Cmdlets ermittelt.

**Set-SiteLabels.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$LabelId,       # GUID des Labels
    [string]$UrlPrefix = "/sites/PRJ-",
    [switch]$Ausfuehren
)
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$sites = Get-SPOSite -Limit All -IncludePersonalSite $false
$ohne  = $sites | Where-Object { -not $_.SensitivityLabel }
"{0} von {1} Websites ohne Label." -f $ohne.Count, $sites.Count

$ziel = $ohne | Where-Object { $_.Url -like "*$UrlPrefix*" }
foreach ($s in $ziel) {
    if ($Ausfuehren) {
        Set-SPOSite -Identity $s.Url -SensitivityLabel $LabelId
        "Label gesetzt: $($s.Url)"
    } else {
        "PROBELAUF: $($s.Url)"
    }
}
```

Das Skript liest alle Websites ohne die persönlichen OneDrive-Websites und zählt, wie viele noch kein Label tragen. Aus dieser Menge wählt es die Websites aus, deren Adresse das Präfix enthält, und weist ihnen entweder im Probelauf oder mit dem Schalter tatsächlich das Label zu. Der Schalter `Ausfuehren` verhindert, dass ein versehentlicher Start Hunderte Websites verändert. Ob die Eigenschaft `SensitivityLabel` in der Ausgabe als GUID oder als Name erscheint, hängt von der Modulversion ab; prüfen Sie das mit einer einzelnen Website, bevor Sie die Schleife laufen lassen. Beachten Sie auch, dass ein Label die Einstellungen der Website verändert, zum Beispiel die Freigabe. Das ist gewollt, kann aber bestehende Zusammenarbeit unterbrechen.

### Typische Fehler und Stolperfallen.

Ein typischer Fehler ist, das Label zu aktivieren, ohne die Auswirkungen zu testen. Ein Label „Vertraulich ohne Externe“ kann bestehende Gäste nicht automatisch entfernen; es verhindert das Hinzufügen neuer. Der zweite Fehler: zu viele Labels. Der dritte: Labels, die nur im Namen schützen, aber keine Einstellungen setzen.

```
FALSCH:  8 Labels ("Intern 1", "Intern 2", "Intern streng" ...), niemand
          weiss, welches gilt; die Besitzer waehlen immer das erste.

RICHTIG: 4 Labels mit klarer Beschreibung und Beispiel:
          Oeffentlich / Intern (Standard) / Vertraulich / Streng vertraulich
```

### Praxisbezug.

Starten Sie mit Labels für neue Websites und Teams und arbeiten Sie den Bestand in Wellen ab: zuerst Websites mit hohem Schutzbedarf (Personal, Geschäftsleitung), dann Projektwebsites. Berichten Sie den Fortschritt als Quote („78 Prozent der Websites mit Label“). Verknüpfen Sie die Labels mit den Freigaberegeln aus Lerneinheit 4.4.

> **Merke**
>
> Container-Labels setzen Rahmenbedingungen einer Website oder eines Teams: Datenschutzstufe, Gäste, Freigabe, Gerätezugriff. Wenige, gut beschriebene Stufen mit Standardlabel sind wirksamer als viele.

## 4.6 Storage und Quotas

Speicherplatz in Microsoft 365 ist ein begrenztes und bezahltes Gut. Jeder Tenant erhält einen Grundspeicher, der sich aus einem festen Anteil und einem Anteil pro lizenziertem Benutzer zusammensetzt, und kann zusätzlichen Speicher kaufen. Innerhalb dieses Rahmens gibt es zwei Modelle zur Verteilung auf Websites. Im Standard, dem *gemeinsamen Speicher* (Pooled Storage), teilen sich alle Websites den Tenantspeicher, und der Tenant bekommt eine Meldung, wenn er knapp wird. Im Modell der *manuellen Quoten* legt der Administrator für jede Website eine Obergrenze fest.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation „Manage site storage limits“ beschreibt, dass der gemeinsame Speicher die Voreinstellung ist und dass die manuelle Quote pro Website bis zu 25 600 GB betragen kann (das entspricht 25 TB, dem Maximum einer Websitesammlung). Die Quoten werden in Megabyte angegeben (Cmdlet `Set-SPOSite -StorageQuota`). Nach der Dokumentation gibt es außerdem einen Ablauf, wie Benutzer mehr Speicher für eine Website beantragen können. Im Modus der automatischen Verwaltung entfällt die manuelle Pflege. Quoten, Vorversionen und Papierkörbe zählen zum Speicher. Prüfen Sie Zahlen und Bezeichnungen vor der Anwendung in der aktuellen Dokumentation.

Warum begrenzt man Speicher überhaupt, wenn er gemeinsam genutzt wird? Der Hauptgrund ist Kontrolle: Eine einzelne Website, in der jemand Videoarchive oder Sicherungen ablegt, kann den Tenantspeicher aufbrauchen. Manuelle Quoten schützen den Tenant vor Ausreißern, bedeuten aber Pflegeaufwand, weil Besitzer bei Bedarf Erweiterungen beantragen müssen. Praxisübliche Mischformen sind gemeinsamer Speicher mit Überwachung und Warnschwellen sowie Quoten nur für bestimmte Websitetypen (etwa Projektwebsites mit 100 GB Standard und Antrag für mehr).

Hinter dem Speicherverbrauch stehen vier typische Verursacher: große Dateien (Videos, Bilder, Sicherungskopien), Versionen (jede Änderung einer Datei kann eine weitere Version erzeugen), Papierkörbe (gelöschte Inhalte zählen bis zum endgültigen Löschen) und vergessene Websites. Die Strategie lautet daher: Verbrauch sichtbar machen, Ausreißer ansprechen, Versionsbegrenzungen konfigurieren, Inaktives archivieren (Lerneinheit 4.7).

Das folgende Skript erstellt einen Bericht der größten Websites mit Auslastung gegen die Quote und exportiert ihn. Es markiert Websites, die mehr als 80 Prozent der Quote nutzen, und zeigt, wie man eine Quote erhöht.

**Get-StorageReport.ps1**

```powershell
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$sites = Get-SPOSite -Limit All -IncludePersonalSite $false |
    Select-Object Url, Title, Owner,
        @{n='GenutztGB'; e={ [math]::Round($_.StorageUsageCurrent / 1024, 2) }},
        @{n='QuoteGB';   e={ [math]::Round($_.StorageQuota / 1024, 2) }},
        @{n='Auslastung';e={ if ($_.StorageQuota -gt 0) { [math]::Round(100 * $_.StorageUsageCurrent / $_.StorageQuota, 1) } else { $null } }}

$sites | Sort-Object GenutztGB -Descending | Select-Object -First 20 | Format-Table -AutoSize
$sites | Export-Csv ".\speicher-bericht.csv" -NoTypeInformation -Encoding UTF8

"`nWebsites ueber 80 Prozent Auslastung:"
$sites | Where-Object { $_.Auslastung -gt 80 } | Format-Table Url, GenutztGB, QuoteGB, Auslastung -AutoSize

# Beispiel: Quote einer Website auf 200 GB (204800 MB) anheben
# Set-SPOSite -Identity https://contoso.sharepoint.com/sites/PRJ-Messe -StorageQuota 204800
```

Die Eigenschaften `StorageUsageCurrent` und `StorageQuota` werden in Megabyte geliefert. Das Skript rechnet sie mit berechneten Eigenschaften in Gigabyte um und bestimmt die Auslastung in Prozent. Die Bedingung für die Quote größer als null verhindert eine Division durch null in Tenants mit gemeinsamem Speicher, in denen Quoten nicht überall gesetzt sind. Der Bericht zeigt die 20 größten Websites und schreibt alle in eine CSV-Datei. Die auskommentierte Zeile am Ende zeigt, wie man eine Quote erhöht; die Quote wird in Megabyte angegeben, 200 GB entsprechen also 204800.

### Typische Fehler und Stolperfallen.

Häufig verwechselt man Gigabyte und Megabyte und setzt versehentlich eine Quote von 200 MB statt 200 GB. Ein zweiter Fehler: Die Quote einer Website unter den aktuellen Verbrauch zu setzen. Der dritte: das Löschen von Dateien als Lösung für Speichermangel anzusehen, ohne den Papierkorb und die Vorversionen zu berücksichtigen, die ebenfalls zählen.

```
FALSCH:  Set-SPOSite -StorageQuota 200      # meint 200 GB, setzt 200 MB

RICHTIG: Set-SPOSite -StorageQuota 204800   # 200 GB in Megabyte
          Vorher pruefen: StorageUsageCurrent < neue Quote
```

### Praxisbezug.

Ein monatlicher Speicherbericht mit den 20 größten Websites genügt meist, um Ausreißer zu erkennen. Kombinieren Sie ihn mit dem Besitzerkontakt: Wer eine große Website hat, soll wissen, warum. Beachten Sie bei Kostenfragen den Zusammenhang mit der Kostenbetrachtung in Modul 12.

> **Merke**
>
> Gemeinsamer Speicher ist die Voreinstellung, manuelle Quoten sind die Ausnahme. Quoten werden in Megabyte gesetzt. Verbrauch entsteht durch Dateien, Versionen, Papierkörbe und vergessene Websites.

## 4.7 Site Lifecycle

Wie bei Teams (Modul 03) haben auch SharePoint-Websites einen Lebenszyklus, und er wird in den wenigsten Tenants gesteuert. Websites werden angelegt, genutzt und dann vergessen. Die Folge sind inaktive Websites, die Speicher belegen, Berechtigungen behalten und für Berichte und Überprüfungen Rauschen erzeugen. SharePoint Advanced Management (SAM) bringt dafür Richtlinien mit, die den Lebenszyklus teilweise automatisieren.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zum Websitelebenszyklus in SharePoint Advanced Management beschreibt mehrere Bausteine: Richtlinien zur Erkennung *inaktiver Websites*, Richtlinien zur *Besitzerpflege* (Websites ohne ausreichende Besitzer) und *Bestätigungsrichtlinien* (Attestierung), bei denen Besitzer regelmäßig bestätigen müssen, dass die Website weiter gebraucht wird. Reagiert niemand, kann die Richtlinie Maßnahmen einleiten: die Website wird schreibgeschützt und kann nach einer wählbaren Frist (3, 6, 9 oder 12 Monate) archiviert werden. Die Dokumentation betont, dass Websites nicht direkt durch die Richtlinie gelöscht werden. Die Archivierung nutzt Microsoft 365 Archive, einen günstigeren Speicherbereich. Lizenzen, Verfügbarkeit und Bedienung ändern sich; prüfen Sie diese Details in der aktuellen Dokumentation.

Ein Lebenszyklus lässt sich als Kette beschreiben. Eine Website wird aktiv genutzt. Bleibt die Aktivität aus, fragt das System den Besitzer, ob die Website noch gebraucht wird (Bestätigung). Bestätigt der Besitzer, beginnt die Frist von vorn. Antwortet er nicht, wird die Website schreibgeschützt, später archiviert. Archivierte Websites können wiederhergestellt werden, und erst nach einer Entscheidung der Verantwortlichen werden sie endgültig gelöscht. Die Reihenfolge ist wichtig: Jede Stufe ist reversibel, bis auf die letzte. Die Wiederherstellung sollte beschrieben und geübt sein, bevor die ersten Websites archiviert werden.

Für Websites mit Aufbewahrungspflichten gilt: Richtlinien aus Purview (Modul 06) haben Vorrang vor Wünschen der Besitzer. Eine Website, die einer Aufbewahrungspflicht unterliegt, darf nicht gelöscht werden, selbst wenn der Besitzer es möchte. Auch rechtliche Sperren (Legal Hold, Modul 07) verhindern das Löschen. Der Lebenszyklus der Website ist daher ein Zusammenspiel von SharePoint-Richtlinien, Purview und organisatorischen Entscheidungen.

Das folgende Skript findet Kandidaten für die Archivierung: Websites ohne Änderung der letzten zwölf Monate, und setzt wahlweise den Status auf schreibgeschützt. Es ergänzt die SAM-Richtlinien dort, wo diese nicht verfügbar oder nicht lizenziert sind.

**Find-InactiveSites.ps1**

```powershell
param([int]$Tage = 365, [switch]$SchreibschutzSetzen)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"
$grenze = (Get-Date).AddDays(-$Tage)

$kandidaten = Get-SPOSite -Limit All -IncludePersonalSite $false |
    Where-Object { $_.LastContentModifiedDate -lt $grenze -and $_.LockState -eq 'Unlock' } |
    Select-Object Url, Title, Owner, LastContentModifiedDate,
        @{n='GB'; e={ [math]::Round($_.StorageUsageCurrent / 1024, 2) }}

"{0} Websites ohne Aenderung seit {1} Tagen." -f @($kandidaten).Count, $Tage
$kandidaten | Sort-Object LastContentModifiedDate | Export-Csv ".\inaktive-websites.csv" -NoTypeInformation -Encoding UTF8
$kandidaten | Sort-Object GB -Descending | Select-Object -First 15 | Format-Table -AutoSize

if ($SchreibschutzSetzen) {
    foreach ($k in $kandidaten) {
        Set-SPOSite -Identity $k.Url -LockState ReadOnly
        "Schreibgeschuetzt: $($k.Url)"
    }
}
```

Der Parameter `Tage` legt fest, was „inaktiv“ heißt. Das Skript vergleicht das Datum der letzten Inhaltsänderung mit der Grenze und nimmt nur Websites auf, die nicht schon gesperrt sind. Das Ergebnis wird gezählt, in eine CSV-Datei geschrieben und als Liste der 15 größten Kandidaten angezeigt. Nur wenn der Schalter gesetzt ist, ruft das Skript `Set-SPOSite -LockState ReadOnly` auf und stellt die Websites auf schreibgeschützt. Der Wert `LockState` der Website kann `Unlock`, `ReadOnly` oder `NoAccess` sein. Das Datum der letzten Änderung erfasst nur Inhaltsänderungen, nicht reines Lesen; eine Website, die oft gelesen und selten geändert wird (Intranet-Richtlinien), erscheint daher als Kandidat und darf nicht blind gesperrt werden.

### Typische Fehler und Stolperfallen.

Der größte Fehler ist, Inaktivität mit Unwichtigkeit zu verwechseln. Ein Archiv mit Verträgen ist selten geändert und trotzdem wertvoll. Der zweite Fehler: sperren, ohne den Besitzer zu informieren. Der dritte: Websites löschen, die einer Aufbewahrung unterliegen.

```
FALSCH:  Alle Websites ohne Aenderung seit 12 Monaten werden gesperrt,
          ohne Information, ohne Ausnahmeliste.

RICHTIG: 1) Liste an Besitzer: "Behalten oder archivieren? Frist 30 Tage"
          2) Keine Antwort -> schreibgeschuetzt (reversibel)
          3) Nach 6 Monaten -> Archiv; Loeschung nur nach Freigabe + Retention-Check
```

### Praxisbezug.

Der erste Lauf eines solchen Berichts ist meist ernüchternd: 30 bis 50 Prozent der Websites sind Kandidaten. Beginnen Sie mit einer kleinen Welle und nutzen Sie die Rückmeldungen, um Schwellenwerte und Texte der Benachrichtigungen anzupassen. Die automatisierten Jobs für Archivierung und Löschung werden in Modul 10 vertieft.

> **Merke**
>
> Der Website-Lebenszyklus lautet: aktiv, Bestätigung durch den Besitzer, schreibgeschützt, archiviert, gelöscht. Jede Stufe außer der letzten ist reversibel. Aufbewahrungspflichten haben Vorrang.

## 4.8 SharePoint-Troubleshooting

SharePoint-Probleme sind meist Berechtigungsprobleme, Synchronisationsprobleme oder Probleme der Freigabe. Wie bei Identitäten und Teams lohnt sich ein klares Raster: Gibt es das Problem für alle oder für eine Person? Betrifft es eine Datei, einen Ordner, eine Bibliothek oder die ganze Website? Hat sich etwas geändert (Berechtigung, Label, Richtlinie, Migration)? Die Antworten grenzen die Ursache ein, bevor man irgendetwas ändert.

Die häufigsten Fälle lassen sich benennen. „Zugriff verweigert“ für eine Person: Sie ist kein Mitglied, die Vererbung ist unterbrochen oder die Gruppenmitgliedschaft ist noch nicht wirksam. „Der Gast sieht die Datei nicht“: externe Freigabe auf Website- oder Tenantebene gesperrt, Label verbietet Gäste, Einladung nicht angenommen oder der Link ist abgelaufen. „Die Website ist schreibgeschützt“: Ein Lebenszyklus-Lauf hat sie gesperrt oder das Team wurde archiviert. „Die Bibliothek ist langsam“: zu viele Elemente in einer Ansicht ohne Index, zu viele eindeutige Berechtigungen. „Die Synchronisation hakt“: OneDrive-Client, Pfadlängen, Sonderzeichen in Dateinamen, Speicherplatz.

> **Ergänzung aus der Nachrecherche**
>
> Zu den technischen Orientierungswerten, die in der Dokumentation zu Hubs und Grenzen genannt werden, gehören die Höchstzahlen für Hubs und Navigationslinks (siehe Lerneinheit 4.2). Für Berechtigungen und große Bibliotheken nennt Microsoft in den Grenzwerten und Empfehlungen, dass viele eindeutige Berechtigungen und sehr große Listenansichten die Leistung beeinträchtigen. Konkrete Grenzen, zum Beispiel für die Zahl der eindeutigen Berechtigungen pro Bibliothek, ändern sich und sollten in der Seite „SharePoint limits“ nachgesehen werden. Für die Analyse von Berechtigungsproblemen bietet SharePoint Advanced Management Berichte zu Berechtigungen und Freigaben.

Ein hilfreiches Werkzeug ist die Funktion „Zugriff prüfen“ (Check Access) in den Berechtigungseinstellungen einer Website oder Datei. Sie zeigt, ob eine bestimmte Person Zugriff hat und auf welchem Weg: über die Website, über eine Gruppe oder über einen Freigabelink. Damit beantwortet man in einer Minute, was sonst eine Stunde dauert. Auf Administratorebene helfen das Überwachungsprotokoll von Purview (Modul 07), in dem Freigabeereignisse und Berechtigungsänderungen stehen, und die Berichte im SharePoint Admin Center.

Das folgende Skript prüft für eine Website, ob sie wie erwartet konfiguriert ist: Sperrstatus, Freigabe, Label, Speicher, Hubzuordnung und Besitzer. Es liefert dem Support den Überblick über die Rahmenbedingungen, bevor man in Details geht.

**Get-SiteHealth.ps1**

```powershell
param([Parameter(Mandatory)][string]$SiteUrl)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$s = Get-SPOSite -Identity $SiteUrl -Detailed
[pscustomobject]@{
    Url              = $s.Url
    Titel            = $s.Title
    Vorlage          = $s.Template
    Sperrstatus      = $s.LockState
    Freigabe         = $s.SharingCapability
    Label            = $s.SensitivityLabel
    HubId            = $s.HubSiteId
    GenutztGB        = [math]::Round($s.StorageUsageCurrent / 1024, 2)
    QuoteGB          = [math]::Round($s.StorageQuota / 1024, 2)
    LetzteAenderung  = $s.LastContentModifiedDate
    Besitzer         = $s.Owner
} | Format-List

"`nSharePoint-Gruppen:"
Get-SPOSiteGroup -Site $SiteUrl | Select-Object Title, @{n='Rolle';e={$_.Roles -join ', '}}, @{n='Mitglieder';e={$_.Users.Count}} | Format-Table -AutoSize
```

Das Skript fragt die Website mit dem Parameter `-Detailed` ab, der mehr Eigenschaften liefert. Es gibt die Merkmale aus, die bei Supportfällen am häufigsten die Ursache sind: Sperrstatus (schreibgeschützt oder gesperrt), die Freigabestufe, das Label, die Speicherauslastung und der Zeitpunkt der letzten Änderung. Anschließend werden die SharePoint-Gruppen mit der Zahl ihrer Mitglieder angezeigt. Aus der Ausgabe erkennt man in Sekunden, ob eine Website durch einen Lebenszyklus gesperrt wurde, ob eine Freigabe überhaupt möglich ist oder ob sie keinen Besitzer mehr hat. Das ersetzt nicht die Analyse der Berechtigungen auf Ordner- und Dateiebene.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist, sich dem Benutzer zuzuwenden, bevor man die Website geprüft hat. Der zweite: dem Benutzer Vollzugriff zu geben, damit „es geht“. Das löst das Symptom, vergrößert aber das Risiko. Der dritte: eine Berechtigung auf Dateiebene zu setzen, obwohl die Ursache eine fehlende Gruppenmitgliedschaft ist.

```
FALSCH:  "Er kommt nicht an die Datei" -> Person als Besitzer der Website eintragen.

RICHTIG: 1) Zugriff pruefen fuer die Person (welcher Weg fehlt?)
          2) Website-Zustand (Get-SiteHealth): gesperrt? Label? Freigabe?
          3) Fehlende Gruppenmitgliedschaft ergaenzen, nicht Rechte ausweiten
```

### Praxisbezug.

Nehmen Sie die zehn häufigsten SharePoint-Tickets der letzten Monate und ordnen Sie sie nach Ursache. Meist erklären drei bis vier Ursachen die Mehrzahl der Tickets. Für diese entstehen Selbsthilfe-Seiten (zum Beispiel „So prüfe ich meinen Zugriff“) und Betriebsanweisungen für den Servicedesk, die Sie in Modul 09 weiter ausbauen.

> **Merke**
>
> Erst den Umfang bestimmen (Person, Datei, Website, Tenant), dann den Zustand der Website prüfen, dann Berechtigungen analysieren. Zugriff nie „zum Test“ ausweiten, immer die Ursache beheben.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Erklären Sie den Unterschied zwischen einer Teamwebsite, einer Kommunikationswebsite und einer gruppenverbundenen Website.

**Aufgabe 2 (leicht).** Welche Aussage über Hubwebsites ist richtig: „Ein Hub vererbt Berechtigungen“ oder „Ein Hub verbindet Navigation und Suche“? Begründen Sie Ihre Antwort in zwei Sätzen.

**Aufgabe 3 (leicht).** Nennen Sie die vier Stufen der externen Freigabe auf Tenantebene (deutsche Bezeichnung und PowerShell-Wert).

**Aufgabe 4 (mittel).** Entwerfen Sie ein Labelmodell mit vier Stufen für Teams und Websites. Beschreiben Sie je Stufe Datenschutzstufe, Gäste und Freigabe.

**Aufgabe 5 (mittel).** Ein Projekt will 40 Websites an einen Hub anschließen. Beschreiben Sie, wie Sie die Zuordnung planen und welche Fehlannahme über Berechtigungen Sie vorab klären müssen.

**Aufgabe 6 (mittel).** Schreiben Sie ein Skript, das alle Websites ausgibt, deren Speicherauslastung über 90 Prozent der Quote liegt, mit Besitzer und freiem Speicher in GB.

**Aufgabe 7 (schwer).** Entwerfen Sie einen Lebenszyklus für Projektwebsites von der Anlage bis zur Löschung. Legen Sie Fristen, Verantwortliche, Benachrichtigungen und die Behandlung von Aufbewahrungspflichten fest.

**Aufgabe 8 (schwer).** Ein Gast meldet, dass er eine freigegebene Datei nicht öffnen kann. Beschreiben Sie Ihr Vorgehen in mindestens fünf Schritten und nennen Sie vier mögliche Ursachen auf unterschiedlichen Ebenen.

## Lösungen

**Lösung 1.** Eine Teamwebsite dient der Zusammenarbeit in einem festen Personenkreis und ist meist mit einer Microsoft-365-Gruppe verbunden (dann spricht man von einer gruppenverbundenen Website, deren Mitgliedschaft der Gruppe folgt). Eine Kommunikationswebsite dient dem Veröffentlichen von Informationen für viele Leser, wird nicht mit einer Gruppe verbunden und über SharePoint-Berechtigungen gesteuert. Die gruppenverbundene Website ist also eine Ausprägung der Teamwebsite, kein dritter Typ neben beiden.

**Lösung 2.** Richtig ist, dass ein Hub Navigation, Erscheinungsbild und Suche verbindet. Er vererbt keine Berechtigungen: Wer eine Website an einen Hub anschließt, ändert nicht, wer sie sehen darf. Inhalte aus angeschlossenen Websites erscheinen im Hub nur für Personen, die sie ohnehin sehen dürfen.

**Lösung 3.** Beliebige Personen (`ExternalUserAndGuestSharing`), neue und vorhandene Gäste (`ExternalUserSharingOnly`), nur vorhandene Gäste (`ExistingExternalUserSharingOnly`) und nur Personen in der Organisation (`Disabled`).

**Lösung 4.** Ein Beispiel: Öffentlich (Datenschutzstufe öffentlich, Gäste erlaubt, Freigabe großzügig bis Gäste), Intern als Standard (privat, Gäste nach Genehmigung, Freigabe an vorhandene Gäste), Vertraulich (privat, keine neuen Gäste, Freigabe nur intern, eingeschränkter Zugriff von nicht verwalteten Geräten), Streng vertraulich (wie Vertraulich, zusätzlich Bedingungen über den bedingten Zugriff und verpflichtende Authentifizierungskontexte). Jede Stufe erhält eine kurze Beschreibung mit Beispiel, ein Standardlabel gilt für neue Teams.

**Lösung 5.** Zuerst wird die Zuordnung nach Thema geplant (zum Beispiel ein Hub „Projekte“ mit der Namensregel `PRJ-`), dann Navigation und Design am Hub festgelegt und die Websites per Skript angeschlossen. Wichtig ist die Klärung der Fehlannahme: Die Anbindung ändert keine Berechtigungen. Vertrauliche Projektwebsites bleiben ebenso geschützt wie vorher. Zusätzlich wird geprüft, dass keine Website bereits an einen anderen Hub angeschlossen ist, weil eine Website nur zu einem Hub gehören kann.

**Lösung 6.** Ein mögliches Skript:

```powershell
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"
Get-SPOSite -Limit All -IncludePersonalSite $false |
  Where-Object { $_.StorageQuota -gt 0 -and
                 ($_.StorageUsageCurrent / $_.StorageQuota) -gt 0.9 } |
  Select-Object Url, Owner,
    @{n='FreiGB'; e={ [math]::Round(($_.StorageQuota - $_.StorageUsageCurrent) / 1024, 2) }} |
  Sort-Object FreiGB | Format-Table -AutoSize
```

Das Skript filtert zuerst auf Websites mit gesetzter Quote, um eine Division durch null zu vermeiden, und vergleicht dann Verbrauch und Quote. Der freie Speicher wird aus der Differenz berechnet und von Megabyte in Gigabyte umgerechnet. Die Sortierung zeigt die engsten Fälle zuerst.

**Lösung 7.** Ein möglicher Entwurf: Anlage über die Bereitstellungsfabrik mit zwei Besitzern, Label und Laufzeit. Nach 12 Monaten ohne Änderung fragt das System die Besitzer (Bestätigungsfrist 30 Tage, Erinnerung nach 14 Tagen). Bestätigung verlängert um 12 Monate. Keine Antwort: schreibgeschützt für 6 Monate, Benachrichtigung an Besitzer und Vertretung. Danach Archivierung. Löschung nur nach Freigabe durch den Fachbereich und nach Prüfung der Aufbewahrung in Purview. Für Websites mit Aufbewahrungspflicht oder rechtlicher Sperre gilt: Der Löschschritt entfällt, die Website bleibt archiviert, bis die Frist abgelaufen ist. Verantwortlich sind Besitzer (Bestätigung), IT-Governance (Betrieb des Jobs) und Compliance (Aufbewahrung).

**Lösung 8.** Vorgehen: (1) Fehlerbild klären: Fehlermeldung, Link, Zeitpunkt. (2) Gastkonto prüfen: Einladung angenommen, Konto aktiv. (3) Zugriff prüfen für den Gast auf der Datei. (4) Website-Zustand prüfen: Freigabestufe, Label, Sperrstatus. (5) Anmeldeprotokoll des Gastes ansehen: blockiert der bedingte Zugriff? (6) Ergebnis dokumentieren. Mögliche Ursachen: Tenantebene verbietet die Freigabe an neue Gäste; die Website ist strenger als der Tenant eingestellt; ein Label verbietet Gäste; der Freigabelink ist abgelaufen; die Einladung wurde nicht angenommen; eine Richtlinie des bedingten Zugriffs verlangt ein Gerät oder eine Authentifizierung, die der Gast nicht erfüllt.
