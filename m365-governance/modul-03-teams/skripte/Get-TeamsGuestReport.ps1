# Quelle: Skript „M365 Governance“, Modul 03, Listing 21 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All","User.Read.All" -NoWelcome

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All -Property Id,DisplayName

$zeilen = foreach ($t in $teams) {
    Get-MgGroupMember -GroupId $t.Id -All |
        Where-Object { $_.AdditionalProperties.userType -eq 'Guest' } |
        ForEach-Object {
            [pscustomobject]@{
                Team  = $t.DisplayName
                Gast  = $_.AdditionalProperties.displayName
                Mail  = $_.AdditionalProperties.mail
                GastId= $_.Id
            }
        }
}

"Teams mit Gaesten: {0}" -f ($zeilen | Select-Object -ExpandProperty Team -Unique).Count
$zeilen | Export-Csv ".\teams-gaeste.csv" -NoTypeInformation -Encoding UTF8

"`nGaeste in mehr als 5 Teams:"
$zeilen | Group-Object GastId | Where-Object Count -gt 5 |
    Select-Object Count, @{n='Gast';e={$_.Group[0].Gast}}, @{n='Mail';e={$_.Group[0].Mail}} |
    Sort-Object Count -Descending | Format-Table -AutoSize
