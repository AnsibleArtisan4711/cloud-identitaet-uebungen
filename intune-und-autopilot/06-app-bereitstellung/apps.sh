#!/usr/bin/env bash
# Modul 6: App-Bereitstellung: Absichten, Erkennungsregeln, Prüfsumme. Echt: SHA-256 (hashlib) und JSON. Modell: Zuweisung und Erkennung. Die Absichten Available, Required, Uninstall sind aus Microsoft Learn (Auszug) gelesen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Prüfsumme eines Installationspakets (echt: SHA-256)"
printf 'Dies ist ein erfundenes Installationspaket.\n' > paket.bin
H=$(sha256sum paket.bin | cut -d' ' -f1)
k app sha256 paket.bin $H
printf 'Dies ist ein veraendertes Paket.\n' > paket2.bin
k app sha256 paket2.bin $H
step "2. Zuweisungen mit Absicht (Modell; Learn: mehrere Absichten für dieselbe Gruppe sind nicht möglich)"
k app intent --group alle:available technik:required
k app intent --group technik:required technik:available || true
step "3. Erkennungsregeln (Modell): wann gilt eine App als installiert?"
cat > regeln.json <<'J'
[ { "type": "file", "path": "C:/Programme/App/app.exe" }, { "type": "version", "path": "C:/Programme/App/app.exe", "min": "2.1" } ]
J
echo '{ "C:/Programme/App/app.exe": "2.3" }' > geraet-neu.json
echo '{ "C:/Programme/App/app.exe": "1.9" }' > geraet-alt.json
echo '{}' > geraet-leer.json
python3 -c "import json; [json.load(open(f)) for f in ('regeln.json','geraet-neu.json','geraet-alt.json','geraet-leer.json')]; print('Alle Dateien sind gültiges JSON (echt)')"
for g in neu alt leer; do echo "Gerät $g:"; k app detect regeln.json geraet-$g.json; done
echo "Der Versionsvergleich im Modell ist ein Textvergleich und gilt nur für diese Beispiele."
step "4. Hinweis (Fachwissen, nicht bestätigt)"
echo "Ohne passende Erkennungsregel kann eine installierte App als „nicht installiert“ gelten und die Installation wiederholt werden; das Verpacken (Win32) wurde nicht ausgeführt."
