#!/usr/bin/env bash
# Modul 5: Mehrfaktor-Authentifizierung: TOTP (RFC 6238) ECHT gerechnet; Methodenvergleich und Lizenzstand aus Microsoft Learn (Auszug).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url --body
echo "Authentifizierungsmethoden-Richtlinien werden im echten Entra ID über die Graph-Schnittstelle gesetzt (az rest); hier nicht ausgeführt."
step "2. TOTP gegen die Testwerte der RFC 6238 prüfen (echt gerechnet)"
k mfa selftest
step "3. Codes mit einem erfundenen Schlüssel (Base32) (echt gerechnet)"
SEC=JBSWY3DPEHPK3PXP
for t in 1000 1029 1030 1059 1060; do k mfa code --secret $SEC --time $t; done
step "4. Prüfung mit Toleranzfenster: eine Uhr, die nachgeht (echt gerechnet)"
CODE=$(python3 "$HERE/entrasim.py" mfa code --secret $SEC --time 1000 | sed -E 's/.*Code ([0-9]+).*/\1/')
k mfa verify --secret $SEC --time 1000 --code $CODE
k mfa verify --secret $SEC --time 1030 --code $CODE
k mfa verify --secret $SEC --time 1030 --code $CODE --window 1
k mfa verify --secret $SEC --time 1090 --code $CODE --window 1
step "5. Lizenzstand (Microsoft Learn, Suchauszug 20.11.2026, nicht die ganze Seite)"
echo "Sicherheitsstandards (Security Defaults): für alle Kunden verfügbar, MFA ohne granulare Steuerung."
echo "Bedingter Zugriff (MFA nach Bedarf): erfordert Entra ID P1."
echo "Risikobasierte Richtlinien: erfordern Entra ID P2."
echo "Der Auszug nennt P1 als enthalten in Microsoft 365 E3/E5/F1/F3 und Business Premium; P2 in E5. Aktuelle Pläne vor der Anwendung prüfen."
