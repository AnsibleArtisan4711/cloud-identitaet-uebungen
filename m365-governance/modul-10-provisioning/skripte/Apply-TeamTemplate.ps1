# Quelle: Skript „M365 Governance“, Modul 10, Listing 121 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$TeamId,
    [Parameter(Mandatory)][string]$Vorlage
)

Connect-MgGraph -Scopes "Channel.Create","ChannelSettings.Read.All" -NoWelcome

$v = Get-Content -Path $Vorlage -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $v.kanaele) { throw "Vorlage enthaelt keine Kanaele." }

$vorhanden = (Get-MgTeamChannel -TeamId $TeamId).DisplayName

foreach ($k in $v.kanaele) {
    if ($k.name -in $vorhanden) {
        Write-Host "Kanal vorhanden, uebersprungen: $($k.name)"
        continue
    }
    New-MgTeamChannel -TeamId $TeamId -DisplayName $k.name -Description $k.beschreibung | Out-Null
    Write-Host "Kanal angelegt: $($k.name)"
}
