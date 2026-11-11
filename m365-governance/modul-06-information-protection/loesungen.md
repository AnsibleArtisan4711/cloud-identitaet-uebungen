# Lösungen – Modul 06: Information Protection und Data Governance

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Das Label ist die Definition der Einstufung (Name, Beschreibung, Schutzaktionen). Die Labelrichtlinie veröffentlicht Labels an Benutzergruppen und bestimmt das Verhalten (Pflicht, Standard, Begründung). Ein Label, das in keiner Richtlinie steht, wird niemandem angeboten und kann deshalb nicht manuell angewendet werden. Es ist, als würde man einen Stempel anfertigen und ihn dann im Schrank lassen.

## Lösung zu Aufgabe 2

Die drei Teile sind Orte, Regeln (Bedingungen und Aktionen) und Modus. Der Testmodus verhindert, dass Fehlalarme den Betrieb stören. Im Testmodus lassen sich Treffer in Berichten und im Aktivitäts-Explorer auswerten, Schwellenwerte anpassen und Ausnahmen identifizieren. Die Aktivierung ist dann eine bewusste, dokumentierte Entscheidung.

## Lösung zu Aufgabe 3

Richtig ist (b): Aufbewahrung gewinnt gegen Löschung. Die Aussage (a) ist falsch, denn bei der Aufbewahrung gilt die längste Frist. Die Aussage (c) ist falsch, denn es gibt keine Regel „zuletzt angelegt gewinnt“; maßgeblich sind die vier Prinzipien (Aufbewahrung vor Löschung, längste Aufbewahrung, explizit vor implizit, kürzeste Löschdauer).

## Lösung zu Aufgabe 4

Ein möglicher Entwurf: Öffentlich (Tooltip: Speisekarte, Pressemitteilung), Intern (Standard, Tooltip: interne Mitteilungen, Protokolle), Vertraulich (Verträge, Preise, Personaldaten), Streng vertraulich (Vorstandsunterlagen, Fusionsprojekte). Intern ist das Standardlabel, damit keine Datei ohne Einstufung bleibt. Verschlüsselung ist ab Vertraulich sinnvoll, wenn der Empfängerkreis klar ist, und bei Streng vertraulich üblich. Dabei muss die Zusammenarbeit mit Externen geplant sein, denn verschlüsselte Dateien benötigen berechtigte Identitäten.

## Lösung zu Aufgabe 5

Ein Lösungsvorschlag:

```powershell
Connect-IPPSSession
New-DlpCompliancePolicy -Name "DLP IBAN Mail" -ExchangeLocation All `
    -Mode TestWithNotifications
New-DlpComplianceRule -Name "IBAN ab drei Treffern" -Policy "DLP IBAN Mail" `
    -ContentContainsSensitiveInformation @{
        Name = "International Banking Account Number (IBAN)"; minCount = "3" } `
    -NotifyUser Owner
```

Die Richtlinie läuft im Testmodus, die Schwelle liegt bei drei Treffern, und es gibt keine Blockadeaktion. Der Besitzer erhält eine Benachrichtigung.

> **Als Datei:** [`loesungen-skripte/aufgabe-05-dlp-iban-mail.ps1`](loesungen-skripte/aufgabe-05-dlp-iban-mail.ps1) (offline getestet)

## Lösung zu Aufgabe 6

Bewertung: Das Verhalten ist gewollt, wenn die Datei zu Recht als Record deklariert wurde. Zu prüfen ist, ob die Datei bereits abgeschlossen ist oder noch ein Entwurf war. Zwei Anpassungen: (1) Entwürfe liegen in einer Bibliothek ohne Record-Label, das Label wird erst bei Freigabe angewendet. (2) Für Änderungen nach Unterschrift wird eine neue Version als eigenes Dokument angelegt, das verweist auf das ursprüngliche. Eine dritte Variante wäre, das Label durch eine berechtigte Person entfernen zu lassen, wenn es sich nicht um einen regulatorischen Record handelt, und dies zu protokollieren.

## Lösung zu Aufgabe 7

Ein möglicher Lösungsvorschlag:

```powershell
Connect-IPPSSession
Get-RetentionCompliancePolicy -DistributionDetail |
    Where-Object { -not $_.Enabled -or $_.DistributionStatus -ne 'Success' } |
    Select-Object Name, Enabled, DistributionStatus |
    Format-Table -AutoSize
```

Das Cmdlet liest alle Aufbewahrungsrichtlinien mit Verteilungsdetails. Der Filter zeigt Richtlinien, die entweder nicht aktiviert sind oder deren Verteilungsstatus nicht `Success` ist. Die Auswahl der Spalten und die tabellarische Ausgabe erleichtern die Weitergabe an den Betrieb.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-aufbewahrung-nicht-aktiv.ps1`](loesungen-skripte/aufgabe-07-aufbewahrung-nicht-aktiv.ps1) (offline getestet)

## Lösung zu Aufgabe 8

Konzept: Zwei Segmente (Mandat A und Mandat B) anhand eines Verzeichnisattributs, zum Beispiel einer Abteilung oder eines benutzerdefinierten Attributs. Zwei Richtlinien, je eine pro Richtung (A blockiert B, B blockiert A), zunächst inaktiv. Nach Prüfung der Zuordnung aktivieren und mit `Start-InformationBarrierPoliciesApplication` anwenden, den Status überwachen. Voraussetzungen: geeignete Lizenz und Administratorrolle, sauber gepflegte Attribute, Klärung der Wirkung auf die Personensuche in Teams. Risiken: (1) Falsche oder veraltete Attribute führen zu Fehlzuordnungen, deshalb gehört die Attributpflege in den Versetzungsprozess. (2) Die Barriere deckt nur die unterstützten Dienste ab; Kommunikation außerhalb (private Kanäle, externe Tools) bleibt ungeschützt und braucht organisatorische Regeln.
