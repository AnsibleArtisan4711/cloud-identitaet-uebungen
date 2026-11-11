# Lösungen – Modul 09: Monitoring, Reporting und Service Operations

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Die Berichte bieten die Zeiträume 7, 30, 90 und 180 Tage. Standardmäßig sind Benutzer-, Gruppen- und Websitenamen verborgen (als Hashwerte), um den Datenschutz zu unterstützen. Ein globaler Administrator kann die Einstellung in den Organisationseinstellungen ändern; das Anzeigen identifizierbarer Informationen wird im Überwachungsprotokoll festgehalten. Die Entscheidung gehört deshalb mit Datenschutz abgestimmt.

## Lösung zu Aufgabe 2

Überwachungs- und Anmeldeprotokolle bleiben bei Entra ID Free sieben Tage und bei P1 und P2 30 Tage erhalten. Längere Aufbewahrung erreicht man durch Diagnoseeinstellungen, die die Protokolle an ein Speicherkonto, einen Log-Analytics-Arbeitsbereich oder einen Event Hub senden. Die Änderung einer Lizenz wirkt nicht rückwirkend; abgelaufene Daten sind verloren.

## Lösung zu Aufgabe 3

Die Dienstintegrität zeigt aktuelle Störungen und Hinweise zum Dienst; das Nachrichtencenter kündigt Änderungen an, teilweise mit Handlungsfrist. Der Betrieb braucht für die Dienstintegrität jemanden, der Störungen einordnet und die Kommunikation steuert, und für das Nachrichtencenter jemanden, der Änderungen bewertet, Maßnahmen anstößt und Fristen verfolgt.

## Lösung zu Aufgabe 4

Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome
Get-MgReportOffice365ActiveUserDetail -Period D30 -OutFile .\aktiv30.csv
$z = Import-Csv .\aktiv30.csv | Where-Object 'Is Deleted' -ne 'True'
if ('Teams Last Activity Date' -notin $z[0].PSObject.Properties.Name) { throw "Spalte fehlt" }
$grenze = (Get-Date).AddDays(-30).Date
$aktiv = $z | Where-Object {
  $d = $null
  [datetime]::TryParse($_.'Teams Last Activity Date', [ref]$d) -and $d -ge $grenze
}
"{0} von {1} ({2:P0}) in Teams aktiv" -f @($aktiv).Count, @($z).Count, (@($aktiv).Count / @($z).Count)
```

Das Skript lädt den 30-Tage-Bericht, entfernt gelöschte Konten, prüft die Spalte, wandelt das Datum um und zählt Konten mit Aktivität nach der Grenze. Der Anteil wird als Prozentwert ausgegeben.

> **Als Datei:** [`loesungen-skripte/aufgabe-04-teams-aktiv.ps1`](loesungen-skripte/aufgabe-04-teams-aktiv.ps1) (Logik offline getestet an einer Kopie; das Original scheitert an `[datetime]::TryParse` mit `$null`, siehe README, Abschnitt „Hinweise“)

## Lösung zu Aufgabe 5

Ein Beispiel: Zweck: Externe Person kontrolliert in die Zusammenarbeit aufnehmen. Voraussetzungen: Rolle zur Einladung, Genehmigung des Verantwortlichen, Ausnahmeprüfung. Schritte: (1) Antrag prüfen, (2) Einladung über den vorgesehenen Weg senden, (3) Zugriffspaket oder Teammitgliedschaft zuweisen, (4) Ablaufdatum setzen. Prüfung: Gast erscheint mit korrektem Status und minimalen Rechten, Anmeldung klappt. Rückweg: Gastkonto aus Gruppe entfernen, bei Bedarf Konto löschen. Eskalation: bei Anmeldeproblemen an das Identity-Team, bei Sicherheitsverdacht an Security. Letzte Prüfung: ein konkretes Datum im Format JJJJ-MM-TT.

## Lösung zu Aufgabe 6

Ein Lösungsvorschlag:

```powershell
SigninLogs
| where TimeGenerated > ago(24h)
| where ResultType != "0"
| summarize Fehlversuche = count() by UserPrincipalName
| where Fehlversuche > 20
| order by Fehlversuche desc
```

Die Abfrage filtert die letzten 24 Stunden und alle Anmeldungen mit Ergebnis ungleich 0 (Fehler), zählt sie je Benutzer mit `summarize`, behält nur Benutzer mit mehr als 20 Versuchen und sortiert absteigend. Bei vielen Fehlversuchen für viele Konten von einer Adresse spricht man von Passwort-Spraying; deshalb lohnt eine zweite Abfrage nach IP-Adresse.

## Lösung zu Aufgabe 7

Ein Ansatz: Nach der Bewertung die Ergebnisse nach Status sortieren (rot, gelb, grün über eine Sortierhilfe) und mit einer Schleife Zeilen im Markdown-Tabellenformat erzeugen:

```powershell
$rang = @{ rot = 0; gelb = 1; gruen = 2 }
$zeilen = $ergebnis | Sort-Object { $rang[$_.Status] }, Kennzahl |
  ForEach-Object { "| {0} | {1} | {2} | {3} | {4} |" -f $_.Kennzahl, $_.Wert, $_.Ziel, $_.Status, $_.Verantwortlich }
@("| Kennzahl | Wert | Ziel | Status | Verantwortlich |", "|---|---|---|---|---|") + $zeilen |
  Set-Content -Path ".\kpi-bericht.md" -Encoding UTF8
```

Die Hashtable `$rang` ordnet den Status einer Zahl zu, die Sortierung stellt rote Kennzahlen nach oben. Die Kopfzeilen und die Datenzeilen werden zu einer Datei zusammengesetzt.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-kpi-bericht.ps1`](loesungen-skripte/aufgabe-07-kpi-bericht.ps1) (offline getestet)
>
> Das Stück ist **kein eigenständiges Skript**: Es braucht die Variable `$ergebnis` aus `Get-KpiStatus.ps1` und gehört ans Ende dieses Skripts. Die Tests setzen `$ergebnis` selbst und führen die Datei dann aus.

## Lösung zu Aufgabe 8

Ein Beispiel: (1) MFA-Abdeckung, Ziel 98, Alarm 90, Quelle Registrierungsbericht, Identity-Team. (2) Teams mit zwei Besitzern, Ziel 98, Alarm 90, Quelle Graph, Teams-Betrieb. (3) Websites ohne Aktivität über 180 Tage, Ziel unter 10, Alarm über 20, Quelle Websitebericht, SharePoint-Betrieb. (4) Anteil beschrifteter Inhalte, Ziel 70 nach 12 Monaten, Alarm 40, Quelle Label-Aktivität und Inventar, Compliance. (5) Secure Score, Ziel nach Roadmap, Quelle Graph, Security. (6) Offene Sicherheitsvorfälle über 7 Tage, Ziel 0, Alarm 5, Quelle Vorfälle, Security-Betrieb. (7) Abgelaufene Ausnahmen, Ziel 0, Alarm 3, Quelle Ausnahmenregister, Security. (8) Runbooks älter als 365 Tage, Ziel 0, Alarm 3, Quelle Runbook-Prüfung, IT-Governance. Datenschutz und Betriebsrat: Kennzahlen sind aggregiert und ohne Personenbezug; Zweck und Datenquellen werden in einer Berichtsrichtlinie festgehalten und mit der Arbeitnehmervertretung abgestimmt, bevor die Verbergung der Namen in den Berichten aufgehoben wird (keine Rechtsberatung).
