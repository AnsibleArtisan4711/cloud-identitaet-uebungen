#!/usr/bin/env python3
"""Modell: Sicherungsaufbewahrung einer Datenbank. Punktgenaue Wiederherstellung ist nur innerhalb der Aufbewahrungszeit möglich. Erfundene Werte."""
aufbewahrung_tage = 7
vorfaelle = [("Tabelle versehentlich gelöscht", 2), ("Fehler entdeckt nach", 9), ("Datenfehler seit", 5)]
print(f"Aufbewahrung: {aufbewahrung_tage} Tage")
for text, tage in vorfaelle:
    print(f"  {text} {tage} Tagen -> {'Wiederherstellung möglich' if tage <= aufbewahrung_tage else 'außerhalb der Aufbewahrung: nur ein älterer Snapshot (falls vorhanden)'}")
print("\nSpeicher: 200 GB, Wachstum 5 GB/Monat -> in 12 Monaten", 200 + 5 * 12, "GB")
