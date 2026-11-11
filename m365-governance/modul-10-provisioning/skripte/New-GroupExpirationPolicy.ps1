# Quelle: Skript „M365 Governance“, Modul 10, Listing 127 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [int]$Lebensdauer = 365,
    [Parameter(Mandatory)][string]$AdresseOhneBesitzer,
    [Parameter(Mandatory)][string]$TestgruppeId
)

if ($Lebensdauer -lt 30) { throw "Die Lebensdauer muss mindestens 30 Tage betragen." }

Connect-MgGraph -Scopes "Directory.ReadWrite.All" -NoWelcome
if (Get-MgGroupLifecyclePolicy) { throw "Es existiert bereits eine Ablaufrichtlinie." }

$richtlinie = New-MgGroupLifecyclePolicy -GroupLifetimeInDays $Lebensdauer `
    -ManagedGroupTypes "Selected" -AlternateNotificationEmails $AdresseOhneBesitzer

Add-MgGroupLifecyclePolicyGroup -GroupLifecyclePolicyId $richtlinie.Id -GroupId $TestgruppeId

Get-MgGroupLifecyclePolicy | Format-List Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails
