#!/usr/bin/env bash
# Modul 3: Entra Connect: Bereich, UPN-Suffix, Delta-Synchronisation, Anmeldemethoden. Modell (kein Active Directory, kein Entra Connect).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "ad user show" --id
azchk "ad user list" --filter
echo "Entra Connect ist ein Windows-Programm (PowerShell: Start-ADSyncSyncCycle); es wurde NICHT ausgeführt und seine Befehle nicht geprüft."
step "2. Lokales AD (Modell): drei OUs, ein nicht routbares UPN-Suffix"
k ad add ana --upn ana@labmuster.onmicrosoft.com --ou Vertrieb --dept Vertrieb
k ad add ben --upn ben@firma.local --ou Technik --dept Technik
k ad add cem --upn cem@muster-lab.example --ou Technik --dept Technik
k ad add dora --upn dora@firma.local --ou Test --dept Test
k ad list
step "3. Erste Synchronisation: Bereich OU Vertrieb und Technik (Modell)"
k connect config --scope Vertrieb Technik --method phs
k connect run
k user list
step "4. Namensraum richtigstellen: Domäne verifizieren und UPN ändern (Modell)"
k domain verify muster-lab.example --txt MS=ms-erfunden-0001 >/dev/null
k ad set ben --upn ben@muster-lab.example
k ad set cem --upn cem@muster-lab.example --dept Betrieb
k connect run
k user list
step "5. Löschen und Bereich: Objekte außerhalb oder gelöscht verschwinden (Modell)"
k ad del ana
k connect run
step "6. Anmeldemethoden und Ausfall der lokalen Umgebung (Modell)"
k connect methods
for m in phs pta federation; do k connect signin ben@muster-lab.example --method $m --onprem down; done
k connect signin ben@muster-lab.example --method pta --onprem up
