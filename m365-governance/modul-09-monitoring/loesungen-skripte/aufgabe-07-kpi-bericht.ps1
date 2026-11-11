# Quelle: Skript „M365 Governance“, Modul 09, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (Codestück, nur zusammen mit Get-KpiStatus.ps1 lauffähig; getestet mit erfundenen Ergebnissen), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
$rang = @{ rot = 0; gelb = 1; gruen = 2 }
$zeilen = $ergebnis | Sort-Object { $rang[$_.Status] }, Kennzahl |
  ForEach-Object { "| {0} | {1} | {2} | {3} | {4} |" -f $_.Kennzahl, $_.Wert, $_.Ziel, $_.Status, $_.Verantwortlich }
@("| Kennzahl | Wert | Ziel | Status | Verantwortlich |", "|---|---|---|---|---|") + $zeilen |
  Set-Content -Path ".\kpi-bericht.md" -Encoding UTF8
