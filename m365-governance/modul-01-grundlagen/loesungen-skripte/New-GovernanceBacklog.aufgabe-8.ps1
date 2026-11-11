# Zusammengesetzt aus Listing 8 und dem Codeausschnitt der Lösung zu Aufgabe 8 (Skript, Modul 01). Die Zusammensetzung stammt aus diesem Repository, nicht aus dem Skript.
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([double]$WeightBenefit = 1, [double]$WeightRisk = 1)

$csv = @"
Massnahme,Nutzen,Risiko,Aufwand,Welle
Notfallzugriffskonten einrichten und testen,4,5,1,1
Besitzerpflicht fuer alle Gruppen durchsetzen,4,3,2,1
Namensrichtlinie aktivieren,2,1,1,1
Gaeste-Rezertifizierung einfuehren,4,4,3,2
Vertraulichkeitsbezeichnungen ausrollen,5,4,5,3
Provisioning-Prozess automatisieren,4,2,5,3
"@

$backlog = $csv | ConvertFrom-Csv | ForEach-Object {
    $aufwand = 0
    if (-not [int]::TryParse($_.Aufwand, [ref]$aufwand) -or $aufwand -le 0) {
        Write-Warning "Massnahme '$($_.Massnahme)': Aufwand muss eine Zahl groesser 0 sein."
        return    # Zeile ueberspringen
    }
    $score = ($WeightBenefit * [int]$_.Nutzen + $WeightRisk * [int]$_.Risiko) / $aufwand
    $_ | Add-Member -NotePropertyName Prioritaet -NotePropertyValue ([math]::Round($score,2)) -PassThru
}

$backlog | Sort-Object Welle, @{Expression='Prioritaet';Descending=$true} |
    Format-Table Welle, Prioritaet, Nutzen, Risiko, Aufwand, Massnahme -AutoSize
