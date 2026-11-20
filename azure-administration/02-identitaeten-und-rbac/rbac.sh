#!/usr/bin/env bash
# Modul 2: Rollen und Bereiche (RBAC). Echt: Prüfung der az-Befehle (Hilfetext). Modell: Rollen (Auszug), Vererbung, Gruppen, Sperren, Datenebene.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
RG=$S/resourceGroups/rg-web; RGD=$S/resourceGroups/rg-daten
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "role assignment create" --assignee --role --scope
azchk "role assignment list" --assignee --scope --all
azchk "role definition list" --name
step "2. Aufbau (Modell): zwei Ressourcengruppen, Benutzer ana, ben, cem; Gruppe grp-admins mit ana"
k group create rg-web --location westeurope >/dev/null
k group create rg-daten --location westeurope >/dev/null
k identity member-add grp-admins ana
step "3. Zuweisungen auf verschiedenen Bereichen (Modell)"
k role assign --assignee grp-admins --role Contributor --scope $S
k role assign --assignee ben --role Reader --scope $RG
k role assign --assignee cem --role "Virtual Machine Contributor" --scope $RG
k role assign --assignee cem --role "Storage Blob Data Reader" --scope $RGD
step "4. Wirksame Zuweisungen: Vererbung von oben nach unten (Modell)"
k role list --scope $RG
k role list --scope $RGD
step "5. Wer darf was? (Modell); Gruppenmitgliedschaft und Vererbung zählen"
chk() { show role check "$@"; python3 "$HERE/azsim.py" role check "$@"; true; }
chk --assignee ana --action Microsoft.Compute/virtualMachines/write --scope $RG
chk --assignee ben --action Microsoft.Compute/virtualMachines/read --scope $RG
chk --assignee ben --action Microsoft.Compute/virtualMachines/write --scope $RG
chk --assignee ben --action Microsoft.Compute/virtualMachines/read --scope $RGD
chk --assignee cem --action Microsoft.Compute/virtualMachines/write --scope $RG
chk --assignee cem --action Microsoft.Network/virtualNetworks/write --scope $RG
step "6. Rollen vergeben darf nur, wer es ausdrücklich darf: Contributor kann keine Zuweisungen schreiben (Modell)"
chk --assignee ana --action Microsoft.Authorization/roleAssignments/write --scope $RG
echo "(Im Modell darf das nur ein Owner; diese Rolle wurde hier niemandem zugewiesen.)"
step "7. Steuerungsebene gegen Datenebene (Modell)"
chk --assignee ana --action Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read --scope $RGD --data
chk --assignee cem --action Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read --scope $RGD --data
echo "Contributor (ana) darf Speicherkonten verwalten, aber die Daten nur mit einer Datenrolle lesen (Fachwissen, Modell)."
step "8. Sperre schlägt Rolle (Modell)"
k lock create --name nur-lesen --group rg-web --type ReadOnly
chk --assignee ana --action Microsoft.Compute/virtualMachines/write --scope $RG
