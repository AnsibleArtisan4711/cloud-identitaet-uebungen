#!/usr/bin/env python3
"""Modell: Zugriff auf Geheimnisse über Rollen. Erfundene Rollennamen mit eigenen Berechtigungen (NICHT die echten Rollen von Azure; deren Namen und Rechte stehen in der Dokumentation)."""
rollen = {"Geheimnisleser": {"get", "list"}, "Geheimnisverwalter": {"get", "list", "set", "delete"}, "Leser": set()}
zuweisung = {"app1": "Geheimnisleser", "admin1": "Geheimnisverwalter", "praktikant": "Leser"}
for wer, rolle in zuweisung.items():
    for aktion in ("get", "set"):
        print(f"{wer:<11} Rolle {rolle:<19} {aktion:<4} -> {'erlaubt' if aktion in rollen[rolle] else 'verboten'}")
print("\nGeheimnis 'db-passwort' wird 90 Tage alt: Erneuerung planen; Ablaufdatum prüfen, nie im Klartext in Dateien oder Repositories ablegen.")
