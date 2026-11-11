# Aufgaben – Modul 10: Provisioning, Standards und Lifecycle Automation

Acht Aufgaben mit steigender Schwierigkeit. Die Lösungen stehen getrennt in [loesungen.md](loesungen.md) – erst selbst versuchen.

Richtwert für den Zeitaufwand (Schätzung, nicht aus dem Skript): leicht 10 bis 15 Minuten, mittel 20 bis 40 Minuten, schwer 45 bis 90 Minuten.

## Aufgabe 1

*Leicht*

Beschreiben Sie die fünf Stufen einer Provisioning Factory in eigenen Worten, und nennen Sie je Stufe ein Risiko, das entsteht, wenn sie fehlt.

## Aufgabe 2

*Leicht*

Warum soll eine Gruppe mindestens zwei Besitzer haben? Welche Art von Konten sollte man als Besitzer nicht eintragen?

## Aufgabe 3

*Leicht*

Nennen Sie die vier Stufen vom Schreibschutz bis zum endgültigen Löschen eines Arbeitsbereichs und geben Sie an, welche davon umkehrbar sind und in welchem Zeitraum.

## Aufgabe 4

*Mittel*

Entwerfen Sie ein Drei-Stufen-Modell für Genehmigungen von Arbeitsbereichen. Legen Sie die Regeln für die Stufen fest und begründen Sie, warum die Stufe nicht von den Antragstellern selbst gewählt werden darf.

## Aufgabe 5

*Mittel*

Schreiben Sie eine PowerShell-Funktion, die einen Freitext in einen Mail-Nickname umwandelt (nur Kleinbuchstaben, Ziffern und Bindestriche, Umlaute ersetzt, maximal 40 Zeichen). Testen Sie sie mit mindestens drei schwierigen Eingaben.

## Aufgabe 6

*Mittel*

Erklären Sie anhand der Ablaufrichtlinie für Microsoft-365-Gruppen, warum man sie zunächst nur für ausgewählte Gruppen einschaltet. Welche Benachrichtigungen erhalten die Besitzer, und was passiert mit einer nicht verlängerten Gruppe?

## Aufgabe 7

*Schwer*

Erweitern Sie das Skript zur Prüfung des Metadatenstandards so, dass es zusätzlich Gruppen findet, die keinen Besitzer mit aktivem Konto haben, und eine Liste je Abteilung erzeugt, damit die Abteilungsleitung die Fälle bereinigen kann.

## Aufgabe 8

*Schwer*

Ein Skript zum Anlegen von Teams scheitert bei etwa jedem fünften Antrag mit dem Fehler 404 direkt nach dem Anlegen der Gruppe, an manchen Tagen zusätzlich mit 429. Analysieren Sie die Ursachen, und entwerfen Sie eine Lösung inklusive Protokollierung und Aufräumregel für halbfertige Gruppen.
