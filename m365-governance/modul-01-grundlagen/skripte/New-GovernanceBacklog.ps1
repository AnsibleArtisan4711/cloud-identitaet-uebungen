# Quelle: Skript „M365 Governance“, Modul 01, Listing 8 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
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
    $score = ([int]$_.Nutzen + [int]$_.Risiko) / [int]$_.Aufwand
    $_ | Add-Member -NotePropertyName Prioritaet -NotePropertyValue ([math]::Round($score,2)) -PassThru
}

$backlog | Sort-Object Welle, @{Expression='Prioritaet';Descending=$true} |
    Format-Table Welle, Prioritaet, Nutzen, Risiko, Aufwand, Massnahme -AutoSize
