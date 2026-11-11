# Modul 11 - Automation, Graph API und Policy-as-Code

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 10 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8,75 Stunden (3 × 1,25 plus 5 × 1). Die Differenz von 1,25 Stunden wird hier nicht als eigene Lerneinheit ausgewiesen, sondern als Übungs- und Vertiefungszeit zu den praktischen Beispielen verstanden; als Richtwert für den Umfang wurde der höhere Wert (10 Stunden) verwendet.  
**Priorität:** 2 (mittlere Priorität)

| **Nr.** | **Lerneinheit**           | **Dauer (h)** | **Prio** |
|:--------|:--------------------------|--------------:|---------:|
| 11.1    | Microsoft Graph           |          1,25 |        1 |
| 11.2    | PowerShell Automation     |          1,25 |        1 |
| 11.3    | Configuration Export      |             1 |        1 |
| 11.4    | Policy-as-Code            |             1 |        1 |
| 11.5    | Drift Detection           |             1 |        1 |
| 11.6    | ITSM Integration          |             1 |        2 |
| 11.7    | Automation Security       |             1 |        2 |
| 11.8    | Rollback                  |          1,25 |        2 |
|         | **Summe laut Details**    |      **8,75** |          |
|         | **Dauer laut Modulblatt** |        **10** |          |

> **Merke: Automatisierung verstärkt Fehler**
>
> Ein Skript, das 5.000 Postfächer oder Gruppen ändert, macht einen Fehler 5.000-mal. Alle Beispiele dieses Moduls sind deshalb so aufgebaut, dass sie zuerst lesen, dann (auf Wunsch) ändern und alles protokollieren. Sie folgen den Mustern der Microsoft-Dokumentation, wurden aber nicht gegen einen echten Tenant ausgeführt. Testen Sie jede Änderung zuerst in einem Testtenant und mit dem Schalter `-WhatIf`.

Die Module 1 bis 10 beschreiben, was in einem gut geführten Microsoft-365-Tenant eingestellt sein soll. Dieses Modul beantwortet die Frage, wie man das dauerhaft sicherstellt, wenn Hunderte Einstellungen, mehrere Administratoren und laufende Microsoft-Änderungen zusammenkommen. Die Antwort ist *Konfiguration als Code*: Man erfasst den Ist-Zustand automatisch, beschreibt den Soll-Zustand in Dateien, vergleicht beides regelmäßig, meldet Abweichungen an das Ticketsystem und kann Änderungen kontrolliert zurücknehmen. Das Modul baut auf den Skripten aus den Modulen 5 und 10 auf und liefert deren Betriebsgrundlage.

## 11.1 Microsoft Graph

*Microsoft Graph* ist die einheitliche Programmierschnittstelle (API) für Microsoft 365: Benutzer, Gruppen, Teams, Postfächer, Dateien, Berichte, Sicherheits- und Compliance-Daten sind über denselben Zugang erreichbar. Eine API ist eine definierte Art, wie Programme miteinander sprechen; hier geschieht das über Webadressen und das Protokoll HTTP. Wer eine Gruppe lesen will, sendet eine GET-Anfrage an die Adresse der Gruppe, wer sie anlegen will, eine POST-Anfrage mit den Daten im JSON-Format. Alle Verwaltungsprogramme von Microsoft nutzen im Kern dieselbe Schnittstelle, auch die Administrationsportale und das PowerShell-Modul, das in diesem Kurs verwendet wird.

Drei Grundentscheidungen bestimmen jede Automatisierung. Die erste ist die Version: Die stabile Version `v1.0` ist für den Produktivbetrieb gedacht, die Version `beta` enthält Neuerungen, die sich ändern können. Die zweite ist die Art der Anmeldung: Bei *delegiertem Zugriff* handelt das Programm im Namen einer angemeldeten Person und hat höchstens deren Rechte, bei *Anwendungszugriff* (app-only) handelt es mit eigener Identität ohne Benutzer, was für geplante Aufgaben nötig ist. Die dritte ist die Berechtigung: Jede Anfrage braucht passende Bereiche (Scopes), und für Anwendungszugriff muss ein Administrator sie ausdrücklich genehmigen.

> **Ergänzung aus der Nachrecherche**
>
> Zur Anmeldung nennt die Dokumentation zum Graph-PowerShell-SDK zwei Arten: delegiert und app-only. Für app-only-Zugriff mit Zertifikat lädt `Connect-MgGraph` das Zertifikat aus dem Speicher „Cert:\CurrentUser\My“ oder „Cert:\LocalMachine\My“, wenn man den Fingerabdruck (`-CertificateThumbprint`) oder den Namen (`-CertificateName`) angibt. Mit `Get-MgContext` lässt sich prüfen, ob der Authentifizierungstyp `AppOnly` ist. Für Clientgeheimnisse empfiehlt die Dokumentation PowerShell 7 oder höher; daneben wird die Anmeldung mit einer verwalteten Identität beschrieben. Zum Umgang mit Antworten nennt die Dokumentation zu bewährten Verfahren: 403 bei fehlender Berechtigung des angemeldeten Benutzers, 404 bei nicht vorhandenen oder noch nicht bereitgestellten Ressourcen (gelöschte Benutzer, Gruppen und Anwendungen können bis zu 30 Tage wiederherstellbar sein), 429 bei Drosselung mit dem Header `Retry-After`, und 503 bei überlasteten Diensten.

Zwei technische Eigenschaften von Graph sind für jedes Skript wichtig. Erstens liefert Graph große Listen seitenweise. Nach der Dokumentation gibt zum Beispiel die Abfrage der Benutzer standardmäßig 100 Einträge je Seite zurück, und solange es weitere Seiten gibt, enthält die Antwort die Eigenschaft `@odata.nextLink` mit der vollständigen Adresse der nächsten Seite. Man muss diese Adresse unverändert aufrufen, bis sie nicht mehr erscheint; man darf den darin enthaltenen Fortsetzungswert nicht herauslösen. Zweitens begrenzt Graph die Zahl der Anfragen. Wer zu viele sendet, bekommt den Status 429 und im Header `Retry-After` die Wartezeit in Sekunden. Die Dokumentation rät, die Zahl der Operationen je Anfrage und die Häufigkeit zu verringern, sofortige Wiederholungen zu vermeiden, weil sie auf das Limit zählen, und stattdessen die genannte Zeit abzuwarten. Bei vielen kleinen Abfragen kann man bis zu 20 Anfragen in einer einzigen Stapelanfrage (`$batch`) bündeln; jede wird einzeln gegen die Limits gerechnet, und eine gedrosselte Anfrage innerhalb eines Stapels wird vom SDK nicht automatisch wiederholt.

Das folgende Skript kapselt das Seitenlesen in einer Funktion und nutzt sie, um alle Microsoft-365-Gruppen mit ihrer Erstellungszeit zu holen. Die Funktion folgt den Verweisen auf die nächste Seite und sammelt die Ergebnisse. Außerdem enthält das Beispiel eine kleine Stapelanfrage, die zu mehreren Gruppen gleichzeitig die Besitzer abfragt. Beides sind Bausteine, die in den übrigen Lerneinheiten dieses Moduls wiederkehren.

**Graph-Bausteine.ps1**

```powershell
function Get-GraphAll {
    param([Parameter(Mandatory)][string]$Uri)
    $ergebnis = New-Object System.Collections.Generic.List[object]
    while ($Uri) {
        $antwort = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($antwort.value) { $ergebnis.AddRange([object[]]$antwort.value) }
        $Uri = $antwort.'@odata.nextLink'
    }
    $ergebnis
}

function Get-GraphBatch {
    param([Parameter(Mandatory)][string[]]$Pfade)   # relative Pfade, z. B. /groups/<id>/owners
    $ergebnis = @{}
    for ($i = 0; $i -lt $Pfade.Count; $i += 20) {
        $teil = $Pfade[$i..([math]::Min($i + 19, $Pfade.Count - 1))]
        $anfragen = for ($j = 0; $j -lt $teil.Count; $j++) {
            @{ id = [string]($i + $j); method = "GET"; url = $teil[$j] }
        }
        $body = @{ requests = @($anfragen) } | ConvertTo-Json -Depth 5
        $antwort = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/`$batch" `
                       -Body $body -ContentType "application/json"
        foreach ($a in $antwort.responses) {
            $ergebnis[$Pfade[[int]$a.id]] = $a
        }
    }
    $ergebnis
}

Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
$gruppen = Get-GraphAll -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=groupTypes/any(c:c eq 'Unified')&`$select=id,displayName,createdDateTime&`$top=100"
"{0} Gruppen gelesen." -f $gruppen.Count

$pfade = $gruppen | Select-Object -First 40 | ForEach-Object { "/groups/$($_.id)/owners?`$select=id" }
$besitzer = Get-GraphBatch -Pfade $pfade
$gedrosselt = @($besitzer.Values | Where-Object { $_.status -eq 429 }).Count
"{0} Stapelantworten, davon {1} gedrosselt." -f $besitzer.Count, $gedrosselt
```

Die erste Funktion ruft die Adresse ab, hängt die Einträge an eine Liste an und liest anschließend die Adresse der nächsten Seite aus der Antwort, bis keine mehr kommt. Die zweite Funktion teilt eine Liste relativer Pfade in Gruppen von höchstens 20 und sendet jede Gruppe als Stapel. Sie merkt sich die Antwort zu jedem Pfad über die laufende Nummer, die als Kennung mitgeschickt wird. Im Hauptteil verbindet sich das Skript mit dem Leserecht für Gruppen, liest alle Microsoft-365-Gruppen und fragt für die ersten vierzig die Besitzer in zwei Stapeln ab. Die Auswertung am Ende zählt die Antworten mit Status 429, damit eine Drosselung nicht stillschweigend übergangen wird. In der Praxis würde man diese Fälle in einem zweiten Durchgang nach der längsten genannten Wartezeit wiederholen.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, nur die erste Seite zu lesen und zu glauben, es seien alle Daten: Der Bericht „Wir haben 100 Gruppen“ ist dann falsch, ohne dass ein Fehler auftritt. Zweitens werden zu weite Berechtigungen angefordert, weil sie im Beispiel standen; für Lesezugriffe genügen meist `.Read.All`-Bereiche. Drittens wird die Betaversion produktiv eingesetzt und bricht nach einer Änderung. Viertens werden Anfragen in enger Schleife und ohne Pause gesendet und lösen die Drosselung aus.

**Falsch und richtig: Seiten und Felder**

```powershell
# FALSCH: nur erste Seite, alle Felder, Betaendpunkt
$g = (Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/groups").value

# RICHTIG: alle Seiten, nur benoetigte Felder, stabile Version
$g = Get-GraphAll -Uri "https://graph.microsoft.com/v1.0/groups?`$select=id,displayName&`$top=100"
```

Die richtige Fassung liest durchgängig, fordert nur die benötigten Felder an (was Antwortgröße und Last verringert) und verwendet die stabile Version. Wer nur Änderungen sucht, sollte nicht ständig alles neu lesen, sondern die Änderungsverfolgung (Delta-Abfragen) oder Benachrichtigungen nutzen, wie es die Dokumentation zur Drosselung empfiehlt.

### Praxisbezug.

In der Praxis beginnt man mit dem PowerShell-SDK, weil es Anmeldung, Wiederholungen und Seitenlesen weitgehend selbst erledigt, und greift mit `Invoke-MgGraphRequest` zu direkten Aufrufen, wo es kein passendes Cmdlet gibt. Legen Sie eine kleine gemeinsame Bibliothek mit den Bausteinen aus diesem Abschnitt an, damit alle Skripte des Teams dieselben Muster verwenden.

## 11.2 PowerShell Automation

*PowerShell* ist die Skriptsprache, mit der Microsoft-365-Verwaltung automatisiert wird. Ein Skript ist dabei mehr als eine Folge von Befehlen: Ein betriebstaugliches Automatisierungsskript hat Parameter, prüft seine Eingaben, protokolliert, kann gefahrlos zur Probe laufen, behandelt Fehler und lässt sich wiederholt ausführen, ohne Schaden anzurichten. Diesen Gedanken fasst man als *Idempotenz* zusammen: Ein zweiter Lauf soll dasselbe Ergebnis liefern wie der erste und nichts doppelt anlegen. Ein Skript, das diese Eigenschaften nicht hat, ist ein Werkzeug für den einmaligen Gebrauch, kein Teil des Betriebs.

Die Sprache bietet für diese Eigenschaften eingebaute Mittel. Mit `[CmdletBinding(SupportsShouldProcess)]` erhält eine Funktion die Schalter `-WhatIf` und `-Confirm`: Mit `-WhatIf` zeigt sie nur an, was sie tun würde. Parameter mit Typ und Prüfregeln (`ValidateSet`, `ValidateRange`) weisen falsche Eingaben ab. `try/catch` mit `-ErrorAction Stop` macht Fehler abfangbar. `Start-Transcript` oder eigene Protokollzeilen halten fest, was geschah. Skripte, die unbeaufsichtigt laufen, brauchen außerdem eine Anmeldung ohne Benutzer (Lerneinheit 11.7) und einen Ausführungsort, etwa ein Azure-Automation-Runbook oder einen geplanten Pipelinelauf (Modul 9.7).

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt für unbeaufsichtigte Skripte die Anmeldung mit Anwendungszertifikat, mit Clientgeheimnis und mit verwalteter Identität; für Skripte, die ohne Benutzer laufen, ist app-only-Zugriff der vorgesehene Weg. Die Aussagen zu Schalter `-WhatIf`, `ShouldProcess` und Protokollierung beruhen auf allgemeinem Fachwissen zu PowerShell und wurden hier nicht aus einer Quelle abgerufen. Die Wahl des Ausführungsorts (Azure Automation, GitHub Actions, Azure DevOps, Aufgabenplanung) hängt von der Umgebung ab; entscheidend ist, dass Protokolle zentral gespeichert werden und die Identität des Skripts minimal berechtigt ist.

Das folgende Skript zeigt eine Vorlage für ein betriebstaugliches Automatisierungsskript. Es verlangt eine Beschreibung (Beschreibung ist ein Mindeststandard aus Modul 10.5), setzt sie auf Gruppen, bei denen sie fehlt, und unterstützt den Probelauf. Jede Änderung wird in eine Protokolldatei geschrieben, und ein zweiter Lauf lässt bereits korrigierte Gruppen aus. Das Beispiel ist bewusst harmlos gewählt, damit man die Struktur lernt, die man auf gefährlichere Aufgaben überträgt.

**Set-MissingGroupDescription.ps1**

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Standardtext,
    [string]$Protokoll = ".\beschreibung-protokoll.csv"
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,Description
$zeilen = foreach ($g in $gruppen) {
    if (-not [string]::IsNullOrWhiteSpace($g.Description)) { continue }   # idempotent: schon erledigt

    $text = "$Standardtext ($($g.DisplayName))"
    $status = "geplant"
    if ($PSCmdlet.ShouldProcess($g.DisplayName, "Beschreibung setzen")) {
        try {
            Update-MgGroup -GroupId $g.Id -Description $text
            $status = "gesetzt"
        } catch {
            $status = "Fehler: " + $_.Exception.Message
        }
    }
    [pscustomobject]@{ Zeit = (Get-Date -Format s); GruppenId = $g.Id; Name = $g.DisplayName; Status = $status }
}

if ($zeilen) { $zeilen | Export-Csv -Path $Protokoll -NoTypeInformation -Encoding UTF8 -Append }
"{0} Gruppen bearbeitet." -f @($zeilen).Count
```

Die Zeile mit `$ErrorActionPreference = "Stop"` macht aus jedem Fehler einen abfangbaren Abbruch, damit nichts unbemerkt scheitert. Die Bedingung am Anfang der Schleife überspringt Gruppen, die bereits eine Beschreibung haben, und macht das Skript damit wiederholbar. Der Aufruf von `ShouldProcess` ist der Kern der Probelauf-Fähigkeit: Mit `-WhatIf` liefert er falsch zurück, und die Änderung wird nicht ausgeführt, das Protokoll zeigt aber den Status „geplant“. Fehler bei einzelnen Gruppen werden im Protokoll vermerkt und stoppen nicht den ganzen Lauf. Am Ende steht die Zahl der bearbeiteten Gruppen.

### Typische Fehler und Stolperfallen.

Der verbreitetste Fehler ist ein Skript ohne Probelauf, das gleich scharf ändert. Zweitens fehlt die Idempotenz, und ein zweiter Lauf erzeugt Duplikate oder Fehler. Drittens werden Zugangsdaten im Skript gespeichert, wo sie in der Versionsverwaltung landen. Viertens werden Fehler mit `-ErrorAction SilentlyContinue` unterdrückt und tauchen erst als Folgeprobleme auf. Fünftens fehlt ein Protokoll, so dass man nach einem Vorfall nicht weiß, was geändert wurde.

**Falsch und richtig: Aenderungen absichern**

```powershell
# FALSCH: direkt aendern, Fehler unterdruecken, kein Protokoll
Get-MgGroup -All | ForEach-Object { Update-MgGroup -GroupId $_.Id -Description "x" -ErrorAction SilentlyContinue }

# RICHTIG: WhatIf-faehig, Fehler sichtbar, Ergebnis protokolliert
.\Set-MissingGroupDescription.ps1 -Standardtext "Bitte Zweck ergaenzen" -WhatIf
# Ergebnis im Protokoll pruefen, dann erst ohne -WhatIf ausfuehren
```

Der Probelauf zeigt, welche Gruppen betroffen wären; erst nach Sichtung des Protokolls läuft das Skript scharf. Dieses Muster („erst zeigen, dann ändern“) ist die wichtigste Gewohnheit der Automatisierung.

### Praxisbezug.

Legen Sie eine Skriptvorlage mit diesem Aufbau im Team ab, und verlangen Sie in der Codeprüfung (Review), dass jedes Skript Probelauf, Protokoll und Idempotenz hat. Skripte, die Daten löschen oder Rechte entziehen, erhalten zusätzlich eine Freigabe durch eine zweite Person (Lerneinheit 11.6).

## 11.3 Configuration Export

Ein *Konfigurationsexport* hält den Ist-Zustand wichtiger Einstellungen in Dateien fest: Richtlinien für bedingten Zugriff, Nachrichtenflussregeln, Aufbewahrungsrichtlinien, Namensrichtlinien, Teams-Richtlinien und vieles mehr. Er dient drei Zwecken. Er ist ein Nachweis für Audits, weil man zeigen kann, wie ein Tenant an einem bestimmten Tag eingestellt war. Er ist die Grundlage für den Vergleich mit dem Soll-Zustand (Lerneinheit 11.5). Und er ist eine Rückfallebene, weil man eine versehentlich geänderte Einstellung anhand der letzten Sicherung nachvollziehen kann (Lerneinheit 11.8).

Es gibt zwei Wege zum Export. Der erste sind eigene Skripte, die einzelne Einstellungen über Graph oder PowerShell lesen und als JSON-Dateien ablegen. Er ist flexibel, deckt aber nur ab, was man selbst programmiert. Der zweite ist der Dienst für Tenant-Konfigurationsverwaltung (Tenant Configuration Management), der Momentaufnahmen (Snapshots) über viele Arbeitslasten hinweg erzeugt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Tenant Configuration Management APIs in Microsoft Graph beschreibt Momentaufnahmen als Möglichkeit, die aktuelle Konfiguration mehrerer Arbeitslasten (Defender, Entra, Exchange Online, Intune, Purview, Teams) auszulesen. Für Momentaufnahmen gelten laut Dokumentation folgende Grenzen: höchstens 20.000 extrahierte Ressourcen je Tenant und Monat insgesamt, höchstens 12 sichtbare Snapshot-Jobs (für weitere müssen vorhandene gelöscht werden), und jede Momentaufnahme wird nach höchstens sieben Tagen automatisch gelöscht. Die Funktion setzt voraus, dass die Dienstidentität der Konfigurationsverwaltung zum Tenant hinzugefügt und mit Leserechten für die jeweiligen Ressourcentypen ausgestattet wird; der angemeldete Benutzer braucht eine privilegierte Entra-Rolle. Für Momentaufnahmen sind nach der Anleitung Lizenzen für „Tenant Governance Basic“ oder „Premium“ vorgesehen. Wegen der kurzen Aufbewahrung von sieben Tagen müssen Momentaufnahmen, die man dauerhaft braucht, in ein eigenes Archiv (etwa ein Git-Repository) übernommen werden. Prüfen Sie Lizenzen, Verfügbarkeit und Kontingente vor der Planung in der aktuellen Dokumentation.

Aus der kurzen Aufbewahrungsfrist der Momentaufnahmen folgt eine Gestaltungsregel: Der Export muss in ein eigenes, dauerhaftes Archiv wandern, am besten in ein Git-Repository, in dem jede Änderung als Unterschied zwischen zwei Ständen sichtbar ist. Damit das funktioniert, müssen die Dateien *stabil* sein: Felder, die sich bei jedem Lauf ändern (Zeitstempel der letzten Abfrage, laufende Zähler), werden entfernt, und die Reihenfolge der Einträge wird festgelegt. Sonst meldet das Versionsverwaltungssystem bei jedem Lauf tausend scheinbare Änderungen.

Das folgende Skript exportiert drei Einstellungsbereiche als JSON: die Richtlinien für bedingten Zugriff über Graph, die Nachrichtenflussregeln aus Exchange Online und die Gruppenlebenszyklus-Richtlinie. Es entfernt flüchtige Felder, sortiert nach Namen und schreibt je Bereich eine Datei in einen Ordner mit dem Datum. Der Ordner wird danach in das Repository übernommen.

**Export-TenantConfig.ps1**

```powershell
param([string]$Ziel = ".\config-export")

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path $Ziel -Force | Out-Null

function Save-Json {
    param($Objekt, [string]$Datei, [string[]]$Fluechtig = @())
    $json = $Objekt | ConvertTo-Json -Depth 20
    $kopie = $json | ConvertFrom-Json
    foreach ($e in @($kopie)) {
        foreach ($f in $Fluechtig) { if ($e.PSObject.Properties[$f]) { $e.PSObject.Properties.Remove($f) } }
    }
    $kopie | ConvertTo-Json -Depth 20 | Set-Content -Path (Join-Path $Ziel $Datei) -Encoding UTF8
}

Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
$ca = Get-MgIdentityConditionalAccessPolicy -All | Sort-Object DisplayName
Save-Json -Objekt $ca -Datei "bedingter-zugriff.json" -Fluechtig @("ModifiedDateTime")

Connect-ExchangeOnline -ShowBanner:$false
$regeln = Get-TransportRule | Sort-Object Name |
    Select-Object Name, Priority, State, Mode, Comments, Description
Save-Json -Objekt $regeln -Datei "transportregeln.json"

Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome
$lebenslauf = Get-MgGroupLifecyclePolicy | Select-Object GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails
Save-Json -Objekt $lebenslauf -Datei "gruppen-ablauf.json"

"Export abgeschlossen: $((Get-ChildItem $Ziel).Count) Dateien in $Ziel"
```

Die Hilfsfunktion `Save-Json` wandelt Objekte in JSON, entfernt die als flüchtig benannten Felder und schreibt die Datei. Der Export liest zuerst die Richtlinien für bedingten Zugriff mit dem Leserecht für Richtlinien und sortiert sie nach Namen, damit die Reihenfolge stabil ist. Danach folgen die Transportregeln aus Exchange und die Ablaufrichtlinie der Gruppen. Für jede Quelle wird nur eine Auswahl von Feldern gespeichert, was die Dateien klein und lesbar hält. In einer vollständigen Fassung würde man die Anmeldung als Anwendung durchführen (Lerneinheit 11.7) und den Export in einem festen Takt ausführen.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist, den Export ohne Zugriffsschutz abzulegen: Konfigurationsdateien enthalten Namen, Ausnahmen und Adressen und gehören in ein Repository mit begrenztem Zugriff. Zweitens enthalten die Dateien flüchtige Felder, und jede Differenz zeigt Rauschen. Drittens wird nur exportiert, wenn jemand daran denkt. Viertens verlässt man sich auf die Momentaufnahmen des Dienstes, obwohl sie nach sieben Tagen verschwinden.

**Falsch und richtig: Stabiler Export**

```powershell
# FALSCH: ganzes Objekt mit Zeitstempeln, Reihenfolge zufaellig
Get-TransportRule | ConvertTo-Json -Depth 5 | Set-Content regeln.json

# RICHTIG: sortiert, nur relevante Felder, in festes Verzeichnis
Get-TransportRule | Sort-Object Name | Select-Object Name, Priority, State, Mode, Comments |
    ConvertTo-Json -Depth 5 | Set-Content -Path .\config-export\transportregeln.json -Encoding UTF8
```

Mit sortierter Ausgabe und festem Feldsatz liefert zweimaliger Export ohne Änderung zwei identische Dateien. Erst dann zeigt eine Differenz tatsächlich eine Änderung an.

### Praxisbezug.

Planen Sie den Export als nächtliche Aufgabe, die das Ergebnis in ein Repository überträgt und dabei die Änderungen seit dem Vortag als Zusammenfassung ausgibt. Ein solches Änderungsprotokoll ist im Alltag wertvoller als jedes Dokument, weil es zeigt, wer wann was verändert hat (in Verbindung mit dem Auditprotokoll, Modul 7.1).

## 11.4 Policy-as-Code

*Policy-as-Code* bedeutet, dass die Regeln der Governance nicht nur in Dokumenten und im Kopf der Administratoren stehen, sondern als Dateien vorliegen, die Programme lesen, prüfen und durchsetzen können. Ein Governance-Handbuch sagt etwa: „Jede Gruppe hat mindestens zwei Besitzer, Namen folgen dem Muster PRJ-ABT-Text, die Lebensdauer beträgt 365 Tage.“ Als Code steht dieselbe Aussage in einer Datei (`standards.json`), die das Bereitstellungsskript aus Modul 10, das Prüfskript aus Modul 10.5 und der Drift-Vergleich aus Lerneinheit 11.5 alle gemeinsam lesen. Ändert sich die Regel, ändert man sie an einer einzigen Stelle.

Der eigentliche Gewinn liegt im Änderungsprozess. Liegen die Standards in einem Versionsverwaltungssystem wie Git, ist jede Änderung ein nachvollziehbarer Vorgang: Wer hat sie vorgeschlagen, wer hat sie geprüft, wann trat sie in Kraft? Änderungen laufen über einen Änderungsvorschlag (Pull Request), den eine zweite Person freigibt (Vier-Augen-Prinzip), und automatische Prüfungen stellen sicher, dass die Datei formal gültig ist, bevor sie wirksam wird. Das ersetzt die Situation, in der ein Administrator „mal eben“ im Portal eine Richtlinie ändert und niemand es bemerkt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Tenant-Konfigurationsverwaltung (Tenant Governance) beschreibt das Konzept als „Configuration as Code“: Eine *Baseline* ist die JSON-Darstellung der gewünschten Konfiguration und besteht aus einer Liste von Ressourcen mit den Soll-Werten ihrer Eigenschaften. Eine Ressource ist ein Konfigurationsbaustein; als Beispiel nennt die Dokumentation die Richtlinie für bedingten Zugriff mit dem Ressourcentyp `microsoft.entra.conditionalaccesspolicy` und Eigenschaften wie `ExcludedUsers`, `IncludedGroups` und `State`. Eine Baseline kann mehrere Instanzen desselben Typs enthalten, etwa mehrere Exchange-Transportregeln. Nach der Anleitung darf eine Baseline bis zu 200 Ressourceninstanzen umfassen, der Tageswert über alle Monitore liegt bei 800. Zum Einstieg kann man eine Baseline aus einer Momentaufnahme erzeugen und dann auf den Soll-Zustand bearbeiten. Wichtig ist die Abgrenzung: Die Dokumentation zur Architektur mit Microsoft365DSC (einem quelloffenen Projekt der Community) hält fest, dass die offiziellen APIs derzeit Momentaufnahmen und Drift-Erkennung unterstützen, aber keine Bereitstellung oder Korrektur; wer Einstellungen automatisch durchsetzen will, braucht dafür eigene Skripte oder andere Werkzeuge.

Für den Kurs ist daher ein zweistufiger Ansatz sinnvoll. Die *Governance-Standards* (Namensmuster, Mindestzahl Besitzer, Lebensdauer, Pflichtmetadaten) liegen in einer eigenen, einfachen Datei, die Ihre Skripte lesen. Die *Konfigurationsbaselines* des Dienstes beschreiben technische Einstellungen und dienen der Überwachung. Beide gehören ins selbe Repository, und beide werden bei Änderungen geprüft.

Das folgende Beispiel zeigt zunächst eine Standarddatei und anschließend ein Prüfskript, das sie auf formale Gültigkeit testet. Das Prüfskript ist der Baustein, der in einem Änderungsvorschlag automatisch läuft: Es prüft, ob Pflichtschlüssel vorhanden sind, ob die Werte sinnvolle Grenzen haben und ob das Namensmuster ein gültiger regulärer Ausdruck ist. Eine fehlerhafte Datei darf nie in den Betrieb gelangen, weil sonst alle Skripte, die sie lesen, falsch arbeiten.

**standards.json**

```json
{
  "version": "1.3.0",
  "gueltigAb": "2026-11-01",
  "gruppen": {
    "namensmuster": "^(PRJ|ABT|GRM|KND)-[A-Z]{2,5}-[a-z0-9-]{3,40}$",
    "mindestBesitzer": 2,
    "lebensdauerTage": 365,
    "pflichtMetadaten": ["Zweck", "Abteilung", "Vertraulichkeit"]
  },
  "freigabestufen": {
    "gaeste": 3,
    "vertraulich": 3,
    "grosserBereichAbMitgliedern": 200
  }
}
```

Die Datei trägt eine Versionsnummer und ein Datum, ab dem sie gilt, damit Änderungen nachvollziehbar sind. Sie enthält genau die Werte, die in den Skripten sonst im Code stünden: das Namensmuster als regulären Ausdruck, die Mindestzahl der Besitzer, die Lebensdauer und die Pflichtmetadaten. Die Stufen der Freigabe stammen aus Modul 10.2. Das Prüfskript liest diese Datei und prüft sie.

**Test-StandardsFile.ps1**

```powershell
param([Parameter(Mandatory)][string]$Datei)

$fehler = New-Object System.Collections.Generic.List[string]
try {
    $s = Get-Content -Path $Datei -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Datei ist kein gueltiges JSON: $($_.Exception.Message)"; exit 1
}

if ($s.version -notmatch '^\d+\.\d+\.\d+$') { $fehler.Add("version muss Form x.y.z haben") }
$d = [datetime]::MinValue
if (-not [datetime]::TryParse($s.gueltigAb, [ref]$d)) { $fehler.Add("gueltigAb ist kein Datum") }

if (-not $s.gruppen) { $fehler.Add("Abschnitt 'gruppen' fehlt") }
else {
    try { [void][regex]::new($s.gruppen.namensmuster) } catch { $fehler.Add("namensmuster ist kein gueltiger regulaerer Ausdruck") }
    if ($s.gruppen.mindestBesitzer -lt 2)          { $fehler.Add("mindestBesitzer muss mindestens 2 sein") }
    if ($s.gruppen.lebensdauerTage -lt 30)         { $fehler.Add("lebensdauerTage muss mindestens 30 sein") }
    if (-not $s.gruppen.pflichtMetadaten -or @($s.gruppen.pflichtMetadaten).Count -eq 0) { $fehler.Add("pflichtMetadaten darf nicht leer sein") }
}

if ($fehler.Count -gt 0) {
    $fehler | ForEach-Object { Write-Host "FEHLER: $_" -ForegroundColor Red }
    exit 1
}
Write-Host "Standards-Datei ist gueltig (Version $($s.version))." -ForegroundColor Green
```

Das Skript lädt die Datei und bricht ab, wenn sie kein gültiges JSON ist. Danach prüft es Schritt für Schritt: die Form der Versionsnummer, das Datum, die Existenz des Abschnitts, die Gültigkeit des Musters (der Versuch, das Muster zu kompilieren, zeigt Syntaxfehler), die Mindestbesitzer und die Lebensdauer. Die Untergrenze 30 Tage entspricht der Vorgabe der Ablaufrichtlinie (Modul 10.6). Alle Fehler werden gesammelt ausgegeben, und der Rückgabewert 1 lässt eine Pipeline den Änderungsvorschlag ablehnen. Bei Erfolg endet das Skript mit 0.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Policy-as-Code einzuführen, ohne den Änderungsprozess zu ändern: Die Dateien liegen im Repository, aber Administratoren ändern weiterhin im Portal, und die Datei veraltet. Zweitens werden Geheimnisse (Kennwörter, Schlüssel) in die Dateien geschrieben. Drittens sind die Regeln so fein, dass niemand sie versteht. Viertens fehlt eine automatische Prüfung, und ein Tippfehler legt alle Skripte lahm.

**Falsch und richtig: Werte aus Datei**

```powershell
# FALSCH: Grenzwert im Skript, drei Skripte, drei verschiedene Werte
$mindestBesitzer = 2      # in einem anderen Skript steht 1

# RICHTIG: eine Quelle fuer alle Skripte
$standards = Get-Content .\standards.json -Raw -Encoding UTF8 | ConvertFrom-Json
$mindestBesitzer = $standards.gruppen.mindestBesitzer
```

Mit einer Quelle gelten dieselben Werte überall. Die Version aus der Datei sollte außerdem in den Protokollen auftauchen, damit man später weiß, nach welcher Fassung eine Entscheidung getroffen wurde.

### Praxisbezug.

Beginnen Sie mit der Standarddatei für Gruppen und der Prüfung im Änderungsvorschlag. Erweitern Sie später um die Baselines des Dienstes für die kritischen Bereiche (bedingter Zugriff, Transportregeln). Machen Sie dabei den Prozess zur Regel: Portaländerungen an überwachten Einstellungen sind nur als Notfalländerung zulässig und werden nachträglich als Änderungsvorschlag erfasst.

## 11.5 Drift Detection

Mit *Drift* (Konfigurationsabweichung) bezeichnet man den Unterschied zwischen dem beschlossenen Soll-Zustand und dem tatsächlichen Ist-Zustand einer Einstellung. Drift entsteht auf vielen Wegen: Ein Administrator ändert im Notfall eine Richtlinie und vergisst die Rücknahme, eine Microsoft-Änderung setzt eine Standardeinstellung um, ein Projekt legt eine Ausnahme an, die nie wieder verschwindet. Für sich genommen sind viele dieser Änderungen harmlos, doch ohne Überwachung summieren sie sich zu einem Zustand, den niemand mehr überblickt, und genau diese Lücken nutzen Angreifer und Prüfer.

Drift-Erkennung heißt, Soll und Ist regelmäßig zu vergleichen und Unterschiede zu melden. Der Vergleich braucht drei Dinge: den Soll-Zustand als Baseline (Lerneinheit 11.4), den Ist-Zustand als Export (Lerneinheit 11.3) und eine Regel, was als Abweichung zählt. Die Meldung muss jemanden erreichen, der entscheiden kann: Entweder war die Änderung gewollt, dann wird die Baseline angepasst (über den Änderungsprozess), oder sie war ungewollt, dann wird der Soll-Zustand wiederhergestellt (Lerneinheit 11.8).

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Tenant-Konfigurationsverwaltung beschreibt Monitore, die ein JSON-Baseline referenzieren und die Konfiguration regelmäßig prüfen. Bei einer Abweichung entsteht ein Drift-Objekt, das die betroffene Ressource und jede abweichende Eigenschaft nennt; nach der Behebung markiert der nächste Lauf den Drift automatisch als „fixed“ (behoben). Die Dokumentation nennt folgende Grenzen: bis zu 30 Monitore je Tenant; jeder Monitor läuft in einem festen Intervall von sechs Stunden, das nicht änderbar ist; höchstens 800 überwachte Konfigurationsressourcen je Tag und Tenant über alle Monitore; wird die Baseline eines Monitors geändert, werden alle bisherigen Ergebnisse und Drifts dieses Monitors gelöscht; aktive Drifts bleiben abrufbar, und behobene Drifts werden 30 Tage nach der Behebung gelöscht. Ein Ergebnis eines Monitorlaufs enthält Dauer, Status und die Zahl der Drifts, aber keine Details; diese liefert die Abfrage der Drift-Objekte. Die Überwachung setzt voraus, dass die Dienstidentität der Konfigurationsverwaltung Leserechte für die überwachten Ressourcentypen hat. Beachten Sie, dass sechs Stunden Intervall bedeuten, dass eine Änderung bis zu diesem Zeitraum unentdeckt bleiben kann.

Der Dienst deckt viele, aber nicht alle Einstellungen ab, und er bewertet nur das, was in der Baseline steht. Für Einstellungen, die er nicht kennt, und für Ihre eigenen Governance-Standards bleibt der Vergleich per Skript. Er ist einfach: Man lädt Baseline und Export, ordnet die Einträge nach einem Schlüssel (meist dem Namen) und vergleicht Feld für Feld. Das folgende Skript tut das für Richtlinien, die in zwei JSON-Dateien liegen. Es meldet drei Arten von Abweichungen: Einträge, die nur in der Baseline stehen (fehlen im Tenant), Einträge, die nur im Tenant stehen (zusätzlich), und Einträge mit anderen Werten.

**Compare-ConfigDrift.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Baseline,
    [Parameter(Mandatory)][string]$Ist,
    [string]$Schluessel = "Name",
    [string[]]$Ignorieren = @()
)

function Read-Config($pfad) {
    $o = Get-Content -Path $pfad -Raw -Encoding UTF8 | ConvertFrom-Json
    $h = @{}
    foreach ($e in @($o)) { $h[[string]$e.$Schluessel] = $e }
    $h
}

$soll = Read-Config $Baseline
$ist  = Read-Config $Ist
$drift = New-Object System.Collections.Generic.List[object]

foreach ($k in $soll.Keys) {
    if (-not $ist.ContainsKey($k)) {
        $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "fehlt im Tenant"; Feld = ""; Soll = ""; Ist = "" }); continue
    }
    foreach ($p in $soll[$k].PSObject.Properties.Name) {
        if ($p -in $Ignorieren) { continue }
        $a = $soll[$k].$p | ConvertTo-Json -Depth 10 -Compress
        $b = $ist[$k].$p  | ConvertTo-Json -Depth 10 -Compress
        if ($a -ne $b) {
            $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "Wert abweichend"; Feld = $p; Soll = $a; Ist = $b })
        }
    }
}
foreach ($k in $ist.Keys) {
    if (-not $soll.ContainsKey($k)) {
        $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "zusaetzlich im Tenant"; Feld = ""; Soll = ""; Ist = "" })
    }
}

if ($drift.Count -eq 0) { Write-Host "Keine Abweichung."; exit 0 }
$drift | Format-Table -AutoSize -Wrap
exit 2
```

Die Funktion `Read-Config` liest eine Datei und legt die Einträge in einer Hashtabelle unter ihrem Schlüssel ab, so dass man sie direkt nachschlagen kann. Die erste Schleife geht durch alle Soll-Einträge: Fehlt einer im Ist, ist das ein Befund; sonst werden die Felder verglichen. Der Vergleich wandelt die Werte in kompaktes JSON, damit auch verschachtelte Werte einheitlich verglichen werden. Die zweite Schleife findet Einträge, die es nur im Tenant gibt. Mit `-Ignorieren` nimmt man bewusst Felder aus, die sich laufend ändern. Der Rückgabewert 2 signalisiert einer Pipeline oder einem Runbook, dass Handlungsbedarf besteht.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist ein Alarm, der so oft kommt, dass er ignoriert wird, weil flüchtige Felder nicht ausgenommen sind. Zweitens wird Drift gemeldet, aber niemand ist zuständig; jede Abweichung braucht einen Besitzer und eine Frist. Drittens wird die Baseline nie aktualisiert, so dass legitime Änderungen dauerhaft als Drift erscheinen. Viertens wird unterschätzt, dass ein Intervall von sechs Stunden zwischen Änderung und Entdeckung liegen kann.

**Falsch und richtig: Vergleich**

```powershell
# FALSCH: ganze Dateien als Text vergleichen - jeder Zeitstempel meldet Drift
if ((Get-Content soll.json -Raw) -ne (Get-Content ist.json -Raw)) { "Drift!" }

# RICHTIG: feldweise vergleichen, flüchtige Felder ausnehmen
.\Compare-ConfigDrift.ps1 -Baseline .\soll\transportregeln.json -Ist .\ist\transportregeln.json `
    -Schluessel Name -Ignorieren @("WhenChanged")
```

Der feldweise Vergleich meldet genau, was sich geändert hat, und lässt sich im Bericht verständlich darstellen. Der Textvergleich liefert nur ein Ja oder Nein und viele Fehlalarme.

### Praxisbezug.

Verbinden Sie die Drift-Meldung mit dem Auditprotokoll: Wer hat die Einstellung geändert, und wann? Dann lässt sich entscheiden, ob es ein autorisierter Eingriff war. Starten Sie mit wenigen kritischen Bereichen (bedingter Zugriff, Transportregeln, Freigaberichtlinien) und erweitern Sie, wenn die Meldungen gepflegt werden.

## 11.6 ITSM Integration

*ITSM* steht für IT Service Management, die geordnete Verwaltung von IT-Diensten mit Vorfällen (Incidents), Änderungen (Changes), Problemen und Anforderungen (Requests). Die Werkzeuge dazu heißen Ticketsysteme. Die Integration von Governance-Automatisierung mit dem Ticketsystem hat zwei Richtungen. Automatisierung *erzeugt* Tickets, zum Beispiel einen Vorfall bei Drift oder eine Aufgabe an die Besitzer verwaister Gruppen. Und Automatisierung *wird ausgelöst* durch Tickets, etwa eine genehmigte Anforderung „neues Team“ oder eine genehmigte Änderung. Beides schafft Nachvollziehbarkeit: Jede Handlung der Automatisierung hat eine Nummer, einen Auftraggeber und eine Freigabe.

Die zweite Richtung ist die wichtigere und riskantere. Sie setzt voraus, dass die Automatisierung nur dann ändert, wenn ein Ticket im richtigen Zustand existiert, zum Beispiel „genehmigt“. Damit wird verhindert, dass ein Skript auf eigene Faust Einstellungen ändert, und die Freigabe des Änderungsmanagements gilt auch für die Maschine. Die Verbindung geschieht über die Programmierschnittstelle des Ticketsystems: Man sendet Anfragen im JSON-Format an eine Webadresse und authentifiziert sich mit einem Token. Die Produkte unterscheiden sich in Feldern und Pfaden, das Prinzip ist gleich.

> **Ergänzung aus der Nachrecherche**
>
> Zu den Schnittstellen verschiedener Ticketsysteme enthält dieser Kurs keine abgerufene Quelle. Die folgenden Aussagen beruhen auf allgemeinem Fachwissen und sind bei der Umsetzung gegen die Dokumentation des eingesetzten Produkts zu prüfen: Ticketsysteme bieten in der Regel REST-Schnittstellen zum Anlegen und Lesen von Vorfällen und Änderungen; Zugangsdaten gehören in einen Tresor (zum Beispiel Azure Key Vault) und nicht ins Skript; für Wiederholungen empfiehlt sich ein Idempotenzschlüssel (eine eindeutige Kennung des Auslösers), damit eine wiederholte Anfrage kein zweites Ticket erzeugt. In der Microsoft-Welt bieten Power Automate und Logic Apps vorgefertigte Verbinder zu verbreiteten Ticketsystemen als Alternative zu eigenem Code.

Das folgende Skript zeigt das Muster in generischer Form. Eine Funktion erzeugt aus einem Drift-Befund ein Ticket, nachdem sie geprüft hat, ob für denselben Befund schon ein offenes Ticket besteht. Die zweite Funktion prüft vor einer Änderung, ob die zugehörige Änderungsnummer im Ticketsystem den Zustand „genehmigt“ hat. Adresse, Felder und Zustandswerte sind Platzhalter, die Sie an Ihr Produkt anpassen; das Token wird aus einer Umgebungsvariablen gelesen und steht nie im Code.

**Itsm-Bausteine.ps1**

```powershell
$script:ItsmBasis = $env:ITSM_URL         # z. B. https://tickets.contoso.com/api
$script:ItsmToken = $env:ITSM_TOKEN       # aus Tresor/Pipeline-Geheimnis, nie im Code

function Invoke-Itsm {
    param([string]$Methode, [string]$Pfad, $Body = $null)
    if (-not $script:ItsmBasis -or -not $script:ItsmToken) { throw "ITSM_URL und ITSM_TOKEN muessen gesetzt sein." }
    $kopf = @{ Authorization = "Bearer $($script:ItsmToken)"; Accept = "application/json" }
    $param = @{ Method = $Methode; Uri = "$($script:ItsmBasis)$Pfad"; Headers = $kopf; ContentType = "application/json" }
    if ($Body) { $param.Body = ($Body | ConvertTo-Json -Depth 5) }
    Invoke-RestMethod @param
}

function New-DriftTicket {
    param([Parameter(Mandatory)][string]$Eintrag, [Parameter(Mandatory)][string]$Beschreibung)
    $schluessel = "drift-" + ($Eintrag.ToLower() -replace '[^a-z0-9]+','-')
    $offen = Invoke-Itsm -Methode GET -Pfad "/tickets?externalKey=$schluessel&status=open"
    if ($offen.items -and @($offen.items).Count -gt 0) {
        Write-Host "Offenes Ticket existiert bereits: $($offen.items[0].number)"; return $offen.items[0]
    }
    Invoke-Itsm -Methode POST -Pfad "/tickets" -Body @{
        type = "incident"; externalKey = $schluessel; priority = "3"
        title = "Konfigurationsabweichung: $Eintrag"; description = $Beschreibung
        assignmentGroup = "M365-Betrieb"
    }
}

function Assert-ChangeApproved {
    param([Parameter(Mandatory)][string]$Nummer)
    $c = Invoke-Itsm -Methode GET -Pfad "/changes/$Nummer"
    if ($c.state -ne "approved") { throw "Change $Nummer hat Status '$($c.state)', erwartet 'approved'." }
    $c
}
```

Die Basisfunktion baut die Anfrage zusammen, prüft die Voraussetzungen und sendet sie. Die Funktion für Tickets bildet aus dem Eintrag einen Schlüssel, fragt nach einem offenen Ticket mit diesem Schlüssel und legt nur dann ein neues an, wenn keines besteht. Die dritte Funktion bricht die Ausführung mit einem Fehler ab, wenn die Änderung nicht genehmigt ist. In einem Änderungsskript steht sie ganz oben, sodass ohne Freigabe nichts geschieht.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist die Ticketflut: Jede Drift-Meldung erzeugt ein neues Ticket, und das Team ertrinkt. Der Idempotenzschlüssel verhindert das. Zweitens läuft die Automatisierung unter einem allmächtigen Ticketkonto. Drittens wird die Freigabe nur geprüft, wenn jemand daran denkt, statt sie im Skript zu erzwingen. Viertens fehlt die Rückmeldung: Das Ticket zeigt nicht, ob die Automatisierung erfolgreich war.

**Falsch und richtig: Freigabe erzwingen**

```powershell
# FALSCH: Aenderung ausfuehren, Ticketnummer nur zur Dokumentation
Set-MgGroup -GroupId $id -Description "neu"        # Ticket: CHG0001234 (steht im Kommentar)

# RICHTIG: Freigabe pruefen, dann aendern, dann Ergebnis ins Ticket schreiben
$c = Assert-ChangeApproved -Nummer "CHG0001234"
Update-MgGroup -GroupId $id -Description "neu"
Invoke-Itsm -Methode POST -Pfad "/changes/CHG0001234/notes" -Body @{ text = "Beschreibung gesetzt, Lauf erfolgreich." }
```

Mit der erzwungenen Prüfung kann das Skript ohne Freigabe nicht ändern. Die Rückmeldung schließt den Kreis: Das Ticket enthält das Ergebnis, und der Auditor findet Antrag, Genehmigung und Ausführung an einer Stelle.

### Praxisbezug.

Beginnen Sie mit der Richtung „Automatisierung erzeugt Ticket“, weil sie ungefährlich ist, und lassen Sie die Richtung „Ticket löst Änderung aus“ erst zu, wenn Rechte, Freigaben und Protokolle sitzen. Vereinbaren Sie mit dem Servicemanagement, welche Änderungen als Standardänderungen vorab genehmigt sind (zum Beispiel das Anlegen eines Teams der Stufe 1 aus Modul 10.2).

## 11.7 Automation Security

Ein Automatisierungsskript mit weitreichenden Rechten ist eines der wertvollsten Ziele in einem Tenant: Wer es übernimmt, hat die Macht über viele Benutzer und Daten, oft ohne Mehrfaktor-Anmeldung und ohne dass ein Mensch zusieht. Die Sicherheit der Automatisierung ist deshalb ein eigenes Thema, das nach demselben Prinzip wie die Administratorrollen behandelt wird (Modul 2.5 und 8.6): so wenig Rechte wie möglich, so kurz wie möglich, mit Protokoll und Freigabe. Vier Fragen strukturieren das Thema: Womit melde ich mich an? Was darf die Identität? Wo liegen ihre Geheimnisse? Und wer bemerkt, wenn sie missbraucht wird?

Die Anmeldung ohne Benutzer geschieht mit einer Anwendungsidentität (App-Registrierung mit Dienstprinzipal). Es gibt drei Arten, sich auszuweisen. Ein *Clientgeheimnis* ist ein Kennwort der Anwendung: einfach, aber leicht zu kopieren und zu verlieren. Ein *Zertifikat* ist besser, weil der private Schlüssel nicht übertragen wird, muss aber sicher gespeichert und erneuert werden. Eine *verwaltete Identität* (Managed Identity) ist die beste Wahl, wenn das Skript in Azure läuft: Es gibt kein Geheimnis, das verloren gehen kann, weil Azure die Identität an die Ressource bindet.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Graph-PowerShell-SDK beschreibt app-only-Zugriff mit Zertifikat (über Fingerabdruck, Name oder Zertifikatsobjekt), mit Clientgeheimnis (dafür wird PowerShell 7 oder neuer empfohlen) und mit verwalteter Identität. Das Zertifikat wird aus dem Speicher des aktuellen Benutzers oder des Computers geladen; ein Zertifikat ohne zugänglichen privaten Schlüssel, ein abgelaufenes Zertifikat oder ein Fingerabdruck, der in der App-Registrierung nicht hinterlegt ist, führen zu Anmeldefehlern. Die Dokumentation zu bewährten Verfahren rät, Anwendungen nur die mindestens nötigen Berechtigungen zu geben, und die Berechtigungsreferenz nennt zu jedem Aufruf die Berechtigung mit den geringsten Rechten („least privileged“). Für die Konfigurationsüberwachung zeigt die Anleitung zum Tenant Governance exemplarisch, wie Berechtigungen gezielt je Ressourcentyp vergeben werden, zum Beispiel `Policy.Read.All` für bedingten Zugriff und die Rolle „Teams Reader“ für Teams-Ressourcen. Aussagen zu Tresoren (Key Vault), Zugriffsbeschränkungen für Workload-Identitäten und Überwachung von Dienstprinzipalen beruhen auf allgemeinem Fachwissen und sind in der aktuellen Dokumentation zu prüfen.

Daraus lassen sich Regeln ableiten. Jede Automatisierung erhält eine eigene Identität, damit man ihre Rechte und Aktionen getrennt sieht. Die Rechte werden auf das Nötige begrenzt: Ein Berichtsskript bekommt Leserechte, kein Skript bekommt `Directory.ReadWrite.All`, nur weil es bequem ist. Lesende und schreibende Aufgaben laufen unter verschiedenen Identitäten. Geheimnisse liegen in einem Tresor, haben ein Ablaufdatum und werden vor dem Ablauf erneuert; besser ist, wo möglich, ganz auf Geheimnisse zu verzichten. Die Anmeldungen der Identität werden überwacht (Modul 9.5), und Änderungen an ihren Rechten sind selbst ein Alarmgrund.

Das folgende Skript prüft die Rechte der Anwendungen im Tenant: Es listet alle Dienstprinzipale, die Rechte auf Microsoft Graph haben, die auf Schreibzugriff in großem Umfang hindeuten (Berechtigungen, die auf „ReadWrite.All“ enden). Das ist eine Stichprobe, die schnell die gefährlichsten Fälle zeigt. Es löst dafür die Kennungen der Berechtigungen in lesbare Namen auf, indem es die Berechtigungsliste des Graph-Dienstprinzipals abfragt.

**Get-RiskyAppPermissions.ps1**

```powershell
Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome

$graphAppId = "00000003-0000-0000-c000-000000000000"      # Microsoft Graph
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"
$rollen = @{}
foreach ($r in $graphSp.AppRoles) { $rollen[$r.Id] = $r.Value }

$ergebnis = foreach ($sp in Get-MgServicePrincipal -All -Property Id,DisplayName,AppId) {
    $zuweisungen = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue |
        Where-Object { $_.ResourceId -eq $graphSp.Id }
    foreach ($z in $zuweisungen) {
        $name = $rollen[$z.AppRoleId]
        if ($name -like "*ReadWrite.All") {
            [pscustomobject]@{ Anwendung = $sp.DisplayName; AppId = $sp.AppId; Berechtigung = $name }
        }
    }
}

if ($ergebnis) {
    $ergebnis | Sort-Object Anwendung | Format-Table -AutoSize
    "{0} Zuweisungen mit weitreichendem Schreibzugriff bei {1} Anwendungen." -f @($ergebnis).Count, @($ergebnis | Select-Object -Unique Anwendung).Count
} else {
    "Keine Zuweisungen mit '*ReadWrite.All' gefunden."
}
```

Das Skript ermittelt zuerst den Dienstprinzipal von Microsoft Graph und baut daraus eine Tabelle, die jede Berechtigungskennung auf ihren Namen abbildet. Danach geht es durch alle Dienstprinzipale des Tenants, liest deren Anwendungsrollen-Zuweisungen und behält die, die sich auf Graph beziehen. Berechtigungen mit dem Namen „…ReadWrite.All“ gelten als weitreichend und werden gemeldet. Für jeden Treffer muss ein Verantwortlicher begründen, warum das Recht nötig ist. Bei Tenants mit vielen Anwendungen dauert der Lauf eine Weile.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Sammelidentität: eine einzige Anwendung mit allen Rechten für alle Skripte, deren Geheimnis in zehn Skripten steht. Zweitens verfallen Geheimnisse unbemerkt, und die Automatisierung fällt um 3 Uhr nachts aus. Drittens bleiben Rechte von Anwendungen bestehen, die niemand mehr nutzt. Viertens enthält das Repository ein Geheimnis im Klartext, und es bleibt in der Historie, auch nachdem man es gelöscht hat.

**Falsch und richtig: Anmeldung**

```powershell
# FALSCH: Geheimnis im Skript
$geheimnis = "abc~123SuperGeheim"
Connect-MgGraph -ClientSecretCredential (New-Object PSCredential($clientId, (ConvertTo-SecureString $geheimnis -AsPlainText -Force))) -TenantId $tenantId

# RICHTIG: Zertifikat aus Zertifikatspeicher oder verwaltete Identitaet
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $env:GRAPH_CERT_THUMBPRINT -NoWelcome
# in Azure Automation / Azure-VM:
# Connect-MgGraph -Identity -NoWelcome
```

Die richtige Variante liest nur den Fingerabdruck des Zertifikats aus der Umgebung; das Zertifikat selbst liegt im Speicher des Rechners und ist nicht Teil des Skripts. In Azure entfällt auch das, wenn man die verwaltete Identität verwendet. Falls Sie in einem Repository versehentlich ein Geheimnis veröffentlicht haben, genügt das Löschen nicht: Das Geheimnis gilt als offengelegt und muss erneuert werden.

### Praxisbezug.

Führen Sie ein Register der Automatisierungsidentitäten: Zweck, Besitzer, Rechte, Art der Anmeldung, Ablaufdatum der Zugangsdaten. Prüfen Sie es vierteljährlich mit dem Skript aus diesem Abschnitt und der Zugriffsüberprüfung (Modul 2.4). Neue Rechte für Anwendungen gehen durch den Ausnahmeprozess (Modul 8.7), wenn sie über das Übliche hinausgehen.

## 11.8 Rollback

Jede Änderung kann falsch sein. Ein *Rollback* ist die kontrollierte Rückkehr zum vorherigen Zustand. Er unterscheidet sich von der Wiederherstellung nach einem Datenverlust (Modul 12.6) dadurch, dass er eine Konfigurationsänderung zurücknimmt und nicht Daten rettet. Die Möglichkeit, eine Änderung schnell zurückzunehmen, entscheidet darüber, wie mutig man Automatisierung einsetzen kann: Wer weiß, dass die Rücknahme in Minuten möglich ist, ändert öfter und in kleineren Schritten und macht dadurch weniger große Fehler.

Ein Rollback muss geplant sein, bevor man die Änderung durchführt. Der Plan beantwortet fünf Fragen: Wie sieht der Zustand vor der Änderung aus (und wo ist er gesichert)? Woran erkenne ich, dass die Änderung fehlgeschlagen ist (Erfolgskriterium)? Wer entscheidet bis wann über die Rücknahme? Welche Schritte stellen den alten Zustand her? Und wie prüfe ich, dass die Rücknahme gelungen ist? Wichtig ist, dass nicht jede Änderung umkehrbar ist: Das endgültige Löschen eines Postfachs oder das Versenden einer E-Mail lässt sich nicht zurücknehmen. Für solche Änderungen ersetzt eine strenge Freigabe den Rollback (Lerneinheit 11.6).

> **Ergänzung aus der Nachrecherche**
>
> Aus den in diesem Kurs abgerufenen Quellen ergeben sich mehrere Rollback-Wege. Gelöschte Microsoft-365-Gruppen sind laut Dokumentation 30 Tage lang wiederherstellbar (die Frist ist nicht änderbar); die Wiederherstellung umfasst Gruppenobjekt, Postfach, SharePoint-Website, Planner und Team. Die Dokumentation zur Tenant-Konfigurationsverwaltung beschreibt Momentaufnahmen mit einer Aufbewahrung von höchstens sieben Tagen und erwähnt, dass die Dienstschnittstellen derzeit keine Bereitstellung oder Korrektur anbieten; ein Rollback der Konfiguration muss daher selbst geschrieben werden. Für Daten nennt die Übersicht zu den Tenant-Verwaltungs-APIs die Sicherungsdienste für Microsoft 365 (Backup Storage), die SharePoint-Websites, OneDrive-Konten und Exchange-Postfächer mit bis zu einem Jahr Aufbewahrung und Wiederherstellungspunkten im Abstand von zehn Minuten schützen und unveränderlich speichern; die Wiederherstellung ist laut dieser Übersicht kostenfrei. Diese Sicherung ist keine Konfigurationssicherung. Die Rolle von Sicherung und Wiederherstellung im Gesamtkonzept behandelt Modul 12.6.

Aus diesen Wegen folgt die Praxis: Vor jeder Änderung exportiert das Skript den betroffenen Zustand in eine Datei, führt die Änderung durch, prüft das Erfolgskriterium und kehrt bei Misserfolg selbstständig zum gesicherten Zustand zurück. Dieses Muster („Sichern, Ändern, Prüfen, notfalls Zurücksetzen“) gilt für jede Konfigurationsänderung. Das folgende Skript wendet es auf die Lebensdauer der Gruppenablaufrichtlinie aus Modul 10.6 an. Es sichert die aktuelle Richtlinie, setzt die neue Lebensdauer, prüft, ob der Wert gesetzt ist, und stellt bei einem Fehler den alten Wert wieder her.

**Set-LifetimeWithRollback.ps1**

```powershell
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateRange(30, 3650)][int]$NeueLebensdauer,
    [Parameter(Mandatory)][string]$ChangeNummer,
    [string]$Sicherung = ".\rollback"
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Directory.ReadWrite.All" -NoWelcome

$richtlinie = Get-MgGroupLifecyclePolicy | Select-Object -First 1
if (-not $richtlinie) { throw "Keine Ablaufrichtlinie vorhanden." }

New-Item -ItemType Directory -Path $Sicherung -Force | Out-Null
$datei = Join-Path $Sicherung ("{0}-{1}.json" -f $ChangeNummer, (Get-Date -Format "yyyyMMdd-HHmmss"))
$richtlinie | Select-Object Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails |
    ConvertTo-Json | Set-Content -Path $datei -Encoding UTF8
Write-Host "Sicherung geschrieben: $datei"

if (-not $PSCmdlet.ShouldProcess("Ablaufrichtlinie $($richtlinie.Id)", "Lebensdauer $($richtlinie.GroupLifetimeInDays) -> $NeueLebensdauer")) { return }

try {
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $richtlinie.Id -GroupLifetimeInDays $NeueLebensdauer
    $pruefung = Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $richtlinie.Id
    if ($pruefung.GroupLifetimeInDays -ne $NeueLebensdauer) { throw "Pruefung fehlgeschlagen: Wert ist $($pruefung.GroupLifetimeInDays)." }
    Write-Host "Aenderung erfolgreich ($ChangeNummer)."
} catch {
    Write-Warning "Fehler: $($_.Exception.Message) - Rollback wird ausgefuehrt."
    $alt = Get-Content -Path $datei -Raw -Encoding UTF8 | ConvertFrom-Json
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $alt.Id -GroupLifetimeInDays $alt.GroupLifetimeInDays
    throw "Rollback ausgefuehrt, Aenderung $ChangeNummer fehlgeschlagen."
}
```

Das Skript verlangt eine Änderungsnummer und einen sinnvollen Wertebereich. Es sichert die Richtlinie in einer Datei mit der Nummer und dem Zeitstempel im Namen, sodass man die Sicherung später dem Vorgang zuordnen kann. Der Aufruf von `ShouldProcess` erlaubt den Probelauf. Danach folgt der Dreischritt: ändern, prüfen, bei Abweichung zurücksetzen. Die Prüfung liest den Wert erneut aus dem Dienst und vergleicht ihn mit dem Ziel; sie darf sich nicht auf die Rückmeldung des Änderungsaufrufs verlassen. Im Fehlerfall wird der gesicherte Wert zurückgeschrieben und der Fehler trotzdem gemeldet, damit das Ticket den Misserfolg zeigt.

### Typische Fehler und Stolperfallen.

Der schwerste Fehler ist, keinen Zustand zu sichern und sich auf „das lässt sich schon wieder einstellen“ zu verlassen: Wer die alten Werte nicht kennt, kann sie nicht wiederherstellen. Zweitens wird die Rücknahme nie getestet und funktioniert im Ernstfall nicht. Drittens wird der Rollback zu spät ausgelöst, weil kein Erfolgskriterium und keine Frist definiert waren. Viertens werden Änderungen gebündelt, so dass man bei einem Fehler nicht weiß, welche Änderung schuld ist.

**Falsch und richtig: Pruefen und zuruecksetzen**

```powershell
# FALSCH: Aenderung ohne Sicherung, Erfolg angenommen
Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays 30
"Fertig."

# RICHTIG: sichern, aendern, Zielwert pruefen, Rueckweg bereit
$alt = Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id | Select-Object -ExpandProperty GroupLifetimeInDays
Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays 365
if ((Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id).GroupLifetimeInDays -ne 365) {
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays $alt
}
```

Die richtige Fassung hält den alten Wert in einer Variablen und prüft das Ergebnis. Für wichtige Änderungen genügt eine Variable nicht, dann gehört die Sicherung in eine Datei, die ein Neustart der Sitzung überlebt. Beachten Sie auch, dass Cmdlet-Namen und Parameter je nach Modulversion abweichen können; testen Sie das Skript im Testtenant.

### Praxisbezug.

Schreiben Sie für jede Änderungsklasse (Richtlinie, Regel, Berechtigung) einen Rollback-Schritt in das Runbook (Modul 9.7), und üben Sie ihn halbjährlich in einer Testumgebung. Verknüpfen Sie die Sicherungsdatei mit der Änderungsnummer im Ticketsystem. Bei der Planung großer Änderungen legen Sie ein Zeitfenster fest, in dem die Rücknahme noch ohne Folgeschäden möglich ist.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Erklären Sie die Begriffe „delegierter Zugriff“ und „Anwendungszugriff“ bei Microsoft Graph. Für welche Art von Aufgaben brauchen Sie welchen?

**Aufgabe 2 (leicht).** Warum reicht es nicht, bei einer Abfrage nur die erste Seite der Antwort zu lesen? Wie erkennt man, dass es weitere Seiten gibt, und was darf man mit der Adresse der nächsten Seite nicht tun?

**Aufgabe 3 (leicht).** Nennen Sie fünf Eigenschaften eines betriebstauglichen PowerShell-Skripts und erklären Sie in je einem Satz, warum sie wichtig sind.

**Aufgabe 4 (mittel).** Schreiben Sie ein Skript im Stil dieses Moduls, das alle Gruppen ohne Besitzer findet, die Liste in eine Datei schreibt und mit dem Schalter `-WhatIf` lediglich anzeigt, welche Gruppen es einer Ersatzperson als Besitzer zuweisen würde. Beschreiben Sie, warum das Skript idempotent ist.

**Aufgabe 5 (mittel).** Ein Export der Transportregeln meldet bei jedem Lauf Hunderte Änderungen im Git-Repository, obwohl niemand etwas geändert hat. Nennen Sie drei mögliche Ursachen und die Gegenmaßnahmen.

**Aufgabe 6 (mittel).** Beschreiben Sie den Unterschied zwischen einer Momentaufnahme, einer Baseline und einem Monitor in der Tenant-Konfigurationsverwaltung. Welche Grenzen müssen Sie bei der Planung beachten?

**Aufgabe 7 (schwer).** Entwerfen Sie ein Gesamtkonzept „Konfiguration als Code“ für die Einstellungen bedingter Zugriff und Transportregeln: Repository-Struktur, Änderungsprozess, automatische Prüfungen, Drift-Erkennung, Benachrichtigung, Rollback. Zeichnen Sie den Ablauf als Liste von Schritten.

**Aufgabe 8 (schwer).** Ein Automatisierungsskript soll Teams archivieren. Es läuft mit einer Anwendungsidentität, die `Directory.ReadWrite.All` besitzt, und das Geheimnis steht im Skript. Bewerten Sie die Lösung und beschreiben Sie eine sichere Neugestaltung mit Identität, Rechten, Geheimnisverwaltung, Freigabe und Protokoll.

## Lösungen

**Lösung 1.** Beim delegierten Zugriff handelt das Programm im Namen einer angemeldeten Person und hat höchstens deren Rechte; das passt zu Aufgaben, die ein Administrator selbst ausführt. Beim Anwendungszugriff handelt die Anwendung mit eigener Identität ohne Benutzer; das braucht man für geplante, unbeaufsichtigte Aufgaben. Anwendungsrechte müssen ein Administrator genehmigen und sind oft weitreichender, weshalb sie besonders sparsam vergeben werden.

**Lösung 2.** Graph liefert große Listen seitenweise, zum Beispiel 100 Benutzer je Seite. Wer nur die erste Seite liest, erhält unvollständige Ergebnisse ohne Fehlermeldung. Weitere Seiten erkennt man an der Eigenschaft `@odata.nextLink` in der Antwort. Man ruft diese Adresse unverändert auf, bis sie nicht mehr erscheint. Man darf nicht den Fortsetzungswert herauslösen und in eine andere Anfrage übernehmen.

**Lösung 3.** Typische Eigenschaften: Parameter mit Prüfung (verhindert falsche Eingaben), Probelauf mit `-WhatIf` (zeigt Wirkung vor dem Ändern), Idempotenz (wiederholter Lauf richtet keinen Schaden an), Fehlerbehandlung (Fehler werden sichtbar statt verschluckt), Protokoll (macht Änderungen nachvollziehbar), Anmeldung ohne Geheimnis im Code (Sicherheit).

**Lösung 4.** Ein Lösungsvorschlag:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$Ersatzbesitzer, [string]$Ausgabe = ".\ohne-besitzer.csv")
$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All" -NoWelcome
$user = Get-MgUser -UserId $Ersatzbesitzer
$treffer = foreach ($g in Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName) {
    if (@(Get-MgGroupOwner -GroupId $g.Id).Count -eq 0) {
        $status = "geplant"
        if ($PSCmdlet.ShouldProcess($g.DisplayName, "Besitzer $Ersatzbesitzer hinzufuegen")) {
            New-MgGroupOwnerByRef -GroupId $g.Id -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)" }
            $status = "zugewiesen"
        }
        [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $g.Id; Status = $status }
    }
}
$treffer | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
```

Das Skript ist idempotent, weil es nur Gruppen bearbeitet, die noch keinen Besitzer haben: Nach dem ersten Lauf haben sie einen, und ein zweiter Lauf findet sie nicht mehr. Mit `-WhatIf` werden keine Änderungen ausgeführt, die Datei zeigt den Status „geplant“.

**Lösung 5.** Mögliche Ursachen: (1) Der Export enthält flüchtige Felder wie Zeitstempel; Gegenmaßnahme: Felder auf einen festen Satz begrenzen. (2) Die Reihenfolge der Einträge ist nicht stabil; Gegenmaßnahme: nach einem festen Schlüssel sortieren. (3) Unterschiedliche Formatierung, etwa Zeilenenden oder Einrückung; Gegenmaßnahme: einheitliche Kodierung und feste Tiefe beim Umwandeln in JSON. Zusätzlich kann der Export in einem anderen Zeitraum andere Objekte liefern, wenn Seiten nicht vollständig gelesen werden.

**Lösung 6.** Eine Momentaufnahme extrahiert die aktuelle Konfiguration ausgewählter Ressourcen. Eine Baseline ist die JSON-Beschreibung des Soll-Zustands. Ein Monitor prüft regelmäßig, ob der Tenant der Baseline entspricht, und erzeugt bei Abweichungen Drift-Objekte. Grenzen: Momentaufnahmen höchstens 20.000 Ressourcen je Monat, 12 sichtbare Jobs und sieben Tage Aufbewahrung; Monitore höchstens 30 je Tenant, festes Intervall von sechs Stunden, höchstens 800 überwachte Ressourcen je Tag, 200 Ressourceninstanzen je Baseline; die Änderung einer Baseline löscht bisherige Ergebnisse.

**Lösung 7.** Ein Beispiel: Repository mit Ordnern `soll/` (Baselines), `ist/` (nächtlicher Export), `skripte/` und `standards/`. Ablauf: (1) Änderung als Pull Request an der Baseline vorschlagen. (2) Automatische Prüfung: Formatprüfung der Dateien, Prüfung auf Geheimnisse. (3) Freigabe durch zweite Person. (4) Änderung im Portal oder per Skript mit Change-Nummer. (5) Nächtlicher Export in `ist/`. (6) Vergleich von Soll und Ist; bei Abweichung ein Ticket mit Idempotenzschlüssel. (7) Entscheidung: Baseline anpassen oder zurücksetzen. (8) Rollback aus der Sicherung, mit Prüfung. Wichtig sind der Verzicht auf Geheimnisse in den Dateien und die Begrenzung der Rechte der Automatisierung auf Lesen.

**Lösung 8.** Bewertung: Die Identität hat zu weitreichende Rechte (Schreibzugriff auf das gesamte Verzeichnis, obwohl nur Teams archiviert werden sollen), das Geheimnis im Skript ist ein Offenlegungsrisiko, und es gibt weder Freigabe noch Protokoll. Neugestaltung: eigene Identität für diese Aufgabe, nur die für das Archivieren nötigen Berechtigungen (laut Berechtigungsreferenz zu prüfen); wenn das Skript in Azure läuft, verwaltete Identität, sonst Zertifikat im Zertifikatspeicher oder Tresor; Ausführung nur mit genehmigter Änderungsnummer; Probelauf und Liste der Kandidaten, die die Besitzer bestätigen; Protokoll je Team; Überwachung der Anmeldungen der Identität; Eintrag im Register der Automatisierungsidentitäten mit Besitzer und Ablaufdatum.
