#!/usr/bin/env python3
"""Vergleich häufiger Begriffe bei AWS, Azure und Google Cloud. Status F: Fachwissen, nicht bestätigt (nicht gegen die Dokumentation geprüft)."""
tab = [("Privates Netzwerk", "VPC", "VNet", "VPC-Netzwerk"), ("Rechner", "EC2", "Virtuelle Maschine", "Compute Engine"),
       ("Objektspeicher", "S3", "Blob Storage", "Cloud Storage"), ("Rechteverwaltung", "IAM", "RBAC (Entra ID)", "IAM"),
       ("Überwachung", "CloudWatch", "Azure Monitor", "Cloud Monitoring")]
w = [max(len(r[i]) for r in tab + [("Konzept", "AWS", "Azure", "Google Cloud")]) for i in range(4)]
print(f"{'Konzept':<{w[0]}}  {'AWS':<{w[1]}}  {'Azure':<{w[2]}}  {'Google Cloud':<{w[3]}}  Status")
for r in tab: print(f"{r[0]:<{w[0]}}  {r[1]:<{w[1]}}  {r[2]:<{w[2]}}  {r[3]:<{w[3]}}  F")
print("\nAlle 5 Zeilen: F (nicht bestätigt). Die Dienste unterscheiden sich im Detail; Gleichsetzen ist nur eine grobe Orientierung.")
