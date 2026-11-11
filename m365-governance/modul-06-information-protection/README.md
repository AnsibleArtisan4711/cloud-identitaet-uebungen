# Modul 06: Information Protection und Data Governance

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 6 (Seiten 114 bis 135). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 10 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 6.1 | Sensitivity Labels | 1,25 | 1 |
| 6.2 | DLP Governance | 1,25 | 1 |
| 6.3 | Retention Policies | 1 | 1 |
| 6.4 | Records Management | 1 | 1 |
| 6.5 | Data Lifecycle | 1 | 1 |
| 6.6 | Information Barriers | 1 | 2 |
| 6.7 | Purview Data Map Bezug | 1 | 2 |
| 6.8 | Data-Governance-Troubleshooting | 1,25 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 50 | `skripte/New-LabelStructure.ps1` | offline getestet |
| 52 | `skripte/New-DlpPolicy.ps1` | offline getestet |
| 54 | `skripte/New-RetentionPolicy.ps1` | nur Syntax geprüft |
| 56 | `skripte/New-RecordLabel.ps1` | offline getestet |
| 58 | `skripte/New-AdaptiveRetention.ps1` | nur Syntax geprüft |
| 60 | `skripte/New-InformationBarrier.ps1` | offline getestet |
| 62 | `skripte/Export-SiteInventory.ps1` | offline getestet |
| 64 | `skripte/Test-PurviewDistribution.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-06-information-protection/tests/modul-06.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Skripte dieses Moduls verwenden **Security & Compliance PowerShell** (`Connect-IPPSSession`, `New-Label`, `New-DlpCompliancePolicy` usw.), eines zusätzlich die SharePoint Online Management Shell. Die Tests laufen gegen simulierte Cmdlets (`tools/Mock-Purview.ps1`, `tools/Mock-SharePoint.ps1`) und erfundene Beispieldaten (`tools/fixtures/purview-klein.json`).

Die Simulation prüft, **welche Werte übergeben werden** (Testmodus, Schwellenwerte, Aufbewahrungsdauer, Reihenfolge) und wie die Skripte Daten auswerten. Neu angelegte Richtlinien haben in der Simulation den Verteilungsstatus `Pending`; in einem echten Tenant dauert die Verteilung.

## Hinweise zu einzelnen Skripten

- **`New-RetentionPolicy.ps1` und `New-AdaptiveRetention.ps1` sind vermutlich nicht lauffähig.** Die Microsoft-Dokumentation von `New-RetentionCompliancePolicy` (abgerufen am 07.11.2026, [Syntax](https://learn.microsoft.com/powershell/module/exchangepowershell/new-retentioncompliancepolicy)) kennt zwei getrennte Parametersätze. Der Satz `AdaptiveScopeLocation` enthält `-ExchangeLocation` nicht, das Skript kombiniert beides. Der Standardsatz enthält `-TeamsChatLocation` nicht in der Parameterliste (die Dokumentation ordnet neuere Standorte den `*-AppRetentionCompliance*`-Cmdlets zu; ob Teams-Chats dazugehören, habe ich nicht geprüft). Die Dateien sind unverändert aus dem Skript übernommen und tragen den Status „nur Syntax geprüft“. Ob und wie ein echter Tenant reagiert, habe ich nicht geprüft; einen Korrekturvorschlag gebe ich nicht ab, weil ich ihn nicht testen kann.
- `New-InformationBarrier.ps1`: Der Kommentar „Nach Pilot und Freigabe“ steht im Skript, aber der Code **aktiviert alle vorhandenen Information-Barrier-Richtlinien sofort** (auch bereits vorhandene) und startet die Anwendung. Beim Einsatz den Skriptteil nach dem Kommentar erst nach der Freigabe ausführen.
- `Test-PurviewDistribution.ps1`: Die Zahl hinter „davon auffaellig“ wird mit `(...).Count` gebildet. In Windows PowerShell 5.1 hat ein einzelnes Objekt keine Eigenschaft `Count`; bei genau **einer** auffälligen Richtlinie bleibt die Zahl dort vermutlich leer (in PowerShell 7 nicht). Der Test prüft diesen Fall nur unter PowerShell 7 genau.
- Nur die Aufbewahrungs-Cmdlets habe ich gegen die Dokumentation geprüft, nicht die Cmdlets für Labels, DLP und Information Barriers.
