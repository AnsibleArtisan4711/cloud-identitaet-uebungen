#!/usr/bin/env bash
# Modul 7 (Priorität 2): App Service und Container im Überblick. Echt: az-Befehle (Hilfetext). Modell: Autoskalierung, Slot-Tausch, Container-Preis ERFUNDEN.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "appservice plan create" --name --resource-group --sku --is-linux
azchk "webapp create" --name --plan --resource-group
azchk "webapp deployment slot swap" --slot --name --resource-group
azchk "monitor autoscale create" --resource --min-count --max-count --count
azchk "container create" --name --image --cpu --memory --resource-group
step "2. Autoskalierung: Regeln nach CPU (Modell, ohne Abkühlzeit)"
k app autoscale --start 2 --min 2 --max 4 --out 70 --in 30 --cpu 50 80 85 90 40 20 20
step "3. Slot-Tausch: Einstellungen, die am Slot haften (Modell)"
k app swap --prod '{"VERSION":"1","DB":"produktiv"}' --staging '{"VERSION":"2","DB":"test"}' --sticky DB
k app swap --prod '{"VERSION":"1","DB":"produktiv"}' --staging '{"VERSION":"2","DB":"test"}'
echo "Ohne Markierung ginge die Test-Datenbank mit in die Produktion: darum Verbindungszeichenfolgen am Slot festhalten (Fachwissen)."
step "4. Container-Gruppe: Größe festlegen (Modell, erfundener Preis)"
k app aci --cpu 1 --mem 1.5
k app aci --cpu 2 --mem 4
