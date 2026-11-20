# Azure-Netzwerk und Azure-Sicherheit (P57)

Übungsreihe zu Azure-Netzwerk und Azure-Sicherheit: virtuelle Netzwerke und Peering, NSG und ASG, Routen mit Azure Firewall, Bastion und VPN Gateway, Private Endpoints und DNS, Key Vault, RBAC und Azure Policy, Defender for Cloud mit Protokollierung sowie Fehlersuche. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Python-Modelle mit CLI-Textdateien; nichts davon wurde in Azure ausgeführt. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P57 (Reihe „Lehrplan-Prompts“, Datei `P57-azure-netzwerk-und-azure-sicherheit.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Nur Python-Modelle ausgeführt, nicht in Azure.** Die Ausgaben in den Ordnern `beispiele/` stammen von vereinfachten Modellen mit erfundenen Werten (Python 3 im Cloud-Container). **Azure-Abonnement, Azure CLI und PowerShell wurden nicht verwendet**: Die Befehle sind Fachwissen und nicht bestätigt. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Ein Azure-Abonnement (Testkonto oder Guthaben) mit Budgetwarnung und ein Windows-11-Client mit Azure CLI und PowerShell (Lehrplan). Das Abonnement wurde **nicht** eingerichtet. Die Python-Modelle laufen auf jedem Rechner mit Python 3.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Virtuelle Netzwerke, Subnetze und Peering](01-virtuelle-netzwerke-und-peering/) | 10,5 h | Modell ausgeführt. |
| 02 | [Netzwerksicherheitsgruppen und Anwendungssicherheitsgruppen](02-nsg-und-asg/) | 10,5 h | Modell ausgeführt. |
| 03 | [Routen, Azure Firewall, Bastion und VPN Gateway](03-routen-firewall-bastion-und-vpn/) | 9 h | Modell ausgeführt. |
| 04 | [Private Endpoints und DNS](04-private-endpoints-und-dns/) | 9 h | Modell ausgeführt. |
| 05 | [Key Vault](05-key-vault/) (Priorität 2) | 7,5 h | Modell ausgeführt. |
| 06 | [RBAC und Azure Policy](06-rbac-und-azure-policy/) | 10,5 h | Modell ausgeführt. |
| 07 | [Defender for Cloud, Protokollierung und Überwachung](07-defender-for-cloud-und-protokollierung/) | 9 h | Modell ausgeführt. |
| 08 | [Fehlersuche im Azure-Netzwerk](08-fehlersuche-im-azure-netzwerk/) | 9 h | Modell ausgeführt. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner.

## Hinweise

- Die Python-Modelle verändern nichts am System.
- Alle Namen, Adressen (`10.57.0.0/16`), Beträge und Daten sind erfunden. **Zugangsdaten gehören nie in ein Repository.**
- Die CLI-Textdateien wurden nicht ausgeführt und nicht gegen die Dokumentation geprüft. Beim Nachvollziehen im Abonnement entstehen eventuell Kosten (Firewall, Gateway, Bastion): Budgetwarnung einrichten und Ressourcengruppen danach löschen.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
