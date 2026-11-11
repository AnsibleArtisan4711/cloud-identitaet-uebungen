# Lösungen – Modul 07: Compliance, Audit und Risk Management

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Das Protokoll beantwortet, wer wann welche Aktivität in welchem Dienst durchgeführt hat. Die Aufbewahrungsdauer bestimmt, wie weit zurück Untersuchungen möglich sind. Ein Ereignis, das älter als die Aufbewahrung ist, lässt sich nicht mehr belegen; die Dauer muss zu den Nachweispflichten und zur Lizenz passen.

## Lösung zu Aufgabe 2

Die Phasen sind Identifizieren, Sichern, Sammeln, Prüfen und Herausgeben. Ein enger Suchumfang entspricht dem Grundsatz der Erforderlichkeit, reduziert die Menge verarbeiteter personenbezogener Daten, erleichtert die Prüfung und verringert das Risiko bei Export und Weitergabe.

## Lösung zu Aufgabe 3

Eine Aufbewahrungsrichtlinie ist eine Dauerregel zur Datenverwaltung mit definiertem Ende, die flächendeckend wirkt. Ein Legal Hold ist eine gezielte Sperre für einen Fall, die ohne Ablaufdatum gilt, bis jemand sie aufhebt, und die dem Fall zugeordnet ist. Der Hold dient der Beweissicherung, die Richtlinie der laufenden Datenverwaltung.

## Lösung zu Aufgabe 4

Ein möglicher Entwurf:

```powershell
Connect-ExchangeOnline
$ende = (Get-Date).ToUniversalTime(); $start = $ende.AddDays(-3)
Search-UnifiedAuditLog -StartDate $start -EndDate $ende `
    -Operations SharingLinkCreated -ResultSize 5000 |
  ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{ Zeit = $_.CreationDate; Benutzer = $_.UserIds
                       Datei = $d.SourceFileName }
  } | Sort-Object Zeit | Format-Table -AutoSize
```

Das Skript begrenzt den Zeitraum auf drei Tage in UTC, filtert nach der Operation, wandelt das JSON-Feld in Objekte um und gibt eine Tabelle aus. Den genauen Operationsnamen prüft man mit einer Suche ohne Filter in einem kleinen Zeitfenster.

> **Als Datei:** [`loesungen-skripte/aufgabe-04-sharing-links.ps1`](loesungen-skripte/aufgabe-04-sharing-links.ps1) (offline getestet)

## Lösung zu Aufgabe 5

Mögliche Punkte: (1) konkreter Zweck (Schutz von Betriebsgeheimnissen, keine Leistungskontrolle), (2) Pseudonymisierung als Standard und Vier-Augen-Prinzip bei Aufhebung, (3) benannte Rollen und Prüfer mit Schulung, (4) Aufbewahrungsfrist für Warnungen und Fälle, (5) Informationspflicht gegenüber Beschäftigten und Beteiligung des Betriebsrats bei Änderungen. Ergänzend: Verbot, Ergebnisse allein für arbeitsrechtliche Maßnahmen zu verwenden.

## Lösung zu Aufgabe 6

Man liest die Mitglieder der vier Rollengruppen aus, bildet die Schnittmenge zwischen Administratoren und Prüfern und meldet jede Überschneidung als Befund. Zusätzlich meldet man Gruppen ohne Mitglied (Prozesslücke), Mitglieder, die nicht mehr im Unternehmen sind, und Personen mit zu breiten Rollen. Das Ergebnis geht in das regelmäßige Berechtigungsreview.

## Lösung zu Aufgabe 7

Beispielzeilen: (1) Rollenbasierter Zugriff mit Gruppen, Maßnahme Zugriffsüberprüfung (Modul 2), Verantwortlich IT-Governance, Nachweis Bericht der Überprüfung. (2) Eingeschränkte Freigabe für Websites (Modul 4), Verantwortlich SharePoint-Betrieb, Nachweis Einstellungen und Bericht. (3) Klassifizierung mit Labels (Modul 6), Verantwortlich Compliance, Nachweis Labelrichtlinie. (4) DLP gegen unbefugten Versand (Modul 6), Verantwortlich Compliance, Nachweis Richtlinie und Trefferbericht. (5) Protokollierung von Zugriffen (Lerneinheit 7.1), Verantwortlich Security, Nachweis Audit-Konfiguration. (6) Nachvollziehbare Administration (Modul 8, Privileged Access), Verantwortlich Security, Nachweis PIM-Protokolle. Hinweis: Welche Anforderung konkret gilt, ist rechtlich zu klären.

> **Als Datei:** [`loesungen-skripte/nachweismatrix-aufgabe-07.csv`](loesungen-skripte/nachweismatrix-aufgabe-07.csv) (sechs Zeilen aus dieser Lösung als CSV mit Semikolon; wird von `Test-EvidenceMatrix.ps1` ohne Lücken gelesen. Die Statuswerte „Entwurf“ sind ein Platzhalter, keine Aussage über einen echten Tenant.)

## Lösung zu Aufgabe 8

Vorgehen: (1) Status der Sperrrichtlinie prüfen (Verteilungsstatus, aktiviert). (2) Prüfen, ob die OneDrive-Adresse in der Richtlinie steht und korrekt geschrieben ist. (3) Prüfen, ob der Benutzer ein OneDrive besitzt und ob die Daten dort tatsächlich fehlen oder nur im Papierkorb liegen. (4) Prüfen, wann die Daten gelöscht wurden (Audit) im Verhältnis zum Hold-Beginn. (5) Wiederherstellung aus Papierkorb und gegebenenfalls Preservation-Hold-Bibliothek. Mögliche Ursachen: OneDrive nicht in die Sperre aufgenommen, Verteilungsfehler, Löschung vor dem Hold, Sperre mit Abfrage, die die Dateien nicht erfasst. Künftig verhindert eine Checkliste den Fehler: Umfang aus Postfach, OneDrive, Teams, Statusprüfung nach 24 Stunden, Dokumentation im Fall.
