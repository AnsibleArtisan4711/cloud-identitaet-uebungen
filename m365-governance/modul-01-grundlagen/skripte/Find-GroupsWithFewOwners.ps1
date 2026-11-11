# Quelle: Skript „M365 Governance“, Modul 01, Listing 2 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [int]$MinOwners = 2,
    [string]$OutFile = ".\gruppen-ohne-ausreichend-besitzer.csv"
)

Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$groups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
          -Property Id,DisplayName,CreatedDateTime

$result = foreach ($g in $groups) {
    $owners = @(Get-MgGroupOwner -GroupId $g.Id -All)
    if ($owners.Count -lt $MinOwners) {
        [pscustomobject]@{
            Gruppe      = $g.DisplayName
            GruppenId   = $g.Id
            Besitzer    = $owners.Count
            Erstellt    = $g.CreatedDateTime
        }
    }
}

$result | Sort-Object Besitzer, Gruppe | Export-Csv $OutFile -NoTypeInformation -Encoding UTF8
Write-Host ("{0} von {1} Gruppen haben weniger als {2} Besitzer." -f @($result).Count, @($groups).Count, $MinOwners)
