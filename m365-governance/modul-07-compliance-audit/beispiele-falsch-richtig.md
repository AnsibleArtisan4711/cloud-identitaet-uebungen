# Falsch und richtig – Modul 07

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 67: Grenze und Zeitraum

```text
# FALSCH: zu grosser Zeitraum, einmalige Abfrage, Grenze unbemerkt
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date)

# RICHTIG: eingrenzen, UTC, Seitenabfrage fuer grosse Mengen
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-2).ToUniversalTime() `
    -EndDate (Get-Date).ToUniversalTime() -UserIds "anna@contoso.com" `
    -Operations FileDeleted -ResultSize 5000 -SessionId "s1" -SessionCommand ReturnLargeSet
```

## Listing 69: Suchumfang

```text
# FALSCH: alles, ohne Zeitraum, ohne Fall
New-ComplianceSearch -Name "Alles" -ExchangeLocation All -ContentMatchQuery "Vertrag"

# RICHTIG: eng, mit Zeitraum, im Fall, nur die betroffene Person
New-ComplianceSearch -Name "F-2026-14 Suche 1" -Case "F-2026-14" `
    -ExchangeLocation "anna@contoso.com" `
    -ContentMatchQuery "(Vertrag) AND (Date>=2026-01-01) AND (Date<=2026-06-30)"
```

## Listing 71: Datei lesen

```text
# FALSCH: Spaltennamen geraten, keine Pruefung
Import-Csv .\export.csv | Group-Object Status

# RICHTIG: pruefen, ob die Spalte existiert, sonst klar abbrechen
$z = Import-Csv .\export.csv
if ("Status" -notin $z[0].PSObject.Properties.Name) { throw "Spalte Status fehlt" }
$z | Group-Object Status
```

## Listing 73: Datenminimierung

```text
# FALSCH: gesamten Personalexport weitergeben
Copy-Item .\Personalexport.csv .\HR-Konnektor.csv

# RICHTIG: nur benoetigte Spalten, gepruefte Daten
Import-Csv .\Personalexport.csv -Delimiter ';' |
  Select-Object @{n='UserPrincipalName';e={$_.UPN}},
                @{n='ResignationDate';e={([datetime]$_.Kuendigung).ToString('yyyy-MM-dd')}},
                @{n='LastWorkingDate';e={([datetime]$_.LetzterTag).ToString('yyyy-MM-dd')}} |
  Export-Csv .\HR-Konnektor.csv -NoTypeInformation -Encoding UTF8
```

## Listing 75: Trennung der Aufgaben

```text
# FALSCH: eine Person in Admin- und Pruefergruppe
Add-RoleGroupMember -Identity "Communication Compliance Admins" -Member "anna@contoso.com"
Add-RoleGroupMember -Identity "Communication Compliance Investigators" -Member "anna@contoso.com"

# RICHTIG: getrennte Personen, Pruefer aus Recht/Personal
Add-RoleGroupMember -Identity "Communication Compliance Admins" -Member "it.admin@contoso.com"
Add-RoleGroupMember -Identity "Communication Compliance Investigators" -Member "recht@contoso.com"
```

## Listing 77: Umfang und Pruefung

```text
# FALSCH: nur Postfach, Status nie geprueft
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -ExchangeLocation "anna@contoso.com"

# RICHTIG: alle relevanten Orte, danach Verteilungsstatus lesen
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -Enabled $true `
    -ExchangeLocation "anna@contoso.com" `
    -SharePointLocation "https://contoso-my.sharepoint.com/personal/anna_contoso_com"
Get-CaseHoldPolicy "Sperre" -DistributionDetail | Select-Object Name, DistributionStatus
```

## Listing 79: Luecken sichtbar machen

```text
# FALSCH: nur zaehlen, was "erledigt" ist
($z | Where-Object Status -eq "erledigt").Count

# RICHTIG: Luecken mit Grund auflisten
$z | Where-Object { -not $_.Nachweis -or -not $_.Verantwortlich } |
    Select-Object Anforderung, Massnahme
```

## Listing 81: Reihenfolge

```text
# FALSCH: erst suchen und aufraeumen, Hold "spaeter"
Start-ComplianceSearch -Identity "Suche 1"
# ... Benutzer loescht in der Zwischenzeit ...

# RICHTIG: erst sichern, dann suchen
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -ExchangeLocation "anna@contoso.com" -Enabled $true
New-CaseHoldRule -Name "Sperre Regel" -Policy "Sperre"
Start-ComplianceSearch -Identity "Suche 1"
```
