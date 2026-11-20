#!/usr/bin/env bash
# Modul 4: Geräte: registriert, eingebunden, hybrid eingebunden. Modell; die dsregcmd-Beispiele sind ERFUNDENE Nachbildungen, nicht von einem echten Gerät.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "ad user list" --filter
echo "Die Geräteabfrage dsregcmd /status läuft nur unter Windows; sie wurde NICHT ausgeführt. Die Beispieldateien unten sind nachgebaut."
step "2. Ausgaben von dsregcmd nachbilden (ERFUNDEN) und auswerten (Modell)"
printf 'AzureAdJoined : YES\nDomainJoined : NO\n' > geraet-cloud.txt
printf 'AzureAdJoined : YES\nDomainJoined : YES\n' > geraet-hybrid.txt
printf 'AzureAdJoined : NO\nDomainJoined : YES\n' > geraet-nur-domaene.txt
printf 'AzureAdJoined : NO\nDomainJoined : NO\n' > geraet-privat.txt
for f in geraet-cloud geraet-hybrid geraet-nur-domaene geraet-privat; do k device dsreg $f.txt; done
step "3. Voraussetzungen der hybriden Einbindung (Modell)"
k device hybrid --connect yes --scp yes --dc yes
k device hybrid --connect no --scp yes --dc yes
k device hybrid --connect yes --scp no --dc no
step "4. Einordnung (Fachwissen, aus Microsoft Learn gelesen: nur der erste Punkt)"
echo "Windows Autopilot im selbstbereitstellenden Modus wird für hybrid eingebundene Geräte nicht unterstützt (Microsoft Learn, Teams-Rooms-Seite, Suchauszug 20.11.2026)."
echo "Alle anderen Aussagen zu Einbindungsarten sind Fachwissen und nicht bestätigt."
