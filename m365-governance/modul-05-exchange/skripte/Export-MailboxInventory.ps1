# Quelle: Skript „M365 Governance“, Modul 05, Listing 34 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([string]$Ausgabe = ".\Postfachinventar.csv")

Connect-ExchangeOnline

$postfaecher = Get-Mailbox -ResultSize Unlimited
if (-not $postfaecher) { throw "Keine Postfaecher gefunden." }

$inventar = foreach ($p in $postfaecher) {
    $stat = Get-MailboxStatistics -Identity $p.ExchangeGuid.ToString() -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Anzeigename    = $p.DisplayName
        Adresse        = $p.PrimarySmtpAddress
        Typ            = $p.RecipientTypeDetails
        GroesseMB      = if ($stat) { [math]::Round($stat.TotalItemSize.Value.ToMB(), 0) } else { $null }
        ArchivAktiv    = $p.ArchiveStatus
        LitigationHold = $p.LitigationHoldEnabled
        WeiterleitungIntern = $p.ForwardingAddress
        WeiterleitungExtern = $p.ForwardingSmtpAddress
        LetzteAnmeldung = if ($stat) { $stat.LastLogonTime } else { $null }
    }
}

$inventar | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
"{0} Postfaecher exportiert nach {1}" -f @($inventar).Count, $Ausgabe

$extern = $inventar | Where-Object { $_.WeiterleitungExtern }
if ($extern) {
    Write-Warning "$(@($extern).Count) Postfaecher mit Weiterleitung an eine SMTP-Adresse:"
    $extern | Select-Object Adresse, WeiterleitungExtern | Format-Table -AutoSize
}
