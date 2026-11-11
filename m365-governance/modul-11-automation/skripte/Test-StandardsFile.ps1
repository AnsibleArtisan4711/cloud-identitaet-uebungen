# Quelle: Skript „M365 Governance“, Modul 11, Listing 141 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei)

$fehler = New-Object System.Collections.Generic.List[string]
try {
    $s = Get-Content -Path $Datei -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
} catch {
    Write-Error "Datei ist kein gueltiges JSON: $($_.Exception.Message)"; exit 1
}

if ($s.version -notmatch '^\d+\.\d+\.\d+$') { $fehler.Add("version muss Form x.y.z haben") }
$d = [datetime]::MinValue
if (-not [datetime]::TryParse($s.gueltigAb, [ref]$d)) { $fehler.Add("gueltigAb ist kein Datum") }

if (-not $s.gruppen) { $fehler.Add("Abschnitt 'gruppen' fehlt") }
else {
    try { [void][regex]::new($s.gruppen.namensmuster) } catch { $fehler.Add("namensmuster ist kein gueltiger regulaerer Ausdruck") }
    if ($s.gruppen.mindestBesitzer -lt 2)          { $fehler.Add("mindestBesitzer muss mindestens 2 sein") }
    if ($s.gruppen.lebensdauerTage -lt 30)         { $fehler.Add("lebensdauerTage muss mindestens 30 sein") }
    if (-not $s.gruppen.pflichtMetadaten -or @($s.gruppen.pflichtMetadaten).Count -eq 0) { $fehler.Add("pflichtMetadaten darf nicht leer sein") }
}

if ($fehler.Count -gt 0) {
    $fehler | ForEach-Object { Write-Host "FEHLER: $_" -ForegroundColor Red }
    exit 1
}
Write-Host "Standards-Datei ist gueltig (Version $($s.version))." -ForegroundColor Green
