#!/usr/bin/env bash
# Modul 6: Bedingter Zugriff als Modell: Richtlinien als JSON (echt gelesen), Auswertung (Modell). Lizenzstand aus Microsoft Learn (Auszug).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url --body
echo "Bedingter Zugriff wird im echten Entra ID über das Portal oder die Graph-Schnittstelle verwaltet; hier nicht ausgeführt."
step "2. Richtlinien als JSON (eigenes Format, nicht das echte Graph-Format), echt gelesen"
cat > mfa-alle.json <<'J'
{ "name": "MFA fuer alle", "state": "enabled", "users": { "include": ["all"], "exclude": ["notfall"] }, "apps": ["all"], "grant": ["mfa"] }
J
cat > geraet-admins.json <<'J'
{ "name": "Admins nur konform", "state": "enabled", "users": { "include": ["admins"], "exclude": ["notfall"] }, "apps": ["all"], "grant": ["compliantDevice"] }
J
cat > extern-sperren.json <<'J'
{ "name": "Fremdplattform sperren", "state": "enabled", "users": { "include": ["all"], "exclude": ["notfall"] }, "apps": ["all"], "conditions": { "platforms": ["linux"] }, "grant": "block" }
J
cat > risiko.json <<'J'
{ "name": "Hohes Risiko MFA", "state": "enabled", "users": { "include": ["all"], "exclude": ["notfall"] }, "apps": ["all"], "conditions": { "userRisk": ["high"] }, "grant": ["mfa"] }
J
cat > bericht.json <<'J'
{ "name": "Nur Bericht", "state": "reportOnly", "users": { "include": ["all"] }, "apps": ["Office"], "grant": ["compliantDevice"] }
J
python3 -c "import json; [json.load(open(f)) for f in ('mfa-alle.json','geraet-admins.json','extern-sperren.json','risiko.json','bericht.json')]; print('Alle Richtlinien sind gültiges JSON (echt)')"
POL="--policies mfa-alle.json geraet-admins.json extern-sperren.json bericht.json"
ev() { echo "\$ entrasim ca $*"; python3 "$HERE/entrasim.py" ca "$@"; }
step "3. Anfragen auswerten (Modell, Lizenz P1)"
ev $POL --user ana --app Office --mfa no
ev $POL --user ana --app Office --mfa yes
ev $POL --user dora --groups admins --app Office --mfa yes --compliant no
ev $POL --user dora --groups admins --app Office --mfa yes --compliant yes
step "4. Eine Sperre schlägt alles; die Notfallkonten sind ausgenommen (Modell)"
ev $POL --user ana --app Office --platform linux --mfa yes
ev $POL --user notfall --groups notfall --app Office --platform linux
step "5. Risiko-Bedingung braucht P2 (Modell, Lizenzstand aus Microsoft Learn-Auszug)"
POL2="--policies mfa-alle.json risiko.json"
ev $POL2 --user ana --app Office --risk high --mfa yes --license p1
ev $POL2 --user ana --app Office --risk high --mfa no --license p2
step "6. Ohne P1 gibt es keinen Bedingten Zugriff (Modell)"
ev $POL --user ana --app Office --license free
