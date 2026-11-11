# Quelle: Skript „M365 Governance“, Modul 01, Listing 3 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome

Get-MgSubscribedSku |
    Select-Object @{n='Lizenz';e={$_.SkuPartNumber}},
                  @{n='Gekauft';e={$_.PrepaidUnits.Enabled}},
                  @{n='Zugewiesen';e={$_.ConsumedUnits}},
                  @{n='Frei';e={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}},
                  @{n='Dienstplaene';e={$_.ServicePlans.Count}} |
    Sort-Object Lizenz |
    Format-Table -AutoSize
