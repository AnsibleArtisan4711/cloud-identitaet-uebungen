# Quelle: Skript „M365 Governance“, Modul 02, Listing 13 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "AccessReview.ReadWrite.All" -NoWelcome

$params = @{
    displayName         = "Quartalsweise Gaeste-Ueberpruefung"
    descriptionForAdmins = "Alle Gaeste in Microsoft-365-Gruppen, Selbstbestaetigung"
    descriptionForReviewers = "Bitte bestaetigen Sie, dass Sie den Zugriff weiter benoetigen."
    scope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query     = './members/microsoft.graph.user/?$filter=(userType eq ''Guest'')'
        queryType = "MicrosoftGraph"
    }
    instanceEnumerationScope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query     = "/groups?`$filter=(groupTypes/any(c:c eq 'Unified'))"
        queryType = "MicrosoftGraph"
    }
    reviewers = @(
        @{ query = "./"; queryType = "MicrosoftGraph"; queryRoot = "decisions_target" }
    )
    settings = @{
        mailNotificationsEnabled        = $true
        reminderNotificationsEnabled    = $true
        justificationRequiredOnApproval = $true
        defaultDecisionEnabled          = $true
        defaultDecision                 = "Deny"
        instanceDurationInDays          = 14
        autoApplyDecisionsEnabled       = $false   # erst nach dem Test auf $true setzen
        recommendationsEnabled          = $true
        recurrence = @{
            pattern = @{ type = "absoluteMonthly"; interval = 3 }
            range   = @{ type = "noEnd"; startDate = "2027-01-04" }
        }
    }
}
New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $params
