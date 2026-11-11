# Lösungen – Modul 05: Exchange und Kommunikations-Governance

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Eine Verteilerliste ist eine reine Adresse für mehrere Empfänger, etwa „alle-vertrieb“. Eine Microsoft-365-Gruppe ist ein Arbeitsbereich mit Postfach, Kalender, Dateispeicher und optional einem Team, etwa für ein Projekt. Ein freigegebenes Postfach ist ein Postfach ohne eigene Person für eine Funktion, etwa „info@“. Die Wahl richtet sich nach dem Zweck: nur Adresse, Zusammenarbeit oder gemeinsame Bearbeitung eingehender Anfragen.

## Lösung zu Aufgabe 2

Die drei Berechtigungen sind Vollzugriff, Senden als und Senden im Auftrag. Bei „Senden als“ erscheint nur die Postfachadresse, bei „Senden im Auftrag“ wird die sendende Person mit genannt. Rechte an Gruppen erleichtern Wechsel, Überprüfung und Nachvollziehbarkeit, weil nur die Gruppenmitgliedschaft geändert wird.

## Lösung zu Aufgabe 3

Mögliche Risiken: Weiterleitungen nach außen (5.1), Verteilerlisten mit offenen Absendern (5.2), Gruppen ohne Besitzer oder Ablauf (5.3), Regeln ohne Dokumentation (5.4), überfüllte oder unverwaltete freigegebene Postfächer (5.5), fehlende Aufbewahrung bei Austritt (5.6), nicht erkennbare externe Absender (5.7), nicht nachvollziehbare Zustellprobleme (5.8).

## Lösung zu Aufgabe 4

Die Regel mit Priorität 2 wird zuerst abgearbeitet, denn niedrigere Zahlen haben Vorrang. Enthält die Nachricht das Wort, wird sie blockiert, und die zweite Regel sieht sie nicht mehr. Soll der Ausschluss trotzdem angehängt werden, tauscht man die Prioritäten, achtet darauf, dass die Blockregel nicht den Ausschluss braucht, oder baut den Ausschluss als Teil der Blockmeldung ein. Die Änderung wirkt erst nach einer Wartezeit von bis zu 30 Minuten (Ergänzung in 5.4).

## Lösung zu Aufgabe 5

Ein Lösungsvorschlag:

```powershell
Connect-ExchangeOnline
$eigene = (Get-AcceptedDomain).DomainName | ForEach-Object { $_.ToString().ToLower() }
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ForwardingSmtpAddress } | ForEach-Object {
    $ziel = ($_.ForwardingSmtpAddress.ToString() -replace '^smtp:','').ToLower()
    $domain = $ziel.Split('@')[-1]
    if ($domain -notin $eigene) {
        [pscustomobject]@{ Postfach = $_.PrimarySmtpAddress; Ziel = $ziel }
    }
}
```

Das Skript sammelt die eigenen Domänen, filtert Postfächer mit Weiterleitung, entfernt das Präfix „smtp:“ und vergleicht die Zieldomäne. Die Eigenschaft erfasst nur vom Administrator gesetzte Weiterleitungen; Posteingangsregeln des Benutzers, die an externe Adressen weiterleiten, stehen in den Regeln des Postfachs und werden mit `Get-InboxRule` abgefragt.

> **Als Datei:** [`loesungen-skripte/aufgabe-05-weiterleitungen-extern.ps1`](loesungen-skripte/aufgabe-05-weiterleitungen-extern.ps1) (offline getestet)

## Lösung zu Aufgabe 6

Ein Beispiel: Präfix „GRP“, Platzhalter für den Gruppennamen und die Abteilung, also „GRP_[GroupName]_[Department]“. Gesperrte Wörter: „CEO“, „Payroll“, „Gehalt“. Zu beachten sind die Gesamtlänge von 63 Zeichen, die exakte Wortübereinstimmung bei gesperrten Wörtern, die Ausnahme bestimmter Administratorrollen, die Lizenzanforderung und die Qualität der Attribute, die als Platzhalter dienen.

## Lösung zu Aufgabe 7

Ein Lösungsvorschlag:

```powershell
Connect-ExchangeOnline
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | ForEach-Object {
    $pm = $_
    $personen = Get-MailboxPermission -Identity $pm.PrimarySmtpAddress |
        Where-Object { $_.User -notlike "NT AUTHORITY*" -and -not $_.IsInherited -and -not $_.Deny } |
        ForEach-Object {
            $r = Get-Recipient -Identity $_.User -ErrorAction SilentlyContinue
            if ($r -and $r.RecipientTypeDetails -in "UserMailbox","MailUser") { $_.User }
        }
    if ($personen) { [pscustomobject]@{ Postfach = $pm.PrimarySmtpAddress; DirektBerechtigt = ($personen -join "; ") } }
}
```

Das Skript ermittelt die Berechtigungen jedes freigegebenen Postfachs, schließt Systemkonten und geerbte Rechte aus und prüft über den Empfängertyp, ob ein Benutzer oder eine Gruppe berechtigt ist. Direkt berechtigte Personen werden aufgelistet und können in Gruppenrechte überführt werden.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-gemeinsame-postfaecher-direkt.ps1`](loesungen-skripte/aufgabe-07-gemeinsame-postfaecher-direkt.ps1) (offline getestet)

## Lösung zu Aufgabe 8

Ein möglicher Ablauf: (1) Fall präzisieren: Absender, Empfänger, Zeitpunkt, Fehlermeldung, ob einzelne oder alle Mails betroffen sind. (2) Junk-Ordner, Quarantäne und Regeln des Benutzers prüfen. (3) Nachrichtenablaufverfolgung nach Absenderadresse und Zeitraum durchführen. (4) Je nach Status die Details abfragen: wurde die Nachricht abgelehnt, von einer Transportregel verändert, gefiltert oder gar nicht empfangen? (5) Ursache beheben, zum Beispiel Ausnahme für einen Absender in der Filterung, Anpassung einer Regel oder Korrektur der Absenderdomäne beim Kunden (SPF, DMARC). (6) Lösung mit dem Benutzer testen, Fall im Ticket dokumentieren und, falls häufig, ein Runbook ergänzen. Mögliche Ursachen: Absenderdomäne neu auf einer Sperrliste, Kunde hat DMARC-Richtlinie verschärft, Regel blockiert wegen Schlüsselwort, Postfach des Empfängers voll, Dienststörung.
