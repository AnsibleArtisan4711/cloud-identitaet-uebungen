#!/usr/bin/env bash
# Gemeinsame Hilfen der Übungsreihe (P28). ECHT ausgeführt: nur die Prüfung, ob Befehle und Parameter in der installierten Azure CLI existieren
# (`az ... --help`, offline, ohne Anmeldung), TOTP nach RFC 6238 und Token-Prüfung (Python). Entra ID, Entra Connect, Active Directory sind ein MODELL (entrasim.py): KEIN Entra-Mandant,
# KEIN Domänencontroller, KEIN `az login`, KEIN Portal. Dateien unter /tmp/p28.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; W=/tmp/p28; export ENTRA_STATE=$W/state.json
AZ="${AZ:-$(command -v az || true)}"; 
step() { echo; echo "## $*"; }
show() { local o="\$ entrasim" a; for a in "$@"; do case "$a" in *" "*|*"{"*|*"*"*) o+=" '$a'";; *) o+=" $a";; esac; done; echo "$o"; }
k() { show "$@"; python3 "$HERE/entrasim.py" "$@" 2>&1; return ${PIPESTATUS[0]}; }
# azchk "Befehl" --param ...: prüft ECHT gegen die installierte Azure CLI (nur Hilfetext, offline), ob der Befehl und die Parameter existieren
azchk() { local c="$1"; shift; local h r="" p
  [ -n "$AZ" ] || { echo "az $c -> az nicht installiert, Prüfung übersprungen"; return 0; }
  h=$($AZ $c --help 2>&1) || { echo "az $c -> Befehl FEHLT"; return 0; }
  for p in "$@"; do if grep -qE "^ +(-{1,2}[a-z0-9-]+ )*${p}( |\$)" <<<"$h"; then r+=" $p:ok"; else r+=" $p:FEHLT"; fi; done
  echo "az $c ->$r"; }
azver() { [ -n "$AZ" ] && echo "Azure CLI $($AZ version 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)["azure-cli"])') (echt, nur Hilfetexte)" || echo "Azure CLI nicht installiert"; }
lab_down() { rm -rf "$W"; }
lab_up() { lab_down; mkdir -p "$W"; python3 "$HERE/entrasim.py" init >/dev/null; }
trap 'lab_down >/dev/null 2>&1' EXIT
