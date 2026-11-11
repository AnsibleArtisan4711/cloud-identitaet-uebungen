# Modul 11: Automation, Graph API und Policy-as-Code

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 11 (Seiten 223 bis 246). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 10 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 2 (mittlere Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 11.1 | Microsoft Graph | 1,25 | 1 |
| 11.2 | PowerShell Automation | 1,25 | 1 |
| 11.3 | Configuration Export | 1 | 1 |
| 11.4 | Policy-as-Code | 1 | 1 |
| 11.5 | Drift Detection | 1 | 1 |
| 11.6 | ITSM Integration | 1 | 2 |
| 11.7 | Automation Security | 1 | 2 |
| 11.8 | Rollback | 1,25 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 134 | `skripte/Graph-Bausteine.ps1` | offline getestet |
| 136 | `skripte/Set-MissingGroupDescription.ps1` | offline getestet |
| 138 | `skripte/Export-TenantConfig.ps1` | offline getestet |
| 140 | `skripte/standards.json` | JSON geprüft |
| 141 | `skripte/Test-StandardsFile.ps1` | offline getestet |
| 143 | `skripte/Compare-ConfigDrift.ps1` | Logik offline getestet (an einer Kopie); das Original ist nicht lauffähig |
| 145 | `skripte/Itsm-Bausteine.ps1` | offline getestet |
| 147 | `skripte/Get-RiskyAppPermissions.ps1` | offline getestet |
| 149 | `skripte/Set-LifetimeWithRollback.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-11-automation/tests/modul-11.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Die Skripte sprechen Microsoft Graph, Exchange Online und ein Ticket-System an. Dafür gibt es `tools/Mock-Automation.ps1` mit erfundenen Beispieldaten in `tools/fixtures/automation-klein.json` (Gruppen mit Besitzern, Ablaufrichtlinie, Richtlinien für bedingten Zugriff, Transportregeln, Dienstprinzipale mit Anwendungsrechten, ein kleines Ticket-System). Die Datei überschreibt mehrere Funktionen anderer Mocks und wird deshalb nur in den Tests dieses Moduls geladen. Sie bildet nach: Seitenabruf mit `@odata.nextLink`, `$batch` mit höchstens 20 Anfragen und gedrosselte Antworten (429). Das Ticket-System ist **erfunden** und entspricht keinem echten Produkt; die Pfade und Felder in `Itsm-Bausteine.ps1` habe ich nicht gegen ein Produkt geprüft.

`Test-StandardsFile.ps1` und `Compare-ConfigDrift.ps1` brauchen keine Simulation; sie laufen mit erfundenen Dateien in einem Wegwerf-Ordner. `Graph-Bausteine.ps1` und `Itsm-Bausteine.ps1` enthalten Funktionen; die Tests laden sie getrennt vom Aufrufteil und führen `Graph-Bausteine.ps1` außerdem als Ganzes aus.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Parameter, Berechtigungen, Filter und Grenzen von Graph (zum Beispiel 20 Anfragen je Batch) habe ich **nicht** mit der aktuellen Dokumentation verglichen.

- **`Compare-ConfigDrift.ps1` ist nicht lauffähig.** PowerShell unterscheidet bei Variablennamen nicht zwischen Groß- und Kleinschreibung: Die Zeile `$ist = Read-Config $Ist` überschreibt den Parameter `$Ist`, der vom Typ `string` ist. Die Hashtable wird dadurch in den Text „System.Collections.Hashtable“ umgewandelt, und `$ist.ContainsKey(...)` scheitert. Die Tests prüfen das Original auf genau diesen Fehler und führen die Logik an einer **Kopie** aus, in der die Variable `$istDaten` heißt. Behebung im Original: Variable umbenennen (an vier Stellen). Ob der Fehler in Windows PowerShell 5.1 gleich auftritt, zeigt der Testlauf dort.
- **`-WhatIf` unterdrückt auch das Schreiben von Dateien.** Bei `Set-MissingGroupDescription.ps1`, `Set-LifetimeWithRollback.ps1` und der Lösung zu Aufgabe 4 gilt `-WhatIf` auch für `Export-Csv`, `New-Item` und `Set-Content`. Im Probelauf entsteht daher **kein Protokoll** und **keine Sicherung**. Das widerspricht dem Beispiel „Falsch und richtig“ zu Listing 137 („Ergebnis im Protokoll prüfen, dann erst ohne -WhatIf ausführen“) und der Lösung zu Aufgabe 4 („die Datei zeigt den Status geplant“). Bei `Set-LifetimeWithRollback.ps1` erscheint zudem die Meldung „Sicherung geschrieben“, obwohl nichts geschrieben wurde. Die Zahl „n Gruppen bearbeitet“ zählt im Probelauf die geplanten Änderungen mit.
- **`Graph-Bausteine.ps1`:** Liefert eine Abfrage genau ein Ergebnis, gibt `Get-GraphAll` es als einzelnes Objekt zurück; `.Count` ist dann bei einer Hashtable die Zahl der Schlüssel (hier 3), nicht 1 („3 Gruppen gelesen“ bei einer Gruppe). Mit `@(Get-GraphAll ...)` stimmt die Zahl. Gedrosselte Antworten (429) im Batch werden nur gezählt, nicht wiederholt. Antworten werden nach Pfad abgelegt; gleiche Pfade überschreiben sich.
- **`Set-MissingGroupDescription.ps1`:** Das Protokoll wird fortgeschrieben (`-Append`); ein Wiederholungslauf hängt nur die Gruppen an, die beim ersten Lauf scheiterten. Eine Beschreibung nur aus Leerzeichen gilt als fehlend.
- **`Export-TenantConfig.ps1`:** Bei genau einem Eintrag schreibt das Skript ein Objekt statt einer Liste, bei keinem Eintrag in PowerShell 7 nur das Wort `null`; in Windows PowerShell 5.1 entsteht dann **gar keine Datei** (Testlauf), und die Meldung „Export abgeschlossen“ nennt entsprechend weniger Dateien. Das Format der Datei ändert sich also mit der Anzahl der Einträge. Der Export meldet sich zweimal bei Graph an (zuerst `Policy.Read.All`, dann `Directory.Read.All`). Dass `Set-Content -Encoding UTF8` in Windows PowerShell 5.1 eine Bytefolge am Dateianfang schreibt und in PowerShell 7 nicht, ist mein Kenntnisstand und nicht geprüft; es kann Vergleiche zwischen Systemen stören.
- **`Test-StandardsFile.ps1`:** Prüft `mindestBesitzer` und `lebensdauerTage` mit Zahlenvergleich; ein Text wie `"abc"` wird nicht beanstandet. Der Abschnitt `freigabestufen` wird nicht geprüft. Dass `gueltigAb` ein Datum ist, hängt von der Spracheinstellung des Rechners ab (nicht geprüft). Bei ungültigem JSON endet das Skript mit Exit-Code 1.
- **`Compare-ConfigDrift.ps1` (Verhalten an der Kopie):** Verglichen werden nur Felder, die in der Baseline stehen; zusätzliche Felder im Ist-Stand bleiben unbemerkt. Schlüssel werden ohne Beachtung der Groß-/Kleinschreibung zugeordnet („Alpha“ = „ALPHA“). Doppelte Schlüssel in der Baseline werden stillschweigend zusammengelegt (der letzte gewinnt); fehlt der Schlüssel, fallen alle Einträge unter einem leeren Schlüssel zusammen. Verschachtelte Werte und Listen werden als Text verglichen: Eine andere Reihenfolge der Felder oder der Listeneinträge zählt als Abweichung. Exit-Code 0 ohne Abweichung, 2 mit Abweichung. Fehlt ein Feld der Baseline im Ist-Stand, steht in der Spalte „Ist“ in PowerShell 7 das Wort `null`, in Windows PowerShell 5.1 nichts.
- **`Itsm-Bausteine.ps1`:** Der Schlüssel eines Tickets macht aus jedem Zeichen außer a–z und 0–9 einen Bindestrich: „Größe“ wird zu `drift-gr-e`, „Regel!“ zu `drift-regel-`, und „A B“ und „A-B“ ergeben denselben Schlüssel (dann wird das Ticket des ersten Eintrags wiederverwendet). Der Statusvergleich in `Assert-ChangeApproved` beachtet die Schreibweise nicht („Approved“ gilt als freigegeben). Die Freigabe prüft nur den Status, nicht Zeitfenster, Zuständigkeit oder den Zusammenhang mit der Änderung. Die Beispieladresse im Kommentar (`contoso.com`) ist ein Platzhalter.
- **`Get-RiskyAppPermissions.ps1`:** Erfasst nur Anwendungsrechte für Microsoft Graph, die auf `ReadWrite.All` enden. Nicht erfasst sind delegierte Rechte, andere Muster (`Sites.FullControl.All`, `Mail.ReadWrite`, `Files.Write.All`) und andere Ressourcen. Zuweisungen eines Dienstprinzipals, die sich nicht lesen lassen, verschwinden wegen `-ErrorAction SilentlyContinue` ohne Hinweis aus dem Ergebnis. Die Zahl der Anwendungen zählt Anzeigenamen, nicht Anwendungen (AppId).
- **`Set-LifetimeWithRollback.ps1`:** Die Change-Nummer wird nur für den Dateinamen der Sicherung verwendet; das Skript prüft nicht, ob der Change freigegeben ist (dafür gäbe es `Assert-ChangeApproved` aus `Itsm-Bausteine.ps1`, es ist aber nicht eingebunden). Geändert wird nur die erste Richtlinie. Ein unveränderter Wert wird trotzdem geschrieben. Scheitert auch der Rollback selbst, kommt dessen Fehlermeldung ohne den Satz „Rollback ausgefuehrt“. Die Sicherung enthält vier Felder (Id, Lebensdauer, Gruppentypen, Benachrichtigungsadressen).
- **Lösung zu Aufgabe 4:** Ein zweiter Lauf findet keine Gruppen mehr und überschreibt die Datei mit einer leeren Liste; das Protokoll des ersten Laufs geht verloren. Die Zuweisung ist idempotent, das Protokoll nicht.
