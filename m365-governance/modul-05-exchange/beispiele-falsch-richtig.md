# Falsch und richtig – Modul 05

Kurze Gegenüberstellungen aus dem Skript (Listing-Nummern wie dort). Es ist Kommentar- und Beispieltext, kein ausführbarer Code.

## Listing 35: Weiterleitungen

```text
# FALSCH: Weiterleitung "mal eben" fuer Urlaub nach extern setzen, keine Frist
Set-Mailbox -Identity anna@contoso.com -ForwardingSmtpAddress "anna.privat@example.com"

# RICHTIG: intern an Vertretung weiterleiten, ohne Kopie im eigenen Postfach zu verlieren
Set-Mailbox -Identity anna@contoso.com -ForwardingAddress "vertretung@contoso.com" `
    -DeliverToMailboxAndForward $true
# Frist im Ticket festhalten und nach der Rueckkehr wieder entfernen
```

## Listing 37: Absenderbeschraenkung

```text
# FALSCH: Liste der Geschaeftsleitung nimmt Mail von jedem entgegen
New-DistributionGroup -Name "Geschaeftsleitung" -PrimarySmtpAddress gl@contoso.com

# RICHTIG: nur authentifizierte Absender, Besitzer gesetzt, im Adressbuch verborgen
New-DistributionGroup -Name "Geschaeftsleitung" -PrimarySmtpAddress gl@contoso.com `
    -ManagedBy "assistenz@contoso.com" -MemberJoinRestriction Closed
Set-DistributionGroup -Identity gl@contoso.com -RequireSenderAuthenticationEnabled $true `
    -HiddenFromAddressListsEnabled $true
```

## Listing 39: Muster pruefen

```text
# FALSCH: Muster ohne [GroupName] - die Einstellung funktioniert nicht
$muster = "GRP_[Department]"

# RICHTIG: Platzhalter fuer den Gruppennamen ist Pflicht
$muster = "GRP_[GroupName]_[Department]"
if ($muster -notmatch "\[GroupName\]") { throw "Muster ungueltig" }
```

## Listing 41: Regeln einfuehren

```text
# FALSCH: breite Regel direkt erzwingen, ohne Test und ohne Ausnahme
New-TransportRule -Name "Alles an extern blockieren" -FromScope InOrganization `
    -SentToScope NotInOrganization -RejectMessageReasonText "Nicht erlaubt" -Mode Enforce

# RICHTIG: eng gefasst, mit Ausnahme, zuerst im Testmodus
New-TransportRule -Name "Vertrauliche Betreffs nicht nach extern" `
    -FromScope InOrganization -SentToScope NotInOrganization `
    -SubjectContainsWords "VERTRAULICH" `
    -ExceptIfSentTo "partner@example.com" `
    -RejectMessageReasonText "Vertrauliche Mails duerfen die Organisation nicht verlassen." `
    -Mode AuditAndNotify -Comments "Testmodus bis zur Auswertung"
```

## Listing 43: Berechtigungen

```text
# FALSCH: Rechte an einzelne Personen, AutoMapping an
Add-MailboxPermission -Identity info@contoso.com -User anna@contoso.com -AccessRights FullAccess

# RICHTIG: Rechte an eine Gruppe, deren Mitglieder regelmaessig geprueft werden
Add-MailboxPermission -Identity info@contoso.com -User "SG-Postfach-Info" `
    -AccessRights FullAccess -AutoMapping $false
```

## Listing 45: Hold begrenzen

```text
# FALSCH: unbegrenzter Litigation Hold fuer alle, ohne Dokumentation
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -LitigationHoldEnabled $true

# RICHTIG: Hold fuer bestimmte Personen mit Dauer und Grund
Set-Mailbox -Identity anna@contoso.com -LitigationHoldEnabled $true `
    -LitigationHoldDuration 730 -LitigationHoldOwner "Rechtsabteilung" `
    -RetentionComment "Verfahren Az. 2026-17"
```

## Listing 47: Ausnahmeliste

```text
# FALSCH: ganze Top-Level-Domain-Gruppen pauschal ausnehmen
Set-ExternalInOutlook -AllowList @{Add = "gmail.com","outlook.com"}

# RICHTIG: nur namentlich bekannte Partnerdomaenen, mit Dokumentation im Ticket
Set-ExternalInOutlook -AllowList @{Add = "partner.example.com"}
```

## Listing 49: Vorgehen

```text
# FALSCH: Regel einfach loeschen, weil "vielleicht die Regel schuld ist"
Remove-TransportRule -Identity "Vertrauliche Betreffs nicht nach extern" -Confirm:$false

# RICHTIG: erst nachweisen, welches Ereignis die Nachricht beeinflusst hat
$m = Get-MessageTrace -SenderAddress anna@contoso.com -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date)
$m | ForEach-Object {
    Get-MessageTraceDetail -MessageTraceId $_.MessageTraceId -RecipientAddress $_.RecipientAddress
} | Select-Object Event, Detail
```
