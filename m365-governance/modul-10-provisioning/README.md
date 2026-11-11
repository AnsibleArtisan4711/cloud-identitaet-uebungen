# Modul 10: Provisioning, Standards und Lifecycle Automation

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 10 (Seiten 199 bis 222). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 10 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 2 (mittlere Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 10.1 | Provisioning Factory | 1,25 | 1 |
| 10.2 | Request und Approval | 1,25 | 1 |
| 10.3 | Templates | 1 | 1 |
| 10.4 | Naming Automation | 1 | 1 |
| 10.5 | Metadata Standards | 1 | 1 |
| 10.6 | Lifecycle Jobs | 1 | 2 |
| 10.7 | Archive und Delete | 1 | 2 |
| 10.8 | Provisioning-Troubleshooting | 1,25 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 116 | `skripte/New-GovernedWorkspace.ps1` | offline getestet |
| 118 | `skripte/Test-WorkspaceRequest.ps1` | offline getestet |
| 120 | `skripte/vorlage-projekt.json` | JSON geprüft |
| 121 | `skripte/Apply-TeamTemplate.ps1` | offline getestet |
| 123 | `skripte/New-WorkspaceName.ps1` | offline getestet |
| 125 | `skripte/Test-MetadataStandard.ps1` | offline getestet |
| 127 | `skripte/New-GroupExpirationPolicy.ps1` | offline getestet |
| 129 | `skripte/Archive-InactiveTeams.ps1` | offline getestet |
| 130 | `skripte/Loeschen-und-Wiederherstellen.ps1` | offline getestet |
| 132 | `skripte/Invoke-WithRetry.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-10-provisioning/tests/modul-10.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Skripte sprechen Microsoft Graph an. Dafür gibt es `tools/Mock-Provisioning.ps1` mit erfundenen Beispieldaten in `tools/fixtures/provisioning-klein.json` (Gruppen mit Besitzern und Mitgliedern, Benutzer, Kanäle, gelöschte Gruppen, Ablaufrichtlinien). Die Datei überschreibt mehrere Funktionen aus `Mock-MgGraph.ps1` und wird deshalb nur in den Tests dieses Moduls geladen. Die Verzögerung nach dem Anlegen einer Gruppe (Fehler 404 beim Erzeugen des Teams) und die Drosselung (429) werden über Optionen nachgestellt: eine bestimmte Zahl von Aufrufen schlägt fehl, danach klappt es.

Drei Dateien enthalten außer Funktionen auch einen Beispielaufruf (`Invoke-WithRetry.ps1`, `New-WorkspaceName.ps1`, `Test-WorkspaceRequest.ps1`). Die Tests laden dort nur den Funktionsteil (bis zur Zeile „# Beispiel“) und führen die Skripte außerdem als Ganzes aus. Wartezeiten ersetzen die Tests durch eine Funktion `Start-Sleep` ohne Wartezeit, die die Sekunden festhält.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Parameter, Berechtigungen und Filter der Cmdlets habe ich **nicht** mit der aktuellen Dokumentation verglichen.

- **`New-GovernedWorkspace.ps1`:** Scheitert das Erzeugen des Teams dreimal, bricht das Skript ab, **die Gruppe bleibt aber bestehen** (keine Aufräumregel; die Lösung zu Aufgabe 8 verlangt eine). Zwei gleiche Besitzer (`-Besitzer a, a`) werden nicht abgelehnt; die Prüfung zählt nur die Einträge. Der Nickname wird nicht vorab auf Kollisionen geprüft (das leistet `New-WorkspaceName.ps1`). Die Wiederholung wartet fest 10 Sekunden und unterscheidet nicht zwischen 404 (Replikation) und anderen Fehlern wie 429 oder 403: jeder Fehler wird dreimal wiederholt; ein „Retry-After“ bei 429 bleibt unbeachtet.
- **`Invoke-WithRetry.ps1`:** Das Skript endet mit einem Beispielaufruf, der die Variable `$gruppenId` voraussetzt; ohne sie wird ein Pfad „…/groups//team“ aufgerufen. Das Auslesen von „Retry-After“ geht davon aus, dass `Response.Headers` Schlüssel-Wert-Paare liefert (so in PowerShell 7). In Windows PowerShell 5.1 liefert `Invoke-MgGraphRequest` nach meinem Kenntnisstand eine andere Antwortart; dort greift die Suche möglicherweise ins Leere und es gilt die feste Wartezeit von 30 Sekunden (nicht geprüft). Beim letzten Versuch geht die ursprüngliche Ausnahme verloren, es bleibt nur der Text „Aufgegeben nach n Versuchen“.
- **`Loeschen-und-Wiederherstellen.ps1`:** Das Skript ist eine Befehlsfolge, kein fertiges Werkzeug: Es setzt `$gruppenId` voraus, löscht die Gruppe **und stellt sie sofort wieder her**. Ohne Bestätigung eingesetzt, löscht es also wirklich (vorläufig). Bei einer unbekannten Gruppe meldet das Skript den Fehler, läuft aber weiter und versucht trotzdem die Wiederherstellung. Die Dokumentation nennt eine Wiederherstellungsfrist von 30 Tagen; die Simulation kennt keine Frist.
- **`Test-WorkspaceRequest.ps1`:** „Streng vertraulich“ (so in den Lösungen zu Aufgabe 4 genannt) wird **nicht** erkannt, denn geprüft wird auf genau „Vertraulich“ oder „Streng“; der Antrag bekäme Stufe 1. Ebenso wird `Gaeste = "ja"` (Text statt `$true`) nicht erkannt. Die Stufe 2 gilt nur bei „Intern“ und mehr als 200 Beschäftigten (`Groesse`); fehlt die Größe, bleibt es bei Stufe 1. Die Stufe wird, wie verlangt, aus den Angaben berechnet und nicht gewählt.
- **`New-WorkspaceName.ps1`:** Der Freitext wird kleingeschrieben („PRJ-VER-produktlaunch-fruehjahr“). Besteht er nur aus Sonderzeichen, endet der Name auf einen Bindestrich („PRJ-VER-“). Die Kollisionsprüfung vergleicht den Nickname mit `Get-MgGroup -Filter`; ob der Filter im echten Tenant so akzeptiert wird, habe ich nicht geprüft.
- **`Test-MetadataStandard.ps1`:** Als Besitzer zählt jedes Objekt, auch ein deaktiviertes Konto (das behandelt die Erweiterung in Aufgabe 7). Hat der Tenant nur konforme Gruppen, enthält die Befunddatei keine Zeilen (in der Simulation leer oder nicht vorhanden; das genaue Verhalten kann je PowerShell-Version abweichen). Die Datei „metadaten-befunde.csv“ landet im aktuellen Ordner.
- **`Archive-InactiveTeams.ps1`:** Die Liste legt fest, was archiviert wird; das Skript prüft die Inaktivität nicht selbst (der Name „Inactive“ bezieht sich auf die Liste). Das Protokoll wird auch im Probelauf geschrieben.
- **`New-GroupExpirationPolicy.ps1`:** Schaltet die Richtlinie nur für ausgewählte Gruppen ein (`Selected`) und trägt genau eine Testgruppe ein. Ist die Testgruppe unbekannt, ist die Richtlinie zu diesem Zeitpunkt schon angelegt. Die Parameter von `Add-MgGroupLifecyclePolicyGroup` habe ich nicht mit der Dokumentation verglichen.
- **`Apply-TeamTemplate.ps1`:** Die Vorlage enthält auch `sensitivityLabel`; das Skript wertet nur die Kanäle aus. Der Vergleich der Kanalnamen unterscheidet nicht zwischen Groß- und Kleinschreibung. Die Kanalabfrage ist nicht mit `-ErrorAction Stop` abgesichert.
