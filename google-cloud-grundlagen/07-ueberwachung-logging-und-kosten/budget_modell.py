#!/usr/bin/env python3
"""Modell: Budgetwarnungen bei 50 %, 90 % und 100 % und Hochrechnung. Erfundene Beträge."""
budget, tage_monat = 30.0, 30
verlauf = [(7, 4.0), (14, 11.0), (21, 21.0), (28, 31.5)]
for tag, k in verlauf:
    prog = k / tag * tage_monat
    st = [s for s in (50, 90, 100) if k >= budget * s / 100]
    print(f"Tag {tag:>2}: bisher {k:>5.2f} ({k/budget*100:>3.0f} %), Prognose {prog:>6.2f}, Schwellen: {st or '-'}")
