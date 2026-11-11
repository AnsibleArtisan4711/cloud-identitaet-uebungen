# Quelle: Skript „M365 Governance“, Modul 10, Listing 132 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
function Invoke-WithRetry {
    param(
        [Parameter(Mandatory)][scriptblock]$Aktion,
        [int]$MaxVersuche = 4,
        [int]$FesteWartezeit = 10
    )
    for ($i = 1; $i -le $MaxVersuche; $i++) {
        try {
            return & $Aktion
        } catch {
            $meldung = $_.Exception.Message
            $status = $null
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }

            if ($i -eq $MaxVersuche) { throw "Aufgegeben nach $i Versuchen: $meldung" }

            if ($status -eq 429) {
                $warte = 30
                $ra = $_.Exception.Response.Headers | Where-Object { $_.Key -eq "Retry-After" }
                if ($ra) { $warte = [int]($ra.Value | Select-Object -First 1) }
                Write-Warning "Gedrosselt (429), warte $warte Sekunden."
                Start-Sleep -Seconds $warte
            }
            elseif ($status -eq 404 -or $meldung -match "NotFound|ResourceNotFound") {
                Write-Warning "Objekt noch nicht sichtbar (404), warte $FesteWartezeit Sekunden."
                Start-Sleep -Seconds $FesteWartezeit
            }
            else {
                throw $_
            }
        }
    }
}

# Beispiel: Team aus Gruppe erzeugen
Invoke-WithRetry -Aktion {
    Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/groups/$gruppenId/team" `
        -Body "{}" -ContentType "application/json"
}
