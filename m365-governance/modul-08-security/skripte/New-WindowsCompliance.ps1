# Quelle: Skript „M365 Governance“, Modul 08, Listing 90 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All",
                        "DeviceManagementManagedDevices.Read.All" -NoWelcome

$body = @{
    "@odata.type"        = "#microsoft.graph.windows10CompliancePolicy"
    displayName          = "Windows Basis-Konformitaet"
    description          = "BitLocker, Secure Boot, Kennwort, Mindest-OS"
    passwordRequired     = $true
    bitLockerEnabled     = $true
    secureBootEnabled    = $true
    osMinimumVersion     = "10.0.19045"
    scheduledActionsForRule = @(
        @{
            ruleName = "PasswordRequired"
            scheduledActionConfigurations = @(
                @{ actionType = "block"; gracePeriodHours = 24 }
            )
        }
    )
}

$neu = Invoke-MgGraphRequest -Method POST `
    -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" `
    -Body ($body | ConvertTo-Json -Depth 6) -ContentType "application/json"
"Angelegt: $($neu.displayName) ($($neu.id))"

"--- Nicht konforme Geraete ---"
$geraete = Get-MgDeviceManagementManagedDevice -Filter "complianceState eq 'noncompliant'" -All
$geraete | Select-Object DeviceName, UserPrincipalName, OperatingSystem, OsVersion, LastSyncDateTime |
    Sort-Object LastSyncDateTime | Format-Table -AutoSize
"Anzahl: {0}" -f @($geraete).Count
