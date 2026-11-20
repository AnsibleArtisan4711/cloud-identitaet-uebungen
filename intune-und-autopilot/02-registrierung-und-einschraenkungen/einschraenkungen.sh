#!/usr/bin/env bash
# Modul 2: Registrierung: Lizenz, MDM-Benutzerbereich, Einschränkungen, Gerätelimit. Modell; die Voraussetzungen sind aus Microsoft Learn (Auszug) gelesen, das Limit ist ein Modellwert.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Ausgangslage (Modell): ana mit Lizenz im Bereich, ben ohne Lizenz, cem ohne MDM-Bereich"
k user ana
k user ben
k user cem
step "2. Registrierungsversuche (Modell)"
k enroll try --user ben --os windows --ownership corporate --name PC-BEN || true
k enroll try --user cem --os windows --ownership corporate --name PC-CEM || true
k enroll try --user ana --os windows --ownership corporate --name PC-ANA-1
k enroll try --user ana --os windows --ownership personal --name PC-ANA-PRIVAT
step "3. Private Windows-Geräte sperren (Modell; Learn: Einschränkungen können private Windows-Geräte blockieren)"
k restrict set --block-personal yes
k enroll try --user ana --os windows --ownership personal --name PC-ANA-PRIVAT-2 || true
step "4. Gerätelimit (Modellwert 3)"
k enroll try --user ana --os windows --ownership corporate --name PC-ANA-2
k enroll try --user ana --os windows --ownership corporate --name PC-ANA-3 || true
step "5. Ursachen beheben: Lizenz und Bereich ergänzen (Modell)"
k user ben --license yes
k user cem --scope yes
k enroll try --user ben --os windows --ownership corporate --name PC-BEN
k enroll try --user cem --os windows --ownership corporate --name PC-CEM
