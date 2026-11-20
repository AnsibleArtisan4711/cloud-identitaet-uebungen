# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Google-Cloud-Testkonto mit Budgetwarnung einrichten, Linux-Client `gcl01` mit gcloud CLI | – | laut Lehrplan aufbauen; Gratis-Kontingente und Kosten mit Stand prüfen |
| 01 | `hierarchie_modell.py`; `beispiel_cli.txt` (`gcloud projects list|create`, `gcloud billing projects link`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto ausprobieren |
| 02 | `dienstkonten_modell.py`; `beispiel_cli.txt` (`gcloud iam service-accounts create|keys list`, `gcloud projects add-iam-policy-binding`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto ausprobieren |
| 03 | `maschinen_modell.py` (erfundene Typen und Preise); `beispiel_cli.txt` (`gcloud compute instances create|list|delete`) | Modell ausgeführt; CLI: nicht ausgeführt | echte Typen und Preise eintragen |
| 04 | `firewall_modell.py`; `beispiel_cli.txt` (`gcloud compute networks create`, `gcloud compute networks subnets create`, `gcloud compute firewall-rules create`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto testen |
| 05 | `speicher_modell.py` (erfundene Preise); `beispiel_cli.txt` (`gcloud storage buckets create`, `gcloud storage cp`) | Modell ausgeführt; CLI: nicht ausgeführt | mit aktuellen Preisen rechnen |
| 06 | `ha_modell.py`; `beispiel_cli.txt` (`gcloud sql instances create`, `gcloud sql backups list`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto testen (Kosten beachten) |
| 07 | `budget_modell.py`; `beispiel_cli.txt` (`gcloud billing budgets create`, `gcloud logging read`) | Modell ausgeführt; CLI: nicht ausgeführt | Budget im Konto einrichten |
| 08 | `vergleich.py` | Modell ausgeführt (Status F) | mit Dokumentation belegen |
