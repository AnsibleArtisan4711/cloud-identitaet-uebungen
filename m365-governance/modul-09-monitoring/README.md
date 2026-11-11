# Modul 09: Monitoring, Reporting und Service Operations

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 9 (Seiten 178 bis 198). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 8 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 9.1 | Admin Center Reports | 1 | 1 |
| 9.2 | Usage Analytics | 1 | 1 |
| 9.3 | Purview Reports | 1 | 1 |
| 9.4 | Defender Reports | 1 | 1 |
| 9.5 | Entra Monitoring | 1 | 1 |
| 9.6 | Service Health | 1 | 2 |
| 9.7 | Operational Runbooks | 1 | 2 |
| 9.8 | Governance KPIs | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 98 | `skripte/Get-InactiveLicensedUsers.ps1` | offline getestet |
| 100 | `skripte/Get-StaleSiteStats.ps1` | Logik offline getestet (an einer Kopie); das Original ist nicht lauffähig |
| 102 | `skripte/Get-LabelActivity.ps1` | offline getestet |
| 104 | `skripte/Get-IncidentTimes.ps1` | offline getestet |
| 106 | `skripte/Notfallkonto-Anmeldungen.kql` | nicht ausgeführt (KQL) |
| 107 | `skripte/Test-EntraLogFlow.ps1` | offline getestet |
| 108 | `skripte/Falsch-und-richtig-Aenderungen-an-Richtlinien.kql` | nicht ausgeführt (KQL) |
| 109 | `skripte/Get-ServiceStatus.ps1` | offline getestet |
| 111 | `skripte/Test-Runbooks.ps1` | offline getestet |
| 113 | `skripte/kpi-definition.json` | JSON geprüft |
| 114 | `skripte/Get-KpiStatus.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-09-monitoring/tests/modul-09.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Sieben Skripte sprechen Microsoft Graph oder Exchange Online an. Dafür gibt es `tools/Mock-Monitoring.ps1` mit erfundenen Beispieldaten in `tools/fixtures/monitoring-klein.json` (Nutzungsberichte als CSV-Dateien, Label-Aktivität im Überwachungsprotokoll, Vorfälle, Dienstintegrität, Nachrichtencenter, Protokollfluss). Die Datei überschreibt `Connect-MgGraph` und `Get-MgAuditLogSignIn` aus `Mock-MgGraph.ps1` und wird deshalb nur in den Tests dieses Moduls geladen. `Test-Runbooks.ps1` und `Get-KpiStatus.ps1` brauchen keine Simulation; sie laufen mit erfundenen Dateien in einem Wegwerf-Ordner.

Die Simulation prüft, **welche Werte übergeben werden** (Zeitraum, Filter, Operationen) und wie die Skripte Daten auswerten. Aufbau und Kodierung der echten Berichtsdateien sind nur nachgebildet, nicht geprüft (siehe Kopf von `Mock-Monitoring.ps1`). Die KQL-Abfragen (`*.kql`) wurden nicht ausgeführt.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Parameter, Berechtigungen und Filter der Cmdlets habe ich **nicht** mit der aktuellen Dokumentation verglichen.

**Nicht lauffähig: `[datetime]::TryParse` mit `$null`.** `Get-StaleSiteStats.ps1` und die Lösung zu Aufgabe 4 setzen `$d = $null` und übergeben `[ref]$d` an `[datetime]::TryParse(...)`. In PowerShell 7.4.6 und in Windows PowerShell 5.1 (Testlauf des Anwenders am 07.11.2026) endet das mit „Für "TryParse" und die folgende Argumenteanzahl kann keine Überladung gefunden werden: "2"“ (englisch: „Cannot find an overload for "TryParse"…“); die Skripte brechen ab, bevor sie etwas ausgeben. Mit dem Anfangswert `[datetime]::MinValue` läuft derselbe Aufruf (Vorschlag, nicht eingebaut). Die Logik-Tests laufen deshalb an einer Kopie mit diesem Anfangswert; ein eigener Test hält fest, dass das Original scheitert. Dasselbe Muster scheiterte in Modul 07 ebenfalls.

Weitere Punkte:

- **`Get-InactiveLicensedUsers.ps1`:** Berichte sind auf 90 Tage begrenzt; „ohne Aktivität“ heißt hier „kein Datum in den letzten 90 Tagen“. Die Berichtsdatei enthält Benutzerprinzipalnamen (personenbezogen) und liegt danach im Arbeitsordner; nach der Auswertung löschen. Sind die Namen verborgen (Datenschutzeinstellung), zählt das Skript trotzdem und weist darauf hin.
- **`Get-StaleSiteStats.ps1`:** (zusätzlich zum Fund oben) Der Bericht reicht höchstens 180 Tage zurück; mit `-InaktivTage` über 180 liefert das Skript keine sinnvolle Aussage. Websites ohne Datum gelten als ruhend. Datumswerte werden mit der Spracheinstellung des Rechners gelesen.
- **`Get-LabelActivity.ps1`:** Es gibt keine Seitenabfrage; bei 5000 Treffern warnt das Skript nur. Die Operationsnamen habe ich nicht geprüft (das Skript weist selbst darauf hin).
- **`Get-IncidentTimes.ps1`:** Die „mittlere Dauer“ ist eine Näherung aus `LastUpdateDateTime` minus `CreatedDateTime` und sagt nichts über die tatsächliche Lösungszeit.
- **`Get-ServiceStatus.ps1`:** Die Filter für Störungen und Nachrichten sind in der Simulation nachgebildet; ob der echte Dienst sie so annimmt, habe ich nicht geprüft.
- **`Test-Runbooks.ps1`:** Die Überschriften müssen genau die ASCII-Schreibweise haben („Pruefung“, „Rueckweg“); „Prüfung“ mit Umlaut gilt als fehlend. Die Datumszeile „Letzte Pruefung: JJJJ-MM-TT“ wird nicht als Überschrift gewertet.
- **`Get-KpiStatus.ps1`:** Jeder Lauf hängt Zeilen an die Verlaufsdatei an; zwei Läufe am selben Tag ergeben doppelte Einträge. Die Schwellenwerte sind Beispielwerte aus `kpi-definition.json`.
