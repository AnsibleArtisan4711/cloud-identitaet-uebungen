# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | AWS-Konto mit Budgetwarnung einrichten, Linux-Client `cli01` mit AWS CLI | – | laut Lehrplan aufbauen; Kosten und Gratis-Kontingente mit Stand prüfen |
| 01 | `iam_modell.py`; `beispiel_cli.txt` (`aws sts get-caller-identity`, `aws iam create-policy`, `aws iam simulate-principal-policy`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto ausprobieren |
| 02 | `vpc_plan.py`; `beispiel_cli.txt` (`aws ec2 create-vpc|create-subnet|create-internet-gateway|create-route-table|create-route`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto ausprobieren und aufräumen |
| 03 | `scaling_modell.py`; `beispiel_cli.txt` (`aws ec2 run-instances`, `aws autoscaling create-auto-scaling-group|put-scaling-policy`) | Modell ausgeführt (ohne Abkühlzeit); CLI: nicht ausgeführt | im Konto ausprobieren |
| 04 | `speicher_modell.py` (erfundene Preise); `beispiel_cli.txt` (`aws s3api put-bucket-lifecycle-configuration`, `aws ec2 create-volume|create-snapshot`) | Modell ausgeführt; CLI: nicht ausgeführt | mit aktuellen Preisen rechnen |
| 05 | `rds_modell.py`; `beispiel_cli.txt` (`aws rds create-db-instance|create-db-snapshot|restore-db-instance-to-point-in-time`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto testen (Kosten beachten) |
| 06 | `alarm_modell.py`; `beispiel_cli.txt` (`aws cloudwatch put-metric-alarm|describe-alarms`) | Modell ausgeführt; CLI: nicht ausgeführt | im Konto testen |
| 07 | `cfn_pruefen.py`; `beispiel_cli.txt` (`aws cloudformation validate-template|create-stack|describe-stack-events`) | Modell ausgeführt (eigene Regeln); CLI: nicht ausgeführt | mit `validate-template` prüfen |
| 08 | `kosten_modell.py`; `beispiel_cli.txt` (`aws budgets create-budget`, `aws cloudtrail lookup-events`) | Modell ausgeführt; CLI: nicht ausgeführt | Budget im Konto einrichten |
