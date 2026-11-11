# Quelle: Skript „M365 Governance“, Modul 11, Listing 136 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Standardtext,
    [string]$Protokoll = ".\beschreibung-protokoll.csv"
)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,Description
$zeilen = foreach ($g in $gruppen) {
    if (-not [string]::IsNullOrWhiteSpace($g.Description)) { continue }   # idempotent: schon erledigt

    $text = "$Standardtext ($($g.DisplayName))"
    $status = "geplant"
    if ($PSCmdlet.ShouldProcess($g.DisplayName, "Beschreibung setzen")) {
        try {
            Update-MgGroup -GroupId $g.Id -Description $text
            $status = "gesetzt"
        } catch {
            $status = "Fehler: " + $_.Exception.Message
        }
    }
    [pscustomobject]@{ Zeit = (Get-Date -Format s); GruppenId = $g.Id; Name = $g.DisplayName; Status = $status }
}

if ($zeilen) { $zeilen | Export-Csv -Path $Protokoll -NoTypeInformation -Encoding UTF8 -Append }
"{0} Gruppen bearbeitet." -f @($zeilen).Count
