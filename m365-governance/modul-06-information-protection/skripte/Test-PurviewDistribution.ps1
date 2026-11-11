# Quelle: Skript „M365 Governance“, Modul 06, Listing 64 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

$ergebnis = @()
$ergebnis += Get-DlpCompliancePolicy -DistributionDetail |
    Select-Object @{n='Typ';e={'DLP'}}, Name, Mode, DistributionStatus
$ergebnis += Get-RetentionCompliancePolicy -DistributionDetail |
    Select-Object @{n='Typ';e={'Aufbewahrung'}}, Name,
        @{n='Mode';e={ if ($_.Enabled) {'Enabled'} else {'Disabled'} }}, DistributionStatus
$ergebnis += Get-LabelPolicy |
    Select-Object @{n='Typ';e={'Label'}}, Name,
        @{n='Mode';e={'-'}}, DistributionStatus

$ergebnis | Where-Object { $_.DistributionStatus -ne 'Success' } |
    Format-Table -AutoSize
Write-Host ("Geprueft: {0} Richtlinien, davon auffaellig: {1}" -f `
    $ergebnis.Count, ($ergebnis | Where-Object { $_.DistributionStatus -ne 'Success' }).Count)
