#!/usr/bin/env python3
"""Modell: Verfügbarkeit einer Datenbank mit und ohne Reserve in einer zweiten Zone. Erfundene Werte (Verfügbarkeit je Zone 99,9 %)."""
a = 0.999
einzel = a
mit = 1 - (1 - a) ** 2
minuten = 365 * 24 * 60
print(f"eine Zone:     {einzel*100:.4f} %  -> bis zu {minuten*(1-einzel):.0f} Minuten Ausfall pro Jahr")
print(f"zwei Zonen:    {mit*100:.4f} %  -> bis zu {minuten*(1-mit):.2f} Minuten Ausfall pro Jahr (Rechenmodell, Umschaltzeit nicht berücksichtigt)")
