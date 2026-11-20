#!/usr/bin/env bash
# Modul 3: Windows Autopilot: Hardware-Hash-Datei (Regeln aus Microsoft Learn, Auszug, ECHT geprüft), Profile, Modi. Modell für Registrierung und Zuordnung; der Hash ist ERFUNDEN.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url --body
echo "Get-WindowsAutopilotInfo (PowerShell) erzeugt die Hash-Datei auf einem Windows-Gerät; es wurde NICHT ausgeführt und nicht geprüft."
step "2. Gültige Hash-Datei prüfen (echt: Regeln nach Microsoft Learn; die Hashes sind ERFUNDEN)"
printf 'Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User\nSN-0001,,AAAA1111erfunden,Vertrieb,ana@labmuster.example\nSN-0002,,BBBB2222erfunden,Technik,\nSN-0003,,CCCC3333erfunden,,\n' > gut.csv
k ap check-csv gut.csv
step "3. Typische Fehler (echt geprüft)"
printf 'Device Serial Number,Windows Product ID,Hardware Hash,Group Tag\nSN-0001,,AAAA1111erfunden,Vertrieb\n' > falsch-kopf.csv
printf 'device serial number,Windows Product ID,Hardware Hash,Group Tag,Assigned User\nSN-0001,,AAAA1111erfunden,Vertrieb,\n' > falsch-gross.csv
printf 'Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User\n"SN-0001",,AAAA1111erfunden,Vertrieb,\nSN-0002,,,Technik,\nSN-0003,,CCCC3333erfunden,,kein-upn\n' > falsch-inhalt.csv
printf '\xef\xbb\xbfDevice Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User\nSN-0001,,AAAA1111erfunden,Vertrieb,\n' > falsch-bom.csv
for f in falsch-kopf falsch-gross falsch-inhalt falsch-bom; do k ap check-csv $f.csv || true; done
step "4. Importieren, Profil erstellen und zuordnen (Modell)"
k ap import gut.csv
k ap profile --name profil-vertrieb --mode user-driven --join entra --tag Vertrieb
k ap profile --name profil-technik --mode self-deploying --join entra --tag Technik
for sn in SN-0001 SN-0002 SN-0003 SN-9999; do k ap boot $sn; done
step "5. Selbstbereitstellend und hybrid (Modell; aus Microsoft Learn, Auszug, 20.11.2026, gelesen)"
k ap profile --name profil-hybrid --mode self-deploying --join hybrid || true
