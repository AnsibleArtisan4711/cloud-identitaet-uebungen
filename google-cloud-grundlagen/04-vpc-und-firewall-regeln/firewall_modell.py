#!/usr/bin/env python3
"""Modell: Firewallregeln eines VPC nach Priorität (kleinere Zahl zuerst); ohne Treffer gilt eingehend verboten. Vereinfacht, erfundene Regeln."""
regeln = [(1000, "erlaube-https", "allow", "0.0.0.0/0", 443), (1000, "erlaube-ssh-intern", "allow", "10.58.0.0/16", 22), (900, "verbiete-telnet", "deny", "0.0.0.0/0", 23)]
import ipaddress as ip
def pruefe(quelle, port):
    for pr, n, a, q, p in sorted(regeln):
        if p == port and ip.ip_address(quelle) in ip.ip_network(q): return a, n
    return "deny", "implizites Verbot eingehend"
for q, p in (("203.0.113.5", 443), ("10.58.1.1", 22), ("203.0.113.5", 22), ("203.0.113.5", 23)):
    a, n = pruefe(q, p); print(f"Quelle {q:<12} Port {p:<4} -> {a:<5} ({n})")
