#!/usr/bin/env python3
"""Modell: Speicherklassen nach Zugriffshäufigkeit. Preise sind ERFUNDEN; echte Preise und Mindestlaufzeiten mit Stand prüfen."""
klassen = [("Standard", 0.020, 0), ("Nearline", 0.010, 30), ("Coldline", 0.004, 90), ("Archive", 0.0012, 365)]
daten_gb = 500
print("Klasse     Preis/GB (erfunden)  Mindestlaufzeit Tage  Kosten pro Monat")
for n, p, tage in klassen: print(f"{n:<10} {p:>10.4f} {tage:>20} {daten_gb*p:>17.2f}")
print("\nKurze Mindestlaufzeit lohnt bei häufigem Zugriff; Archivklassen sind für selten gelesene Daten gedacht (Fachwissen, nicht bestätigt).")
