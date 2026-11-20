#!/usr/bin/env bash
# Modul 8: Anwendungsregistrierungen, Rechte, Token (RS256 echt gerechnet) und Abschluss. Modell für Registrierung; Token echt (PyJWT, cryptography).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "ad app create" --display-name --web-redirect-uris
azchk "ad app credential reset" --id --years
azchk "ad sp create" --id
step "2. Anwendung registrieren (Modell): Umleitung und Geheimnis"
k app create berichte --redirect https://berichte.example.test/anmeldung --secret-days 180
k app create unsicher --redirect http://berichte.example.test/anmeldung || true
k app create langlebig --redirect https://x.example.test/ --secret-days 3650 || true
step "3. Rechte: delegiert und Anwendungsrecht (Modell)"
k app perm berichte --delegated User.Read --application Mail.Read
k app show berichte
k app consent berichte
k app show berichte
step "4. Token prüfen (echt: RS256-Signatur mit PyJWT und cryptography)"
k token
step "5. Abschluss: Kette von der Registrierung bis zur Prüfung (Zusammenfassung)"
echo "Registrierung legt fest, wer die App ist und was sie darf; das Token belegt, wer sich angemeldet hat; die Ressource prüft Signatur, Aussteller, Zielgruppe und Zeit."
echo "Die Schlüssel in Schritt 4 werden bei jedem Lauf neu erzeugt; die Ausgabe enthält nur Werte, die davon nicht abhängen."
