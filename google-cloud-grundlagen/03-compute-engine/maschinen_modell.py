#!/usr/bin/env python3
"""Modell: kleinsten passenden Maschinentyp wählen. Typen sind ERFUNDEN (keine echten Typen oder Preise von Compute Engine)."""
typen = [("klein", 2, 4, 0.02), ("mittel", 4, 8, 0.04), ("gross", 8, 16, 0.08)]
bedarf = [("Webserver", 2, 3), ("Datenbank", 4, 12), ("Batch", 6, 8)]
for n, cpu, ram in bedarf:
    t = next((t for t in typen if t[1] >= cpu and t[2] >= ram), None)
    print(f"{n:<9} braucht {cpu} CPU / {ram} GB -> " + (f"Typ {t[0]} ({t[1]} CPU, {t[2]} GB), {t[3]:.2f} je Stunde (erfunden), {t[3]*730:.2f} je Monat" if t else "kein Typ passt"))
