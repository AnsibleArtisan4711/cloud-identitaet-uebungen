#!/usr/bin/env bash
# Modul 4: Virtuelle Maschinen, Größen, Zonen, Kontingent, ARM-Vorlagen. Echt: az-Befehle (Hilfetext) und JSON-Verarbeitung. Modell: Größen, Preise und Kontingent ERFUNDEN.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "vm create" --name --resource-group --image --size --zone
azchk "vm resize" --name --size
azchk "vm list-sizes" --location
azchk "deployment group validate" --resource-group --template-file --parameters
azchk "deployment group what-if" --resource-group --template-file
step "2. Umgebung (Modell)"
k group create rg-vm --location westeurope >/dev/null
k vnet create netz --group rg-vm --prefix 10.50.0.0/16 --subnet web=10.50.1.0/24 >/dev/null
k vm sizes
step "3. VMs anlegen: Zonen und Kontingent (Modell; Kontingent 12 vCPU erfunden)"
k vm create web1 --group rg-vm --size Lab_S2 --vnet netz --subnet web --zone 1
k vm create web2 --group rg-vm --size Lab_S2 --vnet netz --subnet web --zone 2
k vm create db1 --group rg-vm --size Lab_S4 --vnet netz --subnet web --zone 3
k vm create gross --group rg-vm --size Lab_M8 --vnet netz --subnet web || true
k vm create falsch --group rg-vm --size Lab_S1 --vnet netz --subnet web --zone 4 || true
step "4. Größe ändern und Kosten (Modell, erfundene Preise)"
k vm resize web2 --size Lab_S1
k vm cost
step "5. ARM-Vorlage: gültige JSON-Datei lesen (echt, Python) und Struktur prüfen (Modell, nicht das Azure-Schema)"
cat > vorlage.json <<'J'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": { "vnetName": { "type": "string" }, "ungenutzt": { "type": "string", "defaultValue": "x" } },
  "resources": [
    { "type": "Microsoft.Network/virtualNetworks", "apiVersion": "2023-09-01", "name": "[parameters('vnetName')]", "location": "westeurope",
      "properties": { "addressSpace": { "addressPrefixes": [ "10.60.0.0/16" ] } } }
  ]
}
J
python3 -c "import json; d=json.load(open('vorlage.json')); print('JSON gültig (echt); Schlüssel oben:', ', '.join(d))"
k template vorlage.json
step "6. Fehler in der Vorlage: Parameter nicht definiert, Pflichtfeld fehlt (Modell)"
python3 - <<'PY'
import json
d = json.load(open('vorlage.json')); d['resources'][0]['name'] = "[parameters('vnetname')]"; del d['resources'][0]['apiVersion']
json.dump(d, open('fehler.json', 'w'))
PY
k template fehler.json
step "7. Kaputtes JSON (echt, Python meldet den Fehler)"
printf '{ "resources": [ }' > kaputt.json
python3 -c "import json; json.load(open('kaputt.json'))" 2>&1 | tail -1
