# Quelle: Skript „M365 Governance“, Modul 05, Listing 42 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Adresse,
    [Parameter(Mandatory)][string]$Berechtigtengruppe
)

Connect-ExchangeOnline
Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome

New-Mailbox -Shared -Name $Name -DisplayName $Name -PrimarySmtpAddress $Adresse | Out-Null

Add-MailboxPermission -Identity $Adresse -User $Berechtigtengruppe `
    -AccessRights FullAccess -AutoMapping $false | Out-Null
Add-RecipientPermission -Identity $Adresse -Trustee $Berechtigtengruppe `
    -AccessRights SendAs -Confirm:$false | Out-Null

# Direkte Anmeldung am Konto des Postfachs blockieren
Update-MgUser -UserId $Adresse -AccountEnabled:$false

Get-MailboxPermission -Identity $Adresse |
    Where-Object { $_.User -ne "NT AUTHORITY\SELF" } |
    Format-Table User, AccessRights, IsInherited -AutoSize
