# Quelle: Skript „M365 Governance“, Modul 03, Lösung zu Aufgabe 6 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All" -NoWelcome
Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All -Property Id,DisplayName |
  ForEach-Object {
    $o = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($o -lt 2) {
      $g = @(Get-MgGroupMember -GroupId $_.Id -All |
             Where-Object { $_.AdditionalProperties.userType -eq 'Guest' }).Count
      if ($g -ge 1) { [pscustomobject]@{ Team = $_.DisplayName; Besitzer = $o; Gaeste = $g } }
    }
  } | Format-Table -AutoSize
