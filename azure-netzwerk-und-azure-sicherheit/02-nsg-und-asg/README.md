# 02 NSG und ASG

Übung **02.1** (Priorität 1). Geschätzte Zeit: 8 bis 11 Stunden (Schätzung; Lehrplan: 14 UE zu 45 Minuten = 10,5 Stunden).

> Modell ausgeführt.

| Datei | Zweck |
|---|---|
| `02.1-nsg-und-asg.md` | Die Übung mit Aufgaben, Kontrollfragen und Musterlösung |
| `beispiel_cli.txt` | Azure CLI / PowerShell (Textdatei, NICHT ausgeführt: es gab kein Azure-Abonnement; Fachwissen, Befehle und Parameter nicht gegen die Dokumentation geprüft) |
| `lauf.sh` | Skript |
| `nsg_modell.py` | Modell: Netzwerksicherheitsgruppe. Regeln nach Priorität (kleinere Zahl zuerst), erste passende Regel entscheidet; am Ende Standardregeln. Vereinfacht (Richtung eingehend, Protokoll TCP, Ziel-Port). Erfundene Regeln. |
| `beispiele/lauf.ausgabe.txt` | Echte Ausgabe des Laufs von `lauf` |
