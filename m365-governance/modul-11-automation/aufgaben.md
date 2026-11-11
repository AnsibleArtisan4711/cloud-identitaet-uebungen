# Aufgaben – Modul 11: Automation, Graph API und Policy-as-Code

Acht Aufgaben mit steigender Schwierigkeit. Die Lösungen stehen getrennt in [loesungen.md](loesungen.md) – erst selbst versuchen.

Richtwert für den Zeitaufwand (Schätzung, nicht aus dem Skript): leicht 10 bis 15 Minuten, mittel 20 bis 40 Minuten, schwer 45 bis 90 Minuten.

## Aufgabe 1

*Leicht*

Erklären Sie die Begriffe „delegierter Zugriff“ und „Anwendungszugriff“ bei Microsoft Graph. Für welche Art von Aufgaben brauchen Sie welchen?

## Aufgabe 2

*Leicht*

Warum reicht es nicht, bei einer Abfrage nur die erste Seite der Antwort zu lesen? Wie erkennt man, dass es weitere Seiten gibt, und was darf man mit der Adresse der nächsten Seite nicht tun?

## Aufgabe 3

*Leicht*

Nennen Sie fünf Eigenschaften eines betriebstauglichen PowerShell-Skripts und erklären Sie in je einem Satz, warum sie wichtig sind.

## Aufgabe 4

*Mittel*

Schreiben Sie ein Skript im Stil dieses Moduls, das alle Gruppen ohne Besitzer findet, die Liste in eine Datei schreibt und mit dem Schalter `-WhatIf` lediglich anzeigt, welche Gruppen es einer Ersatzperson als Besitzer zuweisen würde. Beschreiben Sie, warum das Skript idempotent ist.

## Aufgabe 5

*Mittel*

Ein Export der Transportregeln meldet bei jedem Lauf Hunderte Änderungen im Git-Repository, obwohl niemand etwas geändert hat. Nennen Sie drei mögliche Ursachen und die Gegenmaßnahmen.

## Aufgabe 6

*Mittel*

Beschreiben Sie den Unterschied zwischen einer Momentaufnahme, einer Baseline und einem Monitor in der Tenant-Konfigurationsverwaltung. Welche Grenzen müssen Sie bei der Planung beachten?

## Aufgabe 7

*Schwer*

Entwerfen Sie ein Gesamtkonzept „Konfiguration als Code“ für die Einstellungen bedingter Zugriff und Transportregeln: Repository-Struktur, Änderungsprozess, automatische Prüfungen, Drift-Erkennung, Benachrichtigung, Rollback. Zeichnen Sie den Ablauf als Liste von Schritten.

## Aufgabe 8

*Schwer*

Ein Automatisierungsskript soll Teams archivieren. Es läuft mit einer Anwendungsidentität, die `Directory.ReadWrite.All` besitzt, und das Geheimnis steht im Skript. Bewerten Sie die Lösung und beschreiben Sie eine sichere Neugestaltung mit Identität, Rechten, Geheimnisverwaltung, Freigabe und Protokoll.
