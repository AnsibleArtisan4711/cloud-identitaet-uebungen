# Lösungen – Modul 01: Grundlagen, Governance-Modell und Zielarchitektur

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

(a) vorbeugend: Die Richtlinie greift bei der Erstellung und verhindert unerwünschte Namen. (b) aufdeckend: Der Bericht findet bestehende Verstöße nach dem Ereignis. (c) korrigierend: Der gewünschte Zustand wird wiederhergestellt, nachdem ein Fehler passiert ist. (d) vorbeugend: Nur Mitglieder der Erstellergruppe können überhaupt Gruppen anlegen. Wichtig ist die Begründung: Der Zeitpunkt der Wirkung (vor, nach oder bei der Korrektur eines Ereignisses) entscheidet.

## Lösung zu Aufgabe 2

Governance legt fest, wer nach welchen Regeln entscheidet. Management organisiert die Umsetzung mit Ressourcen und Terminen. Administration führt die technischen Tätigkeiten im Alltag aus. Zuordnung: Die 180-Tage-Regel ist Governance (Regelsetzung). Das Anlegen des Teams ist Administration. Die Planung der Einführung bis Quartalsende ist Management.

## Lösung zu Aufgabe 3

Pro Aufgabe darf es nur einen Accountable (Gesamtverantwortlichen) geben. Zwei „A“ bedeuten, dass im Konfliktfall niemand entscheidet. Korrekt ist: Teambesitzer = A/R (er kennt die Notwendigkeit und führt die Verlängerung aus), Service Owner = C (berät zur Technik), Governance Lead = I (wird informiert, prüft die Einhaltung des Standards). Die Zeile bildet damit das föderierte Prinzip ab: Die Entscheidung liegt bei dem, der den Bedarf kennt.

## Lösung zu Aufgabe 4

Das Filtern geschieht nach dem Laden der Gruppen in der Schleife, weil `CreatedDateTime` bereits im Property-Auswahlsatz enthalten ist:

```powershell
$cutoff = (Get-Date).AddDays(-30)
$result = foreach ($g in $groups) {
    if ($g.CreatedDateTime -gt $cutoff) { continue }   # zu neu, ueberspringen
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All)
    if ($owners.Count -lt $MinOwners) {
        [pscustomobject]@{ Gruppe=$g.DisplayName; GruppenId=$g.Id
                           Besitzer=$owners.Count; Erstellt=$g.CreatedDateTime }
    }
}
```

Die Schleife überspringt mit `continue` jede Gruppe, die nach dem Stichtag erstellt wurde, und spart damit auch die Besitzerabfrage. Als Verbesserung könnten Sie den Wert 30 als Parameter `-MinAgeDays` anbieten.

> **Lauffähige Fassung:** [`loesungen-skripte/Find-GroupsWithFewOwners.aufgabe-4.ps1`](loesungen-skripte/Find-GroupsWithFewOwners.aufgabe-4.ps1) (Listing 2 mit eingesetztem Ausschnitt; offline getestet).

## Lösung zu Aufgabe 5

In der JSON-Datei wird unter `rules` die Zeile `"maxGuestShare": 0.2` ergänzt. Im Skript kommt hinzu:

```powershell
Connect-MgGraph -Scopes "RoleManagement.Read.Directory","User.Read.All" -NoWelcome
$all    = Get-MgUserCount -ConsistencyLevel eventual
$guests = Get-MgUserCount -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$share  = if ($all -gt 0) { [math]::Round($guests / $all, 3) } else { 0 }
[pscustomobject]@{
    Regel    = "maxGuestShare"
    Soll     = "<= $($policy.rules.maxGuestShare)"
    Ist      = $share
    Ergebnis = if ($share -le $policy.rules.maxGuestShare) { "OK" } else { "ABWEICHUNG" }
}
```

Wichtig sind der erweiterte Abfragemodus (`ConsistencyLevel eventual`), den die Zählabfragen für Filter benötigen, und die Absicherung gegen eine Division durch null in leeren Testtenants.

> **Lauffähige Fassung:** [`loesungen-skripte/Test-PolicyCompliance.aufgabe-5.ps1`](loesungen-skripte/Test-PolicyCompliance.aufgabe-5.ps1) mit [`policy-tenant.aufgabe-5.json`](loesungen-skripte/policy-tenant.aufgabe-5.json) (offline getestet).

## Lösung zu Aufgabe 6

Beispiel: „Jeder Gast ist einem Team zugeordnet und hat eine bestätigte Zugriffsüberprüfung, die nicht älter als 180 Tage ist.“ Soll: 100 Prozent der Gäste. Prüfmethode: automatisch über einen Bericht der Zugriffsüberprüfungen, ergänzt durch eine manuelle Stichprobe von zehn Gästen. Verantwortlicher: Governance Lead (Auswertung), Teambesitzer (Bestätigung). Prüfintervall: vierteljährlich. Eine gute Antwort enthält alle vier Angaben und eine Messgröße, nicht nur eine Absichtserklärung.

## Lösung zu Aufgabe 7

Eine mögliche Lösung: Mit sechs IT-Mitarbeitern und 800 Beschäftigten ist ein föderiertes Modell mit zentralen Leitplanken sinnvoll, weil das Kernteam die Einzelanfragen nicht allein bewältigen kann. Rollen: ein Governance Lead (Teilzeit in der IT), ein Sponsor aus der Geschäftsführung, Service Owner für Teams/SharePoint und Identität, benannte Besitzer in den Fachbereichen, Champions je Abteilung. Prozesse: (1) Teamanfrage mit Namensstandard und zwei Besitzern, (2) Gastfreigabe mit Befristung und Überprüfung, (3) Ausnahmegenehmigung mit Ablaufdatum. Kennzahlen: Anteil der Gruppen mit mindestens zwei Besitzern, Anteil der Gäste mit gültiger Überprüfung, Anzahl der offenen Ausnahmen. Eine Begründung für die Wahl, die Vor- und Nachteile abwägt, ist wichtiger als die konkrete Auswahl.

## Lösung zu Aufgabe 8

Ein möglicher Ansatz:

```powershell
param([double]$WeightBenefit = 1, [double]$WeightRisk = 1)
$backlog = $csv | ConvertFrom-Csv | ForEach-Object {
    $aufwand = 0
    if (-not [int]::TryParse($_.Aufwand, [ref]$aufwand) -or $aufwand -le 0) {
        Write-Warning "Massnahme '$($_.Massnahme)': Aufwand muss eine Zahl groesser 0 sein."
        return    # Zeile ueberspringen
    }
    $score = ($WeightBenefit * [int]$_.Nutzen + $WeightRisk * [int]$_.Risiko) / $aufwand
    $_ | Add-Member -NotePropertyName Prioritaet -NotePropertyValue ([math]::Round($score,2)) -PassThru
}
```

`TryParse` wandelt Text sicher in eine Zahl um und liefert bei Misserfolg `false`, statt eine Ausnahme auszulösen. Mit `return` innerhalb von `ForEach-Object` wird nur die aktuelle Zeile verlassen, nicht das ganze Skript. Die Gewichte gehen als Faktoren in die Formel ein. Mit `-WeightRisk 2` bevorzugt man Maßnahmen, die Risiken senken.

> **Lauffähige Fassung:** [`loesungen-skripte/New-GovernanceBacklog.aufgabe-8.ps1`](loesungen-skripte/New-GovernanceBacklog.aufgabe-8.ps1) (Listing 8 mit eingesetztem Ausschnitt; offline getestet).
