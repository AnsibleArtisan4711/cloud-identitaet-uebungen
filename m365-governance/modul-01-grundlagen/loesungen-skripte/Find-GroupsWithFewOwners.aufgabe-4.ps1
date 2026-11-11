# Zusammengesetzt aus Listing 2 und dem Codeausschnitt der Lösung zu Aufgabe 4 (Skript, Modul 01). Die Zusammensetzung stammt aus diesem Repository, nicht aus dem Skript.
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [int]$MinOwners = 2,
    [string]$OutFile = ".\gruppen-ohne-ausreichend-besitzer.csv"
)

Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
          -Property Id,DisplayName,CreatedDateTime

$cutoff = (Get-Date).AddDays(-30)
$result = foreach ($g in $groups) {
    if ($g.CreatedDateTime -gt $cutoff) { continue }   # zu neu, ueberspringen
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All)
    if ($owners.Count -lt $MinOwners) {
        [pscustomobject]@{ Gruppe=$g.DisplayName; GruppenId=$g.Id
                           Besitzer=$owners.Count; Erstellt=$g.CreatedDateTime }
    }
}

$result | Sort-Object Besitzer, Gruppe | Export-Csv $OutFile -NoTypeInformation -Encoding UTF8
Write-Host ("{0} von {1} Gruppen haben weniger als {2} Besitzer." -f @($result).Count, @($groups).Count, $MinOwners)
