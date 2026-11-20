#!/usr/bin/env python3
"""Modell: Alarm mit 'M von N Datenpunkten über Schwellwert'. Erfundene CPU-Werte pro Minute."""
werte = [30, 45, 85, 90, 40, 88, 92, 95, 50, 30]
schwelle, n, m = 80, 3, 2
print(f"Alarm, wenn in {n} aufeinanderfolgenden Datenpunkten mindestens {m} über {schwelle} liegen")
for i in range(len(werte)):
    fenster = werte[max(0, i - n + 1): i + 1]
    ueber = sum(1 for w in fenster if w > schwelle)
    zustand = "ALARM" if len(fenster) == n and ueber >= m else "ok"
    print(f"Minute {i:>2}: Wert {werte[i]:>3}  Fenster {fenster}  über Schwelle {ueber}  -> {zustand}")
