# Quelle: Skript „M365 Governance“, Modul 11, Listing 138 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Ziel = ".\config-export")

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Path $Ziel -Force | Out-Null

function Save-Json {
    param($Objekt, [string]$Datei, [string[]]$Fluechtig = @())
    $json = $Objekt | ConvertTo-Json -Depth 20
    $kopie = $json | ConvertFrom-Json
    foreach ($e in @($kopie)) {
        foreach ($f in $Fluechtig) { if ($e.PSObject.Properties[$f]) { $e.PSObject.Properties.Remove($f) } }
    }
    $kopie | ConvertTo-Json -Depth 20 | Set-Content -Path (Join-Path $Ziel $Datei) -Encoding UTF8
}
Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
$ca = Get-MgIdentityConditionalAccessPolicy -All | Sort-Object DisplayName
Save-Json -Objekt $ca -Datei "bedingter-zugriff.json" -Fluechtig @("ModifiedDateTime")

Connect-ExchangeOnline -ShowBanner:$false
$regeln = Get-TransportRule | Sort-Object Name |
    Select-Object Name, Priority, State, Mode, Comments, Description
Save-Json -Objekt $regeln -Datei "transportregeln.json"

Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome
$lebenslauf = Get-MgGroupLifecyclePolicy | Select-Object GroupLifetimeInDays, ManagedGroupTypes, AlternateNotificationEmails
Save-Json -Objekt $lebenslauf -Datei "gruppen-ablauf.json"

"Export abgeschlossen: $((Get-ChildItem $Ziel).Count) Dateien in $Ziel"
