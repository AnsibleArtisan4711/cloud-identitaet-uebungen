#!/usr/bin/env bash
# Modul 2: Gruppen (zugewiesen und dynamisch) und Verwaltungsrollen. Echt: az-Befehle (Hilfetext). Modell: Regelauswertung und Rollen (stark vereinfacht, ERFUNDENE Berechtigungszuordnung).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "ad group create" --display-name --mail-nickname
azchk "ad group member add" --group --member-id
azchk "role assignment create" --assignee --role --scope
step "2. Benutzer vorbereiten (Modell)"
k domain verify muster-lab.example --txt MS=ms-erfunden-0001 >/dev/null
for u in "ana@labmuster.onmicrosoft.com Vertrieb" "ben@labmuster.onmicrosoft.com Technik" "cem@muster-lab.example Technik" "dora@muster-lab.example Vertrieb"; do set -- $u; k user create $1 --dept $2 >/dev/null; done
k user list
step "3. Zugewiesene und dynamische Gruppe (Modell)"
k group create technik-zugewiesen
k group add technik-zugewiesen ben@labmuster.onmicrosoft.com
k group create vertrieb-dynamisch --dynamic 'user.department -eq "Vertrieb"'
k group show vertrieb-dynamisch
k group add vertrieb-dynamisch cem@muster-lab.example || true
step "4. Attributänderung ändert die Mitgliedschaft der dynamischen Gruppe (Modell)"
k group create nicht-vertrieb --dynamic 'user.department -ne "Vertrieb"'
k group show nicht-vertrieb
k group create ana-oder-technik --dynamic 'user.userPrincipalName -startsWith "ana" -or user.department -eq "Technik"'
k group show ana-oder-technik
echo "Regel mit Tippfehler:"
k group create falsch --dynamic 'user.department = Vertrieb' || true
echo "Dynamische Gruppen erfordern laut Microsoft Learn (Auszug, 20.11.2026) Entra ID P1 oder P2; das Modell prüft das nicht."
step "5. Verwaltungsrollen: kleinste Berechtigung (Modell)"
k role assign ben@labmuster.onmicrosoft.com "Helpdesk Administrator"
k role assign cem@muster-lab.example "Conditional Access Administrator"
k role can ben@labmuster.onmicrosoft.com user.resetPassword
k role can ben@labmuster.onmicrosoft.com user.create
k role can cem@muster-lab.example ca.manage
k role can ana@labmuster.onmicrosoft.com ca.manage
