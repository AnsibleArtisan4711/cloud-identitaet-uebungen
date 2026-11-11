# Quelle: Skript „M365 Governance“, Modul 09, Listing 104 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Tage = 30)

Connect-MgGraph -Scopes "SecurityIncident.Read.All" -NoWelcome

$seit = (Get-Date).ToUniversalTime().AddDays(-$Tage).ToString("yyyy-MM-ddTHH:mm:ssZ")
$vorfaelle = Get-MgSecurityIncident -Filter "createdDateTime ge $seit" -All
if (-not $vorfaelle) { Write-Host "Keine Vorfaelle im Zeitraum."; return }

$geloest = $vorfaelle | Where-Object Status -eq "resolved"
$offen   = $vorfaelle | Where-Object Status -ne "resolved"

"Vorfaelle gesamt:   {0}" -f @($vorfaelle).Count
"Geloest:            {0}" -f @($geloest).Count
"Offen:              {0}" -f @($offen).Count
if ($geloest) {
    $stunden = $geloest | ForEach-Object { ($_.LastUpdateDateTime - $_.CreatedDateTime).TotalHours }
    "Mittlere Dauer (Naeherung): {0:N1} Stunden" -f ($stunden | Measure-Object -Average).Average
}

"--- Aelteste offene Vorfaelle ---"
$offen | Sort-Object CreatedDateTime | Select-Object -First 5 CreatedDateTime, Severity, DisplayName |
    Format-Table -AutoSize -Wrap
