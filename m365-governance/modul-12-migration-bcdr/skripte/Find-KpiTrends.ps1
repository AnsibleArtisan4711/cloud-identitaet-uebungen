# Quelle: Skript „M365 Governance“, Modul 12, Listing 163 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (mit erfundenen Testdateien), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$Datei, [int]$Perioden = 3)

$zeilen = Import-Csv -Path $Datei -Delimiter ";"
if (-not $zeilen) { throw "Keine Daten." }

$befunde = foreach ($gruppe in ($zeilen | Group-Object Kennzahl)) {
    $reihe = @($gruppe.Group | Sort-Object { [datetime]$_.Datum })
    $letzter = $reihe[-1]
    $ziel = [decimal]$letzter.Ziel
    $wert = [decimal]$letzter.Wert
    $hoeherBesser = $letzter.BesserWenn -eq "hoeher"

    $verfehlt = if ($hoeherBesser) { $wert -lt $ziel } else { $wert -gt $ziel }

    $verschlechtert = $false
    if ($reihe.Count -gt $Perioden) {
        $ende = $reihe[($reihe.Count - $Perioden - 1)..($reihe.Count - 1)]
        $verschlechtert = $true
        for ($i = 1; $i -lt $ende.Count; $i++) {
            $vorher = [decimal]$ende[$i - 1].Wert; $jetzt = [decimal]$ende[$i].Wert
            $schlechter = if ($hoeherBesser) { $jetzt -lt $vorher } else { $jetzt -gt $vorher }
            if (-not $schlechter) { $verschlechtert = $false; break }
        }
    }

    if ($verfehlt -or $verschlechtert) {
        [pscustomobject]@{
            Kennzahl = $gruppe.Name; Aktuell = $wert; Ziel = $ziel
            Befund = (@(if ($verfehlt) {"Ziel verfehlt"}; if ($verschlechtert) {"$Perioden Perioden schlechter"}) -join "; ")
        }
    }
}

if ($befunde) { $befunde | Format-Table -AutoSize -Wrap } else { "Keine auffaelligen Kennzahlen." }
