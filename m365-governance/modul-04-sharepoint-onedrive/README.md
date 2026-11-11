# Modul 04: SharePoint und OneDrive Governance

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 4 (Seiten 74 bis 92). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 10 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 4.1 | Site Provisioning | 1,25 | 1 |
| 4.2 | Hub Sites und IA | 1,25 | 1 |
| 4.3 | Permission Model | 1 | 1 |
| 4.4 | Sharing Controls | 1 | 1 |
| 4.5 | Sensitivity Labels for Sites | 1 | 1 |
| 4.6 | Storage und Quotas | 1 | 2 |
| 4.7 | Site Lifecycle | 1 | 2 |
| 4.8 | SharePoint-Troubleshooting | 1,25 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 26 | `skripte/New-GovernedSite.ps1` | offline getestet |
| 27 | `skripte/New-HubStructure.ps1` | offline getestet |
| 28 | `skripte/Get-SitePermissionReport.ps1` | offline getestet |
| 29 | `skripte/Set-SharingBaseline.ps1` | offline getestet |
| 30 | `skripte/Set-SiteLabels.ps1` | offline getestet |
| 31 | `skripte/Get-StorageReport.ps1` | offline getestet |
| 32 | `skripte/Find-InactiveSites.ps1` | offline getestet |
| 33 | `skripte/Get-SiteHealth.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-04-sharepoint-onedrive/tests/modul-04.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Skripte dieses Moduls verwenden die **SharePoint Online Management Shell** (`Get-SPOSite`, `Set-SPOTenant` usw.), nicht Microsoft Graph. Die Tests laufen gegen simulierte Cmdlets (`tools/Mock-SharePoint.ps1`) und erfundene Websites (`tools/fixtures/sharepoint-klein.json`: 11 Websites und eine persönliche Website).

Die Simulation prüft, **welche Werte übergeben werden** (Freigabestufe, Schreibschutz, Label, Quote, Reihenfolge der Aufrufe) und wie die Skripte Daten auswerten (Schwellen, Sortierung, Probelauf). Nicht geprüft ist, wie ein echter Tenant reagiert, zum Beispiel ob der Filter `Url -like '/sites/PRJ-'` mit dem echten `Get-SPOSite` genau so Treffer liefert, und ob 20 Sekunden Wartezeit in `New-GovernedSite.ps1` ausreichen.

## Hinweise zu einzelnen Skripten

- `New-GovernedSite.ps1`: wartet fest 20 Sekunden, bevor die Freigabe abgeschaltet wird. Ob das in einem echten Tenant reicht, hängt vom Tenant ab und ist nicht getestet.
- Die Skripte enthalten als Beispiel die Adresse `contoso-admin.sharepoint.com`; vor einem echten Einsatz anpassen.
- `Set-SiteLabels.ps1` und `Find-InactiveSites.ps1` arbeiten ohne Schalter nur lesend (Probelauf).
