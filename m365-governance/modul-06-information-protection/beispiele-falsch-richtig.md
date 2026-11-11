# Falsch und richtig – Modul 06

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 51: Veroeffentlichung

```text
# FALSCH: Label angelegt, aber nie in einer Richtlinie genannt
New-Label -DisplayName "Vertraulich" -Name "Vertraulich"

# RICHTIG: Label anlegen UND in einer Richtlinie veroeffentlichen
New-Label -DisplayName "Vertraulich" -Name "Vertraulich"
New-LabelPolicy -Name "Standard" -Labels "Vertraulich" -ExchangeLocation All
```

## Listing 53: Schwelle und Modus

```text
# FALSCH: aktiv, Schwelle 1, alles blockieren
New-DlpCompliancePolicy -Name "DLP" -ExchangeLocation All -Mode Enable
New-DlpComplianceRule -Name "R1" -Policy "DLP" `
  -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "1" } `
  -BlockAccess $true

# RICHTIG: Testmodus, sinnvolle Schwelle, zuerst nur Hinweis
New-DlpCompliancePolicy -Name "DLP" -ExchangeLocation All -Mode TestWithNotifications
New-DlpComplianceRule -Name "R1" -Policy "DLP" `
  -ContentContainsSensitiveInformation @{ Name = "International Banking Account Number (IBAN)"; minCount = "5" } `
  -NotifyUser Owner
```

## Listing 55: Teams und Gruppen

```text
# FALSCH: Teams-Kanalnachrichten sollen aufbewahrt werden,
# aber es wurde nur Exchange gewaehlt
New-RetentionCompliancePolicy -Name "Teams" -ExchangeLocation All

# RICHTIG: Teams-Orte ausdruecklich waehlen
New-RetentionCompliancePolicy -Name "Teams" `
    -TeamsChannelLocation All -TeamsChatLocation All
```

## Listing 57: Strengegrad

```text
# FALSCH: regulatorisch ohne Rechtspruefung und ohne Pilot
New-ComplianceTag -Name "Alles" -IsRecordLabel $true -Regulatory $true `
    -RetentionAction Keep -RetentionDuration 3650 -RetentionType CreationAgeInDays

# RICHTIG: zuerst als einfacher Record im Pilot, Regulatory erst nach Freigabe
New-ComplianceTag -Name "Vertrag Pilot" -IsRecordLabel $true -Regulatory $false `
    -RetentionAction Keep -RetentionDuration 3650 -RetentionType CreationAgeInDays
```

## Listing 59: Abfrage

```text
# FALSCH: Schreibweise haengt von jedem Pflegenden ab
New-AdaptiveScope -Name "HR" -LocationType User -RawQuery "Department -eq 'HR'"

# RICHTIG: mehrere gepflegte Schreibweisen erfassen
# und die Pflege des Attributs im Identity-Prozess regeln
New-AdaptiveScope -Name "HR" -LocationType User `
    -RawQuery "Department -eq 'Personal' -or Department -eq 'HR'"
```

## Listing 61: beide Richtungen

```text
# FALSCH: nur eine Richtung
New-InformationBarrierPolicy -Name "Handel-Beratung" `
    -AssignedSegment "Handel" -SegmentsBlocked "Beratung" -State Active

# RICHTIG: beide Richtungen, danach anwenden und Status pruefen
New-InformationBarrierPolicy -Name "Beratung-Handel" `
    -AssignedSegment "Beratung" -SegmentsBlocked "Handel" -State Active
Start-InformationBarrierPoliciesApplication
```

## Listing 63: Inventar vor Scan

```text
# FALSCH: alles scannen lassen, danach Eigentuemer suchen
# (Es gibt keine Liste der Quellen und keine Verantwortlichen.)

# RICHTIG: zuerst Inventar mit Eigentuemer, dann gezielt scannen
Get-SPOSite -Limit All -IncludePersonalSite $false |
    Where-Object { -not $_.Owner } |
    Select-Object Url, Title    # Websites ohne Besitzer zuerst klaeren
```

## Listing 65: Fehlersuche

```text
# FALSCH: Richtlinie loeschen und neu anlegen, "damit es geht"
Remove-DlpCompliancePolicy -Identity "DLP Finanzdaten"
New-DlpCompliancePolicy -Name "DLP Finanzdaten" -ExchangeLocation All -Mode Enable

# RICHTIG: Zustand lesen, Ursache eingrenzen, genau eine Aenderung
Get-DlpCompliancePolicy "DLP Finanzdaten" -DistributionDetail |
    Format-List Name, Mode, ExchangeLocation, DistributionStatus
Get-DlpComplianceRule -Policy "DLP Finanzdaten" |
    Format-List Name, Disabled, BlockAccess, ContentContainsSensitiveInformation
```
