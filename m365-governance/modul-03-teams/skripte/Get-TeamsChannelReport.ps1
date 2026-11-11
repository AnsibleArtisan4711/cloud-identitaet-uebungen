# Quelle: Skript „M365 Governance“, Modul 03, Listing 22 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Channel.ReadBasic.All","Team.ReadBasic.All" -NoWelcome

$teams = Get-MgTeam -All

$zeilen = foreach ($t in $teams) {
    try {
        $kanaele = Get-MgTeamChannel -TeamId $t.Id -All
        [pscustomobject]@{
            Team          = $t.DisplayName
            Standard      = @($kanaele | Where-Object MembershipType -eq 'standard').Count
            Privat        = @($kanaele | Where-Object MembershipType -eq 'private').Count
            Freigegeben   = @($kanaele | Where-Object MembershipType -eq 'shared').Count
        }
    } catch {
        Write-Warning "Team '$($t.DisplayName)': $($_.Exception.Message.Split("`n")[0])"
    }
}
$zeilen | Where-Object { $_.Privat -gt 0 -or $_.Freigegeben -gt 0 } |
    Sort-Object Privat -Descending | Format-Table -AutoSize
"Summe private Kanaele: {0}, freigegebene Kanaele: {1}" -f
    ($zeilen | Measure-Object Privat -Sum).Sum, ($zeilen | Measure-Object Freigegeben -Sum).Sum
