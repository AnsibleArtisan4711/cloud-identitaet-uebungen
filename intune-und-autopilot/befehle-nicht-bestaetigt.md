# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors (privater Switch `Lab-Intune`, VM `win11-1`) und eines Test-Tenants mit Intune-Lizenz (Namen angenommen) | – | laut Lehrplan aufbauen und prüfen; Laufzeit und Kosten des Test-Tenants vorab prüfen |
| 01 | `az rest` (Parameter gegen den Hilfetext); `intunesim.py enroll decide` | Parameter **echt** geprüft (Azure CLI 2.93.0, Hilfetext); Empfehlung **Modell** nach Fachwissen | im Test-Tenant die Lizenzzuweisung prüfen |
| 02 | `az rest` (Parameter); `intunesim.py user/restrict/enroll try` | Parameter **echt** geprüft; Registrierung **Modell**; Gerätelimit 3 **erfunden** | im Test-Tenant Einschränkungen und MDM-Benutzerbereich mit dem Modell vergleichen |
| 03 | `Get-WindowsAutopilotInfo` (PowerShell); `intunesim.py ap check-csv/import/profile/boot` | CSV-Prüfung **echt** nach den Regeln aus Suchauszug von Microsoft Learn; **PowerShell und Windows nicht ausgeführt**; Hashes **erfunden**; Profilzuordnung **Modell** | auf einem Labor-Gerät echten Hash erzeugen und importieren |
| 04 | `intunesim.py cfg` (JSON, Zusammenführung) | JSON **echt** gelesen; Zusammenführung und Konflikte **Modell** | im Test-Tenant widersprüchliche Profile zuweisen und das Verhalten prüfen |
| 05 | `intunesim.py comp` (JSON, Auswertung) | JSON **echt** gelesen; Auswertung **Modell**; Aktionen und Standardwerte aus Suchauszug gelesen | im Test-Tenant eine Richtlinie mit Aktionen anlegen |
| 06 | `sha256sum`, `intunesim.py app sha256/intent/detect` | SHA-256 **echt** gerechnet; Absichten und Erkennung **Modell**; Win32-Verpackung **nicht** ausgeführt | im Test-Tenant eine Win32-App verpacken und zuweisen |
| 07 | `az rest` (Parameter); `intunesim.py upd` | Parameter **echt** geprüft; Rechnung **Modell**, Werte erfunden | im Test-Tenant Update-Ringe prüfen (Priorität 2) |
| 08 | `intunesim.py assign/diag` (JSON) | JSON **echt** gelesen; Auswertung **Modell**; Vorrang aus Suchauszug gelesen | im Test-Tenant die Zuweisungsauswertung eines Geräts nachvollziehen |
