# Quelle: Skript „M365 Governance“, Modul 01, Listing 1 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
# Voraussetzung: Install-Module Microsoft.Graph -Scope CurrentUser
Connect-MgGraph -Scopes "Organization.Read.All","User.Read.All","Group.Read.All"

$org      = Get-MgOrganization
$users    = Get-MgUserCount  -ConsistencyLevel eventual
$guests   = Get-MgUserCount  -Filter "userType eq 'Guest'" -ConsistencyLevel eventual
$m365Grp  = Get-MgGroupCount -Filter "groupTypes/any(c:c eq 'Unified')" -ConsistencyLevel eventual

[pscustomobject]@{
    Tenant          = $org.DisplayName
    Benutzer        = $users
    Gaeste          = $guests
    M365Gruppen     = $m365Grp
    Erstellt        = Get-Date -Format "yyyy-MM-dd HH:mm"
} | Format-List

Disconnect-MgGraph
