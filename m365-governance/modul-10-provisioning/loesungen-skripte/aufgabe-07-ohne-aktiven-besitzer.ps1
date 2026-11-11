# Quelle: Skript „M365 Governance“, Modul 10, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName
$befunde = foreach ($g in $gruppen) {
    $aktiv = @(Get-MgGroupOwner -GroupId $g.Id | ForEach-Object {
        $u = Get-MgUser -UserId $_.Id -Property AccountEnabled,Department -ErrorAction SilentlyContinue
        if ($u -and $u.AccountEnabled) { $u }
    })
    if ($aktiv.Count -eq 0) {
        $abt = "unbekannt"
        $m = @(Get-MgGroupMember -GroupId $g.Id -Top 1)
        if ($m) {
            $mu = Get-MgUser -UserId $m[0].Id -Property Department -ErrorAction SilentlyContinue
            if ($mu.Department) { $abt = $mu.Department }
        }
        [pscustomobject]@{ Abteilung = $abt; Gruppe = $g.DisplayName; Id = $g.Id }
    }
}
$befunde | Group-Object Abteilung | ForEach-Object {
    $_.Group | Export-Csv -Path (".\ohne-aktiven-besitzer-{0}.csv" -f $_.Name) -NoTypeInformation -Encoding UTF8
}
