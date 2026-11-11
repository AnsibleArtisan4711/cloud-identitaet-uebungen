# Modul 09 - Monitoring, Reporting und Service Operations

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 8 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich ebenfalls auf 8 Stunden (8 × 1); hier gibt es keine Abweichung.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**           | **Dauer (h)** | **Prio** |
|:--------|:--------------------------|--------------:|---------:|
| 9.1     | Admin Center Reports      |             1 |        1 |
| 9.2     | Usage Analytics           |             1 |        1 |
| 9.3     | Purview Reports           |             1 |        1 |
| 9.4     | Defender Reports          |             1 |        1 |
| 9.5     | Entra Monitoring          |             1 |        1 |
| 9.6     | Service Health            |             1 |        2 |
| 9.7     | Operational Runbooks      |             1 |        2 |
| 9.8     | Governance KPIs           |             1 |        2 |
|         | **Summe laut Details**    |         **8** |          |
|         | **Dauer laut Modulblatt** |         **8** |          |

> **Merke: Berichte sind personenbezogene Daten**
>
> Fast jeder Bericht in diesem Modul enthält Angaben über Beschäftigte: wer wann welchen Dienst nutzt, wer sich von wo anmeldet, wer welche Dateien freigibt. Deshalb gelten für Berichte dieselben Grundsätze wie für alle personenbezogenen Daten: Zweckbindung, Datensparsamkeit, Zugriffsbeschränkung und Löschfristen. Ob und wie weit Nutzungsdaten einzelnen Personen zugeordnet werden dürfen, klären Datenschutz und Betriebsrat (keine Rechtsberatung). Die Beispiele wurden nicht gegen einen echten Tenant ausgeführt; Spaltennamen der Berichte sind vor dem Einsatz an der echten Ausgabe zu prüfen.

Die bisherigen Module haben Regeln aufgestellt. Dieses Modul beantwortet die Frage, ob die Regeln wirken: Welche Berichte gibt es, was bedeuten sie, wie bringt man sie in einen regelmäßigen Betrieb, und wie reagiert man, wenn der Dienst selbst gestört ist? Am Ende steht der Schritt von einzelnen Berichten zu wenigen Kennzahlen, die die Leitung versteht.

## 9.1 Admin Center Reports

Das Microsoft 365 Admin Center enthält unter „Berichte“ eine Sammlung von Nutzungsberichten: aktive Benutzer pro Dienst, E-Mail-Aktivität, OneDrive- und SharePoint-Nutzung, Teams-Aktivität, Gruppenaktivität, Lizenznutzung und weitere. Sie beantworten Grundfragen des Betriebs: Wer nutzt die bezahlten Lizenzen tatsächlich? Welche Dienste werden angenommen? Wächst der Speicher? Die Berichte decken wählbare Zeiträume ab (7, 30, 90 oder 180 Tage) und enthalten eine Übersicht mit Zeitreihe und eine Detailtabelle je Benutzer, Gruppe oder Website. Die Daten sind nicht in Echtzeit: Sie werden mit Verzögerung aufbereitet, weshalb sie sich für Trends eignen, nicht für aktuelle Störungen.

Von zentraler Bedeutung für die Governance ist die Datenschutzeinstellung der Berichte. Seit dem 1. September 2021 sind Benutzernamen, Gruppennamen und Website-Adressen in den Berichten standardmäßig verborgen und erscheinen als Hashwerte. Ein globaler Administrator kann diese Einstellung ändern, und das Anzeigen identifizierbarer Informationen ist ein protokolliertes Ereignis. Governance-seitig ist das eine bewusste Entscheidung: Für die Lizenzbereinigung braucht man Namen, für Trendbetrachtungen reichen anonyme Zahlen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Nutzungsberichten beschreibt, dass die Einstellung zum Verbergen von Benutzer-, Gruppen- und Websitenamen seit dem 1. September 2021 standardmäßig aktiv ist, dass sie unter Einstellungen, Organisationseinstellungen, Dienste, Berichte liegt und dass sie auch für Microsoft Graph und Power BI gilt. Das Anzeigen identifizierbarer Informationen wird im Überwachungsprotokoll festgehalten. Die Berichte lassen sich über Graph abrufen (Zeiträume D7, D30, D90 und D180); der Aufruf liefert eine Weiterleitung auf eine kurzlebige Download-Adresse, die ohne Authentifizierungskopf auskommt. Die Dokumentation empfiehlt außerdem, Rollen mit den geringsten Berechtigungen zu verwenden statt den Globalen Administrator. Zur Auslegung der Aktivitätsdaten: Das Datum der letzten Aktivität nennt den letzten Tag, an dem jemand eine absichtliche Aktivität in der Anwendung ausgeführt hat, unabhängig vom gewählten Berichtszeitraum.

Wie nutzt man die Berichte im Betrieb? Ein sinnvoller Rhythmus ist monatlich: aktive Benutzer pro Dienst festhalten, Lizenzen ohne Aktivität identifizieren, Speicherwachstum prüfen, auffällige Rückgänge hinterfragen. Dabei sind drei Fallen zu beachten. Erstens zeigt „aktiv“ nur, dass irgendeine absichtliche Aktivität stattfand, nicht ob die Nutzung sinnvoll ist. Zweitens fehlen gelöschte Konten in der Detailtabelle, während sie in der Zeitreihe für die Zeit ihrer Aktivität weiter mitgezählt werden. Drittens sind die Berichte keine Echtzeitquelle; für aktuelle Störungen gibt es die Dienstintegrität (Lerneinheit 9.6).

Das folgende Skript lädt den Benutzerdetailbericht der aktiven Benutzer der letzten 90 Tage über Microsoft Graph herunter und ermittelt lizenzierte Konten ohne jede Aktivität in Exchange, OneDrive, SharePoint und Teams. Es verwendet `Get-MgReportOffice365ActiveUserDetail` mit der Option `-OutFile`, die den Bericht als CSV-Datei speichert. Danach liest es die Datei ein, prüft die Spaltenüberschriften und zählt die Konten. Ist die Verbergung der Namen aktiv, gibt es die Zahl aus, aber keine Namen, denn die Spalte enthält dann Hashwerte.

**Get-InactiveLicensedUsers.ps1**

```powershell
param([string]$Datei = ".\ActiveUserDetail.csv")

Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome

Get-MgReportOffice365ActiveUserDetail -Period D90 -OutFile $Datei
$zeilen = Import-Csv -Path $Datei
if (-not $zeilen) { throw "Bericht ist leer." }

$aktSpalten = "Exchange Last Activity Date", "OneDrive Last Activity Date",
              "SharePoint Last Activity Date", "Teams Last Activity Date"
$lizSpalten = "Has Exchange License", "Has OneDrive License",
              "Has SharePoint License", "Has Teams License"

$vorhanden = $zeilen[0].PSObject.Properties.Name
$fehlt = @($aktSpalten + $lizSpalten + "Is Deleted") | Where-Object { $_ -notin $vorhanden }
if ($fehlt) { throw "Spalten nicht gefunden: $($fehlt -join ', ')" }

$ohne = foreach ($z in $zeilen) {
    if ($z.'Is Deleted' -eq 'True') { continue }
    $lizenziert = $lizSpalten | Where-Object { $z.$_ -eq 'True' }
    $aktiv      = $aktSpalten | Where-Object { $z.$_ }
    if ($lizenziert -and -not $aktiv) { $z }
}

"Konten im Bericht:                  {0}" -f @($zeilen).Count
"Lizenziert, aber ohne Aktivitaet:    {0}" -f @($ohne).Count

if ($ohne -and $ohne[0].'User Principal Name' -like '*@*') {
    $ohne | Select-Object 'User Principal Name', 'Display Name' | Format-Table -AutoSize
} elseif ($ohne) {
    Write-Host "Namen sind verborgen (Datenschutzeinstellung der Berichte)."
}
```

Die Schleife bearbeitet jede Zeile des Berichts. Gelöschte Konten werden übersprungen. Für jedes Konto bildet das Skript zwei Listen: die Dienste, für die eine Lizenz besteht, und die Dienste mit einem Datum der letzten Aktivität. Ein Konto gilt als auffällig, wenn mindestens eine Lizenz, aber keine Aktivität vorliegt. Die letzte Prüfung erkennt an der Form der Benutzerkennung (sie enthält ein At-Zeichen), ob die Namen lesbar sind. Das Ergebnis dient als Grundlage für eine Lizenzbereinigung, die man mit den Verantwortlichen abstimmt, bevor Lizenzen entzogen werden.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, einen Bericht ohne Datenschutzentscheidung „aufzudecken“, indem man die Verbergung abschaltet und die Namen weitergibt. Zweitens werden Spaltennamen nicht geprüft, und ein umbenannter Spaltenname erzeugt stille Fehler (leere Ergebnisse). Drittens werden Lizenzen allein nach Aktivität entzogen, obwohl Urlaub, Elternzeit oder Saisonarbeit kurzzeitig Inaktivität erzeugen. Viertens wird mit einem Zeitraum von sieben Tagen entschieden, was viel zu kurz ist.

**Falsch und richtig: Spalten pruefen**

```powershell
# FALSCH: blind auf eine Spalte zugreifen
Import-Csv .\ActiveUserDetail.csv | Where-Object { -not $_.'Teams Last Activity Date' }

# RICHTIG: erst pruefen, ob die Spalte existiert
$z = Import-Csv .\ActiveUserDetail.csv
if ('Teams Last Activity Date' -notin $z[0].PSObject.Properties.Name) { throw "Spalte fehlt" }
$z | Where-Object { -not $_.'Teams Last Activity Date' }
```

Ohne Prüfung liefert ein fehlerhafter Spaltenname für jede Zeile den Wert leer, und das Skript meldet fälschlich alle Konten als inaktiv. Die Prüfung macht den Fehler sofort sichtbar.

### Praxisbezug.

Lizenzkosten sind meist der erste Anlass für Berichtsarbeit, weil sie sofort Geld sparen. Verbinden Sie die Auswertung mit dem Joiner-Mover-Leaver-Prozess (Modul 2): Ein Konto mit Lizenz ohne Aktivität ist oft ein ausgeschiedener Mitarbeiter, dessen Konto nicht abgeschaltet wurde. Das ist zugleich ein Sicherheitsthema.

## 9.2 Usage Analytics

Während die Berichte im Admin Center einzelne Dienste zeigen, fragt die Nutzungsanalyse (Usage Analytics) nach der Gesamtentwicklung: Wie verändert sich die Nutzung über Monate, welche Funktionen werden angenommen, wo gibt es ungenutzte Potenziale? Microsoft stellt dafür mehrere Werkzeuge bereit. Die Nutzungsanalyse als Power-BI-Vorlage verknüpft die Berichtsdaten mit Auswertungen über längere Zeiträume. Der Adoption Score bewertet die Einführung in Kategorien und gibt Empfehlungen. Die Teams-Berichte und die SharePoint-Standortberichte liefern Zahlen zu einzelnen Diensten.

Für die Governance sind drei Anwendungen besonders wichtig. Die erste ist das *Lebenszyklusmanagement*: Websites und Teams ohne Aktivität sind Kandidaten für Archivierung oder Löschung (Modul 3 und 4). Die zweite ist die *Akzeptanzmessung*: Wenn eine neue Regel oder Plattform eingeführt wurde (zum Beispiel Labels oder ein neues Intranet), zeigen Nutzungszahlen, ob sie angenommen wird (Modul 12, Adoption). Die dritte ist die *Kapazitätsplanung*: Speicherwachstum, Aktivität nach Standort, Spitzenzeiten.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation weist darauf hin, dass sich die Daten der Nutzungsberichte über Graph abrufen und in eigene Auswertungen oder Power BI einbinden lassen und dass die Datenschutzeinstellung zur Verbergung von Namen auch für diese Wege gilt. Für Funktionen wie den Adoption Score und Auswertungen auf Personenebene gelten besondere Datenschutzhinweise; ob und in welcher Detailtiefe man sie nutzt, ist mit Datenschutz und Arbeitnehmervertretung zu klären (keine Rechtsberatung). Bezeichnungen und Leistungsumfang der Analysewerkzeuge ändern sich häufig; prüfen Sie die aktuelle Dokumentation.

Ein typisches Auswertungsziel ist die Identifikation inaktiver SharePoint-Websites. Der Bericht zur Websitenutzung enthält je Website das Datum der letzten Aktivität, die Zahl der Dateien, die Zahl der aktiven Dateien, die Seitenaufrufe und den belegten Speicher. Aus diesen Spalten lässt sich eine einfache Alterungsanalyse bauen: Wie viele Websites hatten in den letzten 180 Tagen keine Aktivität, und wie viel Speicher belegen sie? Die Zahl zählt, nicht der Name, solange die Verbergung aktiv ist; für konkrete Maßnahmen verwendet man die Websiteliste aus dem SharePoint-Verwaltungsmodul (Modul 4.7), die immer reale Adressen enthält.

**Get-StaleSiteStats.ps1**

```powershell
param(
    [int]$InaktivTage = 180,
    [string]$Datei = ".\SiteUsage.csv"
)

Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome

Get-MgReportSharePointSiteUsageDetail -Period D180 -OutFile $Datei
$zeilen = Import-Csv -Path $Datei | Where-Object { $_.'Is Deleted' -ne 'True' }
if (-not $zeilen) { throw "Keine Websites im Bericht." }

$grenze = (Get-Date).AddDays(-$InaktivTage).Date
$alt = foreach ($z in $zeilen) {
    $d = $null
    $hatDatum = [datetime]::TryParse($z.'Last Activity Date', [ref]$d)
    if (-not $hatDatum -or $d -lt $grenze) { $z }
}

$gb = ($alt | Measure-Object -Property 'Storage Used (Byte)' -Sum).Sum / 1GB
"Websites gesamt:            {0}" -f @($zeilen).Count
"Ohne Aktivitaet seit {0} Tagen: {1} ({2:P0})" -f $InaktivTage, @($alt).Count, (@($alt).Count / @($zeilen).Count)
"Belegter Speicher dort:     {0:N1} GB" -f $gb
```

Das Skript liest den Websitebericht, entfernt gelöschte Websites und bestimmt eine Grenze (heute minus 180 Tage). Eine Website gilt als alt, wenn sie kein Aktivitätsdatum hat oder das Datum vor der Grenze liegt. Danach summiert es den belegten Speicher mit `Measure-Object` und gibt Anzahl, Anteil und Gigabyte aus. Solche Zahlen überzeugen eine Leitung eher als ein Appell zum Aufräumen. Die Konstante `1GB` rechnet Byte in Gigabyte um.

### Typische Fehler und Stolperfallen.

Ein typischer Fehler ist, Inaktivität mit Wertlosigkeit gleichzusetzen: Archivwebsites und Compliance-Ablagen sind legitim ruhig. Zweitens werden Nutzungsdaten für Leistungsbeurteilungen verwendet, was datenschutzrechtlich problematisch ist und Vertrauen zerstört. Drittens werden Zahlen aus unterschiedlichen Berichten vermischt, die verschiedene Definitionen von „aktiv“ haben. Viertens wird der Zeitraum der Berichte nicht beachtet (D180 ist das Maximum), sodass längere Ruhephasen nicht erkennbar sind.

**Falsch und richtig: Zweck begrenzen**

```powershell
# FALSCH: Aktivitaet je Person als Rangliste veroeffentlichen
Import-Csv .\ActiveUserDetail.csv | Sort-Object 'Teams Last Activity Date' | Select-Object -First 20

# RICHTIG: aggregierte Zahlen je Dienst, ohne Personenbezug
$z = Import-Csv .\ActiveUserDetail.csv
"Teams-aktiv: {0} von {1}" -f @($z | Where-Object 'Teams Last Activity Date').Count, @($z).Count
```

Die korrekte Variante liefert dieselbe Erkenntnis (Akzeptanz von Teams) ohne Rangliste von Personen. Aggregation ist das einfachste Mittel der Datensparsamkeit.

### Praxisbezug.

Vereinbaren Sie mit Datenschutz und Arbeitnehmervertretung, welche Auswertungen in welcher Detailtiefe erlaubt sind, und dokumentieren Sie diese in einer kurzen Berichtsrichtlinie. Das schafft Sicherheit für alle und beschleunigt künftige Projekte.

## 9.3 Purview Reports

Das Purview-Portal bündelt die Berichte, die zeigen, ob Schutz und Compliance wirken. Dazu gehören die Übersicht zur Datenklassifizierung (wie viele Elemente tragen welche Labels), der Aktivitäts-Explorer (welche Aktionen mit beschrifteten Inhalten fanden statt), der Inhalts-Explorer (in welchen Dateien liegen sensible Inhalte), die Berichte zu DLP (Richtlinientreffer, Überschreibungen, Fehlalarme), die Auswertungen zur Aufbewahrung (Labelverwendung) sowie die Compliance-Manager-Bewertung und die Berichte zum Insider-Risikomanagement. Welche Berichte zur Verfügung stehen, hängt von Lizenzen und aktivierten Funktionen ab.

Die Berichte beantworten typischerweise vier Governance-Fragen. Erstens: Wird klassifiziert? Der Anteil beschrifteter Dateien an allen Dateien ist die wichtigste Kennzahl der Informationsschutz-Einführung. Zweitens: Wird geschützt? Die Zahl der DLP-Treffer und deren Ausgang (blockiert, überschrieben, nur protokolliert) zeigt, ob Regeln wirken oder nur Lärm machen. Drittens: Wird aufbewahrt und entsorgt? Die Zahl der Elemente mit Aufbewahrungslabel, die ablaufenden Fristen und die Prüfaufträge zur Entsorgung. Viertens: Sind wir nachweisfähig? Der Score im Compliance Manager und die Zahl offener Maßnahmen.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu den Auditlösungen lassen sich Aktivitäten rund um Labels und DLP auch im Überwachungsprotokoll finden und dort mit dem Cmdlet oder der Suche auswerten (Lerneinheit 7.1). Die Berichte und Explorer im Purview-Portal haben eigene Datenaufbewahrungsfristen und sind nicht in allen Fällen mit dem Überwachungsprotokoll deckungsgleich. Planen Sie deshalb für Nachweiszwecke eine regelmäßige Sicherung der relevanten Kennzahlen (Lerneinheit 9.8). Die Namen der Operationen im Protokoll sollten Sie an einem kleinen Zeitfenster ohne Filter nachprüfen, weil sie sich von den Bezeichnungen in den Berichten unterscheiden können; die im folgenden Skript verwendeten Namen sind Beispiele und wurden nicht gegen einen Tenant geprüft.

Neben der Oberfläche brauchen Governance-Teams Zahlen, die sie selbst weiterverarbeiten. Das Skript zählt Label-Aktivitäten der letzten sieben Tage aus dem Überwachungsprotokoll und fasst sie nach Operation zusammen. Es zeigt, wie viele Labels angewendet, geändert oder entfernt wurden, und eignet sich als Wochenindikator. Die Operationsnamen sind als Liste hinterlegt, damit man sie leicht anpasst. Treffer ab 5000 werden gemeldet, weil dann die Zahl unvollständig sein kann.

**Get-LabelActivity.ps1**

```powershell
param([int]$Tage = 7)

Connect-ExchangeOnline

$ops   = "SensitivityLabelApplied", "SensitivityLabelUpdated", "SensitivityLabelRemoved",
         "FileSensitivityLabelApplied", "FileSensitivityLabelChanged", "FileSensitivityLabelRemoved"
$ende  = (Get-Date).ToUniversalTime()
$start = $ende.AddDays(-$Tage)

$treffer = Search-UnifiedAuditLog -StartDate $start -EndDate $ende -Operations $ops `
    -ResultSize 5000 -SessionId ("lbl-" + (Get-Date -Format yyyyMMddHHmmss)) -SessionCommand ReturnLargeSet

if (-not $treffer) { Write-Host "Keine Label-Aktivitaet gefunden (Operationsnamen pruefen)."; return }

$treffer | Group-Object Operations | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

if (@($treffer).Count -ge 5000) {
    Write-Warning "5000 Treffer erreicht: Zeitraum verkleinern, die Zahl ist moeglicherweise unvollstaendig."
}
```

Die Operationsliste fasst mögliche Namen für Dateilabels zusammen; welche in Ihrem Tenant vorkommen, ergibt sich aus der Ausgabe. Das Skript gruppiert die Treffer nach Operation und sortiert absteigend. Die Warnung am Ende schützt vor der Fehlinterpretation einer gekappten Treffermenge. Zusammen mit einem Gesamtbestand (zum Beispiel aus dem Websiteinventar der Lerneinheit 6.7) ergibt sich der Anteil beschrifteter Inhalte.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Berichte zu betrachten, ohne eine Erwartung zu haben: Wer nicht weiß, welcher Anteil beschrifteter Dateien nach drei Monaten sinnvoll ist, kann das Ergebnis nicht bewerten. Zweitens werden Pilot- und Produktivdaten gemischt. Drittens wird die Verzögerung der Berichte nicht beachtet: Die Zahlen von gestern sind unvollständig. Viertens werden einzelne Auffälligkeiten ohne Untersuchung weitergegeben („100 DLP-Treffer!“), obwohl die Mehrzahl ein einziges Fehlalarmmuster ist.

**Falsch und richtig: Trefferzahl pruefen**

```powershell
# FALSCH: Anzahl ausgeben, ohne die Grenze zu bedenken
(Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)).Count

# RICHTIG: Zeitraum eingrenzen, ResultSize setzen, Grenze pruefen
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -ResultSize 5000
if (@($r).Count -ge 5000) { Write-Warning "Grenze erreicht" }
```

Die Kontrolle der Grenze ist eine Gewohnheit, die man in jedes Auswertungsskript einbaut. Eine gekappte Zahl sieht aus wie ein Ergebnis und ist keines.

### Praxisbezug.

Fragen Sie Compliance, welche drei Purview-Zahlen sie monatlich sehen will, und bauen Sie genau diese. Mehr als fünf Kennzahlen pro Bereich liest niemand. Jede Zahl bekommt einen Verantwortlichen, der sie erklären kann.

## 9.4 Defender Reports

Der Defender-Bereich liefert Berichte aus drei Blickwinkeln. Der erste betrifft E-Mail und Zusammenarbeit: Berichte zum Bedrohungsschutz (blockierte Schadsoftware, Phishing, Spam), zum Nachrichtenfluss, zu den meistangegriffenen Benutzern und zu kompromittierten Konten. Der zweite betrifft Geräte: Gesundheit und Konformität von Endpunkten, Sicherheitsempfehlungen, Schwachstellen. Der dritte betrifft Vorfälle und Warnungen: wie viele Vorfälle entstehen, wie lange dauert ihre Bearbeitung, welche Quellen liefern die meisten. Hinzu kommt der Secure Score (Lerneinheit 8.1).

Aus Governance-Sicht interessieren drei Kennzahlen besonders. Die *Bearbeitungszeit* (Mean Time to Resolve, MTTR) zeigt, wie schnell Vorfälle gelöst werden. Der *Rückstand* (Backlog) zeigt, wie viele Vorfälle offen sind und wie alt sie sind. Die *Abdeckung* zeigt, welcher Anteil der Benutzer und Geräte unter dem Schutz steht. Diese Kennzahlen machen den Sicherheitsbetrieb steuerbar; ohne sie bleibt er ein Gefühl.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Berichten im Defender-Portal beschreibt Berichte zu E-Mail und Zusammenarbeit (Bedrohungsschutzstatus, Nachrichtenfluss, Spitzenwerte) sowie die Möglichkeit, Daten über die Graph-Schnittstellen für Sicherheit abzurufen. Welche Berichte verfügbar sind, hängt von den lizenzierten Defender-Produkten ab. Der Abgleich der Berichte mit den Schutzrichtlinien ist sinnvoll (Lerneinheit 8.4). Aussagen über absolute Zahlen wie die Aufbewahrungsdauer der Vorfallsdaten werden hier nicht gemacht, weil sie nicht abgerufen wurden.

Das folgende Skript liest die Vorfälle der letzten 30 Tage über Microsoft Graph und schätzt daraus die durchschnittliche Dauer zwischen Erstellung und letzter Änderung der gelösten Vorfälle. Es ist eine Näherung, denn das Feld der letzten Änderung ist nicht zwingend der Zeitpunkt der Lösung, und ein später ergänzter Kommentar verschiebt es. Für exakte Zeiten verwendet man die Metriken der Defender-Oberfläche. Die Näherung genügt, um Trends zu erkennen.

**Get-IncidentTimes.ps1**

```powershell
param([int]$Tage = 30)

Connect-MgGraph -Scopes "SecurityIncident.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddDays(-$Tage).ToString("yyyy-MM-ddTHH:mm:ssZ")
$vorfaelle = Get-MgSecurityIncident -Filter "createdDateTime ge $seit" -All
if (-not $vorfaelle) { Write-Host "Keine Vorfaelle im Zeitraum."; return }

$geloest = $vorfaelle | Where-Object Status -eq "resolved"
$offen   = $vorfaelle | Where-Object Status -ne "resolved"

"Vorfaelle gesamt:   {0}" -f @($vorfaelle).Count
"Geloest:            {0}" -f @($geloest).Count
"Offen:              {0}" -f @($offen).Count

if ($geloest) {
    $stunden = $geloest | ForEach-Object { ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours }
    "Mittlere Dauer (Naeherung): {0:N1} Stunden" -f ($stunden | Measure-Object -Average).Average
}

"--- Aelteste offene Vorfaelle ---"
$offen | Sort-Object CreatedDateTime | Select-Object -First 5 CreatedDateTime, Severity, DisplayName |
    Format-Table -AutoSize -Wrap
```

Das Skript trennt gelöste und offene Vorfälle, zählt sie und berechnet für gelöste die Dauer in Stunden. Die Mittelwertbildung geschieht mit `Measure-Object -Average`. Zum Schluss zeigt es die fünf ältesten offenen Vorfälle, die der Betrieb zuerst ansehen sollte. Wegen der Näherung weist man in Berichten ausdrücklich auf die Berechnungsart hin.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, eine niedrige Zahl von Vorfällen als gutes Zeichen zu werten: Sie kann auch bedeuten, dass Erkennung fehlt. Zweitens wird die Bearbeitungszeit ohne Schweregrad betrachtet; ein Mittelwert über alles verwischt, dass kritische Fälle langsam sein können. Drittens werden Berichte verschiedener Produkte nebeneinandergestellt, ohne die Definitionen zu vergleichen. Viertens bleibt der Rückstand unbeachtet.

**Falsch und richtig: nach Schweregrad auswerten**

```powershell
# FALSCH: ein Mittelwert fuer alles
($vorfaelle | ForEach-Object { ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours } |
   Measure-Object -Average).Average

# RICHTIG: je Schweregrad
$vorfaelle | Group-Object Severity | ForEach-Object {
  [pscustomobject]@{ Schweregrad = $_.Name; Anzahl = $_.Count
    MittelStd = [math]::Round(($_.Group | ForEach-Object {
        ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours } | Measure-Object -Average).Average, 1) }
}
```

Die Aufteilung nach Schweregrad zeigt, ob die wichtigen Fälle schnell genug bearbeitet werden. Legen Sie Zielwerte je Schweregrad fest (zum Beispiel kritische Vorfälle am selben Tag) und berichten Sie die Abweichung.

### Praxisbezug.

Der Sicherheitsbericht für die Leitung enthält höchstens eine Seite: Secure Score mit Verlauf, Anzahl und Bearbeitungszeit der Vorfälle, Abdeckung von MFA und Gerätekonformität, drei offene Risiken mit Maßnahmen. Alles andere gehört in den Anhang.

## 9.5 Entra Monitoring

Microsoft Entra ID zeichnet auf, was im Verzeichnis geschieht, und stellt diese Aufzeichnungen in mehreren Protokollen bereit. Die *Anmeldeprotokolle* (Sign-in Logs) zeigen jede Anmeldung mit Benutzer, Anwendung, Ort, Gerät und dem Ergebnis der Richtlinien des bedingten Zugriffs; sie unterscheiden interaktive Anmeldungen von nicht interaktiven (Clients, die im Namen des Benutzers handeln), Anmeldungen von Dienstprinzipalen und von verwalteten Identitäten. Die *Überwachungsprotokolle* (Audit Logs) zeigen Änderungen am Verzeichnis: Benutzer angelegt, Rolle zugewiesen, Richtlinie geändert. Die *Bereitstellungsprotokolle* (Provisioning Logs) zeigen, was an angebundene Anwendungen synchronisiert wurde. Dazu kommen die Berichte von Identity Protection zu riskanten Benutzern und riskanten Anmeldungen.

Die wichtigste Governance-Erkenntnis steht in den Aufbewahrungsfristen. Die Protokolle bleiben in Entra nur kurz erhalten, und danach sind sie unwiederbringlich weg. Eine längere Aufbewahrung erfordert, dass man die Protokolle aktiv exportiert. Das Verfahren dafür heißt *Diagnoseeinstellungen* (Diagnostic Settings): Man leitet die Protokolle an ein Speicherkonto, an einen Log-Analytics-Arbeitsbereich, an einen Event Hub oder an eine Partnerlösung weiter. Im Log-Analytics-Arbeitsbereich lassen sich die Protokolle mit der Abfragesprache KQL durchsuchen, in Arbeitsmappen darstellen und mit Warnungen verbinden. Ein SIEM-System wie Microsoft Sentinel übernimmt dann die Korrelation.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Datenaufbewahrung in Entra nennt für Überwachungs- und Anmeldeprotokolle sieben Tage bei Entra ID Free und 30 Tage bei P1 und P2, für die Nutzung der Mehrfaktor-Authentifizierung 30 Tage, für riskante Benutzer keine zeitliche Grenze und für riskante Anmeldungen sieben (Free), 30 (P1) und 90 Tage (P2). Die Änderung einer Lizenz wirkt nicht rückwirkend: Daten, die bereits abgelaufen sind, lassen sich nicht wiederherstellen. Die Dokumentation betont außerdem, dass die Protokolle von Entra getrennt vom einheitlichen Überwachungsprotokoll in Purview sind (Lerneinheit 7.1), dessen Aufbewahrung über Purview Audit geregelt wird. Für den Download im Portal nennt die Dokumentation Richtwerte (etwa 250.000 Überwachungseinträge und 100.000 Anmeldeeinträge); größere Mengen holt man über die Schnittstelle oder die Diagnoseeinstellungen. Die Angaben können sich ändern und sind vor einer Zusage zu prüfen.

Welche Fragen sollte ein Monitoringkonzept beantworten? Erstens: Wer ändert Konfiguration (Richtlinien, Rollen, Anwendungen), und werden kritische Änderungen gemeldet? Zweitens: Gibt es Anmeldeanomalien (viele Fehlversuche, Anmeldungen aus ungewöhnlichen Ländern, unmögliche Reisen)? Drittens: Werden Notfallkonten benutzt? Viertens: Wie viele Anmeldungen scheitern an Richtlinien, und ist das erwartbar? Fünftens: Sind die Protokolle lückenlos und werden sie lange genug aufbewahrt? Für jede Frage definiert man eine Abfrage, eine Schwelle, einen Empfänger und eine Reaktion.

Zur Veranschaulichung dient die KQL-Abfrage für den Log-Analytics-Arbeitsbereich, in den die Entra-Protokolle exportiert wurden. Sie sucht alle Anmeldungen der Notfallkonten in den letzten 24 Stunden und fasst Zeitpunkt, Anwendung, Ort und Ergebnis zusammen. Aus dieser Abfrage macht man eine Warnregel, die bei jedem Treffer eine Nachricht an das Security-Team sendet; die Nutzung eines Notfallkontos ist immer ein Ereignis, das erklärt werden muss. Die Kontennamen sind Platzhalter.

**Notfallkonto-Anmeldungen (KQL)**

```
let notfallkonten = dynamic(["breakglass1@contoso.onmicrosoft.com",
                             "breakglass2@contoso.onmicrosoft.com"]);
SigninLogs
| where TimeGenerated > ago(24h)
| where UserPrincipalName in~ (notfallkonten)
| project TimeGenerated, UserPrincipalName, AppDisplayName,
          IPAddress, Location, ResultType, ConditionalAccessStatus
| order by TimeGenerated desc
```

Die Abfrage definiert zuerst eine Liste der Konten, durchsucht dann die Tabelle `SigninLogs` im gewünschten Zeitfenster und filtert mit dem Operator `in~`, der Groß- und Kleinschreibung ignoriert. `project` wählt die Spalten aus, `order by` sortiert die jüngsten Ereignisse nach oben. Die Spalte `ResultType` enthält den Fehlercode; der Wert 0 bedeutet Erfolg. Zur Regel gehört außerdem, dass der Treffer nicht still bleibt, sondern an eine Person oder ein Team geht, das tatsächlich liest.

Für die Einrichtung des Exports selbst reicht ein Aufruf der Verwaltungsschnittstelle nicht aus, da Diagnoseeinstellungen im Azure-Portal oder per Azure-CLI angelegt werden. Ein Skript, das den Zustand prüft, ob mindestens eine Diagnoseeinstellung für die Entra-Protokolle besteht, ist aber ein guter Gesundheitscheck. Das Cmdlet `Get-MgBetaAuditLogSignIn` gehört zum Beta-Modul, darum zeigt das Skript einen robusteren Weg: Es prüft, ob in den letzten 24 Stunden überhaupt Anmeldeeinträge im Tenant existieren, und meldet eine Warnung, wenn das Fenster leer ist; ein leerer Export oder eine fehlende Berechtigung fällt so sofort auf.

**Test-EntraLogFlow.ps1**

```powershell
Connect-MgGraph -Scopes "AuditLog.Read.All","Directory.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")

$signin = Get-MgAuditLogSignIn -Filter "createdDateTime ge $seit" -Top 1
$audit  = Get-MgAuditLogDirectoryAudit -Filter "activityDateTime ge $seit" -Top 1

function Ergebnis($name, $objekt) {
    "{0,-28} {1}" -f $name, $(if ($objekt) { "OK (Eintraege vorhanden)" } else { "HINWEIS: keine Eintraege in 24 h" })
}

Ergebnis "Anmeldeprotokoll" $signin
Ergebnis "Verzeichnis-Audit"  $audit

$riskant = Get-MgRiskyUser -Filter "riskState eq 'atRisk'" -ErrorAction SilentlyContinue
"Benutzer mit Risiko (atRisk): {0}" -f @($riskant).Count
```

Das Skript prüft, ob beide Protokolle in den letzten 24 Stunden mindestens einen Eintrag enthalten. In einem lebendigen Tenant ist das stets der Fall; ein leeres Ergebnis zeigt ein Berechtigungs- oder Lizenzproblem. Die Abfrage der riskanten Benutzer benötigt Entra ID P2; ohne Lizenz liefert sie einen Fehler, den `-ErrorAction SilentlyContinue` unterdrückt, sodass die Zahl dann null ist. Das ist eine Schwäche des Skripts, die man in der Auswertung bedenken muss.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Annahme, die Protokolle seien dauerhaft verfügbar. Beim ersten Vorfall nach 45 Tagen stellt man fest, dass die Daten weg sind. Zweitens werden Diagnoseeinstellungen eingerichtet, aber nie getestet. Drittens fließen die Daten in einen Arbeitsbereich, den niemand abfragt. Viertens fehlen Warnungen für die wenigen Ereignisse, die immer geprüft werden müssen (Notfallkonten, Änderungen an Rollen und Richtlinien).

**Falsch und richtig: Aenderungen an Richtlinien (KQL)**

```
// FALSCH: Alle Audit-Eintraege der Woche ansehen und nach Bauchgefuehl suchen
AuditLogs | where TimeGenerated > ago(7d)

// RICHTIG: gezielt auf Aenderungen an Conditional Access eingrenzen
AuditLogs
| where TimeGenerated > ago(7d)
| where Category == "Policy" and OperationName has "conditional access"
| project TimeGenerated, OperationName, InitiatedBy, TargetResources, Result
| order by TimeGenerated desc
```

Die gezielte Abfrage liefert genau die Ereignisse, die ein Prüfer sehen will: wer wann welche Richtlinie des bedingten Zugriffs geändert hat. Die genauen Werte der Kategorie und des Operationsnamens prüfen Sie in Ihrem Arbeitsbereich mit einer ungefilterten Stichprobe.

### Praxisbezug.

Im Projekt bildet der Export der Entra-Protokolle oft die erste Maßnahme überhaupt, weil sie billig ist und jede spätere Untersuchung ermöglicht. Legen Sie fest, wie lange die Protokolle im Arbeitsbereich bleiben (Anforderung aus Compliance und Kosten), wer abfragen darf, und welche fünf Warnungen es gibt. Beschreiben Sie das Ganze auf einer Seite im Runbook (Lerneinheit 9.7).

## 9.6 Service Health

Neben der Frage, ob die eigenen Regeln wirken, steht die Frage, ob der Dienst selbst funktioniert. Microsoft veröffentlicht im Admin Center die *Dienstintegrität* (Service Health): aktuelle Störungen (Vorfälle, englisch Incidents), Hinweise (Advisories) und deren Verlauf mit Auswirkung, Status und Updates. Daneben steht das *Nachrichtencenter* (Message Center) mit angekündigten Änderungen: neue Funktionen, Abschaltungen, notwendige Maßnahmen. Beides ist für den Betrieb unverzichtbar. Die Dienstintegrität erklärt, warum „heute alles hakt“ und ob man selbst etwas tun kann. Das Nachrichtencenter ist das Frühwarnsystem für Änderungen, die die eigene Governance betreffen, etwa wenn Microsoft eine Voreinstellung ändert.

Governance-Aufgaben dazu sind: Wer liest beides regelmäßig? Wie kommen relevante Meldungen zu den richtigen Personen (E-Mail-Benachrichtigung an eine Verteilerliste, Weiterleitung in einen Teams-Kanal oder in das Ticketsystem)? Wie wird entschieden, ob eine Änderung Maßnahmen verlangt (Bewertung, Pilot, Kommunikation)? Und wie dokumentiert man Störungen und deren Auswirkung, etwa für spätere Nachfragen der Leitung oder von Kunden?

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation lässt sich die Dienstintegrität nicht nur im Admin Center, sondern auch über Microsoft Graph abrufen (Ressourcen für Dienstankündigungen, darunter Integritätsübersichten, Störungen und Nachrichten des Nachrichtencenters), wofür besondere Berechtigungen für Dienstintegrität und Dienstnachrichten erforderlich sind. Außerdem kann man im Admin Center E-Mail-Benachrichtigungen für Störungen und Nachrichten einrichten. Welche Mandanten welche Meldungen sehen, hängt von den genutzten Diensten ab, und für jede Meldung gibt es eine Kennung, mit der man in der Kommunikation eindeutig darauf verweisen kann.

Das Skript listet die derzeit offenen Störungen des Tenants mit Dienst, Titel, Beginn und Klassifizierung auf und zeigt, wie viele Nachrichten im Nachrichtencenter in den letzten sieben Tagen erschienen sind. Es verwendet die Graph-Cmdlets für Dienstankündigungen und benötigt die Berechtigungen `ServiceHealth.Read.All` und `ServiceMessage.Read.All`. Die Ausgabe eignet sich als Morgenübersicht für den Betrieb oder als Grundlage für eine Nachricht in einen Teams-Kanal.

**Get-ServiceStatus.ps1**

```powershell
Connect-MgGraph -Scopes "ServiceHealth.Read.All","ServiceMessage.Read.All" -NoWelcome

"--- Offene Stoerungen ---"
$offen = Get-MgServiceAnnouncementIssue -Filter "isResolved eq false" -All
if ($offen) {
    $offen | Sort-Object StartDateTime -Descending |
        Select-Object Id, Service, Classification, Status, StartDateTime, Title |
        Format-Table -AutoSize -Wrap
} else {
    "Keine offenen Stoerungen gemeldet."
}

"--- Zustand je Dienst ---"
Get-MgServiceAnnouncementHealthOverview | Select-Object Service, Status | Sort-Object Service |
    Format-Table -AutoSize

$seit = (Get-Date).ToUniversalTime().AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
$nachrichten = Get-MgServiceAnnouncementMessage -Filter "lastModifiedDateTime ge $seit" -All
"Nachrichtencenter, neu oder geaendert in 7 Tagen: {0}" -f @($nachrichten).Count
$nachrichten | Where-Object { $_.IsMajorChange } |
    Select-Object Id, Title, ActionRequiredByDateTime | Format-Table -AutoSize -Wrap
```

Der erste Block holt Störungen, die noch nicht gelöst sind, und sortiert sie nach Beginn. Der zweite Block zeigt den Gesamtzustand je Dienst. Der dritte Block zählt Neuigkeiten im Nachrichtencenter und zeigt die als wesentlich markierten Änderungen mit Frist für erforderliche Maßnahmen. Das Feld `ActionRequiredByDateTime` ist besonders nützlich, denn es nennt das Datum, bis zu dem man reagieren muss.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, dass niemand zuständig ist: Das Nachrichtencenter wird nur gelesen, wenn jemand Zeit hat, und Maßnahmenfristen laufen ab. Zweitens werden Störungen im Ticketsystem als eigene Fehler bearbeitet, obwohl sie bei Microsoft liegen, und binden Kapazität. Drittens ist die Information nicht ausreichend an die Benutzer gelangt: Der Servicedesk weiß nichts von der Störung. Viertens fehlt die Auswertung: Ohne Rückblick bleibt unklar, wie oft und wie lange Dienste gestört waren.

**Falsch und richtig: Frist im Blick**

```powershell
# FALSCH: Nachrichten nur zaehlen
(Get-MgServiceAnnouncementMessage -All).Count

# RICHTIG: Nachrichten mit Frist und Handlungsbedarf anzeigen
Get-MgServiceAnnouncementMessage -All |
  Where-Object { $_.ActionRequiredByDateTime -and $_.ActionRequiredByDateTime -gt (Get-Date) } |
  Sort-Object ActionRequiredByDateTime |
  Select-Object Id, Title, ActionRequiredByDateTime
```

Die korrekte Variante macht aus einer Flut von Nachrichten eine kurze Liste mit Fristen und erlaubt, jede mit einem Verantwortlichen zu versehen.

### Praxisbezug.

Legen Sie eine wöchentliche, 15-minütige Durchsicht des Nachrichtencenters fest und führen Sie ein einfaches Register: Meldung, Relevanz, Maßnahme, Verantwortlicher, Frist. Wichtige Meldungen enden im Änderungsprozess (Modul 11) oder im Kommunikationsplan (Modul 12).

## 9.7 Operational Runbooks

Ein *Runbook* (Betriebshandbuch für einen bestimmten Ablauf) beschreibt Schritt für Schritt, wie eine wiederkehrende oder kritische Aufgabe durchgeführt wird, so dass sie auch eine andere Person als die Ersteller sicher ausführen kann. Es ist die Brücke zwischen Governance-Regel und Betriebsalltag: Die Regel sagt, was gelten soll, das Runbook sagt, wie man es erreicht oder wiederherstellt. Typische Runbooks in M365-Umgebungen sind: neues Team anlegen, Gast einladen und prüfen, Legal Hold einrichten, Notfallkonto verwenden, Störung melden, Berechtigungsreview durchführen, Offboarding.

Ein gutes Runbook hat einen festen Aufbau. Es beginnt mit Zweck und Auslöser (wann wird es verwendet?), nennt Verantwortliche und Voraussetzungen (Rollen, Zugänge, Werkzeuge), beschreibt die Schritte in nummerierter Reihenfolge mit konkreten Befehlen oder Klickpfaden, enthält die Prüfung des Ergebnisses (woran erkenne ich den Erfolg?), den Rückweg (wie mache ich es rückgängig?), die Eskalation (an wen, wenn es nicht klappt?) und ein Datum der letzten Prüfung. Das Datum ist wichtiger, als es scheint: Ein Runbook, das ein Jahr alt ist, beschreibt Oberflächen, die es nicht mehr gibt.

> **Ergänzung aus der Nachrecherche**
>
> Dieser Abschnitt beruht auf allgemeinem Fachwissen aus dem Betrieb von IT-Diensten (Informationstechnik-Bibliotheken und Betriebspraxis) und nicht auf einer abgerufenen Quelle. Aussagen zu Aufbau und Pflege von Runbooks sind Empfehlungen. Ob Ihre Organisation ein vorgegebenes Format hat, richtet sich nach dem vorhandenen Qualitätsmanagement; übernehmen Sie in dem Fall die vorhandene Vorlage.

Der Wert eines Runbooks zeigt sich in den Ausnahmesituationen: nachts, unter Druck, mit der Vertretung statt der Spezialistin. Deshalb muss es einfach sein: kurze Sätze, jeder Schritt eine Handlung, keine Annahmen über Wissen. Zugleich sollte man Runbooks nicht nur schreiben, sondern üben: Mindestens einmal pro Jahr führt jemand, der sie nicht geschrieben hat, das Runbook auf einem Testtenant aus und meldet jede Unklarheit. Aus Governance-Sicht gehört zu jedem Runbook ein Eigentümer, ein Prüfintervall und ein Ablageort mit Versionsverwaltung.

Das folgende Skript prüft einen Ordner mit Runbooks im Markdown-Format auf Vollständigkeit. Es verlangt die Überschriften Zweck, Voraussetzungen, Schritte, Prüfung, Rückweg, Eskalation und eine Zeile mit dem Datum der letzten Prüfung im Format `Letzte Pruefung: JJJJ-MM-TT`. Es meldet fehlende Abschnitte und Runbooks, deren Prüfung älter als 365 Tage ist. So wird die Pflege des Handbuchs selbst messbar. Die Überschriften sind Konvention und frei anpassbar.

**Test-Runbooks.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Ordner,
    [int]$MaxAlterTage = 365
)

$pflicht = "Zweck", "Voraussetzungen", "Schritte", "Pruefung", "Rueckweg", "Eskalation"
$dateien = Get-ChildItem -Path $Ordner -Filter *.md -File -Recurse
if (-not $dateien) { throw "Keine Runbooks in $Ordner gefunden." }

$ergebnis = foreach ($d in $dateien) {
    $text = Get-Content -Path $d.FullName -Raw -Encoding UTF8
    $fehlt = $pflicht | Where-Object { $text -notmatch "(?im)^#+\s*$_\b" }

    $alt = "kein Datum"
    if ($text -match "Letzte Pruefung:\s*(\d{4}-\d{2}-\d{2})") {
        $tage = ((Get-Date) - [datetime]::ParseExact($Matches[1], "yyyy-MM-dd", $null)).Days
        $alt  = if ($tage -gt $MaxAlterTage) { "veraltet ($tage Tage)" } else { "aktuell ($tage Tage)" }
    }

    [pscustomobject]@{
        Runbook = $d.Name
        Fehlend = if ($fehlt) { $fehlt -join ", " } else { "-" }
        Pruefung = $alt
    }
}

$ergebnis | Format-Table -AutoSize
$schlecht = $ergebnis | Where-Object { $_.Fehlend -ne "-" -or $_.Pruefung -notlike "aktuell*" }
"{0} von {1} Runbooks brauchen Pflege." -f @($schlecht).Count, @($ergebnis).Count
```

Das Skript liest jede Markdown-Datei als Ganzes und sucht mit einem regulären Ausdruck nach den Überschriften, wobei `(?im)` Groß- und Kleinschreibung ignoriert und Zeilenanfänge berücksichtigt. Das Datum wird mit einem zweiten Ausdruck gelesen und in eine Zahl von Tagen umgerechnet. Die Ergebnisliste zeigt je Runbook die fehlenden Abschnitte und den Altersstatus, und eine Zusammenfassung gibt die Zahl der pflegebedürftigen Dokumente aus. Diese Zahl ist zugleich eine Kennzahl für die Governance-Reife.

### Typische Fehler und Stolperfallen.

Typische Fehler sind Runbooks ohne Rückweg, Runbooks mit Zugangsdaten im Klartext, Runbooks, die nur im Kopf der Spezialistin existieren, und Runbooks, die nach dem Schreiben nie wieder geöffnet wurden. Ebenfalls häufig: ein langer Fließtext statt nummerierter Schritte, den in der Störung niemand liest.

**Falsch und richtig: Zugangsdaten im Runbook**

```powershell
# FALSCH (im Runbook): Kennwort steht im Text
#   Schritt 3: Melden Sie sich mit admin@contoso.com und dem Kennwort "Sommer2026!" an.

# RICHTIG: auf den Tresor verweisen, Zugriff protokolliert
#   Schritt 3: Holen Sie die Zugangsdaten des Notfallkontos aus dem Passwort-Tresor
#   (Eintrag "M365 Notfallkonto 1"). Der Zugriff wird protokolliert; melden Sie die Nutzung an security@contoso.com.
```

Das Beispiel zeigt die Grundregel: Ein Runbook beschreibt, wo Geheimnisse liegen, und enthält sie nicht selbst. Sonst wird das Handbuch zum sensibelsten Dokument der Organisation.

### Praxisbezug.

Beginnen Sie mit den fünf Aufgaben, die am häufigsten oder mit der größten Wirkung vorkommen. Ein kurzes, geprüftes Runbook ist mehr wert als zwanzig unfertige. Bauen Sie das Prüfen in den Rhythmus ein: Das Skript oben läuft quartalsweise und erzeugt die Liste der zu pflegenden Dokumente.

## 9.8 Governance KPIs

Eine *Kennzahl* (Key Performance Indicator, KPI) ist eine Zahl, die einen für das Ziel wichtigen Zustand misst und zu einer Entscheidung führt. Das ist anspruchsvoller, als es klingt. Eine Zahl, die man nur zur Kenntnis nimmt („wir haben 4.200 Teams“), ist eine Messgröße, noch keine Kennzahl. Eine Kennzahl hat einen Zielwert, eine Schwelle, die Handeln auslöst, einen Verantwortlichen und eine Datenquelle. „Anteil der Teams mit mindestens zwei Besitzern: Ziel 98 Prozent, Alarm unter 90, Verantwortlich Teams-Betrieb, Quelle: Graph-Abfrage monatlich“ ist eine Kennzahl.

Gute Governance-Kennzahlen verteilen sich auf die Themen des Kurses. Zur Identität: Anteil der Benutzer mit MFA, Anteil phishing-resistenter Anmeldungen bei Administratoren, Zahl der Gastkonten ohne Aktivität. Zu Zusammenarbeit: Anteil der Teams und Websites mit mindestens zwei Besitzern, mit Label, mit Ablaufdatum, Zahl inaktiver Websites. Zu Daten: Anteil beschrifteter Inhalte, DLP-Treffer und deren Ausgang. Zur Sicherheit: Secure Score, Zahl und Bearbeitungsdauer von Vorfällen, Gerätekonformität. Zur Compliance: offene Maßnahmen im Compliance Manager, Zahl abgelaufener Ausnahmen, Alter der Runbooks. Zum Betrieb: Zahl der Tickets zu Governance-Themen, Dauer bis zur Bereitstellung eines Teams.

> **Ergänzung aus der Nachrecherche**
>
> Dieser Abschnitt beruht auf allgemeinem Fachwissen zu Kennzahlensystemen (Zieldefinition, Schwellenwerte, Verantwortliche) und nicht auf einer abgerufenen Quelle. Die genannten Kennzahlen sind Vorschläge für die Auswahl; ihre Datenquellen sind in den vorangehenden Modulen beschrieben (Secure Score in Lerneinheit 8.1, MFA-Abdeckung in 8.3, Besitzer von Teams in Modul 3, Labels in Modul 6). Für die Darstellung können Sie die Berichtsdaten in Power BI einbinden; die Datenschutzeinstellung der Berichte (Lerneinheit 9.1) gilt auch dort.

Die Auswahl ist wichtiger als die Anzahl. Eine Faustregel lautet: höchstens zehn Kennzahlen für die Leitung, höchstens je fünf pro Fachbereich. Jede Kennzahl braucht eine Definition, die niemand missversteht (was zählt als „Besitzer“?), und eine Regel für den Umgang mit Ausnahmen (Archivwebsites zählen nicht als inaktiv). Wer Kennzahlen als Druckmittel gegen Einzelne verwendet, bekommt geschönte Zahlen; wer sie als gemeinsame Orientierung verwendet, bekommt ehrliche.

Technisch lässt sich ein Kennzahlensystem klein halten: Eine Definitionsdatei (JSON) beschreibt Kennzahl, Zielwert, Alarmschwelle und Richtung („mehr ist besser“ oder „weniger ist besser“). Ein Sammelskript trägt die gemessenen Werte ein, bewertet sie mit einer Ampel (grün, gelb, rot) und schreibt eine Ergebnisdatei mit Datum. Die Werte kommen aus den Skripten der vorherigen Lerneinheiten. Die folgende Definitionsdatei zeigt drei Beispielkennzahlen mit Zielwerten, die Beispiele sind und von Ihrer Organisation festgelegt werden müssen.

**kpi-definition.json**

```json
[
  { "id": "mfa-abdeckung",    "name": "Benutzer mit MFA (Prozent)",
    "ziel": 98, "alarm": 90, "richtung": "hoeher", "verantwortlich": "Identity-Team" },
  { "id": "teams-2-besitzer", "name": "Teams mit mindestens 2 Besitzern (Prozent)",
    "ziel": 98, "alarm": 90, "richtung": "hoeher", "verantwortlich": "Teams-Betrieb" },
  { "id": "vorfaelle-offen",  "name": "Offene Sicherheitsvorfaelle (Anzahl)",
    "ziel": 5, "alarm": 15, "richtung": "niedriger", "verantwortlich": "Security-Betrieb" }
]
```

Jede Definition hat eine Kennung, einen lesbaren Namen, den Zielwert und die Alarmschwelle, die Richtung der Verbesserung und einen Verantwortlichen. Bei der Richtung „höher“ ist grün, wenn der Wert das Ziel erreicht oder überschreitet, und rot, wenn er unter die Alarmschwelle fällt; bei „niedriger“ gilt das Spiegelbild. Dazwischen liegt gelb. Das Skript, das diese Definition einliest, nimmt die gemessenen Werte als Hashtable entgegen und gibt die bewertete Tabelle aus. Die Werte stammen aus den Messskripten oder werden vorerst von Hand eingetragen.

**Get-KpiStatus.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Definition,
    [Parameter(Mandatory)][hashtable]$Werte,
    [string]$Verlauf = ".\kpi-verlauf.csv"
)

$kpis = Get-Content -Path $Definition -Raw -Encoding UTF8 | ConvertFrom-Json

$ergebnis = foreach ($k in $kpis) {
    if (-not $Werte.ContainsKey($k.id)) {
        Write-Warning "Kein Messwert fuer $($k.id)"
        continue
    }
    $w = [double]$Werte[$k.id]
    $status =
        if ($k.richtung -eq "hoeher") {
            if ($w -ge $k.ziel) { "gruen" } elseif ($w -lt $k.alarm) { "rot" } else { "gelb" }
        } else {
            if ($w -le $k.ziel) { "gruen" } elseif ($w -gt $k.alarm) { "rot" } else { "gelb" }
        }
    [pscustomobject]@{
        Datum = (Get-Date -Format "yyyy-MM-dd"); Kennzahl = $k.name
        Wert = $w; Ziel = $k.ziel; Alarm = $k.alarm; Status = $status
        Verantwortlich = $k.verantwortlich
    }
}

$ergebnis | Format-Table -AutoSize
$ergebnis | Export-Csv -Path $Verlauf -Append -NoTypeInformation -Encoding UTF8
"{0} Kennzahlen bewertet, {1} rot." -f @($ergebnis).Count, @($ergebnis | Where-Object Status -eq "rot").Count
```

Das Skript liest die Definition als JSON-Objekte, prüft für jede Kennzahl, ob ein Messwert vorliegt, und bewertet nach der Richtung. Die Auswertung wird an eine Verlaufsdatei angehängt; daraus entsteht eine Zeitreihe, die man in Power BI oder Excel darstellt. Der Aufruf lautet zum Beispiel mit einer Hashtable `@{ 'mfa-abdeckung' = 94; 'teams-2-besitzer' = 91 }`. Die Zahl der roten Kennzahlen am Ende gehört in jedes Management-Briefing.

### Typische Fehler und Stolperfallen.

Typisch sind zu viele Kennzahlen, Kennzahlen ohne Zielwert, Kennzahlen, deren Definition sich unbemerkt ändert, und Zahlen, die nur zur Beruhigung dienen. Ein verbreiteter Fehler ist, Zahlen ohne Kontext zu berichten: Eine Abdeckung von 94 Prozent ist erfreulich oder bedenklich, je nachdem, ob das Ziel 90 oder 99 lautet. Auch die Vermischung von Aktivitätszahlen (was wir getan haben) und Wirkungszahlen (was sich verbessert hat) kommt häufig vor.

**Falsch und richtig: Bewertung statt Zahl**

```powershell
# FALSCH: nur den Rohwert melden
"MFA-Abdeckung: 94 Prozent"

# RICHTIG: Wert mit Ziel, Schwelle, Status und Verantwortlichem
.\Get-KpiStatus.ps1 -Definition .\kpi-definition.json -Werte @{ 'mfa-abdeckung' = 94 }
# Ergebnis: 94 / Ziel 98 / Alarm 90 -> gelb, Verantwortlich: Identity-Team
```

Die bewertete Ausgabe macht die Zahl entscheidungsfähig: gelb heißt, es besteht Handlungsbedarf unterhalb der Alarmschwelle. Besprechen Sie gelbe und rote Kennzahlen monatlich im Governance-Gremium und halten Sie Maßnahmen fest.

### Praxisbezug.

Ein monatliches Governance-Briefing von 30 Minuten mit einer Seite Kennzahlen (Ampeln, Verlauf, drei Maßnahmen) hält das Thema in der Leitung präsent. Es verbindet alle Module dieses Kurses: Die Kennzahlen stammen aus den Betriebsprozessen, die Maßnahmen aus Risiko und Compliance, und die Entscheidungen fließen in die Roadmap (Modul 12).

> **Merke**
>
> Berichte beantworten „Was ist?“, Kennzahlen beantworten „Müssen wir handeln?“. Erst mit Zielwert, Schwelle und Verantwortlichem wird aus einer Zahl ein Steuerungsinstrument. Und weil Berichte Personendaten enthalten, ist die Datensparsamkeit Teil der Qualität.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Welche Zeiträume bieten die Nutzungsberichte, und was bedeutet es, dass Benutzernamen standardmäßig verborgen sind? Wer darf das ändern, und was geschieht dabei?

**Aufgabe 2 (leicht).** Nennen Sie die Aufbewahrungsfristen der Anmelde- und Überwachungsprotokolle in Entra ID Free und in P1 und P2, und erklären Sie, wie man sie länger aufbewahrt.

**Aufgabe 3 (leicht).** Worin unterscheiden sich die Dienstintegrität und das Nachrichtencenter, und wofür braucht der Betrieb jeweils eine verantwortliche Person?

**Aufgabe 4 (mittel).** Schreiben Sie ein Skript, das den Benutzerdetailbericht herunterlädt und den Anteil der Konten berechnet, die in den letzten 30 Tagen in Teams aktiv waren.

**Aufgabe 5 (mittel).** Entwerfen Sie ein Runbook „Gast einladen und prüfen“ in der sechsteiligen Gliederung dieses Kurses (Zweck, Voraussetzungen, Schritte, Prüfung, Rückweg, Eskalation) mit Datum der letzten Prüfung.

**Aufgabe 6 (mittel).** Formulieren Sie eine KQL-Abfrage, die fehlgeschlagene Anmeldungen der letzten 24 Stunden je Benutzer zählt und Benutzer mit mehr als 20 Fehlversuchen anzeigt. Erklären Sie die Bestandteile.

**Aufgabe 7 (schwer).** Erweitern Sie das Skript zur Bewertung der Kennzahlen so, dass es zusätzlich eine Textdatei im Markdown-Format mit einer Tabelle der Kennzahlen erzeugt, in der rote Kennzahlen zuerst stehen.

**Aufgabe 8 (schwer).** Entwerfen Sie ein Kennzahlensystem mit acht Kennzahlen für die Governance einer Organisation mit 1.500 Beschäftigten. Geben Sie je Kennzahl Definition, Zielwert, Alarmschwelle, Datenquelle und Verantwortlichen an, und beschreiben Sie, wie Sie Datenschutz und Betriebsrat einbinden.

## Lösungen

**Lösung 1.** Die Berichte bieten die Zeiträume 7, 30, 90 und 180 Tage. Standardmäßig sind Benutzer-, Gruppen- und Websitenamen verborgen (als Hashwerte), um den Datenschutz zu unterstützen. Ein globaler Administrator kann die Einstellung in den Organisationseinstellungen ändern; das Anzeigen identifizierbarer Informationen wird im Überwachungsprotokoll festgehalten. Die Entscheidung gehört deshalb mit Datenschutz abgestimmt.

**Lösung 2.** Überwachungs- und Anmeldeprotokolle bleiben bei Entra ID Free sieben Tage und bei P1 und P2 30 Tage erhalten. Längere Aufbewahrung erreicht man durch Diagnoseeinstellungen, die die Protokolle an ein Speicherkonto, einen Log-Analytics-Arbeitsbereich oder einen Event Hub senden. Die Änderung einer Lizenz wirkt nicht rückwirkend; abgelaufene Daten sind verloren.

**Lösung 3.** Die Dienstintegrität zeigt aktuelle Störungen und Hinweise zum Dienst; das Nachrichtencenter kündigt Änderungen an, teilweise mit Handlungsfrist. Der Betrieb braucht für die Dienstintegrität jemanden, der Störungen einordnet und die Kommunikation steuert, und für das Nachrichtencenter jemanden, der Änderungen bewertet, Maßnahmen anstößt und Fristen verfolgt.

**Lösung 4.** Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome
Get-MgReportOffice365ActiveUserDetail -Period D30 -OutFile .\aktiv30.csv
$z = Import-Csv .\aktiv30.csv | Where-Object 'Is Deleted' -ne 'True'
if ('Teams Last Activity Date' -notin $z[0].PSObject.Properties.Name) { throw "Spalte fehlt" }
$grenze = (Get-Date).AddDays(-30).Date
$aktiv = $z | Where-Object {
  $d = $null
  [datetime]::TryParse($_.'Teams Last Activity Date', [ref]$d) -and $d -ge $grenze
}
"{0} von {1} ({2:P0}) in Teams aktiv" -f @($aktiv).Count, @($z).Count, (@($aktiv).Count / @($z).Count)
```

Das Skript lädt den 30-Tage-Bericht, entfernt gelöschte Konten, prüft die Spalte, wandelt das Datum um und zählt Konten mit Aktivität nach der Grenze. Der Anteil wird als Prozentwert ausgegeben.

**Lösung 5.** Ein Beispiel: Zweck: Externe Person kontrolliert in die Zusammenarbeit aufnehmen. Voraussetzungen: Rolle zur Einladung, Genehmigung des Verantwortlichen, Ausnahmeprüfung. Schritte: (1) Antrag prüfen, (2) Einladung über den vorgesehenen Weg senden, (3) Zugriffspaket oder Teammitgliedschaft zuweisen, (4) Ablaufdatum setzen. Prüfung: Gast erscheint mit korrektem Status und minimalen Rechten, Anmeldung klappt. Rückweg: Gastkonto aus Gruppe entfernen, bei Bedarf Konto löschen. Eskalation: bei Anmeldeproblemen an das Identity-Team, bei Sicherheitsverdacht an Security. Letzte Prüfung: ein konkretes Datum im Format JJJJ-MM-TT.

**Lösung 6.** Ein Lösungsvorschlag:

```
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != "0"
| summarize Fehlversuche = count() by UserPrincipalName
| where Fehlversuche > 20
| order by Fehlversuche desc
```

Die Abfrage filtert die letzten 24 Stunden und alle Anmeldungen mit Ergebnis ungleich 0 (Fehler), zählt sie je Benutzer mit `summarize`, behält nur Benutzer mit mehr als 20 Versuchen und sortiert absteigend. Bei vielen Fehlversuchen für viele Konten von einer Adresse spricht man von Passwort-Spraying; deshalb lohnt eine zweite Abfrage nach IP-Adresse.

**Lösung 7.** Ein Ansatz: Nach der Bewertung die Ergebnisse nach Status sortieren (rot, gelb, grün über eine Sortierhilfe) und mit einer Schleife Zeilen im Markdown-Tabellenformat erzeugen:

```powershell
$rang = @{ rot = 0; gelb = 1; gruen = 2 }
$zeilen = $ergebnis | Sort-Object { $rang[$_.Status] }, Kennzahl |
  ForEach-Object { "| {0} | {1} | {2} | {3} | {4} |" -f $_.Kennzahl, $_.Wert, $_.Ziel, $_.Status, $_.Verantwortlich }
@("| Kennzahl | Wert | Ziel | Status | Verantwortlich |", "|---|---|---|---|---|") + $zeilen |
  Set-Content -Path ".\kpi-bericht.md" -Encoding UTF8
```

Die Hashtable `$rang` ordnet den Status einer Zahl zu, die Sortierung stellt rote Kennzahlen nach oben. Die Kopfzeilen und die Datenzeilen werden zu einer Datei zusammengesetzt.

**Lösung 8.** Ein Beispiel: (1) MFA-Abdeckung, Ziel 98, Alarm 90, Quelle Registrierungsbericht, Identity-Team. (2) Teams mit zwei Besitzern, Ziel 98, Alarm 90, Quelle Graph, Teams-Betrieb. (3) Websites ohne Aktivität über 180 Tage, Ziel unter 10, Alarm über 20, Quelle Websitebericht, SharePoint-Betrieb. (4) Anteil beschrifteter Inhalte, Ziel 70 nach 12 Monaten, Alarm 40, Quelle Label-Aktivität und Inventar, Compliance. (5) Secure Score, Ziel nach Roadmap, Quelle Graph, Security. (6) Offene Sicherheitsvorfälle über 7 Tage, Ziel 0, Alarm 5, Quelle Vorfälle, Security-Betrieb. (7) Abgelaufene Ausnahmen, Ziel 0, Alarm 3, Quelle Ausnahmenregister, Security. (8) Runbooks älter als 365 Tage, Ziel 0, Alarm 3, Quelle Runbook-Prüfung, IT-Governance. Datenschutz und Betriebsrat: Kennzahlen sind aggregiert und ohne Personenbezug; Zweck und Datenquellen werden in einer Berichtsrichtlinie festgehalten und mit der Arbeitnehmervertretung abgestimmt, bevor die Verbergung der Namen in den Berichten aufgehoben wird (keine Rechtsberatung).
