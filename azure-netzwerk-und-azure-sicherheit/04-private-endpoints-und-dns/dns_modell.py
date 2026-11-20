#!/usr/bin/env python3
"""Modell: Namensauflösung bei Private Endpoints. Ein Dienstname verweist per CNAME auf eine 'privatelink'-Zone; ist diese Zone mit dem Netzwerk verknüpft, kommt die private Adresse zurück, sonst die öffentliche. Erfundene Namen und Adressen."""
zonen = {"privatelink.blob.core.windows.net": {"konto1": "10.57.4.5"}}
oeffentlich = {"konto1.blob.core.windows.net": "203.0.113.20"}
def loese(name, verknuepfte_zonen):
    teile = name.split(".", 1); host, rest = teile[0], teile[1]
    privat = "privatelink." + rest
    if privat in verknuepfte_zonen and host in zonen.get(privat, {}):
        return zonen[privat][host], f"über {privat}"
    return oeffentlich.get(name, "nicht gefunden"), "öffentlich"
for netz, z in (("VNet mit verknüpfter Zone", {"privatelink.blob.core.windows.net"}), ("VNet ohne verknüpfte Zone", set())):
    a, w = loese("konto1.blob.core.windows.net", z); print(f"{netz:<28} konto1.blob.core.windows.net -> {a} ({w})")
