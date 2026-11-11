# Falsch und richtig – Modul 09

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 99: Spalten pruefen

```text
# FALSCH: blind auf eine Spalte zugreifen
Import-Csv .\ActiveUserDetail.csv | Where-Object { -not $_.'Teams Last Activity Date' }

# RICHTIG: erst pruefen, ob die Spalte existiert
$z = Import-Csv .\ActiveUserDetail.csv
if ('Teams Last Activity Date' -notin $z[0].PSObject.Properties.Name) { throw "Spalte fehlt" }
$z | Where-Object { -not $_.'Teams Last Activity Date' }
```

## Listing 101: Zweck begrenzen

```text
# FALSCH: Aktivitaet je Person als Rangliste veroeffentlichen
Import-Csv .\ActiveUserDetail.csv | Sort-Object 'Teams Last Activity Date' | Select-Object -First 20

# RICHTIG: aggregierte Zahlen je Dienst, ohne Personenbezug
$z = Import-Csv .\ActiveUserDetail.csv
"Teams-aktiv: {0} von {1}" -f @($z | Where-Object 'Teams Last Activity Date').Count, @($z).Count
```

## Listing 103: Trefferzahl pruefen

```text
# FALSCH: Anzahl ausgeben, ohne die Grenze zu bedenken
(Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date)).Count

# RICHTIG: Zeitraum eingrenzen, ResultSize setzen, Grenze pruefen
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date) -ResultSize 5000
if (@($r).Count -ge 5000) { Write-Warning "Grenze erreicht" }
```

## Listing 105: nach Schweregrad auswerten

```text
# FALSCH: ein Mittelwert fuer alles
($vorfaelle | ForEach-Object { ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours } |
   Measure-Object -Average).Average

# RICHTIG: je Schweregrad
$vorfaelle | Group-Object Severity | ForEach-Object {
  [pscustomobject]@{ Schweregrad = $_.Name; Anzahl = $_.Count
    MittelStd = [math]::Round(($_.Group | ForEach-Object {
        ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours } | Measure-Object -Average).Average, 1) }
}
```

## Listing 110: Frist im Blick

```text
# FALSCH: Nachrichten nur zaehlen
(Get-MgServiceAnnouncementMessage -All).Count

# RICHTIG: Nachrichten mit Frist und Handlungsbedarf anzeigen
Get-MgServiceAnnouncementMessage -All |
  Where-Object { $_.ActionRequiredByDateTime -and $_.ActionRequiredByDateTime -gt (Get-Date) } |
  Sort-Object ActionRequiredByDateTime |
  Select-Object Id, Title, ActionRequiredByDateTime
```

## Listing 112: Zugangsdaten im Runbook

```text
# FALSCH (im Runbook): Kennwort steht im Text
#   Schritt 3: Melden Sie sich mit admin@contoso.com und dem Kennwort "Sommer2026!" an.

# RICHTIG: auf den Tresor verweisen, Zugriff protokolliert
#   Schritt 3: Holen Sie die Zugangsdaten des Notfallkontos aus dem Passwort-Tresor
#   (Eintrag "M365 Notfallkonto 1"). Der Zugriff wird protokolliert; melden Sie die Nutzung an security@contoso.com.
```

## Listing 115: Bewertung statt Zahl

```text
# FALSCH: nur den Rohwert melden
"MFA-Abdeckung: 94 Prozent"

# RICHTIG: Wert mit Ziel, Schwelle, Status und Verantwortlichem
.\Get-KpiStatus.ps1 -Definition .\kpi-definition.json -Werte @{ 'mfa-abdeckung' = 94 }
# Ergebnis: 94 / Ziel 98 / Alarm 90 -> gelb, Verantwortlich: Identity-Team
```
