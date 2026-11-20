#!/usr/bin/env python3
"""azsim.py - einfaches MODELL von Azure für die Übungen (P27). Es ist KEIN Azure und KEIN az.
Alles ist stark vereinfacht; Größen, Preise und Kontingente sind ERFUNDEN. Die Befehlsform ähnelt `az`, ist aber nicht identisch.
Echt geprüft wird in lab.sh nur, ob Befehle und Parameter in der installierten Azure CLI existieren (`az ... --help`, offline).
Zustand: Datei $AZ_STATE (Vorgabe /tmp/p27/state.json). Keine Uhrzeiten, keine Zufallswerte."""
import sys, os, json, re, fnmatch, hmac, hashlib, ipaddress

ST = os.environ.get('AZ_STATE', '/tmp/p27/state.json')
SUBID = '00000000-0000-0000-0000-000000000001'          # erfundene Abonnement-ID
ROOT = 'tenant-root'

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
            k = a[2:]; v = []
            i += 1
            while i < len(args) and not args[i].startswith('--'): v.append(args[i]); i += 1
            o[k] = v if len(v) != 1 else v[0]
            if not v: o[k] = True
        else: pos.append(a); i += 1
    return pos, o

# ---------- Bereiche (Scopes) ----------
def mg_scope(name): return f'/providers/Microsoft.Management/managementGroups/{name}'
def sub_scope(s): return f'/subscriptions/{SUBID}'
def rg_scope(rg): return f'/subscriptions/{SUBID}/resourceGroups/{rg}'
def chain(s, scope):
    """Von der Ressource aufwärts bis zur Wurzel-Verwaltungsgruppe."""
    out = [scope]; m = re.match(r'(/subscriptions/[^/]+/resourceGroups/[^/]+)/', scope)
    if m: out.append(m.group(1))
    if scope.startswith('/subscriptions/'):
        out.append(sub_scope(s)); g = s['subs']['lab-test']['mg']
        while g:
            out.append(mg_scope(g)); g = s['mgs'][g]['parent']
    return list(dict.fromkeys(out))

# ---------- Rollen (vereinfacht, Auszug) ----------
ROLES = {
  'Owner': {'actions': ['*'], 'not': [], 'data': []},
  'Contributor': {'actions': ['*'], 'not': ['Microsoft.Authorization/*/Write', 'Microsoft.Authorization/*/Delete'], 'data': []},
  'Reader': {'actions': ['*/read'], 'not': [], 'data': []},
  'Virtual Machine Contributor': {'actions': ['Microsoft.Compute/virtualMachines/*', 'Microsoft.Network/virtualNetworks/read', '*/read'], 'not': [], 'data': []},
  'Storage Blob Data Reader': {'actions': ['Microsoft.Storage/storageAccounts/read'], 'not': [], 'data': ['Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read']},
}
def match(pats, act): return any(fnmatch.fnmatchcase(act.lower(), p.lower()) for p in pats)

def cmd_init(a):
    s = {'mgs': {ROOT: {'parent': None}}, 'subs': {'lab-test': {'mg': ROOT}}, 'rgs': {}, 'locks': [], 'assign': [], 'members': {},
         'vnets': {}, 'vms': {}, 'stor': {}, 'policies': {}, 'pa': []}
    save(s); print('Modell zurückgesetzt: Verwaltungsgruppe tenant-root, Abonnement lab-test (ID ' + SUBID + ', erfunden)')

def cmd_mg(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        n = pos[0]; p = o.get('parent', ROOT)
        if n in s['mgs']: die(f'Fehler: Verwaltungsgruppe {n} existiert schon')
        if p not in s['mgs']: die(f'Fehler: Übergeordnete Verwaltungsgruppe {p} unbekannt')
        d = 0; g = p
        while s['mgs'][g]['parent']: g = s['mgs'][g]['parent']; d += 1
        if d + 1 >= 6: die('Fehler: Tiefe der Hierarchie überschritten (Modell: höchstens 6 Ebenen einschließlich Wurzel)')
        s['mgs'][n] = {'parent': p}; save(s); print(f'Verwaltungsgruppe {n} unter {p} angelegt')
    elif sub == 'tree':
        def walk(g, ind):
            print('  ' * ind + g + ('' if g != ROOT else '  (Wurzel)'))
            for x in sorted(k for k, v in s['mgs'].items() if v['parent'] == g): walk(x, ind + 1)
            if s['subs']['lab-test']['mg'] == g: print('  ' * (ind + 1) + '[Abonnement] lab-test')
        walk(ROOT, 0)
    else: die('unbekannt: mg ' + sub)

def cmd_sub(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'move':
        if o['mg'] not in s['mgs']: die('Fehler: Verwaltungsgruppe unbekannt')
        s['subs'][pos[0]]['mg'] = o['mg']; save(s); print(f'Abonnement {pos[0]} liegt jetzt unter {o["mg"]}')

def cmd_group(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        n = pos[0]; tags = dict(t.split('=', 1) for t in lst(o, 'tags') if '=' in t)
        s['rgs'][n] = {'loc': o['location'], 'tags': tags}; save(s); print(f'Ressourcengruppe {n} in {o["location"]} angelegt' + (f', Tags {json.dumps(tags, sort_keys=True)}' if tags else ''))
    elif sub == 'list':
        if not s['rgs']: print('(keine Ressourcengruppen)')
        for n in sorted(s['rgs']): print(f'{n:14} {s["rgs"][n]["loc"]:12} Ressourcen: {sum(1 for t in ("vnets","vms","stor") for r in s[t].values() if r["rg"]==n)}')
    elif sub == 'delete':
        n = pos[0]
        for l in s['locks']:
            if l['rg'] == n: die(f'Fehler: Löschen verweigert, Sperre „{l["name"]}“ ({l["type"]}) auf {n}')
        if n not in s['rgs']: die('Fehler: unbekannt')
        for t in ('vnets', 'vms', 'stor'):
            for k in [k for k, v in s[t].items() if v['rg'] == n]: del s[t][k]
        del s['rgs'][n]; save(s); print(f'Ressourcengruppe {n} samt Inhalt gelöscht')

def cmd_lock(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        s['locks'].append({'name': o['name'], 'rg': o['group'], 'type': o['type']}); save(s); print(f'Sperre {o["name"]} ({o["type"]}) auf {o["group"]}')
    elif sub == 'delete':
        s['locks'] = [l for l in s['locks'] if l['name'] != o['name']]; save(s); print('Sperre entfernt')

def cmd_identity(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'member-add': s['members'].setdefault(pos[0], []).append(pos[1]); save(s); print(f'{pos[1]} ist Mitglied von {pos[0]}')

def who(s, assignee): return [assignee] + [g for g, m in s['members'].items() if assignee in m]

def cmd_role(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'assign':
        if o['role'] not in ROLES: die('Fehler: Rolle unbekannt (Modell kennt: ' + ', '.join(ROLES) + ')')
        s['assign'].append({'who': o['assignee'], 'role': o['role'], 'scope': o['scope']}); save(s)
        print(f'Zuweisung: {o["assignee"]} -> {o["role"]} @ {o["scope"].replace(SUBID, "<Abo>")}')
    elif sub == 'list':
        sc = chain(s, o['scope']); print(f'Wirksame Zuweisungen für {o["scope"].replace(SUBID, "<Abo>")}:')
        for x in s['assign']:
            if x['scope'] in sc: print(f'  {x["who"]:12} {x["role"]:28} @ {x["scope"].replace(SUBID, "<Abo>")}' + ('' if x['scope'] == o['scope'] else '  (geerbt)'))
    elif sub == 'check':
        act = o['action']; data = 'data' in o; sc = chain(s, o['scope']); names = who(s, o['assignee']); res = []
        for x in s['assign']:
            if x['who'] in names and x['scope'] in sc:
                r = ROLES[x['role']]
                acts, nots = (r['data'], []) if data else (r['actions'], r['not'])
                if match(acts, act) and not match(nots, act): res.append(x)
        ok = bool(res)
        print(f'{o["assignee"]} darf {act}{" (Datenebene)" if data else ""} auf {o["scope"].replace(SUBID, "<Abo>")}: ' + ('JA' if ok else 'NEIN'))
        for x in res[:1]: print(f'  Grund: {x["role"]} @ {x["scope"].replace(SUBID, "<Abo>")} (über {x["who"]})')
        # Sperren wirken zusätzlich, unabhängig von der Rolle (nur Ressourcengruppen im Modell)
        m = re.search(r'resourceGroups/([^/]+)', o['scope'])
        if m and ok and not data:
            for l in s['locks']:
                if l['rg'] == m.group(1):
                    kind = 'delete' if act.lower().endswith('/delete') else ('write' if not act.lower().endswith('/read') else 'read')
                    if (l['type'] == 'CanNotDelete' and kind == 'delete') or (l['type'] == 'ReadOnly' and kind in ('write', 'delete')):
                        print(f'  ABER: Sperre „{l["name"]}“ ({l["type"]}) blockiert {kind}, die Rolle hilft nicht.')

def cidr(x): return ipaddress.ip_network(x, strict=True)
def cmd_vnet(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        n = pos[0]; pre = cidr(o['prefix'])
        for k, v in s['vnets'].items():
            if v['rg'] == o['group'] and cidr(v['prefix']).overlaps(pre) and False: pass
        subs = {}
        for sp in lst(o, 'subnet'):
            nm, c = sp.split('=', 1); c = cidr(c)
            if not c.subnet_of(pre): die(f'Fehler: Subnetz {nm} ({c}) liegt nicht im Adressraum {pre}')
            for k2, c2 in subs.items():
                if cidr(c2).overlaps(c): die(f'Fehler: Subnetze {nm} und {k2} überlappen')
            if c.prefixlen > 29: die(f'Fehler: Subnetz {nm} ({c}) ist zu klein (Modell: kleinstes Subnetz /29)')
            subs[nm] = str(c)
        s['vnets'][n] = {'rg': o['group'], 'prefix': str(pre), 'subnets': subs}; save(s); print(f'VNet {n} {pre} angelegt, {len(subs)} Subnetz(e)')
    elif sub == 'show':
        v = s['vnets'][pos[0]]; print(f'VNet {pos[0]} {v["prefix"]}')
        for nm, c in sorted(v['subnets'].items()):
            n = cidr(c).num_addresses; print(f'  {nm:10} {c:16} Adressen {n:5}, davon nutzbar für Ressourcen {n - 5:5} (5 sind reserviert)')
    elif sub == 'peer':
        A, B = s['vnets'][pos[0]], s['vnets'][pos[1]]
        if cidr(A['prefix']).overlaps(cidr(B['prefix'])): die(f'Peering {pos[0]} <-> {pos[1]} abgelehnt: Adressräume {A["prefix"]} und {B["prefix"]} überlappen')
        print(f'Peering {pos[0]} <-> {pos[1]}: möglich ({A["prefix"]} / {B["prefix"]}); gilt nicht transitiv (Fachwissen)')
    elif sub == 'plan':
        need = int(o['hosts']); p = 32
        while 2 ** (32 - p) - 5 < need: p -= 1
        print(f'Für {need} Adressen braucht ein Subnetz mindestens /{p} ({2 ** (32 - p)} Adressen, {2 ** (32 - p) - 5} nutzbar)')

PRI = [(65000, 'AllowVnetInBound', 'in', 'allow', 'VirtualNetwork'), (65001, 'AllowAzureLoadBalancerInBound', 'in', 'allow', 'AzureLoadBalancer'), (65500, 'DenyAllInBound', 'in', 'deny', '*')]
def cmd_nsg(a):
    pos, o = opts(a); rules = []
    for r in lst(o, 'rule'):
        p, name, port, act = r.split(':'); rules.append((int(p), name, port, act))
    port = o['port']; src = o.get('source', 'Internet')
    for p, name, rp, act in sorted(rules):
        if rp in ('*', port): print(f'Treffer: Regel {name} (Priorität {p}) -> {act}'); return
    for p, name, _, act, s2 in PRI:
        if s2 == '*' or s2 == src or (s2 == 'VirtualNetwork' and src == 'VirtualNetwork'):
            print(f'Treffer: Standardregel {name} (Priorität {p}) -> {act}'); return

SIZES = {'Lab_S1': (1, 2, 4), 'Lab_S2': (2, 4, 9), 'Lab_S4': (4, 8, 18), 'Lab_M8': (8, 32, 52)}  # vCPU, GiB, erfundener Preis je Tag
QUOTA = {'westeurope': 12}
def cmd_vm(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'sizes':
        for k, (c, m, p) in SIZES.items(): print(f'{k:8} {c} vCPU {m:3} GiB  {p:3} EUR/Tag (erfunden)')
    elif sub == 'create':
        n = pos[0]; size = o['size']
        if size not in SIZES: die('Fehler: Größe unbekannt (Modell: ' + ', '.join(SIZES) + ')')
        v = s['vnets'].get(o['vnet']); 
        if not v or o['subnet'] not in v['subnets']: die(f'Fehler: Subnetz {o["subnet"]} in VNet {o["vnet"]} nicht gefunden')
        loc = s['rgs'][o['group']]['loc']; used = sum(SIZES[x['size']][0] for x in s['vms'].values())
        if used + SIZES[size][0] > QUOTA.get(loc, 10): die(f'Fehler: Kontingent in {loc} überschritten ({used} von {QUOTA.get(loc, 10)} vCPU belegt, {SIZES[size][0]} angefordert; Modell-Kontingent erfunden)')
        z = o.get('zone', '-'); 
        if z != '-' and z not in ('1', '2', '3'): die('Fehler: Zone muss 1, 2 oder 3 sein')
        s['vms'][n] = {'rg': o['group'], 'size': size, 'zone': z, 'subnet': o['subnet'], 'vnet': o['vnet']}; save(s)
        print(f'VM {n}: {size}, Zone {z}, Subnetz {o["vnet"]}/{o["subnet"]}, Kontingent {used + SIZES[size][0]}/{QUOTA.get(loc, 10)} vCPU')
    elif sub == 'resize':
        n = pos[0]; s['vms'][n]['size'] = o['size']; save(s); print(f'VM {n} -> {o["size"]} (im echten Azure Neustart nötig, Fachwissen)')
    elif sub == 'cost':
        tot = 0
        for n, v in sorted(s['vms'].items()):
            c = SIZES[v['size']][2]; tot += c; print(f'{n:8} {v["size"]:8} {c:3} EUR/Tag')
        print(f'Summe {tot} EUR/Tag, {tot * 30} EUR/30 Tage (erfundene Preise)')

def cmd_template(a):
    pos, o = opts(a); t = json.load(open(pos[0])); errs = []
    for k in ('$schema', 'contentVersion', 'resources'):
        if k not in t: errs.append(f'Pflichtschlüssel fehlt: {k}')
    for i, r in enumerate(t.get('resources', [])):
        for k in ('type', 'apiVersion', 'name', 'location'):
            if k not in r: errs.append(f'resources[{i}]: {k} fehlt')
    params = set(t.get('parameters', {})); used = set(re.findall(r"parameters\('([^']+)'\)", json.dumps(t)))
    for u in sorted(used - params): errs.append(f'Parameter {u} wird benutzt, aber nicht definiert')
    for u in sorted(params - used): errs.append(f'Hinweis: Parameter {u} wird nicht benutzt')
    print('Strukturprüfung (eigenes Modell, nicht das Schema von Azure):'); [print('  ' + e) for e in errs]
    print('  Ergebnis: ' + ('FEHLER' if any(not e.startswith('Hinweis') for e in errs) else 'in Ordnung'))

REDUND = {'LRS': (3, 1, 'Ausfall eines Racks oder Servers', 'nicht: Ausfall des Rechenzentrums'), 'ZRS': (3, 3, 'Ausfall eines Rechenzentrums (Zone)', 'nicht: Ausfall der Region'),
          'GRS': (6, 2, 'Ausfall der Region (Lesen erst nach Failover)', 'Kosten höher'), 'RA-GRS': (6, 2, 'wie GRS, zweite Region lesbar', 'Kosten am höchsten')}
def cmd_storage(a):
    s = load(); sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'create':
        n = pos[0]
        if not re.fullmatch(r'[a-z0-9]{3,24}', n): die(f'Fehler: Name „{n}“ ungültig: 3 bis 24 Zeichen, nur Kleinbuchstaben und Ziffern')
        if any(n == k for k in s['stor']): die('Fehler: Name schon vergeben (Namen sind weltweit eindeutig)')
        s['stor'][n] = {'rg': o['group'], 'sku': o['sku'], 'blobs': {}, 'rules': []}; save(s); print(f'Speicherkonto {n} ({o["sku"]}) angelegt')
    elif sub == 'redundancy':
        for k, (c, z, w, x) in REDUND.items(): print(f'{k:7} {c} Kopien, {z} Standort(e): übersteht {w}; {x}')
    elif sub == 'sas':
        key = o['key'].encode(); exp = int(o['expiry']); perm = o['perm']; now = int(o['now']); path = o['path']
        sig = hmac.new(key, f'{path}\n{perm}\n{exp}'.encode(), hashlib.sha256).hexdigest()[:12]
        print(f'Modell-Token: path={path} perm={perm} exp={exp} sig={sig} (NICHT das echte SAS-Format)')
        want = o.get('use', 'r'); okperm = want in perm; okt = now <= exp
        print(f'Zugriff {want!r} bei Zeit {now}: ' + ('erlaubt' if okperm and okt else 'abgelehnt (' + ('abgelaufen' if not okt else 'Recht fehlt') + ')'))
    elif sub == 'lifecycle':
        days = int(o['age']); cool = int(o['cool']); arch = int(o['archive']); dele = int(o['delete'])
        st = 'Hot' if days < cool else 'Cool' if days < arch else 'Archive' if days < dele else 'gelöscht'
        print(f'Blob mit Alter {days} Tagen: Stufe {st} (Regel: Cool ab {cool}, Archive ab {arch}, Löschen ab {dele})')

def cmd_backup(a):
    pos, o = opts(a); d, w, m = int(o['daily']), int(o['weekly']), int(o['monthly']); age = int(o['age'])
    pts = set(range(0, min(age, d) + 1))
    for k in range(1, w + 1):
        if 7 * k <= age: pts.add(7 * k)
    for k in range(1, m + 1):
        if 30 * k <= age: pts.add(30 * k)
    pts = sorted(x for x in pts if x <= age)
    print(f'Richtlinie: täglich {d} Tage, wöchentlich {w} Wochen, monatlich {m} Monate (Modell: Wochen = Vielfache von 7 Tagen, Monate = Vielfache von 30 Tagen)')
    print(f'Nach {age} Tagen gibt es {len(pts)} Wiederherstellungspunkte; ältester: vor {max(pts)} Tagen')
    if 'restore' in o:
        r = int(o['restore']); print(f'Wiederherstellung auf Stand vor {r} Tagen: ' + ('möglich' if r in pts else f'nicht möglich; nächster Punkt: vor {min(pts, key=lambda x: abs(x - r))} Tagen'))

def cmd_alert(a):
    pos, o = opts(a); vals = [float(x) for x in o['series']]; win = int(o['window']); thr = float(o['threshold']); op = o.get('op', '>')
    hit = []
    for i in range(win - 1, len(vals)):
        avg = sum(vals[i - win + 1:i + 1]) / win
        if (avg > thr if op == '>' else avg < thr): hit.append((i + 1, round(avg, 1)))
    print(f'Regel: Mittelwert über {win} Messung(en) {op} {thr}')
    print('Ausgelöst bei: ' + (', '.join(f'Messung {i} (Mittel {v})' for i, v in hit) if hit else 'nie'))

def cond(c, res):
    if 'allOf' in c: return all(cond(x, res) for x in c['allOf'])
    if 'anyOf' in c: return any(cond(x, res) for x in c['anyOf'])
    if 'not' in c: return not cond(c['not'], res)
    f = c['field']; v = res.get(f) if not f.startswith('tags[') else res.get('tags', {}).get(f[6:-2])
    if 'equals' in c: return v == c['equals']
    if 'in' in c: return v in c['in']
    if 'notIn' in c: return v not in c['notIn']
    if 'exists' in c: return (v is not None) == (c['exists'] in (True, 'true'))
    return False
def cmd_policy(a):
    pos, o = opts(a); rule = json.load(open(o['def'])); res = json.load(open(o['resource']))
    excl = o.get('notscope'); eff = rule['then']['effect']
    if excl and res.get('scope', '') .startswith(excl): print(f'{res["name"]}: ausgenommen (notScopes {excl}) -> keine Wirkung'); return
    hit = cond(rule['if'], res)
    out = 'nicht betroffen' if not hit else {'deny': 'ABGELEHNT (deny)', 'audit': 'erlaubt, als nicht konform vermerkt (audit)', 'disabled': 'Regel ausgeschaltet'}.get(eff, eff)
    print(f'{res["name"]:12} {out}')

def cmd_budget(a):
    pos, o = opts(a); b = float(o['amount']); spent = [float(x) for x in o['spent']]; th = [int(x) for x in o['alerts']]
    cum = 0
    for i, x in enumerate(spent, 1):
        cum += x; pc = cum / b * 100
        fired = [t for t in th if pc >= t and (cum - x) / b * 100 < t]
        print(f'Tag {i:2}: {cum:7.2f} von {b:g} EUR ({pc:5.1f} %)' + (''.join(f'  <- Warnung {t} %' for t in fired)))
    print('Hinweis: Eine Budgetwarnung benachrichtigt nur; sie stoppt keine Ressourcen (Fachwissen).')


def cmd_app(a):
    sub, (pos, o) = a[0], opts(a[1:])
    if sub == 'autoscale':
        inst = int(o['start']); lo, hi = int(o['min']), int(o['max']); out, up = [], int(o['out']); dn = int(o['in'])
        for i, c in enumerate([float(x) for x in o['cpu']], 1):
            old = inst
            if c > up and inst < hi: inst += 1
            elif c < dn and inst > lo: inst -= 1
            out.append(f'Messung {i}: CPU {c:5.1f} % -> Instanzen {old} -> {inst}')
        print('\n'.join(out)); print(f'Regeln: ab {up} % eine Instanz mehr (höchstens {hi}), unter {dn} % eine weniger (mindestens {lo}); Modell ohne Abkühlzeit')
    elif sub == 'swap':
        prod = json.loads(o['prod']); stg = json.loads(o['staging']); sticky = set(lst(o, 'sticky'))
        newprod = {k: (prod[k] if k in sticky else stg[k]) for k in stg}; newstg = {k: (stg[k] if k in sticky else prod[k]) for k in prod}
        print('Vor dem Tausch:   Produktion ' + json.dumps(prod, sort_keys=True) + ' | Staging ' + json.dumps(stg, sort_keys=True))
        print('Nach dem Tausch:  Produktion ' + json.dumps(newprod, sort_keys=True) + ' | Staging ' + json.dumps(newstg, sort_keys=True))
        print('Sticky (bleiben am Slot): ' + (', '.join(sorted(sticky)) or '-'))
    elif sub == 'aci':
        cpu, mem = float(o['cpu']), float(o['mem']); print(f'Container-Gruppe mit {cpu:g} vCPU und {mem:g} GiB: erfundener Preis {round(cpu * 3 + mem * 1, 2)} EUR/Tag (Modell)')

CMDS = {k[4:]: v for k, v in globals().items() if k.startswith('cmd_')}
if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS: die('Aufruf: azsim.py ' + '|'.join(sorted(CMDS)) + ' ...', 2)
    CMDS[sys.argv[1]](sys.argv[2:])
