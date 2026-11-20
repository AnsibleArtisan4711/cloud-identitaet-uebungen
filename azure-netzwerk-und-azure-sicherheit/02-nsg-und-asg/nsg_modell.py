#!/usr/bin/env python3
"""Modell: Netzwerksicherheitsgruppe. Regeln nach Priorität (kleinere Zahl zuerst), erste passende Regel entscheidet; am Ende Standardregeln. Vereinfacht (Richtung eingehend, Protokoll TCP, Ziel-Port). Erfundene Regeln."""
import ipaddress as ip
regeln = [(100, "erlaube-https", "Allow", "*", 443), (200, "erlaube-ssh-intern", "Allow", "10.57.2.0/24", 22), (300, "verbiete-ssh", "Deny", "*", 22)]
standard = [(65000, "AllowVnetInBound", "Allow", "10.57.0.0/16", "*"), (65500, "DenyAllInBound", "Deny", "*", "*")]
def passt(r, quelle, port):
    _, _, _, q, p = r
    return (q == "*" or ip.ip_address(quelle) in ip.ip_network(q)) and (p == "*" or p == port)
def pruefe(quelle, port):
    for r in sorted(regeln + standard):
        if passt(r, quelle, port): return r[2], r[1]
for q, p in (("203.0.113.5", 443), ("10.57.2.10", 22), ("203.0.113.5", 22), ("10.57.5.5", 3389), ("203.0.113.5", 3389)):
    e, n = pruefe(q, p); print(f"Quelle {q:<12} Port {p:<5} -> {e:<5} durch {n}")
