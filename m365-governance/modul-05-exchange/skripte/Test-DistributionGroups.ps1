# Quelle: Skript „M365 Governance“, Modul 05, Listing 36 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline

$gruppen = Get-DistributionGroup -ResultSize Unlimited
if (-not $gruppen) { Write-Host "Keine Verteilergruppen gefunden."; return }

$befunde = foreach ($g in $gruppen) {
    $mitglieder = @(Get-DistributionGroupMember -Identity $g.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue)
    $verschachtelt = @($mitglieder | Where-Object { $_.RecipientType -like "*Group*" }).Count
    $probleme = @()
    if (-not $g.ManagedBy -or @($g.ManagedBy).Count -eq 0) { $probleme += "kein Besitzer" }
    if (-not $g.RequireSenderAuthenticationEnabled)         { $probleme += "externe Absender erlaubt" }
    if ($mitglieder.Count -eq 0)                            { $probleme += "keine Mitglieder" }
    if ($verschachtelt -gt 0)                               { $probleme += "verschachtelt ($verschachtelt)" }
    if ($probleme) {
        [pscustomobject]@{ Gruppe = $g.PrimarySmtpAddress; Mitglieder = $mitglieder.Count
                           Befund = ($probleme -join "; ") }
    }
}

if ($befunde) { $befunde | Sort-Object Gruppe | Format-Table -AutoSize -Wrap }
"{0} von {1} Verteilergruppen mit Befund." -f @($befunde).Count, @($gruppen).Count
