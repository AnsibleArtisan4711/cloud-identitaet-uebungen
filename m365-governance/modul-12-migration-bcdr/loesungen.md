# Lösungen – Modul 12: Migration, Kosten, Adoption und BCDR

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Die Ebenen sind Bestand (Zählungen und Listen über Graph und Berichte), Konfiguration (Export und Vergleich mit einem Zielbild), Nutzung (Nutzungsberichte, Aktivität) und Organisation (Interviews zu Rollen, Prozessen und Zuständigkeiten). Die organisatorische Ebene ist besonders wichtig, weil Technik ohne Zuständigkeit nicht wirkt: Wenn niemand für eine Einstellung verantwortlich ist, wird sie nicht gepflegt, und Befunde bleiben liegen.

## Lösung zu Aufgabe 2

Das RPO nennt, wie viel Datenverlust (als Zeitspanne bis zum Ereignis) akzeptabel ist, das RTO, wie lange die Wiederherstellung dauern darf. Beispiel: Finanzdaten brauchen ein kleines RPO und RTO (zum Beispiel wenige Stunden), weil Buchungen zeitkritisch sind und Verluste teuer; eine allgemeine Ablage verträgt ein größeres RPO und RTO (zum Beispiel ein bis zwei Tage). Die Zahlen sind Beispiele; verbindlich werden sie erst mit dem Fachbereich festgelegt.

## Lösung zu Aufgabe 3

Champions sind Beschäftigte in den Fachbereichen, die Kollegen bei der Anwendung helfen und Rückmeldungen an die Zentrale tragen. Sie werden von Kollegen eher gehört als eine Zentrale und kennen die Arbeitsabläufe. Bestandteile: Auswahl von Freiwilligen, Schulung, regelmäßiger Austausch (zum Beispiel monatlich), ein kurzer Draht zur Zentrale und Anerkennung. Auch klare Anforderungen und ein Nachfolgeplan gehören dazu.

## Lösung zu Aufgabe 4

Lücke und Priorität: Identität 0 Lücke, Priorität 0. Teams 1 Lücke mal Gewicht 2 gleich 2. SharePoint 2 Lücke mal Gewicht 3 gleich 6. Information Protection 2 Lücke mal Gewicht 3 gleich 6. Monitoring 1 Lücke mal Gewicht 2 gleich 2. Die Summe der Lücken zeigt, dass die größten Hebel in den Bereichen SharePoint und Information Protection liegen. Reihenfolge: SharePoint und Information Protection zuerst (Priorität 6, bei Gleichstand nach Risiko entscheiden, zum Beispiel Information Protection wegen der Wirkung auf Freigaben), danach Teams und Monitoring (Priorität 2), Identität zuletzt, da das Ziel erreicht ist.

## Lösung zu Aufgabe 5

Kostenblöcke: Lizenzen (Basis und Zusatz für Sicherheit und Compliance), nutzungsabhängige Dienste (Speicher über Kontingent, Sicherung, Archiv), Werkzeuge, Betrieb (Personal, Dienstleister), Einführung (Schulung, Beratung, Projektzeit), Reserve. Annahmen: Zahl der Beschäftigten und Wachstum, Datenwachstum pro Jahr, Anteil archivierbarer Daten, Preise aus dem eigenen Vertrag mit Gültigkeitsdatum, Stundensätze, Einsparungen (wegfallende Lizenzen, geringerer Speicher, weniger Vorfälle), Aufbewahrungspflichten, die Löschen einschränken. Das Modell erhält pro Jahr Kosten und Nutzen und einen Verlauf über drei Jahre; Preise stehen als Parameter in einer Datei mit Datum.

## Lösung zu Aufgabe 6

Ein Lösungsvorschlag:

```powershell
param([Parameter(Mandatory)][string]$Datei, [int]$Mindestgroesse = 5)
$z = Import-Csv -Path $Datei -Delimiter ";"
$gross = $z | Where-Object { [int]$_.Beschaeftigte -ge $Mindestgroesse }
$klein = $z | Where-Object { [int]$_.Beschaeftigte -lt $Mindestgroesse }
$ausgabe = foreach ($a in $gross) {
    $grad = [int]$a.Aktive / [int]$a.Beschaeftigte
    [pscustomobject]@{ Abteilung = $a.Abteilung; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
if ($klein) {
    $b = ($klein | Measure-Object Beschaeftigte -Sum).Sum
    $ak = ($klein | Measure-Object Aktive -Sum).Sum
    $grad = $ak / $b
    $ausgabe += [pscustomobject]@{ Abteilung = "(kleine Abteilungen zusammengefasst)"; Grad = "{0:P0}" -f $grad; Markierung = if ($grad -lt 0.5) { "unter 50 Prozent" } else { "" } }
}
$ausgabe | Format-Table -AutoSize
```

Das Skript teilt die Abteilungen nach der Mindestgröße, berechnet den Anteil der Aktiven, markiert Werte unter 50 Prozent und fasst kleine Abteilungen zu einer Zeile zusammen, damit Einzelpersonen nicht erkennbar werden. In einer produktiven Fassung sollte man außerdem Zeilen mit null Beschäftigten abfangen, um eine Division durch null zu vermeiden.

> **Als Datei:** [`loesungen-skripte/aufgabe-06-nutzungsgrad.ps1`](loesungen-skripte/aufgabe-06-nutzungsgrad.ps1) (offline getestet)
>
> **Achtung:** Gibt es genau **eine** große Abteilung und zusätzlich kleine, bricht das Skript beim Anhängen der Sammelzeile ab (`+=` auf ein einzelnes Objekt); mit `$ausgabe = @(foreach ...)` läuft es. Siehe README, Abschnitt „Hinweise“.

## Lösung zu Aufgabe 7

Ein Beispiel: Finanzdaten: RPO 1 Stunde, RTO 4 Stunden; Schutz durch Papierkorb und Aufbewahrung, Microsoft 365 Backup mit Richtlinie für die betroffenen Websites und Postfächer, Beschriftung und Zugriffsbeschränkung; Verantwortlicher: Leitung Finanzen und Betrieb; Übung halbjährlich. Projektdokumente: RPO 1 Tag, RTO 1 Tag; Schutz durch Papierkorb (93 Tage), Versionen, Aufbewahrung, Sicherung für kritische Projekte; Übung jährlich. Allgemeine Ablage: RPO 1 Woche, RTO 3 Tage; Papierkorb und Standardschutz. Konfiguration: nächtlicher Export in ein Repository, Baselines, Notfallkonten. Grenzen: Papierkörbe und Aufbewahrung sind keine Sicherung; die Sicherung hält nach Dokumentation bis zu einem Jahr und gilt für Daten, nicht für Konfiguration; bei Entra gelöschte Benutzer brauchen besondere Behandlung; die Konfigurationsüberwachung speichert Momentaufnahmen nur sieben Tage. Übungsplan: je ein Szenario pro Quartal, Dauer messen und mit dem RTO vergleichen. Die genannten Zeiten sind Beispiele.

## Lösung zu Aufgabe 8

Ein Beispiel (Auszug): Tage 1 bis 30: Ist-Analyse (Anna, 30 h), Gremium und Rollen (Ben, 16 h), Administratoren absichern (Cem, 12 h, nach Ist-Analyse-Teilergebnis), Protokollierung prüfen (Dilara, 6 h), Reifegrad bewerten (Anna, 8 h). Tage 31 bis 60: Namensund Metadatenstandard (Anna, 20 h, nach Gremium), Gruppenerstellung einschränken (Cem, 10 h, nach Standard), Pilot Bereitstellungsfabrik (Cem, 30 h), Beschriftungen im Pilot (Dilara, 24 h), Lebenszyklus in Simulation (Ben, 12 h, nach Besitzerbereinigung), Kommunikation und Champions (Elif, 24 h). Tage 61 bis 90: Kennzahlen und Berichte (Ben, 20 h), Export und Drift (Cem, 24 h), Runbooks (Dilara, 16 h), Wiederherstellungsübung (Cem, 12 h), erste Betriebsrunde (Ben, 6 h). Bewusst auf später verschoben werden zum Beispiel Information Barriers, Insider Risk und Records Management, weil sie hohen Aufwand und Abstimmung mit Recht und Betriebsrat erfordern; die Begründung gehört in das Dokument. Die Prüfung mit dem Skript deckt Konflikte auf, zum Beispiel wenn eine Person in einer Phase mehr Stunden trägt, als ihr zur Verfügung stehen.
