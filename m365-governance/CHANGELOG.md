# Changelog

Alle nennenswerten Änderungen. Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/).

## [Unveröffentlicht]

### Geändert

- `.gitignore`: Ausnahme `!**/loesungen-skripte/*.csv`. Die Regel `*.csv` hatte `modul-07-compliance-audit/loesungen-skripte/nachweismatrix-aufgabe-07.csv` ausgeschlossen, die Datei fehlte im Repository, und der Test zu Aufgabe 7 in Modul 07 scheiterte in der CI (lokal lief er durch, weil die Datei dort liegt).
- `.github/workflows/ci.yml`: `actions/checkout` von v4 auf v5 (v4 läuft auf Node 20, das GitHub abkündigt; die Versionsnummer ist nicht gegen die aktuelle Veröffentlichung geprüft).
- Modul 01: `Test-TenantBaseline.ps1` ergänzt ein beim Spaltenumbruch verlorenes Leerzeichen (`else { "ABWEICHUNG" }`).
- `tools/Mock-MgGraph.ps1`: Verzeichniseinstellungen mit Name und Werten, `Update-MgUser`.
- `tools/Test-Helper.ps1`: `Assert-Equal` vergleicht Listen elementweise; `Invoke-ScriptUnderTest` ignoriert leere Ausgabeobjekte.

### Hinzugefügt

- Kapitel des Skripts als Markdown: `skript.md` in jedem Modulordner, `docs/skript-einleitung.md` und `docs/skript-quellenverzeichnis.md` (aus der LaTeX-Quelle umgewandelt, 221 Listings zeichengleich geprüft)
- Repository-Gerüst: README, Lizenzen (MIT für Code, CC BY 4.0 für Texte), `docs/kennzeichnung.md`, `docs/quellen.md`
- Testwerkzeuge ohne Pester: `tools/Test-Helper.ps1`, `tools/Mock-MgGraph.ps1` (simulierte Graph-Cmdlets), `tools/Test-Syntax.ps1`, `tools/Invoke-Tests.ps1`, Beispieldaten `tools/fixtures/tenant-klein.json`
- Modul 01 (Grundlagen, Governance-Modell und Zielarchitektur): Aufgaben, Lösungen, 8 Skripte offline getestet (25 Tests), lauffähige Lösungsskripte zu den Praxisaufgaben 4, 5 und 8
- Modul 02 (Identity Governance und Zugriffskontrolle): Aufgaben, Lösungen, 8 Skripte offline getestet (14 Tests), Lösungsskripte zu den Praxisaufgaben 6 und 7; Beispieldaten `tools/fixtures/identitaet-klein.json`
- Modul 03 (Teams Governance und Collaboration Lifecycle): Aufgaben, Lösungen, 8 Skripte offline getestet (25 Tests), Lösungsskripte zu den Praxisaufgaben 6 und 8; Beispieldaten `tools/fixtures/teams-klein.json`
- Modul 04 (SharePoint und OneDrive Governance): Aufgaben, Lösungen, 8 Skripte offline getestet (20 Tests), Lösungsskript zu Aufgabe 6; `tools/Mock-SharePoint.ps1` und `tools/fixtures/sharepoint-klein.json`
- Modul 05 (Exchange und Kommunikations-Governance): Aufgaben, Lösungen, 8 Skripte offline getestet (23 Tests), Lösungsskripte zu den Praxisaufgaben 5 und 7; `tools/Mock-ExchangeOnline.ps1` und `tools/fixtures/exchange-klein.json`
- Modul 06 (Information Protection und Data Governance): Aufgaben, Lösungen, 6 Skripte offline getestet, 2 Skripte (Aufbewahrung) nur Syntax geprüft und mit Hinweis auf vermutlichen Parameterkonflikt, 15 Tests, Lösungsskripte zu den Praxisaufgaben 5 und 7; `tools/Mock-Purview.ps1` und `tools/fixtures/purview-klein.json`
- Modul 07 (Compliance, Audit und Risk Management): Aufgaben, Lösungen, 8 Skripte offline getestet (41 Tests; `Convert-HrExport.ps1` nur an einer Kopie, das Original scheitert in PowerShell 7 und 5.1), Lösungsskript zu Aufgabe 4 und Nachweismatrix-CSV zu Aufgabe 7; `tools/Mock-Compliance.ps1` und `tools/fixtures/compliance-klein.json`
- Modul 08 (Security Governance und Secure-by-Design): Aufgaben, Lösungen, 8 Skripte offline getestet (37 Tests), Lösungsskripte zu den Praxisaufgaben 4 und 7; `tools/Mock-GraphSecurity.ps1` und `tools/fixtures/sicherheit-klein.json`
- Modul 09 (Monitoring, Reporting und Service Operations): Aufgaben, Lösungen, 8 Skripte offline getestet (48 Tests; `Get-StaleSiteStats.ps1` nur an einer Kopie, das Original scheitert in PowerShell 7 und 5.1 an `[datetime]::TryParse` mit `$null`), 2 KQL-Abfragen und 1 JSON-Datei, Lösungsskripte zu den Praxisaufgaben 4 und 7; `tools/Mock-Monitoring.ps1` und `tools/fixtures/monitoring-klein.json`
- Modul 10 (Provisioning, Standards und Lifecycle Automation): Aufgaben, Lösungen, 9 Skripte und 1 JSON-Vorlage offline getestet (55 Tests), Lösungsskripte zu den Praxisaufgaben 5 und 7; `tools/Mock-Provisioning.ps1` und `tools/fixtures/provisioning-klein.json`
- Modul 11 (Automation, Graph API und Policy-as-Code): Aufgaben, Lösungen, 8 Skripte offline getestet (66 Tests; `Compare-ConfigDrift.ps1` nur an einer Kopie, das Original scheitert, weil `$ist` den Parameter `$Ist` überschreibt) und 1 JSON-Datei, Lösungsskript zur Praxisaufgabe 4; `tools/Mock-Automation.ps1` und `tools/fixtures/automation-klein.json`
- Modul 12 (Migration, Kosten, Adoption und BCDR): Aufgaben, Lösungen, 8 Skripte und 1 JSON-Datei offline getestet (59 Tests; `Get-AdoptionByDepartment.ps1` nur an einer Kopie, das Original scheitert an `[datetime]::TryParse` mit `$null`; die mitgelieferte `roadmap.json` enthält einen Konflikt), Lösungsskript zu Aufgabe 6; `tools/Mock-Betrieb.ps1` und `tools/fixtures/betrieb-klein.json`
- CI-Workflow `.github/workflows/ci.yml` (Syntaxprüfung und Offline-Tests unter Linux und Windows)
