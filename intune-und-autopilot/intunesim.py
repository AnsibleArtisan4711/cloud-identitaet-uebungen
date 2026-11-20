#!/usr/bin/env python3
"""intunesim.py - einfaches MODELL von Microsoft Intune und Windows Autopilot für die Übungen (P29). Es ist KEIN Intune und KEIN Windows.
Alles ist stark vereinfacht; Namen und Werte sind ERFUNDEN. Regeln, die aus Microsoft Learn (Suchauszüge vom 20.11.2026) gelesen wurden, sind im Quelltext
mit [Learn] markiert; alles andere ist Fachwissen und nicht bestätigt.
Echt gerechnet sind nur: Prüfung der Autopilot-CSV nach den dokumentierten Regeln, SHA-256 (hashlib) und JSON/CSV-Verarbeitung.
Zustand: Datei $INTUNE_STATE (Vorgabe /tmp/p29/state.json). Keine Uhrzeiten (Zeit = ganze Tage), keine Zufallswerte."""
import sys, os, json, re, csv, hashlib, io

ST = os.environ.get('INTUNE_STATE', '/tmp/p29/state.json')
def load(): return json.load(open(ST))
def save(s):
    os.makedirs(os.path.dirname(ST), exist_ok=True); json.dump(s, open(ST, 'w'), indent=1, sort_keys=True)
def die(m, rc=1): print(m); sys.exit(rc)
def lst(o, k):
    v = o.get(k) or []
    return [v] if isinstance(v, str) else v
def opts(args):
    pos, o, i = [], {}, 0
    while i < len(args):
        a = args[i]
        if a.startswith('--'):
            k = a[2:]; v = []; i += 1
            while i < len(args) and not args[i].startswith('--'): v.append(args[i]); i += 1
            o[k] = True if not v else (v if len(v) != 1 else v[0])
        else: pos.append(a); i += 1
    return pos, o

def cmd_init(a):
    s = {'users': {'ana': {'lic': True, 'scope': True}, 'ben': {'lic': False, 'scope': True}, 'cem': {'lic': True, 'scope': False}},
         'restrict': {'block_personal': False, 'limit': 3}, 'devices': [], 'ap': {}, 'prof': {}}
    save(s); print('Modell zurückgesetzt: Benutzer ana (Lizenz, im MDM-Bereich), ben (keine Lizenz), cem (Lizenz, nicht im MDM-Bereich); Gerätelimit 3 (Modellwert)')

def cmd_user(a):
    s = load(); pos, o = opts(a)
    u = s['users'][pos[0]]
    if 'license' in o: u['lic'] = o['license'] == 'yes'
    if 'scope' in o: u['scope'] = o['scope'] == 'yes'
    save(s); print(f'{pos[0]}: Intune-Lizenz {"ja" if u["lic"] else "nein"}, MDM-Benutzerbereich {"ja" if u["scope"] else "nein"}')

def cmd_restrict(a):
    s = load(); pos, o = opts(a)
    if 'block-personal' in o: s['restrict']['block_personal'] = o['block-personal'] == 'yes'
    if 'limit' in o: s['restrict']['limit'] = int(o['limit'])
    save(s); r = s['restrict']; print(f'Einschränkungen: private Windows-Geräte {"gesperrt" if r["block_personal"] else "erlaubt"}, Limit {r["limit"]} Geräte je Benutzer (Modellwert)')

def cmd_enroll(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'decide':
        os_, own, new = o['os'], o['ownership'], o.get('new', 'no')
        if own == 'personal': r = 'App-Schutz (MAM) ohne Registrierung oder Registrierung als privates Gerät mit geringerer Kontrolle'
        elif os_ == 'windows' and new == 'yes': r = 'Windows Autopilot (Gerät vom Hersteller oder Händler registriert, Einrichtung durch den Benutzer)'
        elif os_ == 'windows': r = 'Einbindung in Entra ID mit automatischer MDM-Registrierung, oder Autopilot nach Erfassung des Hardware-Hashs'
        else: r = 'plattformspezifische Firmenregistrierung (nicht Gegenstand dieses Kurses)'
        print(f'{os_}, {own}, neu={new}: {r}')
    elif sub == 'try':
        u = s['users'][o['user']]; r = s['restrict']; os_, own, name = o['os'], o['ownership'], o['name']
        if not u['lic']: die(f'Registrierung von {name} FEHLGESCHLAGEN: Benutzer {o["user"]} hat keine Intune-Lizenz [Learn: auch bei Microsoft-365-Abonnement müssen Lizenzen zugewiesen sein]')
        if os_ == 'windows' and not u['scope']: die(f'Registrierung von {name} FEHLGESCHLAGEN: {o["user"]} liegt nicht im MDM-Benutzerbereich der automatischen Windows-Registrierung [Learn: Bereich konfigurieren]')
        if os_ == 'windows' and own == 'personal' and r['block_personal']: die(f'Registrierung von {name} FEHLGESCHLAGEN: private Windows-Geräte sind gesperrt [Learn: Registrierungseinschränkungen können private Windows-Geräte sperren]')
        n = sum(1 for d in s['devices'] if d['user'] == o['user'])
        if n >= r['limit']: die(f'Registrierung von {name} FEHLGESCHLAGEN: Limit von {r["limit"]} Geräten für {o["user"]} erreicht (Modellwert)')
        s['devices'].append({'name': name, 'user': o['user'], 'os': os_, 'own': own}); save(s); print(f'Registrierung von {name} ({os_}, {own}) für {o["user"]}: ERFOLGREICH ({n + 1} von {r["limit"]} Geräten)')

HDR = 'Device Serial Number,Windows Product ID,Hardware Hash,Group Tag,Assigned User'
def cmd_ap(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'check-csv':
        raw = open(pos[0], 'rb').read(); probs = []
        if raw.startswith(b'\xef\xbb\xbf') or raw.startswith(b'\xff\xfe') or raw.startswith(b'\xfe\xff'): probs.append('Datei hat eine Unicode-Markierung (BOM); erlaubt ist nur ANSI-Text [Learn]')
        try: txt = raw.decode('cp1252')
        except Exception: txt = raw.decode('latin-1')
        lines = [l for l in txt.replace('\r\n', '\n').split('\n') if l.strip()]
        if not lines or lines[0] != HDR: probs.append(f'Kopfzeile stimmt nicht (Groß-/Kleinschreibung zählt, keine zusätzlichen Spalten) [Learn]; erwartet: {HDR}')
        if len(lines) - 1 > 500: probs.append('mehr als 500 Zeilen [Learn: höchstens 500 Geräte je Datei]')
        if '"' in txt: probs.append('Anführungszeichen enthalten [Learn: keine Anführungszeichen]')
        for i, l in enumerate(lines[1:], 2):
            c = l.split(',')
            if len(c) != 5: probs.append(f'Zeile {i}: {len(c)} statt 5 Spalten'); continue
            if not c[0].strip(): probs.append(f'Zeile {i}: Seriennummer fehlt [Learn: erforderlich]')
            if not c[2].strip(): probs.append(f'Zeile {i}: Hardware-Hash fehlt [Learn: erforderlich]')
            if c[4] and not re.fullmatch(r'[^@\s]+@[^@\s]+\.[^@\s]+', c[4]): probs.append(f'Zeile {i}: zugewiesener Benutzer „{c[4]}“ ist kein gültiger UPN [Learn: ungültiger UPN kann das Gerät unbrauchbar machen]')
        print(f'{pos[0]}: {len(lines) - 1} Gerät(e) geprüft (Regeln nach Microsoft Learn, Auszug)')
        for p in probs: print('  PROBLEM: ' + p)
        print('  Ergebnis: ' + ('FEHLER' if probs else 'in Ordnung'))
        if probs: sys.exit(1)
    elif sub == 'import':
        for r in list(csv.DictReader(open(pos[0], encoding='cp1252'))):
            s['ap'][r['Device Serial Number']] = {'tag': r['Group Tag'], 'user': r['Assigned User']}
        save(s); print(f'Importiert: {len(s["ap"])} Gerät(e): ' + ', '.join(sorted(s['ap'])))
    elif sub == 'profile':
        mode, join = o['mode'], o.get('join', 'entra')
        if mode == 'self-deploying' and join == 'hybrid': die('Fehler: Der selbstbereitstellende Modus wird für hybrid eingebundene Geräte nicht unterstützt [Learn, Teams-Rooms-Seite]')
        s['prof'][o['name']] = {'mode': mode, 'join': join, 'tag': o.get('tag', '')}; save(s); print(f'Autopilot-Profil {o["name"]}: Modus {mode}, Einbindung {join}, Zuordnung über Gruppen-Tag „{o.get("tag", "")}“ (Modell)')
    elif sub == 'boot':
        d = s['ap'].get(pos[0])
        if not d: print(f'Gerät {pos[0]}: nicht bei Autopilot registriert -> normale Einrichtung (OOBE) ohne Profil'); return
        pr = [n for n, p in sorted(s['prof'].items()) if p['tag'] == d['tag']]
        if not pr: print(f'Gerät {pos[0]}: registriert (Tag „{d["tag"]}“), aber kein Profil zugewiesen -> normale Einrichtung'); return
        p = s['prof'][pr[0]]; print(f'Gerät {pos[0]}: Profil {pr[0]} ({p["mode"]}, {p["join"]})' + (f', zugewiesener Benutzer {d["user"]}' if d['user'] else ''))

def cmd_cfg(a):
    pos, o = opts(a); eff, conf = {}, {}
    for f in pos:
        p = json.load(open(f))
        for k, v in p['settings'].items():
            if k in eff and eff[k][0] != v: conf.setdefault(k, [eff[k]]).append((v, p['name']))
            else: eff.setdefault(k, (v, p['name']))
    for k, v in sorted(eff.items()):
        print(f'  {k:28} = {v[0]!s:8} aus {v[1]}' if k not in conf else f'  {k:28} KONFLIKT: ' + ' gegen '.join(f'{x[0]} ({x[1]})' for x in conf[k]) + ' -> Wert nicht zuverlässig (im Modell: nicht angewendet)')
    print(f'Ergebnis: {len(eff) - len(conf)} Einstellung(en) angewendet, {len(conf)} Konflikt(e)')

def cmd_comp(a):
    pos, o = opts(a); pol = json.load(open(o['policy'])); dev = json.load(open(o['device'])); fails = []
    for k, r in sorted(pol['rules'].items()):
        v = dev.get(k)
        ok = (v is True) if r is True else (v is not None and v >= r)
        if not ok: fails.append(f'{k} (Soll {r}, Ist {v})')
    print(f'Gerät {dev["name"]}: ' + ('alle Regeln erfüllt -> konform' if not fails else 'verletzt: ' + '; '.join(fails)))
    if fails:
        for act in sorted(pol['actions'], key=lambda x: x['day']): print(f'  Tag {act["day"]:>3} nach Feststellung: {act["do"]}')
        print('  [Learn] „Gerät als nicht konform markieren“ ist immer vorhanden (Standard 0 Tage) und kann nicht entfernt werden; Bedingter Zugriff wirkt, sobald das Gerät als nicht konform gilt.')
        d0 = min([x['day'] for x in pol['actions'] if x['do'].startswith('Gerät als nicht konform')] or [0])
        if o.get('ca'): print(f'  Zugriff gesperrt (Bedingter Zugriff verlangt Konformität) ab Tag {d0}')

def cmd_app(a):
    sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'sha256':
        h = hashlib.sha256(open(pos[0], 'rb').read()).hexdigest()
        print(f'{pos[0]}: SHA-256 {h[:16]}…; ' + ('stimmt mit der Vorgabe überein' if h == pos[1] else 'WEICHT von der Vorgabe ab'))
    elif sub == 'detect':
        rules = json.load(open(pos[0])); fs = json.load(open(pos[1])); ok = True
        for r in rules:
            if r['type'] == 'file': res = r['path'] in fs
            else: res = fs.get(r['path'], '0') >= r['min']
            print(f'  Erkennungsregel {r["type"]} {r["path"]}' + (f' >= {r["min"]}' if 'min' in r else '') + f': {"erfüllt" if res else "NICHT erfüllt"}'); ok &= res
        print('Ergebnis: ' + ('App gilt als installiert' if ok else 'App gilt als NICHT installiert (Installation wird wiederholt oder als fehlgeschlagen gemeldet)'))
    elif sub == 'intent':
        g = lst(o, 'group')
        seen = {}
        for x in g:
            grp, intent = x.split(':')
            if grp in seen: die(f'Fehler: Gruppe {grp} hat schon die Absicht {seen[grp]}; Intune verhindert mehrere Zuweisungen an dieselbe Gruppe [Learn]')
            seen[grp] = intent
        print('Zuweisungen: ' + ', '.join(f'{k} -> {v}' for k, v in seen.items()))

def cmd_upd(a):
    pos, o = opts(a); rel = int(o['release']); dq, dl = int(o['defer']), int(o['deadline']); pause = int(o.get('pause', 0))
    start = rel + dq + pause; print(f'Ring „{o["ring"]}“: Veröffentlichung Tag {rel}, Zurückstellung {dq} Tage' + (f', angehalten {pause} Tage' if pause else '') + f' -> Angebot ab Tag {start}; Frist {dl} Tage -> Installation spätestens Tag {start + dl}')

def grp_match(g, dev): return g == 'all' or g in dev.get('groups', [])
def cmd_assign(a):
    pos, o = opts(a); asg = json.load(open(pos[0])); dev = json.load(open(pos[1])); filt = json.load(open(pos[2])) if len(pos) > 2 else {}
    def fres(name):
        if not name: return None
        f = filt[name]; m = all(dev.get(k) == v for k, v in f['match'].items()); return m
    print(f'Gerät {dev["name"]}, Gruppen {dev.get("groups", [])}')
    mine = [x for x in asg if grp_match(x['group'], dev) and not x.get('exclude_group')]
    ex = [x for x in asg if x.get('exclude_group') and grp_match(x['group'], dev)]
    if ex: print('  ausgeschlossen durch Gruppenausschluss: ' + ', '.join(x['group'] for x in ex)); print('Ergebnis: Richtlinie wird NICHT angewendet'); return
    if not mine: print('  keine passende Zuweisung'); print('Ergebnis: Richtlinie wird NICHT angewendet'); return
    modes = []
    for x in mine:
        fm = x.get('filter'); r = fres(fm); mode = filt[fm]['mode'] if fm else 'none'
        print(f'  Zuweisung an {x["group"]:10} Filter {fm or "-":10} Modus {mode:8} Filterergebnis {"-" if r is None else ("passt" if r else "passt nicht")}'); modes.append((mode, r))
    # [Learn] Vorrang bei Konflikt: Exclude gewinnt vor Kein Filter, vor Include; gleiche Modi: ODER-Logik
    if any(m == 'exclude' for m, _ in modes):
        res = not any(m == 'exclude' and r for m, r in modes); why = 'Ausschluss-Filter hat Vorrang (Exclude vor Kein Filter vor Include)'
    elif any(m == 'none' for m, _ in modes): res, why = True, 'Zuweisung ohne Filter hat Vorrang vor Include'
    else: res = any(r for m, r in modes); why = 'Include-Filter mit ODER-Logik'
    print(f'  Regel: {why}'); print('Ergebnis: Richtlinie wird ' + ('ANGEWENDET' if res else 'NICHT angewendet'))

def cmd_diag(a):
    pos, o = opts(a); d = json.load(open(pos[0])); checks = [('Intune-Lizenz zugewiesen', d.get('license')), ('Benutzer im MDM-Benutzerbereich', d.get('scope')), ('Registrierung nicht durch Einschränkung blockiert', not d.get('blocked')),
        ('Gerät hat zuletzt eingecheckt (Modell: höchstens 1 Tag)', d.get('lastcheckin_days', 99) <= 1), ('Gerät ist in der Zielgruppe', d.get('in_group')), ('kein Filter schließt das Gerät aus', not d.get('filter_excludes')), ('keine widersprüchliche Einstellung (Konflikt)', not d.get('conflict'))]
    print(f'Fehlersuche für {d["name"]} (Reihenfolge der Prüfung von der Registrierung bis zur Wirkung):')
    first = None
    for t, ok in checks:
        print(f'  [{"ok" if ok else "FEHLT"}] {t}'); first = first or (None if ok else t)
    print('Erste Ursache: ' + (first or 'keine gefunden; Protokolle und Berichte im Dienst prüfen'))

CMDS = {k[4:]: v for k, v in globals().items() if k.startswith('cmd_')}
if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS: die('Aufruf: intunesim.py ' + '|'.join(sorted(CMDS)) + ' ...', 2)
    CMDS[sys.argv[1]](sys.argv[2:])
