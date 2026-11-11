# Quelle: Skript „M365 Governance“, Modul 12, Listing 157 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: Logik offline getestet (simulierte Graph-Cmdlets), aber an einer Kopie mit geändertem Anfangswert: Das Original scheitert an [datetime]::TryParse mit $null als Anfangswert (siehe README dieses Moduls, Abschnitt "Hinweise"). Nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Bericht, [int]$Tage = 30)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "User.Read.All" -NoWelcome

$aktivitaet = Import-Csv -Path $Bericht
if (-not $aktivitaet) { throw "Der Bericht ist leer." }
if ("User Principal Name" -notin $aktivitaet[0].PSObject.Properties.Name) { throw "Spalte 'User Principal Name' fehlt." }

$verzeichnis = @{}
Get-MgUser -All -Property UserPrincipalName,Department,AccountEnabled |
    Where-Object AccountEnabled | ForEach-Object { $verzeichnis[$_.UserPrincipalName.ToLower()] = $_.Department }

$treffer = @($aktivitaet | Where-Object { $verzeichnis.ContainsKey($_.'User Principal Name'.ToLower()) }).Count
if ($treffer -eq 0) {
    throw "Kein Benutzername aus dem Bericht im Verzeichnis gefunden. Sind Benutzernamen im Bericht verborgen?"
}
$grenze = (Get-Date).AddDays(-$Tage).Date
function Test-Aktiv($text) {
    $d = $null
    [datetime]::TryParse($text, [ref]$d) -and $d -ge $grenze
}

$ergebnis = $aktivitaet |
    Where-Object { $_.'Is Deleted' -ne 'True' -and $verzeichnis.ContainsKey($_.'User Principal Name'.ToLower()) } |
    ForEach-Object {
        $abt = $verzeichnis[$_.'User Principal Name'.ToLower()]
        if ([string]::IsNullOrWhiteSpace($abt)) { $abt = "(ohne Abteilung)" }
        [pscustomobject]@{
            Abteilung = $abt
            Teams     = Test-Aktiv $_.'Teams Last Activity Date'
            Exchange  = Test-Aktiv $_.'Exchange Last Activity Date'
        }
    } | Group-Object Abteilung | ForEach-Object {
        $n = $_.Count
        [pscustomobject]@{
            Abteilung = $_.Name; Benutzer = $n
            TeamsAktiv    = "{0:P0}" -f (@($_.Group | Where-Object Teams).Count / $n)
            ExchangeAktiv = "{0:P0}" -f (@($_.Group | Where-Object Exchange).Count / $n)
        }
    }

$ergebnis | Sort-Object Abteilung | Format-Table -AutoSize
