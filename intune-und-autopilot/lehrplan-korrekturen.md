# Anmerkungen zum Lehrplan P29

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Intune, Autopilot und Windows wurden nicht ausgeführt (kein Mandant, kein Gerät, kein `az login`). Echt sind nur die Befehlsprüfung gegen die Azure CLI 2.93.0 (Hilfetexte), die Prüfung der Autopilot-CSV, SHA-256 und das Lesen von JSON; alles Übrige ist ein Modell (`intunesim.py`). | Im Labor und Test-Tenant ausführen und die Ausgaben mit dem Modell vergleichen. |
| 2 | alle | **Quellen und Lizenzen:** Gelesen wurden nur Suchauszüge (20.11.2026) von Microsoft-Learn-Seiten zu Lizenzen, Autopilot-CSV, Nichtkonformitätsaktionen und Zuweisungsfiltern. Alle übrigen Aussagen sind Fachwissen und nicht bestätigt. Portalmenüs wurden nicht geprüft und nicht beschrieben; Lizenzpläne ändern sich. | Lizenz- und Regelseiten vor der Anwendung vollständig lesen. |
| 3 | 02 | **Gerätelimit:** Der Wert 3 ist erfunden; die Reihenfolge der Prüfungen im Modell ist vereinfacht. | Echte Einschränkungen in der Dokumentation nachlesen. |
| 4 | 03 | **Autopilot-CSV:** Die Regeln stammen aus einem Suchauszug; Hashes sind erfunden, es wurden keine echten erzeugt. | Mit echten Hashes im Labor prüfen. |
| 5 | 04 | **Konflikte:** Das JSON-Format ist eigen; das Verhalten bei Konflikten im echten Intune wurde nicht geprüft. | Im Test-Tenant prüfen. |
| 6 | 06 | **Erkennung:** Der Versionsvergleich im Modell ist ein Textvergleich. | Echte Erkennungsregeln und Verpacken prüfen. |
| 7 | 07 | **Priorität:** Modul 7 ist Priorität 2 und enthält das einzige Update-Thema des Lehrplans; die Werte sind erfunden. | Bei Bedarf an Updates nicht weglassen. |
| 8 | 08 | **Filter:** Die Filtersprache im Modell ist stark vereinfacht; Vorrang und ODER-Logik stammen aus einem Suchauszug. | Im Test-Tenant mit echten Filtern vergleichen. |
