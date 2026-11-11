# Modul 10 - Provisioning, Standards und Lifecycle Automation

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 10 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8,75 Stunden (3 × 1,25 plus 5 × 1). Die Differenz von 1,25 Stunden wird hier nicht als eigene Lerneinheit ausgewiesen, sondern als Übungs- und Vertiefungszeit zu den praktischen Beispielen verstanden; als Richtwert für den Umfang wurde der höhere Wert (10 Stunden) verwendet.  
**Priorität:** 2 (mittlere Priorität)

| **Nr.** | **Lerneinheit**              | **Dauer (h)** | **Prio** |
|:--------|:-----------------------------|--------------:|---------:|
| 10.1    | Provisioning Factory         |          1,25 |        1 |
| 10.2    | Request und Approval         |          1,25 |        1 |
| 10.3    | Templates                    |             1 |        1 |
| 10.4    | Naming Automation            |             1 |        1 |
| 10.5    | Metadata Standards           |             1 |        1 |
| 10.6    | Lifecycle Jobs               |             1 |        2 |
| 10.7    | Archive und Delete           |             1 |        2 |
| 10.8    | Provisioning-Troubleshooting |          1,25 |        2 |
|         | **Summe laut Details**       |      **8,75** |          |
|         | **Dauer laut Modulblatt**    |        **10** |          |

> **Merke: Beispielcode und Berechtigungen**
>
> Die Skripte dieses Moduls verwenden das Microsoft Graph PowerShell SDK (`Connect-MgGraph`) und teilweise `Invoke-MgGraphRequest` für Aufrufe, für die kein eigenes Cmdlet nötig ist. Die Beispiele orientieren sich an der Microsoft-Dokumentation, wurden aber nicht gegen einen echten Tenant ausgeführt. Die angegebenen Berechtigungsbereiche (Scopes) sind Ausgangspunkte; prüfen Sie in der Berechtigungsreferenz, welche Bereiche für Ihren Fall mindestens nötig sind (Prinzip der geringsten Rechte, Modul 11.7). Testen Sie Bereitstellungsskripte immer in einem Testtenant, weil sie reale Gruppen, Teams und Websites anlegen.

In den Modulen 3 und 4 wurde beschrieben, wie Teams und Websites aussehen sollen, wenn sie gut verwaltet sind: benannt, beschriftet, mit Besitzern, mit Ablauf. Dieses Modul zeigt, wie man diese Zielbilder nicht per Hand, sondern automatisch herstellt. Der Grundgedanke heißt *Governance by Design*: Wenn jeder neue Arbeitsbereich durch denselben Prozess entsteht, ist er von Anfang an regelkonform, und man muss nicht nachträglich aufräumen. Die Erklärungen zu Namensrichtlinie und Ablaufrichtlinie finden Sie in Modul 5.3 und 3.1, die Site-Vorlagen in Modul 4.1; hier werden sie zu einer durchgängigen Kette verbunden.

## 10.1 Provisioning Factory

Unter *Provisioning* versteht man das Bereitstellen von Ressourcen: hier einer Microsoft-365-Gruppe mit Postfach, einer SharePoint-Website und optional einem Team. Eine *Provisioning Factory* (Bereitstellungsfabrik) ist ein standardisierter, automatisierter Ablauf, durch den alle neuen Arbeitsbereiche entstehen. Statt dass jeder Benutzer selbst Teams oder Gruppen anlegt (was die Standardeinstellung erlaubt), stellt die Fabrik eine einzige Eingangstür bereit: Man beantragt einen Arbeitsbereich, die Anfrage wird geprüft, und die Fabrik legt alles mit den richtigen Einstellungen an.

Die Fabrik besteht aus fünf Stufen. Die erste ist der Antrag mit den nötigen Angaben (Name, Zweck, Besitzer, Vertraulichkeit). Die zweite ist die Prüfung und Genehmigung (Lerneinheit 10.2). Die dritte ist die technische Anlage: Gruppe, Besitzer, Mitglieder, Team, Website. Die vierte ist die Konfiguration nach Standard, also Vorlage, Beschriftung und Metadaten (Lerneinheiten 10.3 bis 10.5). Die fünfte ist die Registrierung im Bestandsverzeichnis, damit Lebenszyklus (10.6, 10.7) und Berichte wissen, was es gibt. Jede Stufe schreibt ein Protokoll, damit später nachvollziehbar ist, wer wann was beantragt und genehmigt hat.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Anlegen von Teams über Microsoft Graph beschreibt als empfohlenen Weg: Zuerst wird eine Microsoft-365-Gruppe angelegt (mit `groupTypes` gleich „Unified“, `mailEnabled` gleich wahr, `securityEnabled` gleich falsch), danach werden Besitzer und Mitglieder hinzugefügt, und erst dann wird die Gruppe in ein Team umgewandelt. Die Gruppe sollte mindestens zwei Besitzer haben, die echte Benutzerkonten und keine Dienstkonten sind, damit der Arbeitsbereich verwaltbar bleibt. Beim Hinzufügen mehrerer Mitglieder empfiehlt die Dokumentation eine Pause von einer Sekunde je Aufruf. Wichtig für die Reihenfolge: Ist die Gruppe weniger als 15 Minuten alt, kann der Aufruf zum Erstellen des Teams mit dem Fehler 404 scheitern, weil die Replikation noch nicht abgeschlossen ist; die Dokumentation empfiehlt bis zu drei Wiederholungen im Abstand von zehn Sekunden und bei weiterem Misserfolg mindestens 15 Minuten Wartezeit. Die erfolgreiche Anforderung wird mit dem Status 202 (angenommen) beantwortet, das Team entsteht also im Hintergrund, und das Team hat dieselbe Kennung wie die Gruppe.

Aus diesen Eckdaten ergibt sich der Aufbau eines robusten Skripts. Es muss mit Verzögerungen umgehen können, es darf keine halbfertigen Arbeitsbereiche hinterlassen und muss einen Fehler eindeutig melden. Der Kern ist daher eine Wiederholungslogik für den Schritt „Team aus Gruppe erzeugen“. Das folgende Skript legt eine Gruppe an, trägt zwei Besitzer ein und erzeugt mit Wiederholungen das Team. Es gibt am Ende die Kennung zurück, die für das Protokoll benötigt wird. Der Namensteil wird hier als fertiger Parameter übergeben; wie er automatisch gebildet wird, zeigt Lerneinheit 10.4.

**New-GovernedWorkspace.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Nickname,
    [Parameter(Mandatory)][string[]]$Besitzer,
    [string]$Beschreibung = "",
    [ValidateSet("Private","Public")][string]$Sichtbarkeit = "Private"
)

if ($Besitzer.Count -lt 2) { throw "Mindestens zwei Besitzer sind Pflicht." }

Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All" -NoWelcome

$besitzerIds = foreach ($b in $Besitzer) { (Get-MgUser -UserId $b -ErrorAction Stop).Id }

$gruppe = New-MgGroup -DisplayName $Name -MailNickname $Nickname `
    -Description $Beschreibung -GroupTypes @("Unified") `
    -MailEnabled:$true -SecurityEnabled:$false -Visibility $Sichtbarkeit `
    -AdditionalProperties @{
        "owners@odata.bind" = @($besitzerIds | ForEach-Object { "https://graph.microsoft.com/v1.0/users/$_" })
    }
Write-Host "Gruppe angelegt: $($gruppe.Id)"

$versuche = 0
do {
    try {
        Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/groups/$($gruppe.Id)/team" `
            -Body (@{ memberSettings = @{ allowCreatePrivateChannels = $true } } | ConvertTo-Json) `
            -ContentType "application/json" | Out-Null
        $team = $true
    } catch {
        $versuche++
        if ($versuche -ge 3) { throw "Team konnte nicht erzeugt werden: $($_.Exception.Message)" }
        Write-Warning "Team noch nicht moeglich, neuer Versuch in 10 Sekunden ($versuche/3)."
        Start-Sleep -Seconds 10
    }
} until ($team)

[pscustomobject]@{ GruppenId = $gruppe.Id; Name = $Name; Besitzer = ($Besitzer -join "; "); Zeit = (Get-Date -Format s) }
```

Zu Beginn prüft das Skript die Regel „mindestens zwei Besitzer“ und löst die Anmeldenamen in Kennungen auf, wobei `-ErrorAction Stop` bei einem unbekannten Benutzer sofort abbricht, bevor etwas angelegt wird. Danach erzeugt es die Gruppe mit den von der Dokumentation genannten Merkmalen und bindet die Besitzer gleich beim Anlegen ein. Die Schleife versucht bis zu dreimal, die Gruppe in ein Team zu verwandeln, mit zehn Sekunden Abstand. Der PUT-Aufruf auf den Pfad der Gruppe ist die in der Dokumentation beschriebene Variante „Team aus bestehender Gruppe“. Die Rückgabe enthält die Angaben für das Protokoll. In einer echten Fabrik wird nicht in einer Konsole gearbeitet, sondern in einem Runbook (Modul 9.7) mit einer Anwendungsidentität (Modul 11.7).

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, die Fabrik zu bauen, aber die Selbstbedienung nicht einzuschränken: Wenn weiterhin alle Benutzer Gruppen anlegen dürfen, ist die Fabrik nur eine von mehreren Türen und ihr Standard nicht durchsetzbar (Modul 3.3). Zweitens entstehen halbfertige Arbeitsbereiche, wenn ein Skript nach dem Anlegen der Gruppe abbricht und nichts aufräumt. Drittens werden Dienstkonten als Besitzer eingetragen, und die echte Verantwortung fehlt. Viertens verlässt man sich darauf, dass die Website sofort bereitsteht, obwohl die Bereitstellung im Hintergrund läuft.

**Falsch und richtig: Aufraeumen bei Fehlern**

```powershell
# FALSCH: Fehler wird verschluckt, die halbfertige Gruppe bleibt zurueck
try { Invoke-MgGraphRequest -Method PUT -Uri $teamUri -Body $body } catch { }

# RICHTIG: bei endgueltigem Fehler die eigene Gruppe wieder entfernen und melden
try {
    Invoke-MgGraphRequest -Method PUT -Uri $teamUri -Body $body -ContentType "application/json"
} catch {
    Remove-MgGroup -GroupId $gruppe.Id
    throw "Provisioning abgebrochen, Gruppe $($gruppe.Id) entfernt: $($_.Exception.Message)"
}
```

Im richtigen Beispiel wird die selbst angelegte Gruppe wieder gelöscht und der Fehler weitergereicht, so dass das Ticket den Misserfolg zeigt. Das Löschen ist in diesem Fall vertretbar, weil die Gruppe noch keinen Inhalt hat; bei Gruppen mit Inhalt wäre das Aufräumen eine bewusste Entscheidung, siehe Lerneinheit 10.7.

### Praxisbezug.

In Projekten beginnt man oft mit einer einfachen Fabrik: ein Formular, eine Genehmigung, ein Skript. Das reicht für die ersten hundert Arbeitsbereiche. Wichtig ist, dass der Ablauf von Anfang an die Besitzerregel und das Protokoll enthält, weil sich beides später kaum nachrüsten lässt. Messen Sie die Zeit vom Antrag bis zum fertigen Arbeitsbereich; sie ist die Kennzahl, an der Benutzer die Fabrik messen (Modul 9.8).

## 10.2 Request und Approval

Ein Antrag (*Request*) ist die strukturierte Bestellung eines Arbeitsbereichs, eine Genehmigung (*Approval*) die Entscheidung einer verantwortlichen Person darüber. Beides ist mehr als Bürokratie: Der Antrag erzwingt, dass der Zweck, der Besitzer und die Vertraulichkeit angegeben werden, und die Genehmigung verhindert, dass ein vertraulicher oder externer Arbeitsbereich ohne Prüfung entsteht. Die Kunst besteht darin, den Aufwand an das Risiko zu koppeln: Ein internes Projektteam mit normaler Vertraulichkeit soll innerhalb von Minuten entstehen, ein Arbeitsbereich mit Gastzugriff oder hoher Vertraulichkeit darf eine Genehmigung brauchen.

Dafür bewährt sich ein Stufenmodell. Stufe eins ist die automatische Freigabe: Alle Pflichtangaben sind vorhanden, die Vertraulichkeit ist „intern“, Gäste sind nicht vorgesehen. Stufe zwei verlangt die Genehmigung durch die Führungskraft des Besitzers. Stufe drei zieht zusätzlich Datenschutz oder Informationssicherheit hinzu, etwa bei Gastzugriff, bei der Bezeichnung „streng vertraulich“ oder bei Verarbeitung besonderer Kategorien personenbezogener Daten. Die Zuordnung zu einer Stufe erfolgt nach festen Regeln und nicht nach Gefühl, damit zwei gleiche Anträge gleich behandelt werden.

> **Ergänzung aus der Nachrecherche**
>
> Für die Umsetzung stehen in Microsoft 365 mehrere Wege bereit: Genehmigungen in Power Automate und in der Teams-App „Genehmigungen“ sowie, für Zugriffe statt Arbeitsbereiche, die Zugriffspakete der Entra ID Governance (Modul 2.3). Welche Variante passt, hängt von Lizenz und vorhandenen Werkzeugen ab. Die Aussagen in diesem Absatz beruhen auf allgemeinem Fachwissen und wurden nicht in einer abgerufenen Quelle geprüft; prüfen Sie Lizenzvoraussetzungen und Verfügbarkeit in der aktuellen Dokumentation.

Technisch besteht ein Antragsablauf aus drei Teilen: einem Eingabeformular (Microsoft Forms, eine SharePoint-Liste oder ein Portal), einer Regelprüfung, die die Stufe bestimmt, und einem Genehmigungsablauf, der entweder automatisch freigibt oder jemanden fragt. Die Regelprüfung lässt sich als Skript oder als Ablauf-Logik formulieren. Das folgende Skript zeigt sie als PowerShell-Funktion: Sie nimmt einen Antrag als Objekt entgegen, prüft die Pflichtangaben und bestimmt die Genehmigungsstufe. Sie liefert entweder eine Liste von Fehlern oder die Stufe zurück. So lässt sich dieselbe Logik in Tests prüfen, bevor sie in einen produktiven Ablauf eingebaut wird.

**Test-WorkspaceRequest.ps1**

```powershell
function Test-WorkspaceRequest {
    param([Parameter(Mandatory)][pscustomobject]$Antrag)

    $fehler = @()
    foreach ($feld in "Name","Zweck","Besitzer1","Besitzer2","Abteilung","Vertraulichkeit") {
        if ([string]::IsNullOrWhiteSpace($Antrag.$feld)) { $fehler += "Pflichtfeld fehlt: $feld" }
    }
    if ($Antrag.Besitzer1 -and $Antrag.Besitzer1 -eq $Antrag.Besitzer2) {
        $fehler += "Die beiden Besitzer muessen verschiedene Personen sein."
    }
    if ($Antrag.Name -and $Antrag.Name.Length -gt 40) { $fehler += "Name laenger als 40 Zeichen." }
    if ($fehler) { return [pscustomobject]@{ Gueltig = $false; Fehler = $fehler; Stufe = $null } }

    $stufe = 1
    if ($Antrag.Gaeste -eq $true)                                  { $stufe = 3 }
    elseif ($Antrag.Vertraulichkeit -in "Vertraulich","Streng")    { $stufe = 3 }
    elseif ($Antrag.Vertraulichkeit -eq "Intern" -and $Antrag.Groesse -gt 200) { $stufe = 2 }

    [pscustomobject]@{ Gueltig = $true; Fehler = @(); Stufe = $stufe }
}

# Beispielaufruf
$antrag = [pscustomobject]@{
    Name = "Projekt Phoenix"; Zweck = "Produktlaunch"; Besitzer1 = "anna@contoso.com"
    Besitzer2 = "ben@contoso.com"; Abteilung = "Vertrieb"; Vertraulichkeit = "Intern"
    Gaeste = $false; Groesse = 12
}
Test-WorkspaceRequest -Antrag $antrag | Format-List
```

Die Funktion sammelt zuerst alle Fehler in einer Liste, statt beim ersten abzubrechen, damit die antragstellende Person alles auf einmal korrigieren kann. Danach wird die Stufe nach festen Regeln bestimmt: Gäste und hohe Vertraulichkeit führen zu Stufe drei, ein sehr großer interner Arbeitsbereich zu Stufe zwei, alles andere ist Stufe eins. Der Beispielaufruf am Ende ergibt Stufe eins, also eine automatische Freigabe. In einer echten Umsetzung stehen die Grenzwerte (hier 200 Personen) in einer Konfigurationsdatei und nicht im Code (Lerneinheit 11.4).

### Typische Fehler und Stolperfallen.

Zu häufig werden alle Anträge gleich behandelt, und die Genehmigenden bestätigen reflexartig. Zweitens bleibt die Genehmigung ohne Frist liegen; ein Antrag, der drei Wochen wartet, treibt die Benutzer in die Schattenorganisation, etwa in private Chats oder externe Werkzeuge. Drittens wird die Entscheidung nicht protokolliert, und bei einer Prüfung kann man nicht zeigen, wer zugestimmt hat. Viertens fehlt eine Vertretungsregel für Genehmigende im Urlaub.

**Falsch und richtig: Antrag pruefen**

```powershell
# FALSCH: alles genehmigen lassen, Pflichtfelder nicht pruefen
$stufe = 2

# RICHTIG: Stufe aus Regeln ableiten, bei fehlenden Angaben zurueckweisen
$ergebnis = Test-WorkspaceRequest -Antrag $antrag
if (-not $ergebnis.Gueltig) { $ergebnis.Fehler | ForEach-Object { Write-Warning $_ }; return }
"Genehmigungsstufe: $($ergebnis.Stufe)"
```

Mit der Regelprüfung entscheiden Menschen nur dort, wo ein Urteil nötig ist. Die Fristen und Vertretungen gehören in den Genehmigungsablauf selbst; viele Werkzeuge erlauben eine Erinnerung nach wenigen Tagen und eine Eskalation an die Vertretung.

### Praxisbezug.

Starten Sie mit zwei Stufen, nicht mit fünf. Messen Sie die Zahl der Anträge je Stufe und die Bearbeitungsdauer; wenn die Stufe zwei 95 Prozent der Anträge ohne Änderung genehmigt, gehört ihre Regel nach Stufe eins. Die Entscheidungen werden im Bestandsverzeichnis gespeichert und dienen später als Nachweis bei Audits (Modul 7).

## 10.3 Templates

Eine *Vorlage* (Template) legt fest, wie ein neuer Arbeitsbereich beim Start aussieht: welche Kanäle ein Team hat, welche Apps und Registerkarten eingebunden sind, welche Struktur, Navigation und Bibliotheken eine Website besitzt. Für die Governance sind Vorlagen aus zwei Gründen wichtig. Erstens sparen sie den Benutzern Arbeit und führen zu einheitlichen Arbeitsbereichen, in denen man sich zurechtfindet. Zweitens binden sie Standards ein, die man sonst vergessen würde: ein Kanal für Dokumentation, ein Planner, die Beschriftung, die richtigen Freigabeeinstellungen.

Für Teams gibt es die Basisvorlage „standard“ und von Microsoft bereitgestellte oder selbst erstellte Teams-Vorlagen. Für SharePoint gibt es Websitevorlagen und Websitedesigns mit Websiteskripten (Modul 4.1) sowie PnP-Bereitstellungsvorlagen für komplexere Strukturen. Eine gute Praxis ist, die Zahl der Vorlagen klein zu halten, etwa „Projekt“, „Abteilung“, „Gremium“ und „Kunde“, weil jede Vorlage gepflegt werden muss und eine zu große Auswahl die Benutzer überfordert.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zur Graph-Schnittstelle „Team erstellen“ lässt sich ein Team auf Basis einer Vorlage anlegen, indem im Anfragetext die Vorlage über `template@odata.bind` (zum Beispiel die Basisvorlage „standard“) und, wenn das Team zu einer bestehenden Gruppe gehören soll, die Gruppe über `group@odata.bind` angegeben wird. Ein dokumentiertes Beispiel zeigt außerdem, dass ein Team beim Erstellen gleich mit mehreren Kanälen, installierten Apps und angehefteten Registerkarten angelegt werden kann. Wird die Gruppe angegeben, übernimmt das Team Eigenschaften wie Anzeigename, Sichtbarkeit und Mitglieder von der Gruppe; die gleichzeitige Angabe von Anzeigename, Sichtbarkeit oder Mitgliedern im Teamteil führt zu einem Fehler, und ein erster Kanalname wird beim Erstellen aus einer Gruppe nicht unterstützt.

Aus der Dokumentation folgt ein praktisches Vorgehen: Man hält die Vorlage als Datei (JSON) im Versionsverwaltungssystem und liest daraus die Kanäle, die beim Anlegen oder danach erzeugt werden. Das folgende Beispiel zeigt eine einfache Vorlagendatei und ein Skript, das die darin beschriebenen Kanäle in einem vorhandenen Team anlegt. Es wählt bewusst den einfachen Weg, nach dem Erstellen Kanäle hinzuzufügen, weil er unabhängig von der Variante des Erstellungsaufrufs funktioniert.

**vorlage-projekt.json**

```json
{
  "name": "Projekt",
  "beschreibung": "Standardvorlage fuer Projektteams",
  "kanaele": [
    { "name": "Planung",      "beschreibung": "Zeitplan und Meilensteine" },
    { "name": "Dokumentation", "beschreibung": "Ergebnisse und Protokolle" },
    { "name": "Abstimmung",   "beschreibung": "Fragen und Entscheidungen" }
  ],
  "sensitivityLabel": "Intern"
}
```

Die Datei enthält den Namen der Vorlage, eine Beschreibung, die Liste der Kanäle und die vorgesehene Beschriftung. Sie ist bewusst klein und lesbar, damit auch Fachverantwortliche sie prüfen können. Das Skript liest sie ein, legt jeden Kanal an, der noch nicht existiert, und meldet das Ergebnis. Die Prüfung auf vorhandene Kanäle macht das Skript wiederholbar (idempotent): Ein zweiter Lauf legt nichts doppelt an.

**Apply-TeamTemplate.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$TeamId,
    [Parameter(Mandatory)][string]$Vorlage
)

Connect-MgGraph -Scopes "Channel.Create","ChannelSettings.Read.All" -NoWelcome

$v = Get-Content -Path $Vorlage -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $v.kanaele) { throw "Vorlage enthaelt keine Kanaele." }

$vorhanden = (Get-MgTeamChannel -TeamId $TeamId).DisplayName

foreach ($k in $v.kanaele) {
    if ($k.name -in $vorhanden) {
        Write-Host "Kanal vorhanden, uebersprungen: $($k.name)"
        continue
    }
    New-MgTeamChannel -TeamId $TeamId -DisplayName $k.name -Description $k.beschreibung | Out-Null
    Write-Host "Kanal angelegt: $($k.name)"
}
```

Das Skript liest die Datei als UTF-8, damit Umlaute erhalten bleiben, und bricht ab, wenn keine Kanäle definiert sind. Dann holt es die Namen der vorhandenen Kanäle und legt nur die fehlenden an. Die Beschriftung aus der Vorlage wird hier nicht gesetzt; sie wird über die Richtlinien aus Modul 6.1 und 4.5 angewendet.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist die Vorlagenflut: Für jede Abteilung gibt es drei Varianten, und niemand pflegt sie. Zweitens werden Vorlagen nur beim Start angewendet, und bestehende Arbeitsbereiche laufen auseinander, weil spätere Änderungen an der Vorlage nicht nachgezogen werden. Drittens wird die Vorlage nicht versioniert, sodass niemand weiß, welche Fassung ein Team erhalten hat. Viertens enthalten Vorlagen Standardmitglieder oder feste Gäste, die später zu falschen Rechten führen.

**Falsch und richtig: Wiederholbar anlegen**

```powershell
# FALSCH: Kanal immer neu anlegen, zweiter Lauf erzeugt einen Fehler
New-MgTeamChannel -TeamId $TeamId -DisplayName "Planung"

# RICHTIG: erst pruefen, dann anlegen
if ("Planung" -notin (Get-MgTeamChannel -TeamId $TeamId).DisplayName) {
    New-MgTeamChannel -TeamId $TeamId -DisplayName "Planung" | Out-Null
}
```

Durch die Prüfung lässt sich dasselbe Skript später erneut auf bestehende Teams anwenden, um Abweichungen von der Vorlage nachzuziehen. Das ist die Grundlage für die Drift-Erkennung in Modul 11.5.

### Praxisbezug.

Führen Sie die Vorlagen zusammen mit den Fachbereichen ein: Jede Vorlage hat einen Besitzer, eine Versionsnummer und ein Änderungsdatum. Ergänzen Sie in der Vorlage nur, was alle Teams dieses Typs brauchen. Alles Weitere sollen die Teams selbst entscheiden, sonst wird die Vorlage als Bevormundung wahrgenommen.

## 10.4 Naming Automation

Namen sind die einfachste und zugleich wirksamste Ordnungsmaßnahme in Microsoft 365: Wer Arbeitsbereiche am Namen erkennt, findet sie, ordnet sie einer Abteilung zu und kann sie in Berichten filtern. Die Namensrichtlinie aus Modul 5.3 setzt Präfixe, Suffixe und gesperrte Wörter beim Anlegen durch; die Namenskonvention für Teams steht in Modul 3.2. *Naming Automation* geht einen Schritt weiter: Die Fabrik bildet den Namen aus den Angaben des Antrags selbst, statt ihn der antragstellenden Person zu überlassen, prüft ihn auf Eindeutigkeit und leitet daraus weitere technische Namen ab, etwa die E-Mail-Adresse der Gruppe (den *Mail-Nickname*) und die Adresse der Website.

Eine gute Namenskonvention beantwortet drei Fragen: Was ist es (Typ), wem gehört es (Abteilung oder Projekt), und worum geht es (Freitext)? Ein Beispiel ist „PRJ-VER-Produktlaunch-2026“ für ein Projekt der Vertriebsabteilung. Der Typ und die Abteilung stammen aus festen Listen, nur der Freitext kommt vom Benutzer. Dadurch bleiben die Namen sortierbar und maschinenlesbar. Der Preis ist, dass die Listen gepflegt werden müssen, und dass Namen sich nicht mehr ändern sollten, weil Adressen und Verweise an ihnen hängen.

> **Ergänzung aus der Nachrecherche**
>
> Aus den Angaben der Microsoft-Dokumentation zur Namensrichtlinie (siehe Modul 5.3) ergeben sich Rahmenbedingungen für die Automatisierung: Die Gesamtlänge des Gruppennamens einschließlich Präfix und Suffix ist auf 63 Zeichen begrenzt, die Richtlinie wird bei der Anlage durchgesetzt, und bestimmte Administratorrollen sind von ihr ausgenommen. Eine Fabrik, die über die Anwendungsidentität arbeitet, sollte deshalb Namen so bilden, dass sie die Vorgaben von sich aus erfüllen, statt auf die Ablehnung durch die Richtlinie zu warten. Weitere technische Einschränkungen für Mail-Nicknames (erlaubte Zeichen, Länge) sind der aktuellen Graph-Referenz zur Gruppenressource zu entnehmen; die Beispiele hier gehen auf der sicheren Seite und verwenden nur Kleinbuchstaben, Ziffern und Bindestriche.

Das folgende Skript bildet aus Typ, Abteilung und Freitext den Anzeigenamen und den Mail-Nickname. Es entfernt Umlaute und Sonderzeichen (aus „ä“ wird „ae“), kürzt auf die erlaubte Länge, prüft über Microsoft Graph, ob der Name schon vergeben ist, und hängt bei Bedarf eine laufende Nummer an. Die Funktion ist so geschrieben, dass sie in der Fabrik aus Lerneinheit 10.1 aufgerufen werden kann.

**New-WorkspaceName.ps1**

```powershell
function ConvertTo-Slug {
    param([string]$Text)
    $t = $Text.ToLower()
    $t = $t -replace 'ä','ae' -replace 'ö','oe' -replace 'ü','ue' -replace 'ß','ss'
    $t = $t -replace '[^a-z0-9]+','-'
    $t.Trim('-')
}

function New-WorkspaceName {
    param(
        [Parameter(Mandatory)][ValidateSet("PRJ","ABT","GRM","KND")][string]$Typ,
        [Parameter(Mandatory)][ValidateLength(2,5)][string]$Abteilung,
        [Parameter(Mandatory)][string]$Freitext,
        [int]$MaxLaenge = 50
    )

    $slug = ConvertTo-Slug $Freitext
    $basis = "{0}-{1}-{2}" -f $Typ, $Abteilung.ToUpper(), $slug
    if ($basis.Length -gt $MaxLaenge) { $basis = $basis.Substring(0, $MaxLaenge).TrimEnd('-') }

    $name = $basis
    $nr = 1
    while (Get-MgGroup -Filter "mailNickname eq '$(ConvertTo-Slug $name)'" -ErrorAction SilentlyContinue) {
        $nr++
        $suffix = "-$nr"
        $name = $basis.Substring(0, [math]::Min($basis.Length, $MaxLaenge - $suffix.Length)) + $suffix
    }

    [pscustomobject]@{ Anzeigename = $name; Nickname = (ConvertTo-Slug $name) }
}

# Beispiel
New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext "Produktlaunch Frühjahr"
```

Die erste Funktion wandelt Text in eine sichere Kleinschreibung um: Sie ersetzt Umlaute, ersetzt alle anderen Sonderzeichen durch Bindestriche und entfernt Bindestriche am Rand. Die zweite Funktion setzt den Namen aus den drei Bestandteilen zusammen, kürzt ihn und sucht in einer Schleife nach einem freien Namen, indem sie bei einer Kollision eine Nummer anhängt. Wichtig ist, dass die Länge nach dem Anhängen der Nummer erneut eingehalten wird. Die Filtersyntax des Graph-Cmdlets erwartet einfache Anführungszeichen um den Wert; da der Slug nur Kleinbuchstaben, Ziffern und Bindestriche enthält, ist keine Maskierung nötig, was bei freiem Text anders wäre.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist, Freitext unbearbeitet in Adressen zu übernehmen: Leerzeichen, Umlaute oder Apostrophe führen zu Fehlern oder zu überraschenden Adressen. Zweitens werden Namen nachträglich geändert, und die E-Mail-Adresse, die Website-Adresse und die Links folgen nicht mit. Drittens wird die Eindeutigkeit nicht geprüft, und die Fabrik scheitert erst im letzten Schritt. Viertens ist die Abkürzungsliste (Typen, Abteilungen) veraltet.

**Falsch und richtig: Adresse bilden**

```powershell
# FALSCH: Freitext direkt als Nickname
$nick = "Produktlaunch Frühjahr (Vertrieb)"

# RICHTIG: normalisieren und Zeichensatz begrenzen
$nick = ConvertTo-Slug "Produktlaunch Frühjahr (Vertrieb)"   # produktlaunch-fruehjahr-vertrieb
```

Die Normalisierung verhindert ungültige Zeichen und liefert reproduzierbare Ergebnisse. Prüfen Sie die Funktion mit schwierigen Eingaben (Umlaute, sehr lange Texte, nur Sonderzeichen), bevor sie in der Fabrik läuft.

### Praxisbezug.

Stimmen Sie die Konvention mit den Fachbereichen ab, bevor Sie sie automatisieren, und dokumentieren Sie sie auf einer Seite. Wer nach Jahren einen Arbeitsbereich im Bericht sieht, soll am Namen erkennen können, wer ihn verantwortet. Das erleichtert auch die Zugriffsüberprüfung (Modul 2.4) und die Kostenverteilung (Modul 12.3).

## 10.5 Metadata Standards

*Metadaten* sind Daten über den Arbeitsbereich: Besitzer, Abteilung, Kostenstelle, Vertraulichkeit, Zweck, Erstellungsdatum, geplantes Ende. Sie entscheiden, ob Governance sich messen und steuern lässt. Ohne Metadaten kann man nicht beantworten, wie viele Arbeitsbereiche eine Abteilung hat, welche vertraulich sind oder wann ein Projekt endet. Ein *Metadatenstandard* legt fest, welche Angaben Pflicht sind, wie sie heißen, welche Werte erlaubt sind und wo sie gespeichert werden.

Der Speicherort ist die schwierigste Frage. Es gibt mehrere Möglichkeiten, die nebeneinander bestehen können: die Beschreibung der Gruppe (einfach, aber unstrukturiert), Eigenschaften an der Gruppe wie Abteilung oder Anzeigename, Erweiterungen des Verzeichnisobjekts, die Eigenschaften der SharePoint-Website (Modul 4) und das Bestandsverzeichnis der Fabrik, etwa eine SharePoint-Liste oder eine Datenbank. Bewährt hat sich, eine Quelle zur „führenden“ zu erklären, meist das Bestandsverzeichnis, und die anderen daraus zu füllen, sodass die Zuständigkeit klar ist. Die Beschriftung (Sensitivity Label, Modul 6.1) ist der einzige Teil der Metadaten, der technisch durchgesetzt wird; die übrigen sind Information.

> **Ergänzung aus der Nachrecherche**
>
> Für die Speicherung zusätzlicher Eigenschaften an Gruppen bietet Microsoft Graph sogenannte offene Erweiterungen (Open Extensions) und Schemaerweiterungen. Offene Erweiterungen sind einfach zu verwenden, tragen aber keine Typprüfung und lassen sich nicht in jeder Abfrage filtern; Schemaerweiterungen sind typisiert, brauchen aber einen Registrierungsschritt. Diese Aussage beruht auf allgemeinem Fachwissen und wurde in diesem Kurs nicht in der Dokumentation abgerufen; prüfen Sie Verfügbarkeit, Grenzen (Anzahl Erweiterungen, Größe) und Filtermöglichkeiten in der aktuellen Graph-Referenz, bevor Sie sich festlegen. Die Alternative, die Metadaten in einer Liste zu führen, ist unabhängig von diesen Grenzen und für viele Organisationen die robustere Wahl.

Entscheidend ist weniger der Speicherort als die Vollständigkeit. Ein Standard, der nicht geprüft wird, ist keiner. Deshalb gehört zu jedem Metadatenstandard eine automatische Prüfung, die Arbeitsbereiche mit fehlenden oder ungültigen Angaben findet. Das folgende Skript definiert den Standard als Liste von Regeln und prüft damit die Gruppen eines Tenants. Es nutzt dafür die vorhandenen Gruppeneigenschaften (Beschreibung, Besitzer) und lässt sich um die Felder Ihres Bestandsverzeichnisses erweitern. Es meldet jede Gruppe mit Verstößen und zählt am Ende die Quote der konformen Gruppen.

**Test-MetadataStandard.ps1**

```powershell
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
    -Property Id,DisplayName,Description,Visibility,CreatedDateTime
if (-not $gruppen) { Write-Host "Keine Microsoft-365-Gruppen gefunden."; return }

$muster = '^(PRJ|ABT|GRM|KND)-[A-Z]{2,5}-'
$befunde = foreach ($g in $gruppen) {
    $probleme = @()
    if ($g.DisplayName -notmatch $muster)                         { $probleme += "Name entspricht nicht der Konvention" }
    if ([string]::IsNullOrWhiteSpace($g.Description))             { $probleme += "Beschreibung fehlt" }
    $besitzer = @(Get-MgGroupOwner -GroupId $g.Id)
    if ($besitzer.Count -lt 2)                                    { $probleme += "weniger als zwei Besitzer ($($besitzer.Count))" }
    if ($probleme) {
        [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $g.Id; Befund = ($probleme -join "; ") }
    }
}

$gesamt = @($gruppen).Count
$konform = $gesamt - @($befunde).Count
"{0} von {1} Gruppen konform ({2:P0})" -f $konform, $gesamt, ($konform / $gesamt)
$befunde | Sort-Object Gruppe | Export-Csv -Path ".\metadaten-befunde.csv" -NoTypeInformation -Encoding UTF8
```

Der Filter holt nur Microsoft-365-Gruppen (Gruppentyp „Unified“) und fordert gezielt die benötigten Eigenschaften an, was die Abfrage beschleunigt. Für jede Gruppe prüft das Skript drei Regeln: den Namen gegen den regulären Ausdruck der Konvention, die Beschreibung und die Zahl der Besitzer. Befunde werden gesammelt und als CSV gespeichert; die Quote ist eine Kennzahl für den Bericht (Modul 9.8). Bei sehr vielen Gruppen ist die Abfrage der Besitzer pro Gruppe langsam und kann gedrosselt werden (Lerneinheit 10.8); dann nutzt man Stapelanfragen.

### Typische Fehler und Stolperfallen.

Ein Standard mit zu vielen Pflichtfeldern wird mit Platzhaltern ausgefüllt („n/a“, „-“), die wertlos sind. Zweitens werden Metadaten nur beim Anlegen erhoben und veralten, weil niemand sie aktualisiert; ein Besitzer, der das Unternehmen verlassen hat, ist kein Besitzer mehr. Drittens existieren dieselben Angaben an mehreren Orten mit abweichenden Werten. Viertens wird die Prüfung nur einmal durchgeführt und nicht regelmäßig.

**Falsch und richtig: Pflichtangabe pruefen**

```powershell
# FALSCH: nur auf "nicht leer" pruefen, Platzhalter bestehen die Pruefung
if ($g.Description) { "ok" }

# RICHTIG: Platzhalter erkennen und Mindestlaenge verlangen
$platzhalter = "n/a","-","tbd","test","."
if ([string]::IsNullOrWhiteSpace($g.Description) -or $g.Description.Trim().Length -lt 15 -or $g.Description.Trim().ToLower() -in $platzhalter) {
    "Beschreibung unbrauchbar"
}
```

Die strengere Prüfung erkennt unbrauchbare Einträge. Sie sollte mit Augenmaß eingesetzt werden: Ein Mindestlängen-Test ist eine Hilfe, kein Beweis für Qualität. Die Fachbereiche erhalten die Befunde zur Korrektur, und nur hartnäckige Fälle gehen in die Eskalation.

### Praxisbezug.

Beginnen Sie mit wenigen Pflichtfeldern (Besitzer, Zweck, Vertraulichkeit, Abteilung) und erweitern Sie den Standard erst, wenn diese zuverlässig gepflegt werden. Legen Sie die Zuständigkeit fest: Wer korrigiert falsche Metadaten, und bis wann? Die Quote konformer Arbeitsbereiche ist eine der aussagekräftigsten Governance-Kennzahlen.

## 10.6 Lifecycle Jobs

Arbeitsbereiche haben einen Lebenslauf: Sie werden beantragt, genutzt, werden ruhig, verwaisen und werden schließlich archiviert oder gelöscht. Ohne Steuerung bleiben sie fast alle in der Phase „ruhig“ stehen, belegen Speicher und Lizenzen, enthalten veraltete Berechtigungen und gefährden bei Fehlbedienung vertrauliche Inhalte. *Lifecycle Jobs* sind automatische, wiederkehrende Aufgaben, die den Lebenslauf steuern: Sie erkennen Arbeitsbereiche ohne Besitzer oder Aktivität, erinnern die Verantwortlichen, verlängern aktive Arbeitsbereiche und leiten bei ausbleibender Reaktion die nächste Phase ein.

Microsoft bietet dafür mehrere eingebaute Mechanismen, die sich ergänzen. Die Ablaufrichtlinie für Microsoft-365-Gruppen (Entra ID) setzt eine Lebensdauer und lässt Gruppen nach Ablauf löschen, sofern sie nicht verlängert werden. Die Richtlinien für die Lebenszyklusverwaltung von SharePoint-Websites (SharePoint Advanced Management) erkennen inaktive Websites, Websites ohne ausreichend Besitzer und verlangen Bestätigungen. Eigene Jobs schließen die Lücken, etwa für die Prüfung der Metadaten (Lerneinheit 10.5) oder für Berichte an die Verantwortlichen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Ablaufrichtlinie für Microsoft-365-Gruppen nennt folgende Eckdaten: Gruppen mit Benutzeraktivität werden vor dem Ablauf automatisch verlängert; ist das nicht der Fall, erhalten die Besitzer Benachrichtigungen 30 Tage, 15 Tage und einen Tag vor dem Ablauf. Eine nicht verlängerte Gruppe wird einen Tag nach dem Ablaufdatum gelöscht und kann danach 30 Tage lang wiederhergestellt werden; diese Frist ist nicht änderbar. Die Lebensdauer muss mindestens 30 Tage betragen, und es kann nur eine einzige Ablaufrichtlinie für alle Microsoft-365-Gruppen eines Tenants geben, die entweder alle, ausgewählte (bis zu 500) oder keine Gruppen betrifft. Beim erstmaligen Einrichten werden Gruppen, die älter als das Intervall sind, auf 35 Tage bis zum Ablauf gesetzt, sofern sie nicht automatisch oder vom Besitzer verlängert werden. Für die Richtlinie sind Entra-ID-P1- oder P2-Lizenzen für die Mitglieder der betroffenen Gruppen erforderlich (besitzen, aber nicht zwingend zuweisen), und die Mindestrolle für die Einrichtung ist die des Benutzeradministrators. Die Aktivitätsbewertung für die automatische Verlängerung erfolgt über Outlook, SharePoint, Teams und andere Dienste; ein Teams-Besuch eines Kanals reicht für die Verlängerung eines Teams.
>
> Für SharePoint beschreibt die Dokumentation zur Websitelebenszyklusverwaltung drei Richtlinientypen: Inaktive Websites, Websitebesitz und Websitebestätigung (Attestation). Bei fehlender Reaktion der Besitzer nach drei monatlichen Benachrichtigungen sind drei Folgeaktionen möglich: nichts unternehmen (nur berichten), Schreibschutz setzen oder nach einer wählbaren Schreibschutzzeit von 3, 6, 9 oder 12 Monaten über Microsoft 365 Archive archivieren. Jede Richtlinie kann im Simulationsmodus einmal laufen und einen Bericht erzeugen, bevor sie im aktiven Modus wiederkehrend ausgeführt wird. Überlappende Richtlinien desselben Typs auf denselben Websites sollte man vermeiden.

Die Simulation ist die wichtigste Schutzmaßnahme. Bevor eine Richtlinie Benachrichtigungen verschickt oder Websites sperrt, läuft sie einmal im Simulationsmodus; man prüft den Bericht und passt Umfang und Ausnahmen an. Bei der Ablaufrichtlinie für Gruppen gibt es keinen Testmodus, deshalb ist dort besondere Vorsicht geboten: Man schaltet sie zunächst für eine kleine ausgewählte Gruppenliste ein, beobachtet die Wirkung und erweitert dann.

Das folgende Skript richtet die Ablaufrichtlinie über Microsoft Graph ein, zunächst nur für ausgewählte Gruppen. Es legt eine Richtlinie mit 365 Tagen Lebensdauer an, setzt eine Adresse für Gruppen ohne Besitzer und fügt eine Testgruppe hinzu. Existiert schon eine Richtlinie, bricht es ab, weil es nur eine geben kann.

**New-GroupExpirationPolicy.ps1**

```powershell
param(
    [int]$Lebensdauer = 365,
    [Parameter(Mandatory)][string]$AdresseOhneBesitzer,
    [Parameter(Mandatory)][string]$TestgruppeId
)

if ($Lebensdauer -lt 30) { throw "Die Lebensdauer muss mindestens 30 Tage betragen." }

Connect-MgGraph -Scopes "Directory.ReadWrite.All" -NoWelcome

if (Get-MgGroupLifecyclePolicy) { throw "Es existiert bereits eine Ablaufrichtlinie." }

$richtlinie = New-MgGroupLifecyclePolicy -GroupLifetimeInDays $Lebensdauer `
    -ManagedGroupTypes "Selected" -AlternateNotificationEmails $AdresseOhneBesitzer

Add-MgGroupLifecyclePolicyGroup -GroupLifecyclePolicyId $richtlinie.Id -GroupId $TestgruppeId

Get-MgGroupLifecyclePolicy | Format-List Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails
```

Das Skript prüft zuerst die Mindestdauer und das Fehlen einer vorhandenen Richtlinie, was die Dokumentation vorgibt. Der Wert „Selected“ für die verwalteten Gruppentypen beschränkt die Richtlinie auf ausdrücklich hinzugefügte Gruppen. Die Testgruppe wird mit `Add-MgGroupLifecyclePolicyGroup` aufgenommen. Nach einigen Wochen Beobachtung stellt man den Gruppentyp auf „All“ um oder fügt weitere Gruppen hinzu.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, die Ablaufrichtlinie sofort für alle Gruppen scharfzuschalten, ohne die Besitzer zu informieren: Die Benachrichtigungen gehen an Personen, die sie nicht erwarten, und echte Arbeitsbereiche gehen verloren. Zweitens sind viele Gruppen ohne Besitzer, so dass die Meldungen an die Ersatzadresse gehen, die niemand liest. Drittens wird die Aktivität falsch eingeschätzt: Eine Gruppe, die nur im Hintergrund genutzt wird (etwa ein Archiv), erscheint inaktiv. Viertens überlagern sich mehrere Richtlinien.

**Falsch und richtig: Einfuehrung**

```powershell
# FALSCH: sofort fuer alle Gruppen, ohne Vorinformation
New-MgGroupLifecyclePolicy -GroupLifetimeInDays 90 -ManagedGroupTypes "All" `
    -AlternateNotificationEmails "niemand@contoso.com"

# RICHTIG: zuerst ausgewaehlte Gruppen, realistische Dauer, gepflegte Ersatzadresse
New-MgGroupLifecyclePolicy -GroupLifetimeInDays 365 -ManagedGroupTypes "Selected" `
    -AlternateNotificationEmails "m365-governance@contoso.com"
```

Die richtige Variante ist vorsichtiger: längere Dauer, kleiner Umfang, eine Adresse, die ein Team liest. Zusätzlich informiert man die Besitzer im Voraus über den Zweck und über das, was sie tun müssen. Der Erfolg der Richtlinie hängt weniger von der Technik als von dieser Kommunikation ab (Modul 12.4).

### Praxisbezug.

Planen Sie die Einführung von Lifecycle-Richtlinien wie ein Projekt: Bestandsaufnahme der Gruppen ohne Besitzer, Bereinigung, Simulation der SharePoint-Richtlinien, Kommunikation an die Besitzer, Pilotgruppe, Ausweitung. Verfolgen Sie danach die Zahl der verlängerten, gelöschten und wiederhergestellten Arbeitsbereiche; viele Wiederherstellungen sind ein Zeichen, dass die Kommunikation nicht ausreichte.

## 10.7 Archive und Delete

Am Ende des Lebenslaufs steht die Entscheidung, was mit einem Arbeitsbereich geschieht. Es gibt vier Möglichkeiten, die sich in Eingriffstiefe und Umkehrbarkeit unterscheiden. Der *Schreibschutz* (Read-only) lässt Inhalte sichtbar, verhindert aber Änderungen. Das *Archivieren* nimmt einen Arbeitsbereich aus der täglichen Nutzung, erhält aber Inhalte, Berechtigungen und Metadaten. Das *Löschen* entfernt ihn, wobei Microsoft 365 zunächst ein vorläufiges Löschen (Soft Delete) mit Wiederherstellungsfrist vornimmt. Das *endgültige Löschen* ist nicht umkehrbar. Eine Governance legt fest, wann welche Stufe eintritt und wer entscheidet. Die Reihenfolge heißt meist: Benachrichtigung, Schreibschutz, Archiv, Löschung, jeweils mit Fristen dazwischen.

Zwei Prüfungen gehören vor jede Löschung, weil die Technik sie nicht ersetzt. Die erste ist die Aufbewahrung: Unterliegt der Inhalt einer Aufbewahrungspflicht oder einem Hold (Modul 6.3 und 7.6), bleibt er erhalten, auch wenn der Arbeitsbereich gelöscht wird; das ist gewollt, muss aber bedacht sein. Die zweite ist die Fachverantwortung: Die Besitzer entscheiden, ob die Inhalte noch gebraucht werden, nicht die IT. Deshalb gehört zu jedem Löschlauf eine Frist, in der die Besitzer widersprechen können.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt für Teams den Vorgang des Archivierens über die Graph-Schnittstelle: Der Aufruf (POST auf den Archivpfad des Teams) wird mit 202 beantwortet, die Archivierung läuft also im Hintergrund. Im archivierten Zustand können Benutzer in der Regel nichts mehr ändern, etwa keine Nachrichten senden oder liken und weder Namen noch Beschreibung ändern; Änderungen an der Mitgliedschaft bleiben jedoch erlaubt. Zum Archivieren müssen das Team und die Gruppe einen Besitzer haben. Mit der Gegenoperation lässt sich der Zustand rückgängig machen. Für gelöschte Microsoft-365-Gruppen gilt nach der Dokumentation eine Wiederherstellungsfrist von 30 Tagen, die nicht anpassbar ist; die Wiederherstellung umfasst unter anderem das Gruppenobjekt, die Postfachadressen, das gemeinsame Postfach und den Kalender, die SharePoint-Website samt Dateien, Planner, das Team und den OneNote-Notizblock, und sie kann bis zu 24 beziehungsweise 48 Stunden dauern (die beiden Dokumentationsseiten nennen unterschiedliche Werte, planen Sie also die längere Zeit ein). Nach den 30 Tagen sind Gruppe und Inhalt endgültig gelöscht.
>
> Für SharePoint-Websites beschreibt die Dokumentation zu Microsoft 365 Archive, dass eine archivierte Website in eine kostengünstige Speicherebene verschoben wird, keinen aktiven Speicherplatz mehr belegt, Inhalt, Berechtigungen und Metadaten behält und erst nach der Reaktivierung wieder zugänglich ist. Die Reaktivierung ist Tenant-Administratoren vorbehalten. Der Schreibschutz einer Website kann ebenfalls nur von Administratoren aufgehoben werden, nicht von den Besitzern. Archivierung setzt voraus, dass Microsoft 365 Archive im Tenant aktiviert ist und abgerechnet wird; dazu muss in der Regel eine nutzungsabhängige Abrechnung eingerichtet sein.

Aus diesen Angaben folgen die Regeln für die Fabrik. Archivieren ist für Teams ein sicherer, schnell umkehrbarer erster Schritt. Löschen ist ebenfalls umkehrbar, aber nur innerhalb der Frist, und die Wiederherstellung kann einen Tag dauern. Deshalb sollte ein Löschlauf nie automatisch am letzten Tag der Frist alles löschen, sondern vorher einen Bericht an die Verantwortlichen schicken. Das folgende Skript archiviert Teams, deren Gruppe nach einer Liste (zum Beispiel aus dem Bericht über inaktive Gruppen) als beendet gilt. Es prüft, ob das Team Besitzer hat, protokolliert jeden Schritt und hat einen Probelaufmodus.

**Archive-InactiveTeams.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Liste,      # CSV mit Spalte GruppenId
    [switch]$Ausfuehren,                       # ohne diesen Schalter nur Probelauf
    [string]$Protokoll = ".\archiv-protokoll.csv"
)

Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","Group.Read.All" -NoWelcome

$ziele = Import-Csv -Path $Liste
if (-not $ziele) { throw "Die Liste ist leer." }

$ergebnis = foreach ($z in $ziele) {
    $id = $z.GruppenId
    $status = "uebersprungen"
    try {
        $besitzer = @(Get-MgGroupOwner -GroupId $id -ErrorAction Stop)
        if ($besitzer.Count -eq 0) {
            $status = "kein Besitzer - manuell klaeren"
        } elseif (-not $Ausfuehren) {
            $status = "Probelauf: wuerde archivieren"
        } else {
            Invoke-MgArchiveTeam -TeamId $id -ErrorAction Stop
            $status = "Archivierung angestossen"
        }
    } catch {
        $status = "Fehler: " + $_.Exception.Message
    }
    [pscustomobject]@{ GruppenId = $id; Status = $status; Zeit = (Get-Date -Format s) }
}

$ergebnis | Export-Csv -Path $Protokoll -NoTypeInformation -Encoding UTF8
$ergebnis | Format-Table -AutoSize -Wrap
```

Das Skript liest die Liste, ruft pro Eintrag die Besitzer ab und archiviert nur, wenn es Besitzer gibt, denn die Dokumentation verlangt das. Ohne den Schalter `-Ausfuehren` meldet es nur, was es täte; das ist die wichtigste Sicherung, weil Fehler in der Liste sofort sichtbar werden. Jeder Schritt landet im Protokoll. Beachten Sie, dass die Archivierung im Hintergrund abläuft, die Antwort also keinen Abschluss bedeutet; der Zustand ist später am Team ablesbar.

Das Löschen und Wiederherstellen von Gruppen ist ebenfalls skriptbar, gehört aber in einen Ablauf mit Freigabe. Die folgenden Zeilen zeigen die beiden Handgriffe, die man in einem Runbook (Modul 9.7) als Schritte beschreibt: das Löschen einer Gruppe und das Wiederherstellen aus den gelöschten Objekten innerhalb der Frist.

**Loeschen-und-Wiederherstellen.ps1**

```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All" -NoWelcome

# Loeschen (vorlaeufig, 30 Tage wiederherstellbar)
Remove-MgGroup -GroupId $gruppenId

# Geloeschte Gruppen anzeigen
Get-MgDirectoryDeletedItemAsGroup | Select-Object Id, DisplayName, DeletedDateTime

# Wiederherstellen innerhalb der Frist
Restore-MgDirectoryDeletedItem -DirectoryObjectId $gruppenId
```

Die erste Zeile löscht die Gruppe vorläufig, die zweite zeigt alle gelöschten Gruppen mit Löschzeitpunkt, die dritte stellt eine Gruppe wieder her. Danach kann es nach der Dokumentation bis zu einem oder zwei Tagen dauern, bis alle zugehörigen Dienste wieder vollständig verfügbar sind; Benutzer sollten darüber informiert werden.

### Typische Fehler und Stolperfallen.

Der schwerste Fehler ist die automatische Löschung ohne Vorwarnung und ohne Probelauf. Zweitens wird vergessen, dass Aufbewahrung und Holds ein Löschen unterlaufen können, und die erwartete Speicherersparnis bleibt aus. Drittens wird die Wiederherstellung nie getestet; im Ernstfall kennt niemand die Schritte. Viertens wird archiviert, ohne Berechtigungen und Freigaben zu überprüfen, so dass vertrauliche Inhalte unverändert extern freigegeben bleiben.

**Falsch und richtig: Loeschen**

```powershell
# FALSCH: alle inaktiven Gruppen ohne Probelauf und Protokoll loeschen
Get-MgGroup -All | Where-Object { $_.RenewedDateTime -lt (Get-Date).AddDays(-400) } |
    ForEach-Object { Remove-MgGroup -GroupId $_.Id }

# RICHTIG: erst Liste erzeugen, von Besitzern bestaetigen lassen, dann archivieren
Get-MgGroup -All -Property Id,DisplayName,RenewedDateTime |
    Where-Object { $_.RenewedDateTime -lt (Get-Date).AddDays(-400) } |
    Select-Object Id, DisplayName, RenewedDateTime |
    Export-Csv -Path .\kandidaten.csv -NoTypeInformation -Encoding UTF8
# Die CSV geht an die Verantwortlichen; erst die bestaetigte Liste wird verarbeitet.
```

Die richtige Variante trennt das Finden vom Handeln. Zwischen beiden liegt die Bestätigung durch Menschen, die den fachlichen Zusammenhang kennen.

### Praxisbezug.

Dokumentieren Sie die Löschregeln im Governance-Handbuch, und testen Sie die Wiederherstellung einmal im Jahr mit einer Testgruppe. Berichten Sie, wie viele Arbeitsbereiche archiviert, gelöscht und wiederhergestellt wurden, und wie viel Speicher dadurch frei wurde. Bei Archivierung von Websites vergleichen Sie die Kosten der Archivebene mit dem Nutzen (Modul 12.3).

## 10.8 Provisioning-Troubleshooting

Automatisierte Bereitstellung scheitert auf eine Handvoll typischer Arten, und wer sie kennt, findet die Ursache meist schnell. Die häufigste ist *zeitliche Verzögerung*: Microsoft-365-Dienste sind verteilte Systeme, bei denen neu angelegte Objekte nicht sofort überall sichtbar sind (*eventual consistency*). Die zweite sind *Berechtigungsfehler*: Die Anwendungsidentität besitzt nicht die nötigen Rechte oder die Zustimmung des Administrators fehlt. Die dritte ist *Drosselung*: Der Dienst begrenzt die Zahl der Anfragen und antwortet mit dem Statuscode 429 und einer Wartezeit. Die vierte sind *Richtlinienkonflikte*: Namensrichtlinie, Gesperrte Wörter, Erstellungsbeschränkungen oder Beschriftungsregeln lehnen den Aufruf ab. Die fünfte sind *Datenfehler*: ein unbekannter Benutzer, ein doppelter Name, ein ungültiges Zeichen.

> **Ergänzung aus der Nachrecherche**
>
> Zu den zeitlichen Verzögerungen nennt die Microsoft-Dokumentation zu Teams und Graph konkrete Werte: Ist die Gruppe jünger als 15 Minuten, kann das Erstellen des Teams mit 404 scheitern; empfohlen werden bis zu drei Wiederholungen im Abstand von zehn Sekunden und danach eine Wartezeit von mindestens 15 Minuten. Die Bereitstellung der SharePoint-Website erfolgt im Hintergrund, und ihr Abschluss lässt sich über diese Schnittstelle nicht feststellen. Mitgliedschaftsänderungen an Microsoft-365-Gruppen werden über einen Hintergrundmechanismus nach Teams synchronisiert, der typischerweise 24 Stunden oder länger braucht und nur anläuft, wenn mindestens eine Person des Teams im Desktop-Client aktiv ist; die mobilen Clients lösen ihn nicht aus. Auch die Wiederherstellung gelöschter Gruppen kann bis zu 24 beziehungsweise 48 Stunden dauern. Aus diesen Angaben folgt: Ein Fehler im Minutenbereich nach dem Anlegen ist oft keiner, sondern ein Warten.

Das Vorgehen bei Fehlern folgt einem festen Ablauf. Zuerst prüft man den genauen Fehlercode und die Meldung, nicht nur den Text im Ticket. Dann fragt man, ob das Objekt schon existiert (Gruppe da, Team fehlt?), denn davon hängt ab, ob man neu startet oder fortsetzt. Danach prüft man Rechte und Zustimmung der Anwendung, dann Richtlinien. Erst zuletzt vermutet man einen Dienstfehler und schaut in die Dienstintegrität (Modul 9.6). Die Anmelde- und Überwachungsprotokolle von Entra zeigen, welche Identität den Aufruf gesendet hat und warum er abgelehnt wurde (Modul 9.5).

Für die Automatisierung folgt daraus ein wichtiger Baustein: eine Wiederholungsfunktion, die zwischen Fehlern unterscheidet. Bei Drosselung (429) wartet sie die vom Dienst genannte Zeit, bei einem Replikationsfehler (404 kurz nach dem Anlegen) wartet sie fest, und bei allen anderen Fehlern bricht sie sofort ab, weil Wiederholen nichts ändert. Das folgende Skript zeigt eine solche Funktion mit begrenzter Zahl von Versuchen. Sie wird in den Skripten dieses Moduls anstelle der einfachen Schleife aus Lerneinheit 10.1 eingesetzt.

**Invoke-WithRetry.ps1**

```powershell
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)][scriptblock]$Aktion,
        [int]$MaxVersuche = 4,
        [int]$FesteWartezeit = 10
    )
    for ($i = 1; $i -le $MaxVersuche; $i++) {
        try {
            return & $Aktion
        } catch {
            $meldung = $_.Exception.Message
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }

            if ($i -eq $MaxVersuche) { throw "Aufgegeben nach $i Versuchen: $meldung" }

            if ($status -eq 429) {
                $warte = 30
                $ra = $_.Exception.Response.Headers | Where-Object { $_.Key -eq "Retry-After" }
                if ($ra) { $warte = [int]($ra.Value | Select-Object -First 1) }
                Write-Warning "Gedrosselt (429), warte $warte Sekunden."
                Start-Sleep -Seconds $warte
            }
            elseif ($status -eq 404 -or $meldung -match "NotFound|ResourceNotFound") {
                Write-Warning "Objekt noch nicht sichtbar (404), warte $FesteWartezeit Sekunden."
                Start-Sleep -Seconds $FesteWartezeit
            }
            else {
                throw $_
            }
        }
    }
}

# Beispiel: Team aus Gruppe erzeugen
Invoke-WithRetry -Aktion {
    Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/groups/$gruppenId/team" `
        -Body "{}" -ContentType "application/json"
}
```

Die Funktion führt den übergebenen Codeblock aus und fängt Fehler ab. Bei Drosselung liest sie den Header „Retry-After“, soweit vorhanden, und wartet entsprechend; bei „nicht gefunden“ wartet sie die feste Zeit; jeder andere Fehler wird sofort weitergereicht. Nach dem letzten Versuch gibt sie mit einer klaren Meldung auf. Die Art, wie die Statuscodes aus der Ausnahme gelesen werden, hängt von der PowerShell-Version und vom SDK ab; testen Sie die Funktion mit einem gezielt erzeugten Fehler, bevor Sie sich auf sie verlassen.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, jeden Fehler mit Wiederholen zu beantworten: Ein Berechtigungsfehler (403) verschwindet nicht durch Warten, und endlose Wiederholungen verschärfen die Drosselung. Zweitens wird bei Teilfehlern nicht aufgeräumt, und es bleiben Gruppen ohne Team zurück. Drittens fehlt die Korrelation: Im Protokoll steht nicht, zu welchem Antrag ein Fehler gehört. Viertens wird die Zustimmung des Administrators nach einer Rechteänderung der Anwendung vergessen.

**Falsch und richtig: Fehlerbehandlung**

```powershell
# FALSCH: endlos wiederholen, egal welcher Fehler
while ($true) { try { New-MgGroup @params; break } catch { Start-Sleep 5 } }

# RICHTIG: begrenzt, mit Unterscheidung und mit Antragsnummer im Fehlertext
try {
    Invoke-WithRetry -Aktion { New-MgGroup @params }
} catch {
    Write-Error "Antrag $antragsNr fehlgeschlagen: $($_.Exception.Message)"
}
```

Die richtige Variante begrenzt die Versuche, behandelt die bekannten Fälle gezielt und nennt im Fehlertext die Antragsnummer. So kann der Helpdesk den Fall dem Antrag zuordnen und dem Benutzer eine verständliche Auskunft geben.

### Praxisbezug.

Schreiben Sie für die fünf Fehlerarten je eine Runbook-Seite mit Erkennungsmerkmal, Prüfschritten und Gegenmaßnahme (Modul 9.7). Sammeln Sie die Fehler der Fabrik in einer Liste und werten Sie sie monatlich aus: Häufen sich Namensfehler, verbessert man die Eingabeprüfung, bei Rechtefehlern die Einrichtung der Anwendung.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Beschreiben Sie die fünf Stufen einer Provisioning Factory in eigenen Worten, und nennen Sie je Stufe ein Risiko, das entsteht, wenn sie fehlt.

**Aufgabe 2 (leicht).** Warum soll eine Gruppe mindestens zwei Besitzer haben? Welche Art von Konten sollte man als Besitzer nicht eintragen?

**Aufgabe 3 (leicht).** Nennen Sie die vier Stufen vom Schreibschutz bis zum endgültigen Löschen eines Arbeitsbereichs und geben Sie an, welche davon umkehrbar sind und in welchem Zeitraum.

**Aufgabe 4 (mittel).** Entwerfen Sie ein Drei-Stufen-Modell für Genehmigungen von Arbeitsbereichen. Legen Sie die Regeln für die Stufen fest und begründen Sie, warum die Stufe nicht von den Antragstellern selbst gewählt werden darf.

**Aufgabe 5 (mittel).** Schreiben Sie eine PowerShell-Funktion, die einen Freitext in einen Mail-Nickname umwandelt (nur Kleinbuchstaben, Ziffern und Bindestriche, Umlaute ersetzt, maximal 40 Zeichen). Testen Sie sie mit mindestens drei schwierigen Eingaben.

**Aufgabe 6 (mittel).** Erklären Sie anhand der Ablaufrichtlinie für Microsoft-365-Gruppen, warum man sie zunächst nur für ausgewählte Gruppen einschaltet. Welche Benachrichtigungen erhalten die Besitzer, und was passiert mit einer nicht verlängerten Gruppe?

**Aufgabe 7 (schwer).** Erweitern Sie das Skript zur Prüfung des Metadatenstandards so, dass es zusätzlich Gruppen findet, die keinen Besitzer mit aktivem Konto haben, und eine Liste je Abteilung erzeugt, damit die Abteilungsleitung die Fälle bereinigen kann.

**Aufgabe 8 (schwer).** Ein Skript zum Anlegen von Teams scheitert bei etwa jedem fünften Antrag mit dem Fehler 404 direkt nach dem Anlegen der Gruppe, an manchen Tagen zusätzlich mit 429. Analysieren Sie die Ursachen, und entwerfen Sie eine Lösung inklusive Protokollierung und Aufräumregel für halbfertige Gruppen.

## Lösungen

**Lösung 1.** Die Stufen sind Antrag, Genehmigung, technische Anlage, Konfiguration nach Standard und Registrierung. Fehlt der Antrag, gibt es keine Pflichtangaben; fehlt die Genehmigung, entstehen riskante Arbeitsbereiche unkontrolliert; fehlt die automatische Anlage, entstehen Fehler und Wartezeiten; fehlt die Konfiguration, sind die Arbeitsbereiche uneinheitlich; fehlt die Registrierung, kennt später niemand den Bestand und der Lebenslauf lässt sich nicht steuern.

**Lösung 2.** Zwei Besitzer sichern ab, dass bei Ausscheiden oder Abwesenheit einer Person der Arbeitsbereich verwaltbar bleibt. Dienstkonten sind als Besitzer ungeeignet, weil sie keine verantwortliche Person sind, nicht auf Benachrichtigungen reagieren und das Konto selbst ein Angriffsziel ist.

**Lösung 3.** Schreibschutz (umkehrbar durch Administratoren), Archiv (umkehrbar durch Reaktivierung), vorläufiges Löschen (30 Tage lang wiederherstellbar, die Wiederherstellung kann bis zu ein bis zwei Tage dauern) und endgültiges Löschen (nicht umkehrbar). Ob Aufbewahrungspflichten das Löschen von Inhalten verhindern, ist gesondert zu prüfen.

**Lösung 4.** Ein Beispiel: Stufe 1 (automatisch): interner Arbeitsbereich, Pflichtangaben vollständig, keine Gäste, Vertraulichkeit „Intern“. Stufe 2 (Führungskraft): sehr großer interner Arbeitsbereich oder abweichende Vorlage. Stufe 3 (Führungskraft plus Datenschutz oder Informationssicherheit): Gäste, „Vertraulich“ oder „Streng vertraulich“, besondere Datenkategorien. Die Stufe darf nicht von den Antragstellern gewählt werden, weil sie ein Interesse an schneller Freigabe haben; sie ergibt sich aus den Angaben nach festen Regeln, die geprüft werden.

**Lösung 5.** Ein Lösungsvorschlag:

```powershell
function ConvertTo-Nickname {
    param([Parameter(Mandatory)][string]$Text, [int]$Max = 40)
    $t = $Text.ToLower()
    $t = $t -replace 'ä','ae' -replace 'ö','oe' -replace 'ü','ue' -replace 'ß','ss'
    $t = ($t -replace '[^a-z0-9]+','-').Trim('-')
    if ($t.Length -gt $Max) { $t = $t.Substring(0,$Max).TrimEnd('-') }
    if (-not $t) { throw "Kein gueltiges Zeichen im Text." }
    $t
}
ConvertTo-Nickname "Größe & Übung (2026)!"        # groesse-uebung-2026
ConvertTo-Nickname "   --Test--   "                 # test
ConvertTo-Nickname ("a" * 100)                      # 40 mal a
```

Die Funktion ersetzt Umlaute, wandelt alle anderen Zeichen in Bindestriche um, entfernt Randbindestriche, kürzt und meldet einen Fehler, wenn nichts übrig bleibt. Die drei Aufrufe prüfen Sonderzeichen, Randfälle und die Längenbegrenzung.

**Lösung 6.** Die Richtlinie kennt keinen Testmodus und wirkt auf alle erfassten Gruppen; eine zu kurze Dauer oder fehlende Besitzer führen zu Löschungen. Mit ausgewählten Gruppen (bis zu 500) beobachtet man Wirkung und Benachrichtigungen ohne großes Risiko. Besitzer erhalten Meldungen 30, 15 und 1 Tag vor dem Ablauf, soweit die Gruppe nicht wegen Aktivität automatisch verlängert wird. Eine nicht verlängerte Gruppe wird einen Tag nach dem Ablaufdatum gelöscht und ist danach 30 Tage lang wiederherstellbar.

**Lösung 7.** Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName
$befunde = foreach ($g in $gruppen) {
    $aktiv = @(Get-MgGroupOwner -GroupId $g.Id | ForEach-Object {
        $u = Get-MgUser -UserId $_.Id -Property AccountEnabled,Department -ErrorAction SilentlyContinue
        if ($u -and $u.AccountEnabled) { $u }
    })
    if ($aktiv.Count -eq 0) {
        $abt = "unbekannt"
        $m = @(Get-MgGroupMember -GroupId $g.Id -Top 1)
        if ($m) {
            $mu = Get-MgUser -UserId $m[0].Id -Property Department -ErrorAction SilentlyContinue
            if ($mu.Department) { $abt = $mu.Department }
        }
        [pscustomobject]@{ Abteilung = $abt; Gruppe = $g.DisplayName; Id = $g.Id }
    }
}
$befunde | Group-Object Abteilung | ForEach-Object {
    $_.Group | Export-Csv -Path (".\ohne-aktiven-besitzer-{0}.csv" -f $_.Name) -NoTypeInformation -Encoding UTF8
}
```

Das Skript prüft für jede Gruppe, ob mindestens ein Besitzer ein aktives Konto hat. Für Gruppen ohne aktiven Besitzer schätzt es die Abteilung aus dem ersten Mitglied und erzeugt je Abteilung eine Datei. Die Abteilungsermittlung über das erste Mitglied ist eine Näherung; besser ist die Abteilung im Bestandsverzeichnis. Dateinamen mit Sonderzeichen in Abteilungsnamen sollten bereinigt werden.

**Lösung 8.** Das 404 direkt nach dem Anlegen ist die Replikationsverzögerung: Das Team wird zu früh erzeugt. Die Dokumentation empfiehlt bis zu drei Wiederholungen im Abstand von zehn Sekunden und bei weiterem Misserfolg eine Wartezeit von mindestens 15 Minuten. Das 429 ist Drosselung durch zu viele Anfragen, besonders bei Stapelläufen; die Lösung ist, die Wartezeit aus dem Header zu beachten, Anfragen zu bündeln und Läufe zu verteilen. Die Lösung: eine Wiederholungsfunktion mit Unterscheidung nach Statuscode (siehe Beispiel in 10.8), eine Pause zwischen Anträgen, ein Protokoll je Antrag mit Gruppen-ID und Fehler, und eine Aufräumregel: Gruppen ohne Team, die älter als eine Stunde sind und deren Antrag als fehlgeschlagen gilt, werden gemeldet und nach Prüfung gelöscht oder fortgesetzt. Automatisches Löschen sollte nur für selbst angelegte, noch leere Gruppen erfolgen.
