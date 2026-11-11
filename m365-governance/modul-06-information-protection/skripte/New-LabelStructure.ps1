# Quelle: Skript „M365 Governance“, Modul 06, Listing 50 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Purview- und SharePoint-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-IPPSSession

New-Label -DisplayName "Intern" -Name "Intern" `
    -Tooltip "Informationen fuer Mitarbeitende, nicht fuer die Oeffentlichkeit." `
    -ContentType "File, Email" `
    -ApplyContentMarkingFooterEnabled $true `
    -ApplyContentMarkingFooterText "Intern" `
    -ApplyContentMarkingFooterFontSize 9

New-Label -DisplayName "Vertraulich" -Name "Vertraulich" `
    -Tooltip "Geschaeftskritisch, z. B. Vertraege, Preise, Personaldaten." `
    -ContentType "File, Email" `
    -ApplyContentMarkingFooterEnabled $true `
    -ApplyContentMarkingFooterText "Vertraulich" `
    -ApplyContentMarkingFooterFontSize 9

New-LabelPolicy -Name "Standard-Labelrichtlinie" `
    -Labels "Intern","Vertraulich" `
    -ExchangeLocation All `
    -AdvancedSettings @{ requiredowngradejustification = "true" }

Get-Label | Select-Object DisplayName, Priority, ContentType
