#!/usr/bin/env python3
"""Modell: Adressplan für virtuelle Netzwerke und Prüfung auf überlappende Adressräume (Peering braucht überlappungsfreie Räume). Rechnung mit ipaddress; erfundene Adressen."""
import ipaddress as ip
vnets = {"hub": ["10.57.0.0/16"], "app": ["10.58.0.0/16"], "test": ["10.58.128.0/17"], "onprem": ["192.168.0.0/16"]}
print("Subnetze im Hub (10.57.0.0/16): ")
for n, s in (("firewall", "10.57.0.0/26"), ("gateway", "10.57.1.0/27"), ("verwaltung", "10.57.2.0/24")):
    net = ip.ip_network(s); print(f"  {n:<11} {s:<14} Adressen {net.num_addresses}, nutzbar nach Abzug von 5 reservierten {net.num_addresses - 5}")
print("\nPeering-Prüfung (Überlappung der Adressräume):")
namen = list(vnets)
for i in range(len(namen)):
    for j in range(i + 1, len(namen)):
        a, b = namen[i], namen[j]
        ueber = any(ip.ip_network(x).overlaps(ip.ip_network(y)) for x in vnets[a] for y in vnets[b])
        print(f"  {a:<6} <-> {b:<6} {'ÜBERLAPPUNG: Peering nicht möglich' if ueber else 'ok'}")
