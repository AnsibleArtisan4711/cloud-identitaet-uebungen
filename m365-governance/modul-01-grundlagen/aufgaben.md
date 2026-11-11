# Aufgaben – Modul 01: Grundlagen, Governance-Modell und Zielarchitektur

Acht Aufgaben mit steigender Schwierigkeit. Die Lösungen stehen getrennt in [loesungen.md](loesungen.md) – erst selbst versuchen.

Richtwert für den Zeitaufwand (Schätzung, nicht aus dem Skript): leicht 10 bis 15 Minuten, mittel 20 bis 40 Minuten, schwer 45 bis 90 Minuten.

## Aufgabe 1

*Leicht, Wissen*

Ordnen Sie die folgenden Maßnahmen den Kontrolltypen vorbeugend, aufdeckend oder korrigierend zu und begründen Sie kurz: (a) Namensrichtlinie für Gruppen, (b) monatlicher Bericht über Gruppen ohne Besitzer, (c) Wiederherstellen einer gelöschten Gruppe, (d) Einschränkung der Gruppenerstellung auf eine Sicherheitsgruppe.

## Aufgabe 2

*Leicht, Wissen*

Erklären Sie in je einem Satz den Unterschied zwischen Governance, Management und Administration. Ordnen Sie dann zu: „Der Teamverantwortliche legt fest, dass Gäste nach 180 Tagen ablaufen.“, „Ein Administrator legt ein Team an.“, „Die IT-Leitung plant die Einführung der Ablaufrichtlinie bis Ende des Quartals.“

## Aufgabe 3

*Mittel, Konzept*

Die folgende RACI-Zeile ist fehlerhaft: Aufgabe „Gastzugriff verlängern“, Teambesitzer = A, Governance Lead = A, Service Owner = R. Beschreiben Sie den Fehler und korrigieren Sie die Zeile begründet.

## Aufgabe 4

*Mittel, Praxis*

Erweitern Sie das Skript `Find-GroupsWithFewOwners.ps1` so, dass nur Gruppen berücksichtigt werden, die älter als 30 Tage sind (neue Gruppen werden häufig erst nach der Erstellung vollständig eingerichtet). Verwenden Sie die Eigenschaft `CreatedDateTime`.

## Aufgabe 5

*Mittel, Praxis*

Ergänzen Sie die Datei `policy-tenant.json` um die Regel `maxGuestShare` (maximaler Anteil der Gäste an allen Benutzern, Wert 0.2) und erweitern Sie `Test-PolicyCompliance.ps1` um die Prüfung dieser Regel. Verwenden Sie `Get-MgUserCount`.

## Aufgabe 6

*Mittel, Konzept*

Formulieren Sie die vage Aussage „Die Zusammenarbeit mit Externen ist sicher“ als messbaren Baseline-Punkt mit Soll-Wert, Prüfmethode (automatisch oder manuell), Verantwortlichem und Prüfintervall.

## Aufgabe 7

*Schwer, Konzept*

Ein Mittelständler mit 800 Beschäftigten, einer IT-Abteilung von sechs Personen und starker Nutzung von Teams möchte ein Operating Model einführen. Entwerfen Sie auf einer Seite die Rollen, die drei wichtigsten Prozesse und die Kennzahlen. Begründen Sie, ob Sie ein zentrales oder föderiertes Modell wählen.

## Aufgabe 8

*Schwer, Praxis*

Erweitern Sie `New-GovernanceBacklog.ps1` so, dass Nutzen und Risiko unterschiedlich gewichtet werden können (Parameter `-WeightBenefit` und `-WeightRisk`, Standardwert 1) und dass Maßnahmen mit Aufwand 0 oder einem nicht numerischen Wert eine verständliche Fehlermeldung erzeugen, statt das Skript abstürzen zu lassen.
