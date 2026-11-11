# Modul 05: Exchange und Kommunikations-Governance

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 5 (Seiten 93 bis 113). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 8 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 2 (mittlere Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 5.1 | Mailbox Governance | 1 | 1 |
| 5.2 | Distribution Lists | 1 | 1 |
| 5.3 | Microsoft 365 Groups | 1 | 1 |
| 5.4 | Mail Flow Rules | 1 | 1 |
| 5.5 | Shared Mailboxes | 1 | 1 |
| 5.6 | Retention für Mail | 1 | 2 |
| 5.7 | External Sender Controls | 1 | 2 |
| 5.8 | Exchange-Troubleshooting | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 34 | `skripte/Export-MailboxInventory.ps1` | offline getestet |
| 36 | `skripte/Test-DistributionGroups.ps1` | offline getestet |
| 38 | `skripte/Set-GroupNamingPolicy.ps1` | offline getestet |
| 40 | `skripte/New-ImpersonationWarningRule.ps1` | offline getestet |
| 42 | `skripte/New-SharedMailboxGoverned.ps1` | offline getestet |
| 44 | `skripte/Get-MailRetentionOverview.ps1` | offline getestet |
| 46 | `skripte/Set-ExternalSenderControls.ps1` | offline getestet |
| 48 | `skripte/Trace-MailProblem.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-05-exchange/tests/modul-05.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Skripte dieses Moduls verwenden das **Exchange-Online-Modul** (`Get-Mailbox`, `New-TransportRule` usw.), einzelne zusätzlich Microsoft Graph. Die Tests laufen gegen simulierte Cmdlets (`tools/Mock-ExchangeOnline.ps1`, `tools/Mock-MgGraph.ps1`) und erfundene Beispieldaten (`tools/fixtures/exchange-klein.json`: 7 Postfächer, davon 2 freigegebene, ein inaktives Postfach, 4 Verteilergruppen, 4 Nachrichten).

Geprüft wird, **welche Werte übergeben werden** (Testmodus der Regel, Berechtigungen, gesperrtes Konto) und wie die Skripte Daten auswerten. Nicht geprüft ist das Verhalten eines echten Tenants, zum Beispiel ob `Get-ExternalInOutlook` und `Get-MessageTrace` in Ihrer Modulversion vorhanden sind und welche Parameter sie dort kennen.

## Hinweise zu einzelnen Skripten

- `Export-MailboxInventory.ps1`: Die Warnung am Ende nennt **alle** Weiterleitungen an eine SMTP-Adresse, auch an eigene Domänen. Die Prüfung auf externe Ziele zeigt die Lösung zu Aufgabe 5.
- `New-ImpersonationWarningRule.ps1` enthält als Platzhalter die Namen `Erika Mustermann` und `Max Beispiel`, die vor dem Einsatz ersetzt werden müssen. Die Regel startet im Testmodus (`AuditAndNotify`).
- `Set-ExternalSenderControls.ps1` verwendet `Resolve-DnsName` (nur unter Windows). Der Test ersetzt die DNS-Abfrage durch Beispieldaten.
- `New-SharedMailboxGoverned.ps1` sperrt die Anmeldung am Konto des Postfachs über Microsoft Graph (`Update-MgUser`).
