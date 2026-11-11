# Quelle: Skript „M365 Governance“, Modul 12, Listing 151 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Ausgabe = (".\ist-analyse-{0}.md" -f (Get-Date -Format "yyyy-MM-dd")))

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All" -NoWelcome

$benutzer = Get-MgUserCount -ConsistencyLevel eventual
$gaeste   = Get-MgUserCount -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$gruppen  = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName

$ohneBesitzer = 0
foreach ($g in $gruppen) {
    if (@(Get-MgGroupOwner -GroupId $g.Id).Count -eq 0) { $ohneBesitzer++ }
}
$anteil = if ($gruppen.Count -gt 0) { $ohneBesitzer / $gruppen.Count } else { 0 }

$zeilen = @(
    "# Ist-Analyse (Bestand) vom $(Get-Date -Format 'yyyy-MM-dd')",
    "",
    "| Kennzahl | Wert |",
    "|---|---|",
    "| Benutzer | $benutzer |",
    "| Gaeste | $gaeste |",
    "| Microsoft-365-Gruppen | $($gruppen.Count) |",
    ("| Gruppen ohne Besitzer | $ohneBesitzer ({0:P0}) |" -f $anteil)
)
$zeilen | Set-Content -Path $Ausgabe -Encoding UTF8
Get-Content $Ausgabe
