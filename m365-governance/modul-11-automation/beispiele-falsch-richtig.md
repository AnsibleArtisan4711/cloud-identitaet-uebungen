# Falsch und richtig – Modul 11

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 135: Seiten und Felder

```text
# FALSCH: nur erste Seite, alle Felder, Betaendpunkt
$g = (Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/groups").value

# RICHTIG: alle Seiten, nur benoetigte Felder, stabile Version
$g = Get-GraphAll -Uri "https://graph.microsoft.com/v1.0/groups?`$select=id,displayName&`$top=100"
```

## Listing 137: Aenderungen absichern

```text
# FALSCH: direkt aendern, Fehler unterdruecken, kein Protokoll
Get-MgGroup -All | ForEach-Object { Update-MgGroup -GroupId $_.Id -Description "x" -ErrorAction SilentlyContinue }

# RICHTIG: WhatIf-faehig, Fehler sichtbar, Ergebnis protokolliert
.\Set-MissingGroupDescription.ps1 -Standardtext "Bitte Zweck ergaenzen" -WhatIf
# Ergebnis im Protokoll pruefen, dann erst ohne -WhatIf ausfuehren
```

## Listing 139: Stabiler Export

```text
# FALSCH: ganzes Objekt mit Zeitstempeln, Reihenfolge zufaellig
Get-TransportRule | ConvertTo-Json -Depth 5 | Set-Content regeln.json

# RICHTIG: sortiert, nur relevante Felder, in festes Verzeichnis
Get-TransportRule | Sort-Object Name | Select-Object Name, Priority, State, Mode, Comments |
    ConvertTo-Json -Depth 5 | Set-Content -Path .\config-export\transportregeln.json -Encoding UTF8
```

## Listing 142: Werte aus Datei

```text
# FALSCH: Grenzwert im Skript, drei Skripte, drei verschiedene Werte
$mindestBesitzer = 2      # in einem anderen Skript steht 1

# RICHTIG: eine Quelle fuer alle Skripte
$standards = Get-Content .\standards.json -Raw -Encoding UTF8 | ConvertFrom-Json
$mindestBesitzer = $standards.gruppen.mindestBesitzer
```

## Listing 144: Vergleich

```text
# FALSCH: ganze Dateien als Text vergleichen - jeder Zeitstempel meldet Drift
if ((Get-Content soll.json -Raw) -ne (Get-Content ist.json -Raw)) { "Drift!" }

# RICHTIG: feldweise vergleichen, flüchtige Felder ausnehmen
.\Compare-ConfigDrift.ps1 -Baseline .\soll\transportregeln.json -Ist .\ist\transportregeln.json `
    -Schluessel Name -Ignorieren @("WhenChanged")
```

## Listing 146: Freigabe erzwingen

```text
# FALSCH: Aenderung ausfuehren, Ticketnummer nur zur Dokumentation
Set-MgGroup -GroupId $id -Description "neu"        # Ticket: CHG0001234 (steht im Kommentar)

# RICHTIG: Freigabe pruefen, dann aendern, dann Ergebnis ins Ticket schreiben
$c = Assert-ChangeApproved -Nummer "CHG0001234"
Update-MgGroup -GroupId $id -Description "neu"
Invoke-Itsm -Methode POST -Pfad "/changes/CHG0001234/notes" -Body @{ text = "Beschreibung gesetzt, Lauf erfolgreich." }
```

## Listing 148: Anmeldung

```text
# FALSCH: Geheimnis im Skript
$geheimnis = "abc~123SuperGeheim"
Connect-MgGraph -ClientSecretCredential (New-Object PSCredential($clientId, (ConvertTo-SecureString $geheimnis -AsPlainText -Force))) -TenantId $tenantId

# RICHTIG: Zertifikat aus Zertifikatspeicher oder verwaltete Identitaet
Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $env:GRAPH_CERT_THUMBPRINT -NoWelcome
# in Azure Automation / Azure-VM:
# Connect-MgGraph -Identity -NoWelcome
```

## Listing 150: Pruefen und zuruecksetzen

```text
# FALSCH: Aenderung ohne Sicherung, Erfolg angenommen
Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays 30
"Fertig."

# RICHTIG: sichern, aendern, Zielwert pruefen, Rueckweg bereit
$alt = Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id | Select-Object -ExpandProperty GroupLifetimeInDays
Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays 365
if ((Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id).GroupLifetimeInDays -ne 365) {
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $id -GroupLifetimeInDays $alt
}
```
