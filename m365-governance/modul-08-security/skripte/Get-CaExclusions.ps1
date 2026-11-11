# Quelle: Skript „M365 Governance“, Modul 08, Listing 94 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Policy.Read.All","Group.Read.All" -NoWelcome

$zeilen = foreach ($p in Get-MgIdentityConditionalAccessPolicy -All) {
    $u = $p.Conditions.Users
    foreach ($id in $u.ExcludeUsers) {
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Benutzer"; Name = $id; Mitglieder = $null }
    }
    foreach ($gid in $u.ExcludeGroups) {
        $g = Get-MgGroup -GroupId $gid -ErrorAction SilentlyContinue
        $n = @(Get-MgGroupMember -GroupId $gid -All -ErrorAction SilentlyContinue).Count
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Gruppe"
                           Name = $(if ($g) { $g.DisplayName } else { $gid }); Mitglieder = $n }
    }
    foreach ($rid in $u.ExcludeRoles) {
        [pscustomobject]@{ Richtlinie = $p.DisplayName; Art = "Rolle"; Name = $rid; Mitglieder = $null }
    }
}

$zeilen | Sort-Object Richtlinie, Art | Format-Table -AutoSize

$direkt = $zeilen | Where-Object Art -eq "Benutzer"
if ($direkt) {
    Write-Warning "$(@($direkt).Count) direkte Benutzerausschluesse (Notfallkonten ausgenommen pruefen)."
}
