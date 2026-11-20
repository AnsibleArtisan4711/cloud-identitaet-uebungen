#!/usr/bin/env bash
# Führt alle Modulskripte aus und schreibt die Ausgaben nach NN-name/beispiele/SKRIPT.ausgabe.txt.
# Braucht python3 und die Azure CLI (pip install azure-cli) nur für die Befehlsprüfung; ohne az wird sie übersprungen. Dateien unter /tmp/p27.
cd "$(dirname "$0")" || exit 1
for d in [0-9][0-9]-*/; do
  for s in "$d"*.sh; do
    [ -f "$s" ] || continue
    b=$(basename "$s" .sh); mkdir -p "${d}beispiele"
    bash "$s" > "${d}beispiele/$b.ausgabe.txt" 2>&1
    echo "$s -> $(wc -l < "${d}beispiele/$b.ausgabe.txt") Zeilen"
  done
done
