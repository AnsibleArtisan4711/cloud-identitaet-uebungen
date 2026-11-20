#!/usr/bin/env python3
"""Modell: Prüfung von Dienstkonten: zu weite Rollen und alte Schlüssel. Erfundene Konten, Rollennamen allgemein gehalten."""
konten = [("sa-backup", ["Speicher-Schreiber"], [40]), ("sa-web", ["Projekt-Inhaber"], []), ("sa-ci", ["Bearbeiter"], [200, 15])]
max_alter, weit = 90, {"Projekt-Inhaber", "Bearbeiter"}
for name, rollen, schluessel in konten:
    meld = []
    meld += [f"Rolle {r} ist sehr weit" for r in rollen if r in weit]
    meld += [f"Schlüssel mit {a} Tagen älter als {max_alter}" for a in schluessel if a > max_alter]
    if schluessel: meld.append(f"{len(schluessel)} Schlüssel vorhanden: wenn möglich ohne Schlüssel arbeiten")
    print(f"{name:<10} " + ("ok" if not meld else "; ".join(meld)))
