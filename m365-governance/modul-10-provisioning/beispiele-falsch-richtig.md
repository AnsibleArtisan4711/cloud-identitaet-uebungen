# Falsch und richtig – Modul 10

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 117: Aufraeumen bei Fehlern

```text
# FALSCH: Fehler wird verschluckt, die halbfertige Gruppe bleibt zurueck
try { Invoke-MgGraphRequest -Method PUT -Uri $teamUri -Body $body } catch { }

# RICHTIG: bei endgueltigem Fehler die eigene Gruppe wieder entfernen und melden
try {
    Invoke-MgGraphRequest -Method PUT -Uri $teamUri -Body $body -ContentType "application/json"
} catch {
    Remove-MgGroup -GroupId $gruppe.Id
    throw "Provisioning abgebrochen, Gruppe $($gruppe.Id) entfernt: $($_.Exception.Message)"
}
```

## Listing 119: Antrag pruefen

```text
# FALSCH: alles genehmigen lassen, Pflichtfelder nicht pruefen
$stufe = 2

# RICHTIG: Stufe aus Regeln ableiten, bei fehlenden Angaben zurueckweisen
$ergebnis = Test-WorkspaceRequest -Antrag $antrag
if (-not $ergebnis.Gueltig) { $ergebnis.Fehler | ForEach-Object { Write-Warning $_ }; return }
"Genehmigungsstufe: $($ergebnis.Stufe)"
```

## Listing 122: Wiederholbar anlegen

```text
# FALSCH: Kanal immer neu anlegen, zweiter Lauf erzeugt einen Fehler
New-MgTeamChannel -TeamId $TeamId -DisplayName "Planung"

# RICHTIG: erst pruefen, dann anlegen
if ("Planung" -notin (Get-MgTeamChannel -TeamId $TeamId).DisplayName) {
    New-MgTeamChannel -TeamId $TeamId -DisplayName "Planung" | Out-Null
}
```

## Listing 124: Adresse bilden

```text
# FALSCH: Freitext direkt als Nickname
$nick = "Produktlaunch Frühjahr (Vertrieb)"

# RICHTIG: normalisieren und Zeichensatz begrenzen
$nick = ConvertTo-Slug "Produktlaunch Frühjahr (Vertrieb)"   # produktlaunch-fruehjahr-vertrieb
```

## Listing 126: Pflichtangabe pruefen

```text
# FALSCH: nur auf "nicht leer" pruefen, Platzhalter bestehen die Pruefung
if ($g.Description) { "ok" }

# RICHTIG: Platzhalter erkennen und Mindestlaenge verlangen
$platzhalter = "n/a","-","tbd","test","."
if ([string]::IsNullOrWhiteSpace($g.Description) -or $g.Description.Trim().Length -lt 15 -or $g.Description.Trim().ToLower() -in $platzhalter) {
    "Beschreibung unbrauchbar"
}
```

## Listing 128: Einfuehrung

```text
# FALSCH: sofort fuer alle Gruppen, ohne Vorinformation
New-MgGroupLifecyclePolicy -GroupLifetimeInDays 90 -ManagedGroupTypes "All" `
    -AlternateNotificationEmails "niemand@contoso.com"

# RICHTIG: zuerst ausgewaehlte Gruppen, realistische Dauer, gepflegte Ersatzadresse
New-MgGroupLifecyclePolicy -GroupLifetimeInDays 365 -ManagedGroupTypes "Selected" `
    -AlternateNotificationEmails "m365-governance@contoso.com"
```

## Listing 131: Loeschen

```text
# FALSCH: alle inaktiven Gruppen ohne Probelauf und Protokoll loeschen
Get-MgGroup -All | Where-Object { $_.RenewedDateTime -lt (Get-Date).AddDays(-400) } |
    ForEach-Object { Remove-MgGroup -GroupId $_.Id }

# RICHTIG: erst Liste erzeugen, von Besitzern bestaetigen lassen, dann archivieren
Get-MgGroup -All -Property Id,DisplayName,RenewedDateTime |
    Where-Object { $_.RenewedDateTime -lt (Get-Date).AddDays(-400) } |
    Select-Object Id, DisplayName, RenewedDateTime |
    Export-Csv -Path .\kandidaten.csv -NoTypeInformation -Encoding UTF8
# Die CSV geht an die Verantwortlichen; erst die bestaetigte Liste wird verarbeitet.
```

## Listing 133: Fehlerbehandlung

```text
# FALSCH: endlos wiederholen, egal welcher Fehler
while ($true) { try { New-MgGroup @params; break } catch { Start-Sleep 5 } }

# RICHTIG: begrenzt, mit Unterscheidung und mit Antragsnummer im Fehlertext
try {
    Invoke-WithRetry -Aktion { New-MgGroup @params }
} catch {
    Write-Error "Antrag $antragsNr fehlgeschlagen: $($_.Exception.Message)"
}
```
