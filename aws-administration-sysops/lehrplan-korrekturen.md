# Anmerkungen zum Lehrplan P56

Beim Ausarbeiten aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Ausgeführt wurden nur die Python-Modelle (Cloud-Container, Python 3). Es gab **kein AWS-Konto**; alle fachlichen Aussagen und CLI-Befehle sind Fachwissen und **nicht bestätigt**. | Im Konto nachvollziehen. |
| 2 | alle | **Quellen, Kosten und Versionen:** Die AWS-Dokumentation wurde nicht gelesen; Kosten, Preise, Gratis-Kontingente und Versionsstände wurden **nicht recherchiert**. Die Preise der Modelle sind erfunden. | Aktuelle Werte mit Stand prüfen und eintragen. |
| 3 | 01 | **IAM-Modell:** Es wertet nur Aktion und Ressource aus; Bedingungen, Berechtigungsgrenzen und Organisationsrichtlinien fehlen. | In der Dokumentation prüfen. |
| 4 | 03 | **Scaling-Modell:** Ohne Abkühlzeit und Startzeit; das Verhalten echter Gruppen weicht ab. | Im Konto beobachten. |
| 5 | 05 | **Priorität:** Modul 5 ist Priorität 2; kein anderes Modul setzt es voraus. | Bei Zeitmangel entfallen lassen. |
| 6 | 07 | **Vorlagenprüfung:** `cfn_pruefen.py` prüft nur eigene Regeln und ersetzt `validate-template` nicht. | Mit dem Dienst prüfen. |
