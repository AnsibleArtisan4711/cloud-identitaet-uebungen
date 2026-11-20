#!/usr/bin/env bash
# Modul 8: Azure Policy, Kosten, Budget und Abschlussprojekt. Echt: az-Befehle (Hilfetext), JSON. Modell: Richtlinienprüfung (Auszug) und Budget; Preise ERFUNDEN.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "policy definition create" --name --rules --mode
azchk "policy assignment create" --name --policy --scope --not-scopes
azchk "consumption budget create" --budget-name --amount --time-grain
azchk "tag create" --name
step "2. Richtlinie als JSON (echt gelesen): Standorte beschränken und Tag verlangen"
cat > nur-westeuropa.json <<'J'
{ "if": { "not": { "field": "location", "in": ["westeurope", "northeurope"] } }, "then": { "effect": "deny" } }
J
cat > tag-pflicht.json <<'J'
{ "if": { "field": "tags['kostenstelle']", "exists": false }, "then": { "effect": "deny" } }
J
cat > tag-audit.json <<'J'
{ "if": { "field": "tags['kostenstelle']", "exists": false }, "then": { "effect": "audit" } }
J
echo '{"name":"vm-ok","scope":"/rg-prod","location":"westeurope","tags":{"kostenstelle":"4711"}}' > r1.json
echo '{"name":"vm-usa","scope":"/rg-prod","location":"eastus","tags":{"kostenstelle":"4711"}}' > r2.json
echo '{"name":"vm-notag","scope":"/rg-prod","location":"westeurope","tags":{}}' > r3.json
echo '{"name":"vm-test","scope":"/rg-test","location":"eastus","tags":{}}' > r4.json
python3 -c "import json; [json.load(open(f)) for f in ('nur-westeuropa.json','tag-pflicht.json','tag-audit.json')]; print('Alle Richtlinien sind gültiges JSON (echt)')"
step "3. Richtlinien auf Ressourcen anwenden (Modell)"
pol() { echo "\$ azsim policy --def $1 --resource $2${3:+ --notscope $3}"; python3 "$HERE/azsim.py" policy --def $1 --resource $2 ${3:+--notscope $3}; }
for r in r1 r2 r3; do pol nur-westeuropa.json $r.json; done
for r in r1 r3; do pol tag-pflicht.json $r.json; done
pol tag-audit.json r3.json
step "4. Ausnahme (notScopes): /rg-test ist ausgenommen (Modell)"
pol nur-westeuropa.json r4.json /rg-test
step "5. Budget: Schwellen 50, 80 und 100 Prozent (Modell, erfundene Beträge)"
k budget --amount 100 --alerts 50 80 100 --spent 20 25 10 30 12 8
step "6. Kosten schätzen: 3 VMs, 30 Tage (Modell, erfundene Preise)"
k group create rg-abschluss --location westeurope >/dev/null
k vnet create netz --group rg-abschluss --prefix 10.70.0.0/16 --subnet web=10.70.1.0/24 >/dev/null
k vm create web1 --group rg-abschluss --size Lab_S2 --vnet netz --subnet web --zone 1 >/dev/null
k vm create web2 --group rg-abschluss --size Lab_S2 --vnet netz --subnet web --zone 2 >/dev/null
k vm create db1 --group rg-abschluss --size Lab_S4 --vnet netz --subnet web --zone 3 >/dev/null
k vm cost
step "7. Abschlussprojekt: Aufräumen (Modell): Ressourcengruppe löschen, nichts bleibt zurück"
k group delete rg-abschluss
k group list
echo "Im echten Azure nach jeder Übung Ressourcengruppen löschen und das Budget prüfen (Lehrplan)."
