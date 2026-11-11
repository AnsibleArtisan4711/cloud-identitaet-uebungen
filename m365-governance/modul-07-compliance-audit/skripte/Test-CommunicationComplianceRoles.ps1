# Quelle: Skript „M365 Governance“, Modul 07, Listing 74 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Audit-, eDiscovery- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

$gruppen = "Communication Compliance Admins",
           "Communication Compliance Analysts",
           "Communication Compliance Investigators",
           "Communication Compliance Viewers"
$zuordnung = foreach ($g in $gruppen) {
    $rg = Get-RoleGroup -Identity $g -ErrorAction SilentlyContinue
    if (-not $rg) { Write-Warning "Rollengruppe nicht gefunden: $g"; continue }
    Get-RoleGroupMember -Identity $g | ForEach-Object {
        [pscustomobject]@{ Gruppe = $g; Mitglied = $_.Name }
    }
}

$zuordnung | Sort-Object Gruppe, Mitglied | Format-Table -AutoSize

"--- Personen in Admin-Gruppe UND Pruefergruppe ---"
$admins = $zuordnung | Where-Object Gruppe -like "*Admins"        | Select-Object -ExpandProperty Mitglied
$pruefer = $zuordnung | Where-Object Gruppe -like "*Investigators" | Select-Object -ExpandProperty Mitglied
$admins | Where-Object { $_ -in $pruefer }
