# Quelle: Skript „M365 Governance“, Modul 11, Listing 134 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
function Get-GraphAll {
    param([Parameter(Mandatory)][string]$Uri)
    $ergebnis = New-Object System.Collections.Generic.List[object]
    while ($Uri) {
        $antwort = Invoke-MgGraphRequest -Method GET -Uri $Uri
        if ($antwort.value) { $ergebnis.AddRange([object[]]$antwort.value) }
        $Uri = $antwort.'@odata.nextLink'
    }
    $ergebnis
}

function Get-GraphBatch {
    param([Parameter(Mandatory)][string[]]$Pfade)   # relative Pfade, z. B. /groups/<id>/owners
    $ergebnis = @{}
    for ($i = 0; $i -lt $Pfade.Count; $i += 20) {
        $teil = $Pfade[$i..([math]::Min($i + 19, $Pfade.Count - 1))]
        $anfragen = for ($j = 0; $j -lt $teil.Count; $j++) {
            @{ id = [string]($i + $j); method = "GET"; url = $teil[$j] }
        }
        $body = @{ requests = @($anfragen) } | ConvertTo-Json -Depth 5
        $antwort = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/`$batch" `
                       -Body $body -ContentType "application/json"
        foreach ($a in $antwort.responses) {
            $ergebnis[$Pfade[[int]$a.id]] = $a
        }
    }
    $ergebnis
}

Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
$gruppen = Get-GraphAll -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=groupTypes/any(c:c eq 'Unified')&`$select=id,displayName,createdDateTime&`$top=100"
"{0} Gruppen gelesen." -f $gruppen.Count

$pfade = $gruppen | Select-Object -First 40 | ForEach-Object { "/groups/$($_.id)/owners?`$select=id" }
$besitzer = Get-GraphBatch -Pfade $pfade
$gedrosselt = @($besitzer.Values | Where-Object { $_.status -eq 429 }).Count
"{0} Stapelantworten, davon {1} gedrosselt." -f $besitzer.Count, $gedrosselt
