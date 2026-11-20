#!/usr/bin/env python3
"""Modell: Budgetwarnungen bei 50 %, 80 % und 100 % der Monatsgrenze, mit Hochrechnung auf den Monatsende. Erfundene Beträge."""
budget = 20.0; tage_monat = 30
verlauf = [(5, 2.0), (10, 5.5), (15, 9.5), (20, 15.0), (25, 19.0)]   # (Tag, bisherige Kosten)
print(f"Budget {budget:.2f} (Währung egal)")
for tag, k in verlauf:
    prognose = k / tag * tage_monat
    st = [s for s in (50, 80, 100) if k >= budget * s / 100]
    print(f"Tag {tag:>2}: bisher {k:>5.2f} ({k/budget*100:>3.0f} %), Prognose {prognose:>6.2f} {'ÜBER Budget' if prognose > budget else 'im Rahmen'}, Schwellen erreicht: {st or '-'}")
