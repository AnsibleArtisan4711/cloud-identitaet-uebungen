# Modul 06 - Information Protection und Data Governance

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 10 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8,75 Stunden (3 × 1,25 plus 5 × 1). Als Richtwert für den Umfang wurde der höhere Wert (10 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**                 | **Dauer (h)** | **Prio** |
|:--------|:--------------------------------|--------------:|---------:|
| 6.1     | Sensitivity Labels              |          1,25 |        1 |
| 6.2     | DLP Governance                  |          1,25 |        1 |
| 6.3     | Retention Policies              |             1 |        1 |
| 6.4     | Records Management              |             1 |        1 |
| 6.5     | Data Lifecycle                  |             1 |        1 |
| 6.6     | Information Barriers            |             1 |        2 |
| 6.7     | Purview Data Map Bezug          |             1 |        2 |
| 6.8     | Data-Governance-Troubleshooting |          1,25 |        2 |
|         | **Summe laut Details**          |      **8,75** |          |
|         | **Dauer laut Modulblatt**       |        **10** |          |

> **Merke: Verbindung zu Purview per PowerShell**
>
> Die Purview-Beispiele dieses Moduls verwenden das Modul `ExchangeOnlineManagement`. Mit `Connect-IPPSSession` baut man die Verbindung zum Security-und-Compliance-PowerShell auf, über das Labels, DLP-Richtlinien und Aufbewahrungsrichtlinien verwaltet werden. Wie in den früheren Modulen gilt: Die Beispiele folgen den Mustern der Microsoft-Dokumentation, wurden aber nicht gegen einen echten Tenant ausgeführt. Testen Sie jedes Skript zuerst in einem Testtenant, und beachten Sie, dass Richtlinien in Purview mit Verzögerung wirksam werden.

Dieses Modul behandelt den Schutz und die Steuerung von Daten. Sensitivity Labels beantworten die Frage „Wie vertraulich ist das?“, DLP beantwortet „Darf das das Haus verlassen?“, Aufbewahrung und Records beantworten „Wie lange muss oder darf es existieren?“. Information Barriers beantworten „Wer darf mit wem überhaupt kommunizieren?“, und die Data Map beantwortet „Welche Daten haben wir eigentlich und wo?“. Die Container-Sicht auf Labels (Teams und Websites) steht in Modul 4, Lerneinheit 4.5; hier geht es um Dateien und E-Mails. Die Governance von Administratorrechten für Purview selbst gehört zu Modul 2 (Rollen, PIM).

## 6.1 Sensitivity Labels

Jede Organisation verarbeitet Informationen mit sehr unterschiedlichem Schutzbedarf: die Speisekarte der Kantine, den Quartalsabschluss vor der Veröffentlichung, Gehaltslisten, Patientendaten. Wenn alles gleich behandelt wird, ist entweder das Unwichtige zu streng oder das Wichtige zu lax geschützt. Die Grundidee der *Klassifizierung* ist deshalb, Informationen in wenige verständliche Stufen einzuteilen und jede Stufe mit Schutzmaßnahmen zu verbinden. In Microsoft 365 heißt das Werkzeug dafür *Sensitivity Label* (deutsch: Vertraulichkeitsbezeichnung). Ein Label ist eine Markierung, die an der Datei oder E-Mail selbst hängt, nicht am Speicherort. Sie wandert also mit, wenn die Datei kopiert, per Mail verschickt oder auf einen USB-Stick gelegt wird.

Ein Label kann drei Dinge bewirken. Erstens kann es *kennzeichnen*: Es fügt Kopfzeile, Fußzeile oder Wasserzeichen ein, damit Menschen sofort sehen, wie die Datei einzustufen ist. Zweitens kann es *verschlüsseln* und damit Zugriffsrechte durchsetzen (wer darf lesen, bearbeiten, drucken, weiterleiten). Die Verschlüsselung ist Teil der Datei, nicht des Servers; selbst wer die Datei in die Finger bekommt, kann sie ohne berechtigte Identität nicht öffnen. Drittens liefert das Label einen *Metadatenwert*, auf den andere Dienste reagieren können: Eine DLP-Regel kann zum Beispiel das Versenden aller Dateien mit dem Label „Streng vertraulich“ an externe Adressen verbieten, und Defender-Produkte können Aktivitäten rund um beschriftete Dateien auswerten. Das Label ist damit das gemeinsame Vokabular, auf dem die übrigen Schutzmechanismen aufbauen.

Das Zusammenspiel besteht aus zwei Teilen, die man unbedingt trennen muss. Das *Label* selbst wird definiert: Name, Beschreibung, Gültigkeitsbereich, Schutzaktionen. Die *Labelrichtlinie* (englisch Label Policy) veröffentlicht Labels an Benutzer und bestimmt Verhalten: welche Labels welche Personen sehen, ob ein Label Pflicht ist, welches Label standardmäßig vorausgewählt wird, ob eine Begründung nötig ist, wenn jemand die Einstufung senkt. Ein Label, das in keiner Richtlinie veröffentlicht ist, kann niemand manuell anwenden. Das ist die häufigste Ursache für die Beschwerde „Ich sehe das Label nicht“.

> **Ergänzung aus der Nachrecherche**
>
> Laut der Microsoft-Dokumentation zu Vertraulichkeitsbezeichnungen lassen sich Labels sowohl auf Dateien und E-Mails als auch auf Container wie Teams, Microsoft-365-Gruppen und SharePoint-Websites anwenden; für Container-Labels gelten andere Einstellungen (Datenschutzstufe, Gastzugriff, Freigabe, Zugriff von nicht verwalteten Geräten) als für Dateilabels. Die Reihenfolge der Labels in der Oberfläche spielt eine Rolle: Ein Label weiter unten in der Liste gilt als sensibler und erhält eine höhere Priorität, was zum Beispiel für die Frage relevant ist, welche Einstellung bei Konflikten gewinnt. Diese Ergänzung stammt aus der Microsoft-Dokumentation (siehe Quellenverzeichnis). Konkrete Lizenzvoraussetzungen für einzelne Funktionen (etwa automatische Kennzeichnung) ändern sich und sollten vor dem Einsatz in der aktuellen Lizenzübersicht geprüft werden.

Wie entwirft man eine gute Labelstruktur? Die Erfahrung vieler Einführungen ist eindeutig: weniger ist mehr. Vier bis fünf Stufen genügen fast immer, zum Beispiel Öffentlich, Intern, Vertraulich und Streng vertraulich. Jede zusätzliche Stufe erzeugt Unsicherheit bei den Anwendern („Ist das jetzt Vertraulich oder Intern-Plus?“) und damit falsche oder fehlende Kennzeichnung. Zu jedem Label gehört ein Tooltip mit einem Alltagsbeispiel, denn Anwender entscheiden in Sekunden. Unterlabels (Labels unter einem Hauptlabel, zum Beispiel „Vertraulich / Personal“ und „Vertraulich / Finanzen“) sind nützlich, wenn innerhalb einer Stufe unterschiedliche Schutzmaßnahmen nötig sind, etwa unterschiedliche Empfängergruppen.

Die Einführung läuft in Schritten. Zuerst legt man Labels und eine Richtlinie für eine kleine Pilotgruppe an, mit einem Standardlabel (zum Beispiel Intern), damit nichts unbeschriftet bleibt, aber noch ohne Pflicht. Danach schaltet man Kennzeichnung (Fußzeile) ein, später Verschlüsselung für die obersten Stufen. Zuletzt kommt die *automatische Kennzeichnung*: Eine Regel erkennt Muster wie IBAN, Kreditkartennummern oder Sozialversicherungsnummern in Dateien und wendet das Label an oder schlägt es vor. Die Reihenfolge ist wichtig: Die Anwender müssen das System zuerst kennenlernen, bevor es Schutz erzwingt, und die Verschlüsselung darf erst kommen, wenn Zusammenarbeit mit Externen und Weiterverarbeitung (etwa durch Suche) geklärt sind.

Das folgende Skript legt zwei Labels an (eines mit Fußzeile, eines für Vertrauliches), veröffentlicht sie in einer Richtlinie für alle Benutzer von Exchange und setzt über die erweiterten Einstellungen eine Begründungspflicht für das Herabstufen. Die ersten Zeilen verbinden sich mit Purview. `New-Label` legt je ein Label an, `New-LabelPolicy` veröffentlicht sie. Beachten Sie, dass das Label zuerst existieren muss, bevor es in einer Richtlinie genannt werden kann.

**New-LabelStructure.ps1**

```powershell
Connect-IPPSSession

New-Label -DisplayName "Intern" -Name "Intern" `
    -Tooltip "Informationen fuer Mitarbeitende, nicht fuer die Oeffentlichkeit." `
    -ContentType "File, Email" `
    -ApplyContentMarkingFooterEnabled $true `
    -ApplyContentMarkingFooterText "Intern" `
    -ApplyContentMarkingFooterFontSize 9

New-Label -DisplayName "Vertraulich" -Name "Vertraulich" `
    -Tooltip "Geschaeftskritisch, z. B. Vertraege, Preise, Personaldaten." `
    -ContentType "File, Email" `
    -ApplyContentMarkingFooterEnabled $true `
    -ApplyContentMarkingFooterText "Vertraulich" `
    -ApplyContentMarkingFooterFontSize 9

New-LabelPolicy -Name "Standard-Labelrichtlinie" `
    -Labels "Intern","Vertraulich" `
    -ExchangeLocation All `
    -AdvancedSettings @{ requiredowngradejustification = "true" }

Get-Label | Select-Object DisplayName, Priority, ContentType
```

Die wichtigsten Zeilen im Einzelnen: `-ContentType "File, Email"` begrenzt den Geltungsbereich des Labels auf Dateien und Mails (Container-Labels bekommen einen anderen Inhaltstyp, siehe Modul 4.5). Die Fußzeilenparameter bewirken, dass Office-Apps beim Anwenden des Labels den Text einfügen. `-AdvancedSettings` nimmt eine Hashtable mit Verhaltensschaltern; hier verlangt `requiredowngradejustification`, dass Anwender eine Begründung eingeben, wenn sie ein Label herabstufen oder entfernen. Die letzte Zeile liest die Labels mit ihrer Priorität zurück, was nach jeder Änderung eine gute Kontrolle ist.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Labels anzulegen und nicht zu veröffentlichen. Das zeigt sich so: Im Portal ist alles grün, aber in Word erscheint die Schaltfläche „Vertraulichkeit“ ohne Auswahl. Der zweite Fehler ist die Verschlüsselung ohne Plan. Eine Datei, die mit Rechten auf „nur Mitarbeitende der Organisation“ verschlüsselt ist, lässt sich vom externen Partner nicht öffnen, und automatische Suche oder Vorschauen funktionieren je nach Dienst nicht. Der dritte Fehler ist eine zu feingliedrige Struktur.

**Falsch und richtig: Veroeffentlichung**

```powershell
# FALSCH: Label angelegt, aber nie in einer Richtlinie genannt
New-Label -DisplayName "Vertraulich" -Name "Vertraulich"

# RICHTIG: Label anlegen UND in einer Richtlinie veroeffentlichen
New-Label -DisplayName "Vertraulich" -Name "Vertraulich"
New-LabelPolicy -Name "Standard" -Labels "Vertraulich" -ExchangeLocation All
```

Der Unterschied liegt im zweiten Befehl: Erst die Richtlinie macht das Label für die Zielgruppe sichtbar. Prüfen Sie nach der Veröffentlichung mit einem Testkonto, ob das Label erscheint, und rechnen Sie mit einer Verzögerung bis zur vollständigen Verteilung.

### Praxisbezug.

In einem mittelgroßen Unternehmen beginnt die Einführung typischerweise mit einem Workshop, in dem Fachbereiche ihre Dokumenttypen einer Stufe zuordnen. Das Ergebnis ist eine einseitige Klassifizierungsrichtlinie mit Beispielen. Erst danach werden die Labels technisch angelegt. Die Governance-Frage lautet später: Wer darf Labels ändern (nur das Compliance-Team, über eine Purview-Rolle), und wie wird mit Wünschen neuer Labels umgegangen?

> **Praxisbeispiel**
>
> Ein Steuerberatungsbüro führt vier Labels ein. Nach drei Monaten zeigt der Aktivitätsbericht, dass 80 Prozent der Dateien das Standardlabel „Intern“ tragen und nur wenige „Vertraulich“. Das Ergebnis wird nicht als Versagen gelesen, sondern als Ausgangspunkt: Mandantendaten werden zusätzlich durch automatische Kennzeichnung erkannt und bei Treffern auf „Vertraulich“ gehoben. Der Anteil der korrekt beschrifteten Dateien wird zur Kennzahl für das Governance-Reporting (Modul 9).

## 6.2 DLP Governance

*Data Loss Prevention* (DLP, Verhinderung von Datenverlust) ist das Regelwerk, das verhindert, dass vertrauliche Informationen unbeabsichtigt oder unbefugt die Organisation verlassen. Die Betonung liegt auf „unbeabsichtigt“: Die meisten Vorfälle sind keine Angriffe, sondern Alltagsfehler. Jemand hängt die falsche Tabelle an eine Mail an, teilt einen Ordner mit „jeder mit dem Link“ oder kopiert Kundendaten in ein privates Chatprogramm. DLP erkennt solche Situationen anhand des Inhalts und der Umstände und reagiert: Es kann den Anwender nur warnen (Richtlinientipp), eine Begründung verlangen, die Aktion blockieren oder nur protokollieren.

Eine DLP-Richtlinie besteht aus drei Teilen. Der erste Teil sind die *Orte* (Locations), an denen sie wirkt: Exchange-E-Mail, SharePoint-Websites, OneDrive-Konten, Teams-Chat und -Kanalnachrichten, Endgeräte (Windows und macOS) und weitere. Der zweite Teil sind die *Regeln* (Rules): Jede Regel enthält Bedingungen (was wird erkannt?) und Aktionen (was passiert dann?). Der dritte Teil ist der *Modus*: Eine Richtlinie läuft im Testmodus mit oder ohne Benachrichtigung, aktiv oder ausgeschaltet. Die wichtigste Governance-Regel für DLP lautet: Jede neue Richtlinie beginnt im Testmodus und wird erst nach Auswertung der Treffer scharf geschaltet.

Als Bedingung nutzt man meist *Typen vertraulicher Informationen* (Sensitive Information Types, SIT). Das sind vordefinierte Erkennungsmuster, etwa für Kreditkartennummern, IBAN oder Ausweisnummern einzelner Länder. Ein SIT kombiniert ein Muster (zum Beispiel eine Ziffernfolge mit Prüfsumme) mit unterstützenden Hinweisen in der Umgebung (Wörter wie „Kartennummer“ in der Nähe) und einer Vertrauensstufe (Confidence). Daneben lassen sich Labels als Bedingung verwenden („Inhalt trägt Label Vertraulich“), Empfängerbedingungen („an externe Adressen“) und Dateieigenschaften. Der Mix aus Muster, Label und Kontext macht Regeln präzise. Eine Regel „jede Zahl mit 16 Ziffern“ erzeugt Fehlalarme, eine Regel „Kreditkartennummer mit hoher Vertrauensstufe, mindestens zehn Treffer, Empfänger extern“ erzeugt wenige und aussagekräftige.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu DLP-Richtlinien ist der Testmodus ein ausdrücklich empfohlener Schritt vor der Aktivierung, weil man die Treffer in Berichten und im Aktivitäts-Explorer auswerten kann, ohne Anwender zu behindern. Für die Auswertung der Treffer stehen im Purview-Portal Warnungen (Alerts), der Aktivitäts-Explorer und der Inhalts-Explorer zur Verfügung. Zu beachten ist, dass sich der Funktionsumfang der Orte (zum Beispiel Endgeräte-DLP oder DLP für Teams-Chat) und die Lizenzvoraussetzungen je nach Tarif unterscheiden; prüfen Sie dies in der aktuellen Dokumentation, bevor Sie Zusagen an Fachbereiche machen.

Das Governance-Thema hinter der Technik ist die Frage, wie viel Reibung die Organisation verträgt. Jede Blockade stört Arbeit, jedes Durchlassen birgt Risiko. Bewährt hat sich ein gestuftes Modell: Bei geringer Treffermenge und niedriger Vertrauensstufe nur protokollieren, bei mittlerer Warnung mit Möglichkeit zur Begründung (Override), bei hoher Menge und hoher Vertrauensstufe blockieren und Compliance informieren. Alle Stufen erzeugen Daten, die den Regelsatz im Laufe der Zeit verbessern. Außerdem sind Ausnahmen unvermeidlich (die Buchhaltung verschickt legitim Kontonummern), und jede Ausnahme gehört dokumentiert: wer, wofür, bis wann (vergleiche Modul 8, Security Exceptions).

Das folgende Skript legt eine Richtlinie für Exchange, SharePoint und OneDrive im Testmodus an und fügt zwei Regeln hinzu: Die erste schützt Kreditkartendaten mit Blockade bei externer Weitergabe, die zweite erkennt IBAN-Nummern und warnt nur. Zuerst entsteht die Richtlinie mit Orten und Modus, danach hängt man die Regeln an. Das Cmdlet `New-DlpComplianceRule` bekommt über `-Policy` den Bezug zur Richtlinie.

**New-DlpPolicy.ps1**

```powershell
Connect-IPPSSession

New-DlpCompliancePolicy -Name "DLP Finanzdaten" `
    -ExchangeLocation All `
    -SharePointLocation All `
    -OneDriveLocation All `
    -Mode TestWithNotifications `
    -Comment "Pilot: Kreditkarte und IBAN, zuerst nur Test"

New-DlpComplianceRule -Name "Kreditkarte extern blockieren" `
    -Policy "DLP Finanzdaten" `
    -ContentContainsSensitiveInformation @{ Name = "Credit Card Number"; minCount = "1" } `
    -AccessScope NotInOrganization `
    -BlockAccess $true `
    -NotifyUser Owner `
    -GenerateAlert SiteAdmin

New-DlpComplianceRule -Name "IBAN nur warnen" `
    -Policy "DLP Finanzdaten" `
    -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "5" } `
    -NotifyUser Owner `
    -GenerateIncidentReport SiteAdmin

Get-DlpCompliancePolicy "DLP Finanzdaten" -DistributionDetail |
    Select-Object Name, Mode, DistributionStatus
```

Zeile für Zeile: `-Mode TestWithNotifications` sorgt dafür, dass Anwender Hinweise sehen, aber nichts blockiert wird. In der ersten Regel bedeutet `-AccessScope NotInOrganization`, dass die Regel nur greift, wenn Inhalte von außerhalb der Organisation zugänglich wären, und `-BlockAccess` setzt die Blockade (im Testmodus nur simuliert). In der zweiten Regel verlangt `minCount = "5"` mindestens fünf Treffer, damit eine einzelne IBAN in einer Signatur keinen Alarm auslöst. Die letzte Abfrage mit `-DistributionDetail` zeigt, ob die Richtlinie an alle Orte verteilt ist oder dort noch hängt.

### Typische Fehler und Stolperfallen.

Der klassische Fehler ist, DLP sofort im aktiven Modus mit Blockade zu starten. Das erzeugt innerhalb eines Tages Supportanrufe, weil die Buchhaltung ihre Arbeit nicht mehr tun kann, und liefert den Gegnern der Governance ein starkes Argument. Ein zweiter Fehler ist zu niedrige Schwellen, die Fehlalarme erzeugen. Ein dritter Fehler ist, DLP als reine IT-Aufgabe zu behandeln: Ohne Fachbereich, der entscheidet, was schützenswert ist, entstehen Regeln, die an der Arbeit vorbeigehen.

**Falsch und richtig: Schwelle und Modus**

```powershell
# FALSCH: aktiv, Schwelle 1, alles blockieren
New-DlpCompliancePolicy -Name "DLP" -ExchangeLocation All -Mode Enable
New-DlpComplianceRule -Name "R1" -Policy "DLP" `
  -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "1" } `
  -BlockAccess $true

# RICHTIG: Testmodus, sinnvolle Schwelle, zuerst nur Hinweis
New-DlpCompliancePolicy -Name "DLP" -ExchangeLocation All -Mode TestWithNotifications
New-DlpComplianceRule -Name "R1" -Policy "DLP" `
  -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "5" } `
  -NotifyUser Owner
```

Der Gegenentwurf zeigt drei Änderungen: Modus, Schwelle und Aktion. Aus Governance-Sicht entscheidend ist, dass der Wechsel von Test zu aktiv eine bewusste, dokumentierte Entscheidung mit Datum und Verantwortlichem ist.

### Praxisbezug.

DLP begegnet Ihnen im Projekt in zwei Formen: als Richtlinienwerk, das Compliance pflegt, und als Anwenderhinweis („Diese Nachricht enthält vertrauliche Informationen“), den der Support erklären muss. Legen Sie deshalb gemeinsam mit dem Servicedesk einen Standardtext und einen Weg für Fehlalarmmeldungen fest. Die Treffer werden zu einer Kennzahl für Modul 9 (zum Beispiel „DLP-Treffer pro 1000 Mitarbeitende und Monat“).

> **Merke**
>
> Label und DLP ergänzen sich: Das Label sagt, wie schutzwürdig eine Datei ist, die DLP-Regel sagt, was mit solchen Dateien an den Grenzen der Organisation passiert. Wer DLP ohne Labels einführt, ist auf Mustererkennung angewiesen, und wer Labels ohne DLP einführt, hat zwar Kennzeichnung, aber keine Durchsetzung an den Grenzen.

## 6.3 Retention Policies

Aufbewahrung wird oft mit dem Aufheben verwechselt. Tatsächlich beantwortet sie zwei getrennte Fragen: Wie lange *muss* ein Inhalt erhalten bleiben (zum Beispiel wegen Handels- und Steuerrecht oder aus internen Gründen), und ab wann *soll* er gelöscht werden (Datensparsamkeit, Speicherplatz, Risikominimierung)? Beide Fragen sind Governance-Fragen, weil sie jeweils ein Risiko adressieren: Wer zu früh löscht, kann gesetzliche Pflichten verletzen und Beweismittel vernichten. Wer nie löscht, sammelt Altlasten, die bei einem Vorfall oder einer Anfrage nach Betroffenenrechten teuer werden.

In Purview gibt es dafür zwei Werkzeuge: *Aufbewahrungsrichtlinien* (Retention Policies) und *Aufbewahrungslabels* (Retention Labels). Eine Richtlinie wirkt flächendeckend auf Orte, etwa „alle Exchange-Postfächer“ oder „alle Teams-Chats“, und braucht kein Zutun der Anwender. Ein Label wirkt auf einzelne Inhalte und wird entweder manuell vom Anwender, automatisch durch Regeln oder als Standard eines Ordners oder einer Bibliothek vergeben. Die Faustregel: Die Richtlinie ist das Netz, das alles auffängt, das Label ist der Stempel für Besonderheiten.

Die Einstellungen einer Aufbewahrungsregel lassen sich in vier Varianten kombinieren: nur aufbewahren, nur löschen, aufbewahren und danach löschen oder gar nichts tun. Außerdem wählt man den Beginn der Frist: das Erstellungsdatum, das Datum der letzten Änderung oder (nur bei Labels) das Datum der Beschriftung bzw. ein Ereignis wie „Vertragsende“. Bei „letzte Änderung“ verschiebt jede Bearbeitung das Fristende, was für lebendige Dokumente gewollt sein kann und für Archivmaterial nicht.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Grundsätzen der Aufbewahrung beschreibt, wie Purview Konflikte auflöst, wenn auf denselben Inhalt mehrere Richtlinien und Labels wirken. Das Ergebnis ist nicht, dass eine einzelne Richtlinie „gewinnt“, sondern Aufbewahrung und Löschung werden unabhängig voneinander aus allen Einstellungen berechnet. Die vier Prinzipien lauten: (1) Aufbewahrung gewinnt gegen Löschung, (2) die längste Aufbewahrungsdauer gewinnt, (3) explizit gewinnt gegen implizit (ein Label auf dem Element schlägt eine Richtlinie auf dem Ort), (4) die kürzeste Löschdauer gewinnt. Ein Beispiel der Dokumentation: Eine E-Mail unterliegt einer Richtlinie „nach drei Jahren löschen“ und trägt ein Label „fünf Jahre aufbewahren“. Sie wird fünf Jahre aufbewahrt und danach gelöscht. Weiter beschreibt die Dokumentation, wo aufbewahrte Kopien liegen: in SharePoint und OneDrive in der Bibliothek „Preservation Hold“, in Exchange im Ordner „Recoverable Items“ und für Teams-Nachrichten in einem versteckten Ordner „SubstrateHolds“ unterhalb davon. Da die Preservation-Hold-Bibliothek zur Speicherquote der Website zählt, kann der Speicherbedarf steigen (vergleiche Modul 4.6).

Wie wirkt Aufbewahrung „in place“? Der Inhalt bleibt, wo er ist; Anwender arbeiten wie bisher. Löscht oder ändert aber jemand einen Inhalt, der unter einer Aufbewahrungsregel liegt, legt das System unbemerkt eine Kopie im geschützten Bereich ab. Für die Anwender sieht die Datei gelöscht aus; für Compliance existiert sie weiter, bis die Frist abläuft. Nach Ablauf entfernt ein Hintergrundprozess die Kopie. Dieser Prozess läuft nicht sofort: Man darf nicht erwarten, dass am Tag des Fristendes alles verschwunden ist, sondern mit einer Verzögerung von mehreren Tagen rechnen. Das ist wichtig, wenn man Zusagen gegenüber Datenschutzbeauftragten macht.

Das folgende Skript legt eine Aufbewahrungsrichtlinie für Exchange-Postfächer und Teams-Chats an, die Inhalte sieben Jahre aufbewahrt und danach löscht, und eine zweite Richtlinie, die nur löscht. Die Richtlinie definiert die Orte, die Regel definiert Dauer und Aktion. `RetentionDuration` wird in Tagen angegeben, 2555 Tage entsprechen etwa sieben Jahren (Schaltjahre ignoriert).

**New-RetentionPolicy.ps1**

```powershell
Connect-IPPSSession

New-RetentionCompliancePolicy -Name "Mail und Chat 7 Jahre" `
    -ExchangeLocation All `
    -TeamsChatLocation All `
    -Enabled $true `
    -Comment "Geschaeftskorrespondenz: 7 Jahre aufbewahren, dann loeschen"

New-RetentionComplianceRule -Name "7 Jahre ab Erstellung" `
    -Policy "Mail und Chat 7 Jahre" `
    -RetentionDuration 2555 `
    -RetentionComplianceAction KeepAndDelete `
    -ExpirationDateOption CreationAgeInDays

Get-RetentionCompliancePolicy "Mail und Chat 7 Jahre" -DistributionDetail |
    Select-Object Name, Enabled, DistributionStatus
```

Der Ablauf: Die Richtlinie wählt Exchange und Teams-Chats als Orte. Die Regel setzt die Dauer (`-RetentionDuration 2555`), die Aktion (`KeepAndDelete`: erst halten, dann löschen) und den Fristbeginn (`CreationAgeInDays`, also ab Erstellung). Mit `-DistributionDetail` liest man den Verteilungsstatus, der bei Fehlern „Error“ oder „PendingDeletion“ statt „Success“ zeigt.

### Typische Fehler und Stolperfallen.

Der gravierendste Fehler ist, eine Löschrichtlinie ohne Prüfung der gesetzlichen Aufbewahrungspflichten zu aktivieren, denn Löschen ist nicht rückholbar. Ein zweiter Fehler ist zu viele überlappende Richtlinien, deren Ergebnis niemand mehr vorhersagen kann. Ein dritter ist die Annahme, Löschen geschehe sofort. Ein vierter betrifft die Gruppen: Eine Richtlinie für Microsoft-365-Gruppen erfasst Postfach und Website der Gruppe; wer nur Exchange einstellt, hält die Gruppen-Konversationen nicht zurück.

**Falsch und richtig: Teams und Gruppen**

```powershell
# FALSCH: Teams-Kanalnachrichten sollen aufbewahrt werden,
# aber es wurde nur Exchange gewaehlt
New-RetentionCompliancePolicy -Name "Teams" -ExchangeLocation All

# RICHTIG: Teams-Orte ausdruecklich waehlen
New-RetentionCompliancePolicy -Name "Teams" `
    -TeamsChannelLocation All -TeamsChatLocation All
```

Im Gegenbeispiel sieht man, dass Aufbewahrung ortsbezogen konfiguriert wird: Was nicht als Ort gewählt ist, wird nicht erfasst. Kontrollieren Sie nach jeder Einführung, welche Orte tatsächlich zugeordnet sind.

### Praxisbezug.

Im Projekt starten Sie mit einer Tabelle aus Datenkategorie, Rechtsgrundlage, Aufbewahrungsfrist, Verantwortlichem und Löschregel. Die Tabelle erstellt nicht die IT allein; Recht, Datenschutz und Fachbereiche sind beteiligt. Technisch entstehen daraus wenige Richtlinien (E-Mail, Teams, Dateien) und eine überschaubare Zahl von Labels (Verträge, Personalakte, Rechnungen).

> **Merke**
>
> Rechtliche Hinweise in diesem Modul (Fristen, Datenschutz, Nachweispflichten) dienen der Orientierung und sind keine Rechtsberatung. Verbindliche Aufbewahrungsfristen müssen Sie mit Ihrer Rechtsabteilung oder Ihrem Steuerberater klären. Die Zahl „sieben Jahre“ im Beispiel ist ein Beispielwert und keine Empfehlung.

## 6.4 Records Management

Manche Inhalte sind nicht nur Information, sondern Nachweis: ein unterschriebener Vertrag, eine Rechnung, ein Prüfbericht, ein Protokoll. Solche Inhalte müssen unverändert bleiben, damit sie als Beweis taugen. Der Fachbegriff dafür lautet *Record* (Geschäftsunterlage, Aufzeichnung), und das Fachgebiet heißt *Records Management*. Ein Record unterscheidet sich von einem gewöhnlichen Dokument dadurch, dass nach der Deklaration bestimmte Änderungen nicht mehr erlaubt sind: Der Inhalt darf nicht verändert werden, und der Inhalt darf je nach Strenge nicht gelöscht werden. Dazu kommt eine Pflicht zur Nachvollziehbarkeit, wann etwas deklariert, freigegeben oder entsorgt wurde.

In Purview setzt man Records mit *Aufbewahrungslabels* um, die als Record gekennzeichnet sind. Es gibt dabei zwei Strengegrade, die man scharf trennen muss. Bei einem *Record* (im Sprachgebrauch auch „gesperrter Record“) kann der Inhalt nicht mehr bearbeitet oder gelöscht werden, das Label selbst kann aber von berechtigten Personen entfernt werden. Bei einem *regulatorischen Record* (Regulatory Record) ist das Label unveränderlich: Auch Administratoren können es nach der Anwendung nicht entfernen, die Dauer nicht verkürzen. Letzteres ist für Branchen gedacht, in denen Regulierung (etwa im Finanzbereich) eine Unveränderbarkeit verlangt. Der Preis ist hoch: Ein falsch konfiguriertes regulatorisches Label lässt sich nicht zurücknehmen, und wer es auf viele Dateien automatisch anwendet, hat sich festgelegt. Deshalb gilt in Projekten: Regulatorische Records nur nach ausdrücklicher Rechtsprüfung und mit Pilotgruppe.

Eine weitere Ergänzung zum Record ist der *Dateiplan* (File Plan). Das ist eine Übersicht aller Aufbewahrungslabels mit Eigenschaften wie Referenz-ID, Fachbereich, Kategorie, Behörde und Zitat, die sich als Tabelle exportieren und importieren lässt. Für Organisationen mit formalem Records Management ist der Dateiplan das zentrale Steuerdokument; kleine Organisationen kommen ohne ihn aus. Am Ende der Frist steht die *Disposition*: die Entscheidung, ob der Inhalt gelöscht, geprüft oder dauerhaft bewahrt wird. Wenn ein Prüfer („Disposition Review“) beteiligt ist, wird die Löschung durch Menschen bestätigt, und der Beweis darüber bleibt erhalten.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Verwaltung von Records beschreibt, dass die Deklaration als Record in Purview über Aufbewahrungslabels erfolgt und dass sich die Eigenschaften „Record“ und „regulatorischer Record“ in ihrer Wirkung unterscheiden: Für regulatorische Labels sind Änderungen an der Konfiguration des Labels nach der Veröffentlichung stark eingeschränkt, und ein solches Label kann nicht von Anwendern entfernt werden. Ebenso beschreibt sie Funktionen wie den Dateiplan-Import und -Export, die Ereignis-basierte Aufbewahrung (etwa „Vertragsende“ als Startpunkt) und die Prüfung zur Entsorgung (Disposition Review). Details zu Einschränkungen (zum Beispiel, welche Aktionen auf Dateien mit Record-Label noch möglich sind) hängen vom Workload und der Version ab und sind vor dem Einsatz in der aktuellen Dokumentation zu prüfen.

Wie sieht ein Aufbewahrungslabel in der Praxis aus? Nehmen wir „Vertrag“: Das Label setzt die Aufbewahrung auf zehn Jahre ab Ende des Vertrags, markiert den Inhalt als Record und führt danach eine Prüfung durch den Fachbereich Recht aus. Das Label wird in einer Bibliothek „Verträge“ als Standardlabel gesetzt, sodass jede neue Datei es automatisch erhält. Die Wirkung für den Anwender: Eine unterschriebene Datei lässt sich nicht mehr ändern oder löschen, ohne das Label zu entfernen; wo das nicht erlaubt ist, bleibt sie schreibgeschützt. Für Dokumente, die noch in Arbeit sind, würde man den Record erst bei Freigabe deklarieren (manuell oder durch einen Workflow), damit nicht jeder Entwurf gesperrt wird.

Das Skript legt ein Aufbewahrungslabel mit Record-Eigenschaft an und veröffentlicht es über eine Aufbewahrungsrichtlinie auf die SharePoint-Websites. `New-ComplianceTag` erzeugt das Label (in der Programmierschnittstelle heißen Aufbewahrungslabels „Compliance Tags“). Die Veröffentlichung erfolgt dann über eine Richtlinie mit einer Regel, die das Label `-PublishComplianceTag` nennt.

**New-RecordLabel.ps1**

```powershell
Connect-IPPSSession

New-ComplianceTag -Name "Vertrag 10 Jahre" `
    -Comment "Unterschriebene Vertraege, Frist ab Erstellung" `
    -IsRecordLabel $true `
    -Regulatory $false `
    -RetentionAction KeepAndDelete `
    -RetentionDuration 3650 `
    -RetentionType CreationAgeInDays

New-RetentionCompliancePolicy -Name "Veroeffentlichung Vertragslabel" `
    -SharePointLocation All `
    -Enabled $true

New-RetentionComplianceRule -Name "Vertragslabel veroeffentlichen" `
    -Policy "Veroeffentlichung Vertragslabel" `
    -PublishComplianceTag "Vertrag 10 Jahre"

Get-ComplianceTag "Vertrag 10 Jahre" |
    Select-Object Name, IsRecordLabel, Regulatory, RetentionDuration
```

Die entscheidenden Zeilen sind `-IsRecordLabel $true`, das den Inhalt zum Record macht, und `-Regulatory $false`, das bewusst den weniger strengen Grad wählt. `-RetentionType CreationAgeInDays` verknüpft die Frist mit dem Erstellungsdatum. Die Veröffentlichung in der Richtlinie macht das Label an den Orten sichtbar. Ob das Label zusätzlich automatisch angewendet wird, ist ein eigener Schritt (Standardlabel einer Bibliothek oder automatische Anwendungsregel).

### Typische Fehler und Stolperfallen.

Der schwerste Fehler ist das regulatorische Label aus Neugier oder Vorsicht. Er lässt sich nicht rückgängig machen. Zweitens wird oft vergessen, dass Records Zusammenarbeit stören können: Eine Excel-Datei, die als Record deklariert ist, lässt sich nicht mehr bearbeiten, und Skripte oder Workflows, die in die Datei schreiben, scheitern mit Fehlern. Drittens ist ein Label, das man in einer Richtlinie veröffentlicht hat, noch nicht angewendet.

**Falsch und richtig: Strengegrad**

```powershell
# FALSCH: regulatorisch ohne Rechtspruefung und ohne Pilot
New-ComplianceTag -Name "Alles" -IsRecordLabel $true -Regulatory $true `
    -RetentionAction Keep -RetentionDuration 3650 -RetentionType CreationAgeInDays

# RICHTIG: zuerst als einfacher Record im Pilot, Regulatory erst nach Freigabe
New-ComplianceTag -Name "Vertrag Pilot" -IsRecordLabel $true -Regulatory $false `
    -RetentionAction Keep -RetentionDuration 3650 -RetentionType CreationAgeInDays
```

Beim Vergleich fällt auf, dass sich die beiden Befehle nur im Schalter `-Regulatory` unterscheiden. Dieser eine Schalter entscheidet, ob eine Korrektur möglich bleibt. Planen Sie daher immer eine Testumgebung ein und dokumentieren Sie die Entscheidung für den regulatorischen Grad schriftlich.

### Praxisbezug.

In Projekten taucht Records Management meist bei Verträgen, Personalakten, Rechnungen und Protokollen auf. Der Zugang erfolgt über Fachbereiche: Die Rechtsabteilung benennt Kategorien und Fristen, die IT setzt Labels und Standardlabels in Bibliotheken um. Vergessen Sie die Anwenderschulung nicht, denn eine gesperrte Datei erzeugt Support-Tickets, und der Servicedesk muss erklären können, warum.

> **Praxisbeispiel**
>
> Eine Gemeinde legt für Verträge eine Bibliothek mit Standardlabel an. Nach einem Monat melden die Mitarbeitenden, dass sich Entwürfe nicht mehr bearbeiten lassen. Die Ursache: Das Standardlabel hatte schon für Entwürfe gegolten. Die Lösung: Entwürfe liegen in einer anderen Bibliothek ohne Record-Label, und erst die freigegebene Fassung wird in die Vertragsbibliothek verschoben, wo das Label greift.

## 6.5 Data Lifecycle

Daten haben einen Lebenslauf: Sie entstehen, werden aktiv genutzt, verlieren an Bedeutung, müssen ein Weilchen aufbewahrt werden und werden schließlich entsorgt. *Data Lifecycle Management* (Datenlebenszyklus-Verwaltung) bedeutet, diesen Lauf bewusst zu steuern, statt Daten in einem Tenant anwachsen zu lassen. Die bisherigen Lerneinheiten haben die Bausteine geliefert (Labels, Aufbewahrung, Records). Diese Lerneinheit setzt sie zu einem durchgängigen Modell zusammen und führt vier Ergänzungen ein: adaptive Bereiche, ereignisbasierte Aufbewahrung, Disposition Review und Zeitpunkte der automatischen Anwendung.

Ein *adaptiver Bereich* (Adaptive Scope) ist eine Zielgruppendefinition, die sich selbst aktualisiert. Statt „diese Postfächer“ ausdrücklich aufzuzählen, definiert man eine Abfrage wie „alle Benutzer mit Abteilung gleich Finanzen“ oder „alle Websites, deren URL mit /sites/PRJ- beginnt“. Wächst die Abteilung, gilt die Richtlinie automatisch auch für die neuen Personen. Das ist der entscheidende Vorteil gegenüber statischen Zuordnungen, die Verwaltungsaufwand erzeugen. Der Nachteil: Die Abfrage setzt saubere Attribute im Verzeichnis voraus. Wer Abteilungsangaben im Entra-Verzeichnis nicht pflegt, bekommt Lücken, die niemand bemerkt. Auch hier hängt die Datenqualität am Identity-Betrieb aus Modul 2.

Die *ereignisbasierte Aufbewahrung* (Event-based Retention) startet die Frist nicht beim Erstellen, sondern bei einem fachlichen Ereignis. Typische Beispiele sind das Ausscheiden eines Mitarbeiters (Personalakte zehn Jahre nach Austritt), das Ende eines Vertrags oder der Abschluss eines Projekts. Technisch muss das Ereignis gemeldet werden, entweder manuell, über eine Schnittstelle oder durch einen Workflow aus dem Personalsystem. Dieses Zusammenspiel von Fachprozess und Technik wird gern unterschätzt: Ohne zuverlässige Meldung des Ereignisses läuft die Frist nie los, und die Daten bleiben für immer. Deshalb gehört zu jedem ereignisbasierten Label ein Verantwortlicher für die Meldung.

> **Ergänzung aus der Nachrecherche**
>
> Laut der Microsoft-Dokumentation zur Datenlebenszyklus-Verwaltung lassen sich Aufbewahrungsrichtlinien auf statische Zuordnungen (Konten, Websites, Gruppen auswählen) oder auf adaptive Bereiche anwenden; adaptive Bereiche gibt es für Benutzer, Gruppen und Websites. Die Entsorgung kann mit einer Überprüfung (Disposition Review) verbunden werden, bei der festgelegte Prüfer entscheiden, ob Inhalte gelöscht oder weiter aufbewahrt werden. Beim Löschen von Inhalten können außerdem Besonderheiten gelten: In SharePoint und OneDrive wird nach Ablauf zunächst in den Papierkorb verschoben, bevor die endgültige Entfernung erfolgt, und die Dokumentation beschreibt für dringende Fälle eine Funktion namens „Priority Cleanup“, die die Entsorgung gegenüber den normalen Prinzipien beschleunigen kann. Über Einzelheiten wie Zeitverzögerungen entscheidet die aktuelle Dokumentation; planen Sie in Projekten großzügige Puffer.

Wie setzt man all dies zu einem Gesamtbild zusammen? Eine bewährte Reihenfolge: Zuerst eine Basisrichtlinie für alle Orte mit einer überschaubaren Frist, die weder zu früh löscht noch ewig hält. Dann Labels für Besonderheiten (Verträge, Personal, Projekte). Dann adaptive Bereiche, sobald die Basis steht. Dazu kommt das operative Zusammenspiel mit dem Lebenszyklus von Teams und Websites aus den Modulen 3 und 4: Wenn ein Team nach Ablauf gelöscht wird, müssen Aufbewahrungsrichtlinien die Inhalte noch halten können. Wer Teams automatisch löscht und gleichzeitig Aufbewahrungsregeln hat, erzielt das gewünschte Ergebnis (Inhalte bleiben im Hintergrund erhalten), aber man muss testen, wie sich dies für Anwender und für spätere Suche (eDiscovery, Modul 7) darstellt.

Das Skript legt einen adaptiven Bereich für Benutzer der Abteilung „Personal“ an und eine Aufbewahrungsrichtlinie, die diesen Bereich verwendet. Das Cmdlet `New-AdaptiveScope` definiert den Bereichstyp und die Abfrage. Die Richtlinie verweist über `-AdaptiveScopeLocation` auf den Bereich. Die Dauer ist eine Beispielgröße.

**New-AdaptiveRetention.ps1**

```powershell
Connect-IPPSSession

New-AdaptiveScope -Name "Abteilung Personal" `
    -LocationType User `
    -RawQuery "Department -eq 'Personal'"

New-RetentionCompliancePolicy -Name "Personal Postfaecher 10 Jahre" `
    -AdaptiveScopeLocation "Abteilung Personal" `
    -ExchangeLocation All `
    -Enabled $true

New-RetentionComplianceRule -Name "Personal 10 Jahre" `
    -Policy "Personal Postfaecher 10 Jahre" `
    -RetentionDuration 3650 `
    -RetentionComplianceAction Keep `
    -ExpirationDateOption CreationAgeInDays
```

Das Skript arbeitet in drei Schritten. Zuerst definiert `New-AdaptiveScope` mit einer Abfrage im Filterformat (`-RawQuery`), welche Benutzer zum Bereich gehören; `-LocationType User` legt fest, dass es um Benutzer (und damit um deren Postfächer und OneDrive-Konten) geht. Dann entsteht eine Richtlinie, die statt einer festen Liste den Bereich nennt. Zuletzt hält die Regel die Inhalte zehn Jahre. Wie bei allen Beispielen dieses Moduls gilt: Die genaue Parameterkombination (hier besonders das Zusammenspiel von `-ExchangeLocation` und `-AdaptiveScopeLocation`) ist in Ihrer Umgebung gegen die aktuelle Cmdlet-Referenz zu prüfen, bevor das Skript produktiv läuft.

### Typische Fehler und Stolperfallen.

Adaptive Bereiche scheitern an schlechten Attributen: Wer die Abteilung als „Personal“, „HR“ und „Human Resources“ pflegt, erfasst nur einen Teil. Ein zweiter Fehler ist, ereignisbasierte Aufbewahrung ohne Prozess einzuführen: Das Label existiert, das Ereignis wird aber nie gemeldet. Ein dritter Fehler ist, die Entsorgung nicht zu testen, sondern zu vertrauen. Man legt daher einen Testbereich mit wenigen Dateien an, wartet den Ablauf kurzer Testfristen ab und beobachtet, was in welcher Reihenfolge passiert.

**Falsch und richtig: Abfrage**

```powershell
# FALSCH: Schreibweise haengt von jedem Pflegenden ab
New-AdaptiveScope -Name "HR" -LocationType User -RawQuery "Department -eq 'HR'"

# RICHTIG: mehrere gepflegte Schreibweisen erfassen
# und die Pflege des Attributs im Identity-Prozess regeln
New-AdaptiveScope -Name "HR" -LocationType User `
    -RawQuery "Department -eq 'Personal' -or Department -eq 'HR'"
```

Die bessere Lösung wäre eigentlich, das Attribut selbst zu bereinigen, denn Abfragen mit Aufzählungen sind eine Notlösung. Die Qualität der Quelldaten ist hier wie bei Dynamic Groups (Modul 2) die eigentliche Governance-Aufgabe.

### Praxisbezug.

In der Praxis stoßen Sie auf diese Themen, wenn Datenschutz fragt: „Löscht ihr die Daten ausgeschiedener Mitarbeiter nach der vorgesehenen Frist?“ Die ehrliche Antwort lautet fast immer: Das hängt davon ab, ob jemand das Ereignis meldet. Gute Projekte verbinden deshalb das Personalsystem mit dem Offboarding-Prozess und dokumentieren die Kette vom Ereignis bis zur Löschung, einschließlich der Verzögerungen.

## 6.6 Information Barriers

Manchmal ist nicht der Schutz einzelner Dateien das Ziel, sondern die Trennung ganzer Gruppen. In einer Bank dürfen Mitarbeitende des Investmentbereichs nicht mit der Kreditberatung über Kundenvorhaben sprechen, in einer Anwaltskanzlei darf das Team einer Partei nicht auf die Unterlagen der Gegenpartei zugreifen, in einer Behörde sollen bestimmte Abteilungen getrennt bleiben. Das Werkzeug dafür heißt *Information Barriers* (Informationsbarrieren, kurz IB). Es verhindert auf Richtlinienbasis, dass bestimmte Personengruppen miteinander kommunizieren und zusammenarbeiten, etwa in Teams-Chats, Besprechungen, Anrufen oder beim Hinzufügen zu Teams und Websites.

Der Aufbau folgt drei Begriffen. Ein *Segment* (Organization Segment) ist eine Gruppe von Benutzern, die über ein Attribut im Verzeichnis definiert wird, zum Beispiel „Abteilung gleich Handel“. Eine *IB-Richtlinie* verbindet zwei Segmente miteinander und sagt entweder „Segment A darf nicht mit Segment B kommunizieren“ (Blockieren) oder „Segment A darf nur mit Segment B und C kommunizieren“ (Erlauben). Die Richtlinie wird erst wirksam, wenn man sie *anwendet*, also ein Prozess startet, der alle Benutzer neu bewertet. Das sind drei getrennte Schritte, die oft verwechselt werden: Segmente anlegen, Richtlinien definieren und Richtlinien anwenden.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu Informationsbarrieren basieren Segmente auf Attributen aus Microsoft Entra ID, und die Richtlinien werden erst nach einem ausdrücklichen Anwendungsschritt aktiv; der Anwendungsprozess braucht je nach Größe des Tenants Zeit (die Dokumentation nennt Zeiträume im Bereich von Stunden). Zusätzlich gilt: Die Funktion ist an Voraussetzungen gebunden (unter anderem eine geeignete Lizenz und bestimmte Administratorrollen), und für das Verhalten in Teams (zum Beispiel die Suche nach Benutzern) ist die Konfiguration des begrenzten Verzeichniszugriffs relevant. Welche Workloads im Einzelnen durch Informationsbarrieren abgedeckt werden, ändert sich mit der Zeit; prüfen Sie die aktuelle Liste der unterstützten Dienste, bevor Sie den Schutz zusagen.

Warum ist das Thema Governance und nicht nur Technik? Weil die Trennung eine fachliche Entscheidung ist, die ein Konfliktmodell voraussetzt: Welche Gruppen dürfen nicht miteinander? Dieses Modell stammt aus Recht und Compliance, nicht aus der IT. Außerdem hat die Trennung Nebenwirkungen auf die ganze Organisation: Ein getrennter Benutzer sieht bestimmte Kollegen nicht in der Personensuche, kann sie nicht in Besprechungen einladen und nicht in ein gemeinsames Team aufnehmen. Wer das nicht kommuniziert, erzeugt Tickets mit „Person X ist unauffindbar“. Und: Die Barriere wirkt nur so gut wie die Attribute. Wird jemand versetzt, aber sein Attribut nicht angepasst, bleibt er im falschen Segment.

Das folgende Skript legt zwei Segmente an (Handel und Beratung) und eine IB-Richtlinie, die beide Seiten gegenseitig sperrt. Die Richtlinie wird zunächst inaktiv angelegt, damit sie noch nicht wirkt. Erst der Befehl `Start-InformationBarrierPoliciesApplication` startet die Anwendung. Zwei Richtlinien sind nötig, weil jede Richtlinie eine Richtung beschreibt.

**New-InformationBarrier.ps1**

```powershell
Connect-IPPSSession

New-OrganizationSegment -Name "Handel" `
    -UserGroupFilter "Department -eq 'Handel'"
New-OrganizationSegment -Name "Beratung" `
    -UserGroupFilter "Department -eq 'Beratung'"

New-InformationBarrierPolicy -Name "Handel blockiert Beratung" `
    -AssignedSegment "Handel" -SegmentsBlocked "Beratung" -State Inactive
New-InformationBarrierPolicy -Name "Beratung blockiert Handel" `
    -AssignedSegment "Beratung" -SegmentsBlocked "Handel" -State Inactive

# Nach Pilot und Freigabe: Richtlinien aktivieren und anwenden
Get-InformationBarrierPolicy | ForEach-Object {
    Set-InformationBarrierPolicy -Identity $_.Identity -State Active
}
Start-InformationBarrierPoliciesApplication
Get-InformationBarrierPoliciesApplicationStatus
```

Die Segmente nutzen Abfragen auf das Verzeichnisattribut `Department`. Die beiden Richtlinien beschreiben jeweils eine Richtung. Mit `-State Inactive` entstehen sie ohne Wirkung, und erst nach der Freigabe setzt die Schleife sie auf aktiv. `Start-InformationBarrierPoliciesApplication` stößt die Auswertung für alle Benutzer an, `Get-InformationBarrierPoliciesApplicationStatus` zeigt den Fortschritt. In einem echten Projekt liegt zwischen Anlegen und Aktivieren eine Prüfung der Segmentzuordnung, denn ein Benutzer in zwei Segmenten führt zu Fehlern.

### Typische Fehler und Stolperfallen.

Der erste Fehler: nur eine Richtung zu definieren. Dann kann Handel Beratung nicht erreichen, aber Beratung kann Handel anschreiben, und das Ziel ist verfehlt. Der zweite Fehler: Benutzer, die zu mehreren Segmenten gehören. Das ist nicht erlaubt und führt zu Konflikten. Der dritte: Segmente aus unsauberen Attributen. Der vierte: die Anwendung nicht zu starten oder nicht auf den Abschluss zu warten.

**Falsch und richtig: beide Richtungen**

```powershell
# FALSCH: nur eine Richtung
New-InformationBarrierPolicy -Name "Handel-Beratung" `
    -AssignedSegment "Handel" -SegmentsBlocked "Beratung" -State Active

# RICHTIG: beide Richtungen, danach anwenden und Status pruefen
New-InformationBarrierPolicy -Name "Beratung-Handel" `
    -AssignedSegment "Beratung" -SegmentsBlocked "Handel" -State Active
Start-InformationBarrierPoliciesApplication
```

Die Korrektur ergänzt die Gegenrichtung und startet die Anwendung. Beachten Sie, dass das Beispiel zeigt, wie man eine fehlende Richtung nachholt; im Projekt legt man beide Richtungen von Anfang an gemeinsam an und prüft das Ergebnis mit einem Testkonto aus jedem Segment.

### Praxisbezug.

Informationsbarrieren begegnen Ihnen in regulierten Branchen und in Organisationen mit Interessenkonflikten (Beratung und Prüfung, Handel und Analyse, Bildungsträger mit getrennten Klassen). Die Einführung ist ein Rechts- und Kommunikationsprojekt mit technischem Anteil. Dokumentieren Sie das Konfliktmodell, die Segmentdefinition und die Pflege der Attribute als Teil des Joiner-Mover-Leaver-Prozesses aus Modul 2.

## 6.7 Purview Data Map Bezug

Alle bisherigen Werkzeuge dieses Moduls setzen voraus, dass man weiß, wo die Daten liegen. In einer Organisation, die nur Microsoft 365 nutzt, ist das überschaubar: Exchange, SharePoint, OneDrive und Teams. Realistischer sind jedoch Umgebungen mit Datenbanken, Dateiservern, Cloud-Speichern, Analyseplattformen und SaaS-Anwendungen. Hier setzt der *Microsoft Purview Data Map* an: ein Dienst, der Datenquellen der gesamten Datenlandschaft registriert, durchsucht (scannt), klassifiziert und deren Metadaten in einem zentralen Verzeichnis ablegt. Aus den Metadaten entsteht ein Katalog, in dem Fachbereiche Daten finden, mit Begriffen aus einem Glossar versehen und Verantwortlichen zuordnen können, und eine Herkunftsdarstellung (Lineage), die zeigt, aus welchen Quellen ein Bericht gespeist wird.

Der Bezug zur M365-Governance liegt an drei Stellen. Erstens verwenden die Scans dieselben Klassifizierungen (Typen vertraulicher Informationen) wie DLP und automatische Kennzeichnung, sodass eine Kreditkartennummer in einer Datenbank genauso erkannt wird wie in einer Excel-Datei. Zweitens lassen sich Sensitivity Labels auf Datenobjekte außerhalb der Dokumente ausdehnen; ein Label hat dann nicht mehr nur Dateien und Container, sondern auch Tabellen und Spalten im Blick. Drittens verbindet der Katalog die technische Sicht („Tabelle X enthält Spalte Y“) mit der fachlichen Sicht („X ist ein Kundenstamm, verantwortlich ist Vertrieb“). Genau diese Verbindung ist Kern von Daten-Governance.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt den Purview Data Map als Grundlage der Purview-Angebote für Datenverwaltung: Quellen werden registriert und gescannt, Scanregeln bestimmen, welche Klassifizierungen geprüft werden, und der Katalog stellt die Ergebnisse bereit. Die Bezeichnungen und der Zuschnitt der Produkte in diesem Bereich haben sich in den letzten Jahren mehrfach geändert (Katalog, Governance-Bereiche, Datenprodukte); schlagen Sie daher die aktuellen Namen in der Dokumentation nach, bevor Sie Begriffe in Konzepten festschreiben. Preise und Lizenzmodelle der Data-Map-Dienste sind nutzungsabhängig und werden hier nicht genannt, weil sie nicht abgerufen wurden. Der Lehrplaneintrag „Purview Data Map Bezug“ verlangt keine Konfiguration, sondern das Verständnis der Schnittstellen zur M365-Governance.

Was heißt das für die Praxis in einem M365-Governance-Projekt? Sie müssen die Data Map nicht selbst betreiben, aber Sie sollten wissen, welche Fragen davor beantwortet sein müssen. Welche Datenquellen gibt es überhaupt (Inventar)? Wer verantwortet sie? Welche Klassifizierungen sind relevant? Welche Quellen enthalten personenbezogene Daten, und auf welcher Rechtsgrundlage? Ohne Antworten darauf produziert ein Scan nur eine große Liste. Der pragmatische Einstieg ist daher ein Inventar der M365-Seite, das als Vorbereitung dient und gleichzeitig der Governance von SharePoint nützt: Welche Websites existieren, wie groß sind sie, wie alt, wem gehören sie und welches Label tragen sie?

Das Skript erstellt ein solches Inventar als CSV-Datei. Es liest alle Websites mit Titel, Vorlage, Speicherverbrauch, letzter Änderung, Besitzer und Label-ID und schreibt sie in eine Tabelle. Damit entsteht eine Grundlage für Eigentümerfragen und für einen späteren Abgleich mit dem Katalog. Die Spalte `SensitivityLabel` liefert eine Kennung (GUID), die man gegen die Ausgabe von `Get-Label` auflöst; das Skript tut das, damit die Tabelle lesbar wird.

**Export-SiteInventory.ps1**

```powershell
param([Parameter(Mandatory)][string]$Tenant)

Connect-SPOService -Url "https://$Tenant-admin.sharepoint.com"
Connect-IPPSSession

$labels = @{}
Get-Label | ForEach-Object { $labels[[string]$_.Guid] = $_.DisplayName }

Get-SPOSite -Limit All -IncludePersonalSite $false |
    Select-Object Url, Title, Template, Owner,
        @{ n = 'GB';    e = { [math]::Round($_.StorageUsageCurrent / 1024, 2) } },
        LastContentModifiedDate,
        @{ n = 'Label'; e = { if ($_.SensitivityLabel) {
                                  $labels[[string]$_.SensitivityLabel] } else { '(kein Label)' } } } |
    Sort-Object GB -Descending |
    Export-Csv -Path ".\Standortinventar.csv" -NoTypeInformation -Encoding UTF8
```

Die Hashtable `$labels` übersetzt Label-GUIDs in Namen. Die berechnete Eigenschaft `GB` rechnet Megabyte in Gigabyte um, die Eigenschaft `Label` fängt Websites ohne Label ab, damit die Spalte nicht leer bleibt. Sortiert wird absteigend nach Größe, geschrieben wird mit UTF-8, damit Umlaute in Titeln erhalten bleiben. Ob die Eigenschaft `SensitivityLabel` in Ihrer Modulversion enthalten ist, prüfen Sie mit `Get-SPOSite | Get-Member`.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, die Data Map ohne Zielbild einzuführen: Man scannt alles, bekommt Tausende Treffer und weiß nicht, was man damit tun soll. Ein zweiter Fehler ist, den Scanumfang nicht nach Datenschutz zu prüfen; ein Scan liest Inhalte und Metadaten und braucht daher selbst eine Rechtsgrundlage und Berechtigungsprüfung. Ein dritter ist, den Katalog ohne Verantwortliche zu füllen, sodass jede Quelle „niemandem gehört“.

**Falsch und richtig: Inventar vor Scan**

```powershell
# FALSCH: alles scannen lassen, danach Eigentuemer suchen
# (Es gibt keine Liste der Quellen und keine Verantwortlichen.)

# RICHTIG: zuerst Inventar mit Eigentuemer, dann gezielt scannen
Get-SPOSite -Limit All -IncludePersonalSite $false |
    Where-Object { -not $_.Owner } |
    Select-Object Url, Title    # Websites ohne Besitzer zuerst klaeren
```

Das Gegenbeispiel zeigt die Reihenfolge: Erst wenn jede Quelle eine verantwortliche Person hat, lohnt sich der Scan. Besitzerlose Quellen sind die ersten Kandidaten für Aufräumarbeiten.

### Praxisbezug.

In Projekten kommt das Thema meist als Frage der Datenschutz- oder Compliance-Verantwortlichen: „Wissen wir, wo personenbezogene Daten liegen?“ Die M365-Seite beantworten Sie mit Labels, automatischer Kennzeichnung und Inventar; die Seite außerhalb von M365 ist ein Katalogprojekt, das meist die Dateneinheit oder Business Intelligence führt. Ihre Aufgabe ist die Schnittstelle: dieselben Klassifizierungen, dieselben Begriffe, dieselben Verantwortlichen.

## 6.8 Data-Governance-Troubleshooting

Fehlerbilder in der Datenverwaltung haben die Besonderheit, dass sie sich oft nicht als Fehler zeigen, sondern als Erwartung, die nicht eintritt: Das Label erscheint nicht, die DLP-Regel greift nicht, die Datei ist trotz abgelaufener Frist noch da, ein Benutzer kann plötzlich jemanden nicht finden. Ein systematisches Vorgehen verhindert, dass man in Portalen herumklickt. Bewährt hat sich eine feste Abfolge von fünf Fragen: Was genau wird erwartet und was geschieht tatsächlich? Welche Richtlinie sollte wirken? Ist sie aktiv und verteilt? Gilt sie für diesen Ort und diese Person? Gibt es einen Konflikt oder Zeitverzug?

Die erste Ursachenklasse sind Verteilungsfehler. Purview-Richtlinien sind Konfigurationen im Dienst, die in die Workloads verteilt werden müssen. Dieser Vorgang kann fehlschlagen oder dauern. Der Verteilungsstatus lässt sich per Cmdlet abfragen. Die zweite Klasse sind Bereichsfehler: Die Richtlinie ist verteilt, erfasst aber den Ort oder die Person nicht, zum Beispiel weil Teams-Orte nicht gewählt wurden oder eine Ausnahme versehentlich zu breit ist. Die dritte Klasse sind Konflikte: Mehrere Richtlinien wirken zugleich, und das Ergebnis folgt den Prinzipien der Aufbewahrung (Lerneinheit 6.3) oder der Priorität der Labels. Die vierte Klasse sind Zeitverzögerungen: Viele Funktionen wirken nicht sofort, und Tests unmittelbar nach der Änderung führen zu falschen Schlüssen. Die fünfte Klasse sind Client- und Lizenzprobleme: Eine veraltete Office-Version, fehlende Lizenz oder ein nicht unterstütztes Dateiformat.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation empfiehlt für die Wirkungskontrolle von DLP den Testmodus und die Auswertung mit Aktivitäts-Explorer und Warnungen, und sie weist darauf hin, dass sich neue oder geänderte Richtlinien erst nach einer Verteilungszeit auswirken. Für Aufbewahrung beschreibt sie die oben genannten Prinzipien und einen Ablaufplan (Flowchart), mit dem sich das Ergebnis mehrerer Einstellungen für ein einzelnes Element herleiten lässt. Konkrete Verzögerungszeiten werden in der Dokumentation je Funktion angegeben und ändern sich; verlassen Sie sich nicht auf Zahlen aus Schulungsunterlagen, sondern lesen Sie die Angaben zum jeweiligen Zeitpunkt nach.

Ein typischer Fall: „Die DLP-Regel blockiert den Versand der Kreditkartenliste nicht.“ Der Weg der Analyse führt zunächst zur Richtlinie, deren Modus man prüft: Steht sie im Testmodus, ist das Verhalten korrekt. Danach prüft man, ob der Ort Exchange gewählt ist und ob der Absender in einer Ausnahme liegt. Dann sieht man sich die Regel an: Wird die Kreditkartennummer wirklich erkannt (Vertrauensstufe, Mindestanzahl)? Am Ende hilft der Aktivitäts-Explorer, der zeigt, ob es Treffer gab und welche Aktion ausgewählt wurde. Der gleiche Gedankengang gilt für Labels (veröffentlicht? Zielgruppe? Client?) und Aufbewahrung (Ort? Frist? Konflikt?).

Das folgende Skript automatisiert die erste Frage, nämlich den Verteilungsstatus. Es listet DLP-, Aufbewahrungs- und Label-Richtlinien auf und zeigt alle, deren Verteilung nicht erfolgreich ist. Die Ausgabe ist als Einstieg bei jeder Störungsmeldung gedacht. Die drei Abfragen verwenden dieselbe Struktur; `-DistributionDetail` liefert den Status, der sonst nicht in der Standardausgabe steht.

**Test-PurviewDistribution.ps1**

```powershell
Connect-IPPSSession

$ergebnis = @()
$ergebnis += Get-DlpCompliancePolicy -DistributionDetail |
    Select-Object @{n='Typ';e={'DLP'}}, Name, Mode, DistributionStatus
$ergebnis += Get-RetentionCompliancePolicy -DistributionDetail |
    Select-Object @{n='Typ';e={'Aufbewahrung'}}, Name,
        @{n='Mode';e={ if ($_.Enabled) {'Enabled'} else {'Disabled'} }}, DistributionStatus
$ergebnis += Get-LabelPolicy |
    Select-Object @{n='Typ';e={'Label'}}, Name,
        @{n='Mode';e={'-'}}, DistributionStatus

$ergebnis | Where-Object { $_.DistributionStatus -ne 'Success' } |
    Format-Table -AutoSize

Write-Host ("Geprueft: {0} Richtlinien, davon auffaellig: {1}" -f `
    $ergebnis.Count, ($ergebnis | Where-Object { $_.DistributionStatus -ne 'Success' }).Count)
```

Das Skript sammelt alle Richtlinien in einer Liste und vereinheitlicht die Spalten, indem es eigene Eigenschaften (`Typ`, `Mode`) berechnet. Der Filter am Ende zeigt nur Richtlinien, deren Verteilungsstatus nicht `Success` ist, und die Zusammenfassung gibt die Zahl der geprüften und auffälligen Richtlinien aus. Den Zustand `Pending` bewertet man als „noch warten“, `Error` als „Detailmeldung lesen und gegebenenfalls Richtlinie neu verteilen“.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler beim Troubleshooting ist, mit dem Testkonto sofort nach der Änderung zu prüfen und aus dem Ausbleiben der Wirkung zu schließen, die Konfiguration sei falsch. Zweitens wird mit Administratorkonten getestet, die Ausnahmen oder andere Lizenzen haben. Drittens ändert man bei Fehlersuche mehrere Dinge zugleich und weiß hinterher nicht, was geholfen hat. Viertens wird die Lösung nicht dokumentiert, und derselbe Fall tritt nach drei Monaten wieder auf.

**Falsch und richtig: Fehlersuche**

```powershell
# FALSCH: Richtlinie loeschen und neu anlegen, "damit es geht"
Remove-DlpCompliancePolicy -Identity "DLP Finanzdaten"
New-DlpCompliancePolicy -Name "DLP Finanzdaten" -ExchangeLocation All -Mode Enable

# RICHTIG: Zustand lesen, Ursache eingrenzen, genau eine Aenderung
Get-DlpCompliancePolicy "DLP Finanzdaten" -DistributionDetail |
    Format-List Name, Mode, ExchangeLocation, DistributionStatus
Get-DlpComplianceRule -Policy "DLP Finanzdaten" |
    Format-List Name, Disabled, BlockAccess, ContentContainsSensitiveInformation
```

Die richtige Variante liest zuerst den Zustand aus, und die Änderung folgt erst nach der Diagnose. Löschen und neu anlegen vernichtet außerdem die Beweislage und kann Verlaufsdaten kosten.

### Praxisbezug.

Für den Betrieb lohnt sich ein Störungsleitfaden mit den fünf Klassen und je einem Prüfschritt, ergänzt um Standardantworten für den Servicedesk. Er ist Bestandteil der Runbooks in Modul 9. Wer einen Fall gelöst hat, trägt Ursache und Lösung in diesen Leitfaden ein; so entsteht über Monate ein belastbares Wissen, das auch neuen Kolleginnen und Kollegen hilft.

> **Merke**
>
> Wer Datenverwaltung prüft, trennt sauber: Existiert die Richtlinie? Ist sie verteilt? Gilt sie für Ort und Person? Gibt es Konflikte? Ist genug Zeit vergangen? Jede dieser Fragen hat ein eigenes Cmdlet oder einen eigenen Bericht.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Erklären Sie in eigenen Worten den Unterschied zwischen einem Sensitivity Label und einer Labelrichtlinie. Warum sieht ein Anwender ein angelegtes Label nicht, wenn es in keiner Richtlinie veröffentlicht ist?

**Aufgabe 2 (leicht).** Nennen Sie die drei Teile einer DLP-Richtlinie und beschreiben Sie, warum eine neue Richtlinie immer im Testmodus beginnt.

**Aufgabe 3 (leicht).** Welche der folgenden Aussagen zur Aufbewahrung ist richtig? (a) Die kürzeste Aufbewahrung gewinnt. (b) Aufbewahrung gewinnt gegen Löschung. (c) Das zuletzt angelegte Label gewinnt. Begründen Sie.

**Aufgabe 4 (mittel).** Entwerfen Sie eine Labelstruktur für ein Unternehmen mit rund 500 Mitarbeitenden: vier Labels, je ein Tooltip mit Beispiel, ein Standardlabel und eine Aussage, wann Verschlüsselung sinnvoll ist.

**Aufgabe 5 (mittel).** Schreiben Sie ein PowerShell-Skript, das eine DLP-Richtlinie für Exchange im Testmodus anlegt und eine Regel hinzufügt, die bei mindestens drei IBAN-Treffern den Besitzer benachrichtigt, ohne zu blockieren.

**Aufgabe 6 (mittel).** Ein Mitarbeiter meldet, dass er eine als Record gekennzeichnete Vertragsdatei nicht mehr ändern kann. Beschreiben Sie, wie Sie den Fall bewerten, und nennen Sie zwei Möglichkeiten, wie Sie den Arbeitsablauf anpassen könnten.

**Aufgabe 7 (schwer).** Schreiben Sie ein Skript, das alle Aufbewahrungsrichtlinien ausliest und diejenigen anzeigt, die nicht aktiviert oder nicht erfolgreich verteilt sind. Erläutern Sie die wichtigsten Zeilen.

**Aufgabe 8 (schwer).** Eine Anwaltskanzlei will die Teams der Mandate A und B so trennen, dass sich die Anwälte nicht gegenseitig finden. Entwerfen Sie ein Konzept mit Informationsbarrieren (Segmente, Richtlinien, Anwendung), nennen Sie Voraussetzungen und beschreiben Sie zwei Risiken.

## Lösungen

**Lösung 1.** Das Label ist die Definition der Einstufung (Name, Beschreibung, Schutzaktionen). Die Labelrichtlinie veröffentlicht Labels an Benutzergruppen und bestimmt das Verhalten (Pflicht, Standard, Begründung). Ein Label, das in keiner Richtlinie steht, wird niemandem angeboten und kann deshalb nicht manuell angewendet werden. Es ist, als würde man einen Stempel anfertigen und ihn dann im Schrank lassen.

**Lösung 2.** Die drei Teile sind Orte, Regeln (Bedingungen und Aktionen) und Modus. Der Testmodus verhindert, dass Fehlalarme den Betrieb stören. Im Testmodus lassen sich Treffer in Berichten und im Aktivitäts-Explorer auswerten, Schwellenwerte anpassen und Ausnahmen identifizieren. Die Aktivierung ist dann eine bewusste, dokumentierte Entscheidung.

**Lösung 3.** Richtig ist (b): Aufbewahrung gewinnt gegen Löschung. Die Aussage (a) ist falsch, denn bei der Aufbewahrung gilt die längste Frist. Die Aussage (c) ist falsch, denn es gibt keine Regel „zuletzt angelegt gewinnt“; maßgeblich sind die vier Prinzipien (Aufbewahrung vor Löschung, längste Aufbewahrung, explizit vor implizit, kürzeste Löschdauer).

**Lösung 4.** Ein möglicher Entwurf: Öffentlich (Tooltip: Speisekarte, Pressemitteilung), Intern (Standard, Tooltip: interne Mitteilungen, Protokolle), Vertraulich (Verträge, Preise, Personaldaten), Streng vertraulich (Vorstandsunterlagen, Fusionsprojekte). Intern ist das Standardlabel, damit keine Datei ohne Einstufung bleibt. Verschlüsselung ist ab Vertraulich sinnvoll, wenn der Empfängerkreis klar ist, und bei Streng vertraulich üblich. Dabei muss die Zusammenarbeit mit Externen geplant sein, denn verschlüsselte Dateien benötigen berechtigte Identitäten.

**Lösung 5.** Ein Lösungsvorschlag:

```powershell
Connect-IPPSSession
New-DlpCompliancePolicy -Name "DLP IBAN Mail" -ExchangeLocation All `
    -Mode TestWithNotifications
New-DlpComplianceRule -Name "IBAN ab drei Treffern" -Policy "DLP IBAN Mail" `
    -ContentContainsSensitiveInformation @{
        Name = "International Banking Account Number (IBAN)"; minCount = "3" } `
    -NotifyUser Owner
```

Die Richtlinie läuft im Testmodus, die Schwelle liegt bei drei Treffern, und es gibt keine Blockadeaktion. Der Besitzer erhält eine Benachrichtigung.

**Lösung 6.** Bewertung: Das Verhalten ist gewollt, wenn die Datei zu Recht als Record deklariert wurde. Zu prüfen ist, ob die Datei bereits abgeschlossen ist oder noch ein Entwurf war. Zwei Anpassungen: (1) Entwürfe liegen in einer Bibliothek ohne Record-Label, das Label wird erst bei Freigabe angewendet. (2) Für Änderungen nach Unterschrift wird eine neue Version als eigenes Dokument angelegt, das verweist auf das ursprüngliche. Eine dritte Variante wäre, das Label durch eine berechtigte Person entfernen zu lassen, wenn es sich nicht um einen regulatorischen Record handelt, und dies zu protokollieren.

**Lösung 7.** Ein möglicher Lösungsvorschlag:

```powershell
Connect-IPPSSession
Get-RetentionCompliancePolicy -DistributionDetail |
    Where-Object { -not $_.Enabled -or $_.DistributionStatus -ne 'Success' } |
    Select-Object Name, Enabled, DistributionStatus |
    Format-Table -AutoSize
```

Das Cmdlet liest alle Aufbewahrungsrichtlinien mit Verteilungsdetails. Der Filter zeigt Richtlinien, die entweder nicht aktiviert sind oder deren Verteilungsstatus nicht `Success` ist. Die Auswahl der Spalten und die tabellarische Ausgabe erleichtern die Weitergabe an den Betrieb.

**Lösung 8.** Konzept: Zwei Segmente (Mandat A und Mandat B) anhand eines Verzeichnisattributs, zum Beispiel einer Abteilung oder eines benutzerdefinierten Attributs. Zwei Richtlinien, je eine pro Richtung (A blockiert B, B blockiert A), zunächst inaktiv. Nach Prüfung der Zuordnung aktivieren und mit `Start-InformationBarrierPoliciesApplication` anwenden, den Status überwachen. Voraussetzungen: geeignete Lizenz und Administratorrolle, sauber gepflegte Attribute, Klärung der Wirkung auf die Personensuche in Teams. Risiken: (1) Falsche oder veraltete Attribute führen zu Fehlzuordnungen, deshalb gehört die Attributpflege in den Versetzungsprozess. (2) Die Barriere deckt nur die unterstützten Dienste ab; Kommunikation außerhalb (private Kanäle, externe Tools) bleibt ungeschützt und braucht organisatorische Regeln.
