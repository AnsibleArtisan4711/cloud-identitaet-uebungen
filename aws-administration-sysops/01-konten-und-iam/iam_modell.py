#!/usr/bin/env python3
"""Modell: Auswertung von Berechtigungsrichtlinien: ausdrückliches Verbot (Deny) schlägt Erlaubnis (Allow), ohne Erlaubnis ist alles verboten. Vereinfacht (nur Aktion und Ressource mit Platzhalter *), erfundene Richtlinien."""
from fnmatch import fnmatch
richtlinien = {
  "anna":  [("Allow", "s3:*", "arn:aws:s3:::berichte/*"), ("Deny", "s3:DeleteObject", "arn:aws:s3:::berichte/*")],
  "ben":   [("Allow", "ec2:Describe*", "*")],
  "admin": [("Allow", "*", "*")],
}
def erlaubt(benutzer, aktion, ressource):
    allow = False
    for effekt, a, r in richtlinien[benutzer]:
        if fnmatch(aktion, a) and fnmatch(ressource, r):
            if effekt == "Deny": return "verboten (ausdrückliches Deny)"
            allow = True
    return "erlaubt" if allow else "verboten (kein Allow, implizit)"
faelle = [("anna", "s3:GetObject", "arn:aws:s3:::berichte/q1.pdf"), ("anna", "s3:DeleteObject", "arn:aws:s3:::berichte/q1.pdf"),
          ("ben", "ec2:DescribeInstances", "*"), ("ben", "ec2:StartInstances", "*"), ("admin", "iam:DeleteUser", "*")]
for b, a, r in faelle: print(f"{b:<6} {a:<22} -> {erlaubt(b, a, r)}")
