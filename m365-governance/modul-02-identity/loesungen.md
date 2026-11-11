# Lösungen – Modul 02: Identity Governance und Zugriffskontrolle

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Die drei Lebenszyklen sind der Identitätslebenszyklus (Eintritt, Wechsel, Austritt; Werkzeug: Lifecycle Workflows), der Zugriffslebenszyklus (Zugriffspakete und Zugriffsüberprüfungen) und der Lebenszyklus privilegierter Zugriffe (Privileged Identity Management). Wichtig ist die Unterscheidung: Der erste regelt, wer zur Organisation gehört, der zweite, worauf er zugreift, der dritte, wer verwalten darf.

## Lösung zu Aufgabe 2

Eine berechtigte Zuweisung erlaubt es der Person, die Rolle bei Bedarf zu aktivieren, sie ist aber nicht wirksam. Eine aktive Zuweisung ist dauerhaft oder zeitlich begrenzt wirksam. PIM erzwingt bei der Aktivierung Maßnahmen wie Mehrstufen-Authentifizierung und Begründung, und die Aktivierung läuft nach der eingestellten Dauer von selbst ab. Dadurch bestehen Rechte nur während des tatsächlichen Bedarfs.

## Lösung zu Aufgabe 3

Mindestens nötig sind: ein Bereich (wer ist betroffen, zum Beispiel eine Abteilung), ein zeitbasierter Auslöser auf einem Benutzerattribut (zum Beispiel `employeeHireDate` mit einem Versatz), eine Liste von Aufgaben (Konto aktivieren, Willkommens-E-Mail senden) und gepflegte Benutzerdaten. Ohne ein Eintrittsdatum am Benutzerobjekt läuft der Workflow nicht, auch wenn er korrekt konfiguriert ist.

## Lösung zu Aufgabe 4

Im Katalog des Projekts legt man ein Zugriffspaket an, das das Team und die Website enthält (jeweils mit Rolle Mitglied beziehungsweise Besucher). Die Richtlinie lässt Benutzer aus einer verbundenen Organisation oder bestimmte externe Verzeichnisse anfordern, verlangt Genehmigung durch den Projektleiter, setzt den Ablauf auf 90 Tage und aktiviert, dass das Gastkonto nach Ablauf des letzten Zugriffs automatisch entfernt wird. Optional folgt eine Zugriffsüberprüfung nach 60 Tagen. Der Projektleiter wird als Katalogbesitzer delegiert und kann Ressourcen nur hinzufügen, die er selbst besitzt.

## Lösung zu Aufgabe 5

Prüfer sollten unabhängige Personen sein, etwa die Sicherheitsbeauftragte und die IT-Leitung, nicht die Administratoren selbst. Der Rhythmus ist vierteljährlich oder bei kleiner Gruppe monatlich. Standardentscheidung bei fehlender Reaktion ist „Zugriff entziehen“, weil eine nicht bestätigte Dauerberechtigung ein Risiko darstellt. Ergebnisse werden automatisch angewendet, mit verpflichtender Begründung. Wichtig: Notfallkonten werden in die Überprüfung einbezogen oder bewusst dokumentiert ausgenommen.

## Lösung zu Aufgabe 6

Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,CreatedDateTime |
  ForEach-Object {
    $n = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($n -lt 2) {
      [pscustomobject]@{ Name = $_.DisplayName; AnzahlBesitzer = $n; Erstellt = $_.CreatedDateTime }
    }
  } | Export-Csv ".\gruppen-ohne-besitzer.csv" -NoTypeInformation -Encoding UTF8
```

Das Skript filtert auf Microsoft-365-Gruppen, zählt die Besitzer je Gruppe und schreibt nur die Gruppen mit weniger als zwei Besitzern in die CSV-Datei. Das Einpacken mit `@(...)` stellt sicher, dass auch bei null oder einem Besitzer eine Anzahl bestimmt werden kann.

> **Als Datei:** [`loesungen-skripte/aufgabe-06-gruppen-ohne-besitzer.ps1`](loesungen-skripte/aufgabe-06-gruppen-ohne-besitzer.ps1) (offline getestet)

## Lösung zu Aufgabe 7

Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
$g = Get-MgUser -Filter "userType eq 'Guest'" -All `
     -Property Id,DisplayName,Mail,CreatedDateTime,ExternalUserState,SignInActivity
$inaktiv = $g | Where-Object {
  $_.ExternalUserState -ne 'PendingAcceptance' -and
  ( -not $_.SignInActivity.LastSuccessfulSignInDateTime -or
    $_.SignInActivity.LastSuccessfulSignInDateTime -lt (Get-Date).AddDays(-120) ) }
$offen = $g | Where-Object {
  $_.ExternalUserState -eq 'PendingAcceptance' -and
  $_.CreatedDateTime -lt (Get-Date).AddDays(-45) }
"--- Inaktiv (>120 Tage) ---"; $inaktiv | Select-Object DisplayName, Mail
"--- Einladung offen (>45 Tage) ---"; $offen | Select-Object DisplayName, Mail, CreatedDateTime
```

Die beiden Kategorien werden getrennt gefiltert, damit offene Einladungen nicht als inaktive Gäste doppelt erscheinen. Gäste mit offener Einladung haben naturgemäß keine Anmeldung.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-gaeste-pruefen.ps1`](loesungen-skripte/aufgabe-07-gaeste-pruefen.ps1) (offline getestet)

## Lösung zu Aufgabe 8

Vorgehen: Zuerst klären, ob sich etwas geändert hat (Überwachungsprotokoll nach Änderungen an Verzeichniseinstellungen in den letzten 24 Stunden filtern). Mögliche Ursachen: Erstens wurde die Einschränkung der Gruppenerstellung auf eine Sicherheitsgruppe aktiviert; Administratorrollen sind ausgenommen, was erklärt, warum zwei Administratoren weiterhin können (Verzeichniseinstellung `Group.Unified` prüfen). Zweitens ist die Änderung noch nicht überall wirksam oder umgekehrt erst jetzt angekommen, da sie mindestens 30 Minuten braucht. Drittens könnte eine Namensrichtlinie oder eine gesperrte Wortliste neue Teams ablehnen (Fehlermeldung des Anlegens ansehen). Viertens könnte eine Teams-Richtlinie oder eine Lizenzänderung die Erstellung verhindern. Das Ergebnis wird im Ticket dokumentiert und die Ursache im Betriebshandbuch ergänzt.
