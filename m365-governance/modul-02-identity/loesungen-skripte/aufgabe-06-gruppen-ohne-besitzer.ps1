# Quelle: Skript „M365 Governance“, Modul 02, Lösung zu Aufgabe 6 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,CreatedDateTime |
  ForEach-Object {
    $n = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($n -lt 2) {
      [pscustomobject]@{ Name = $_.DisplayName; AnzahlBesitzer = $n; Erstellt = $_.CreatedDateTime }
    }
  } | Export-Csv ".\gruppen-ohne-besitzer.csv" -NoTypeInformation -Encoding UTF8
