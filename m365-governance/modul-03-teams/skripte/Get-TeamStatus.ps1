# Quelle: Skript „M365 Governance“, Modul 03, Listing 25 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$TeamName)

Connect-MgGraph -Scopes "Group.Read.All","Team.ReadBasic.All","TeamSettings.Read.All","Channel.ReadBasic.All" -NoWelcome

$gruppe = @(Get-MgGroup -Filter "displayName eq '$TeamName'" `
            -Property Id,DisplayName,Visibility,CreatedDateTime,RenewedDateTime,DeletedDateTime)
if ($gruppe.Count -eq 0) {
    Write-Warning "Keine aktive Gruppe gefunden. Pruefen Sie geloeschte Gruppen (30 Tage Wiederherstellung)."
    return
}
$g = $gruppe[0]
$team = Get-MgTeam -TeamId $g.Id
$owner = @(Get-MgGroupOwner -GroupId $g.Id) | ForEach-Object { $_.AdditionalProperties.userPrincipalName }
$mem   = @(Get-MgGroupMember -GroupId $g.Id -All)
$gast  = @($mem | Where-Object { $_.AdditionalProperties.userType -eq 'Guest' })
$kan   = @(Get-MgTeamChannel -TeamId $g.Id -All)

[pscustomobject]@{
    Name          = $g.DisplayName
    Archiviert    = $team.IsArchived
    Sichtbarkeit  = $g.Visibility
    Besitzer      = ($owner -join '; ')
    Mitglieder    = $mem.Count
    Gaeste        = $gast.Count
    Kanaele       = $kan.Count
    Erstellt      = $g.CreatedDateTime
    Verlaengert   = $g.RenewedDateTime
} | Format-List
