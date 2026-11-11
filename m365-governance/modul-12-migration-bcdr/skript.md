# Modul 12 - Migration, Kosten, Adoption und BCDR

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 9 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8 Stunden (8 × 1). Die Differenz von einer Stunde wird hier nicht als eigene Lerneinheit ausgewiesen, sondern als Übungs- und Vertiefungszeit verstanden; als Richtwert für den Umfang wurde der höhere Wert (9 Stunden) verwendet.  
**Priorität:** 2 (mittlere Priorität)

| **Nr.** | **Lerneinheit**              | **Dauer (h)** | **Prio** |
|:--------|:-----------------------------|--------------:|---------:|
| 12.1    | Ist-Analyse                  |             1 |        1 |
| 12.2    | Governance Maturity          |             1 |        1 |
| 12.3    | Kostenmodell                 |             1 |        1 |
| 12.4    | Adoption und Change          |             1 |        1 |
| 12.5    | Training und Champions       |             1 |        1 |
| 12.6    | BCDR für M365 Governance     |             1 |        2 |
| 12.7    | Kontinuierliche Verbesserung |             1 |        2 |
| 12.8    | 30-60-90-Tage-Roadmap        |             1 |        2 |
|         | **Summe laut Details**       |         **8** |          |
|         | **Dauer laut Modulblatt**    |         **9** |          |

> **Merke: Hinweis zum Titel „Migration“**
>
> Das Blatt „Lehrplan in Details“ enthält für dieses Modul keine eigene Lerneinheit zur Migration von Daten (zum Beispiel von Dateiservern oder fremden Mailsystemen nach Microsoft 365). Der Modulname nennt sie dennoch. Dieses Modul behandelt die Migration deshalb dort, wo sie für die Governance-Einführung eine Rolle spielt: in der Ist-Analyse (Lerneinheit 12.1), die den Bestand und die Altlasten erfasst, in der Roadmap (Lerneinheit 12.8) und in der Kostenbetrachtung (Lerneinheit 12.3). Eine technische Migrationsanleitung ist nicht Teil dieses Skripts.

Die Module 1 bis 11 beschreiben, wie ein Tenant gut verwaltet wird. Dieses Modul beantwortet die Frage, wie man dorthin kommt, wie man es bezahlt, wie man die Menschen mitnimmt und wie man dafür sorgt, dass es auch nach einem Ausfall oder Angriff weiterläuft. Es ist das Modul für die Einführung: Der beste Standard nützt nichts, wenn er nicht angenommen, nicht finanziert oder nach dem ersten Vorfall nicht wiederherstellbar ist. Die technischen Beispiele zeigen Messungen und Auswertungen; sie wurden nicht gegen einen echten Tenant ausgeführt.

## 12.1 Ist-Analyse

Bevor man Governance einführt, muss man wissen, wo man steht. Die *Ist-Analyse* erfasst den Bestand und den Zustand eines Tenants: Wie viele Benutzer, Gäste, Gruppen, Teams und Websites gibt es? Wer besitzt sie? Was ist inaktiv oder verwaist? Wo sind Daten zu weit freigegeben? Welche Richtlinien existieren, welche Lizenzen sind vergeben, welche Dienste werden genutzt? Die Ist-Analyse hat zwei Zwecke. Sie liefert die Ausgangswerte, an denen man später den Fortschritt misst (Modul 9.8), und sie zeigt die dringendsten Risiken, an denen die Roadmap (Lerneinheit 12.8) ansetzt.

Eine gute Ist-Analyse trennt vier Ebenen. Die erste ist der *Bestand*: Zählungen und Listen. Die zweite ist die *Konfiguration*: Welche Einstellungen gelten, und wie weichen sie von einem Zielbild ab (Modul 11.3 und 11.5)? Die dritte ist die *Nutzung*: Was wird tatsächlich gebraucht (Modul 9.2)? Die vierte ist die *Organisation*: Wer ist zuständig, welche Prozesse gibt es, welche Rollen sind besetzt? Die vierte Ebene lässt sich nicht aus dem Tenant lesen, sondern nur in Gesprächen erheben. Sie ist oft die wichtigste, weil Technik ohne Zuständigkeit nicht wirkt.

> **Ergänzung aus der Nachrecherche**
>
> Für die Ebene der Freigaben und Berechtigungen bietet Microsoft in der SharePoint-Verwaltung die Berichte zur Datenzugriffs-Governance (Data access governance) an. Nach der Dokumentation unterscheidet man *Momentaufnahmeberichte* (zum Beispiel Websiteberechtigungen der Organisation, Websiteberechtigungen für einzelne Benutzer, Beschriftungen für Dateien) und *Aktivitätsberichte* für die letzten 28 Tage (Freigabelinks, Freigaben für „Alle außer externen Benutzern“). Die Dokumentation empfiehlt, die Momentaufnahmen vierteljährlich und die Aktivitätsberichte monatlich auszuführen. Die Berichte setzen die Voraussetzungen von SharePoint Advanced Management voraus; für Organisationen mit Microsoft-365-E5-Lizenz, aber ohne diese Verwaltungsfunktionen, gibt es eingeschränkte Berichte, und für Aktivitätsberichte muss die Datensammlung zunächst aktiviert werden, wonach die Daten 28 Tage vorgehalten werden und der Bericht erst nach 24 Stunden verfügbar ist. Wenn die Anzeige verborgener Benutzer-, Gruppen- und Websitenamen in den Berichtseinstellungen nicht angepasst ist, können die Berichte nach der Dokumentation unter Umständen nicht funktionieren (Modul 9.1). Zur Nacharbeit nennt die Dokumentation die Überprüfung durch Websitebesitzer (Websitezugriffsüberprüfung), die für bis zu 100 Websites direkt aus dem Bericht und für mehr Websites per PowerShell angestoßen werden kann, sowie den eingeschränkten Zugriff als Sofortmaßnahme. Für die Berichte per PowerShell nennt die Dokumentation das Modul `Microsoft.Online.SharePoint.PowerShell` und den Befehl `Start-SPODataAccessGovernanceInsight`; für den Bericht zu Dateien und Ordnern, die über die speziellen Gruppen „Alle außer externen Benutzern“ oder „Alle“ freigegeben sind, wird eine Mindestversion des Moduls und die Rolle „SharePoint Advanced Management Administrator“ genannt.

Für den Bestand an Benutzern und Gruppen genügen einfache Zählungen über Microsoft Graph. Das folgende Skript erstellt daraus einen Kurzbericht im Markdown-Format, den man als Anlage zum Ist-Analyse-Bericht verwenden kann. Es zählt Benutzer, Gäste und Microsoft-365-Gruppen, ermittelt den Anteil der Gruppen ohne Besitzer und schreibt das Ergebnis mit Datum in eine Datei. Das Datum ist wichtig, weil die Zahl allein ohne Zeitbezug wenig aussagt: Der Wert gilt als Ausgangswert („Baseline“) für spätere Vergleiche.

**Get-TenantBaseline.ps1**

```powershell
param([string]$Ausgabe = (".\ist-analyse-{0}.md" -f (Get-Date -Format "yyyy-MM-dd")))

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All" -NoWelcome

$benutzer = Get-MgUserCount -ConsistencyLevel eventual
$gaeste   = Get-MgUserCount -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$gruppen  = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName

$ohneBesitzer = 0
foreach ($g in $gruppen) {
    if (@(Get-MgGroupOwner -GroupId $g.Id).Count -eq 0) { $ohneBesitzer++ }
}
$anteil = if ($gruppen.Count -gt 0) { $ohneBesitzer / $gruppen.Count } else { 0 }

$zeilen = @(
    "# Ist-Analyse (Bestand) vom $(Get-Date -Format 'yyyy-MM-dd')",
    "",
    "| Kennzahl | Wert |",
    "|---|---|",
    "| Benutzer | $benutzer |",
    "| Gaeste | $gaeste |",
    "| Microsoft-365-Gruppen | $($gruppen.Count) |",
    ("| Gruppen ohne Besitzer | $ohneBesitzer ({0:P0}) |" -f $anteil)
)
$zeilen | Set-Content -Path $Ausgabe -Encoding UTF8
Get-Content $Ausgabe
```

Das Skript fordert nur Leserechte an. Die Zählungen über `Get-MgUserCount` verwenden die Ebene „eventual“ der Abfragekonsistenz, die Graph für Zählungen im Verzeichnis verlangt. Danach geht es durch alle Microsoft-365-Gruppen und zählt die ohne Besitzer. Bei vielen Gruppen ist das langsam; dann nutzt man die Stapelabfrage aus Modul 11.1. Das Ergebnis ist eine kleine Datei mit Datum im Namen, die man in das Repository (Modul 11.3) legt. Die letzte Tabellenzeile steht in Klammern, weil der Formatoperator `-f` sonst auf die ganze Liste statt nur auf diese Zeichenfolge wirken würde; solche Feinheiten der Rangfolge von Operatoren sind eine häufige Fehlerquelle.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, die Ist-Analyse als reine Technikübung zu sehen. Ohne Gespräche mit Fachbereichen bleibt unklar, welche der „inaktiven“ Websites aufbewahrt werden müssen. Zweitens wird der Bericht zu lang: Eine Analyse mit 80 Befunden ohne Priorisierung führt zu keiner Handlung. Drittens fehlt der Zeitbezug, und niemand kann später Fortschritt belegen. Viertens werden Nutzerdaten mit Personenbezug ausgewertet, ohne Datenschutz und Betriebsrat einzubeziehen (keine Rechtsberatung: Klären Sie das mit den zuständigen Stellen).

**Falsch und richtig: Befunde bewerten**

```powershell
# FALSCH: nur Liste ausgeben, keine Einordnung
$gruppenOhneBesitzer | Format-Table

# RICHTIG: Befund mit Risiko, Aufwand und Verantwortlichem einordnen
$gruppenOhneBesitzer | Select-Object DisplayName,
    @{n="Risiko";e={ if ($_.Visibility -eq "Public") {"hoch"} else {"mittel"} }},
    @{n="Aufwand";e={"gering"}},
    @{n="Verantwortlich";e={"Teams-Betrieb"}} |
    Export-Csv -Path .\befunde.csv -NoTypeInformation -Encoding UTF8
```

Die zweite Fassung macht aus der Liste eine Entscheidungsgrundlage: Sie ergänzt Risiko, Aufwand und Zuständigkeit. In einem echten Bericht werden diese Spalten gemeinsam mit den Fachbereichen festgelegt, nicht vom Skript geraten.

### Praxisbezug.

Planen Sie für die Ist-Analyse zwei bis vier Wochen ein. Beginnen Sie mit den automatischen Berichten, führen Sie parallel Interviews mit Fachbereichen, Datenschutz, Informationssicherheit und Betriebsrat, und verdichten Sie das Ergebnis auf höchstens zehn priorisierte Befunde. Achten Sie dabei besonders auf Altlasten, die bei früheren Migrationen von anderen Systemen entstanden sind: alte Verteilerlisten, Dateiablagen mit offenen Berechtigungen und doppelte Strukturen.

## 12.2 Governance Maturity

Ein *Reifegradmodell* (Maturity Model) beschreibt Stufen, auf denen eine Organisation ein Thema beherrscht, von „ungeregelt“ bis „optimiert“. Es dient dazu, den eigenen Stand einzuordnen, sich ein realistisches Ziel zu setzen und den Weg dorthin in Etappen zu planen. Für die Governance von Microsoft 365 ist ein solches Modell hilfreich, weil die Themen sehr unterschiedlich weit sind: Eine Organisation kann bei Identität sehr reif sein und bei Datenklassifizierung kaum begonnen haben. Ein Gesamtwert hilft wenig, wichtig ist das Profil über die Bereiche hinweg.

Die Stufen in diesem Kurs sind ein eigenes, einfaches Modell und kein Standard von Microsoft oder einer Normungsstelle. Stufe 1 heißt *ad hoc*: Es gibt keine festen Regeln, Einzelne entscheiden von Fall zu Fall. Stufe 2 heißt *wiederholbar*: Einzelne Regeln und Abläufe bestehen, hängen aber von Personen ab. Stufe 3 heißt *definiert*: Regeln, Rollen und Prozesse sind dokumentiert und verbindlich. Stufe 4 heißt *gesteuert*: Die Einhaltung wird gemessen, Abweichungen werden verfolgt (Modul 9.8, 11.5). Stufe 5 heißt *optimiert*: Erkenntnisse aus Messung und Vorfällen verbessern die Regeln fortlaufend (Lerneinheit 12.7). Für jeden Bereich dieses Kurses (die Module 1 bis 11) beschreibt man, woran man jede Stufe erkennt.

> **Ergänzung aus der Nachrecherche**
>
> Zum Reifegrad gibt es in diesem Kurs keine abgerufene Quelle; das Modell ist ein didaktisches Hilfsmittel. Es gibt veröffentlichte Reifegradmodelle für Cloud-Einführung und für Datenschutz-/Sicherheitsmanagement (zum Beispiel in der Cloud-Adoption-Framework-Dokumentation von Microsoft), die als weiterführende Lektüre dienen können; ihre Inhalte wurden hier nicht geprüft und sind eigenständig zu bewerten. Verwenden Sie das Modell nicht als Prüfnachweis, sondern als Gesprächsgrundlage. Wenn Sie für eine Zertifizierung oder Prüfung ein bestimmtes Modell nachweisen müssen, verwenden Sie das von der Prüfstelle verlangte.

Die Bewertung selbst geschieht in einem Workshop mit den Verantwortlichen der Bereiche. Für jeden Bereich werden Ist-Stufe und Ziel-Stufe festgelegt, mit einer kurzen Begründung. Aus dem Unterschied ergibt sich die Lücke, und aus der Lücke zusammen mit der Wichtigkeit des Bereichs die Priorität. Das folgende Skript wertet eine solche Bewertung aus einer CSV-Datei aus: Es berechnet die Lücke je Bereich, gewichtet sie mit der Wichtigkeit und gibt eine geordnete Prioritätenliste aus. Die Datei hat die Spalten Bereich, Ist, Ziel und Gewicht (1 bis 3).

**Get-MaturityPriorities.ps1**

```powershell
param([Parameter(Mandatory)][string]$Datei)

$zeilen = Import-Csv -Path $Datei -Delimiter ";"
if (-not $zeilen) { throw "Die Datei enthaelt keine Zeilen." }

$ergebnis = foreach ($z in $zeilen) {
    $ist = [int]$z.Ist; $ziel = [int]$z.Ziel; $gewicht = [int]$z.Gewicht
    if ($ist -lt 1 -or $ist -gt 5 -or $ziel -lt 1 -or $ziel -gt 5) {
        throw "Ungueltige Stufe bei '$($z.Bereich)': Werte muessen zwischen 1 und 5 liegen."
    }
    if ($ziel -lt $ist) { Write-Warning "Ziel unter Ist bei '$($z.Bereich)'." }
    $luecke = [math]::Max(0, $ziel - $ist)
    [pscustomobject]@{
        Bereich   = $z.Bereich
        Ist       = $ist
        Ziel      = $ziel
        Luecke    = $luecke
        Prioritaet = $luecke * $gewicht
    }
}

$ergebnis | Sort-Object Prioritaet -Descending | Format-Table -AutoSize
$mittel = ($ergebnis | Measure-Object Ist -Average).Average
"Durchschnittliche Ist-Stufe: {0:N1} (Hinweis: Das Profil ist aussagekraeftiger als der Durchschnitt.)" -f $mittel
```

Das Skript liest die Bewertung, prüft die Wertebereiche und berechnet für jeden Bereich die Lücke zwischen Ziel- und Ist-Stufe. Die Priorität ist das Produkt aus Lücke und Gewicht: Ein Bereich mit großer Lücke und hoher Wichtigkeit steht oben. Die Warnung bei einem Ziel unter dem Ist-Wert fängt Eingabefehler ab. Am Ende steht der Durchschnitt, mit dem Hinweis, dass das Profil wichtiger ist. Das Ergebnis ersetzt keine Entscheidung, sondern bereitet sie vor.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, die höchste Stufe überall anzustreben. Stufe 5 ist teuer, und für viele Bereiche genügt Stufe 3. Zweitens bewerten sich Teams zu optimistisch, wenn niemand Belege verlangt; für jede Einstufung sollte ein Nachweis (Dokument, Bericht, Prozess) genannt werden. Drittens wird die Bewertung einmal gemacht und nie wiederholt. Viertens wird der Durchschnitt zur Kennzahl erklärt und verdeckt kritische Lücken.

**Falsch und richtig: Nachweis verlangen**

```powershell
# FALSCH: Einstufung ohne Beleg akzeptieren
$bewertung = [pscustomobject]@{ Bereich = "Identitaet"; Ist = 4 }

# RICHTIG: Beleg zur Einstufung verlangen
$bewertung = [pscustomobject]@{ Bereich = "Identitaet"; Ist = 4; Beleg = "Zugriffsueberpruefung 2026-Q3, Bericht liegt im Repository" }
if (-not $bewertung.Beleg) { throw "Einstufung ohne Beleg nicht zulaessig." }
```

Die zweite Fassung zwingt zu einem Nachweis. Damit wird aus dem Reifegrad eine überprüfbare Aussage, die bei einem Audit vorgelegt werden kann.

### Praxisbezug.

Führen Sie die Bewertung jährlich mit denselben Fragen durch, damit die Ergebnisse vergleichbar bleiben. Nutzen Sie das Profil für die Roadmap (Lerneinheit 12.8) und für die Gespräche mit der Geschäftsleitung: Ein Profil mit drei roten Bereichen ist verständlicher als eine lange Liste technischer Befunde.

## 12.3 Kostenmodell

Governance kostet Geld, und sie spart Geld. Ein *Kostenmodell* stellt beides gegenüber, damit Entscheidungen auf Zahlen beruhen. Die Kosten setzen sich aus mehreren Blöcken zusammen: Lizenzen (Basislizenzen und Zusatzlizenzen für Sicherheit und Compliance), nutzungsabhängige Dienste (Speicher über dem Kontingent, Sicherung, Archiv), Werkzeuge von Drittanbietern, Betrieb (Personal, Dienstleister) und Einführung (Schulung, Beratung, Projektzeit). Der Nutzen ist schwerer zu messen und besteht aus eingesparten Lizenzen und Speicher, vermiedenen Vorfällen, kürzeren Bereitstellungszeiten und geringerem Prüfungsaufwand.

Wichtig ist die Unterscheidung zwischen fixen und variablen Kosten. Lizenzen hängen von der Zahl der Beschäftigten ab, Speicher und Sicherung vom Datenwachstum, Personalkosten von der Reife der Automatisierung. Wer Governance einführt, verschiebt Kosten: Schulung und Werkzeuge kosten zu Beginn, die Einsparungen zeigen sich später. Das Kostenmodell muss deshalb einen Zeitverlauf enthalten, mindestens über drei Jahre.

> **Ergänzung aus der Nachrecherche**
>
> Für nutzungsabhängige Dienste nennt die Microsoft-Dokumentation zu den Pay-as-you-go-Diensten in Microsoft 365 unter anderem: Microsoft 365 Backup (Abrechnung nach Menge der gesicherten Daten), SharePoint-Speicher und OneDrive-Speicher (Abrechnung nach tatsächlichem Verbrauch über dem Kontingent des Tenants beziehungsweise über den enthaltenen Grenzen). Nach der Dokumentation zu Microsoft 365 Archive wird eine archivierte Website in eine kostengünstigere Speicherebene verschoben, belegt keinen aktiven SharePoint-Speicher mehr und behält Inhalt, Berechtigungen und Metadaten; die Kosten der Archivierung werden über die nutzungsabhängige Abrechnung berechnet. In den Neuerungen zu Microsoft 365 Backup ist beschrieben, dass sich Kosten über Azure-Kostendaten zuordnen lassen (für SharePoint und OneDrive pro Schutzeinheit über ein Etikett) und dass mehrere Abrechnungsrichtlinien verbunden werden können, um die Kosten auf Azure-Abonnements zu verteilen. Konkrete Preise nennt dieses Skript nicht, weil sie sich ändern, vertraglich unterschiedlich sind und regional abweichen; verwenden Sie für Berechnungen Ihre eigenen Vertragspreise.

Aus der Zuordnung von Kosten ergibt sich ein Organisationsthema: Wer trägt sie? Beim *Showback* zeigt man den Fachbereichen ihre Kosten an, ohne sie zu belasten. Beim *Chargeback* werden sie verrechnet. Showback ist der übliche Anfang, weil es das Bewusstsein schafft, ohne Verteilungsstreit. Voraussetzung ist, dass Kosten Fachbereichen zuordenbar sind, was bei Speicher und Sicherung über die Metadaten der Arbeitsbereiche (Modul 10.5, Abteilung oder Kostenstelle) möglich ist.

Das folgende Skript berechnet aus einer Verbrauchsdatei einen Showback-Bericht. Die Datei enthält je Zeile eine Abteilung und die genutzten Gigabyte Speicher und gesicherten Gigabyte. Die Preise je Gigabyte und Monat werden als Parameter übergeben, es sind keine Preise im Skript fest eingebaut, und das Skript weist Kosten für den Speicher über dem freien Kontingent anteilig zu. So lässt sich dasselbe Skript mit den Preisen des eigenen Vertrags betreiben.

**New-ShowbackReport.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Verbrauch,       # CSV: Abteilung;SpeicherGB;SicherungGB
    [Parameter(Mandatory)][decimal]$FreiesKontingentGB,
    [Parameter(Mandatory)][decimal]$PreisSpeicherProGBMonat,
    [Parameter(Mandatory)][decimal]$PreisSicherungProGBMonat,
    [string]$Ausgabe = ".\showback.csv"
)

$daten = Import-Csv -Path $Verbrauch -Delimiter ";"
if (-not $daten) { throw "Keine Verbrauchsdaten." }

$gesamtSpeicher = ($daten | ForEach-Object { [decimal]$_.SpeicherGB } | Measure-Object -Sum).Sum
$ueber = [math]::Max(0, $gesamtSpeicher - $FreiesKontingentGB)
$anteilUeber = if ($gesamtSpeicher -gt 0) { $ueber / $gesamtSpeicher } else { 0 }

$bericht = foreach ($z in $daten) {
    $sp = [decimal]$z.SpeicherGB
    $si = [decimal]$z.SicherungGB
    $kostenSpeicher  = [math]::Round($sp * $anteilUeber * $PreisSpeicherProGBMonat, 2)
    $kostenSicherung = [math]::Round($si * $PreisSicherungProGBMonat, 2)
    [pscustomobject]@{
        Abteilung = $z.Abteilung; SpeicherGB = $sp; SicherungGB = $si
        KostenSpeicher = $kostenSpeicher; KostenSicherung = $kostenSicherung
        Summe = $kostenSpeicher + $kostenSicherung
    }
}

$bericht | Sort-Object Summe -Descending | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$bericht | Sort-Object Summe -Descending | Format-Table -AutoSize
"Gesamt pro Monat: {0:N2}" -f ($bericht | Measure-Object Summe -Sum).Sum
```

Das Skript nimmt Verbrauch, freies Kontingent und die beiden Preise als Parameter. Es berechnet, welcher Anteil des Gesamtspeichers über dem freien Kontingent liegt, und verteilt die Kosten für den Mehrverbrauch im Verhältnis des Speichers der Abteilungen. Die Sicherungskosten werden direkt aus den gesicherten Gigabyte berechnet. Der Bericht wird sortiert, als CSV gespeichert und zeigt am Ende die Gesamtsumme je Monat. Die Verteilung nach Anteil ist eine Vereinfachung; wenn die Abrechnung auf Schutzeinheiten genau zugeordnet werden kann, ist die direkte Zuordnung vorzuziehen.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist, nur die Lizenzkosten zu betrachten und die Betriebskosten zu vergessen: Eine günstige Lizenz hilft wenig, wenn niemand sie konfiguriert und betreibt. Zweitens werden Einsparungen versprochen, die nicht eintreten, weil die Daten nach Archivierung weiter aufbewahrt werden müssen. Drittens ändert sich der Preis während der Laufzeit, und das Modell wird nicht angepasst. Viertens werden Kosten pauschal verteilt, so dass die Fachbereiche sie nicht beeinflussen können.

**Falsch und richtig: Preise nicht fest einbauen**

```powershell
# FALSCH: Preis im Skript, veraltet nach der naechsten Vertragsaenderung
$kosten = $gb * 0.20

# RICHTIG: Preis als Parameter oder Konfigurationswert mit Datum
$konfig = Get-Content .\preise.json -Raw -Encoding UTF8 | ConvertFrom-Json
if ([datetime]$konfig.gueltigBis -lt (Get-Date)) { Write-Warning "Preisliste abgelaufen: $($konfig.gueltigBis)" }
$kosten = $gb * [decimal]$konfig.speicherProGBMonat
```

Die zweite Fassung liest die Preise aus einer Datei mit Gültigkeitsdatum und warnt, wenn sie abgelaufen ist. Die Zahlen gehören in die Datei, nicht in den Code und nicht in dieses Skript.

### Praxisbezug.

Erstellen Sie vor dem Governance-Projekt ein einfaches Dreijahresmodell mit Kosten und erwartetem Nutzen, und legen Sie die Annahmen offen. Zeigen Sie den Fachbereichen zunächst im Showback ihre Kosten, bevor Sie verrechnen. Beachten Sie bei Archiv und Löschung die Aufbewahrungspflichten (Modul 6.3): Eine Einsparung durch Löschen ist nur zulässig, wenn keine Pflicht entgegensteht (keine Rechtsberatung).

## 12.4 Adoption und Change

*Adoption* bedeutet, dass Beschäftigte die vereinbarten Arbeitsweisen tatsächlich anwenden. *Change Management* (Veränderungsmanagement) ist die Disziplin, die dafür sorgt, dass das geschieht. Beides ist bei Governance besonders wichtig, weil Governance den Beschäftigten zunächst etwas wegnimmt oder erschwert: Sie dürfen nicht mehr jedes Team selbst anlegen, müssen Dokumente beschriften, bekommen Hinweise zu externen Absendern. Ohne gute Begründung und Begleitung entsteht Widerstand, und der äußert sich nicht in offener Ablehnung, sondern in Umgehung: private Messenger, externe Speicherdienste, E-Mail-Anhänge statt Links. Damit wird die Governance ausgehebelt, ohne dass ein einziger Alarm ausgelöst wird.

Der Kern guter Einführung ist, den Nutzen für die Betroffenen sichtbar zu machen. „Dokumente sind jetzt beschriftet“ ist ein Ziel der Organisation; „Sie können Dokumente künftig mit zwei Klicks sicher an Kunden senden“ ist ein Nutzen für die Person. Der zweite Satz überzeugt. Ein bewährtes Vorgehen gliedert sich in vier Phasen: Verstehen (Wer ist betroffen, welche Ängste und Gewohnheiten gibt es?), Vorbereiten (Kommunikation, Schulung, Unterstützung), Einführen (in Wellen, mit Pilotgruppen) und Verankern (Rückmeldung, Anpassung, Erfolge zeigen). Die Einführung in Wellen ist wichtig: Eine Pilotgruppe findet die Fehler, bevor alle sie erleben.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Einführungsprogrammen betont mehrere Punkte, die sich auf die Governance übertragen lassen. In den Hinweisen zum Aufbau von Communities heißt es, dass Führungskräfte, die Werkzeuge sichtbar selbst nutzen und darüber sprechen, ein starker Treiber der Annahme sind und dass Schulung dieses Vorbild nicht ersetzt; die Führungskräfte sollten dieselbe Schulung und Unterstützung erhalten wie die übrigen Beteiligten. Rückmeldungen sollten laufend gesammelt (Umfragen, Sprechstunden, Community-Kanäle) und umgesetzt werden; wenn eine Anleitung verwirrt, soll sie verbessert und die Rückmeldung an die Personen zurückgespielt werden. Erfolge sollen sichtbar gemacht und Beteiligte gewürdigt werden, wobei die Sichtbarkeit durch die Leitung oft Anerkennung genug ist. Diese Aussagen stammen aus Leitfäden zu Copilot Studio, Power Platform und Teams-Einführung; sie sind übertragbare Praxisempfehlungen, keine Anforderungen an Microsoft-365-Governance im engeren Sinn.

Adoption lässt sich messen, wenn man sie in konkrete Verhaltensweisen übersetzt: Wie viele Beschäftigte nutzen Teams statt E-Mail-Verteilern? Wie hoch ist der Anteil der Dokumente mit Beschriftung? Wie viele Arbeitsbereiche entstehen über die Bereitstellungsfabrik (Modul 10.1) und wie viele außerhalb davon? Aus dem Auswertungsbericht zur Nutzung (Modul 9.2) lässt sich zum Beispiel ableiten, in welchen Abteilungen ein Dienst kaum genutzt wird. Das folgende Skript führt die Aktivitätsdaten des Benutzerberichts mit der Abteilung aus dem Verzeichnis zusammen und berechnet je Abteilung den Anteil der Aktiven in Teams und Exchange in den letzten 30 Tagen. Es setzt voraus, dass der Bericht bereits als CSV vorliegt (Modul 9.2) und dass die Benutzernamen im Bericht nicht verborgen sind; bei verborgenen Namen schlägt die Zusammenführung fehl, weil die Namen im Bericht durch Kennungen ersetzt sind, was das Skript erkennt und meldet.

**Get-AdoptionByDepartment.ps1**

```powershell
param([Parameter(Mandatory)][string]$Bericht, [int]$Tage = 30)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

$aktivitaet = Import-Csv -Path $Bericht
if (-not $aktivitaet) { throw "Der Bericht ist leer." }
if ("User Principal Name" -notin $aktivitaet[0].PSObject.Properties.Name) { throw "Spalte 'User Principal Name' fehlt." }

$verzeichnis = @{}
Get-MgUser -All -Property UserPrincipalName,Department,AccountEnabled |
    Where-Object AccountEnabled | ForEach-Object { $verzeichnis[$_.UserPrincipalName.ToLower()] = $_.Department }

$treffer = @($aktivitaet | Where-Object { $verzeichnis.ContainsKey($_.'User Principal Name'.ToLower()) }).Count
if ($treffer -eq 0) {
    throw "Kein Benutzername aus dem Bericht im Verzeichnis gefunden. Sind Benutzernamen im Bericht verborgen?"
}

$grenze = (Get-Date).AddDays(-$Tage).Date
function Test-Aktiv($text) {
    $d = $null
    [datetime]::TryParse($text, [ref]$d) -and $d -ge $grenze
}

$ergebnis = $aktivitaet |
    Where-Object { $_.'Is Deleted' -ne 'True' -and $verzeichnis.ContainsKey($_.'User Principal Name'.ToLower()) } |
    ForEach-Object {
        $abt = $verzeichnis[$_.'User Principal Name'.ToLower()]
        if ([string]::IsNullOrWhiteSpace($abt)) { $abt = "(ohne Abteilung)" }
        [pscustomobject]@{
            Abteilung = $abt
            Teams     = Test-Aktiv $_.'Teams Last Activity Date'
            Exchange  = Test-Aktiv $_.'Exchange Last Activity Date'
        }
    } | Group-Object Abteilung | ForEach-Object {
        $n = $_.Count
        [pscustomobject]@{
            Abteilung = $_.Name; Benutzer = $n
            TeamsAktiv    = "{0:P0}" -f (@($_.Group | Where-Object Teams).Count / $n)
            ExchangeAktiv = "{0:P0}" -f (@($_.Group | Where-Object Exchange).Count / $n)
        }
    }

$ergebnis | Sort-Object Abteilung | Format-Table -AutoSize
```

Das Skript prüft zuerst die Eingabedatei und lädt die Abteilungen aller aktiven Konten in eine Hashtabelle. Findet es keinen einzigen Benutzernamen des Berichts im Verzeichnis, bricht es mit dem Hinweis auf verborgene Namen ab, damit kein leerer Bericht entsteht. Die Hilfsfunktion `Test-Aktiv` prüft, ob das Datum der letzten Aktivität innerhalb der letzten 30 Tage liegt. Für jede Abteilung zählt das Skript die aktiven Personen in Teams und Exchange und gibt die Anteile aus. Konten ohne Abteilung werden gesondert ausgewiesen, weil sie bereits ein Datenqualitätsproblem anzeigen (Modul 10.5). Beachten Sie den Datenschutz: Auswertungen auf Ebene einzelner Personen sind sensibel, Abteilungswerte mit sehr wenigen Personen können Einzelne erkennbar machen (Betriebsrat und Datenschutz einbeziehen, keine Rechtsberatung).

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Adoption mit Information zu verwechseln: Eine Rundmail ist keine Einführung. Zweitens wird nur Technik eingeführt, ohne Unterstützung im Alltag (kurze Anleitungen, Sprechstunden). Drittens werden Pilotgruppen nach Bequemlichkeit gewählt, nicht nach Vielfalt, und die Probleme der übrigen Bereiche zeigen sich erst im Betrieb. Viertens wird Widerstand als Dummheit abgetan, statt die zugrunde liegende Sorge zu verstehen, zum Beispiel Angst vor Kontrolle.

**Falsch und richtig: Kleine Gruppen schuetzen**

```powershell
# FALSCH: Abteilungswerte auch bei 1-2 Personen veroeffentlichen
$ergebnis | Format-Table

# RICHTIG: Gruppen unter einer Mindestgroesse zusammenfassen
$mindest = 5
$ergebnis | Where-Object { $_.Benutzer -ge $mindest } | Format-Table
$klein = @($ergebnis | Where-Object { $_.Benutzer -lt $mindest })
if ($klein.Count -gt 0) { "Zusammengefasst: {0} Abteilungen mit weniger als {1} Personen." -f $klein.Count, $mindest }
```

Mit einer Mindestgröße werden keine Einzelpersonen erkennbar. Der Wert 5 ist ein Beispiel; die Mindestgröße legen Datenschutz und Arbeitnehmervertretung fest.

### Praxisbezug.

Planen Sie die Einführung jeder Governance-Maßnahme mit einer kurzen Mitteilung (Was ändert sich, warum, ab wann, wo gibt es Hilfe), einer Pilotphase und einer Auswertung nach vier Wochen. Binden Sie Betriebsrat und Datenschutz früh ein, wenn Auswertungen das Verhalten von Beschäftigten betreffen. Verfolgen Sie die Umgehung als Kennzahl: Wenn Teams außerhalb der Fabrik entstehen, ist die Fabrik zu langsam oder zu kompliziert.

## 12.5 Training und Champions

Schulung ist der zweite Pfeiler der Einführung. Sie muss auf die Zielgruppe zugeschnitten sein: Beschäftigte brauchen kurze, praktische Hinweise (Wie beschrifte ich ein Dokument? Wie erkenne ich eine externe Mail?), Teambesitzer brauchen mehr (Mitglieder verwalten, Ablauf erneuern, Gäste einladen), Administratoren brauchen Tiefe (Richtlinien, Skripte, Fehlersuche). Eine einzige Schulung für alle ist für niemanden passend. Bewährt sind kurze Formate (zehn bis fünfzehn Minuten), die unmittelbar vor oder bei der Anwendung kommen, ergänzt durch eine zentrale Seite mit Anleitungen und Antworten auf häufige Fragen.

*Champions* sind Beschäftigte in den Fachbereichen, die sich für das Thema begeistern und Kollegen helfen, ohne dass es ihre Hauptaufgabe ist. Sie sind der wirksamste Hebel für Adoption, weil Kollegen ihnen mehr vertrauen als einer Zentrale, und sie kennen die Sprache und die Arbeitsabläufe ihres Bereichs. Ein Champions-Programm besteht aus einer Auswahl (Freiwillige mit Zeit und Ansehen), einer Schulung, einem regelmäßigen Austausch, einem kurzen Draht zur Zentrale und einer Anerkennung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Aufbau eines Champions-Programms für Microsoft Teams beschreibt Champions als Personen, die vor allem von dem Wunsch getragen sind, anderen zu helfen, sich für die Technik interessieren und Kolleginnen und Kollegen im Sinne der bewährten Verfahren der Organisation unterstützen. Champions sollen formell geschult, ermutigt und befähigt werden, Kollegen anzuleiten, laufend positive Bestätigung erhalten und einen klaren Plan haben. Als bewährte Praktiken nennt die Dokumentation unter anderem regelmäßige monatliche Treffen (in Präsenz oder virtuell, Beständigkeit sei entscheidend), einen eigenen Teams-Kanal oder ein Team für die Programmkommunikation, klare Anforderungen an die Teilnahme (zum Beispiel Teilnahme an Treffen, Sprechstunden, Schulung neuer Benutzer), sichtbare Würdigung der Champions und frühe, wiederholte Schulung. Für größere Gemeinschaften wird in der Dokumentation zu Copilot Studio ein Stufenmodell beschrieben, in dem erfahrene Champions Sprechstunden leiten, Veranstaltungen organisieren und später die Koordination der Gemeinschaft übernehmen, damit das Programm nicht von wenigen Personen abhängt. Auch hier gilt: Die Leitfäden stammen aus anderen Produktbereichen und sind für Governance übertragbare Praxis.

Ein Champions-Programm braucht eine Abdeckung: Jede Abteilung sollte mindestens einen Champion haben, große Abteilungen mehrere. Eine Faustregel ist ein Champion je 30 bis 50 Beschäftigte; sie ist eine Erfahrungsgröße und kein Standard, und der passende Wert hängt von Arbeitsweise und Standorten ab. Das folgende Skript prüft die Abdeckung: Es liest die Liste der Champions (eine CSV mit der Abteilung) und vergleicht sie mit der Zahl der aktiven Beschäftigten je Abteilung aus dem Verzeichnis. Abteilungen, die unter dem Zielwert liegen, werden mit der Anzahl der fehlenden Champions ausgegeben.

**Test-ChampionCoverage.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Champions,      # CSV: Name;Abteilung
    [int]$BeschaeftigtePorChampion = 40
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

$champ = Import-Csv -Path $Champions -Delimiter ";" | Group-Object Abteilung -AsHashTable -AsString
if (-not $champ) { $champ = @{} }

$bestand = Get-MgUser -All -Property Department,AccountEnabled,UserType |
    Where-Object { $_.AccountEnabled -and $_.UserType -eq "Member" -and $_.Department } |
    Group-Object Department

$luecken = foreach ($abt in $bestand) {
    $ist = if ($champ.ContainsKey($abt.Name)) { @($champ[$abt.Name]).Count } else { 0 }
    $soll = [math]::Max(1, [math]::Ceiling($abt.Count / $BeschaeftigtePorChampion))
    if ($ist -lt $soll) {
        [pscustomobject]@{ Abteilung = $abt.Name; Beschaeftigte = $abt.Count; Champions = $ist; Soll = $soll; Fehlend = $soll - $ist }
    }
}

if ($luecken) { $luecken | Sort-Object Fehlend -Descending | Format-Table -AutoSize }
else { "Alle Abteilungen erreichen die Zielabdeckung." }
```

Das Skript liest die Champions und gruppiert sie nach Abteilung, damit man sie direkt nachschlagen kann. Aus dem Verzeichnis nimmt es aktive Mitglieder (keine Gäste) mit gepflegter Abteilung und gruppiert sie ebenfalls. Der Sollwert je Abteilung ist die aufgerundete Zahl der Beschäftigten geteilt durch die Zielgröße, mindestens jedoch ein Champion. Ausgegeben werden nur die Abteilungen mit Lücke, sortiert nach der Zahl der fehlenden Champions. Der Parameter für die Zielgröße lässt sich an die Organisation anpassen.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Champions zu ernennen, statt Freiwillige zu gewinnen: Wer es nicht will, tut es nicht. Zweitens bekommen Champions mehr Arbeit, aber keine Zeit und keine Anerkennung; die Motivation sinkt. Drittens fehlt ein Nachfolgeplan, und das Programm hängt an wenigen Personen. Viertens bleibt das Programm einseitig, ein Champion lehrt nur, ohne die Rückmeldungen aus dem Bereich in die Zentrale zu tragen.

**Falsch und richtig: Wirkung messen**

```powershell
# FALSCH: Erfolg des Programms nur an der Zahl der Champions messen
"Wir haben 25 Champions."

# RICHTIG: Wirkung in den betreuten Bereichen vergleichen
# Beispiel: Anteil aktiver Teams-Nutzer mit/ohne Champion in der Abteilung
$mitChampion  = $ergebnis | Where-Object { $_.Abteilung -in $championAbteilungen }
$ohneChampion = $ergebnis | Where-Object { $_.Abteilung -notin $championAbteilungen }
"mit: {0}, ohne: {1}" -f $mitChampion.Count, $ohneChampion.Count
```

Die richtige Fassung vergleicht Abteilungen mit und ohne Champion. Vorsicht bei der Deutung: Ein Unterschied muss nicht durch das Programm entstanden sein, denn motivierte Bereiche stellen eher Champions. Es handelt sich um einen Hinweis, nicht um einen Beweis.

### Praxisbezug.

Starten Sie mit einer kleinen Gruppe von zehn bis zwanzig Champions in verschiedenen Bereichen. Geben Sie ihnen früh Zugang zu Neuerungen, laden Sie sie monatlich zu einer halbstündigen Runde ein, und nutzen Sie ihre Rückmeldungen zur Verbesserung der Standards. Würdigen Sie sie sichtbar; die Anerkennung durch die Leitung wirkt oft stärker als materielle Anreize.

## 12.6 BCDR für M365 Governance

BCDR steht für Business Continuity and Disaster Recovery: die Fähigkeit, nach einer Störung, einem Fehler oder einem Angriff den Geschäftsbetrieb fortzuführen (Business Continuity) und die Systeme und Daten wiederherzustellen (Disaster Recovery). Für Microsoft 365 betrifft das mehrere Ebenen. Die Plattform selbst ist redundant aufgebaut, aber sie schützt nicht vor allem: nicht vor versehentlichem Löschen durch Benutzer, nicht vor Verschlüsselung durch Schadsoftware, nicht vor Fehlkonfigurationen durch Administratoren und nicht vor dem Verlust des Zugangs zum Tenant selbst. Für die Governance stehen zwei Fragen im Vordergrund: Welche Daten und Einstellungen müssen wir wiederherstellen können, und in welcher Zeit?

Zwei Kennzahlen machen die Anforderung greifbar. Das *Recovery Point Objective* (RPO) beschreibt, wie viel Datenverlust akzeptabel ist, gemessen als Zeitspanne zwischen dem letzten Wiederherstellungspunkt und dem Ereignis. Das *Recovery Time Objective* (RTO) beschreibt, wie lange die Wiederherstellung höchstens dauern darf. Beide werden je Datenklasse festgelegt: Für die Finanzbuchhaltung gelten strengere Werte als für ein Wiki. Aus ihnen folgt, welche Mechanismen nötig sind.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt mehrere ineinandergreifende Schutzschichten. Für Microsoft Entra ID gilt: Benutzer, Microsoft-365-Gruppen, Cloud-Sicherheitsgruppen und Anwendungen werden vorläufig gelöscht (Papierkorb) und nach 30 Tagen endgültig entfernt; alle anderen Objekttypen werden sofort endgültig gelöscht. Fehlkonfigurationen verändern Objekte dagegen an Ort und Stelle; für unterstützte Objekttypen helfen die Differenzberichte von Microsoft Entra Backup and Recovery und ein Wiederherstellungsauftrag, für nicht unterstützte Konfigurationen muss man Einstellungen aus einem dokumentierten bekannten Zustand erneut anwenden. Für Exchange Online gilt: Gelöschte Elemente bleiben standardmäßig 14 Tage im Ordner „Wiederherstellbare Elemente“, einstellbar bis höchstens 30 Tage; mit aktivierter Wiederherstellung einzelner Elemente (standardmäßig bei neuen Postfächern) lassen sich auch endgültig gelöschte Elemente innerhalb der Frist durch Administratoren wiederherstellen; bei einem Litigation Hold werden endgültig gelöschte Elemente unbefristet aufbewahrt. Für SharePoint und OneDrive beträgt die Aufbewahrung in den Papierkörben 93 Tage ab dem Löschen aus dem ursprünglichen Speicherort; SharePoint behält danach für weitere 14 Tage Sicherungen, aus denen Microsoft auf Anfrage Websites (nicht einzelne Dateien) wiederherstellen kann.
>
> Als zusätzliche, längerfristige Absicherung beschreibt die Dokumentation Microsoft 365 Backup für SharePoint-Websites, OneDrive-Konten und Exchange-Postfächer. Es wird nutzungsabhängig abgerechnet, sichert innerhalb der Datengrenzen von Microsoft 365, speichert nur anfügend (unveränderlich), und die Wiederherstellungspunkte liegen für Exchange im Abstand von zehn Minuten über ein ganzes Jahr, für SharePoint und OneDrive im Abstand von zehn Minuten für bis zu zwei Wochen und danach wöchentlich bis zu 52 Wochen. Es gibt Grenzen im Umfang (bis zu 1.000.000 Elemente je Arbeitslast, bis zu 100 Richtlinien je Arbeitslast, bis zu 100.000 Elemente je Richtlinie). Bei Exchange werden nur Elemente wiederhergestellt, die geändert, in die wiederherstellbaren Elemente gelöscht oder endgültig gelöscht wurden; Elemente im Ordner „Gelöschte Elemente“ holen Benutzer selbst zurück. Für Benutzer, die in Entra ID gelöscht wurden, ist laut Dokumentation eine besondere Behandlung bei der Wiederherstellung nötig. Das Produkt sichert Daten und ist keine Sicherung der Tenant-Konfiguration; dafür dienen die Exporte aus Modul 11.3.

Aus diesen Angaben lässt sich ein Konzept ableiten, das drei Teile umfasst. Der erste sind die *Datenklassen* mit Zielwerten für RPO und RTO und den dafür genutzten Mechanismen. Der zweite sind die *Konfigurationssicherungen*, also die regelmäßigen Exporte und die Baselines (Modul 11.3 bis 11.5), damit Richtlinien nach einer Fehlkonfiguration oder einem Angriff neu aufgesetzt werden können. Der dritte ist die *Notfallorganisation*: Notfallzugänge (Break-Glass-Konten, Modul 8.6), Kontaktlisten, Entscheidungswege, Kommunikationswege für den Fall, dass E-Mail und Teams ausgefallen sind, und regelmäßige Übungen. Ein Wiederherstellungskonzept, das nie geübt wurde, ist nur eine Hoffnung.

Das folgende Skript prüft einen Teil der Wiederherstellungsbereitschaft: Es listet vorläufig gelöschte Benutzer und Microsoft-365-Gruppen mit den verbleibenden Tagen bis zur endgültigen Löschung und hebt Objekte hervor, deren Frist bald endet. Das ist eine einfache, aber nützliche Prüfung, weil sie zeigt, welche versehentlichen Löschungen noch rückgängig gemacht werden können, und weil sie in einen wöchentlichen Bericht passt.

**Get-SoftDeletedObjects.ps1**

```powershell
param([int]$Frist = 30, [int]$Warnschwelle = 7)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome

function Add-Rest($objekt, [string]$typ) {
    $tage = $Frist - [int]((Get-Date) - $objekt.DeletedDateTime).TotalDays
    [pscustomobject]@{
        Typ = $typ
        Name = $objekt.AdditionalProperties.displayName
        GeloeschtAm = $objekt.DeletedDateTime.ToString("yyyy-MM-dd")
        RestTage = $tage
        Hinweis = if ($tage -le $Warnschwelle) { "Frist endet bald" } else { "" }
    }
}

$benutzer = Get-MgDirectoryDeletedItemAsUser -All | ForEach-Object { Add-Rest $_ "Benutzer" }
$gruppen  = Get-MgDirectoryDeletedItemAsGroup -All | ForEach-Object { Add-Rest $_ "Gruppe" }

$alle = @($benutzer) + @($gruppen)
if (-not $alle) { "Keine vorlaeufig geloeschten Objekte."; return }
$alle | Sort-Object RestTage | Format-Table -AutoSize
```

Die Funktion berechnet aus dem Löschdatum und der Frist die verbleibenden Tage. Die Frist von 30 Tagen entspricht den dokumentierten Werten für Benutzer und Microsoft-365-Gruppen und ist als Parameter einstellbar. Die Namen stehen je nach Modulversion in den Zusatzeigenschaften der Objekte, deshalb liest das Skript sie von dort. Das Ergebnis wird nach den verbleibenden Tagen sortiert, so dass die dringendsten Fälle oben stehen. Bei Zugriffsfehlern (403) fehlt dem Konto die Berechtigung zum Lesen gelöschter Objekte.

### Typische Fehler und Stolperfallen.

Der gefährlichste Irrtum ist, Microsoft 365 sei „ohnehin gesichert“ und brauche kein eigenes Konzept. Die Plattform schützt ihre eigene Verfügbarkeit, nicht vor Handlungen im Tenant. Zweitens wird Aufbewahrung (Retention) mit Sicherung verwechselt (Modul 5.6). Drittens existiert die Sicherung, aber die Wiederherstellung wurde nie getestet, oder der Notfallzugang ist an dasselbe Konto gebunden, das ausgefallen ist. Viertens werden RPO und RTO nicht abgestimmt: Der Fachbereich erwartet Minuten, die Technik liefert Stunden.

**Falsch und richtig: Notfallzugang pruefen**

```powershell
# FALSCH: Break-Glass-Konto existiert, wurde aber nie getestet
Get-MgUser -Filter "startswith(displayName,'BreakGlass')" | Select-Object DisplayName

# RICHTIG: letzte Anmeldung pruefen (muss bewusst und selten, aber nachweisbar sein)
Get-MgUser -Filter "startswith(displayName,'BreakGlass')" -Property DisplayName,SignInActivity |
    Select-Object DisplayName, @{n="LetzteAnmeldung";e={$_.SignInActivity.LastSignInDateTime}}
# Pruefregel: Anmeldung im letzten Halbjahr als Uebungsnachweis dokumentieren
```

Die zweite Fassung zeigt, wann das Notfallkonto zuletzt benutzt wurde. Eine Anmeldung ohne Übung ist ein Alarmsignal, eine dokumentierte Übung im Halbjahr der gewünschte Zustand. Das Lesen der Anmeldeaktivität erfordert zusätzliche Berechtigungen und Lizenzen, die in der aktuellen Dokumentation zu prüfen sind.

### Praxisbezug.

Legen Sie fest, wer im Notfall entscheidet, wie kommuniziert wird, wenn Teams ausfällt, und wo die Wiederherstellungsanleitung liegt (außerhalb von Microsoft 365, sonst ist sie im Ernstfall nicht erreichbar). Üben Sie mindestens jährlich ein Szenario: versehentlich gelöschtes Team, verschlüsselte Dokumentenbibliothek, fehlerhafte Richtlinie für bedingten Zugriff. Dokumentieren Sie Dauer und Ergebnis, und vergleichen Sie sie mit RTO und RPO.

## 12.7 Kontinuierliche Verbesserung

Governance ist kein Projekt mit Enddatum, sondern ein Betrieb mit laufender Anpassung. Microsoft ändert seine Dienste im Wochentakt, die Organisation verändert sich, Risiken verschieben sich, und Regeln, die vor zwei Jahren richtig waren, sind heute vielleicht zu streng oder zu lasch. *Kontinuierliche Verbesserung* bedeutet, diese Veränderungen systematisch aufzunehmen und in bessere Regeln zu übersetzen, statt ad hoc zu reagieren. Der klassische Rahmen dafür ist der Zyklus Planen, Umsetzen, Prüfen, Handeln (Plan-Do-Check-Act): Man plant eine Verbesserung, setzt sie um, prüft anhand von Messwerten, ob sie gewirkt hat, und übernimmt oder verwirft sie.

Damit das funktioniert, braucht es vier Dinge. Erstens *Eingänge*: Woher kommen Anstöße? Aus den Kennzahlen (Modul 9.8), aus Vorfällen und Beinahe-Vorfällen, aus Audit- und Prüfbefunden (Modul 7), aus Drift-Meldungen (Modul 11.5), aus den Ankündigungen im Nachrichtencenter und den Dienststörungen (Modul 9.6) und aus der Rückmeldung der Beschäftigten und Champions (Lerneinheit 12.5). Zweitens ein *Verbesserungsverzeichnis* (Backlog), in dem alle Vorschläge mit Nutzen, Aufwand und Verantwortlichem stehen. Drittens ein *Rhythmus*: monatliche Betriebsrunde, vierteljährliches Governance-Gremium, jährliche Neubewertung des Reifegrads (Lerneinheit 12.2). Viertens *Entscheidungsregeln*: Wer darf Standards ändern, und mit welchem Verfahren (Modul 11.4)?

> **Ergänzung aus der Nachrecherche**
>
> Für diese Lerneinheit wurden keine zusätzlichen Quellen abgerufen; sie beruht auf allgemeinem Fachwissen über Verbesserungszyklen und auf den in diesem Kurs bereits dokumentierten Bausteinen: Das Nachrichtencenter und die Dienstintegrität (Modul 9.6) liefern Ankündigungen und Störungen, die Konfigurationsüberwachung (Modul 11.5) liefert Abweichungen, und die Lebenszyklusrichtlinien für Websites erzeugen laut Dokumentation Berichte über Besitz, Aktivität, Benachrichtigungen und Maßnahmen (Modul 10.6), die als Eingang für das Verbesserungsverzeichnis dienen können. Bei Entscheidungen über Änderungen der Standards sollten Datenschutz, Informationssicherheit und gegebenenfalls Arbeitnehmervertretung beteiligt werden (keine Rechtsberatung).

Ein wichtiger Teil ist das Erkennen von Verschlechterungen, bevor sie zum Problem werden. Eine einzelne schlechte Messung ist oft Zufall, eine Folge von drei schlechteren Messungen ist ein Trend. Das folgende Skript liest eine Datei mit Kennzahlen über mehrere Monate (Spalten Datum, Kennzahl, Wert, Ziel, BesserWenn mit den Werten „hoeher“ oder „niedriger“) und meldet Kennzahlen, die das Ziel verfehlen oder drei Perioden in Folge schlechter geworden sind. Aus den Meldungen entstehen Einträge im Verbesserungsverzeichnis.

**Find-KpiTrends.ps1**

```powershell
param([Parameter(Mandatory)][string]$Datei, [int]$Perioden = 3)

$zeilen = Import-Csv -Path $Datei -Delimiter ";"
if (-not $zeilen) { throw "Keine Daten." }

$befunde = foreach ($gruppe in ($zeilen | Group-Object Kennzahl)) {
    $reihe = @($gruppe.Group | Sort-Object { [datetime]$_.Datum })
    $letzter = $reihe[-1]
    $ziel = [decimal]$letzter.Ziel
    $wert = [decimal]$letzter.Wert
    $hoeherBesser = $letzter.BesserWenn -eq "hoeher"

    $verfehlt = if ($hoeherBesser) { $wert -lt $ziel } else { $wert -gt $ziel }

    $verschlechtert = $false
    if ($reihe.Count -gt $Perioden) {
        $ende = $reihe[($reihe.Count - $Perioden - 1)..($reihe.Count - 1)]
        $verschlechtert = $true
        for ($i = 1; $i -lt $ende.Count; $i++) {
            $vorher = [decimal]$ende[$i - 1].Wert; $jetzt = [decimal]$ende[$i].Wert
            $schlechter = if ($hoeherBesser) { $jetzt -lt $vorher } else { $jetzt -gt $vorher }
            if (-not $schlechter) { $verschlechtert = $false; break }
        }
    }

    if ($verfehlt -or $verschlechtert) {
        [pscustomobject]@{
            Kennzahl = $gruppe.Name; Aktuell = $wert; Ziel = $ziel
            Befund = (@(if ($verfehlt) {"Ziel verfehlt"}; if ($verschlechtert) {"$Perioden Perioden schlechter"}) -join "; ")
        }
    }
}

if ($befunde) { $befunde | Format-Table -AutoSize -Wrap } else { "Keine auffaelligen Kennzahlen." }
```

Das Skript gruppiert die Messungen nach Kennzahl und sortiert sie nach Datum. Für die jüngste Messung prüft es, ob das Ziel verfehlt ist, wobei die Richtung davon abhängt, ob höhere oder niedrigere Werte besser sind. Für den Trend nimmt es die letzten Messungen (die angegebene Zahl der Perioden plus die vorhergehende als Ausgangspunkt) und prüft, ob jeder Wert schlechter als der vorherige ist; bei einer einzigen Ausnahme gilt der Trend als nicht vorhanden. Am Ende werden die auffälligen Kennzahlen mit Begründung ausgegeben. Die Zahl der Perioden ist ein Parameter, weil die passende Empfindlichkeit von der Messhäufigkeit abhängt.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Verbesserungen ohne Messwert zu beschließen und dann nicht zu wissen, ob sie gewirkt haben. Zweitens wird das Verbesserungsverzeichnis zur Wunschliste ohne Priorität; Einträge werden nie abgearbeitet. Drittens wird auf jede Kennzahlschwankung mit Aktionismus reagiert. Viertens gibt es keinen Abschluss: Maßnahmen werden umgesetzt, aber die Wirkung wird nicht geprüft und nicht dokumentiert.

**Falsch und richtig: Wirkung pruefen**

```powershell
# FALSCH: Massnahme umsetzen und als erledigt abhaken
$eintrag.Status = "erledigt"

# RICHTIG: Wirkung nach festem Zeitraum gegen Ausgangswert pruefen
$eintrag | Add-Member -NotePropertyName Ausgangswert -NotePropertyValue 62 -Force
$eintrag | Add-Member -NotePropertyName PruefungAm -NotePropertyValue (Get-Date).AddDays(60).ToString("yyyy-MM-dd") -Force
$eintrag.Status = "umgesetzt - Wirkung offen"
```

Die korrigierte Fassung speichert Ausgangswert und Prüfdatum. Erst nach der Prüfung wird der Status auf „wirksam“ oder „nicht wirksam“ gesetzt. Der Ausgangswert 62 ist ein Beispiel.

### Praxisbezug.

Legen Sie einen festen Termin für die monatliche Betriebsrunde fest und halten Sie sie kurz: Kennzahlen, neue Verbesserungsvorschläge, Entscheidungen. Veröffentlichen Sie nach jeder Runde eine Seite mit „Was wir geändert haben und warum“. Das schafft Vertrauen bei den Beschäftigten, weil sie sehen, dass ihre Rückmeldungen Wirkung haben.

## 12.8 30-60-90-Tage-Roadmap

Eine *30-60-90-Tage-Roadmap* gliedert die Einführung in drei überschaubare Abschnitte, jeweils mit einem klaren Ergebnis. Sie ist beliebt, weil sie dem Management einen Rahmen gibt, in dem Fortschritt sichtbar wird, und weil sie die Versuchung dämpft, zu viel gleichzeitig zu beginnen. Die Roadmap fasst alles zusammen, was in den Modulen 1 bis 12 erarbeitet wurde, und bringt es in eine Reihenfolge. Die Reihenfolge folgt drei Regeln: Erst Risiken senken, die schnell und billig zu senken sind. Dann Standards festlegen und im Pilot erproben. Dann messen, automatisieren und verankern.

Die Inhalte der drei Abschnitte in diesem Kurs sind eine Empfehlung der Kursautoren und kein Standard von Microsoft. Die *ersten 30 Tage* schaffen das Fundament: Ist-Analyse (Lerneinheit 12.1), Verantwortliche und Entscheidungsgremium benennen (Modul 1), Sofortmaßnahmen für Administratoren (Mehrfaktor-Anmeldung, Notfallkonten, minimale Rollen, Modul 2.5 und 8.3), Protokollierung prüfen (Modul 7.1) und Reifegrad bewerten (Lerneinheit 12.2). Die *Tage 31 bis 60* legen Standards fest und erproben sie: Namens- und Metadatenstandard (Modul 10.4 und 10.5), Einschränkung der Gruppenerstellung und Pilot der Bereitstellungsfabrik (Modul 3.3 und 10.1), Beschriftungen und Aufbewahrung im Pilot (Modul 6.1 und 6.3), Lebenszyklusrichtlinien zunächst in der Simulation (Modul 10.6), Kommunikation und Champions (Lerneinheiten 12.4 und 12.5). Die *Tage 61 bis 90* bringen den Betrieb in den Regelzustand: Kennzahlen und Berichte (Modul 9), Drift-Erkennung und Konfigurationsexport (Modul 11.3 und 11.5), Runbooks und Ticketanbindung (Modul 9.7 und 11.6), Wiederherstellungskonzept und erste Übung (Lerneinheit 12.6), Kostenübersicht (Lerneinheit 12.3) und die erste Betriebsrunde (Lerneinheit 12.7).

> **Ergänzung aus der Nachrecherche**
>
> Die Reihenfolge der Maßnahmen berücksichtigt Hinweise aus den in diesem Kurs abgerufenen Quellen. Die Ablaufrichtlinie für Gruppen hat nach der Dokumentation keinen Simulationsmodus und wirkt auf alle ausgewählten Gruppen; die Lebenszyklusrichtlinien für SharePoint-Websites bieten dagegen einen Simulationsmodus, der einmal läuft und einen Bericht erzeugt, bevor die Richtlinie aktiv wird. Beide sollten deshalb erst nach der Bereinigung der Besitzerlage und nach Kommunikation an die Besitzer aktiv werden. Für die Konfigurationsüberwachung nennt die Dokumentation Voraussetzungen (Einrichtung der Dienstidentität, Lizenzen), die vor dem ersten Monitor erfüllt sein müssen, und ein Intervall von sechs Stunden. Für Microsoft 365 Backup ist eine nutzungsabhängige Abrechnung einzurichten, bevor Richtlinien angelegt werden. Zeitaufwand, Verantwortliche und Reihenfolge hängen von Ihrer Organisation ab; die Tagesangaben sind eine Orientierung.

Eine Roadmap ist nur so gut wie ihre Prüfung auf Machbarkeit. Zwei Fehler sind häufig: Aufgaben hängen voneinander ab, ohne dass die Reihenfolge stimmt (die Lebenszyklusrichtlinie wird aktiv, bevor die Besitzer bereinigt sind), und einzelne Personen sind in einem Abschnitt überbucht. Das folgende Skript prüft beides für eine Roadmap-Datei im JSON-Format. Jede Aufgabe hat eine Kennung, einen Namen, Start- und Endtag (gezählt ab dem Projektbeginn), einen Verantwortlichen, den Aufwand in Stunden und die Kennungen der Vorgänger. Das Skript meldet Verstöße gegen die Reihenfolge und Überbuchung je Person und Phase, und es schreibt die Roadmap als Markdown-Tabelle mit echten Datumsangaben.

**roadmap.json (Auszug)**

```json
{
  "start": "2026-11-02",
  "stundenProPersonUndPhase": 40,
  "aufgaben": [
    { "id": "A1", "name": "Ist-Analyse", "von": 1,  "bis": 20, "wer": "Anna", "stunden": 30, "nach": [] },
    { "id": "A2", "name": "Gremium und Rollen", "von": 5,  "bis": 25, "wer": "Ben",  "stunden": 16, "nach": [] },
    { "id": "B1", "name": "Namens- und Metadatenstandard", "von": 31, "bis": 45, "wer": "Anna", "stunden": 20, "nach": ["A1","A2"] },
    { "id": "B2", "name": "Pilot Bereitstellungsfabrik", "von": 40, "bis": 60, "wer": "Cem",  "stunden": 30, "nach": ["B1"] },
    { "id": "C1", "name": "Lebenszyklus aktivieren", "von": 61, "bis": 75, "wer": "Cem",  "stunden": 12, "nach": ["B2"] }
  ]
}
```

Die Datei beschreibt fünf Aufgaben in drei Abschnitten. Man erkennt die Abhängigkeiten im Feld „nach“: Die Aufgabe B1 darf erst beginnen, wenn A1 und A2 abgeschlossen sind. Das Skript prüft solche Beziehungen automatisch.

**Test-Roadmap.ps1**

```powershell
param([Parameter(Mandatory)][string]$Datei, [string]$Ausgabe = ".\roadmap.md")

$r = Get-Content -Path $Datei -Raw -Encoding UTF8 | ConvertFrom-Json
$start = [datetime]$r.start
$ids = @{}; foreach ($a in $r.aufgaben) { $ids[$a.id] = $a }
$fehler = New-Object System.Collections.Generic.List[string]

foreach ($a in $r.aufgaben) {
    if ($a.bis -lt $a.von) { $fehler.Add("$($a.id): Ende vor Beginn") }
    foreach ($v in $a.nach) {
        if (-not $ids.ContainsKey($v)) { $fehler.Add("$($a.id): Vorgaenger $v existiert nicht"); continue }
        if ($ids[$v].bis -ge $a.von) { $fehler.Add("$($a.id) beginnt an Tag $($a.von), Vorgaenger $v endet erst an Tag $($ids[$v].bis)") }
    }
}

function Get-Phase($tag) { if ($tag -le 30) { 1 } elseif ($tag -le 60) { 2 } else { 3 } }
$last = $r.aufgaben | ForEach-Object {
    $phase = Get-Phase $_.von
    [pscustomobject]@{ Wer = $_.wer; Phase = $phase; Stunden = $_.stunden }
} | Group-Object Wer, Phase | ForEach-Object {
    [pscustomobject]@{ Wer = $_.Group[0].Wer; Phase = $_.Group[0].Phase; Stunden = ($_.Group | Measure-Object Stunden -Sum).Sum }
}
foreach ($l in $last) {
    if ($l.Stunden -gt $r.stundenProPersonUndPhase) {
        $fehler.Add("$($l.Wer) in Phase $($l.Phase): $($l.Stunden) Stunden geplant, verfuegbar $($r.stundenProPersonUndPhase)")
    }
}

$zeilen = @("| Nr | Aufgabe | Von | Bis | Wer | Stunden |", "|---|---|---|---|---|---|")
foreach ($a in $r.aufgaben | Sort-Object von) {
    $zeilen += "| {0} | {1} | {2:yyyy-MM-dd} | {3:yyyy-MM-dd} | {4} | {5} |" -f $a.id, $a.name, $start.AddDays($a.von - 1), $start.AddDays($a.bis - 1), $a.wer, $a.stunden
}
$zeilen | Set-Content -Path $Ausgabe -Encoding UTF8

if ($fehler.Count -gt 0) { $fehler | ForEach-Object { Write-Host "PROBLEM: $_" -ForegroundColor Yellow }; exit 2 }
Write-Host "Roadmap ist konsistent. Ausgabe: $Ausgabe" -ForegroundColor Green
```

Das Skript liest die Roadmap und legt die Aufgaben in einer Tabelle nach Kennung ab. In der ersten Schleife prüft es, ob das Ende vor dem Anfang liegt, ob die genannten Vorgänger existieren und ob sie vor dem Beginn der Aufgabe enden. Danach summiert es die geplanten Stunden je Person und Abschnitt, wobei der Abschnitt vom Starttag bestimmt wird, und vergleicht sie mit dem verfügbaren Rahmen. Abschließend schreibt es eine Markdown-Tabelle mit Kalenderdaten, berechnet aus dem Startdatum, und meldet Probleme mit dem Rückgabewert 2. In der Beispieldatei fällt auf, dass Anna in Phase 1 und 2 mit 30 und 20 Stunden unter dem Rahmen liegt, die Aufgabe B2 aber an Tag 40 beginnt, obwohl ihr Vorgänger B1 erst an Tag 45 endet. Das Skript meldet genau diesen Konflikt.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist eine überladene Roadmap, die nach zwei Wochen nicht mehr stimmt. Zweitens fehlen Verantwortliche und Stunden; eine Aufgabe ohne Namen und Zeit geschieht nicht. Drittens werden die Abhängigkeiten nicht beachtet, und eine Maßnahme wird vor ihrer Voraussetzung eingeführt. Viertens wird die Roadmap nicht kommuniziert, und niemand außerhalb des Projekts weiß, was auf ihn zukommt.

**Falsch und richtig: Abhaengigkeit pruefen**

```powershell
# FALSCH: Aufgabe mit Abhaengigkeit einfach einplanen
$aufgabe = @{ id = "B2"; von = 40; nach = @("B1") }       # B1 endet erst an Tag 45

# RICHTIG: Beginn aus dem spaetesten Vorgaengerende ableiten
$fruehesterStart = ($aufgabe.nach | ForEach-Object { $ids[$_].bis } | Measure-Object -Maximum).Maximum + 1
if ($aufgabe.von -lt $fruehesterStart) { "B2 kann fruehestens an Tag $fruehesterStart beginnen." }
```

Die zweite Fassung leitet den frühesten Beginn aus dem Ende der Vorgänger ab und meldet den Konflikt. In echten Projekten verwendet man dafür ein Planungswerkzeug; das Skript zeigt das Prinzip.

### Praxisbezug.

Stellen Sie die Roadmap zu Beginn im Gremium vor und vereinbaren Sie die Entscheidungspunkte nach 30, 60 und 90 Tagen. Zeigen Sie an jedem Punkt, was erreicht ist, was sich verschoben hat und warum. Rechnen Sie ehrlich: Wenn die Stunden nicht reichen, ist es besser, den Umfang zu kürzen, als die Qualität. Nach den 90 Tagen geht das Projekt in die kontinuierliche Verbesserung über (Lerneinheit 12.7).

## Übungsaufgaben

**Aufgabe 1 (leicht).** Nennen Sie die vier Ebenen einer Ist-Analyse und geben Sie für jede ein Beispiel, wie Sie sie erheben würden. Warum ist die organisatorische Ebene besonders wichtig?

**Aufgabe 2 (leicht).** Erklären Sie die Begriffe RPO und RTO in eigenen Worten und geben Sie je ein Beispiel für zwei Datenklassen mit unterschiedlichen Anforderungen.

**Aufgabe 3 (leicht).** Welche Rolle spielen Champions bei der Einführung von Governance? Nennen Sie vier Bestandteile eines Champions-Programms.

**Aufgabe 4 (mittel).** Ein Unternehmen bewertet seinen Reifegrad: Identität Stufe 4 (Ziel 4), Teams Stufe 2 (Ziel 3), SharePoint Stufe 2 (Ziel 4), Information Protection Stufe 1 (Ziel 3), Monitoring Stufe 3 (Ziel 4). Die Gewichte sind in dieser Reihenfolge 3, 2, 3, 3 und 2. Berechnen Sie die Prioritäten wie im Skript dieses Moduls, und legen Sie die Reihenfolge der Bearbeitung fest.

**Aufgabe 5 (mittel).** Erstellen Sie ein einfaches Dreijahres-Kostenmodell für Governance in einem Unternehmen mit 800 Beschäftigten. Beschreiben Sie die Kostenblöcke, die Sie berücksichtigen, und die Annahmen, die Sie festhalten müssen. Nennen Sie keine konkreten Preise, sondern Parameter.

**Aufgabe 6 (mittel).** Schreiben Sie ein PowerShell-Skript, das aus einer CSV-Datei mit den Spalten Abteilung, Beschaeftigte und Aktive den Adoptionsgrad je Abteilung berechnet, Abteilungen unter 50 Prozent markiert und Abteilungen mit weniger als fünf Beschäftigten zusammenfasst.

**Aufgabe 7 (schwer).** Entwerfen Sie ein Wiederherstellungskonzept für drei Datenklassen (Finanzdaten, Projektdokumente, allgemeine Ablage) mit RPO, RTO, Schutzmechanismen (Papierkorb, Aufbewahrung, Sicherung, Konfigurationsexport), Verantwortlichen und einem Übungsplan. Berücksichtigen Sie die Grenzen der einzelnen Mechanismen.

**Aufgabe 8 (schwer).** Erstellen Sie für eine mittelgroße Organisation eine 30-60-90-Tage-Roadmap mit mindestens zwölf Aufgaben, Verantwortlichen, Aufwand und Abhängigkeiten. Prüfen Sie sie gedanklich oder mit dem Skript dieses Moduls auf Reihenfolge und Überbuchung, und begründen Sie, welche Aufgaben Sie bewusst auf später verschieben.

## Lösungen

**Lösung 1.** Die Ebenen sind Bestand (Zählungen und Listen über Graph und Berichte), Konfiguration (Export und Vergleich mit einem Zielbild), Nutzung (Nutzungsberichte, Aktivität) und Organisation (Interviews zu Rollen, Prozessen und Zuständigkeiten). Die organisatorische Ebene ist besonders wichtig, weil Technik ohne Zuständigkeit nicht wirkt: Wenn niemand für eine Einstellung verantwortlich ist, wird sie nicht gepflegt, und Befunde bleiben liegen.

**Lösung 2.** Das RPO nennt, wie viel Datenverlust (als Zeitspanne bis zum Ereignis) akzeptabel ist, das RTO, wie lange die Wiederherstellung dauern darf. Beispiel: Finanzdaten brauchen ein kleines RPO und RTO (zum Beispiel wenige Stunden), weil Buchungen zeitkritisch sind und Verluste teuer; eine allgemeine Ablage verträgt ein größeres RPO und RTO (zum Beispiel ein bis zwei Tage). Die Zahlen sind Beispiele; verbindlich werden sie erst mit dem Fachbereich festgelegt.

**Lösung 3.** Champions sind Beschäftigte in den Fachbereichen, die Kollegen bei der Anwendung helfen und Rückmeldungen an die Zentrale tragen. Sie werden von Kollegen eher gehört als eine Zentrale und kennen die Arbeitsabläufe. Bestandteile: Auswahl von Freiwilligen, Schulung, regelmäßiger Austausch (zum Beispiel monatlich), ein kurzer Draht zur Zentrale und Anerkennung. Auch klare Anforderungen und ein Nachfolgeplan gehören dazu.

**Lösung 4.** Lücke und Priorität: Identität 0 Lücke, Priorität 0. Teams 1 Lücke mal Gewicht 2 gleich 2. SharePoint 2 Lücke mal Gewicht 3 gleich 6. Information Protection 2 Lücke mal Gewicht 3 gleich 6. Monitoring 1 Lücke mal Gewicht 2 gleich 2. Die Summe der Lücken zeigt, dass die größten Hebel in den Bereichen SharePoint und Information Protection liegen. Reihenfolge: SharePoint und Information Protection zuerst (Priorität 6, bei Gleichstand nach Risiko entscheiden, zum Beispiel Information Protection wegen der Wirkung auf Freigaben), danach Teams und Monitoring (Priorität 2), Identität zuletzt, da das Ziel erreicht ist.

**Lösung 5.** Kostenblöcke: Lizenzen (Basis und Zusatz für Sicherheit und Compliance), nutzungsabhängige Dienste (Speicher über Kontingent, Sicherung, Archiv), Werkzeuge, Betrieb (Personal, Dienstleister), Einführung (Schulung, Beratung, Projektzeit), Reserve. Annahmen: Zahl der Beschäftigten und Wachstum, Datenwachstum pro Jahr, Anteil archivierbarer Daten, Preise aus dem eigenen Vertrag mit Gültigkeitsdatum, Stundensätze, Einsparungen (wegfallende Lizenzen, geringerer Speicher, weniger Vorfälle), Aufbewahrungspflichten, die Löschen einschränken. Das Modell erhält pro Jahr Kosten und Nutzen und einen Verlauf über drei Jahre; Preise stehen als Parameter in einer Datei mit Datum.

**Lösung 6.** Ein Lösungsvorschlag:

```powershell
param([Parameter(Mandatory)][string]$Datei, [int]$Mindestgroesse = 5)
$z = Import-Csv -Path $Datei -Delimiter ";"
$gross = $z | Where-Object { [int]$_.Beschaeftigte -ge $Mindestgroesse }
$klein = $z | Where-Object { [int]$_.Beschaeftigte -lt $Mindestgroesse }
$ausgabe = foreach ($a in $gross) {
    $grad = [int]$a.Aktive / [int]$a.Beschaeftigte
    [pscustomobject]@{ Abteilung = $a.Abteilung; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
if ($klein) {
    $b = ($klein | Measure-Object Beschaeftigte -Sum).Sum
    $ak = ($klein | Measure-Object Aktive -Sum).Sum
    $grad = $ak / $b
    $ausgabe += [pscustomobject]@{ Abteilung = "(kleine Abteilungen zusammengefasst)"; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
$ausgabe | Format-Table -AutoSize
```

Das Skript teilt die Abteilungen nach der Mindestgröße, berechnet den Anteil der Aktiven, markiert Werte unter 50 Prozent und fasst kleine Abteilungen zu einer Zeile zusammen, damit Einzelpersonen nicht erkennbar werden. In einer produktiven Fassung sollte man außerdem Zeilen mit null Beschäftigten abfangen, um eine Division durch null zu vermeiden.

**Lösung 7.** Ein Beispiel: Finanzdaten: RPO 1 Stunde, RTO 4 Stunden; Schutz durch Papierkorb und Aufbewahrung, Microsoft 365 Backup mit Richtlinie für die betroffenen Websites und Postfächer, Beschriftung und Zugriffsbeschränkung; Verantwortlicher: Leitung Finanzen und Betrieb; Übung halbjährlich. Projektdokumente: RPO 1 Tag, RTO 1 Tag; Schutz durch Papierkorb (93 Tage), Versionen, Aufbewahrung, Sicherung für kritische Projekte; Übung jährlich. Allgemeine Ablage: RPO 1 Woche, RTO 3 Tage; Papierkorb und Standardschutz. Konfiguration: nächtlicher Export in ein Repository, Baselines, Notfallkonten. Grenzen: Papierkörbe und Aufbewahrung sind keine Sicherung; die Sicherung hält nach Dokumentation bis zu einem Jahr und gilt für Daten, nicht für Konfiguration; bei Entra gelöschte Benutzer brauchen besondere Behandlung; die Konfigurationsüberwachung speichert Momentaufnahmen nur sieben Tage. Übungsplan: je ein Szenario pro Quartal, Dauer messen und mit dem RTO vergleichen. Die genannten Zeiten sind Beispiele.

**Lösung 8.** Ein Beispiel (Auszug): Tage 1 bis 30: Ist-Analyse (Anna, 30 h), Gremium und Rollen (Ben, 16 h), Administratoren absichern (Cem, 12 h, nach Ist-Analyse-Teilergebnis), Protokollierung prüfen (Dilara, 6 h), Reifegrad bewerten (Anna, 8 h). Tage 31 bis 60: Namens- und Metadatenstandard (Anna, 20 h, nach Gremium), Gruppenerstellung einschränken (Cem, 10 h, nach Standard), Pilot Bereitstellungsfabrik (Cem, 30 h), Beschriftungen im Pilot (Dilara, 24 h), Lebenszyklus in Simulation (Ben, 12 h, nach Besitzerbereinigung), Kommunikation und Champions (Elif, 24 h). Tage 61 bis 90: Kennzahlen und Berichte (Ben, 20 h), Export und Drift (Cem, 24 h), Runbooks (Dilara, 16 h), Wiederherstellungsübung (Cem, 12 h), erste Betriebsrunde (Ben, 6 h). Bewusst auf später verschoben werden zum Beispiel Information Barriers, Insider Risk und Records Management, weil sie hohen Aufwand und Abstimmung mit Recht und Betriebsrat erfordern; die Begründung gehört in das Dokument. Die Prüfung mit dem Skript deckt Konflikte auf, zum Beispiel wenn eine Person in einer Phase mehr Stunden trägt, als ihr zur Verfügung stehen.
