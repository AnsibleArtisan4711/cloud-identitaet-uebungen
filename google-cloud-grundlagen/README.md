# Google Cloud Grundlagen (P58)

Übungsreihe zu den Grundlagen von Google Cloud: Organisation, Projekte und Abrechnung, IAM und Dienstkonten, Compute Engine, VPC und Firewall-Regeln, Cloud Storage, Cloud SQL im Überblick, Überwachung, Logging und Kosten sowie Vergleich mit AWS und Azure. 8 Module, 45 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Python-Modelle mit CLI-Textdateien; nichts davon wurde in Google Cloud ausgeführt. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P58 (Reihe „Lehrplan-Prompts“, Datei `P58-google-cloud-grundlagen.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Nur Python-Modelle ausgeführt, nicht in Google Cloud.** Die Ausgaben in den Ordnern `beispiele/` stammen von vereinfachten Modellen mit erfundenen Werten (Python 3 im Cloud-Container). **Google-Cloud-Konto und gcloud CLI wurden nicht verwendet**: Die Befehle sind Fachwissen und nicht bestätigt. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Ein Google-Cloud-Testkonto mit Budgetwarnung und ein Linux-Client mit gcloud CLI (Lehrplan). Das Konto wurde **nicht** eingerichtet. Die Python-Modelle laufen auf jedem Rechner mit Python 3.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Organisation, Projekte und Abrechnung](01-organisation-projekte-und-abrechnung/) | 3,75 h | Modell ausgeführt. |
| 02 | [IAM und Dienstkonten](02-iam-und-dienstkonten/) | 4,5 h | Modell ausgeführt. |
| 03 | [Compute Engine](03-compute-engine/) | 3,75 h | Modell ausgeführt. |
| 04 | [VPC und Firewall-Regeln](04-vpc-und-firewall-regeln/) | 4,5 h | Modell ausgeführt. |
| 05 | [Cloud Storage](05-cloud-storage/) | 3,75 h | Modell ausgeführt. |
| 06 | [Cloud SQL im Überblick](06-cloud-sql-im-ueberblick/) (Priorität 2) | 3 h | Modell ausgeführt. |
| 07 | [Überwachung, Logging und Kosten](07-ueberwachung-logging-und-kosten/) | 5,25 h | Modell ausgeführt. |
| 08 | [Vergleich mit AWS und Azure](08-vergleich-mit-aws-und-azure/) | 5,25 h | Modell ausgeführt. |

Summe 33,75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner.

## Hinweise

- Die Python-Modelle verändern nichts am System.
- Alle Namen, Adressen (`10.58.0.0/24`), Beträge und Daten sind erfunden. **Zugangsdaten gehören nie in ein Repository.**
- Die CLI-Textdateien wurden nicht ausgeführt und nicht gegen die Dokumentation geprüft. Beim Nachvollziehen im Konto entstehen eventuell Kosten: Budgetwarnung einrichten und Ressourcen danach löschen.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
