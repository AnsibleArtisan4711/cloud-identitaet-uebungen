#!/usr/bin/env python3
"""Modell: Auswertung erfundener Flow-Protokolle einer NSG: abgelehnte Verbindungen je Quelle zählen und bei Überschreiten einer Schwelle melden."""
from collections import Counter
zeilen = """203.0.113.5 10.57.2.10 22 Deny
203.0.113.5 10.57.2.10 22 Deny
203.0.113.5 10.57.2.11 3389 Deny
198.51.100.7 10.57.2.10 443 Allow
203.0.113.5 10.57.2.12 22 Deny
10.57.2.50 10.57.2.10 22 Allow
198.51.100.9 10.57.2.10 3389 Deny""".splitlines()
abgelehnt = Counter(z.split()[0] for z in zeilen if z.endswith("Deny"))
schwelle = 3
for q, n in abgelehnt.most_common():
    print(f"{q:<14} {n} abgelehnt" + ("  -> ALARM (Schwelle %d)" % schwelle if n >= schwelle else ""))
print("Gesamt:", len(zeilen), "Zeilen,", sum(abgelehnt.values()), "abgelehnt")
