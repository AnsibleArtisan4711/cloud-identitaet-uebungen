#!/usr/bin/env python3
"""Modell: Routenauswahl mit eigenen Routen (UDR) nach längstem Präfix; bei gleichem Präfix gewinnt die eigene Route vor der Systemroute. Vereinfacht, erfundene Adressen."""
import ipaddress as ip
routen = [("10.57.0.0/16", "VirtualNetwork", "System"), ("0.0.0.0/0", "Internet", "System"),
          ("0.0.0.0/0", "10.57.0.4 (Firewall)", "Eigene"), ("10.60.0.0/16", "10.57.0.4 (Firewall)", "Eigene")]
rang = {"Eigene": 0, "System": 1}
def wahl(ziel):
    z = ip.ip_address(ziel)
    t = [(ip.ip_network(p), h, q) for p, h, q in routen if z in ip.ip_network(p)]
    return min(t, key=lambda x: (-x[0].prefixlen, rang[x[2]]))
for z in ("10.57.3.4", "10.60.1.1", "8.8.8.8"):
    p, h, q = wahl(z); print(f"Ziel {z:<10} -> {h:<22} (Präfix {p}, Quelle {q})")
