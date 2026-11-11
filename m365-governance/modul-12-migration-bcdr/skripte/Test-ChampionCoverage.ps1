# Quelle: Skript „M365 Governance“, Modul 12, Listing 159 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Champions,      # CSV: Name;Abteilung
    [int]$BeschaeftigtePorChampion = 40
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

$champ = Import-Csv -Path $Champions -Delimiter ";" | Group-Object Abteilung -AsHashTable -AsString
if (-not $champ) { $champ = @{} }

$bestand = Get-MgUser -All -Property Department,AccountEnabled,UserType |
    Where-Object { $_.AccountEnabled -and $_.UserType -eq "Member" -and $_.Department } |
    Group-Object Department

$luecken = foreach ($abt in $bestand) {
    $ist = if ($champ.ContainsKey($abt.Name)) { @($champ[$abt.Name]).Count } else { 0 }
    $soll = [math]::Max(1, [math]::Ceiling($abt.Count / $BeschaeftigtePorChampion))
    if ($ist -lt $soll) {
        [pscustomobject]@{ Abteilung = $abt.Name; Beschaeftigte = $abt.Count; Champions = $ist; Soll = $soll; Fehlend = $soll - $ist }
    }
}

if ($luecken) { $luecken | Sort-Object Fehlend -Descending | Format-Table -AutoSize }
else { "Alle Abteilungen erreichen die Zielabdeckung." }
