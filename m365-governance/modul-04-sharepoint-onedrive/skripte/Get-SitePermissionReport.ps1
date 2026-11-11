# Quelle: Skript „M365 Governance“, Modul 04, Listing 28 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$SiteUrl)

Connect-SPOService -Url "https://contoso-admin.sharepoint.com"

$gruppen = Get-SPOSiteGroup -Site $SiteUrl
$zeilen = foreach ($g in $gruppen) {
    foreach ($u in $g.Users) {
        $art = if ($u -like 'c:0t.c|tenant|*' -or $u -like 'c:0o.c|federateddirectoryclaimprovider|*') { 'Gruppe' }
               elseif ($u -like '*#ext#*') { 'Gast' }
               else { 'Einzelperson' }
        [pscustomobject]@{
            SharePointGruppe = $g.Title
            Rolle            = ($g.Roles -join ', ')
            Eintrag          = $u
            Art              = $art
        }
    }
}
$zeilen | Group-Object Art | Select-Object Name, Count | Format-Table -AutoSize
$zeilen | Where-Object Art -in 'Einzelperson','Gast' | Format-Table -AutoSize
