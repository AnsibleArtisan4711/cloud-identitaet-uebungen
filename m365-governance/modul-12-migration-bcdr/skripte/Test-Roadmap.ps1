# Quelle: Skript „M365 Governance“, Modul 12, Listing 166 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei, [string]$Ausgabe = ".\roadmap.md")

$r = Get-Content -Path $Datei -Raw -Encoding UTF8 | ConvertFrom-Json
$start = [datetime]$r.start
$ids = @{}; foreach ($a in $r.aufgaben) { $ids[$a.id] = $a }
$fehler = New-Object System.Collections.Generic.List[string]

foreach ($a in $r.aufgaben) {
    if ($a.bis -lt $a.von) { $fehler.Add("$($a.id): Ende vor Beginn") }
    foreach ($v in $a.nach) {
        if (-not $ids.ContainsKey($v)) { $fehler.Add("$($a.id): Vorgaenger $v existiert nicht"); continue }
        if ($ids[$v].bis -ge $a.von) { $fehler.Add("$($a.id) beginnt an Tag $($a.von), Vorgaenger $v endet erst an Tag $($ids[$v].bis)") }
    }
}

function Get-Phase($tag) { if ($tag -le 30) { 1 } elseif ($tag -le 60) { 2 } else { 3 } }
$last = $r.aufgaben | ForEach-Object {
    $phase = Get-Phase $_.von
    [pscustomobject]@{ Wer = $_.wer; Phase = $phase; Stunden = $_.stunden }
} | Group-Object Wer, Phase | ForEach-Object {
    [pscustomobject]@{ Wer = $_.Group[0].Wer; Phase = $_.Group[0].Phase; Stunden = ($_.Group | Measure-Object Stunden -Sum).Sum }
}
foreach ($l in $last) {
    if ($l.Stunden -gt $r.stundenProPersonUndPhase) {
        $fehler.Add("$($l.Wer) in Phase $($l.Phase): $($l.Stunden) Stunden geplant, verfuegbar $($r.stundenProPersonUndPhase)")
    }
}

$zeilen = @("| Nr | Aufgabe | Von | Bis | Wer | Stunden |", "|---|---|---|---|---|---|")
foreach ($a in $r.aufgaben | Sort-Object von) {
    $zeilen += "| {0} | {1} | {2:yyyy-MM-dd} | {3:yyyy-MM-dd} | {4} | {5} |" -f $a.id, $a.name, $start.AddDays($a.von - 1), $start.AddDays($a.bis - 1), $a.wer, $a.stunden
}
$zeilen | Set-Content -Path $Ausgabe -Encoding UTF8

if ($fehler.Count -gt 0) { $fehler | ForEach-Object { Write-Host "PROBLEM: $_" -ForegroundColor Yellow }; exit 2 }
Write-Host "Roadmap ist konsistent. Ausgabe: $Ausgabe" -ForegroundColor Green
