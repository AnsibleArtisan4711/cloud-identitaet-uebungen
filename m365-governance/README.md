# Microsoft 365 Governance – Übungen

Übungsreihe zur Governance von Microsoft 365: Identitäten, Teams, SharePoint, Exchange, Information Protection, Compliance, Security, Monitoring, Provisioning, Automation und Betrieb. Jedes Modul hat acht Aufgaben mit steigender Schwierigkeit, getrennt davon die Lösungen und die zugehörigen PowerShell-Skripte.

Die Reihe folgt dem Skript „M365 Governance – Lernmodule nach Lehrplan“ (12 Module). Die Texte und Skripte sind daraus übernommen; Ergänzungen dieses Repositories sind gekennzeichnet. Die Kapitel des Skripts stehen als `skript.md` in den Modulordnern, die [Einleitung](docs/skript-einleitung.md) und das [Quellenverzeichnis](docs/skript-quellenverzeichnis.md) im Ordner `docs`.

## Wichtig: Was dieses Repository nicht ist

- **Kein Skript wurde gegen einen echten Microsoft-365-Tenant ausgeführt.** Das Skript, aus dem die Beispiele stammen, sagt das selbst. Welche Datei wie geprüft wurde, steht in [docs/kennzeichnung.md](docs/kennzeichnung.md) und in der Statustabelle jedes Moduls.
- Die Tests laufen gegen **simulierte** Graph-Cmdlets und erfundene Beispieldaten. Sie prüfen die Logik der Skripte, nicht das Verhalten von Microsoft Graph.
- Hinweise zu Datenschutz, Aufbewahrung und anderen rechtlichen Themen sind fachliche Orientierung und keine Rechtsberatung.
- Viele Governance-Funktionen sind an Lizenzen gebunden. Prüfen Sie die Voraussetzungen vor dem Einsatz.
- Alle Namen, Adressen und Domains in Beispielen und Testdaten sind erfunden (`example.com`).

## Module

| Modul | Thema | Stand |
|---|---|---|
| [01](modul-01-grundlagen/) | Grundlagen, Governance-Modell und Zielarchitektur | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [02](modul-02-identity/) | Identity Governance und Zugriffskontrolle | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [03](modul-03-teams/) | Teams Governance und Collaboration Lifecycle | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [04](modul-04-sharepoint-onedrive/) | SharePoint und OneDrive Governance | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [05](modul-05-exchange/) | Exchange und Kommunikations-Governance | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [06](modul-06-information-protection/) | Information Protection und Data Governance | verfügbar (Aufgaben, Lösungen, Skripte, Tests; zwei Skripte nur Syntax geprüft) |
| [07](modul-07-compliance-audit/) | Compliance, Audit und Risk Management | verfügbar (Aufgaben, Lösungen, Skripte, Tests; ein Skript nicht lauffähig) |
| [08](modul-08-security/) | Security Governance und Secure-by-Design | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [09](modul-09-monitoring/) | Monitoring, Reporting und Service Operations | verfügbar (Aufgaben, Lösungen, Skripte, Tests; ein Skript nicht lauffähig) |
| [10](modul-10-provisioning/) | Provisioning, Standards und Lifecycle Automation | verfügbar (Aufgaben, Lösungen, Skripte, Tests) |
| [11](modul-11-automation/) | Automation, Graph API und Policy-as-Code | verfügbar (Aufgaben, Lösungen, Skripte, Tests; ein Skript nicht lauffähig) |
| [12](modul-12-migration-bcdr/) | Migration, Kosten, Adoption und BCDR | verfügbar (Aufgaben, Lösungen, Skripte, Tests; ein Skript nicht lauffähig) |

## Aufbau eines Moduls

```text
modul-NN-thema/
  README.md                       Überblick, Lerneinheiten, Skripte und Status
  aufgaben.md                     acht Aufgaben (leicht bis schwer)
  loesungen.md                    die zugehörigen Lösungen
  beispiele-falsch-richtig.md     kurze Gegenüberstellungen (wenn im Skript vorhanden)
  skripte/                        die Beispielskripte aus dem Skript
  loesungen-skripte/              lauffähig zusammengesetzte Lösungen der Praxisaufgaben
  tests/                          Offline-Tests
tools/                            Test-Hilfen, simulierte Graph-Cmdlets, Beispieldaten
docs/                             Kennzeichnung der Prüfungen, Quellen
```

## Voraussetzungen

- **Tests ausführen:** PowerShell 7 (`pwsh`). Sonst nichts; kein Pester, kein Microsoft-365-Konto.
- **Skripte tatsächlich einsetzen** (nur in einem Testtenant): PowerShell 7, das Modul `Microsoft.Graph`, für die SharePoint-Beispiele das SharePoint-Online-Verwaltungsmodul, für Exchange-Beispiele das Exchange-Online-Modul, und ein Konto mit den passenden Berechtigungen. Welche Module und Berechtigungen ein Skript braucht, steht in den Skripten (`Connect-MgGraph -Scopes …`) und im Skript, aus dem sie stammen.

## Tests

Im Hauptordner des Repositories:

```powershell
pwsh -NoProfile -File tools/Invoke-Tests.ps1
```

Das führt zuerst die Syntaxprüfung über alle `.ps1`- und `.json`-Dateien aus und danach alle Dateien `*.tests.ps1`.

## Lizenz

- **Code** (alle PowerShell-Skripte, Testwerkzeuge, Tests): [MIT-Lizenz](LICENSE)
- **Texte** (README-Dateien, Aufgaben, Lösungen, Dokumente in `docs/`): [CC BY 4.0](LICENSE-DOCS.md)
- **Nicht von diesen Lizenzen erfasst:** Inhalte des Lehrplans, auf dem das Skript aufbaut. Für ihn gelten die Bedingungen seines Herausgebers. Texte der Microsoft-Dokumentation sind nicht Teil dieses Repositories; sie sind in [docs/quellen.md](docs/quellen.md) nur verlinkt.
- Microsoft, Microsoft 365, Entra, Purview, Defender, Teams, SharePoint, Exchange und Intune sind Marken der Microsoft Corporation. Dieses Repository steht in keiner Verbindung zu Microsoft.

Autor: AnsibleArtisan4711
