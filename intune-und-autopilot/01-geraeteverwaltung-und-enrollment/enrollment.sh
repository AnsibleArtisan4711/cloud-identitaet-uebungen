#!/usr/bin/env bash
# Modul 1: Geräteverwaltung (MDM und MAM) und Registrierungswege. Modell nach Fachwissen; keine Intune-Verbindung.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Befehle prüfen (echt gegen die installierte Azure CLI, offline)"
azver
azchk "rest" --method --url --body
echo "Intune wird im echten Mandanten über das Verwaltungszentrum oder die Graph-Schnittstelle bedient (az rest); hier nicht ausgeführt."
step "2. Lizenzstand (Microsoft Learn, Suchauszug 20.11.2026)"
echo "Intune ist in einigen Microsoft-365-Plänen enthalten (laut Auszug u. a. Business Premium, F1/F3, E3/E5, EMS E3/E5 und Intune for Education)."
echo "Auch bei einem Microsoft-365-Abonnement müssen Lizenzen den Benutzern zugewiesen werden, damit sie Geräte registrieren können."
echo "Entra ID P1 oder P2 (Bedingter Zugriff, MFA, dynamische Gruppen) kann zusätzlich nötig sein. Aktuelle Pläne vor der Anwendung prüfen."
step "3. Welcher Weg passt? (Modell nach Fachwissen, nicht bestätigt)"
k enroll decide --os windows --ownership corporate --new yes
k enroll decide --os windows --ownership corporate --new no
k enroll decide --os windows --ownership personal
k enroll decide --os android --ownership corporate
step "4. MDM und MAM (Fachwissen, kein Modellergebnis)"
echo "MDM: Das Gerät wird registriert und als Ganzes verwaltet (Profile, Richtlinien, Apps, Löschen)."
echo "MAM: Nur Apps und deren Daten werden geschützt; das Gerät bleibt unverwaltet (typisch für private Geräte)."
