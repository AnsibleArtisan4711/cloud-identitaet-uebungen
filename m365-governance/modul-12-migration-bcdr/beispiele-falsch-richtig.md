# Falsch und richtig – Modul 12

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 152: Befunde bewerten

```text
# FALSCH: nur Liste ausgeben, keine Einordnung
$gruppenOhneBesitzer | Format-Table

# RICHTIG: Befund mit Risiko, Aufwand und Verantwortlichem einordnen
$gruppenOhneBesitzer | Select-Object DisplayName,
    @{n="Risiko";e={ if ($_.Visibility -eq "Public") {"hoch"} else {"mittel"} }},
    @{n="Aufwand";e={"gering"}},
    @{n="Verantwortlich";e={"Teams-Betrieb"}} |
    Export-Csv -Path .\befunde.csv -NoTypeInformation -Encoding UTF8
```

## Listing 154: Nachweis verlangen

```text
# FALSCH: Einstufung ohne Beleg akzeptieren
$bewertung = [pscustomobject]@{ Bereich = "Identitaet"; Ist = 4 }

# RICHTIG: Beleg zur Einstufung verlangen
$bewertung = [pscustomobject]@{ Bereich = "Identitaet"; Ist = 4; Beleg = "Zugriffsueberpruefung 2026-Q3, Bericht liegt im Repository" }
if (-not $bewertung.Beleg) { throw "Einstufung ohne Beleg nicht zulaessig." }
```

## Listing 156: Preise nicht fest einbauen

```text
# FALSCH: Preis im Skript, veraltet nach der naechsten Vertragsaenderung
$kosten = $gb * 0.20

# RICHTIG: Preis als Parameter oder Konfigurationswert mit Datum
$konfig = Get-Content .\preise.json -Raw -Encoding UTF8 | ConvertFrom-Json
if ([datetime]$konfig.gueltigBis -lt (Get-Date)) { Write-Warning "Preisliste abgelaufen: $($konfig.gueltigBis)" }
$kosten = $gb * [decimal]$konfig.speicherProGBMonat
```

## Listing 158: Kleine Gruppen schuetzen

```text
# FALSCH: Abteilungswerte auch bei 1-2 Personen veroeffentlichen
$ergebnis | Format-Table

# RICHTIG: Gruppen unter einer Mindestgroesse zusammenfassen
$mindest = 5
$ergebnis | Where-Object { $_.Benutzer -ge $mindest } | Format-Table
$klein = @($ergebnis | Where-Object { $_.Benutzer -lt $mindest })
if ($klein.Count -gt 0) { "Zusammengefasst: {0} Abteilungen mit weniger als {1} Personen." -f $klein.Count, $mindest }
```

## Listing 160: Wirkung messen

```text
# FALSCH: Erfolg des Programms nur an der Zahl der Champions messen
"Wir haben 25 Champions."

# RICHTIG: Wirkung in den betreuten Bereichen vergleichen
# Beispiel: Anteil aktiver Teams-Nutzer mit/ohne Champion in der Abteilung
$mitChampion  = $ergebnis | Where-Object { $_.Abteilung -in $championAbteilungen }
$ohneChampion = $ergebnis | Where-Object { $_.Abteilung -notin $championAbteilungen }
"mit: {0}, ohne: {1}" -f $mitChampion.Count, $ohneChampion.Count
```

## Listing 162: Notfallzugang pruefen

```text
# FALSCH: Break-Glass-Konto existiert, wurde aber nie getestet
Get-MgUser -Filter "startswith(displayName,'BreakGlass')" | Select-Object DisplayName
# RICHTIG: letzte Anmeldung pruefen (muss bewusst und selten, aber nachweisbar sein)
Get-MgUser -Filter "startswith(displayName,'BreakGlass')" -Property DisplayName,SignInActivity |
    Select-Object DisplayName, @{n="LetzteAnmeldung";e={$_.SignInActivity.LastSignInDateTime}}
# Pruefregel: Anmeldung im letzten Halbjahr als Uebungsnachweis dokumentieren
```

## Listing 164: Wirkung pruefen

```text
# FALSCH: Massnahme umsetzen und als erledigt abhaken
$eintrag.Status = "erledigt"

# RICHTIG: Wirkung nach festem Zeitraum gegen Ausgangswert pruefen
$eintrag | Add-Member -NotePropertyName Ausgangswert -NotePropertyValue 62 -Force
$eintrag | Add-Member -NotePropertyName PruefungAm -NotePropertyValue (Get-Date).AddDays(60).ToString("yyyy-MM-dd") -Force
$eintrag.Status = "umgesetzt - Wirkung offen"
```

## Listing 167: Abhaengigkeit pruefen

```text
# FALSCH: Aufgabe mit Abhaengigkeit einfach einplanen
$aufgabe = @{ id = "B2"; von = 40; nach = @("B1") }       # B1 endet erst an Tag 45

# RICHTIG: Beginn aus dem spaetesten Vorgaengerende ableiten
$fruehesterStart = ($aufgabe.nach | ForEach-Object { $ids[$_].bis } | Measure-Object -Maximum).Maximum + 1
if ($aufgabe.von -lt $fruehesterStart) { "B2 kann fruehestens an Tag $fruehesterStart beginnen." }
```
