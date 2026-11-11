# Quelle: Skript „M365 Governance“, Modul 11, Listing 149 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateRange(30, 3650)][int]$NeueLebensdauer,
    [Parameter(Mandatory)][string]$ChangeNummer,
    [string]$Sicherung = ".\rollback"
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Directory.ReadWrite.All" -NoWelcome

$richtlinie = Get-MgGroupLifecyclePolicy | Select-Object -First 1
if (-not $richtlinie) { throw "Keine Ablaufrichtlinie vorhanden." }

New-Item -ItemType Directory -Path $Sicherung -Force | Out-Null
$datei = Join-Path $Sicherung ("{0}-{1}.json" -f $ChangeNummer, (Get-Date -Format "yyyyMMdd-HHmmss"))
$richtlinie | Select-Object Id, GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails |
    ConvertTo-Json | Set-Content -Path $datei -Encoding UTF8
Write-Host "Sicherung geschrieben: $datei"

if (-not $PSCmdlet.ShouldProcess("Ablaufrichtlinie $($richtlinie.Id)", "Lebensdauer $($richtlinie.GroupLifetimeInDays) -> $NeueLebensdauer")) { return }

try {
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $richtlinie.Id -GroupLifetimeInDays $NeueLebensdauer
    $pruefung = Get-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $richtlinie.Id
    if ($pruefung.GroupLifetimeInDays -ne $NeueLebensdauer) { throw "Pruefung fehlgeschlagen: Wert ist $($pruefung.GroupLifetimeInDays)." }
    Write-Host "Aenderung erfolgreich ($ChangeNummer)."
} catch {
    Write-Warning "Fehler: $($_.Exception.Message) - Rollback wird ausgefuehrt."
    $alt = Get-Content -Path $datei -Raw -Encoding UTF8 | ConvertFrom-Json
    Update-MgGroupLifecyclePolicy -GroupLifecyclePolicyId $alt.Id -GroupLifetimeInDays $alt.GroupLifetimeInDays
    throw "Rollback ausgefuehrt, Aenderung $ChangeNummer fehlgeschlagen."
}
