# Quelle: Skript „M365 Governance“, Modul 05, Listing 48 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [string]$Absender,
    [string]$Empfaenger,
    [int]$Tage = 2
)
if (-not $Absender -and -not $Empfaenger) { throw "Absender oder Empfaenger angeben." }

Connect-ExchangeOnline

$param = @{ StartDate = (Get-Date).AddDays(-$Tage); EndDate = Get-Date }
if ($Absender)   { $param.SenderAddress    = $Absender }
if ($Empfaenger) { $param.RecipientAddress = $Empfaenger }

$ergebnis = Get-MessageTrace @param
if (-not $ergebnis) { Write-Host "Keine Nachrichten im Zeitraum gefunden."; return }

$ergebnis | Sort-Object Received -Descending |
    Select-Object Received, SenderAddress, RecipientAddress, Subject, Status |
    Format-Table -AutoSize -Wrap

foreach ($m in $ergebnis | Where-Object Status -notin "Delivered") {
    "--- Details: $($m.Subject) ($($m.Status))"
    Get-MessageTraceDetail -MessageTraceId $m.MessageTraceId -RecipientAddress $m.RecipientAddress |
        Select-Object Date, Event, Detail | Format-Table -AutoSize -Wrap
}
