# Quelle: Skript „M365 Governance“, Modul 08, Listing 84 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$NotfallGruppeId)

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Application.Read.All" -NoWelcome

$name = "CA001 - Legacy-Authentifizierung blockieren"
if (Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$name'") {
    throw "Richtlinie existiert bereits: $name"
}

$body = @{
    displayName = $name
    state       = "enabledForReportingButNotEnforced"
    conditions  = @{
        clientAppTypes = @("exchangeActiveSync", "other")
        applications   = @{ includeApplications = @("All") }
        users          = @{
            includeUsers  = @("All")
            excludeGroups = @($NotfallGruppeId)
        }
    }
    grantControls = @{
        operator        = "OR"
        builtInControls = @("block")
    }
}

$neu = New-MgIdentityConditionalAccessPolicy -BodyParameter $body
"Angelegt: {0} (Zustand: {1})" -f $neu.DisplayName, $neu.State
