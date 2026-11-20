# AWS Administration (SysOps) (P56)

Übungsreihe zur AWS-Administration (SysOps): Konten und IAM, VPC, EC2 mit Auto Scaling und Load Balancing, Speicher (EBS, S3, EFS), Datenbanken im Betrieb (RDS), Überwachung mit CloudWatch, Automatisierung mit AWS CLI und CloudFormation sowie Kostenkontrolle, Sicherheit und Fehlersuche. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Python-Modelle mit CLI-Textdateien; nichts davon wurde in AWS ausgeführt. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P56 (Reihe „Lehrplan-Prompts“, Datei `P56-aws-administration-sysops.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Nur Python-Modelle ausgeführt, nicht in AWS.** Die Ausgaben in den Ordnern `beispiele/` stammen von vereinfachten Modellen mit erfundenen Werten (Python 3 im Cloud-Container). **AWS-Konto, AWS CLI und CloudFormation wurden nicht verwendet**: Die Befehle sind Fachwissen und nicht bestätigt. Preise sind erfunden. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Ein kostenloses oder budgetbegrenztes AWS-Konto mit Budgetwarnung und ein Linux-Client mit AWS CLI (Lehrplan). Das Konto wurde **nicht** eingerichtet. Die Python-Modelle laufen auf jedem Rechner mit Python 3.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Konten und IAM](01-konten-und-iam/) | 9 h | Modell ausgeführt. |
| 02 | [VPC und Netzwerkaufbau](02-vpc-und-netzwerkaufbau/) | 10,5 h | Modell ausgeführt. |
| 03 | [EC2, Auto Scaling und Load Balancing](03-ec2-auto-scaling-und-load-balancing/) | 10,5 h | Modell ausgeführt. |
| 04 | [Speicher: EBS, S3 und EFS](04-speicher-ebs-s3-und-efs/) | 9 h | Modell ausgeführt. |
| 05 | [Datenbanken im Betrieb mit RDS](05-datenbanken-im-betrieb-mit-rds/) (Priorität 2) | 7,5 h | Modell ausgeführt. |
| 06 | [Überwachung mit CloudWatch](06-ueberwachung-mit-cloudwatch/) | 9 h | Modell ausgeführt. |
| 07 | [Automatisierung mit CLI und CloudFormation](07-automatisierung-mit-cli-und-cloudformation/) | 10,5 h | Modell ausgeführt. |
| 08 | [Kostenkontrolle, Sicherheit und Fehlersuche](08-kosten-sicherheit-und-fehlersuche/) | 9 h | Modell ausgeführt. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner.

## Hinweise

- Die Python-Modelle verändern nichts am System.
- Alle Namen, Adressen (`10.56.0.0/16`), Beträge und Daten sind erfunden. **Zugangsdaten gehören nie in ein Repository.**
- Die CLI-Textdateien wurden nicht ausgeführt und nicht gegen die Dokumentation geprüft. Beim Nachvollziehen im Konto entstehen eventuell Kosten: Budgetwarnung einrichten und Ressourcen danach löschen.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
