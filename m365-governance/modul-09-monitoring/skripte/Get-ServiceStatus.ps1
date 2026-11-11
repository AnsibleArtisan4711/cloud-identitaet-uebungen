# Quelle: Skript „M365 Governance“, Modul 09, Listing 109 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph- und Exchange-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "ServiceHealth.Read.All","ServiceMessage.Read.All" -NoWelcome

"--- Offene Stoerungen ---"
$offen = Get-MgServiceAnnouncementIssue -Filter "isResolved eq false" -All
if ($offen) {
    $offen | Sort-Object StartDateTime -Descending |
        Select-Object Id, Service, Classification, Status, StartDateTime, Title |
        Format-Table -AutoSize -Wrap
} else {
    "Keine offenen Stoerungen gemeldet."
}

"--- Zustand je Dienst ---"
Get-MgServiceAnnouncementHealthOverview | Select-Object Service, Status | Sort-Object Service |
    Format-Table -AutoSize

$seit = (Get-Date).ToUniversalTime().AddDays(-7).ToString("yyyy-MM-ddTHH:mm:ssZ")
$nachrichten = Get-MgServiceAnnouncementMessage -Filter "lastModifiedDateTime ge $seit" -All
"Nachrichtencenter, neu oder geaendert in 7 Tagen: {0}" -f @($nachrichten).Count
$nachrichten | Where-Object { $_.IsMajorChange } |
    Select-Object Id, Title, ActionRequiredByDateTime | Format-Table -AutoSize -Wrap
