# Quelle: Skript „M365 Governance“, Modul 09, Listing 98 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Datei = ".\ActiveUserDetail.csv")

Connect-MgGraph -Scopes "Reports.Read.All" -NoWelcome

Get-MgReportOffice365ActiveUserDetail -Period D90 -OutFile $Datei
$zeilen = Import-Csv -Path $Datei
if (-not $zeilen) { throw "Bericht ist leer." }

$aktSpalten = "Exchange Last Activity Date", "OneDrive Last Activity Date",
              "SharePoint Last Activity Date", "Teams Last Activity Date"
$lizSpalten = "Has Exchange License", "Has OneDrive License",
              "Has SharePoint License", "Has Teams License"

$vorhanden = $zeilen[0].PSObject.Properties.Name
$fehlt = @($aktSpalten + $lizSpalten + "Is Deleted") | Where-Object { $_ -notin $vorhanden }
if ($fehlt) { throw "Spalten nicht gefunden: $($fehlt -join ', ')" }

$ohne = foreach ($z in $zeilen) {
    if ($z.'Is Deleted' -eq 'True') { continue }
    $lizenziert = $lizSpalten | Where-Object { $z.$_ -eq 'True' }
    $aktiv      = $aktSpalten | Where-Object { $z.$_ }
    if ($lizenziert -and -not $aktiv) { $z }
}

"Konten im Bericht:                  {0}" -f @($zeilen).Count
"Lizenziert, aber ohne Aktivitaet:    {0}" -f @($ohne).Count

if ($ohne -and $ohne[0].'User Principal Name' -like '*@*') {
    $ohne | Select-Object 'User Principal Name', 'Display Name' | Format-Table -AutoSize
} elseif ($ohne) {
    Write-Host "Namen sind verborgen (Datenschutzeinstellung der Berichte)."
}
