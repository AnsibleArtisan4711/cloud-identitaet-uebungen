# Quelle: Skript „M365 Governance“, Modul 02, Listing 11 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "LifecycleWorkflows.ReadWrite.All" -NoWelcome

$params = @{
    category            = "joiner"
    displayName         = "Eintritt Marketing - Willkommen"
    description         = "Konto aktivieren und Willkommensnachricht senden"
    isEnabled           = $true
    isSchedulingEnabled = $false      # zuerst nur manuell/on demand testen
    executionConditions = @{
        "@odata.type" = "#microsoft.graph.identityGovernance.triggerAndScopeBasedConditions"
        scope = @{
            "@odata.type" = "#microsoft.graph.identityGovernance.ruleBasedSubjectSet"
            rule          = "(department eq 'Marketing')"
        }
        trigger = @{
            "@odata.type"      = "#microsoft.graph.identityGovernance.timeBasedAttributeTrigger"
            timeBasedAttribute = "employeeHireDate"
            offsetInDays       = -1       # einen Tag vor dem Eintrittsdatum
        }
    }
    tasks = @(
        @{ continueOnError = $false; isEnabled = $true
           displayName = "Konto aktivieren"
           taskDefinitionId = "6fc52c9d-398b-4305-9763-15f42c1676fc"; arguments = @() }
        @{ continueOnError = $false; isEnabled = $true
           displayName = "Willkommens-E-Mail senden"
           taskDefinitionId = "70b29d51-b59a-4773-9280-8841dfd3f2ea"; arguments = @() }
    )
}

$wf = New-MgIdentityGovernanceLifecycleWorkflow -BodyParameter $params
"Workflow angelegt: $($wf.Id)"

# Bisherige Laeufe auflisten
Get-MgIdentityGovernanceLifecycleWorkflowRun -WorkflowId $wf.Id | Format-Table Id, ProcessingStatus, StartedDateTime
