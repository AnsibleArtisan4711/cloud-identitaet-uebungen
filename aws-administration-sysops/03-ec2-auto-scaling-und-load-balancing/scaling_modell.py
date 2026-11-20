#!/usr/bin/env python3
"""Modell: Ziel-Auslastung (Target Tracking) für eine Auto-Scaling-Gruppe. Gewünschte Anzahl = aufrunden(aktuell * Auslastung / Ziel), begrenzt auf Minimum und Maximum. Ohne Abkühlzeit, erfundene Last."""
import math
ziel, mn, mx = 50, 2, 6
last = [60, 140, 220, 300, 260, 120, 60]   # Anfragen pro Sekunde (erfunden), je Instanz 100 = 100 % Auslastung
n = mn
print("Minute Last  Instanzen  Auslastung  gewünscht")
for t, l in enumerate(last):
    ausl = l / n
    wunsch = max(mn, min(mx, math.ceil(n * ausl / ziel)))
    print(f"{t:>6} {l:>5} {n:>9} {ausl:>10.0f} % {wunsch:>9}")
    n = wunsch
