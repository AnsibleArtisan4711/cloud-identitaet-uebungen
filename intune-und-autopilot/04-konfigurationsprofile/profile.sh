#!/usr/bin/env bash
# Modul 4: Konfigurationsprofile, Konflikte und Einordnung gegenüber Gruppenrichtlinien. Echt: JSON lesen. Modell: Zusammenführung und Konflikte (Verhalten bei Konflikten ist Fachwissen).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Profile als JSON (eigenes Format, nicht das von Intune), echt gelesen"
cat > grundschutz.json <<'J'
{ "name": "Grundschutz", "settings": { "BitLocker": true, "Bildschirmsperre_min": 10, "Firewall": true } }
J
cat > buero.json <<'J'
{ "name": "Buero", "settings": { "Bildschirmsperre_min": 10, "Hintergrund": "firma.png" } }
J
cat > streng.json <<'J'
{ "name": "Streng", "settings": { "Bildschirmsperre_min": 5, "USB_Speicher": false } }
J
python3 -c "import json; [json.load(open(f)) for f in ('grundschutz.json','buero.json','streng.json')]; print('Alle Profile sind gültiges JSON (echt)')"
step "2. Zwei Profile ohne Widerspruch (Modell)"
k cfg grundschutz.json buero.json
step "3. Drei Profile mit Widerspruch bei der Bildschirmsperre (Modell)"
k cfg grundschutz.json buero.json streng.json
echo "Gleicher Wert in zwei Profilen ist kein Konflikt; unterschiedliche Werte sind einer. Das genaue Verhalten bei Konflikten im echten Intune wurde nicht geprüft."
step "4. Einordnung gegenüber Gruppenrichtlinien (Fachwissen, nicht bestätigt)"
printf '%-24s %-34s %s\n' "" "Gruppenrichtlinien (GPO)" "Intune-Konfigurationsprofil"
printf '%-24s %-34s %s\n' "Ort der Verwaltung" "lokales AD, Domänencontroller" "Cloud"
printf '%-24s %-34s %s\n' "Zielgeräte" "domänenverbundene Geräte" "bei Intune registrierte Geräte"
printf '%-24s %-34s %s\n' "Zuweisung" "OU, Verknüpfung, Filter" "Gruppen und Filter"
printf '%-24s %-34s %s\n' "Reichweite" "sehr viele Windows-Einstellungen" "viele, nicht alle Einstellungen"
echo "Einstellungen, die in beiden Systemen gesetzt werden, können sich widersprechen; Vorrang und Planung der Umstellung sind im echten Mandanten zu prüfen (nicht geprüft)."
