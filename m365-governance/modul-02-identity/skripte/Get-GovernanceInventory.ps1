# Quelle: Skript „M365 Governance“, Modul 02, Listing 10 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "EntitlementManagement.Read.All","AccessReview.Read.All","LifecycleWorkflows.Read.All" -NoWelcome

function Get-CountSafe($Name, [scriptblock]$Query) {
    try {
        $n = @(& $Query).Count
        [pscustomobject]@{ Funktion = $Name; Anzahl = $n; Hinweis = "" }
    } catch {
        [pscustomobject]@{ Funktion = $Name; Anzahl = $null; Hinweis = $_.Exception.Message.Split("`n")[0] }
    }
}

@(
  Get-CountSafe "Kataloge"                { Get-MgEntitlementManagementCatalog -All }
  Get-CountSafe "Zugriffspakete"          { Get-MgEntitlementManagementAccessPackage -All }
  Get-CountSafe "Zugriffsueberpruefungen" { Get-MgIdentityGovernanceAccessReviewDefinition -All }
  Get-CountSafe "Lifecycle Workflows"     { Get-MgIdentityGovernanceLifecycleWorkflow -All }
) | Format-Table -AutoSize
