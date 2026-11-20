#!/usr/bin/env bash
# Modul 3: Virtuelle Netzwerke, Subnetze, Peering, NSG-Grundlagen. Echt: Prüfung der az-Befehle (Hilfetext) und CIDR-Rechnung (Python ipaddress). Modell: Anlegen und Regeln.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "network vnet create" --name --resource-group --address-prefixes --subnet-prefixes
azchk "network vnet subnet create" --name --vnet-name --address-prefixes
azchk "network vnet peering create" --name --vnet-name --remote-vnet --allow-vnet-access
azchk "network nsg rule create" --nsg-name --priority --access --direction --destination-port-ranges
step "2. Adressplanung rechnen (echt mit Python ipaddress): wie viele Adressen hat ein Subnetz?"
python3 - <<'PY'
import ipaddress
for c in ('10.10.0.0/16', '10.10.1.0/24', '10.10.2.0/27', '10.10.3.0/29'):
    n = ipaddress.ip_network(c); print(f'{c:14} {n.num_addresses:6} Adressen, Netzadresse {n.network_address}, Broadcast {n.broadcast_address}')
print('Azure reserviert je Subnetz 5 Adressen (Fachwissen, hier nicht gegen die Dokumentation geprüft); das Modell rechnet damit.')
PY
step "3. VNets anlegen (Modell)"
k group create rg-net --location westeurope >/dev/null
k vnet create hub --group rg-net --prefix 10.10.0.0/16 --subnet web=10.10.1.0/24 daten=10.10.2.0/27
k vnet show hub
k vnet create spoke --group rg-net --prefix 10.20.0.0/16 --subnet app=10.20.1.0/24
k vnet create falsch --group rg-net --prefix 10.30.0.0/24 --subnet a=10.31.0.0/24 || true
k vnet create ueber --group rg-net --prefix 10.40.0.0/24 --subnet a=10.40.0.0/25 b=10.40.0.64/26 || true
step "4. Wie groß muss ein Subnetz für 60 Server sein? (Modell)"
k vnet plan --hosts 60
k vnet plan --hosts 27
step "5. Peering: Adressräume dürfen nicht überlappen (Modell)"
k vnet peer hub spoke
k vnet create alt --group rg-net --prefix 10.10.128.0/17 --subnet x=10.10.128.0/24
k vnet peer hub alt || true
step "6. NSG: Priorität entscheidet, kleinere Zahl zuerst; sonst greifen die Standardregeln (Modell)"
nsg() { show nsg "$@"; python3 "$HERE/azsim.py" nsg "$@"; }
nsg --port 443 --rule 100:https-erlauben:443:allow 200:alles-sperren:*:deny
nsg --port 22 --rule 100:https-erlauben:443:allow 200:alles-sperren:*:deny
nsg --port 22 --source Internet
nsg --port 22 --source VirtualNetwork
