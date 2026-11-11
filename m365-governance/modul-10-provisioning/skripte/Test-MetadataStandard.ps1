# Quelle: Skript „M365 Governance“, Modul 10, Listing 125 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All `
    -Property Id,DisplayName,Description,Visibility,CreatedDateTime
if (-not $gruppen) { Write-Host "Keine Microsoft-365-Gruppen gefunden."; return }

$muster = '^(PRJ|ABT|GRM|KND)-[A-Z]{2,5}-'
$befunde = foreach ($g in $gruppen) {
    $probleme = @()
    if ($g.DisplayName -notmatch $muster)                         { $probleme += "Name entspricht nicht der Konvention" }
    if ([string]::IsNullOrWhiteSpace($g.Description))             { $probleme += "Beschreibung fehlt" }
    $besitzer = @(Get-MgGroupOwner -GroupId $g.Id)
    if ($besitzer.Count -lt 2)                                    { $probleme += "weniger als zwei Besitzer ($($besitzer.Count))" }
    if ($probleme) {
        [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $g.Id; Befund = ($probleme -join "; ") }
    }
}

$gesamt = @($gruppen).Count
$konform = $gesamt - @($befunde).Count
"{0} von {1} Gruppen konform ({2:P0})" -f $konform, $gesamt, ($konform / $gesamt)
$befunde | Sort-Object Gruppe | Export-Csv -Path ".\metadaten-befunde.csv" -NoTypeInformation -Encoding UTF8
