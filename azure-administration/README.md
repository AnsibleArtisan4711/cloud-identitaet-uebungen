# Azure Administration (P27)

Übungsreihe zur Azure-Administration: Abonnements, Verwaltungsgruppen und Ressourcengruppen, Rollen und Bereiche (RBAC), virtuelle Netzwerke, virtuelle Maschinen und ARM-Vorlagen, Speicher, Sicherung und Überwachung, App Service und Container im Überblick, Azure Policy, Kosten und Budgets. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Azure wird nicht ausgeführt; die Umgebung ist ein Lernmodell in Python. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P27 (Reihe „Lehrplan-Prompts“, Datei `P27-azure-administration.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt, Azure nicht.** Echt geprüft ist, ob Befehle und Parameter im Hilfetext der Azure CLI 2.93.0 existieren (offline, ohne Anmeldung), dazu Rechnungen und JSON in Python; die Umgebung ist ein Lernmodell (`azsim.py`) mit erfundenen Größen, Preisen und Kontingenten. Nicht ausgeführt: Azure-Abonnement, `az login`, Portal, Bicep, PowerShell. Von der AZ-104-Studienanleitung wurde nur ein Suchauszug gelesen. Die Ausgaben stehen in den Ordnern `beispiele/`. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Ein **Test-Tenant** (Microsoft-365-Entwickler- oder Testzugang), kein produktiver Tenant; Laufzeit und Kosten vorab prüfen; Kostenlimit und Budgetwarnung einrichten; Ressourcen nach jeder Übung löschen. Das Labor wurde **nicht** aufgebaut. Die Skripte brauchen keinen Zugang und arbeiten unter `/tmp/p27`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Abonnements, Verwaltungsgruppen und Ressourcengruppen](01-abonnements-und-ressourcengruppen/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 02 | [Identitäten und rollenbasierte Zugriffssteuerung (RBAC)](02-identitaeten-und-rbac/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 03 | [Virtuelle Netzwerke, Subnetze und Peering](03-virtuelle-netzwerke/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 04 | [Virtuelle Maschinen und ARM-Vorlagen](04-virtuelle-maschinen-und-vorlagen/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 05 | [Speicher: Konten, Redundanz, Zugriff und Lebenszyklus](05-speicher/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 06 | [Sicherung und Überwachung](06-sicherung-und-ueberwachung/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 07 | [App Service und Container im Überblick](07-app-service-und-container/) (Priorität 2) | 6 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |
| 08 | [Azure Policy, Kosten und Abschlussprojekt](08-richtlinien-kosten-und-abschluss/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung echt (Azure CLI 2.93.0, Hilfetexte), Azure als Modell. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein; `azsim.py` (Modell) liegt im Kursordner. Benötigt: `python3`; für die Befehlsprüfung zusätzlich die Azure CLI (`pip install azure-cli`; ohne `az` wird die Prüfung übersprungen).

## Hinweise

- Alle Namen, Adressen und Beträge sind erfunden; die Abonnement-ID ist ein Platzhalter.
- Die Skripte arbeiten nur unter `/tmp/p27` und räumen am Ende auf.
- Die Ausgaben stammen vom Modell `azsim.py`, nicht von Azure (`azsim` ersetzt hier `az`).

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
