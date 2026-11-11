# Quelle: Skript „M365 Governance“, Modul 10, Listing 116 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Nickname,
    [Parameter(Mandatory)][string[]]$Besitzer,
    [string]$Beschreibung = "",
    [ValidateSet("Private","Public")][string]$Sichtbarkeit = "Private"
)

if ($Besitzer.Count -lt 2) { throw "Mindestens zwei Besitzer sind Pflicht." }

Connect-MgGraph -Scopes "Group.ReadWrite.All","User.Read.All" -NoWelcome

$besitzerIds = foreach ($b in $Besitzer) { (Get-MgUser -UserId $b -ErrorAction Stop).Id }

$gruppe = New-MgGroup -DisplayName $Name -MailNickname $Nickname `
    -Description $Beschreibung -GroupTypes @("Unified") `
    -MailEnabled:$true -SecurityEnabled:$false -Visibility $Sichtbarkeit `
    -AdditionalProperties @{
        "owners@odata.bind" = @($besitzerIds | ForEach-Object { "https://graph.microsoft.com/v1.0/users/$_" })
    }
Write-Host "Gruppe angelegt: $($gruppe.Id)"

$versuche = 0
do {
    try {
        Invoke-MgGraphRequest -Method PUT -Uri "https://graph.microsoft.com/v1.0/groups/$($gruppe.Id)/team" `
            -Body (@{ memberSettings = @{ allowCreatePrivateChannels = $true } } | ConvertTo-Json) `
            -ContentType "application/json" | Out-Null
        $team = $true
    } catch {
        $versuche++
        if ($versuche -ge 3) { throw "Team konnte nicht erzeugt werden: $($_.Exception.Message)" }
        Write-Warning "Team noch nicht moeglich, neuer Versuch in 10 Sekunden ($versuche/3)."
        Start-Sleep -Seconds 10
    }
} until ($team)

[pscustomobject]@{ GruppenId = $gruppe.Id; Name = $Name; Besitzer = ($Besitzer -join "; "); Zeit = (Get-Date -Format s) }
