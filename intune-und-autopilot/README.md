# Intune und Autopilot (P29)

Übungsreihe zu Intune und Autopilot: Geräteverwaltung (MDM und MAM), Registrierung und Einschränkungen, Windows Autopilot mit Prüfung der Hardware-Hash-Datei, Konfigurationsprofile, Compliance-Richtlinien, App-Bereitstellung, Updates, Zuweisungen und Filter, Fehlersuche und Einordnung gegenüber Gruppenrichtlinien. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Intune und Autopilot werden nicht ausgeführt; die Umgebung ist ein Lernmodell in Python. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P29 (Reihe „Lehrplan-Prompts“, Datei `P29-intune-und-autopilot.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt, Intune und Windows nicht.** Echt sind die Prüfung der Befehle gegen die Azure CLI 2.93.0 (Hilfetexte), die Prüfung der Autopilot-CSV nach den Regeln aus einem Microsoft-Learn-Suchauszug, SHA-256 und das Lesen von JSON; der Rest ist ein Lernmodell (`intunesim.py`). Nicht ausgeführt: Intune-Mandant, Windows, Hyper-V, PowerShell, `Get-WindowsAutopilotInfo`. Die Ausgaben stehen in den Ordnern `beispiele/`. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Eine Windows-11-VM `win11-1` unter **Hyper-V** am privaten Switch `Lab-Intune` (`10.91.0.0/24`), dazu ein **Test-Tenant** mit Intune-Lizenz (kein produktiver Tenant; Laufzeit und Kosten vorab prüfen). Namen und Netz sind angenommen; das Labor wurde **nicht** aufgebaut. Die Skripte brauchen es nicht und arbeiten unter `/tmp/p29`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Geräteverwaltung: MDM, MAM und Registrierungswege](01-geraeteverwaltung-und-enrollment/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 02 | [Registrierung: Lizenz, MDM-Benutzerbereich, Einschränkungen und Limit](02-registrierung-und-einschraenkungen/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 03 | [Windows Autopilot: Hardware-Hash-Datei, Profile und Modi](03-windows-autopilot/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 04 | [Konfigurationsprofile, Konflikte und Gruppenrichtlinien](04-konfigurationsprofile/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 05 | [Compliance-Richtlinien und Aktionen bei Nichtkonformität](05-compliance-richtlinien/) | 9 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 06 | [App-Bereitstellung: Absichten, Erkennungsregeln und Prüfsumme](06-app-bereitstellung/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 07 | [Windows-Updates: Ringe, Zurückstellung und Frist](07-windows-updates/) (Priorität 2) | 6 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |
| 08 | [Zuweisungen, Filter, Fehlersuche und Abschluss](08-zuweisungen-filter-und-fehlersuche/) | 10,5 h | Skripte im Container ausgeführt; Befehlsprüfung, CSV-Prüfung, SHA-256 und JSON echt, Intune und Autopilot als Modell. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein; `intunesim.py` (Modell) liegt im Kursordner. Benötigt: `python3`; für die Befehlsprüfung zusätzlich die Azure CLI (`pip install azure-cli`; ohne `az` wird die Prüfung übersprungen).

## Hinweise

- Alle Namen, Seriennummern, Hashes und Werte sind erfunden.
- Die Skripte arbeiten nur unter `/tmp/p29`.
- Die Ausgaben stammen vom Modell `intunesim.py`, nicht von Intune.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
