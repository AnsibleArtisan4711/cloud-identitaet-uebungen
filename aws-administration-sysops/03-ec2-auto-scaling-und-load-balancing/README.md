# 03 EC2

Übung **03.1** (Priorität 1). Geschätzte Zeit: 8 bis 11 Stunden (Schätzung; Lehrplan: 14 UE zu 45 Minuten = 10,5 Stunden).

> Modell ausgeführt.

| Datei | Zweck |
|---|---|
| `03.1-ec2-auto-scaling-und-load-balancing.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `beispiel_cli.txt` | AWS CLI (Textdatei, NICHT ausgeführt: es gab kein AWS-Konto; Fachwissen, Befehle und Parameter nicht gegen die Dokumentation geprüft) |
| `lauf.sh` | Skript |
| `scaling_modell.py` | Modell: Ziel-Auslastung (Target Tracking) für eine Auto-Scaling-Gruppe. Gewünschte Anzahl = aufrunden(aktuell * Auslastung / Ziel), begrenzt auf Minimum und Maximum. Ohne Abkühlzeit, erfundene Last. |
| `beispiele/lauf.ausgabe.txt` | Echte Ausgabe des Laufs von `lauf` |
