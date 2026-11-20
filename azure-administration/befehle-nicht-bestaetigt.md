# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Test-Tenants (Abonnement, Kostenlimit, Budgetwarnung, Azure CLI) | – | laut Lehrplan aufbauen; Laufzeit und Kosten vorab prüfen |
| 01 | `az account management-group create`, `az group create`, `az lock create`, `az tag update` (Parameter gegen den Hilfetext); `azsim.py mg/sub/group/lock` | Parameter **echt** geprüft (Azure CLI 2.93.0, Hilfetext); Hierarchie, Sperre **Modell** | im Test-Tenant mit `az` anlegen; Hierarchietiefe in der Dokumentation prüfen |
| 02 | `az role assignment create/list`, `az role definition list` (Parameter); `azsim.py role assign/list/check` | Parameter **echt** geprüft; Rollen (Auszug) und Vererbung **Modell** | im Test-Tenant mit `az role assignment list --all` prüfen |
| 03 | `az network vnet create`, `vnet subnet create`, `vnet peering create`, `network nsg rule create` (Parameter); Rechnung mit Python `ipaddress` | Parameter und Adressrechnung **echt**; Anlegen, Peering und NSG **Modell** | im Test-Tenant anlegen und Peering ausprobieren |
| 04 | `az vm create/resize/list-sizes`, `az deployment group validate/what-if` (Parameter); JSON mit Python | Parameter und JSON **echt**; Größen, Kontingent und Preise **Modell, erfunden** | im Test-Tenant mit `az deployment group what-if` prüfen |
| 05 | `az storage account create/generate-sas`, `az storage container create`, `az storage account management-policy create` (Parameter); HMAC-SHA256 mit Python | Parameter und HMAC **echt**; Konten, Redundanz, Token und Lebenszyklus **Modell** (Token ist **nicht** das echte SAS-Format) | im Test-Tenant mit echtem SAS und Lebenszyklusregel prüfen |
| 06 | `az backup vault create`, `az backup protection enable-for-vm`, `az backup restore restore-disks`, `az monitor metrics alert create`, `az monitor action-group create` (Parameter) | Parameter **echt** geprüft; Aufbewahrung und Alarm **Modell** | im Test-Tenant Sicherung und Alarm einrichten (Kosten beachten) |
| 07 | `az appservice plan create`, `az webapp create`, `az webapp deployment slot swap`, `az monitor autoscale create`, `az container create` (Parameter) | Parameter **echt** geprüft; Autoskalierung, Slot-Tausch und Preise **Modell, erfunden** | im Test-Tenant mit echtem Plan und Slot prüfen (Priorität 2) |
| 08 | `az policy definition create`, `az policy assignment create`, `az consumption budget create`, `az tag create` (Parameter); JSON mit Python | Parameter und JSON **echt**; Richtlinienprüfung und Budget **Modell** | Richtlinien im Test-Tenant mit Wirkung audit zuerst erproben |
