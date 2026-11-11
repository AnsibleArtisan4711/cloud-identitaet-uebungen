# Lösungen – Modul 11: Automation, Graph API und Policy-as-Code

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Beim delegierten Zugriff handelt das Programm im Namen einer angemeldeten Person und hat höchstens deren Rechte; das passt zu Aufgaben, die ein Administrator selbst ausführt. Beim Anwendungszugriff handelt die Anwendung mit eigener Identität ohne Benutzer; das braucht man für geplante, unbeaufsichtigte Aufgaben. Anwendungsrechte müssen ein Administrator genehmigen und sind oft weitreichender, weshalb sie besonders sparsam vergeben werden.

## Lösung zu Aufgabe 2

Graph liefert große Listen seitenweise, zum Beispiel 100 Benutzer je Seite. Wer nur die erste Seite liest, erhält unvollständige Ergebnisse ohne Fehlermeldung. Weitere Seiten erkennt man an der Eigenschaft `@odata.nextLink` in der Antwort. Man ruft diese Adresse unverändert auf, bis sie nicht mehr erscheint. Man darf nicht den Fortsetzungswert herauslösen und in eine andere Anfrage übernehmen.

## Lösung zu Aufgabe 3

Typische Eigenschaften: Parameter mit Prüfung (verhindert falsche Eingaben), Probelauf mit `-WhatIf` (zeigt Wirkung vor dem Ändern), Idempotenz (wiederholter Lauf richtet keinen Schaden an), Fehlerbehandlung (Fehler werden sichtbar statt verschluckt), Protokoll (macht Änderungen nachvollziehbar), Anmeldung ohne Geheimnis im Code (Sicherheit).

## Lösung zu Aufgabe 4

Ein Lösungsvorschlag:

```powershell
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$Ersatzbesitzer, [string]$Ausgabe = ".\ohne-besitzer.csv")
$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All" -NoWelcome
$user = Get-MgUser -UserId $Ersatzbesitzer
$treffer = foreach ($g in Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName) {
    if (@(Get-MgGroupOwner -GroupId $g.Id).Count -eq 0) {
        $status = "geplant"
        if ($PSCmdlet.ShouldProcess($g.DisplayName, "Besitzer $Ersatzbesitzer hinzufuegen")) {
            New-MgGroupOwnerByRef -GroupId $g.Id -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)" }
            $status = "zugewiesen"
        }
        [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $g.Id; Status = $status }
    }
}
$treffer | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
```

Das Skript ist idempotent, weil es nur Gruppen bearbeitet, die noch keinen Besitzer haben: Nach dem ersten Lauf haben sie einen, und ein zweiter Lauf findet sie nicht mehr. Mit `-WhatIf` werden keine Änderungen ausgeführt, die Datei zeigt den Status „geplant“.

> **Als Datei:** [`loesungen-skripte/aufgabe-04-ohne-besitzer.ps1`](loesungen-skripte/aufgabe-04-ohne-besitzer.ps1) (offline getestet)
>
> **Achtung:** Mit `-WhatIf` entsteht die Datei **nicht** (der Schalter gilt auch für `Export-Csv`); der Satz „die Datei zeigt den Status geplant“ in der Lösung trifft deshalb nicht zu. Siehe README, Abschnitt „Hinweise“.

## Lösung zu Aufgabe 5

Mögliche Ursachen: (1) Der Export enthält flüchtige Felder wie Zeitstempel; Gegenmaßnahme: Felder auf einen festen Satz begrenzen. (2) Die Reihenfolge der Einträge ist nicht stabil; Gegenmaßnahme: nach einem festen Schlüssel sortieren. (3) Unterschiedliche Formatierung, etwa Zeilenenden oder Einrückung; Gegenmaßnahme: einheitliche Kodierung und feste Tiefe beim Umwandeln in JSON. Zusätzlich kann der Export in einem anderen Zeitraum andere Objekte liefern, wenn Seiten nicht vollständig gelesen werden.

## Lösung zu Aufgabe 6

Eine Momentaufnahme extrahiert die aktuelle Konfiguration ausgewählter Ressourcen. Eine Baseline ist die JSON-Beschreibung des Soll-Zustands. Ein Monitor prüft regelmäßig, ob der Tenant der Baseline entspricht, und erzeugt bei Abweichungen Drift-Objekte. Grenzen: Momentaufnahmen höchstens 20.000 Ressourcen je Monat, 12 sichtbare Jobs und sieben Tage Aufbewahrung; Monitore höchstens 30 je Tenant, festes Intervall von sechs Stunden, höchstens 800 überwachte Ressourcen je Tag, 200 Ressourceninstanzen je Baseline; die Änderung einer Baseline löscht bisherige Ergebnisse.

## Lösung zu Aufgabe 7

Ein Beispiel: Repository mit Ordnern `soll/` (Baselines), `ist/` (nächtlicher Export), `skripte/` und `standards/`. Ablauf: (1) Änderung als Pull Request an der Baseline vorschlagen. (2) Automatische Prüfung: Formatprüfung der Dateien, Prüfung auf Geheimnisse. (3) Freigabe durch zweite Person. (4) Änderung im Portal oder per Skript mit Change-Nummer. (5) Nächtlicher Export in `ist/`. (6) Vergleich von Soll und Ist; bei Abweichung ein Ticket mit Idempotenzschlüssel. (7) Entscheidung: Baseline anpassen oder zurücksetzen. (8) Rollback aus der Sicherung, mit Prüfung. Wichtig sind der Verzicht auf Geheimnisse in den Dateien und die Begrenzung der Rechte der Automatisierung auf Lesen.

## Lösung zu Aufgabe 8

Bewertung: Die Identität hat zu weitreichende Rechte (Schreibzugriff auf das gesamte Verzeichnis, obwohl nur Teams archiviert werden sollen), das Geheimnis im Skript ist ein Offenlegungsrisiko, und es gibt weder Freigabe noch Protokoll. Neugestaltung: eigene Identität für diese Aufgabe, nur die für das Archivieren nötigen Berechtigungen (laut Berechtigungsreferenz zu prüfen); wenn das Skript in Azure läuft, verwaltete Identität, sonst Zertifikat im Zertifikatspeicher oder Tresor; Ausführung nur mit genehmigter Änderungsnummer; Probelauf und Liste der Kandidaten, die die Besitzer bestätigen; Protokoll je Team; Überwachung der Anmeldungen der Identität; Eintrag im Register der Automatisierungsidentitäten mit Besitzer und Ablaufdatum.
