#!/usr/bin/env python3
"""entrasim.py - einfaches MODELL von Microsoft Entra ID, Entra Connect, Hybrid Join, MFA, Bedingtem Zugriff und PIM für die Übungen (P28).
Es ist KEIN Entra ID und KEIN Windows Server Active Directory. Alles ist stark vereinfacht; Namen und Werte sind ERFUNDEN.
Echt gerechnet sind nur: TOTP nach RFC 6238 (HMAC, gegen die Testwerte der RFC geprüft) und Token (RS256, PyJWT + cryptography).
Zustand: Datei $ENTRA_STATE (Vorgabe /tmp/p28/state.json). Keine Uhrzeiten (Zeit ist eine ganze Zahl in Minuten oder Sekunden), keine Zufallsausgaben."""
import sys, os, json, re, uuid, hmac, hashlib, struct, base64

ST = os.environ.get('ENTRA_STATE', '/tmp/p28/state.json')
DEFAULT = 'labmuster.onmicrosoft.com'

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
def oid(kind, name): return str(uuid.uuid5(uuid.NAMESPACE_DNS, kind + ':' + name))[:8]

# ---------- Rollen (stark vereinfachte Fähigkeiten, ERFUNDENE Zuordnung) ----------
ROLES = {'Global Administrator': ['*'], 'User Administrator': ['user.create', 'user.resetPassword', 'group.manage'], 'Helpdesk Administrator': ['user.resetPassword'],
         'Conditional Access Administrator': ['ca.manage', 'ca.read'], 'Hybrid Identity Administrator': ['connect.manage'], 'Security Reader': ['ca.read', 'signin.read']}

def cmd_init(a):
    s = {'domains': {DEFAULT: True, 'muster-lab.example': False}, 'users': {}, 'groups': {}, 'devices': {}, 'roles': [], 'ad': {}, 'connect': None, 'pim': [], 'apps': {}}
    save(s); print(f'Modell zurückgesetzt: Mandant „Lab Muster“, Standarddomäne {DEFAULT} (verifiziert), benutzerdefinierte Domäne muster-lab.example (nicht verifiziert)')

def cmd_domain(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'list':
        for d, v in sorted(s['domains'].items()): print(f'{d:28} {"verifiziert" if v else "NICHT verifiziert"}')
    elif sub == 'verify':
        if o.get('txt') != 'MS=ms-erfunden-0001': die(f'Verifizierung von {pos[0]} fehlgeschlagen: TXT-Eintrag nicht gefunden oder falsch (Modell erwartet MS=ms-erfunden-0001)')
        s['domains'][pos[0]] = True; save(s); print(f'Domäne {pos[0]} verifiziert (Modell: über TXT-Eintrag im DNS)')

def cmd_user(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        upn = pos[0]; dom = upn.split('@')[1]
        if dom not in s['domains']: die(f'Fehler: Domäne {dom} gehört nicht zum Mandanten')
        if not s['domains'][dom]: die(f'Fehler: Domäne {dom} ist nicht verifiziert; Benutzer können sie nicht als UPN-Suffix verwenden')
        if upn in s['users']: die('Fehler: UPN existiert schon')
        s['users'][upn] = {'dept': o.get('dept', ''), 'src': 'Cloud', 'id': oid('user', upn), 'licenses': []}; save(s); print(f'Benutzer {upn} angelegt (Objekt {s["users"][upn]["id"]}, Quelle Cloud)')
    elif sub == 'list':
        for u, v in sorted(s['users'].items()): print(f'{u:36} {v["src"]:6} Abteilung={v["dept"] or "-":10} Objekt {v["id"]}')

def evalrule(rule, u, upn):
    def one(t):
        m = re.fullmatch(r'\s*user\.(\w+)\s+-(eq|ne|startsWith)\s+"([^"]*)"\s*', t)
        if not m: die(f'Regelfehler in „{t.strip()}“ (Modell kennt: user.attribut -eq|-ne|-startsWith "wert")')
        a, op, val = m.groups(); cur = upn if a == 'userPrincipalName' else u.get(a if a != 'department' else 'dept', '')
        return cur == val if op == 'eq' else cur != val if op == 'ne' else cur.startswith(val)
    return any(all(one(t) for t in alt.split(' -and ')) for alt in rule.split(' -or '))
def cmd_group(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        s['groups'][pos[0]] = {'dyn': o.get('dynamic'), 'members': [], 'licenses': []}
        if o.get('dynamic'):
            for u, v in s['users'].items(): evalrule(o['dynamic'], v, u)
        save(s); print(f'Gruppe {pos[0]} angelegt (' + ('dynamisch: ' + o['dynamic'] if o.get('dynamic') else 'zugewiesen') + ')')
    elif sub == 'add':
        g = s['groups'][pos[0]]
        if g['dyn']: die(f'Fehler: {pos[0]} ist dynamisch; die Mitglieder bestimmt die Regel, manuelles Hinzufügen ist nicht möglich')
        g['members'].append(pos[1]); save(s); print(f'{pos[1]} zu {pos[0]} hinzugefügt')
    elif sub == 'show':
        g = s['groups'][pos[0]]
        mem = sorted(u for u, v in s['users'].items() if evalrule(g['dyn'], v, u)) if g['dyn'] else sorted(g['members'])
        print(f'Gruppe {pos[0]}: {len(mem)} Mitglied(er)'); [print('  ' + m) for m in mem]

def cmd_role(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'assign':
        if pos[1] not in ROLES: die('Fehler: Rolle unbekannt (Modell kennt: ' + ', '.join(ROLES) + ')')
        s['roles'].append([pos[0], pos[1]]); save(s); print(f'{pos[0]} hat jetzt die Rolle {pos[1]}')
    elif sub == 'can':
        for u, r in s['roles']:
            if u == pos[0] and ('*' in ROLES[r] or pos[1] in ROLES[r]): print(f'{pos[0]} darf {pos[1]}: JA (Rolle {r})'); return
        print(f'{pos[0]} darf {pos[1]}: NEIN')

# ---------- Lokales AD und Entra Connect (Modell) ----------
def cmd_ad(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'add':
        s['ad'][pos[0]] = {'upn': o['upn'], 'ou': o['ou'], 'dept': o.get('dept', ''), 'rev': 1, 'guid': oid('adguid', pos[0])}; save(s); print(f'AD-Benutzer {pos[0]} in OU={o["ou"]}, UPN {o["upn"]}')
    elif sub == 'set':
        u = s['ad'][pos[0]]
        for k in ('dept', 'upn', 'ou'):
            if k in o: u[k] = o[k]
        u['rev'] += 1; save(s); print(f'AD-Benutzer {pos[0]} geändert')
    elif sub == 'del': del s['ad'][pos[0]]; save(s); print(f'AD-Benutzer {pos[0]} gelöscht')
    elif sub == 'list':
        for k, v in sorted(s['ad'].items()): print(f'{k:8} OU={v["ou"]:10} UPN={v["upn"]:26} Abteilung={v["dept"] or "-"}')

def cmd_connect(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'config':
        s['connect'] = {'scope': lst(o, 'scope'), 'method': o.get('method', 'phs'), 'seen': {}}; save(s); print(f'Entra Connect (Modell): Bereich OU={", ".join(lst(o, "scope"))}, Anmeldemethode {s["connect"]["method"]}')
    elif sub == 'run':
        c = s['connect']; new = upd = rem = skip = 0; notes = []
        for sam, v in sorted(s['ad'].items()):
            if v['ou'] not in c['scope']: skip += 1; continue
            dom = v['upn'].split('@')[1]; pre = v['upn'].split('@')[0]
            cloud = v['upn'] if s['domains'].get(dom) else f'{pre}@{DEFAULT}'
            if cloud != v['upn']: notes.append(f'  Hinweis {sam}: UPN-Suffix {dom} ist im Mandanten nicht verifiziert -> Cloud-UPN {cloud}')
            if sam not in c['seen']:
                s['users'][cloud] = {'dept': v['dept'], 'src': 'AD', 'id': oid('user', cloud), 'licenses': [], 'anchor': v['guid'], 'sam': sam}; c['seen'][sam] = [v['rev'], cloud]; new += 1
            elif c['seen'][sam][0] != v['rev']:
                old = c['seen'][sam][1]; u = s['users'].pop(old); u['dept'] = v['dept']; s['users'][cloud] = u; c['seen'][sam] = [v['rev'], cloud]; upd += 1
        for sam in [x for x in c['seen'] if x not in s['ad'] or s['ad'][x]['ou'] not in c['scope']]:
            s['users'].pop(c['seen'][sam][1], None); del c['seen'][sam]; rem += 1
        save(s); print(f'Synchronisation: {new} neu, {upd} geändert, {rem} entfernt, {skip} außerhalb des Bereichs'); [print(n) for n in notes]
    elif sub == 'methods':
        rows = [('Methode', 'Wo wird das Kennwort geprüft', 'Abhängigkeit bei der Anmeldung'), ('PHS', 'in der Cloud (Hash des Hashs synchronisiert)', 'keine zum lokalen AD'),
                ('PTA', 'lokal, über einen Agenten', 'Agent und lokales AD müssen erreichbar sein'), ('Federation', 'lokal, beim Verbund-Server (AD FS)', 'AD FS-Server und lokales AD müssen erreichbar sein')]
        for r in rows: print(f'{r[0]:11} {r[1]:46} {r[2]}')
    elif sub == 'signin':
        m = o['method']; up = o['onprem'] == 'up'; ok = m == 'phs' or up
        print(f'Anmeldung von {pos[0]} mit {m}, lokale Umgebung {o["onprem"]}: ' + ('ERFOLGREICH' if ok else 'FEHLGESCHLAGEN (lokale Prüfung nicht erreichbar)'))

# ---------- Geräte ----------
def cmd_device(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'dsreg':
        t = open(pos[0]).read(); g = lambda k: re.search(rf'{k}\s*:\s*(\w+)', t).group(1)
        aad, dom = g('AzureAdJoined') == 'YES', g('DomainJoined') == 'YES'
        kind = 'Entra hybrid eingebunden' if aad and dom else 'Entra eingebunden (nur Cloud)' if aad else 'nur Domäne (hybride Einbindung steht aus oder schlug fehl)' if dom else 'nicht eingebunden (höchstens registriert)'
        print(f'{pos[0]}: AzureAdJoined={g("AzureAdJoined")}, DomainJoined={g("DomainJoined")} -> {kind}')
    elif sub == 'hybrid':
        miss = [n for n, k in (('Entra Connect synchronisiert das Gerät', 'connect'), ('Dienstverbindungspunkt (SCP) ist konfiguriert', 'scp'), ('Sichtverbindung zum Domänencontroller', 'dc')) if o.get(k) != 'yes']
        print('Hybride Einbindung: ' + ('möglich' if not miss else 'NICHT möglich, es fehlt: ' + '; '.join(miss)))

# ---------- MFA: TOTP nach RFC 6238 (echt gerechnet) ----------
def totp(key, t, digits=6, step=30, alg=hashlib.sha1):
    c = struct.pack('>Q', t // step); h = hmac.new(key, c, alg).digest(); o = h[-1] & 15
    return str((struct.unpack('>I', h[o:o + 4])[0] & 0x7fffffff) % 10 ** digits).zfill(digits)
RFC = [(59, '94287082'), (1111111109, '07081804'), (1111111111, '14050471'), (1234567890, '89005924'), (2000000000, '69279037'), (20000000000, '65353130')]
def cmd_mfa(a):
    sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'selftest':
        key = b'12345678901234567890'; ok = True
        for t, exp in RFC:
            got = totp(key, t, 8); print(f'Zeit {t:>11}: RFC {exp}, berechnet {got} -> ' + ('gleich' if got == exp else 'ABWEICHUNG')); ok &= got == exp
        print('Ergebnis: ' + ('alle sechs Testwerte der RFC 6238 stimmen (SHA-1, 8 Stellen)' if ok else 'FEHLER'))
    elif sub == 'code':
        k = base64.b32decode(o['secret']); t = int(o['time']); print(f'Zeit {t}: Code {totp(k, t)} (Schritt {t // 30})')
    elif sub == 'verify':
        k = base64.b32decode(o['secret']); t = int(o['time']); w = int(o.get('window', 0)); code = o['code']
        for d in range(-w, w + 1):
            if totp(k, t + 30 * d) == code: print(f'Code {code} bei Zeit {t}: ANGENOMMEN (Schritt {t // 30 + d}, Abweichung {d:+d})'); return
        print(f'Code {code} bei Zeit {t}: ABGELEHNT (Fenster ±{w} Schritte)')

# ---------- Bedingter Zugriff (Modell) ----------
def cmd_ca(a):
    pos, o = opts(a); lic = o.get('license', 'p1'); pols = [json.load(open(f)) for f in lst(o, 'policies')]
    req = {'user': o['user'], 'groups': lst(o, 'groups'), 'app': o.get('app', 'Office'), 'loc': o.get('location', 'untrusted'), 'plat': o.get('platform', 'windows'), 'risk': o.get('risk', 'none'),
           'mfa': o.get('mfa', 'no') == 'yes', 'comp': o.get('compliant', 'no') == 'yes'}
    print(f'Anfrage: Benutzer {req["user"]}, Gruppen {",".join(req["groups"]) or "-"}, App {req["app"]}, Ort {req["loc"]}, Plattform {req["plat"]}, Risiko {req["risk"]}, MFA {"ja" if req["mfa"] else "nein"}, Gerät konform {"ja" if req["comp"] else "nein"}, Lizenz {lic}')
    if lic == 'free': print('Bedingter Zugriff nicht verfügbar: erfordert Entra ID P1 (Microsoft Learn gelesen, Stand 20.11.2026). Es gelten höchstens die Sicherheitsstandards.'); return
    need, blocked, final = [], False, []
    for p in pols:
        c = p.get('conditions', {}); inc = p['users']['include']; exc = p['users'].get('exclude', [])
        inn = 'all' in inc or req['user'] in inc or any(g in inc for g in req['groups']); out = req['user'] in exc or any(g in exc for g in req['groups'])
        apps = p.get('apps', ['all']); ok = inn and not out and ('all' in apps or req['app'] in apps)
        if 'platforms' in c and req['plat'] not in c['platforms']: ok = False
        if 'locationsExclude' in c and req['loc'] in c['locationsExclude']: ok = False
        if 'userRisk' in c:
            if lic != 'p2': print(f'  {p["name"]:22} wird übersprungen: Risikobedingung erfordert P2 (Learn gelesen)'); continue
            if req['risk'] not in c['userRisk']: ok = False
        if not ok: print(f'  {p["name"]:22} trifft nicht zu'); continue
        st = p.get('state', 'enabled')
        if st == 'disabled': print(f'  {p["name"]:22} ausgeschaltet'); continue
        g = p['grant']; res = 'BLOCK' if g == 'block' else 'verlangt ' + ' und '.join(g)
        if st == 'reportOnly': print(f'  {p["name"]:22} nur Bericht (nicht wirksam): {res}'); continue
        print(f'  {p["name"]:22} trifft zu: {res}')
        if g == 'block': blocked = True
        else: need += [c2 for c2 in g if c2 not in need]
    if blocked: print('Ergebnis: ZUGRIFF GESPERRT (eine Sperre schlägt alle anderen Richtlinien)'); return
    miss = [c2 for c2 in need if not ((c2 == 'mfa' and req['mfa']) or (c2 == 'compliantDevice' and req['comp']))]
    print('Ergebnis: ' + ('ZUGRIFF ERLAUBT' + (' (Auflagen erfüllt: ' + ', '.join(need) + ')' if need else ' (keine Richtlinie verlangt etwas)') if not miss else 'ZUGRIFF ERST NACH ERFÜLLEN: ' + ', '.join(miss)))

# ---------- PIM (Modell; Zeit in Minuten) ----------
MAXACT = 480
def cmd_pim(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if o.get('license', 'p2') != 'p2' and sub != 'x': die('PIM nicht verfügbar: erfordert P2 oder Entra ID Governance (Microsoft Learn gelesen, Stand 20.11.2026)')
    if sub == 'assign':
        s['pim'].append({'user': pos[0], 'role': pos[1], 'type': o['type'], 'act': None, 'approval': 'approval' in o}); save(s); print(f'{pos[0]}: {pos[1]} als {o["type"]} zugewiesen' + (' (Aktivierung braucht Genehmigung)' if 'approval' in o else ''))
    elif sub == 'activate':
        for p in s['pim']:
            if p['user'] == pos[0] and p['role'] == pos[1]:
                if p['type'] != 'eligible': die('Fehler: nur berechtigte (eligible) Zuweisungen werden aktiviert')
                if not o.get('reason'): die('Fehler: Begründung fehlt')
                m = int(o['minutes']); at = int(o['at'])
                if m > MAXACT: die(f'Fehler: Aktivierung für {m} Minuten über der Modellgrenze {MAXACT}')
                if p['approval'] and not o.get('approved'): die('Aktivierung wartet auf Genehmigung')
                p['act'] = [at, at + m]; save(s); print(f'{pos[0]}: {pos[1]} aktiv von Minute {at} bis {at + m} (Begründung: {o["reason"]})'); return
        die('Fehler: keine Zuweisung gefunden')
    elif sub == 'status':
        t = int(o['at']); print(f'Stand Minute {t}:')
        for p in s['pim']:
            st = 'aktiv (ständig)' if p['type'] == 'active' else ('aktiv bis Minute %d' % p['act'][1] if p['act'] and p['act'][0] <= t < p['act'][1] else 'berechtigt, nicht aktiviert')
            print(f'  {p["user"]:6} {p["role"]:34} {st}')

# ---------- Anwendungen und Token ----------
def cmd_app(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        for r in lst(o, 'redirect'):
            if not (r.startswith('https://') or r.startswith('http://localhost')): die(f'Fehler: Umleitungs-URI {r} nicht erlaubt (Modell: nur https oder http://localhost)')
        days = int(o.get('secret-days', 180))
        if days > 730: die(f'Fehler: Gültigkeit {days} Tage über der Modellgrenze 730 Tage')
        s['apps'][pos[0]] = {'redirect': lst(o, 'redirect'), 'days': days, 'delegated': [], 'application': [], 'consent': []}; save(s); print(f'App {pos[0]} registriert (Client-ID {oid("app", pos[0])}), Geheimnis {days} Tage gültig, Umleitung {", ".join(lst(o, "redirect")) or "-"}')
    elif sub == 'perm':
        ap = s['apps'][pos[0]]; ap['delegated'] += lst(o, 'delegated'); ap['application'] += lst(o, 'application'); save(s); print(f'{pos[0]}: delegiert {ap["delegated"]}, Anwendung {ap["application"]}')
    elif sub == 'consent':
        ap = s['apps'][pos[0]]; ap['consent'] = ap['application'][:]; save(s); print(f'{pos[0]}: Administratoreinwilligung für {ap["consent"]}')
    elif sub == 'show':
        ap = s['apps'][pos[0]]
        print(f'App {pos[0]}: delegierte Rechte (handelt im Namen eines Benutzers): {ap["delegated"] or "-"}')
        for r in ap['application']: print(f'  Anwendungsrecht {r}: ' + ('mit Administratoreinwilligung wirksam' if r in ap['consent'] else 'OHNE Administratoreinwilligung unwirksam (Modell)'))

def cmd_token(a):
    import jwt
    from cryptography.hazmat.primitives.asymmetric import rsa
    k1 = rsa.generate_private_key(public_exponent=65537, key_size=2048); k2 = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    ISS = 'https://login.example.test/00000000-0000-0000-0000-0000000000aa/v2.0'; AUD = 'api://app-lab-0001'
    claims = {'iss': ISS, 'aud': AUD, 'sub': 'ana', 'iat': 1000, 'nbf': 1000, 'exp': 1900, 'scp': 'Berichte.Lesen'}
    tok = jwt.encode(claims, k1, algorithm='RS256', headers={'kid': 'demo-key-1'})
    h, p, sg = tok.split('.'); dec = lambda x: json.loads(base64.urlsafe_b64decode(x + '=' * (-len(x) % 4)))
    print('Aufbau: drei Teile, durch Punkte getrennt (Kopf, Nutzdaten, Signatur)')
    print('Kopf:      ' + json.dumps(dec(h), sort_keys=True)); print('Nutzdaten: ' + json.dumps(dec(p), sort_keys=True)); print(f'Signatur:  <{len(sg)} Zeichen Base64URL, zufällig je Schlüssel, nicht ausgegeben>')
    print('Die Nutzdaten sind nur Base64URL-kodiert, NICHT verschlüsselt: jeder kann sie lesen. Geschützt ist nur die Unverfälschtheit (Signatur).')
    def chk(label, token, key, now, aud=AUD, iss=ISS):
        try:
            d = jwt.decode(token, key.public_key(), algorithms=['RS256'], audience=aud, issuer=iss, options={'verify_exp': False, 'verify_nbf': False, 'verify_iat': False})
            if now >= d['exp']: raise ValueError('abgelaufen (exp ' + str(d['exp']) + ' <= jetzt ' + str(now) + ')')
            if now < d['nbf']: raise ValueError('noch nicht gültig')
            print(f'{label:34} GÜLTIG')
        except Exception as e: print(f'{label:34} ABGELEHNT: {type(e).__name__ if not isinstance(e, ValueError) else "Zeit"}: {str(e) if isinstance(e, ValueError) else str(e).split(chr(10))[0]}')
    chk('unverändert, Zeit 1200', tok, k1, 1200)
    chk('abgelaufen, Zeit 2000', tok, k1, 2000)
    chk('falsche Zielgruppe (aud)', tok, k1, 1200, aud='api://andere-app')
    chk('falscher Aussteller (iss)', tok, k1, 1200, iss='https://fremd.example.test/')
    forged = h + '.' + base64.urlsafe_b64encode(json.dumps(dict(claims, scp='Admin.Alles')).encode()).decode().rstrip('=') + '.' + sg
    chk('Nutzdaten verändert', forged, k1, 1200)
    chk('mit fremdem Schlüssel geprüft', tok, k2, 1200)
    print('Ergebnis: Signatur, Zielgruppe, Aussteller und Zeit müssen ALLE stimmen.')

CMDS = {k[4:]: v for k, v in globals().items() if k.startswith('cmd_')}
if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS: die('Aufruf: entrasim.py ' + '|'.join(sorted(CMDS)) + ' ...', 2)
    CMDS[sys.argv[1]](sys.argv[2:])
