# Quelle: Skript „M365 Governance“, Modul 12, Listing 153 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei)

$zeilen = Import-Csv -Path $Datei -Delimiter ";"
if (-not $zeilen) { throw "Die Datei enthaelt keine Zeilen." }

$ergebnis = foreach ($z in $zeilen) {
    $ist = [int]$z.Ist; $ziel = [int]$z.Ziel; $gewicht = [int]$z.Gewicht
    if ($ist -lt 1 -or $ist -gt 5 -or $ziel -lt 1 -or $ziel -gt 5) {
        throw "Ungueltige Stufe bei '$($z.Bereich)': Werte muessen zwischen 1 und 5 liegen."
    }
    if ($ziel -lt $ist) { Write-Warning "Ziel unter Ist bei '$($z.Bereich)'." }
    $luecke = [math]::Max(0, $ziel - $ist)
    [pscustomobject]@{
        Bereich   = $z.Bereich
        Ist       = $ist
        Ziel      = $ziel
        Luecke    = $luecke
        Prioritaet = $luecke * $gewicht
    }
}

$ergebnis | Sort-Object Prioritaet -Descending | Format-Table -AutoSize
$mittel = ($ergebnis | Measure-Object Ist -Average).Average
"Durchschnittliche Ist-Stufe: {0:N1} (Hinweis: Das Profil ist aussagekraeftiger als der Durchschnitt.)" -f $mittel
