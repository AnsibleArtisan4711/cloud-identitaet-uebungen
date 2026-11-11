# Quelle: Skript „M365 Governance“, Modul 12, Listing 161 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([int]$Frist = 30, [int]$Warnschwelle = 7)

$ErrorActionPreference = "Stop"
Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome

function Add-Rest($objekt, [string]$typ) {
    $tage = $Frist - [int]((Get-Date) - $objekt.DeletedDateTime).TotalDays
    [pscustomobject]@{
        Typ = $typ
        Name = $objekt.AdditionalProperties.displayName
        GeloeschtAm = $objekt.DeletedDateTime.ToString("yyyy-MM-dd")
        RestTage = $tage
        Hinweis = if ($tage -le $Warnschwelle) { "Frist endet bald" } else { "" }
    }
}

$benutzer = Get-MgDirectoryDeletedItemAsUser -All | ForEach-Object { Add-Rest $_ "Benutzer" }
$gruppen  = Get-MgDirectoryDeletedItemAsGroup -All | ForEach-Object { Add-Rest $_ "Gruppe" }

$alle = @($benutzer) + @($gruppen)
if (-not $alle) { "Keine vorlaeufig geloeschten Objekte."; return }
$alle | Sort-Object RestTage | Format-Table -AutoSize
