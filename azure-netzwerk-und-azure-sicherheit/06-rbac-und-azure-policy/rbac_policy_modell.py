#!/usr/bin/env python3
"""Modell: Rollenzuweisungen werden nach unten vererbt (Pfad: Verwaltungsgruppe/Abonnement/Ressourcengruppe/Ressource); eine Richtlinie prüft Eigenschaften neuer Ressourcen. Erfundene Zuweisungen."""
zuweisungen = [("gruppe1", "anna", "Leser"), ("gruppe1/sub1", "ben", "Mitwirkender"), ("gruppe1/sub1/rg-web", "cara", "Besitzer")]
def wirksam(person, pfad):
    return [r for ort, p, r in zuweisungen if p == person and (pfad == ort or pfad.startswith(ort + "/"))]
for p, pfad in (("anna", "gruppe1/sub1/rg-web/vm1"), ("ben", "gruppe1/sub1/rg-web/vm1"), ("cara", "gruppe1/sub1/rg-db"), ("cara", "gruppe1/sub1/rg-web")):
    print(f"{p:<5} auf {pfad:<26} -> {wirksam(p, pfad) or 'keine'}")
erlaubt = {"westeurope", "northeurope"}
print("\nRichtlinie 'erlaubte Regionen' (Effekt Deny):")
for name, region in (("vm1", "westeurope"), ("vm2", "eastus")):
    print(f"  {name} in {region:<11} -> {'erlaubt' if region in erlaubt else 'abgelehnt (Deny)'}")
print("Richtlinie 'Pflicht-Tag kostenstelle' (Effekt Audit): Ressourcen ohne Tag werden nur gemeldet, nicht abgelehnt")
