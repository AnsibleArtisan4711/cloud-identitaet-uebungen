# Quelle: Skript „M365 Governance“, Modul 05, Listing 44 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-ExchangeOnline

"== Aufbewahrung gelöschter Elemente (Abweichung vom Standard) =="
Get-Mailbox -ResultSize Unlimited |
    Where-Object { $_.RetainDeletedItemsFor.Days -ne 14 } |
    Select-Object PrimarySmtpAddress, RetainDeletedItemsFor |
    Format-Table -AutoSize
"== Postfaecher mit Litigation Hold =="
Get-Mailbox -ResultSize Unlimited -Filter "LitigationHoldEnabled -eq `$true" |
    Select-Object PrimarySmtpAddress, LitigationHoldDuration, LitigationHoldDate |
    Format-Table -AutoSize

"== Inaktive Postfaecher =="
Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited |
    Select-Object DisplayName, PrimarySmtpAddress, WhenSoftDeleted |
    Format-Table -AutoSize
