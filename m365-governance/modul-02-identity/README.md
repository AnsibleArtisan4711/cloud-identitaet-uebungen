# Modul 02: Identity Governance und Zugriffskontrolle

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 2 (Seiten 30 bis 53). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 9 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 2.1 | Entra ID Governance | 1 | 1 |
| 2.2 | Lifecycle Workflows | 1 | 1 |
| 2.3 | Access Packages | 1 | 1 |
| 2.4 | Access Reviews | 1 | 1 |
| 2.5 | PIM und Adminrollen | 1 | 1 |
| 2.6 | Gruppen-Governance | 1 | 2 |
| 2.7 | Guest Access | 1 | 2 |
| 2.8 | Identity-Troubleshooting | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 10 | `skripte/Get-GovernanceInventory.ps1` | offline getestet |
| 11 | `skripte/New-JoinerWorkflow.ps1` | offline getestet |
| 12 | `skripte/New-AccessPackagePolicy.ps1` | offline getestet |
| 13 | `skripte/New-GuestAccessReview.ps1` | offline getestet |
| 14 | `skripte/PIM-Beispiel.ps1` | offline getestet |
| 15 | `skripte/Gruppen-Governance.ps1` | offline getestet |
| 16 | `skripte/Gast-Verwaltung.ps1` | offline getestet |
| 17 | `skripte/Get-IdentitySupportReport.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-02-identity/tests/modul-02.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Tests laufen gegen simulierte Graph-Cmdlets und erfundene Beispieldaten (`tools/fixtures/identitaet-klein.json`). Bei Skripten, die etwas anlegen (Zugriffsüberprüfung, Workflow, PIM, Zugriffspaket-Richtlinie), prüfen sie die **übergebenen Werte** (Fristen, Standardentscheidung, Testmodus), nicht die Wirkung im echten Tenant.

## Hinweise zu einzelnen Skripten

- `New-GuestAccessReview.ps1`: Das Startdatum (`startDate`) ist fest eingetragen und muss vor dem Einsatz angepasst werden; die automatische Anwendung der Entscheidungen ist bewusst ausgeschaltet.
- `PIM-Beispiel.ps1` und `New-AccessPackagePolicy.ps1`: enthalten Platzhalter in spitzen Klammern (Objekt-IDs), die vor dem Einsatz ersetzt werden müssen.
- `Gast-Verwaltung.ps1`: Schritt 3 zählt auch Gäste mit offener Einladung (sie haben naturgemäß keine Anmeldung). Aufgabe 7 trennt die beiden Gruppen.
