# Anmerkungen zum Lehrplan P27

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Azure wurde nicht ausgeführt (kein Abonnement, kein `az login`). Echt geprüft ist nur, ob Befehle und Parameter im Hilfetext der Azure CLI 2.93.0 stehen; alles Übrige ist ein Modell in Python (`azsim.py`) mit erfundenen Größen, Preisen und Kontingenten. | Im Test-Tenant ausführen und die Ausgaben mit dem Modell vergleichen. |
| 2 | alle | **Quellen:** Gelesen wurde nur ein Auszug (Suchergebnis vom 20.11.2026) der Microsoft-Learn-Seite „Study guide for Exam AZ-104“, der den Stand „Skills measured as of October 26, 2023“ nennt; eine neuere Fassung wurde nicht geprüft. Alle übrigen Aussagen sind Fachwissen und nicht bestätigt. Portalmenüs wurden nicht geprüft und nicht beschrieben. | Aktuelle Prüfungsziele und Dokumentation lesen und den Lehrplan abgleichen. |
| 3 | 01 | **Hierarchietiefe:** Die Grenze im Modell (6 Ebenen einschließlich Wurzel) ist eine Modellgrenze; der echte Wert wurde nicht geprüft. | In der Azure-Dokumentation nachlesen. |
| 4 | 04 | **Vorlage:** Die Strukturprüfung ist ein eigenes Modell und ersetzt weder das Schema noch `az deployment group validate`; Groß- und Kleinschreibung von Parameternamen wird im Modell unterschieden, bei Azure nicht geprüft. Bicep wurde nicht ausgeführt. | Im Test-Tenant mit `az deployment group validate` prüfen. |
| 5 | 05 | **Token:** Das Modell-Token ist **nicht** das echte SAS-Format; es zeigt nur Ablauf, Recht und Schlüssel. | Im Test-Tenant ein echtes SAS erzeugen und die Felder lesen. |
| 6 | 06 | **Parameternamen:** Die Prüfung gegen die Azure CLI hat zwei zunächst geratene Parameternamen als falsch erkannt (`--vault-name` bei `backup vault create`, `--recovery-point-name` bei `restore-disks`); sie wurden korrigiert. Das zeigt den Wert der Prüfung und die Grenze von Fachwissen. | Neue Befehle immer mit `az … --help` gegenprüfen. |
| 7 | 07 | **Priorität:** Modul 7 ist Priorität 2, enthält aber das einzige Thema „App Service und Container“ des Lehrplans. | Bei Ausrichtung an AZ-104 nicht weglassen. |
