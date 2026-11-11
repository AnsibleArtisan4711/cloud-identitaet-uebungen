# Quelle: Skript „M365 Governance“, Modul 10, Listing 129 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Liste,      # CSV mit Spalte GruppenId
    [switch]$Ausfuehren,                       # ohne diesen Schalter nur Probelauf
    [string]$Protokoll = ".\archiv-protokoll.csv"
)

Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","Group.Read.All" -NoWelcome

$ziele = Import-Csv -Path $Liste
if (-not $ziele) { throw "Die Liste ist leer." }

$ergebnis = foreach ($z in $ziele) {
    $id = $z.GruppenId
    $status = "uebersprungen"
    try {
        $besitzer = @(Get-MgGroupOwner -GroupId $id -ErrorAction Stop)
        if ($besitzer.Count -eq 0) {
            $status = "kein Besitzer - manuell klaeren"
        } elseif (-not $Ausfuehren) {
            $status = "Probelauf: wuerde archivieren"
        } else {
            Invoke-MgArchiveTeam -TeamId $id -ErrorAction Stop
            $status = "Archivierung angestossen"
        }
    } catch {
        $status = "Fehler: " + $_.Exception.Message
    }
    [pscustomobject]@{ GruppenId = $id; Status = $status; Zeit = (Get-Date -Format s) }
}

$ergebnis | Export-Csv -Path $Protokoll -NoTypeInformation -Encoding UTF8
$ergebnis | Format-Table -AutoSize -Wrap
