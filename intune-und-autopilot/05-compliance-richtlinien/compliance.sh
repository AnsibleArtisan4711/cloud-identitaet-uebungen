#!/usr/bin/env bash
# Modul 5: Compliance-Richtlinien und Aktionen bei Nichtkonformität. Echt: JSON lesen. Modell: Auswertung. Aktionen und Standardwerte aus Microsoft Learn (Auszug, 20.11.2026) gelesen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Richtlinie und Geräte als JSON (eigenes Format), echt gelesen"
cat > richtlinie.json <<'J'
{ "name": "Windows-Grundschutz", "rules": { "BitLocker": true, "Firewall": true, "Kennwortlaenge": 8, "Windows_Build": 22631 },
  "actions": [ { "day": 0, "do": "Gerät als nicht konform markieren" }, { "day": 2, "do": "E-Mail an den Benutzer senden" }, { "day": 5, "do": "E-Mail erneut senden" }, { "day": 14, "do": "Gerät zur Außerbetriebnahme vormerken (retire list)" } ] }
J
cat > richtlinie-karenz.json <<'J'
{ "name": "Windows-Grundschutz mit Karenz", "rules": { "BitLocker": true, "Firewall": true, "Kennwortlaenge": 8, "Windows_Build": 22631 },
  "actions": [ { "day": 3, "do": "Gerät als nicht konform markieren" }, { "day": 1, "do": "E-Mail an den Benutzer senden" } ] }
J
echo '{ "name": "PC-GUT", "BitLocker": true, "Firewall": true, "Kennwortlaenge": 12, "Windows_Build": 26100 }' > gut.json
echo '{ "name": "PC-ALT", "BitLocker": false, "Firewall": true, "Kennwortlaenge": 6, "Windows_Build": 19045 }' > alt.json
python3 -c "import json; [json.load(open(f)) for f in ('richtlinie.json','richtlinie-karenz.json','gut.json','alt.json')]; print('Alle Dateien sind gültiges JSON (echt)')"
step "2. Konformes und nicht konformes Gerät (Modell)"
k comp --policy richtlinie.json --device gut.json
k comp --policy richtlinie.json --device alt.json
step "3. Mit Bedingtem Zugriff: Sperre sofort (Modell; Learn: Bedingter Zugriff wirkt, sobald das Gerät als nicht konform gilt)"
k comp --policy richtlinie.json --device alt.json --ca yes
step "4. Karenzzeit: „nicht konform markieren“ erst nach 3 Tagen (Modell; Learn: Zeitplan 0 bis 365 Tage)"
k comp --policy richtlinie-karenz.json --device alt.json --ca yes
step "5. Was die Standardaktion bedeutet (Microsoft Learn, Suchauszug 20.11.2026, nicht die ganze Seite)"
echo "Jede Richtlinie enthält die Aktion „Gerät als nicht konform markieren“ mit 0 Tagen; sie kann nicht entfernt, aber zeitlich verschoben werden."
echo "Weitere Aktionen laut Auszug: E-Mail an Benutzer, Gerät aus der Ferne sperren, Gerät auf eine Retire-Liste setzen, Push-Benachrichtigung; nicht jede Aktion gibt es für jede Plattform."
