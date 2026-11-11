# Quelle: Skript „M365 Governance“, Modul 01, Listing 9 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

$groups = Get-MgGroup -All -Property Id,DisplayName,GroupTypes,SecurityEnabled,MailEnabled,MembershipRule

$typed = $groups | ForEach-Object {
    $typ = if ($_.GroupTypes -contains "Unified") { "Microsoft 365" }
           elseif ($_.SecurityEnabled -and -not $_.MailEnabled) { "Sicherheitsgruppe" }
           elseif ($_.MailEnabled -and -not $_.SecurityEnabled) { "Verteiler" }
           else { "Sonstige" }
    $dyn = [bool]$_.MembershipRule
    [pscustomobject]@{ Typ = $typ; Dynamisch = $dyn }
}

$lines = @("| Typ | Dynamisch | Anzahl |", "|---|---|---|")
$typed | Group-Object Typ, Dynamisch | Sort-Object Name | ForEach-Object {
    $lines += "| {0} | {1} | {2} |" -f $_.Group[0].Typ, $_.Group[0].Dynamisch, $_.Count
}
$lines | Set-Content ".\ist-architektur-gruppen.md" -Encoding UTF8
$lines
