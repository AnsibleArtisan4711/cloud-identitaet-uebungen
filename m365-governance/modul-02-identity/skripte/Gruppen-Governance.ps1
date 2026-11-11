# Quelle: Skript „M365 Governance“, Modul 02, Listing 15 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.ReadWrite.All" -NoWelcome

# 1) Ablaufrichtlinie: 365 Tage, gilt fuer alle Microsoft-365-Gruppen
$policy = New-MgGroupLifecyclePolicy `
    -GroupLifetimeInDays 365 `
    -ManagedGroupTypes "All" `
    -AlternateNotificationEmails "it-governance@contoso.example"
"Richtlinie angelegt: $($policy.Id)"

# 2) Dynamische Microsoft-365-Gruppe fuer die Abteilung Vertrieb
$grp = New-MgGroup -DisplayName "GRP_Vertrieb_Alle" `
    -MailNickname "grp-vertrieb-alle" `
    -MailEnabled:$true -SecurityEnabled:$false `
    -GroupTypes @("Unified","DynamicMembership") `
    -MembershipRule '(user.department -eq "Vertrieb") and (user.accountEnabled -eq true)' `
    -MembershipRuleProcessingState "On"
"Gruppe angelegt: $($grp.Id)"

# 3) Gruppen ohne zwei Besitzer finden
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All | ForEach-Object {
    $owners = @(Get-MgGroupOwner -GroupId $_.Id)
    if ($owners.Count -lt 2) {
        [pscustomobject]@{ Gruppe = $_.DisplayName; Besitzer = $owners.Count }
    }
} | Sort-Object Besitzer | Format-Table -AutoSize
