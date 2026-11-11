# Quelle: Skript „M365 Governance“, Modul 03, Listing 23 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "DelegatedPermissionGrant.Read.All","Application.Read.All" -NoWelcome

$riskant = "Files.ReadWrite.All","Mail.ReadWrite","Mail.Send","Sites.ReadWrite.All","Directory.ReadWrite.All"

$sp = @{}
Get-MgServicePrincipal -All -Property Id,DisplayName | ForEach-Object { $sp[$_.Id] = $_.DisplayName }

Get-MgOauth2PermissionGrant -All |
    ForEach-Object {
        $scopes = $_.Scope -split ' ' | Where-Object { $_ }
        $treffer = $scopes | Where-Object { $_ -in $riskant }
        if ($treffer) {
            [pscustomobject]@{
                Anwendung = $sp[$_.ClientId]
                Art       = $_.ConsentType      # AllPrincipals = Administratorzustimmung
                Rechte    = ($treffer -join ', ')
            }
        }
    } | Sort-Object Anwendung | Format-Table -AutoSize
