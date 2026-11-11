# Modul 08: Security Governance und Secure-by-Design

Quelle: Skript „M365 Governance – Lernmodule nach Lehrplan“, Modul 8 (Seiten 157 bis 177). Die Texte und Skripte dieses Ordners sind daraus übernommen; Ergänzungen sind gekennzeichnet.

- Dauer: 9 Stunden laut Blatt „Lehrplan in Modulen“.
- Priorität: 1 (höchste Priorität)

## Lerneinheiten

| Nr. | Lerneinheit | Dauer (h) | Prio |
|---|---|---|---|
| 8.1 | Secure Score | 1 | 1 |
| 8.2 | Conditional Access Baseline | 1 | 1 |
| 8.3 | MFA und Passwordless | 1 | 1 |
| 8.4 | Defender Integration | 1 | 1 |
| 8.5 | Device Compliance | 1 | 1 |
| 8.6 | Privileged Access | 1 | 2 |
| 8.7 | Security Exceptions | 1 | 2 |
| 8.8 | Security-Troubleshooting | 1 | 2 |

## Inhalt des Ordners

- [aufgaben.md](aufgaben.md): acht Aufgaben (leicht bis schwer)
- [loesungen.md](loesungen.md): die zugehörigen Lösungen
- [beispiele-falsch-richtig.md](beispiele-falsch-richtig.md): kurze Gegenüberstellungen
- [skript.md](skript.md): das Kapitel des Skripts zu diesem Modul (aus LaTeX umgewandelt)
- `skripte/`: die Beispielskripte des Moduls

## Skripte und Status

| Listing | Datei | Status |
|---|---|---|
| 82 | `skripte/Save-SecureScore.ps1` | offline getestet |
| 84 | `skripte/New-CaBlockLegacy.ps1` | offline getestet |
| 86 | `skripte/Get-MfaCoverage.ps1` | offline getestet |
| 88 | `skripte/Get-DefenderAlertSummary.ps1` | offline getestet |
| 90 | `skripte/New-WindowsCompliance.ps1` | offline getestet |
| 92 | `skripte/Test-GlobalAdmins.ps1` | offline getestet |
| 94 | `skripte/Get-CaExclusions.ps1` | offline getestet |
| 96 | `skripte/Get-SignInCaDetails.ps1` | offline getestet |

Was die Status bedeuten, steht in [docs/kennzeichnung.md](../docs/kennzeichnung.md). **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Testen Sie jedes Skript zuerst in einem Testtenant mit Testdaten und lesen Sie jede Zeile, bevor Sie es einsetzen.

## Tests

```powershell
pwsh -NoProfile -File modul-08-security/tests/modul-08.tests.ps1
```

Alle Tests des Repositories: `pwsh -NoProfile -File tools/Invoke-Tests.ps1` (aus dem Hauptordner).

Alle acht Skripte verwenden Microsoft-Graph-PowerShell-Cmdlets. Dafür gibt es `tools/Mock-GraphSecurity.ps1` mit erfundenen Beispieldaten in `tools/fixtures/sicherheit-klein.json` (Secure Score, Richtlinien für bedingten Zugriff, Gruppen, Registrierungsdetails, Warnungen, Geräte, Anmeldungen). Die Anmeldefunktion `Connect-MgGraph` wird von dieser Datei bereitgestellt; sie überschreibt einige Funktionen aus `Mock-MgGraph.ps1`, deshalb wird sie nur in den Tests dieses Moduls geladen.

Die Simulation prüft, **welche Werte übergeben werden** (Berechtigungen, Filter, Richtlinieninhalt) und wie die Skripte Daten auswerten. Ob Microsoft Graph den Inhalt einer neuen Richtlinie akzeptiert, ob Lizenzen vorhanden sind und ob die Filter in einem echten Tenant funktionieren, wird nicht geprüft.

## Hinweise zu einzelnen Skripten

Diese Punkte sind beim Fachlektorat aufgefallen. Die Skripte habe ich **nicht verändert**; die Tests halten das heutige Verhalten fest und nennen es „Hinweis“. Parameter, Berechtigungen und Filter der Cmdlets habe ich **nicht** mit der aktuellen Dokumentation verglichen; die Simulation akzeptiert sie, ein echter Tenant kann anders reagieren.

- **`Save-SecureScore.ps1`:** Die Zahlen in der CSV-Datei werden so geschrieben, wie es die Spracheinstellung des Rechners vorgibt; wer die Datei in anderer Umgebung weiterverarbeitet, sollte das prüfen. Der Tag wird aus `CreatedDateTime` gebildet (Datum in UTC, wenn der Wert als UTC geliefert wird).
- **`New-CaBlockLegacy.ps1`:** Der Zustand ist bewusst „nur Bericht“. Ob der Filter `displayName eq '…'` für Richtlinien des bedingten Zugriffs im echten Tenant funktioniert und ob die angeforderten Berechtigungen genügen, habe ich nicht geprüft. Die Notfallgruppe wird nicht auf Existenz geprüft.
- **`Get-MfaCoverage.ps1`:** Gibt es keine Administratoren, steht „0 von 1“ statt „0 von 0“, weil `@($null).Count` in PowerShell 1 ergibt (die Division selbst ist abgesichert). Die Quote hängt von den Registrierungsdaten ab, nicht davon, ob eine Richtlinie MFA tatsächlich erzwingt.
- **`Get-DefenderAlertSummary.ps1`:** Die Gruppenbezeichnung „Quelle, Status“ ist ein Text; mit `-Tage 0` ist der Zeitraum leer. Welche Warnungen der Tenant liefert, hängt von den Lizenzen ab.
- **`New-WindowsCompliance.ps1`:** Das Skript prüft nicht, ob die Richtlinie schon existiert; jeder Lauf sendet einen neuen POST und kann doppelte Richtlinien erzeugen. Der Inhalt (`scheduledActionsForRule`, `gracePeriodHours` und weitere Eigenschaften) ist nicht gegen das Graph-Schema geprüft. Die Richtlinie wird nur angelegt, nicht zugewiesen. Das Skript fordert Schreibrechte an, während die übrigen Skripte dieses Moduls lesen.
- **`Test-GlobalAdmins.ps1`:** `Get-MgDirectoryRole` liefert nach meinem Kenntnisstand nur aktivierte Rollen; für „berechtigte“ (PIM-)Zuweisungen müsste man einen anderen Weg gehen (nicht geprüft). Ein Administrator ohne Eintrag in den Registrierungsdaten gilt als „unbekannt“ und löst die Warnung „Keine MFA“ aus.
- **`Get-CaExclusions.ps1`:** Mit `-ErrorAction SilentlyContinue` wird auch ein Berechtigungsfehler unterdrückt; dann erscheint die ID statt des Namens und die Mitgliederzahl 0. Eine gelöschte Gruppe sieht damit wie eine leere Gruppe aus (erkennbar nur am Namen = ID). Ob `Get-MgGroupMember` verschachtelte Mitglieder mitzählt, habe ich nicht geprüft. Die Sortierung nach „Art“ ist durch die Reihenfolge im Skript ohnehin gegeben.
- **`Get-SignInCaDetails.ps1`:** `-Top 25` wird vor dem Sortieren angewendet. Bei mehr als 25 Anmeldungen im Zeitraum ist nicht gesichert, dass die 25 neuesten geliefert werden (Reihenfolge der Antwort nicht geprüft).
