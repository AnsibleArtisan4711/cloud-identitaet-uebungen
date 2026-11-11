# Quelle: Skript „M365 Governance“, Modul 08, Listing 82 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Verlauf = ".\SecureScore-Verlauf.csv")

Connect-MgGraph -Scopes "SecurityEvents.Read.All" -NoWelcome

$s = Get-MgSecuritySecureScore -Top 1
if (-not $s) { throw "Kein Secure-Score-Eintrag gefunden." }

$zeile = [pscustomobject]@{
    Datum       = $s.CreatedDateTime.ToString("yyyy-MM-dd")
    Punkte      = $s.CurrentScore
    Maximum     = $s.MaxScore
    ProzentWert = [math]::Round(100 * $s.CurrentScore / $s.MaxScore, 1)
}

if ((Test-Path $Verlauf) -and
    (Import-Csv $Verlauf | Where-Object Datum -eq $zeile.Datum)) {
    Write-Host "Eintrag fuer $($zeile.Datum) existiert bereits."
} else {
    $zeile | Export-Csv -Path $Verlauf -Append -NoTypeInformation -Encoding UTF8
    $zeile | Format-Table -AutoSize
}
