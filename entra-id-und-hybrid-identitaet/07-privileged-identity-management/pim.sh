#!/usr/bin/env bash
# Modul 7 (Priorität 2): Privileged Identity Management im Überblick. Modell; Lizenzstand aus Microsoft Learn (Auszug).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url
echo "PIM wird im echten Entra ID im Portal oder über die Graph-Schnittstelle bedient; hier nicht ausgeführt."
step "2. Lizenzstand (Microsoft Learn, Suchauszug 20.11.2026)"
echo "PIM ist laut dem Auszug in Entra ID P2, Entra ID Governance und Entra Suite enthalten, nicht in Free und P1."
k pim assign ana "Global Administrator" --type eligible --license p1 || true
step "3. Berechtigt (eligible) und aktiv (Modell; Zeit in Minuten)"
k pim assign ana "Global Administrator" --type eligible
k pim assign ben "Helpdesk Administrator" --type active
k pim status --at 0
step "4. Aktivierung mit Begründung und Dauer (Modell)"
k pim activate ana "Global Administrator" --minutes 60 --at 100 --reason "Konto fuer Rolle anlegen" 
k pim status --at 120
k pim status --at 160
step "5. Fehlerfälle: ohne Begründung, zu lang, aktive Zuweisung (Modell)"
k pim activate ana "Global Administrator" --minutes 60 --at 200 || true
k pim activate ana "Global Administrator" --minutes 600 --at 200 --reason "Wartung" || true
k pim activate ben "Helpdesk Administrator" --minutes 30 --at 200 --reason "Test" || true
step "6. Genehmigung verlangen (Modell)"
k pim assign cem "Security Reader" --type eligible --approval
k pim activate cem "Security Reader" --minutes 30 --at 300 --reason "Analyse" || true
k pim activate cem "Security Reader" --minutes 30 --at 300 --reason "Analyse" --approved
