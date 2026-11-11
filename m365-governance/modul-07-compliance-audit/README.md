# Modul 07: Compliance, Audit und Risk Management

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 7 (Seiten 136 bis 156). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 9 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 7.1 | Audit Logs | 1 | 1 |
| 7.2 | eDiscovery | 1 | 1 |
| 7.3 | Compliance Manager | 1 | 1 |
| 7.4 | Insider Risk | 1 | 1 |
| 7.5 | Communication Compliance | 1 | 1 |
| 7.6 | Legal Hold | 1 | 2 |
| 7.7 | Regulatory Mapping | 1 | 2 |
| 7.8 | Compliance-Troubleshooting | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 66 | `skripte/Search-FileDeletions.ps1` | offline getestet |
| 68 | `skripte/New-EDiscoverySearch.ps1` | offline getestet |
| 70 | `skripte/Summary-ComplianceActions.ps1` | offline getestet |
| 72 | `skripte/Convert-HrExport.ps1` | Logik offline getestet (an einer Kopie); das Original ist nicht lauffähig |
| 74 | `skripte/Test-CommunicationComplianceRoles.ps1` | offline getestet |
| 76 | `skripte/New-CaseHold.ps1` | offline getestet |
| 78 | `skripte/Test-EvidenceMatrix.ps1` | offline getestet |
| 80 | `skripte/Test-ComplianceHealth.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-07-compliance-audit/tests/modul-07.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Vier Skripte lesen oder schreiben nur CSV-Dateien (`Summary-ComplianceActions`, `Convert-HrExport`, `Test-EvidenceMatrix` und die Lösungsdatei zu Aufgabe 7) und brauchen keine Simulation. Die übrigen verwenden Exchange Online PowerShell (`Connect-ExchangeOnline`) und Security & Compliance PowerShell (`Connect-IPPSSession`). Dafür gibt es `tools/Mock-Compliance.ps1` (Audit, eDiscovery, Case Holds, Rollengruppen) mit erfundenen Beispieldaten in `tools/fixtures/compliance-klein.json`; die Anmeldefunktionen kommen aus `Mock-ExchangeOnline.ps1` und `Mock-Purview.ps1`.

Die Simulation prüft, **welche Werte übergeben werden** (Zeitraum, Operationen, Abfrage, Orte, Reihenfolge) und wie die Skripte Daten auswerten. Die Abfrage einer Compliance-Suche wird nicht ausgewertet, Seitenabfragen des Auditprotokolls werden nicht nachgebildet (siehe Kopf von `Mock-Compliance.ps1`). Die Wartezeit in `New-EDiscoverySearch.ps1` ersetzen die Tests durch eine Funktion `Start-Sleep` ohne Wartezeit.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Die Cmdlet-Angaben habe ich für `New-ComplianceSearch`, `Get-CaseHoldPolicy`, `New-CaseHoldPolicy` und `Search-UnifiedAuditLog` mit der Microsoft-Dokumentation verglichen (abgerufen am 07.11.2026), nicht für die übrigen Cmdlets.

- **`New-EDiscoverySearch.ps1` (und das Beispiel „Suchumfang“): vermutlich leere Suche.** Laut Dokumentation von [New-ComplianceSearch](https://learn.microsoft.com/en-us/powershell/module/exchange/new-compliancesearch) wird `-ExchangeLocation` gelöscht, wenn `-Name` Leerzeichen enthält und `-Case` verwendet wird. Das Skript benennt die Suche `"$Fall - Suche 1"`, also mit Leerzeichen. Die Simulation bildet das nach: Die Suche meldet dann 0 Elemente. Außerdem verlangt die Dokumentation für dieses Cmdlet in der Cloud eine aktuelle Version des Exchange-Online-Moduls und `-EnableSearchOnlySession` bei `Connect-IPPSSession`; das Skript ruft `Connect-IPPSSession` ohne diesen Parameter auf. `-Case` gilt nur für eDiscovery (Standard). Die Warteschleife hat kein Zeitlimit und endet bei einer fehlgeschlagenen Suche nie.
- **`Search-FileDeletions.ps1`: nur die erste Seite.** Mit `-SessionCommand ReturnLargeSet` liefert `Search-UnifiedAuditLog` laut Dokumentation unsortierte Seiten und muss mit derselben `SessionId` wiederholt aufgerufen werden, bis nichts mehr zurückkommt. Das Skript ruft einmal auf (höchstens 5000 Treffer) und meldet trotzdem „Treffer: n“. Das Sortieren nach Zeit ist wegen der unsortierten Ausgabe nötig und richtig. Das Skript schaltet bei ausgeschalteter Erfassung die Audit-Konfiguration des Tenants ohne Rückfrage ein.
- **`Summary-ComplianceActions.ps1`:** Der Filter `-notmatch "Implemented|Umgesetzt|Completed"` vergleicht Teilstrings ohne Beachtung der Groß- und Kleinschreibung. Ein Status wie „Nicht umgesetzt“ enthält „umgesetzt“ und zählt deshalb als erledigt und fehlt in der Liste der offenen Maßnahmen.
- **`Test-EvidenceMatrix.ps1`:** Die Prüfung `-match "offen|open"` hat dasselbe Teilstring-Problem: „erledigt, keine offenen Punkte“ wird als „Status offen“ gemeldet.
- **`Convert-HrExport.ps1`: nicht lauffähig (PowerShell 7 und Windows PowerShell 5.1).** Das Skript setzt `$kuendigung = $null` und übergibt die Variable mit `[ref]` an `[datetime]::TryParseExact(...)`. In PowerShell 7.4.6 und in Windows PowerShell 5.1 (Testlauf des Anwenders am 07.11.2026) endet das mit „Für TryParseExact … kann keine Überladung gefunden werden“; keine Zeile würde übernommen. Mit dem Anfangswert `[datetime]::MinValue` läuft derselbe Aufruf (Vorschlag, nicht eingebaut). Die Logik-Tests laufen deshalb an einer Kopie mit diesem Anfangswert; ein eigener Test hält fest, dass das Original scheitert. Außerdem müssen Daten genau im Format `dd.MM.yyyy` stehen (mit führenden Nullen), sonst wird die Zeile mit einer Warnung verworfen. Die Ausgabedatei enthält personenbezogene Daten (Kündigungsdaten) und gehört geschützt und nach dem Import gelöscht.
- **`Test-CommunicationComplianceRoles.ps1`:** Personen werden über den Anzeigenamen (`Name`) verglichen; zwei Personen mit gleichem Namen wären nicht zu unterscheiden. Geprüft wird nur die Überschneidung von Admin- und Prüfergruppe.
- **`New-CaseHold.ps1`:** Ohne `-OneDriveUrls` wird ein leeres Array als `-SharePointLocation` übergeben; ob das echte Cmdlet das akzeptiert, habe ich nicht geprüft (die Simulation akzeptiert es). Laut Dokumentation löst `New-CaseHoldPolicy` eine vollständige Synchronisierung aus; vor der nächsten Richtlinie sollte die Verteilung erfolgreich sein. Das Skript liest den Verteilungsstatus sofort danach, rechnen Sie dort mit „Pending“. Ein zweiter Lauf mit demselben Fall scheitert, weil die Richtlinie schon existiert.
- **`Test-ComplianceHealth.ps1`:** Bei den Sperrrichtlinien wird nur der Verteilungsstatus geprüft, nicht `Enabled`: Eine ausgeschaltete Sperre mit Status „Success“ gilt als in Ordnung.
