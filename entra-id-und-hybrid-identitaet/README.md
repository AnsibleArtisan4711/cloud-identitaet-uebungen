# Entra ID und Hybrid-Identität (P28)

Übungsreihe zu Entra ID und Hybrid-Identität: Mandant und Domänen, Gruppen und Rollen, Entra Connect und Synchronisation, Hybrid Join, Mehrfaktor-Authentifizierung, Bedingter Zugriff mit Lizenzabhängigkeit, Privileged Identity Management im Überblick, Anwendungsregistrierungen und Token. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Entra ID und Active Directory werden nicht ausgeführt; die Umgebung ist ein Lernmodell in Python. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P28 (Reihe „Lehrplan-Prompts“, Datei `P28-entra-id-und-hybrid-identitaet.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt, Entra ID und Active Directory nicht.** Echt sind die Prüfung der Befehle gegen die Azure CLI 2.93.0 (Hilfetexte), TOTP nach RFC 6238 (gegen die RFC-Testwerte geprüft) und die Token-Signatur (PyJWT, cryptography); der Rest ist ein Lernmodell (`entrasim.py`). Nicht ausgeführt: Entra-Mandant, Entra Connect, Windows Server, `dsregcmd`, PowerShell, Hyper-V. Von Microsoft Learn wurden nur Suchauszüge zu Lizenzen gelesen. Die Ausgaben stehen in den Ordnern `beispiele/`. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Ein Domänencontroller `dc1` (Windows Server mit Active Directory) und ein Windows-Client `client1` unter **Hyper-V** am privaten Switch `Lab-Entra` (`10.90.0.0/24`), dazu ein **Test-Tenant** (kein produktiver Tenant; Laufzeit und Kosten vorab prüfen). Das Labor wurde **nicht** aufgebaut. Die Skripte brauchen es nicht und arbeiten unter `/tmp/p28`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Aufbau von Entra ID: Mandant, Domänen und Benutzer](01-entra-id-aufbau/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 02 | [Gruppen, dynamische Mitgliedschaft und Verwaltungsrollen](02-benutzer-gruppen-geraete-und-rollen/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 03 | [Entra Connect: Synchronisation und Anmeldemethoden](03-entra-connect-und-synchronisation/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 04 | [Geräte: Registrierung, Einbindung und Hybrid Join](04-hybrid-join-und-geraete/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 05 | [Mehrfaktor-Authentifizierung und Einmalkennwörter](05-mehrfaktor-authentifizierung/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 06 | [Bedingter Zugriff](06-bedingter-zugriff/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 07 | [Privileged Identity Management im Überblick](07-privileged-identity-management/) (Priorität 2) | 6 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |
| 08 | [Anwendungsregistrierungen, Token und Abschlussprojekt](08-anwendungsregistrierungen-und-abschluss/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, TOTP und Token echt, Entra ID und Active Directory als Modell. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein; `entrasim.py` (Modell) liegt im Kursordner. Benötigt: `python3` mit PyJWT und cryptography (`pip install pyjwt cryptography`); für die Befehlsprüfung zusätzlich die Azure CLI (`pip install azure-cli`; ohne `az` wird die Prüfung übersprungen).

## Hinweise

- Alle Namen, Domänen und Werte sind erfunden (Domänen mit `.example` und `.test`).
- Die Skripte arbeiten nur unter `/tmp/p28` und räumen am Ende auf.
- Die Ausgaben stammen vom Modell `entrasim.py`, nicht von Entra ID; die Schlüssel in Modul 8 werden bei jedem Lauf neu erzeugt.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
