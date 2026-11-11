# AWS Cloud Practitioner (CLF-C02) – Lernskript

Lernskript zur Vorbereitung auf die Prüfung **AWS Certified Cloud Practitioner (CLF-C02)** in zwölf Modulen. Jede Lerneinheit wird zusammenhängend und von Grund auf erklärt, mit einem durchgängigen Beispiel (meist AWS CLI oder eine Richtlinie), typischen Fehlern und einem Praxisbezug. Am Ende jedes Kapitels stehen Übungsaufgaben, die Lösungen folgen getrennt dahinter.

## Wichtig: Was dieses Repository (noch) ist

- Es enthält das **Skript als Markdown**, ein Kapitel pro Modul (`skript.md`), dazu [Einleitung](docs/skript-einleitung.md) und [Quellenverzeichnis](docs/skript-quellenverzeichnis.md) im Ordner `docs`.
- Eine eigenständige Übungsreihe mit Aufgaben, Lösungen und Beispieldateien je Modul ist **noch nicht** Teil des Repositories.
- Die Codebeispiele (AWS CLI, Richtlinien, Vorlagen) wurden **nicht gegen ein AWS-Konto ausgeführt**. Wer sie nachvollzieht, arbeitet in einem eigenen Testkonto, behält die Kosten im Blick (Budget einrichten) und räumt am Ende auf.
- Inhalt und Beispiele beruhen auf dem Lehrplan und auf fachlicher Recherche; Preise, Limits und Servicenamen ändern sich bei AWS laufend. Maßgeblich ist die offizielle AWS-Dokumentation.
- Hinweise zu Datenschutz und anderen rechtlichen Themen sind fachliche Orientierung und keine Rechtsberatung.

## Module

| Modul | Thema | Dauer | Prio | Stand |
|---|---|---|---|---|
| [01](modul-01-cloud-grundlagen/) | Cloud-Grundlagen und AWS Architektur | 8 h | 1 | Skript verfügbar |
| [02](modul-02-globale-infrastruktur/) | Globale Infrastruktur und Bereitstellungsmodelle | 7 h | 1 | Skript verfügbar |
| [03](modul-03-identitaet-zugriff/) | Identität, Zugriff und Account-Struktur | 9 h | 1 | Skript verfügbar |
| [04](modul-04-compute-serverless/) | Compute und Serverless Grundlagen | 10 h | 1 | Skript verfügbar |
| [05](modul-05-storage-datenbanken/) | Storage, Datenbanken und Datenplattformen | 10 h | 1 | Skript verfügbar |
| [06](modul-06-netzwerk-cdn/) | Netzwerk, Connectivity und Content Delivery | 10 h | 1 | Skript verfügbar |
| [07](modul-07-betrieb-monitoring/) | Betrieb, Monitoring und Troubleshooting | 9 h | 2 | Skript verfügbar |
| [08](modul-08-security-compliance/) | Security, Compliance und Governance | 10 h | 1 | Skript verfügbar |
| [09](modul-09-well-architected/) | Architekturprinzipien und Well-Architected | 8 h | 2 | Skript verfügbar |
| [10](modul-10-automation-iac/) | Automation, Deployment und IaC Grundlagen | 9 h | 2 | Skript verfügbar |
| [11](modul-11-kosten-finops/) | Kosten, Billing und FinOps | 8 h | 2 | Skript verfügbar |
| [12](modul-12-migration-bcdr-pruefung/) | Migration, BCDR und Prüfungsvorbereitung | 8 h | 3 | Skript verfügbar |

Die Dauer ist die Angabe aus dem Skript; bei einigen Modulen weicht die Summe der Lerneinheiten davon ab, das steht im jeweiligen Kapitel. Priorität: 1 = höchste, 3 = niedrigste.

## Lizenz

- **Code** (Beispieldateien und Skripte, falls das Repository solche enthält): [MIT-Lizenz](LICENSE)
- **Texte** (die Modul-READMEs, die Kapitel `skript.md` und die Dateien unter `docs/`): [CC BY 4.0](LICENSE-DOCS.md)
- **Nicht von diesen Lizenzen erfasst:** Inhalte des Lehrplans, auf dem das Skript aufbaut („AWS Cloud Practitioner“). Er ist die Quelle der Themen; für ihn gelten die Bedingungen seines Herausgebers. Das betrifft auch die Tabellen der Lerneinheiten am Anfang der Kapitel `skript.md`.
- AWS und die Namen der AWS-Dienste sind Marken von Amazon Web Services; dieses Repository steht in keiner Verbindung zu AWS.

Autor: AnsibleArtisan4711
