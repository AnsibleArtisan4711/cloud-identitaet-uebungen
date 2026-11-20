#!/usr/bin/env python3
"""Modell: Ressourcenhierarchie Organisation -> Ordner -> Projekt. Berechtigungen werden nach unten vererbt (Vereinigung); Abrechnungskonto ist einem Projekt zugeordnet. Erfundene Namen und Rollen."""
bindungen = [("org", "anna", "Betrachter"), ("org/ordner-dev", "ben", "Bearbeiter"), ("org/ordner-dev/projekt-web", "cara", "Administrator")]
abrechnung = {"org/ordner-dev/projekt-web": "konto-1", "org/ordner-dev/projekt-test": None}
def wirksam(person, pfad):
    return sorted({r for ort, p, r in bindungen if p == person and (pfad == ort or pfad.startswith(ort + "/"))})
for p, pfad in (("anna", "org/ordner-dev/projekt-web"), ("ben", "org/ordner-dev/projekt-web"), ("cara", "org/ordner-dev/projekt-test"), ("cara", "org/ordner-dev/projekt-web")):
    print(f"{p:<5} auf {pfad:<28} -> {wirksam(p, pfad) or 'keine'}")
print()
for pr, k in abrechnung.items():
    print(f"{pr:<28} Abrechnung: {k or 'KEIN Abrechnungskonto -> kostenpflichtige Dienste nicht nutzbar'}")
