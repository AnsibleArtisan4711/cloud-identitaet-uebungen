#!/usr/bin/env python3
"""Modell: Verbindungsdiagnose entlang der Kette Namensauflösung -> Route -> Sicherheitsgruppe. Meldet das erste blockierende Glied. Erfundene Zustände."""
faelle = [
  ("vm1 -> konto1 (Port 443)", {"dns": True,  "route": True,  "nsg": True}),
  ("vm1 -> db1 (Port 1433)",   {"dns": True,  "route": True,  "nsg": False}),
  ("vm2 -> konto1 (Port 443)", {"dns": False, "route": True,  "nsg": True}),
  ("vm3 -> app1 (Port 80)",    {"dns": True,  "route": False, "nsg": True}),
]
for text, kette in faelle:
    blockiert = next((k for k in ("dns", "route", "nsg") if not kette[k]), None)
    print(f"{text:<26} -> " + ("erreichbar" if blockiert is None else f"blockiert bei: {blockiert}"))
