#!/usr/bin/env python3
"""Modell: VPC-Adressplan und Routenauswahl (längstes Präfix). Rechnung mit dem Modul ipaddress; erfundene Adressen und Namen."""
import ipaddress as ip
vpc = ip.ip_network("10.56.0.0/16")
teile = list(vpc.subnets(new_prefix=24))
plan = [("public-a", teile[0]), ("public-b", teile[1]), ("private-a", teile[10]), ("private-b", teile[11])]
print(f"VPC {vpc}: {len(teile)} Subnetze der Größe /24 möglich")
for n, s in plan:
    print(f"  {n:<10} {s}  Adressen gesamt {s.num_addresses}  nutzbar nach Abzug von 5 reservierten: {s.num_addresses - 5}")
routen = {"10.56.0.0/16": "local", "0.0.0.0/0": "igw-1", "10.57.0.0/16": "pcx-1"}
def route(ziel):
    z = ip.ip_address(ziel)
    treffer = [(ip.ip_network(p), t) for p, t in routen.items() if z in ip.ip_network(p)]
    return max(treffer, key=lambda x: x[0].prefixlen)
print("\nRouten:", routen)
for z in ("10.56.10.5", "10.57.1.1", "8.8.8.8"):
    p, t = route(z); print(f"  Ziel {z:<11} -> {t} (Präfix {p})")
