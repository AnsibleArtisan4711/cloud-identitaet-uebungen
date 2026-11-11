# Quellen

Dieses Verzeichnis ist aus dem Quellenverzeichnis des Skripts „M365 Governance“ übernommen (Stand der Recherche dort: Oktober 2026). **Die Links wurden für dieses Repository nicht erneut geprüft;** Microsoft verschiebt Seiten gelegentlich. Die Texte der Microsoft-Dokumentation sind nicht Teil dieses Repositories. Maßgeblich ist immer die aktuelle Dokumentation von Microsoft.

Aussage des Skripts zur Quellenlage: Im Projektwissen lagen keine Kursunterlagen vor; der Inhalt beruht auf dem Lehrplan, auf Recherche in der öffentlichen Microsoft-Dokumentation und auf allgemeinem Fachwissen. Die Skripte wurden nicht gegen einen echten Tenant ausgeführt.


## Tatsächlich abgerufen (Seite vollständig gelesen)

- Microsoft Entra ID Governance, Überblick: <https://learn.microsoft.com/en-us/entra/id-governance/identity-governance-overview>
- Entitlement Management, Überblick: <https://learn.microsoft.com/en-us/entra/id-governance/entitlement-management-overview>
- Access Reviews, Überblick: <https://learn.microsoft.com/en-us/entra/id-governance/access-reviews-overview>
- Lifecycle Workflows, Überblick: <https://learn.microsoft.com/en-us/entra/id-governance/what-are-lifecycle-workflows>
- Privileged Identity Management, Konfiguration und Überblick: <https://learn.microsoft.> com/en-us/entra/id-governance/privileged-identity-management/pim-configure
- Best Practices für Entra-Rollen: <https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices>
- Notfallzugriffskonten: <https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access>
- Ablaufrichtlinie für Microsoft-365-Gruppen: <https://learn.microsoft.com/en-us/microsoft-365/solutions/microsoft-365-groups-expiration-policy>
- Wer darf Microsoft-365-Gruppen erstellen: <https://learn.microsoft.com/en-us/microsoft-365/solutions/manage-creation-of-groups>
- Namensrichtlinie für Gruppen: <https://learn.microsoft.com/en-us/entra/identity/users/groups-naming-policy>
- Teams-Governance und dynamische Gruppen: <https://learn.microsoft.com/en-us/microsoftteams/teams-dynamic-group-governance>
- Microsoft-365-Gasteinstellungen (Referenz): <https://learn.microsoft.com/en-us/microsoft-365/solutions/microsoft-365-guest-settings>
- Ende des Lebenszyklus von Gruppen, Teams, Websites und Viva Engage: <https://learn.> microsoft.com/en-us/microsoft-365/solutions/end-life-cycle-groups-teams-s ites-viva-engage
- Freigegebene Kanäle in Teams: <https://learn.microsoft.com/en-us/microsoftteams/shared-channels>
- Externe Freigabe in SharePoint und OneDrive, Überblick: <https://learn.microsoft.com/en-us/sharepoint/external-sharing-overview>
- Berechtigungen in SharePoint-Websites (Referenz): <https://learn.microsoft.com/en-us/sharepoint/site-permissions>
- Hubwebsites planen: <https://learn.microsoft.com/en-us/sharepoint/planning-hub-sites>
- Speicherlimits für Websites verwalten: <https://learn.microsoft.com/en-us/sharepoint/manage-site-collection-storage-limits>
- Restricted Access Control: <https://learn.microsoft.com/en-us/sharepoint/restricted-access-control>
- Vertraulichkeitsbezeichnungen für Teams, Gruppen und Websites: <https://learn.microsoft.com/en-us/purview/sensitivity-labels-teams-groups-sites>
- Microsoft Purview, „Learn about retention policies and retention labels“ (Etappe 2, Modul 6): <https://learn.microsoft.com/purview/retention>

## Als Suchauszug oder Codebeispiel gelesen (nicht vollständig abgerufen)

- Lebenszyklus von SharePoint-Websites (SharePoint Advanced Management): <https://learn.microsoft.com/en-us/sharepoint/site-lifecycle-management>
- Richtlinie für inaktive Websites: <https://learn.microsoft.com/en-us/sharepoint/inactive-site-policy>
- Websitebestätigungen anfordern: <https://learn.microsoft.com/en-us/sharepoint/request-site-attestations>
- Microsoft 365 Archive, Überblick: <https://learn.microsoft.com/en-us/microsoft-365/archive/archive-overview>
- Codebeispiele auf den Referenzseiten der Cmdlets für Zugriffsüberprüfungen, PIM-Zuweisungsanfragen, Lifecycle Workflows, Zugriffspaket-Richtlinien, Einladungen, Anmeldeprotokolle, Teams-Archivierung und Set-SPOSite. Beispiel: <https://learn.microsoft.com/powershell/module/microsoft.graph.identity.governance/new-mgidentitygovernanceaccessreviewdefinition?view=graph-powershell-1.0>
- Modul 7 und 9, Audit (Suchauszüge): Microsoft Purview, „Learn about auditing solutions“ (<https://learn.microsoft.com/purview/audit-solutions-overview>), „Manage audit log retention policies“ (<https://learn.microsoft.com/purview/audit-log-retention-policies>), „Get started with auditing solutions“ (<https://learn.microsoft.com/purview/audit-get-started>), „Search the audit log“ (<https://learn.microsoft.com/purview/audit-search>)
- Modul 9, Entra-Protokolle (Suchauszüge): „Microsoft Entra data retention“ (<https://learn.microsoft.com/entra/identity/monitoring-health/reference-reports-data-retention>), „Microsoft Entra audit logs API overview“ (<https://learn.microsoft.com/graph/api/resources/azure-ad-auditlog-overview>), „Frequently asked questions around Microsoft Entra monitoring and health“ (<https://learn.microsoft.com/entra/identity/monitoring-health/reports-faq>)
- Modul 9, Nutzungsberichte (Suchauszüge): „Microsoft 365 admin center usage reports overview“ (<https://learn.microsoft.com/microsoft-365/admin/activity-reports/activity-reports>), „Working with Microsoft 365 usage reports in Microsoft Graph“ (<https://learn.microsoft.com/graph/api/resources/report>), „Microsoft Teams analytics and reporting“ (<https://learn.microsoft.com/microsoftteams/teams-analytics-and-reports/teams-reporting-reference>), Graph-Berichtsfunktionen für aktive Benutzer (<https://learn.microsoft.com/graph/api/reportroot-getoffice365activeusercounts>)
- Module 6 bis 8: Die Vorrecherche zu Sensitivity Labels, DLP, Records, Information Barriers, Data Map, eDiscovery, Compliance Manager, Insider Risk, Communication Compliance, Secure Score, bedingtem Zugriff, Authentifizierungsmethoden, Intune-Konformität und Dienstintegrität stützte sich auf die Suche in Microsoft Learn und auf Codebeispiele; die Ergänzungsboxen dieser Module geben diesen Stand sinngemäß wieder. Cmdlet-Parameter, Rollengruppennamen, Operationsnamen im Überwachungsprotokoll und Berichtsspalten sind vor produktivem Einsatz gegen die aktuelle Referenz und die echte Ausgabe zu prüfen.
- Exchange Online limits (Postfachgrößen, Shared Mailbox 50 GB): <https://learn.microsoft.com/office365/servicedescriptions/exchange-online-service-description/exchange-online-limits>
- About shared mailboxes in Microsoft 365: <https://learn.microsoft.com/microsoft-365/admin/email/about-shared-mailboxes>
- Shared mailboxes in Exchange Online: <https://learn.microsoft.com/exchange/collaboration-exo/shared-mailboxes>
- Set-ExternalInOutlook: <https://learn.microsoft.com/powershell/module/exchangepowershell/set-externalinoutlook>
- Mail flow rules in Exchange Online: <https://learn.microsoft.com/exchange/security-and-compliance/mail-flow-rules/mail-flow-rules>
- Manage mail flow rules in Exchange Online: <https://learn.microsoft.com/exchange/security-and-compliance/mail-flow-rules/manage-mail-flow-rules>
- Test mail flow rules in Exchange Online: <https://learn.microsoft.com/exchange/security-and-compliance/mail-flow-rules/test-mail-flow-rules>
- Mail flow rule too large (8 KB): <https://learn.microsoft.com/troubleshoot/exchange/email-delivery/transport-rule-not-created-because-too-large>
- Naming policy für Microsoft 365-Gruppen (Entra): <https://learn.microsoft.com/entra/identity/users/groups-naming-policy>
- Microsoft 365 Groups and Teams naming policy: <https://learn.microsoft.com/microsoft-365/enterprise/groups-naming-policy>
- Learn about auto-expanding archiving: <https://learn.microsoft.com/purview/autoexpanding-archiving>
- Module 10 bis 12 (Suchauszüge aus Microsoft Learn, Seiten nicht vollständig abgerufen; die genauen Adressen sind in Microsoft Learn über die Titel zu finden): Ablaufrichtlinie für Microsoft-365-Gruppen und groupLifecyclePolicy; Wiederherstellen gelöschter Gruppen; Ablauf und Erneuerung von Teams; Graph-Referenz „Create team“, „Archive team“ und „Create a team from a group“; Richtlinien für inaktive Websites, Besitz und Bestätigung sowie Microsoft 365 Archive; Berichte zur Datenzugriffs-Governance; Microsoft-Graph-Dokumentation zu Drosselung (Throttling), Paging, JSON-Batching und App-only-Authentifizierung; Tenant Configuration Management (Snapshots, Monitore, Drift); Architekturbeispiel zu Microsoft365DSC; Microsoft 365 Backup (Überblick, Wiederherstellung, Neuerungen, Pay-as-you-go); Datenresilienz von SharePoint und OneDrive; Wiederherstellbarkeit in Microsoft Entra; Papierkorb von SharePoint-Websitesammlungen; Exchange „Recoverable Items“ und Datenlöschung; Champions-Programme für Teams, Power Platform und Copilot Studio.
- Zeitangaben, Grenzwerte und Funktionsumfang in Modul 10 bis 12 (zum Beispiel Wiederherstellungsfristen, Limits von Tenant Configuration Management und Microsoft 365 Backup) geben den Stand der Suchauszüge vom Oktober 2026 wieder und ändern sich häufig. Cmdlet-Namen und Parameter wurden nicht gegen einen Tenant getestet.

## Weiterführend (nicht abgerufen)

- Microsoft Learn, Lernpfad „Implement lifecycle management and governance for Microsoft Teams“: <https://learn.microsoft.com/training/modules/implement-lifecycle-management-governance-for-microsoft-teams/>
- Microsoft Learn, Planung der Teams-Governance: <https://learn.microsoft.com/microsoftteams/plan-teams-governance>
- Microsoft Learn, SharePoint Advanced Management, Überblick: <https://learn.microsoft.com/sharepoint/advanced-management>
- Microsoft Purview, Sensitivity Labels: <https://learn.microsoft.com/purview/sensitivity-labels>
- Microsoft Purview, Data Loss Prevention: <https://learn.microsoft.com/purview/dlp-learn-about-dlp>
- Microsoft Purview, Records Management: <https://learn.microsoft.com/purview/records-management>
- Microsoft Purview, Information Barriers: <https://learn.microsoft.com/purview/information-barriers>
- Microsoft Purview, eDiscovery: <https://learn.microsoft.com/purview/ediscovery>
- Microsoft Purview, Compliance Manager: <https://learn.microsoft.com/purview/compliance-manager>
- Microsoft Purview, Insider Risk Management: <https://learn.microsoft.com/purview/insider-risk-management>
- Microsoft Purview, Communication Compliance: <https://learn.microsoft.com/purview/communication-compliance>
- Microsoft Entra, Conditional Access: <https://learn.microsoft.com/entra/identity/conditional-access/overview>
- Microsoft Defender, Secure Score: <https://learn.microsoft.com/defender-xdr/microsoft-secure-score>
- Microsoft Intune, Device Compliance: <https://learn.microsoft.com/intune/intune-service/protect/device-compliance-get-started>
- Hinweis zu den Weiterführend-Adressen von Modul 6 bis 9: Die Seiten wurden nicht abgerufen, und die Adressen wurden nicht einzeln geprüft; Microsoft verschiebt Seiten gelegentlich. Rechtliche Themen (DSGVO, NIS-2, DORA, Beschäftigtendatenschutz) beruhen auf allgemeinem Fachwissen, wurden nicht recherchiert und sind keine Rechtsberatung. Hinweis: Die Seiten ändern sich laufend; Funktionsumfang, Lizenzbedingungen und Bezeichnungen im Portal können vom Stand dieses Skripts abweichen. Rechtliche Themen (zum Beispiel DSGVO, Aufbewahrung) sind keine Rechtsberatung.
