#!/usr/bin/env python3
"""Modell: prüft die Struktur einer CloudFormation-Vorlage im JSON-Format auf typische Fehler (Ref auf Unbekanntes, fehlende Ressourcen). Eigene Beispielregeln, kein Ersatz für die Prüfung durch AWS."""
import json
gut = {"AWSTemplateFormatVersion": "2010-09-09", "Parameters": {"Umgebung": {"Type": "String", "Default": "test"}},
       "Resources": {"Daten": {"Type": "AWS::S3::Bucket", "Properties": {"BucketName": {"Fn::Sub": "berichte-${Umgebung}"}}}},
       "Outputs": {"Bucket": {"Value": {"Ref": "Daten"}}}}
schlecht = {"Resources": {"Daten": {"Type": "AWS::S3::Bucket", "Properties": {"BucketName": {"Ref": "Umgebung"}}}},
            "Outputs": {"Bucket": {"Value": {"Ref": "Gibtesnicht"}}}}
def refs(x):
    if isinstance(x, dict):
        for k, v in x.items():
            if k == "Ref": yield v
            else: yield from refs(v)
    elif isinstance(x, list):
        for v in x: yield from refs(v)
def pruefe(v):
    f = []
    if "Resources" not in v or not v["Resources"]: f.append("Abschnitt Resources fehlt oder ist leer")
    bekannt = set(v.get("Parameters", {})) | set(v.get("Resources", {}))
    for r in refs(v):
        if r not in bekannt and not r.startswith("AWS::"): f.append(f"Ref auf unbekannten Namen: {r}")
    return f
for name, v in (("gut", gut), ("schlecht", schlecht)):
    f = pruefe(json.loads(json.dumps(v)))
    print(f"Vorlage {name}: " + ("keine Befunde" if not f else "Befunde"))
    for x in f: print("   -", x)
