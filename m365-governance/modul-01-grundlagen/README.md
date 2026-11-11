# Modul 01: Grundlagen, Governance-Modell und Zielarchitektur

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 1 (Seiten 5 bis 29). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 8 Stunden (Blatt „Lehrplan in Modulen“; die Summe der acht Lerneinheiten im Blatt „Lehrplan in Details“ beträgt ebenfalls 8 Stunden)
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 1.1 | Governance-Grundlagen | 1 | 3 |
| 1.2 | Operating Model | 1 | 1 |
| 1.3 | M365 Workload Landscape | 1 | 1 |
| 1.4 | Rollen und Verantwortlichkeiten | 1 | 1 |
| 1.5 | Policy Framework | 1 | 1 |
| 1.6 | Tenant Baseline | 1 | 2 |
| 1.7 | Governance Roadmap | 1 | 2 |
| 1.8 | Zielarchitektur | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 1 | `skripte/Get-TenantSnapshot.ps1` | offline getestet |
| 2 | `skripte/Find-GroupsWithFewOwners.ps1` | offline getestet |
| 3 | `skripte/Get-LicenseOverview.ps1` | offline getestet |
| 4 | `skripte/Get-GlobalAdminReport.ps1` | offline getestet |
| 5 | `skripte/policy-tenant.json` | JSON geprüft |
| 6 | `skripte/Test-PolicyCompliance.ps1` | offline getestet |
| 7 | `skripte/Test-TenantBaseline.ps1` | offline getestet |
| 8 | `skripte/New-GovernanceBacklog.ps1` | offline getestet |
| 9 | `skripte/Export-GroupArchitecture.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

Die gekennzeichneten Skripte laufen offline gegen simulierte Graph-Cmdlets (`tools/Mock-MgGraph.ps1`) und erfundene Beispieldaten (`tools/fixtures/tenant-klein.json`):

```powershell
pwsh -NoProfile -File modul-01-grundlagen/tests/modul-01.tests.ps1
```

Alle Tests des Repositories auf einmal (mit Syntaxprüfung), aus dem Hauptordner: `pwsh -NoProfile -File tools/Invoke-Tests.ps1`.

Die Tests prüfen die Logik (Zählen, Schwellenwerte, Sortierung, Fehlerbehandlung) und dass die Skripte nur lesende Berechtigungen anfordern. Sie beweisen nicht, dass das echte Microsoft Graph genauso antwortet.

## Zusätzliche Dateien

- `loesungen-skripte/`: die Lösungen zu den Praxisaufgaben 4, 5 und 8 als lauffähige Skripte. Das Skript zeigt dort nur Ausschnitte; das Einsetzen in das jeweilige Listing stammt aus diesem Repository.
