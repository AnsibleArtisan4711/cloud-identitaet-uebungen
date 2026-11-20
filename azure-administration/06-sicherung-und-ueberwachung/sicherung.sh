#!/usr/bin/env bash
# Modul 6: Sicherung (Aufbewahrung, Wiederherstellungspunkte) und Überwachung (Metrik-Alarm). Echt: az-Befehle (Hilfetext) und Rechnung (Python). Modell: Regeln stark vereinfacht.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "backup vault create" --name --resource-group --location
azchk "backup protection enable-for-vm" --vault-name --vm --policy-name
azchk "backup restore restore-disks" --storage-account --restore-mode
azchk "monitor metrics alert create" --name --scopes --condition --action
azchk "monitor action-group create" --name --resource-group
step "2. Aufbewahrung: Wie viele Wiederherstellungspunkte gibt es? (Modell)"
k backup --daily 7 --weekly 4 --monthly 3 --age 100 --restore 3
k backup --daily 7 --weekly 4 --monthly 3 --age 100 --restore 20
k backup --daily 30 --weekly 12 --monthly 12 --age 400
step "3. Eine Sicherung ersetzt weder Replikation noch Sperre (Fachwissen, kein Modellergebnis)"
echo "Gelöscht wird auch der Schutz, wenn das Löschen nicht abgesichert ist (Soft Delete, Sperre); das Modell bildet das nicht ab."
step "4. Metrik-Alarm: Mittelwert über ein Fenster gegen Schwellwert (Modell)"
k alert --series 20 30 45 80 85 90 60 30 --window 3 --threshold 75
k alert --series 20 30 45 80 20 90 20 30 --window 3 --threshold 75
step "5. Kurze Spitzen lösen mit größerem Fenster nicht aus (Modell)"
k alert --series 20 30 45 80 20 90 20 30 --window 2 --threshold 75
k alert --series 90 10 10 10 --window 1 --threshold 75
step "6. Alarm bei zu wenig freiem Speicher (Operator <) (Modell)"
k alert --series 40 30 20 10 8 --window 2 --threshold 15 --op '<'
