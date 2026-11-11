# Quelle: Skript „M365 Governance“, Modul 11, Listing 143 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: Logik offline getestet mit erfundenen Dateien, aber an einer Kopie mit umbenannter Variable: Das Original scheitert, weil die Variable $ist den Parameter $Ist (Typ string) überschreibt (siehe README dieses Moduls, Abschnitt "Hinweise"). Nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Baseline,
    [Parameter(Mandatory)][string]$Ist,
    [string]$Schluessel = "Name",
    [string[]]$Ignorieren = @()
)
function Read-Config($pfad) {
    $o = Get-Content -Path $pfad -Raw -Encoding UTF8 | ConvertFrom-Json
    $h = @{}
    foreach ($e in @($o)) { $h[[string]$e.$Schluessel] = $e }
    $h
}

$soll = Read-Config $Baseline
$ist  = Read-Config $Ist
$drift = New-Object System.Collections.Generic.List[object]

foreach ($k in $soll.Keys) {
    if (-not $ist.ContainsKey($k)) {
        $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "fehlt im Tenant"; Feld = ""; Soll = ""; Ist = "" }); continue
    }
    foreach ($p in $soll[$k].PSObject.Properties.Name) {
        if ($p -in $Ignorieren) { continue }
        $a = $soll[$k].$p | ConvertTo-Json -Depth 10 -Compress
        $b = $ist[$k].$p  | ConvertTo-Json -Depth 10 -Compress
        if ($a -ne $b) {
            $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "Wert abweichend"; Feld = $p; Soll = $a; Ist = $b })
        }
    }
}
foreach ($k in $ist.Keys) {
    if (-not $soll.ContainsKey($k)) {
        $drift.Add([pscustomobject]@{ Eintrag = $k; Art = "zusaetzlich im Tenant"; Feld = ""; Soll = ""; Ist = "" })
    }
}

if ($drift.Count -eq 0) { Write-Host "Keine Abweichung."; exit 0 }
$drift | Format-Table -AutoSize -Wrap
exit 2
