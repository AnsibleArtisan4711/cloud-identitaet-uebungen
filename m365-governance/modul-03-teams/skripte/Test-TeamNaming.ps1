# Quelle: Skript „M365 Governance“, Modul 03, Listing 19 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome

# Konvention: TYP-Bereich-Name, TYP aus ABT, PRJ, KND, GRM
$muster = '^(ABT|PRJ|KND|GRM)-[A-Za-z0-9]+-[A-Za-z0-9 _.\-]{2,40}$'

$teams = Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All `
         -Property Id,DisplayName,CreatedDateTime

$ergebnis = $teams | ForEach-Object {
    [pscustomobject]@{
        Name     = $_.DisplayName
        Erstellt = $_.CreatedDateTime
        Konform  = [bool]($_.DisplayName -match $muster)
    }
}

"{0} von {1} Teams entsprechen der Konvention." -f ($ergebnis | Where-Object Konform).Count, $ergebnis.Count
$ergebnis | Where-Object { -not $_.Konform } | Sort-Object Erstellt | Select-Object -First 25 | Format-Table -AutoSize
