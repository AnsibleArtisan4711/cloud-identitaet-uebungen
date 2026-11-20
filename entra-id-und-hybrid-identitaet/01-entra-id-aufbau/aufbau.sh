#!/usr/bin/env bash
# Modul 1: Aufbau von Entra ID: Mandant, Domänen, Benutzer. Echt: az-Befehle (Hilfetext). Modell: Mandant, Domänenprüfung, Benutzer.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "ad user create" --display-name --password --user-principal-name
azchk "ad user list" --filter
azchk "rest" --method --url --body
step "2. Mandant und Domänen (Modell)"
k domain list
step "3. Benutzer anlegen: nur mit verifizierter Domäne (Modell)"
k user create ana@labmuster.onmicrosoft.com --dept Vertrieb
k user create ben@labmuster.onmicrosoft.com --dept Technik
k user create cem@muster-lab.example --dept Technik || true
step "4. Domäne verifizieren: falscher und richtiger TXT-Eintrag (Modell)"
k domain verify muster-lab.example --txt MS=falsch || true
k domain verify muster-lab.example --txt MS=ms-erfunden-0001
k domain list
k user create cem@muster-lab.example --dept Technik
step "5. Wer ist im Mandanten? (Modell)"
k user list
