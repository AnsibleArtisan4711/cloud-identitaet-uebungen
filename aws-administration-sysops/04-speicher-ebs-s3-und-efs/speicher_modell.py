#!/usr/bin/env python3
"""Modell: Lebenszyklus von Objekten (S3). Kosten pro Monat mit ERFUNDENEN Preisen je GB (keine echten Preise) für Standard und Seltener Zugriff nach 30 Tagen."""
preis = {"standard": 0.023, "selten": 0.0125}   # erfunden
daten_gb = 1000; neu_pro_monat = 100
print("Monat  Standard-GB  Selten-GB  Kosten ohne Regel  Kosten mit Regel (nach 1 Monat)")
st_ohne = 0
for m in range(1, 7):
    ohne = daten_gb * preis["standard"] if m == 1 else (daten_gb + neu_pro_monat * (m - 1)) * preis["standard"]
    gesamt = daten_gb + neu_pro_monat * (m - 1)
    standard = neu_pro_monat if m > 1 else daten_gb
    selten = gesamt - standard
    mit = standard * preis["standard"] + selten * preis["selten"]
    print(f"{m:>5} {standard:>12} {selten:>10} {ohne:>18.2f} {mit:>17.2f}")
print("\nPreise sind erfunden; echte Preise und Mindestlaufzeiten der Speicherklassen mit Stand prüfen.")
