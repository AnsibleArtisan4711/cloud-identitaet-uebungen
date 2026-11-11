# Quelle: Skript „M365 Governance“, Modul 11, Lösung zu Aufgabe 4 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
[CmdletBinding(SupportsShouldProcess)]
param([Parameter(Mandatory)][string]$Ersatzbesitzer, [string]$Ausgabe = ".\ohne-besitzer.csv")
$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All" -NoWelcome
$user = Get-MgUser -UserId $Ersatzbesitzer
$treffer = foreach ($g in Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName) {
    if (@(Get-MgGroupOwner -GroupId $g.Id).Count -eq 0) {
        $status = "geplant"
        if ($PSCmdlet.ShouldProcess($g.DisplayName, "Besitzer $Ersatzbesitzer hinzufuegen")) {
            New-MgGroupOwnerByRef -GroupId $g.Id -BodyParameter @{ "@odata.id" = "https://graph.microsoft.com/v1.0/users/$($user.Id)" }
            $status = "zugewiesen"
        }
        [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $g.Id; Status = $status }
    }
}
$treffer | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
