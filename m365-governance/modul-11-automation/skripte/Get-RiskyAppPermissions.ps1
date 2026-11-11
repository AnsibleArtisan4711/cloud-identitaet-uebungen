# Quelle: Skript „M365 Governance“, Modul 11, Listing 147 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Application.Read.All" -NoWelcome

$graphAppId = "00000003-0000-0000-c000-000000000000"      # Microsoft Graph
$graphSp = Get-MgServicePrincipal -Filter "appId eq '$graphAppId'"
$rollen = @{}
foreach ($r in $graphSp.AppRoles) { $rollen[$r.Id] = $r.Value }

$ergebnis = foreach ($sp in Get-MgServicePrincipal -All -Property Id,DisplayName,AppId) {
    $zuweisungen = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue |
        Where-Object { $_.ResourceId -eq $graphSp.Id }
    foreach ($z in $zuweisungen) {
        $name = $rollen[$z.AppRoleId]
        if ($name -like "*ReadWrite.All") {
            [pscustomobject]@{ Anwendung = $sp.DisplayName; AppId = $sp.AppId; Berechtigung = $name }
        }
    }
}

if ($ergebnis) {
    $ergebnis | Sort-Object Anwendung | Format-Table -AutoSize
    "{0} Zuweisungen mit weitreichendem Schreibzugriff bei {1} Anwendungen." -f @($ergebnis).Count, @($ergebnis | Select-Object -Unique Anwendung).Count
} else {
    "Keine Zuweisungen mit '*ReadWrite.All' gefunden."
}
