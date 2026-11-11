# Quelle: Skript „M365 Governance“, Modul 05, Lösung zu Aufgabe 7 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | ForEach-Object {
    $pm = $_
    $personen = Get-MailboxPermission -Identity $pm.PrimarySmtpAddress |
        Where-Object { $_.User -notlike "NT AUTHORITY*" -and -not $_.IsInherited -and -not $_.Deny } |
        ForEach-Object {
            $r = Get-Recipient -Identity $_.User -ErrorAction SilentlyContinue
            if ($r -and $r.RecipientTypeDetails -in "UserMailbox","MailUser") { $_.User }
        }
    if ($personen) { [pscustomobject]@{ Postfach = $pm.PrimarySmtpAddress; DirektBerechtigt = ($personen -join "; ") } }
}
