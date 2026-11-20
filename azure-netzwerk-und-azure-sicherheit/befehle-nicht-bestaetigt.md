# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Azure-Abonnement mit Budgetwarnung einrichten, Windows-11-Client `win11` mit Azure CLI und PowerShell | – | laut Lehrplan aufbauen; Preise und Kontingente mit Stand prüfen |
| 01 | `vnet_plan.py`; `beispiel_cli.txt` (`az network vnet create`, `az network vnet peering create`) | Modell ausgeführt; CLI: nicht ausgeführt | im Abonnement ausprobieren |
| 02 | `nsg_modell.py`; `beispiel_cli.txt` (`az network nsg create`, `az network nsg rule create`, `az network asg create`) | Modell ausgeführt (nur eingehend/TCP); CLI: nicht ausgeführt | im Abonnement ausprobieren |
| 03 | `routen_modell.py`; `beispiel_cli.txt` (`az network route-table create`, `az network route-table route create`, `az network firewall create`) | Modell ausgeführt; CLI: nicht ausgeführt | Kosten mit Stand prüfen, dann testen |
| 04 | `dns_modell.py`; `beispiel_cli.txt` (`az network private-endpoint create`, `az network private-dns zone create`, `az network private-dns link vnet create`) | Modell ausgeführt; CLI: nicht ausgeführt | im Abonnement testen |
| 05 | `keyvault_zugriff.py` (erfundene Rollennamen); `beispiel_cli.txt` (`az keyvault create`, `az keyvault secret set|show`) | Modell ausgeführt; CLI: nicht ausgeführt | echte Rollennamen aus der Dokumentation einsetzen |
| 06 | `rbac_policy_modell.py`; `beispiel_cli.txt` (`az role assignment create`, `az policy assignment create`) | Modell ausgeführt; CLI: nicht ausgeführt | im Abonnement testen |
| 07 | `log_modell.py`; `beispiel_cli.txt` (`az monitor diagnostic-settings create`, `az security pricing list`) | Modell ausgeführt (erfundene Zeilen); CLI: nicht ausgeführt | mit echten Protokollen auswerten |
| 08 | `diagnose_modell.py`; `beispiel_cli.txt` (`az network watcher test-connectivity`, `az network nic show-effective-route-table`, `az network nic list-effective-nsg`) | Modell ausgeführt; CLI: nicht ausgeführt | im Abonnement testen |
