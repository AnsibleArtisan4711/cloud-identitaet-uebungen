#!/usr/bin/env bash
# Modul 7 (Priorität 2): Update-Ringe als Rechnung. Modell mit erfundenen Werten; die Wirkung von Zurückstellung und Frist ist Fachwissen und nicht bestätigt.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url --body
step "2. Drei Ringe für dieselbe Veröffentlichung am Tag 0 (Modell, erfundene Werte)"
k upd --ring Pilot --release 0 --defer 0 --deadline 2
k upd --ring Breit --release 0 --defer 7 --deadline 5
k upd --ring Spaet --release 0 --defer 21 --deadline 7
step "3. Ein Problem wird entdeckt: der breite Ring wird für 10 Tage angehalten (Modell)"
k upd --ring Breit --release 0 --defer 7 --deadline 5 --pause 10
step "4. Einordnung (Fachwissen, nicht bestätigt)"
echo "Zurückstellung verschiebt das Angebot, die Frist erzwingt danach die Installation; Pilotgruppen sehen Probleme zuerst."
echo "Die echten Einstellungen und Grenzen von Windows-Update-Ringen und Aktualisierungsrichtlinien wurden nicht gelesen."
