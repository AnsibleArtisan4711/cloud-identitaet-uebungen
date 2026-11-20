#!/usr/bin/env bash
# Modul 5: Speicherkonten, Redundanz, Zugriff (Modell-Token), Lebenszyklus. Echt: az-Befehle (Hilfetext), HMAC-SHA256 (Python). Modell: alles andere; das Token ist NICHT das echte SAS-Format.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "storage account create" --name --resource-group --sku --kind --location
azchk "storage account generate-sas" --account-name --permissions --expiry --services
azchk "storage container create" --name --account-name --auth-mode
azchk "storage account management-policy create" --account-name --policy --resource-group
step "2. Redundanz (Modell, Fachwissen, nicht gegen die Dokumentation geprüft)"
k storage redundancy
step "3. Speicherkonten anlegen: Namensregeln (Modell)"
k group create rg-sp --location westeurope >/dev/null
k storage create labdaten01 --group rg-sp --sku Standard_LRS
k storage create labdaten01 --group rg-sp --sku Standard_LRS || true
k storage create LabDaten --group rg-sp --sku Standard_LRS || true
k storage create ab --group rg-sp --sku Standard_LRS || true
k storage create lab-daten-02 --group rg-sp --sku Standard_LRS || true
step "4. Zugriff mit zeitlich begrenztem Token (Modell mit HMAC-SHA256, echt gerechnet; NICHT das echte SAS-Format)"
K=testschluessel-erfunden
k storage sas --key $K --path labdaten01/berichte/q1.pdf --perm r --expiry 1000 --now 900 --use r
k storage sas --key $K --path labdaten01/berichte/q1.pdf --perm r --expiry 1000 --now 1001 --use r
k storage sas --key $K --path labdaten01/berichte/q1.pdf --perm r --expiry 1000 --now 900 --use w
echo "Mit anderem Schlüssel entsteht eine andere Signatur (Schlüssel rotieren macht Token ungültig, Fachwissen):"
k storage sas --key anderer-schluessel --path labdaten01/berichte/q1.pdf --perm r --expiry 1000 --now 900 --use r | head -2
step "5. Lebenszyklus: Stufen nach Alter (Modell)"
for d in 5 40 120 400; do k storage lifecycle --age $d --cool 30 --archive 90 --delete 365; done
step "6. Regel als JSON: echt gelesen, Struktur prüfen (Python)"
cat > lifecycle.json <<'J'
{ "rules": [ { "name": "alt-abkuehlen", "enabled": true, "type": "Lifecycle",
  "definition": { "filters": { "blobTypes": ["blockBlob"] },
    "actions": { "baseBlob": { "tierToCool": { "daysAfterModificationGreaterThan": 30 }, "delete": { "daysAfterModificationGreaterThan": 365 } } } } } ] }
J
python3 - <<'PY'
import json
r = json.load(open('lifecycle.json'))['rules'][0]; a = r['definition']['actions']['baseBlob']
print('Regel', r['name'], '->', ', '.join(f'{k} nach {v["daysAfterModificationGreaterThan"]} Tagen' for k, v in a.items()))
PY
