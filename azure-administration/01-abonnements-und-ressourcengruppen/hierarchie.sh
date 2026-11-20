#!/usr/bin/env bash
# Modul 1: Hierarchie (Verwaltungsgruppen, Abonnement, Ressourcengruppen), Tags, Sperren. Echt: Prüfung der az-Befehle (Hilfetext). Modell: alles andere.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "account management-group create" --name --parent
azchk "group create" --name --location --tags
azchk "lock create" --name --lock-type --resource-group
azchk "tag update" --resource-id --operation
step "2. Hierarchie aufbauen (Modell): Wurzel -> prod/test -> Abonnement"
k mg create mg-prod
k mg create mg-test
k mg create mg-lab --parent mg-test
k sub move lab-test --mg mg-lab
k mg tree
step "3. Ressourcengruppen mit Tags (Modell)"
k group create rg-web --location westeurope --tags env=lab
k group create rg-daten --location westeurope --tags env=lab owner=ana
k group list
step "4. Fehlerfälle: doppelte Gruppe und zu tiefe Hierarchie (Modell)"
k mg create mg-prod || true
k mg create e1 --parent mg-lab
k mg create e2 --parent e1
k mg create e3 --parent e2
k mg create e4 --parent e3 || true
step "5. Sperre: Löschen wird verweigert, bis die Sperre entfernt ist (Modell)"
k lock create --name nicht-loeschen --group rg-daten --type CanNotDelete
k group delete rg-daten || true
k lock delete --name nicht-loeschen
k group delete rg-daten
k group list
