# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors (privater Switch `Lab-Entra`, `dc1` mit Active Directory, `client1`) und eines Test-Tenants | – | laut Lehrplan aufbauen und prüfen; Laufzeit und Kosten des Test-Tenants vorab prüfen |
| 01 | `az ad user create/list`, `az rest` (Parameter gegen den Hilfetext); `entrasim.py domain/user` | Parameter **echt** geprüft (Azure CLI 2.93.0, Hilfetext); Mandant, Domänenprüfung **Modell** | im Test-Tenant mit `az ad user list` nachvollziehen |
| 02 | `az ad group create`, `az ad group member add`, `az role assignment create` (Parameter); `entrasim.py group/role` | Parameter **echt** geprüft; Regelauswertung und Rollen **Modell** (Rollenzuordnung erfunden) | im Test-Tenant dynamische Gruppen anlegen (P1/P2 erforderlich, nicht geprüft) |
| 03 | `az ad user show/list` (Parameter); `entrasim.py ad/connect` | Parameter **echt** geprüft; **Entra Connect, AD und PowerShell nicht ausgeführt**; Synchronisation **Modell** | Entra Connect im Labor installieren und das Verhalten (UPN-Rückfall) prüfen |
| 04 | `dsregcmd /status` (Windows); `entrasim.py device` | **dsregcmd nicht ausgeführt**; Beispieldateien **erfunden**; Auswertung **Modell** | auf einem Labor-Client `dsregcmd /status` ausführen |
| 05 | `entrasim.py mfa selftest/code/verify` (TOTP nach RFC 6238, HMAC-SHA-1) | **Echt** gerechnet und gegen die sechs Testwerte der RFC geprüft; Authentifizierungs-App und Entra ID nicht beteiligt | echte Authenticator-App im Test-Tenant einrichten |
| 06 | `az rest` (Parameter); `entrasim.py ca` | Parameter **echt** geprüft; Richtlinienformat und Auswertung **Modell**; Lizenzstand aus Suchauszug gelesen | im Test-Tenant Richtlinien zuerst im Modus „Nur Bericht“ anlegen |
| 07 | `az rest` (Parameter); `entrasim.py pim` | Parameter **echt** geprüft; PIM **Modell**; Lizenzstand aus Suchauszug gelesen | im Test-Tenant mit P2-Lizenz prüfen (Priorität 2) |
| 08 | `az ad app create`, `az ad app credential reset`, `az ad sp create` (Parameter); `entrasim.py app/token` (RS256 mit PyJWT 2.15.0 und cryptography 50.0.1) | Parameter und Token-Signatur **echt**; Registrierung **Modell**; Token **nicht** von Entra ID | im Test-Tenant echte Registrierung und Token prüfen |
