#!/usr/bin/env bash
# Modul 8: Zuweisungen, Filter, Fehlersuche, Abschluss. Echt: JSON lesen. Modell: Auswertung. Vorrang der Filtermodi und ODER-Logik aus Microsoft Learn (Auszug, 20.11.2026) gelesen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Gruppen, Filter und Gerät als JSON (eigenes Format), echt gelesen"
cat > filter.json <<'J'
{ "NurSurface": { "mode": "include", "match": { "model": "Surface" } }, "KeinSurface": { "mode": "exclude", "match": { "model": "Surface" } }, "NurLaptop": { "mode": "include", "match": { "typ": "Laptop" } } }
J
echo '{ "name": "PC-A", "groups": ["vertrieb"], "model": "Surface", "typ": "Laptop" }' > pc-a.json
echo '{ "name": "PC-B", "groups": ["vertrieb", "technik"], "model": "Dell", "typ": "Laptop" }' > pc-b.json
python3 -c "import json; [json.load(open(f)) for f in ('filter.json','pc-a.json','pc-b.json')]; print('Alle Dateien sind gültiges JSON (echt)')"
step "2. Einfache Zuweisung mit Include-Filter (Modell)"
echo '[ { "group": "vertrieb", "filter": "NurSurface" } ]' > a1.json
k assign a1.json pc-a.json filter.json
k assign a1.json pc-b.json filter.json
step "3. Vorrang: Exclude vor Kein Filter vor Include (Learn-Auszug)"
echo '[ { "group": "vertrieb", "filter": "NurSurface" }, { "group": "technik", "filter": "KeinSurface" } ]' > a2.json
k assign a2.json pc-b.json filter.json
echo '[ { "group": "vertrieb", "filter": "NurSurface" }, { "group": "technik" } ]' > a3.json
k assign a3.json pc-b.json filter.json
step "4. Gleiche Modi: ODER-Logik (Learn-Auszug)"
echo '[ { "group": "vertrieb", "filter": "NurSurface" }, { "group": "technik", "filter": "NurLaptop" } ]' > a4.json
k assign a4.json pc-b.json filter.json
step "5. Gruppenausschluss (Modell)"
echo '[ { "group": "all" }, { "group": "technik", "exclude_group": true } ]' > a5.json
k assign a5.json pc-a.json filter.json
k assign a5.json pc-b.json filter.json
step "6. Fehlersuche: von der Registrierung bis zur Wirkung (Modell)"
echo '{ "name": "PC-C", "license": true, "scope": true, "blocked": false, "lastcheckin_days": 1, "in_group": true, "filter_excludes": true, "conflict": false }' > pc-c.json
echo '{ "name": "PC-D", "license": true, "scope": false, "blocked": false, "lastcheckin_days": 9, "in_group": true, "filter_excludes": false, "conflict": false }' > pc-d.json
echo '{ "name": "PC-E", "license": true, "scope": true, "blocked": false, "lastcheckin_days": 0, "in_group": true, "filter_excludes": false, "conflict": false }' > pc-e.json
for d in c d e; do k diag pc-$d.json; done
step "7. Abschlussprojekt: die Kette (Zusammenfassung)"
echo "Registrieren (Lizenz, Bereich, Einschränkungen) -> Autopilot-Profil -> Konfigurationsprofile -> Compliance-Richtlinie -> Bedingter Zugriff -> Apps -> Updates."
echo "Zuweisungen und Filter entscheiden an jeder Stelle, ob die Maßnahme das Gerät erreicht."
