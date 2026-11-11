# Modul 03: Teams Governance und Collaboration Lifecycle

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 3 (Seiten 54 bis 73). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 9 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 3.1 | Teams Lifecycle | 1 | 1 |
| 3.2 | Naming und Templates | 1 | 1 |
| 3.3 | Teams Creation Controls | 1 | 1 |
| 3.4 | Guest und External Access | 1 | 1 |
| 3.5 | Channels und Shared Channels | 1 | 1 |
| 3.6 | Apps und Tabs Governance | 1 | 2 |
| 3.7 | Teams Archiving | 1 | 2 |
| 3.8 | Teams-Troubleshooting | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 18 | `skripte/Get-TeamsInventory.ps1` | offline getestet |
| 19 | `skripte/Test-TeamNaming.ps1` | offline getestet |
| 20 | `skripte/Set-GroupCreationControl.ps1` | offline getestet |
| 21 | `skripte/Get-TeamsGuestReport.ps1` | offline getestet |
| 22 | `skripte/Get-TeamsChannelReport.ps1` | offline getestet |
| 23 | `skripte/Get-RiskyConsents.ps1` | offline getestet |
| 24 | `skripte/Invoke-TeamArchive.ps1` | offline getestet |
| 25 | `skripte/Get-TeamStatus.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-03-teams/tests/modul-03.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Tests laufen gegen simulierte Graph-Cmdlets und erfundene Beispieldaten (`tools/fixtures/teams-klein.json`: 7 Teams, eine nicht-Teams-Gruppe, 3 Apps mit Zustimmungen). Beim Archivierungsskript wird geprüft, dass der Probelauf **nichts** archiviert und dass Teams mit Gästen übersprungen werden. Die Wirkung im echten Tenant (z. B. wie lange eine Einstellung zur Gruppenerstellung braucht) ist nicht getestet.

## Hinweise zu einzelnen Skripten

- `Set-GroupCreationControl.ps1` nutzt Beta-Cmdlets (`Get-MgBetaDirectorySetting` usw.); deren Verhalten kann sich ändern.
- `Invoke-TeamArchive.ps1`: ohne `-Ausfuehren` nur Probelauf. Teams mit Gästen werden übersprungen und gemeldet.
- `Test-TeamNaming.ps1`: Der Operator `-match` unterscheidet nicht zwischen Groß- und Kleinschreibung. Ein Name wie `abt-Einkauf-Lieferanten` gilt daher als konform. Für eine strenge Prüfung wäre `-cmatch` nötig (vom Test dokumentiert, im Skript nicht geändert).
- `aufgabe-08-archivierung-mit-protokoll.ps1`: prüft anders als `Invoke-TeamArchive.ps1` **nicht**, ob das Team Gäste hat; das war in der Aufgabe nicht verlangt.
- `Get-TeamsChannelReport.ps1`: Teams, deren Kanäle nicht gelesen werden dürfen, erscheinen als Warnung statt als Abbruch.
