# Quelle: Skript „M365 Governance“, Modul 09, Listing 100 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: Logik offline getestet mit erfundenen Berichtsdaten, aber an einer Kopie mit geändertem Anfangswert: Das Original scheitert in PowerShell 7 und Windows PowerShell 5.1 an [datetime]::TryParse mit $d = $null (siehe README dieses Moduls, Abschnitt "Hinweise"). Nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [int]$InaktivTage = 180,
    [string]$Datei = ".\SiteUsage.csv"
)

Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome
Get-MgReportSharePointSiteUsageDetail -Period D180 -OutFile $Datei
$zeilen = Import-Csv -Path $Datei | Where-Object { $_.'Is Deleted' -ne 'True' }
if (-not $zeilen) { throw "Keine Websites im Bericht." }

$grenze = (Get-Date).AddDays(-$InaktivTage).Date
$alt = foreach ($z in $zeilen) {
    $d = $null
    $hatDatum = [datetime]::TryParse($z.'Last Activity Date', [ref]$d)
    if (-not $hatDatum -or $d -lt $grenze) { $z }
}

$gb = ($alt | Measure-Object -Property 'Storage Used (Byte)' -Sum).Sum / 1GB
"Websites gesamt:            {0}" -f @($zeilen).Count
"Ohne Aktivitaet seit {0} Tagen: {1} ({2:P0})" -f $InaktivTage, @($alt).Count, (@($alt).Count / @($zeilen).Count)
"Belegter Speicher dort:     {0:N1} GB" -f $gb
