# Quelle: Skript „M365 Governance“, Modul 11, Listing 145 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simuliertes Ticket-System), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
$script:ItsmBasis = $env:ITSM_URL         # z. B. https://tickets.contoso.com/api
$script:ItsmToken = $env:ITSM_TOKEN       # aus Tresor/Pipeline-Geheimnis, nie im Code

function Invoke-Itsm {
    param([string]$Methode, [string]$Pfad, $Body = $null)
    if (-not $script:ItsmBasis -or -not $script:ItsmToken) { throw "ITSM_URL und ITSM_TOKEN muessen gesetzt sein." }
    $kopf = @{ Authorization = "Bearer $($script:ItsmToken)"; Accept = "application/json" }
    $param = @{ Method = $Methode; Uri = "$($script:ItsmBasis)$Pfad"; Headers = $kopf; ContentType = "application/json" }
    if ($Body) { $param.Body = ($Body | ConvertTo-Json -Depth 5) }
    Invoke-RestMethod @param
}

function New-DriftTicket {
    param([Parameter(Mandatory)][string]$Eintrag, [Parameter(Mandatory)][string]$Beschreibung)
    $schluessel = "drift-" + ($Eintrag.ToLower() -replace '[^a-z0-9]+','-')
    $offen = Invoke-Itsm -Methode GET -Pfad "/tickets?externalKey=$schluessel&status=open"
    if ($offen.items -and @($offen.items).Count -gt 0) {
        Write-Host "Offenes Ticket existiert bereits: $($offen.items[0].number)"; return $offen.items[0]
    }
    Invoke-Itsm -Methode POST -Pfad "/tickets" -Body @{
        type = "incident"; externalKey = $schluessel; priority = "3"
        title = "Konfigurationsabweichung: $Eintrag"; description = $Beschreibung
        assignmentGroup = "M365-Betrieb"
    }
}

function Assert-ChangeApproved {
    param([Parameter(Mandatory)][string]$Nummer)
    $c = Invoke-Itsm -Methode GET -Pfad "/changes/$Nummer"
    if ($c.state -ne "approved") { throw "Change $Nummer hat Status '$($c.state)', erwartet 'approved'." }
    $c
}
