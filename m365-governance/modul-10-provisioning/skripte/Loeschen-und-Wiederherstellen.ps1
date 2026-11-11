# Quelle: Skript „M365 Governance“, Modul 10, Listing 130 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.ReadWrite.All" -NoWelcome

# Loeschen (vorlaeufig, 30 Tage wiederherstellbar)
Remove-MgGroup -GroupId $gruppenId

# Geloeschte Gruppen anzeigen
Get-MgDirectoryDeletedItemAsGroup | Select-Object Id, DisplayName, DeletedDateTime

# Wiederherstellen innerhalb der Frist
Restore-MgDirectoryDeletedItem -DirectoryObjectId $gruppenId
