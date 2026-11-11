# Lösungen – Modul 04: SharePoint und OneDrive Governance

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Eine Teamwebsite dient der Zusammenarbeit in einem festen Personenkreis und ist meist mit einer Microsoft-365-Gruppe verbunden (dann spricht man von einer gruppenverbundenen Website, deren Mitgliedschaft der Gruppe folgt). Eine Kommunikationswebsite dient dem Veröffentlichen von Informationen für viele Leser, wird nicht mit einer Gruppe verbunden und über SharePoint-Berechtigungen gesteuert. Die gruppenverbundene Website ist also eine Ausprägung der Teamwebsite, kein dritter Typ neben beiden.

## Lösung zu Aufgabe 2

Richtig ist, dass ein Hub Navigation, Erscheinungsbild und Suche verbindet. Er vererbt keine Berechtigungen: Wer eine Website an einen Hub anschließt, ändert nicht, wer sie sehen darf. Inhalte aus angeschlossenen Websites erscheinen im Hub nur für Personen, die sie ohnehin sehen dürfen.

## Lösung zu Aufgabe 3

Beliebige Personen (`ExternalUserAndGuestSharing`), neue und vorhandene Gäste (`ExternalUserSharingOnly`), nur vorhandene Gäste (`ExistingExternalUserSharingOnly`) und nur Personen in der Organisation (`Disabled`).

## Lösung zu Aufgabe 4

Ein Beispiel: Öffentlich (Datenschutzstufe öffentlich, Gäste erlaubt, Freigabe großzügig bis Gäste), Intern als Standard (privat, Gäste nach Genehmigung, Freigabe an vorhandene Gäste), Vertraulich (privat, keine neuen Gäste, Freigabe nur intern, eingeschränkter Zugriff von nicht verwalteten Geräten), Streng vertraulich (wie Vertraulich, zusätzlich Bedingungen über den bedingten Zugriff und verpflichtende Authentifizierungskontexte). Jede Stufe erhält eine kurze Beschreibung mit Beispiel, ein Standardlabel gilt für neue Teams.

## Lösung zu Aufgabe 5

Zuerst wird die Zuordnung nach Thema geplant (zum Beispiel ein Hub „Projekte“ mit der Namensregel `PRJ-`), dann Navigation und Design am Hub festgelegt und die Websites per Skript angeschlossen. Wichtig ist die Klärung der Fehlannahme: Die Anbindung ändert keine Berechtigungen. Vertrauliche Projektwebsites bleiben ebenso geschützt wie vorher. Zusätzlich wird geprüft, dass keine Website bereits an einen anderen Hub angeschlossen ist, weil eine Website nur zu einem Hub gehören kann.

## Lösung zu Aufgabe 6

Ein mögliches Skript:

```powershell
Connect-SPOService -Url "https://contoso-admin.sharepoint.com"
Get-SPOSite -Limit All -IncludePersonalSite $false |
  Where-Object { $_.StorageQuota -gt 0 -and
                 ($_.StorageUsageCurrent / $_.StorageQuota) -gt 0.9 } |
  Select-Object Url, Owner,
    @{n='FreiGB'; e={ [math]::Round(($_.StorageQuota - $_.StorageUsageCurrent) / 1024, 2) }} |
  Sort-Object FreiGB | Format-Table -AutoSize
```

Das Skript filtert zuerst auf Websites mit gesetzter Quote, um eine Division durch null zu vermeiden, und vergleicht dann Verbrauch und Quote. Der freie Speicher wird aus der Differenz berechnet und von Megabyte in Gigabyte umgerechnet. Die Sortierung zeigt die engsten Fälle zuerst.

> **Als Datei:** [`loesungen-skripte/aufgabe-06-speicher-ueber-90-prozent.ps1`](loesungen-skripte/aufgabe-06-speicher-ueber-90-prozent.ps1) (offline getestet)

## Lösung zu Aufgabe 7

Ein möglicher Entwurf: Anlage über die Bereitstellungsfabrik mit zwei Besitzern, Label und Laufzeit. Nach 12 Monaten ohne Änderung fragt das System die Besitzer (Bestätigungsfrist 30 Tage, Erinnerung nach 14 Tagen). Bestätigung verlängert um 12 Monate. Keine Antwort: schreibgeschützt für 6 Monate, Benachrichtigung an Besitzer und Vertretung. Danach Archivierung. Löschung nur nach Freigabe durch den Fachbereich und nach Prüfung der Aufbewahrung in Purview. Für Websites mit Aufbewahrungspflicht oder rechtlicher Sperre gilt: Der Löschschritt entfällt, die Website bleibt archiviert, bis die Frist abgelaufen ist. Verantwortlich sind Besitzer (Bestätigung), IT-Governance (Betrieb des Jobs) und Compliance (Aufbewahrung).

## Lösung zu Aufgabe 8

Vorgehen: (1) Fehlerbild klären: Fehlermeldung, Link, Zeitpunkt. (2) Gastkonto prüfen: Einladung angenommen, Konto aktiv. (3) Zugriff prüfen für den Gast auf der Datei. (4) Website-Zustand prüfen: Freigabestufe, Label, Sperrstatus. (5) Anmeldeprotokoll des Gastes ansehen: blockiert der bedingte Zugriff? (6) Ergebnis dokumentieren. Mögliche Ursachen: Tenantebene verbietet die Freigabe an neue Gäste; die Website ist strenger als der Tenant eingestellt; ein Label verbietet Gäste; der Freigabelink ist abgelaufen; die Einladung wurde nicht angenommen; eine Richtlinie des bedingten Zugriffs verlangt ein Gerät oder eine Authentifizierung, die der Gast nicht erfüllt.
