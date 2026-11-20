# Anmerkungen zum Lehrplan P28

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Entra ID, Entra Connect und Active Directory wurden nicht ausgeführt (kein Mandant, kein Domänencontroller, kein `az login`). Echt sind nur die Befehlsprüfung gegen die Azure CLI 2.93.0 (Hilfetexte), TOTP nach RFC 6238 und die Token-Signatur; alles Übrige ist ein Modell (`entrasim.py`). | Im Labor und Test-Tenant ausführen und die Ausgaben mit dem Modell vergleichen. |
| 2 | alle | **Quellen und Lizenzen:** Gelesen wurden nur Suchauszüge (20.11.2026) von Microsoft-Learn-Seiten zu Lizenzen (Entra, Bedingter Zugriff, MFA, PIM/Governance) und zu Autopilot. Alle übrigen Aussagen sind Fachwissen und nicht bestätigt. Portalmenüs wurden nicht geprüft und nicht beschrieben; Lizenzpläne ändern sich. | Lizenzseiten vor der Anwendung vollständig lesen. |
| 3 | 02 | **Rollen:** Die Zuordnung von Aktionen zu Rollen im Modell ist erfunden. | Echte Rollenberechtigungen in der Dokumentation nachlesen. |
| 4 | 03 | **Entra Connect:** Rückfall auf die Standarddomäne, Quellanker und Delta-Verhalten sind Fachwissen und im Modell vereinfacht. | Im Labor mit echtem Entra Connect prüfen. |
| 5 | 04 | **dsregcmd:** Die Beispieldateien sind nachgebaut; Feldnamen sind Fachwissen und nicht geprüft. | Auf einem Windows-Client ausführen. |
| 6 | 06 | **Richtlinienformat:** Das JSON-Format ist eigen und nicht das von Microsoft Graph; Standorte, Sitzungssteuerung und Authentifizierungsstärken fehlen. | Echte Richtlinien im Modus „Nur Bericht“ erproben. |
| 7 | 07 | **Priorität:** Modul 7 ist Priorität 2 und enthält das einzige PIM-Thema des Lehrplans; die Grenze von 480 Minuten ist erfunden. | Bei Bedarf an PIM nicht weglassen. |
| 8 | 08 | **Token:** Aussteller, Zielgruppe und Kennungen sind erfunden; echte Entra-Ansprüche wurden nicht gelesen. Fehlermeldungen stammen von PyJWT 2.15.0. | Echte Token im Test-Tenant mit einem Dekoder lesen. |
