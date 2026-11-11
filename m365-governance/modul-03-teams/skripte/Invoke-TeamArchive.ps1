# Quelle: Skript „M365 Governance“, Modul 03, Listing 24 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$CsvPfad,        # Spalte: TeamId
    [switch]$Ausfuehren                             # ohne Schalter nur Probelauf
)
Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","GroupMember.Read.All" -NoWelcome

foreach ($zeile in Import-Csv $CsvPfad) {
    $id = $zeile.TeamId
    $team = Get-MgTeam -TeamId $id
    $gaeste = @(Get-MgGroupMember -GroupId $id -All |
                Where-Object { $_.AdditionalProperties.userType -eq 'Guest' })

    if ($gaeste.Count -gt 0) {
        Write-Warning "'$($team.DisplayName)': $($gaeste.Count) Gaeste - zuerst bereinigen."
        continue
    }
    if (-not $Ausfuehren) { "PROBELAUF: wuerde archivieren: $($team.DisplayName)"; continue }

    Invoke-MgArchiveTeam -TeamId $id
    "Archivierung angestossen: $($team.DisplayName)"
}
