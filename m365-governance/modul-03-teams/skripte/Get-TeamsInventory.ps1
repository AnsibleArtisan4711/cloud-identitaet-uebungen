# Quelle: Skript „M365 Governance“, Modul 03, Listing 18 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All" -NoWelcome

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
         -Property Id,DisplayName,Visibility,CreatedDateTime,RenewedDateTime

$report = foreach ($t in $teams) {
    $owners  = @(Get-MgGroupOwner  -GroupId $t.Id -All)
    $members = @(Get-MgGroupMember -GroupId $t.Id -All)
    $guests  = @($members | Where-Object {
                   $_.AdditionalProperties.userType -eq 'Guest' })
    [pscustomobject]@{
        Team       = $t.DisplayName
        Sichtbar   = $t.Visibility
        Erstellt   = $t.CreatedDateTime
        Verlaengert= $t.RenewedDateTime
        Besitzer   = $owners.Count
        Mitglieder = $members.Count
        Gaeste     = $guests.Count
    }
}
$report | Sort-Object Besitzer, Erstellt | Export-Csv ".\teams-bestand.csv" -NoTypeInformation -Encoding UTF8
$report | Where-Object { $_.Besitzer -lt 2 } | Format-Table -AutoSize
