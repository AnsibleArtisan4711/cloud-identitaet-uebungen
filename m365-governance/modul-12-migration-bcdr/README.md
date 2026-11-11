# Modul 12: Migration, Kosten, Adoption und BCDR

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 12 (Seiten 247 bis 270). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 9 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 2 (mittlere Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 12.1 | Ist-Analyse | 1 | 1 |
| 12.2 | Governance Maturity | 1 | 1 |
| 12.3 | Kostenmodell | 1 | 1 |
| 12.4 | Adoption und Change | 1 | 1 |
| 12.5 | Training und Champions | 1 | 1 |
| 12.6 | BCDR für M365 Governance | 1 | 2 |
| 12.7 | Kontinuierliche Verbesserung | 1 | 2 |
| 12.8 | 30-60-90-Tage-Roadmap | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 151 | `skripte/Get-TenantBaseline.ps1` | offline getestet |
| 153 | `skripte/Get-MaturityPriorities.ps1` | offline getestet |
| 155 | `skripte/New-ShowbackReport.ps1` | offline getestet |
| 157 | `skripte/Get-AdoptionByDepartment.ps1` | Logik offline getestet (an einer Kopie); das Original ist nicht lauffähig |
| 159 | `skripte/Test-ChampionCoverage.ps1` | offline getestet |
| 161 | `skripte/Get-SoftDeletedObjects.ps1` | offline getestet |
| 163 | `skripte/Find-KpiTrends.ps1` | offline getestet |
| 165 | `skripte/roadmap.json` | JSON geprüft |
| 166 | `skripte/Test-Roadmap.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-12-migration-bcdr/tests/modul-12.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Vier Skripte sprechen Microsoft Graph an (`Get-TenantBaseline.ps1`, `Get-AdoptionByDepartment.ps1`, `Test-ChampionCoverage.ps1`, `Get-SoftDeletedObjects.ps1`). Dafür gibt es `tools/Mock-Betrieb.ps1` mit erfundenen Beispieldaten in `tools/fixtures/betrieb-klein.json` (acht Benutzer, davon ein Gast und ein deaktiviertes Konto; sechs Gruppen, davon zwei Microsoft-365-Gruppen ohne Besitzer; zwei vorläufig gelöschte Benutzer und eine gelöschte Gruppe). Die Datei überschreibt mehrere Funktionen anderer Mocks und wird deshalb nur in den Tests dieses Moduls geladen. Sie verlangt für die Anzahl-Abfragen `-ConsistencyLevel eventual` und kennt nur den Filter `userType eq 'Guest'`. Den Typ von `DeletedDateTime` habe ich **angenommen** (`DateTime`); ob Ihre Version des Graph-Moduls `DateTime` oder `DateTimeOffset` liefert, habe ich nicht geprüft (siehe Hinweise zu `Get-SoftDeletedObjects.ps1`).

Die übrigen Skripte (`Get-MaturityPriorities.ps1`, `New-ShowbackReport.ps1`, `Find-KpiTrends.ps1`, `Test-Roadmap.ps1`) und die Lösung zu Aufgabe 6 brauchen keine Simulation; sie laufen mit erfundenen Dateien in einem Wegwerf-Ordner. Die Kosten, Preise und Kontingente in den Tests sind **erfundene Rechenbeispiele** und keine Preise von Microsoft.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Parameter, Berechtigungen, Filter und die Frist von 30 Tagen für gelöschte Objekte habe ich **nicht** mit der aktuellen Dokumentation verglichen.

- **`Get-AdoptionByDepartment.ps1` ist nicht lauffähig.** Die Funktion `Test-Aktiv` setzt `$d = $null` und ruft dann `[datetime]::TryParse($text, [ref]$d)` auf. Mit `$null` als Anfangswert findet PowerShell die passende Überladung nicht, das Skript bricht ab (der Test prüft das Original auf genau diesen Fehler). Die Tests führen die Logik an einer **Kopie** aus, in der der Anfangswert `[datetime]::MinValue` ist. Behebung im Original: diese eine Zeile ändern. Ob der Fehler in Windows PowerShell 5.1 gleich auftritt, zeigt der Testlauf dort. Weitere Punkte: Konten, die im Verzeichnis fehlen oder deaktiviert sind, zählen nicht mit; Zeilen mit `Is Deleted` = `True` werden übergangen; ist die Abteilung leer oder besteht nur aus Leerzeichen, steht „(ohne Abteilung)“; genau `-Tage` Tage zurück zählt noch als aktiv. Sind die Benutzernamen im Bericht verborgen (Hash statt Name), bricht das Skript mit einer Meldung ab.
- **`Get-SoftDeletedObjects.ps1`:** Die Zeile `(Get-Date) - $objekt.DeletedDateTime` setzt voraus, dass der Löschzeitpunkt ein `DateTime` ist. Liefert Ihre Version des Graph-Moduls einen `DateTimeOffset`, scheitert die Subtraktion mit der Meldung „op_Subtraction“ (der Test zeigt das mit einem simulierten `DateTimeOffset`). Welchen Typ Ihre Version liefert, habe ich nicht geprüft. Die verbleibenden Tage werden aus der **gerundeten** Zahl vergangener Tage berechnet: 5,6 Tage ergeben 6, die Rest-Tage also 24 statt rund 24,4. Die Warnung gilt ab der Schwelle selbst („kleiner oder gleich“).
- **`Find-KpiTrends.ps1`:** Als „höher ist besser“ gilt nur das Wort `hoeher` (Groß-/Kleinschreibung egal). `höher` mit Umlaut, ein Tippfehler oder ein leeres Feld werden stillschweigend wie „niedriger ist besser“ behandelt, die Befunde sind dann umgekehrt. Ein Komma als Dezimalzeichen wird nicht als solches gelesen: `98,5` wird zu `985` (PowerShell wandelt Text beim Umwandeln in Zahlen mit dem invarianten Format um, in dem das Komma als Tausendertrenner gilt). Ziel und Richtung werden nur der **letzten** Zeile je Kennzahl entnommen. Ein Trend wird nur gemeldet, wenn es mehr Werte als `-Perioden` gibt und jeder Schritt **streng** schlechter ist; gleichbleibende Werte brechen die Reihe ab. Die Datums-Spalte wird als Datum sortiert.
- **`New-ShowbackReport.ps1`:** `[math]::Round` rundet auf die nächste gerade Zahl (0,125 ergibt 0,12, nicht 0,13). Ein Komma in den CSV-Zahlen wird als Tausendertrenner gelesen (`2,5` wird zu `25`). Der Mehrverbrauch an Speicher wird nach dem Anteil am Gesamtspeicher verteilt, die Sicherung nach eigenem Verbrauch und ohne freies Kontingent. Die Summe addiert die bereits gerundeten Teilbeträge. Preise und Kontingent sind Eingaben; das Skript kennt keine echten Preise. Die Ausgabedatei `showback.csv` enthält die Beträge in Windows PowerShell 5.1 mit dem Dezimalzeichen der Systemsprache (auf einem deutschsprachigen System `12,00`, Testlauf), in PowerShell 7 mit Punkt (`12.00`); wer die Datei mit `Import-Csv` und `[decimal]` weiterverarbeitet, liest `12,00` als 1200.
- **`Test-ChampionCoverage.ps1`:** Die Abteilungsnamen werden ohne Beachtung der Groß-/Kleinschreibung zugeordnet, ein Leerzeichen am Ende („IT “) führt aber dazu, dass der Champion nicht zählt. Abteilungen aus der Champion-Liste, die im Verzeichnis nicht vorkommen, werden ignoriert. Gäste, deaktivierte Konten und Konten ohne Abteilung zählen nicht zu den Beschäftigten. Die Soll-Zahl ist die aufgerundete Zahl der Beschäftigten geteilt durch `-BeschaeftigtePorChampion`.
- **`Get-TenantBaseline.ps1`:** Das Skript fragt die Besitzer **je Gruppe** einzeln ab (bei großen Tenants viele Aufrufe). Gibt es genau eine Microsoft-365-Gruppe, hat `$gruppen.Count` in Windows PowerShell 5.1 vermutlich keinen Wert (ein einzelnes Objekt hat dort keine Eigenschaft `Count`), und die Zeile „Microsoft-365-Gruppen“ bleibt leer; in PowerShell 7 steht 1. Ohne Gruppen steht 0 (0 %), ohne Division durch null.
- **`Get-MaturityPriorities.ps1`:** Fehlt die Spalte `Gewicht`, ist jede Priorität 0, ohne Hinweis. Ein Text statt einer Zahl als Stufe bricht mit einer Umwandlungsfehlermeldung ab. Ein Ziel unter dem Ist-Wert erzeugt eine Warnung und die Lücke 0.
- **`Test-Roadmap.ps1` und `roadmap.json`:** Die mitgelieferte `roadmap.json` ist ein **Auszug** und selbst nicht stimmig: Aufgabe B2 beginnt an Tag 40, ihr Vorgänger B1 endet erst an Tag 45. Das Skript meldet das und endet mit Exit-Code 2; die Markdown-Tabelle wird trotzdem geschrieben. Endet ein Vorgänger an dem Tag, an dem die Folgeaufgabe beginnt, gilt das bereits als Konflikt. Die Phase richtet sich nur nach dem **Beginn** (Tag 1 bis 30, 31 bis 60, ab 61); eine Aufgabe zählt mit allen Stunden in der Phase, in der sie beginnt, auch wenn sie länger läuft. Die Grenze `stundenProPersonUndPhase` selbst ist erlaubt.
- **Lösung zu Aufgabe 6:** Gibt es genau **eine** große Abteilung und zusätzlich kleine, bricht das Skript beim Anhängen der Sammelzeile ab (`$ausgabe` ist dann ein einzelnes Objekt, `+=` funktioniert nicht). Ein Ausweg ist `$ausgabe = @(foreach ...)`. Mit `-Mindestgroesse 0` und einer Abteilung ohne Beschäftigte entsteht eine Division durch null.
