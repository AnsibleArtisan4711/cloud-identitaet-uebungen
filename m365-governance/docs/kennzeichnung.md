# Kennzeichnung: Was wurde wie geprüft?

Dieses Repository enthält PowerShell-Skripte, die gegen Microsoft 365 arbeiten sollen. **Kein Skript wurde gegen einen echten Tenant ausgeführt.** Jede Datei trägt deshalb einen Status, damit klar bleibt, was geprüft wurde und was nicht.

## Status

| Status | Bedeutung | Was es nicht bedeutet |
|---|---|---|
| **offline getestet** | Das Skript wurde in PowerShell 7 ausgeführt, die Graph-Cmdlets waren durch `tools/Mock-MgGraph.ps1` ersetzt (bei SharePoint-Skripten die SPO-Cmdlets durch `tools/Mock-SharePoint.ps1`, bei Exchange-Skripten die Exchange-Online-Cmdlets durch `tools/Mock-ExchangeOnline.ps1`, bei Purview-Skripten die Compliance-Cmdlets durch `tools/Mock-Purview.ps1`, bei Audit-, eDiscovery- und Hold-Skripten durch `tools/Mock-Compliance.ps1`, bei Sicherheits-Skripten (Secure Score, bedingter Zugriff, Defender, Intune) durch `tools/Mock-GraphSecurity.ps1`, bei Monitoring-Skripten (Berichte, Dienstintegrität, Vorfälle) durch `tools/Mock-Monitoring.ps1`, bei Provisioning-Skripten (Gruppen, Teams, Ablaufrichtlinien, Wiederholung bei Fehlern) durch `tools/Mock-Provisioning.ps1`, bei Automations-Skripten (Seitenabruf, Batch, Konfigurationsexport, Ticket-System) durch `tools/Mock-Automation.ps1`, bei Betriebs-Skripten (Bestand, Akzeptanz, Champions, vorläufig gelöschte Objekte) durch `tools/Mock-Betrieb.ps1`), die Daten stammen aus erfundenen Beispieldaten. Die Tests prüfen Logik, Grenzwerte und dass nur lesende Berechtigungen angefordert werden. | Es heißt nicht, dass das echte Microsoft Graph die gleichen Antworten, Eigenschaften oder Filter kennt. |
| **nur Syntax geprüft** | Der PowerShell-Parser liest die Datei ohne Fehler. | Es heißt nicht, dass das Skript läuft oder das Richtige tut. |
| **JSON geprüft** | Die Datei ist gültiges JSON. | Der Inhalt ist nicht fachlich geprüft. |
| **nicht ausgeführt** | z. B. KQL-Abfragen für Log Analytics. | Weder Syntax noch Ergebnis geprüft. |

## Was die simulierten Cmdlets können und was nicht

- Sie kennen nur die Parameter und Filter, die die Skripte dieses Repositories verwenden. Ein unbekannter Filter löst einen Fehler aus.
- Wie im echten Graph sind bei `-Property` nur die ausgewählten Eigenschaften gefüllt. Das fängt Skripte ab, die eine nicht abgefragte Eigenschaft lesen.
- Die Annahme, dass Zählabfragen `-ConsistencyLevel eventual` brauchen, stammt aus dem Skript, nicht aus einer eigenen Prüfung gegen die Dokumentation.
- Drosselung, Seitenweise Abfragen, Berechtigungsfehler, Lizenzvoraussetzungen und Wartezeiten werden nicht simuliert.

## Was Sie vor dem Einsatz tun sollten

1. Skript vollständig lesen.
2. Zuerst in einem Testtenant mit Testdaten ausführen, nie zuerst in der Produktion.
3. Cmdlets, Parameter und Berechtigungen gegen die aktuelle Microsoft-Dokumentation prüfen. Sie ändern sich.
4. Lizenzvoraussetzungen der jeweiligen Funktion prüfen. Viele Governance-Funktionen sind an bestimmte Lizenzen gebunden.

## Weitere Hinweise

- Getestet wurde mit PowerShell 7.4.6 unter Linux. Die Testwerkzeuge sind so geschrieben, dass sie auch in Windows PowerShell 5.1 laufen sollten; ein Testlauf aller Module in Windows PowerShell 5.1 auf Windows (Stand 7. November 2026) bestand vollständig. Dabei zeigten sich Unterschiede zu PowerShell 7, die in den READMEs der Module unter „Hinweise“ stehen.
- Die Skripte aus dem Skript sind unverändert übernommen. Ergänzt wurde nur ein Kopfkommentar mit Quelle und Status. Aus Skript-Ausschnitten zusammengesetzte Lösungsskripte tragen einen entsprechenden Vermerk.
- Die Kapitel `skript.md` in den Modulordnern sind aus der LaTeX-Quelle des Skripts mit pandoc in Markdown umgewandelt. Die Listings sind zeichengleich zur Quelle (geprüft), der Text ist unverändert; Aufgaben und Lerneinheiten sind neu nummeriert, Boxen („Merke“, „Ergänzung aus der Nachrecherche“, „Praxisbeispiel“) erscheinen als Zitatblöcke. Die Listings sind **nicht ausgeführt**; maßgeblich für den getesteten Stand sind die Dateien in `skripte/`.
- Hinweise zu Datenschutz, Aufbewahrung und anderen rechtlichen Themen sind fachliche Orientierung und keine Rechtsberatung.
