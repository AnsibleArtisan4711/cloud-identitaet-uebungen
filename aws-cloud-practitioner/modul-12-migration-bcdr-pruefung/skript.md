# Modul 12 - Migration, BCDR und Pruefungsvorbereitung

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 8 h

**Priorität:** 3

|  Nr. | Lerneinheit                     | Dauer (h) |
|-----:|:--------------------------------|----------:|
| 12.1 | Migrationstreiber und Strategie |         1 |
| 12.2 | 6R/7R Migrationsmuster          |         1 |
| 12.3 | Migration Services              |         1 |
| 12.4 | Backup-Grundlagen               |         1 |
| 12.5 | Disaster Recovery Konzepte      |         1 |
| 12.6 | BCDR-Governance                 |         1 |
| 12.7 | Prüfungsreview CLF-C02          |         1 |
| 12.8 | Abschluss-Lab und Readiness     |         1 |
|      | **Summe**                       |     **8** |

Dieses letzte Modul verbindet zwei Themen, die in der Praxis zusammengehören: den Weg bestehender Systeme in die Cloud (Migration) und den Schutz vor Ausfall und Datenverlust (Backup und Disaster Recovery, zusammen *BCDR*, Business Continuity and Disaster Recovery). Danach folgt die Prüfungsvorbereitung für CLF-C02, die den Stoff der Module 01 bis 11 bündelt. Wer die vorherigen Module durchgearbeitet hat, findet hier vor allem Zusammenhänge: Migration nutzt Compute, Speicher und Netzwerk, Disaster Recovery nutzt Regionen und Zonen, und beides wird über Kosten, Governance und Automatisierung gesteuert.

## 12.1 Migrationstreiber und Strategie

Eine Migration ist kein technisches Selbstzweckprojekt, sondern beantwortet eine geschäftliche Frage. Typische *Treiber* sind: Kosten (Ablösung von Hardware, die ersetzt werden müsste, oder ein Rechenzentrumsvertrag, der ausläuft), Agilität (neue Umgebungen in Minuten statt Wochen), Skalierbarkeit für schwankende Last, Ausfallsicherheit und Reichweite (Regionen nahe an den Kunden), Zugang zu neuen Diensten wie Analytik oder Machine Learning und schließlich Sicherheits- und Compliance-Anforderungen. Ein Team sollte seine Treiber ausdrücklich benennen und gewichten, denn sie entscheiden später, welche Systeme zuerst umziehen und wie viel Umbau sich lohnt. Wer nur “Kosten sparen” nennt, wählt meist den schnellsten Weg; wer Agilität nennt, ist eher bereit, Anwendungen umzubauen.

AWS beschreibt den Weg in drei Phasen, die sich in der Praxis überlappen. In der *Bewertungsphase* (Assess) wird geklärt, ob und wie bereit die Organisation ist: Welche Systeme gibt es, wie hängen sie zusammen, welche Fähigkeiten fehlen, welche Risiken bestehen? Die Ergebnisse fließen in den Business Case (Modul 11). In der *Mobilisierungsphase* (Mobilize) entstehen die Grundlagen: eine Landing Zone mit Kontostruktur, Netzwerk, Identitäten und Sicherheitsvorgaben (Module 03, 06 und 08), Schulung und erste Pilotprojekte. In der *Migrations- und Modernisierungsphase* (Migrate and Modernize) ziehen Anwendungen in Wellen um und werden anschließend betrieben und verbessert. Dazu passt das *AWS Cloud Adoption Framework* (CAF), das Fähigkeiten in Perspektiven wie Geschäft, Menschen, Governance, Plattform, Sicherheit und Betrieb ordnet. Es erinnert daran, dass die Technik nur ein Teil der Arbeit ist: Rollen, Prozesse und Schulungen entscheiden oft über den Erfolg.

Der Kern der Planung ist die *Portfolioanalyse*. Man erfasst alle Anwendungen mit Eigentümer, Kritikalität, Technologie, Abhängigkeiten, Datenmengen und Lizenzen, und ordnet jeder eine Migrationsstrategie zu (nächste Einheit). Anwendungen werden in *Wellen* gruppiert: Zuerst kommen einfache, wenig kritische Systeme, um zu lernen, danach die komplexeren. Eng gekoppelte Systeme müssen gemeinsam oder in abgestimmter Reihenfolge umziehen, sonst entstehen Verzögerungen über die Verbindung zwischen Rechenzentrum und Cloud.

Das folgende Beispiel ist ein kleines Werkzeug für die Portfolioanalyse: Es ordnet Anwendungen nach einfachen Regeln einer Welle zu. Die Regeln sind bewusst vereinfacht und dienen der Anschauung.

```bash
python3 - <<'EOT'
apps = [
  {"name": "Intranet-Wiki",   "kritisch": 1, "abhaengig": 0, "gb": 50},
  {"name": "Shop",            "kritisch": 5, "abhaengig": 4, "gb": 800},
  {"name": "Reporting",       "kritisch": 2, "abhaengig": 1, "gb": 300},
  {"name": "Zeiterfassung",   "kritisch": 2, "abhaengig": 0, "gb": 20},
]
def punkte(a):                     # kleiner = einfacher
    return a["kritisch"] * 2 + a["abhaengig"] * 3 + a["gb"] / 200
for a in sorted(apps, key=punkte):
    welle = 1 if punkte(a) < 5 else 2 if punkte(a) < 15 else 3
    print(f'Welle {welle}: {a["name"]:15s} (Punkte {punkte(a):.1f})')
EOT
```

Das Skript bewertet jede Anwendung mit einem Punktwert aus Kritikalität, Abhängigkeiten und Datenmenge und teilt sie anhand fester Schwellen einer Welle zu. Die Sortierung stellt einfache Systeme nach vorn. Die Gewichte und Schwellen sind frei erfunden; in einem echten Projekt kommen sie aus dem Inventar von Discovery-Werkzeugen (Einheit 12.3) und aus Gesprächen mit den Fachabteilungen. Wichtig ist, dass die Zuordnung nachvollziehbar und anpassbar ist.

### Typische Fehler.

Falsch: Mit dem kritischsten System zu beginnen, um “Eindruck zu machen”. Richtig: Mit einem einfachen Pilot lernen. Falsch: Abhängigkeiten nicht zu erfassen, sodass nach dem Umzug Verbindungen scheitern. Falsch: Die Landing Zone erst nach dem ersten Umzug zu bauen. Falsch: Schulung zu vergessen; ein Team, das die Cloud nicht kennt, baut die alte Welt nur woanders nach.

### Praxisbezug.

Läuft der Vertrag eines Rechenzentrums in 18 Monaten aus, definiert das den Zeitplan. Ein Team bildet drei Wellen, startet mit dem Intranet-Wiki und nutzt die Erfahrungen, um die Landing Zone zu verbessern, bevor der Shop folgt.

> **Merke**
>
> Migration beginnt mit dem Geschäftsziel. Drei Phasen: Assess, Mobilize, Migrate and Modernize. Landing Zone vor dem ersten Umzug. Anwendungen in Wellen planen, einfach zuerst, Abhängigkeiten beachten.

## 12.2 6R/7R Migrationsmuster

Für jede Anwendung muss entschieden werden, *wie* sie in die Cloud kommt. AWS beschreibt dafür Migrationsstrategien, ursprünglich als “6 Rs”, heute meist mit sieben Mustern. Die Namen sind prüfungsrelevant und sollten sicher zugeordnet werden können.

*Rehost* (“Lift and Shift”) verschiebt die Anwendung unverändert, zum Beispiel einen Server als EC2-Instanz. Es ist schnell und risikoarm, nutzt aber die Vorteile der Cloud kaum; Einsparungen entstehen vor allem durch Wegfall der Hardware und späteres Rightsizing. *Replatform* (“Lift, Tinker and Shift”) nimmt geringe Anpassungen vor, um einen verwalteten Dienst zu nutzen, etwa eine selbst betriebene Datenbank durch Amazon RDS zu ersetzen. Der Code bleibt weitgehend gleich, der Betriebsaufwand sinkt. *Refactor* (oder Re-architect) baut die Anwendung neu auf cloud-nativen Prinzipien auf, zum Beispiel als Microservices mit Lambda und DynamoDB. Das ist der aufwendigste Weg, bringt aber die größten Vorteile bei Skalierung und Agilität. *Repurchase* (“Drop and Shop”) ersetzt die Anwendung durch ein Software-as-a-Service-Produkt, etwa ein selbst betriebenes CRM durch einen SaaS-Anbieter. *Relocate* verlegt Systeme ohne Neuanschaffung und ohne Änderung auf die Cloud-Version derselben Plattform, typisch bei VMware-Umgebungen auf VMware Cloud on AWS; der Umzug ist schnell, weil Werkzeuge und Betriebsabläufe gleich bleiben. *Retain* bedeutet, die Anwendung vorerst an ihrem Ort zu lassen, etwa wegen Abhängigkeit von Spezialhardware, rechtlicher Vorgaben oder weil sie bald abgelöst wird; man prüft später erneut. *Retire* schließlich schaltet die Anwendung ab, weil sie nicht mehr gebraucht wird. In der Bestandsaufnahme zeigt sich oft, dass ein erheblicher Teil der Systeme kaum noch genutzt wird; das Abschalten spart die gesamte Migration.

Welche Strategie passt, hängt von Treibern, Zeit, Budget, Know-how und der Lebensdauer der Anwendung ab. Eine hilfreiche Entscheidungsreihenfolge: erst fragen, ob die Anwendung noch gebraucht wird (Retire), dann ob sie bleiben muss (Retain), dann ob ein fertiges Produkt sie ersetzen kann (Repurchase), und erst danach, wie stark man sie umbaut. Man kann die Strategie auch später verfeinern: Ein Rehost ist oft der erste Schritt, dem nach dem Umzug schrittweise ein Replatform oder Refactor folgt. Das senkt das Risiko, weil Umzug und Umbau getrennt werden.

Das folgende Beispiel zeigt eine einfache Entscheidungslogik als Code und ordnet Anwendungseigenschaften einer der Strategien zu.

```bash
python3 - <<'EOT'
def strategie(a):
    if not a.get("genutzt", True):            return "Retire"
    if a.get("spezialhardware") or a.get("recht"): return "Retain"
    if a.get("saas_verfuegbar"):              return "Repurchase"
    if a.get("vmware"):                       return "Relocate"
    if a.get("eigene_db") and not a.get("umbau"): return "Replatform"
    if a.get("umbau"):                        return "Refactor"
    return "Rehost"

tests = [
  {"name": "Altsystem",  "genutzt": False},
  {"name": "CRM",        "saas_verfuegbar": True},
  {"name": "ERP",        "eigene_db": True},
  {"name": "Webshop",    "umbau": True},
  {"name": "Fileserver"},
]
for t in tests:
    print(f'{t["name"]:12s} -> {strategie(t)}')
EOT
```

Die Funktion prüft die Fragen in der oben beschriebenen Reihenfolge und liefert die erste passende Strategie zurück; die Reihenfolge ist also Teil der Logik. Ohne besondere Eigenschaft landet eine Anwendung bei Rehost als Grundeinstellung. Die Ausgabe ordnet im Beispiel das Altsystem Retire, das CRM Repurchase, das ERP Replatform, den Webshop Refactor und den Fileserver Rehost zu. Die Regeln sind bewusst vereinfacht; echte Entscheidungen berücksichtigen zusätzlich Kosten, Risiko und Zeit.

### Typische Fehler.

Falsch: Alles per Rehost zu migrieren und dann zu erwarten, dass die Cloud automatisch günstiger sei. Falsch: Alles refactoren zu wollen; das dauert Jahre. Falsch: Die Begriffe zu verwechseln: Replatform ändert nur Teile (zum Beispiel Datenbank als Dienst), Refactor ändert die Architektur. Falsch: Anwendungen zu migrieren, die niemand mehr braucht.

### Praxisbezug.

In einem Portfolio von 200 Anwendungen werden typischerweise einige abgeschaltet, einige bleiben, die Mehrheit zieht per Rehost oder Replatform um, und nur wenige strategische Anwendungen werden refactort.

> **Merke**
>
> Sieben Muster: Retire, Retain, Rehost, Relocate, Repurchase, Replatform, Refactor. Rehost = unverändert, Replatform = kleine Anpassung (verwalteter Dienst), Refactor = neue Architektur, Repurchase = SaaS, Relocate = gleiche Plattform in der Cloud.

## 12.3 Migration Services

AWS bietet für jede Phase Werkzeuge. Für die Bestandsaufnahme gibt es den *AWS Application Discovery Service*: Er sammelt über einen Agenten oder agentenlos Informationen zu Servern, Auslastung und Netzwerkverbindungen in der bestehenden Umgebung und liefert so die Grundlage für Abhängigkeitsanalyse und Größenplanung. *AWS Migration Evaluator* (Modul 11) ergänzt die Kostenseite. Der *AWS Migration Hub* bietet einen zentralen Ort, um den Fortschritt von Migrationen über mehrere Werkzeuge hinweg zu verfolgen.

Für den Umzug von Servern ist der *AWS Application Migration Service* (MGN) das Standardwerkzeug für Rehost: Ein Agent auf dem Quellserver repliziert die Datenträger fortlaufend in ein Staging-Gebiet in AWS. Wenn der Zeitpunkt gekommen ist, startet man Testinstanzen, prüft sie und führt dann den *Cutover* durch: Die Quelle wird abgeschaltet, die Zielinstanz wird produktiv. Weil die Replikation fortlaufend läuft, ist die Ausfallzeit kurz. Für Datenbanken gibt es den *AWS Database Migration Service* (DMS), der Daten zwischen Datenbanken kopiert und nach einer ersten Volllast Änderungen fortlaufend nachführt (Change Data Capture), sodass die Quelle während der Migration weiterlaufen kann. Er unterstützt homogene Migrationen (gleiche Engine) und heterogene (zum Beispiel Oracle nach PostgreSQL). Bei heterogenen Wechseln wandelt die *AWS Schema Conversion Tool* oder ihr Nachfolger in DMS die Schemas und Code um; manuelle Nacharbeit bleibt nötig.

Für Dateien und große Datenmengen gibt es *AWS DataSync*, das Daten zwischen lokalem Speicher (NFS, SMB) und AWS-Speicherdiensten beschleunigt und automatisiert überträgt, mit Prüfung der Integrität und Zeitplänen. Der *AWS Transfer Family*-Dienst stellt SFTP-, FTPS- und FTP-Endpunkte bereit, die direkt auf S3 oder EFS schreiben und so bestehende Partner-Schnittstellen weiter bedienen. Für sehr große Datenmengen oder schlechte Netzanbindung gibt es die *AWS Snow Family*, physische Geräte, die mit Daten gefüllt und per Kurier an AWS geschickt werden (“Sneakernet” auf Industrieniveau). Ob eine Übertragung über das Netz oder per Gerät sinnvoller ist, ergibt sich aus Datenmenge und Bandbreite: Bei Terabytes und langsamer Leitung dauert das Netz oft Wochen.

> **Ergänzung aus der Nachrecherche**
>
> Das Angebot der Snow-Familie hat sich in den letzten Jahren geändert; einzelne Geräte wurden für Neukunden eingestellt oder durch andere Angebote ersetzt. Dieser Text wurde nicht gegen die aktuelle Produktseite geprüft. Vor einer Planung ist zu klären, welche Geräte aktuell bestellbar sind. Für die Prüfung genügt das Prinzip: Physische Geräte für große Datenmengen bei begrenzter Bandbreite, DataSync und Direct Connect (Modul 06) für laufende Übertragungen.

Das folgende Beispiel richtet per CLI eine DataSync-Übertragung von einem NFS-Server nach S3 ein und startet sie. Voraussetzung ist ein bereits bereitgestellter DataSync-Agent; ARNs und Adressen sind Platzhalter.

```bash
quelle=$(aws datasync create-location-nfs \
  --server-hostname 10.0.1.25 --subdirectory /export/daten \
  --on-prem-config AgentArns=arn:aws:datasync:eu-central-1:123456789012:agent/agent-0abc \
  --query LocationArn --output text)

ziel=$(aws datasync create-location-s3 \
  --s3-bucket-arn arn:aws:s3:::migration-ziel-beispiel \
  --s3-config BucketAccessRoleArn=arn:aws:iam::123456789012:role/DataSyncS3Rolle \
  --query LocationArn --output text)

task=$(aws datasync create-task --source-location-arn "$quelle" \
  --destination-location-arn "$ziel" --name nfs-nach-s3 \
  --options VerifyMode=ONLY_FILES_TRANSFERRED,TransferMode=CHANGED \
  --query TaskArn --output text)

aws datasync start-task-execution --task-arn "$task"
```

Die ersten beiden Befehle legen Quelle (NFS-Freigabe, erreichbar über den Agenten) und Ziel (S3-Bucket mit einer IAM-Rolle, die DataSync schreiben lässt) als Orte an und speichern deren ARNs in Variablen. Der dritte Befehl verbindet beide zu einer Aufgabe; die Option `TransferMode=CHANGED` überträgt bei Wiederholungen nur geänderte Dateien, `VerifyMode` prüft die übertragenen Dateien. Der letzte startet die Ausführung. Ein typischer Ablauf: ein erster Volllauf vorab und ein kurzer Abgleich kurz vor dem Cutover.

### Typische Fehler.

Falsch: Datenmengen und Bandbreite nicht zu rechnen und dann am Cutover-Termin festzustellen, dass die Übertragung Wochen dauert. Falsch: Eine heterogene Datenbankmigration nur mit DMS zu planen und den Umbau von Anwendungscode zu vergessen. Falsch: Den Cutover nie zu proben. Falsch: Den Rückweg (Rollback) nicht vorzubereiten.

### Praxisbezug.

Ein Team repliziert 40 Server mit MGN, startet Testinstanzen am Wochenende, prüft sie mit den Fachbereichen und führt den Cutover in einem kurzen Wartungsfenster durch; die Datenbank läuft dank DMS bis kurz vor Umschaltung weiter.

## 12.4 Backup-Grundlagen

Ein *Backup* ist eine getrennte Kopie von Daten, die es erlaubt, nach Fehlern, Löschungen, Ransomware oder Ausfällen einen früheren Zustand wiederherzustellen. Wichtig ist die Abgrenzung zur Hochverfügbarkeit: Multi-AZ-Betrieb (Modul 02, 05) schützt vor dem Ausfall einer Zone, aber nicht davor, dass jemand versehentlich Daten löscht oder falsche Daten schreibt, denn die Änderung wird sofort auf alle Kopien übertragen. Replikation ist deshalb kein Backup. Ein Backup muss zusätzlich zeitlich zurückreichen und von den Produktivdaten getrennt sein.

Eine bewährte Faustregel ist die *3-2-1-Regel*: mindestens drei Kopien der Daten, auf zwei verschiedenen Medien oder Systemen, davon eine an einem anderen Ort. In der Cloud entspricht das etwa: Produktivdaten, ein Backup in derselben Region und ein Backup in einer anderen Region oder einem anderen Konto. Das andere Konto ist wichtig, weil es auch gegen kompromittierte Zugangsdaten schützt.

AWS bietet dafür auf mehreren Ebenen Werkzeuge. Dienste haben eigene Mechanismen: EBS-Snapshots (inkrementell, in S3 gespeichert), RDS-Sicherungen mit Wiederherstellung zu einem Zeitpunkt (Point-in-Time Recovery), DynamoDB-Sicherungen und Point-in-Time Recovery, S3-Versionierung und Replikation (Modul 05). *AWS Backup* fasst diese zusammen: Man definiert zentral *Backup-Pläne* mit Zeitplan und Aufbewahrungsdauer, weist Ressourcen per Tag oder ID zu und speichert die Sicherungen in einem *Backup Vault*. Es unterstützt Kopien in andere Regionen und Konten und, über *Vault Lock*, eine unveränderliche Speicherung nach dem WORM-Prinzip (write once, read many), die auch Administratoren nicht umgehen können, was gegen Ransomware und Manipulation hilft. Zusätzlich erlauben Berichte, die Einhaltung von Vorgaben nachzuweisen.

Zwei Kennzahlen bestimmen die Planung: Wie oft gesichert wird, bestimmt, wie viel Datenverlust im schlimmsten Fall droht (RPO, nächste Einheit), und wie lange die Wiederherstellung dauert, bestimmt die Ausfallzeit (RTO). Ein Backup ist erst dann wertvoll, wenn die *Wiederherstellung getestet* wurde; ein ungeprüftes Backup ist eine Hoffnung.

Das folgende Beispiel legt mit AWS Backup einen täglichen Plan an, der per Tag ausgewählte Ressourcen sichert und nach 35 Tagen löscht.

```bash
aws backup create-backup-vault --backup-vault-name tresor-prod

cat > plan.json <<'EOT'
{
  "BackupPlanName": "taeglich-35-tage",
  "Rules": [{
    "RuleName": "taeglich",
    "TargetBackupVaultName": "tresor-prod",
    "ScheduleExpression": "cron(0 2 * * ? *)",
    "StartWindowMinutes": 60,
    "CompletionWindowMinutes": 180,
    "Lifecycle": {"DeleteAfterDays": 35}
  }]
}
EOT
planid=$(aws backup create-backup-plan --backup-plan file://plan.json \
  --query BackupPlanId --output text)

cat > auswahl.json <<'EOT'
{
  "SelectionName": "alle-mit-tag",
  "IamRoleArn": "arn:aws:iam::123456789012:role/service-role/AWSBackupDefaultServiceRole",
  "ListOfTags": [{"ConditionType": "STRINGEQUALS",
                  "ConditionKey": "Backup", "ConditionValue": "taeglich"}]
}
EOT
aws backup create-backup-selection --backup-plan-id "$planid" \
  --backup-selection file://auswahl.json
```

Der erste Befehl legt den Tresor an. Die Plandatei beschreibt eine Regel: täglich um 2 Uhr UTC (cron-Ausdruck), Start innerhalb von 60 Minuten, Abschluss innerhalb von 180 Minuten, Aufbewahrung 35 Tage. Der Plan wird erzeugt und seine ID gespeichert. Die Auswahl verbindet den Plan mit allen Ressourcen, die das Tag `Backup=taeglich` tragen, und nutzt dafür eine Servicerolle von AWS Backup. Damit wird neu getaggten Ressourcen automatisch gesichert, was ein Argument für den konsequenten Tagging-Standard aus Modul 11 ist. Kontonummer und Rolle sind Platzhalter.

### Typische Fehler.

Falsch: Multi-AZ oder Replikation mit Backup zu verwechseln. Falsch: Backups im selben Konto und derselben Region wie die Daten zu halten. Falsch: Die Wiederherstellung nie zu testen. Falsch: Keine Aufbewahrungsfristen zu definieren; Kosten und Rechtspflichten laufen dann auseinander. Falsch: Backup-Daten unverschlüsselt zu speichern.

### Praxisbezug.

Nach einem versehentlichen Löschen einer Tabelle stellt das Team sie aus der Point-in-Time-Sicherung auf einen Zeitpunkt wenige Minuten vor dem Fehler her. Das Backup in einem separaten Konto schützt zudem gegen kompromittierte Zugangsdaten.

> **Merke**
>
> Replikation ist kein Backup. 3-2-1: drei Kopien, zwei Medien, eine an anderem Ort. AWS Backup zentralisiert Pläne, Vaults, Kopien über Regionen und Konten sowie Vault Lock. Nur getestete Wiederherstellungen zählen.

## 12.5 Disaster Recovery Konzepte

*Disaster Recovery* (DR) beschreibt, wie man nach einem schweren Ausfall, etwa dem Verlust einer ganzen Region, durch Fehler, Naturereignisse oder Angriffe den Betrieb wieder aufnimmt. Zwei Kennzahlen legen die Anforderungen fest. Das *Recovery Point Objective* (RPO) gibt an, wie viel Datenverlust, gemessen in Zeit, höchstens akzeptabel ist; ein RPO von fünf Minuten verlangt, dass Daten mindestens so oft gesichert oder repliziert werden. Das *Recovery Time Objective* (RTO) gibt an, wie lange der Dienst höchstens ausfallen darf, bis er wieder läuft. Beide werden aus dem Geschäftswert abgeleitet: Je kleiner RPO und RTO, desto teurer die Lösung. Nicht jedes System braucht dieselben Werte; eine Analyse der Auswirkungen (Business Impact Analysis) ordnet die Systeme in Stufen.

AWS beschreibt vier typische Strategien, die sich nach Kosten und Wiederherstellungsgeschwindigkeit unterscheiden. *Backup and Restore* ist die günstigste: Daten werden gesichert (wenn nötig in eine andere Region), im Notfall wird die Umgebung neu aufgebaut, am besten per Infrastruktur als Code (Modul 10), und die Daten werden zurückgespielt. RPO und RTO liegen im Bereich von Stunden. Bei *Pilot Light* läuft in der DR-Region nur der Kern, meist die replizierten Datenbanken, während die Rechenleistung ausgeschaltet oder minimal bleibt und im Notfall hochgefahren wird; wie die Zündflamme eines Heizkessels. *Warm Standby* hält eine vollständige, aber verkleinerte Umgebung laufend bereit, die im Notfall hochskaliert wird; sie kann schneller übernehmen, kostet aber dauerhaft mehr. *Multi-Site Active/Active* betreibt mehrere Regionen gleichzeitig produktiv und verteilt die Last; fällt eine aus, übernehmen die anderen, sodass RTO und RPO nahe null liegen können. Das ist die teuerste und komplexeste Variante, vor allem wegen der Datenhaltung über Regionen hinweg.

Bausteine dafür kennt man aus früheren Modulen: Route 53 mit Gesundheitsprüfungen und Failover-Routing (Modul 06), S3-Replikation, RDS-Read-Replicas und Aurora Global Database, DynamoDB Global Tables (Modul 05), AMIs und Snapshots in anderen Regionen sowie CloudFormation für den schnellen Aufbau. Speziell für Server gibt es *AWS Elastic Disaster Recovery*, das ähnlich wie MGN fortlaufend repliziert und im Notfall Instanzen startet. Man unterscheidet Ausfälle einer Zone, die durch Multi-AZ abgedeckt sind, von Ausfällen einer Region, für die DR in einer anderen Region nötig ist.

Das folgende Beispiel zeigt Failover-Routing in Route 53 für Warm Standby: Eine Gesundheitsprüfung überwacht die primäre Region, bei Ausfall antwortet der DNS-Eintrag mit der sekundären.

```bash
hc=$(aws route53 create-health-check --caller-reference dr-$(date +%s) \
  --health-check-config Type=HTTPS,FullyQualifiedDomainName=primaer.beispiel.de,Port=443,ResourcePath=/health,RequestInterval=30,FailureThreshold=3 \
  --query HealthCheck.Id --output text)

cat > failover.json <<EOT
{"Changes": [
 {"Action": "UPSERT", "ResourceRecordSet": {
   "Name": "app.beispiel.de", "Type": "CNAME", "TTL": 60,
   "SetIdentifier": "primaer", "Failover": "PRIMARY",
   "HealthCheckId": "$hc",
   "ResourceRecords": [{"Value": "primaer.beispiel.de"}]}},
 {"Action": "UPSERT", "ResourceRecordSet": {
   "Name": "app.beispiel.de", "Type": "CNAME", "TTL": 60,
   "SetIdentifier": "sekundaer", "Failover": "SECONDARY",
   "ResourceRecords": [{"Value": "sekundaer.beispiel.de"}]}}
]}
EOT
aws route53 change-resource-record-sets --hosted-zone-id Z0123456789ABC \
  --change-batch file://failover.json
```

Die Gesundheitsprüfung ruft alle 30 Sekunden den Pfad `/health` der primären Adresse ab und gilt nach drei Fehlschlägen als ausgefallen. Die Änderungsdatei legt zwei Einträge unter demselben Namen an: den primären, der an die Prüfung gebunden ist, und den sekundären als Ausweich. Eine kurze TTL von 60 Sekunden sorgt dafür, dass Clients den Wechsel zügig sehen; das heißt, dass die tatsächliche Umschaltzeit aus Prüfintervall, Fehlerzahl und TTL besteht und in das RTO eingerechnet werden muss. Zone-ID und Domains sind Platzhalter.

### Typische Fehler.

Falsch: RPO und RTO nicht festzulegen und “möglichst schnell” zu planen. Falsch: DR-Pläne nur auf Papier zu haben. Falsch: Die DR-Region nicht auf Servicelimits, Kapazität und Berechtigungen vorzubereiten. Falsch: Abhängigkeiten zu vergessen, etwa Identitätsdienste oder DNS, die selbst nur in einer Region liegen. Falsch: Das Failback (Rückkehr) nicht zu bedenken.

### Praxisbezug.

Ein Onlineshop wählt für Bestellungen Warm Standby (RTO unter einer Stunde), für das interne Wiki Backup and Restore (RTO ein Tag) und spart so Kosten, ohne das Geschäft zu gefährden.

> **Merke**
>
> RPO = tolerierter Datenverlust, RTO = tolerierte Ausfallzeit. Vier Strategien von günstig und langsam bis teuer und schnell: Backup and Restore, Pilot Light, Warm Standby, Multi-Site Active/Active.

## 12.6 BCDR-Governance

Technik allein macht noch keine Ausfallsicherheit. Die *Governance* legt fest, wer was entscheidet, was gilt und wie geprüft wird. Zentral ist die Unterscheidung zwischen *Business Continuity* (Fortführung der Geschäftsprozesse, auch mit Notlösungen) und *Disaster Recovery* (Wiederherstellung der IT-Systeme). Ein Notfallplan beginnt mit der Business Impact Analysis: Welche Prozesse sind kritisch, welche Ausfallzeit ist tragbar, welche Abhängigkeiten bestehen? Daraus entstehen Klassen mit festgelegten RPO und RTO, Zuständigkeiten und Budgets.

Zur Governance gehören Dokumente und Rollen. *Runbooks* beschreiben Schritt für Schritt, wie ein Ausfall behandelt wird, sodass auch ein Team unter Druck handlungsfähig bleibt; sie lassen sich teilweise mit AWS Systems Manager automatisieren (Modul 10). Eine *Eskalations- und Kommunikationsliste* legt fest, wer wann informiert wird, einschließlich Kunden und Aufsicht. Rollen wie Incident Commander und Kommunikationsverantwortlicher vermeiden Chaos. Nach jedem Vorfall steht eine *Nachbetrachtung* (Post-Mortem) ohne Schuldzuweisung, deren Maßnahmen verfolgt werden (Modul 07).

Ohne Tests bleibt jeder Plan eine Annahme. Übungen reichen vom Durchsprechen am Tisch (Tabletop) über das Wiederherstellen aus Backups in einer Testumgebung bis zu echten Umschaltungen in die DR-Region (Game Days). *AWS Fault Injection Service* (FIS) erlaubt kontrollierte Fehlerexperimente, etwa das Beenden von Instanzen oder das Stören von Netzwerkverbindungen, um zu prüfen, ob die Anwendung wie erwartet reagiert. *AWS Resilience Hub* bewertet Anwendungen gegen definierte RPO- und RTO-Ziele und gibt Empfehlungen. Ergänzend kontrollieren AWS Config und Backup-Berichte, ob Vorgaben eingehalten werden, und die Säule Zuverlässigkeit des Well-Architected Frameworks (Modul 09) liefert Fragen für die Selbstprüfung.

Rechtliche und vertragliche Vorgaben beeinflussen die Planung, etwa Aufbewahrungsfristen, Regionswahl aus Datenschutzgründen und branchenspezifische Anforderungen an Ausfallsicherheit. Diese Hinweise sind keine Rechtsberatung; verbindliche Auskunft geben Fachleute für Datenschutz und Recht. Auch das Modell der geteilten Verantwortung (Modul 08) gilt: AWS stellt resiliente Infrastruktur bereit, aber Architektur, Backups, Tests und Pläne liegen beim Kunden.

Das folgende Beispiel führt ein kontrolliertes Experiment mit dem Fault Injection Service durch: Es beendet eine zufällige, getaggte EC2-Instanz und prüft damit, ob der Auto Scaling Group-Verbund den Verlust ausgleicht.

```bash
cat > experiment.json <<'EOT'
{
  "description": "Eine Instanz der Web-Gruppe beenden",
  "targets": {
    "webinstanzen": {
      "resourceType": "aws:ec2:instance",
      "resourceTags": {"Rolle": "web"},
      "selectionMode": "COUNT(1)"
    }
  },
  "actions": {
    "beenden": {
      "actionId": "aws:ec2:terminate-instances",
      "targets": {"Instances": "webinstanzen"}
    }
  },
  "stopConditions": [{
    "source": "aws:cloudwatch:alarm",
    "value": "arn:aws:cloudwatch:eu-central-1:123456789012:alarm:Fehlerrate-hoch"
  }],
  "roleArn": "arn:aws:iam::123456789012:role/FisRolle"
}
EOT
vorlage=$(aws fis create-experiment-template --cli-input-json file://experiment.json \
  --query experimentTemplate.id --output text)
aws fis start-experiment --experiment-template-id "$vorlage"
```

Die Vorlage wählt per Tag `Rolle=web` genau eine Instanz zufällig aus und beendet sie. Wichtig ist die *Stop-Bedingung*: Steigt der CloudWatch-Alarm für die Fehlerrate, bricht das Experiment ab, sodass der Test nicht selbst zum Ausfall wird. Die IAM-Rolle erlaubt dem Dienst die Aktion und sollte so eng wie möglich sein. Das Ziel des Versuchs ist eine Aussage wie: “Die Gruppe startet innerhalb von drei Minuten Ersatz, und die Fehlerrate bleibt unter einem Prozent.” Zeigt sich anderes, hat man eine Schwäche gefunden, bevor ein echter Ausfall sie zeigt. ARNs sind Platzhalter, und Experimente beginnt man zuerst in Testumgebungen.

### Typische Fehler.

Falsch: Notfallpläne einmal zu schreiben und nie zu aktualisieren. Falsch: Runbooks nur in dem System zu speichern, das ausfällt. Falsch: Zu wenig Personal zu schulen; im Ernstfall sind nur Spezialisten erreichbar. Falsch: Chaos-Experimente ohne Stop-Bedingung in Produktion. Falsch: Rechtliche Vorgaben erst nach der Planung zu prüfen.

### Praxisbezug.

Ein Unternehmen führt zweimal im Jahr einen Game Day durch, protokolliert tatsächliche Wiederherstellungszeiten und vergleicht sie mit dem RTO. Abweichungen werden Maßnahmen im nächsten Quartal.

## 12.7 Prüfungsreview CLF-C02

Die Prüfung *AWS Certified Cloud Practitioner* (CLF-C02) testet Grundverständnis, keine Konfigurationsfertigkeit. Laut Prüfungsleitfaden besteht sie aus Multiple-Choice- und Mehrfachauswahlfragen mit Bewertung auf einer Skala bis 1000 und einer Bestehensgrenze von 700 Punkten; einige Fragen sind ungewertet und dienen der Erprobung. Dauer und Gewichtung der Themenbereiche gehören in die aktuelle Prüfungsbeschreibung und wurden hier nicht abgerufen (siehe Quellenverzeichnis); bitte dort nachlesen. Die Themenbereiche lauten: Cloud-Konzepte, Sicherheit und Compliance, Cloud-Technologie und -Dienste sowie Abrechnung, Preise und Support.

Zur Wiederholung hilft es, die Module nach Bereichen zu ordnen. *Cloud-Konzepte* umfassen Vorteile der Cloud, Wert und Kostenmodell (Modul 01), globale Infrastruktur und Bereitstellungsmodelle (Modul 02) sowie die Säulen des Well-Architected Frameworks und Prinzipien der Cloud-Architektur (Modul 09). *Sicherheit und Compliance* umfassen das Modell der geteilten Verantwortung, IAM, Konten- und Organisationsstruktur (Modul 03), Verschlüsselung, Bedrohungserkennung, Compliance-Berichte (Modul 08) und das Netzwerk (Modul 06). *Technologie und Dienste* umfassen Compute, Speicher, Datenbanken, Netzwerk (Module 04 bis 06), Betrieb und Monitoring (Modul 07), Automation (Modul 10) und Migration (dieses Modul). *Abrechnung und Support* umfassen Preismodelle, Kostenwerkzeuge, Rabatte und Support-Pläne (Modul 11).

Fragen sind häufig szenariobasiert: “Ein Unternehmen will X; welcher Dienst passt?” Bewährte Methode: Schlüsselwörter erkennen (zum Beispiel “verwaltet”, “serverlos”, “unveränderlich”, “kostengünstigste”, “geringster Betriebsaufwand”), offensichtlich falsche Antworten streichen und die Antwort wählen, die die Anforderung mit dem geringsten Aufwand erfüllt. Typische Verwechslungen sind lehrreich: Security Group gegen Network ACL, Inspector gegen GuardDuty, CloudWatch gegen CloudTrail, Savings Plan gegen Reserved Instance, Replikation gegen Backup, Rehost gegen Replatform. Zu jedem Paar gibt es einen Satz, der es trennt, und diese Sätze sollte man auswendig können.

Das folgende kleine Hilfsprogramm baut aus einer Liste von Begriffspaaren ein Abfragespiel für die Konsole; es dient der Selbstkontrolle.

```bash
python3 - <<'EOT'
import random
paare = {
 "Wer protokolliert API-Aufrufe?": "CloudTrail",
 "Wer sammelt Metriken und Alarme?": "CloudWatch",
 "Wer erkennt Bedrohungen anhand von Logs?": "GuardDuty",
 "Wer scannt EC2 und Container auf Schwachstellen?": "Inspector",
 "Zustandsbehaftete Firewall pro Instanz?": "Security Group",
 "Zustandslose Firewall pro Subnetz?": "Network ACL",
 "Unveraenderliche Backups?": "Vault Lock",
 "Verwalteter Dienst statt eigener DB (kleine Anpassung)?": "Replatform",
}
fragen = list(paare.items()); random.shuffle(fragen)
richtig = 0
for frage, antwort in fragen:
    eingabe = input(frage + " ").strip().lower()
    if eingabe == antwort.lower():
        richtig += 1; print("richtig")
    else:
        print("falsch, richtig ist:", antwort)
print(f"{richtig} von {len(fragen)}")
EOT
```

Das Programm mischt die Fragen, liest die Eingaben und vergleicht sie unabhängig von Groß- und Kleinschreibung mit der gespeicherten Antwort. Am Ende steht die Trefferquote. Die Liste lässt sich beliebig erweitern; sinnvoll sind besonders die Paare, die man selbst verwechselt. Als Selbsttest ist es nützlicher, falsch beantwortete Begriffe zu markieren und erneut zu üben, als alles gleichmäßig zu wiederholen.

### Typische Fehler.

Falsch: Nur Begriffe auswendig zu lernen, ohne Szenarien zu üben. Falsch: Ältere Aussagen (Free Tier, Support-Pläne, Dienstnamen) ungeprüft zu übernehmen; die aktuelle Prüfungsbeschreibung und Dokumentation gelten. Falsch: Zu viel Zeit an einer Frage zu verlieren; unsichere Fragen markieren und später zurückkehren. Falsch: Beim Mehrfachauswahl-Format zu wenig Antworten zu wählen.

### Praxisbezug.

Das Zertifikat belegt Grundwissen gegenüber Kunden und Arbeitgebern; der eigentliche Wert liegt darin, die Dienste einem Nicht-Techniker verständlich erklären zu können.

## 12.8 Abschluss-Lab und Readiness

Das Abschluss-Lab verbindet Themen aller Module in einem kleinen, aber vollständigen Szenario. Aufgabe: Eine einfache Webanwendung soll in einem eigenen Test-Konto aufgebaut, abgesichert, überwacht, gesichert und kostenkontrolliert werden. Das geht mit den Bausteinen aus den Modulen, ohne neue Technik: Ein S3-Bucket liefert statische Inhalte mit Verschlüsselung und gesperrtem öffentlichem Zugriff (Module 05 und 08), ein Budget warnt vor Kosten (Modul 11), ein CloudWatch-Alarm überwacht die Fehlerrate (Modul 07), AWS Backup sichert Daten (diese Einheit), und alles wird per CloudFormation beschrieben, damit es reproduzierbar ist und nach dem Lab vollständig gelöscht werden kann (Modul 10).

Wichtig sind Schutzmaßnahmen für das Lab selbst: ein separates Konto oder zumindest eine Region mit Budget und Alarm, MFA für den Root User, kein Root-Betrieb, und am Ende das Aufräumen. Vergessene Ressourcen sind die häufigste Ursache unerwarteter Rechnungen (Modul 11). Dazu kommt eine Checkliste der *Bereitschaft* (Readiness): Kann ich die Preisprinzipien, die Säulen, die geteilte Verantwortung, die RPO/RTO-Begriffe und die Migrationsmuster ohne Hilfe erklären? Kann ich zu jedem Dienst in einem Satz sagen, wofür er da ist und wann er *nicht* passt?

Das folgende Template baut den Kern des Labs: einen verschlüsselten, nicht öffentlichen Bucket und ein Kostenbudget in einem Stack.

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: Abschluss-Lab - Bucket und Budget
Parameters:
  Mail:
    Type: String
    Description: E-Mail-Adresse fuer Budget-Warnungen
Resources:
  LabBucket:
    Type: AWS::S3::Bucket
    DeletionPolicy: Delete
    Properties:
      VersioningConfiguration: {Status: Enabled}
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault: {SSEAlgorithm: AES256}
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags: [{Key: Backup, Value: taeglich}, {Key: Projekt, Value: lab}]
  LabBudget:
    Type: AWS::Budgets::Budget
    Properties:
      Budget:
        BudgetName: lab-10-usd
        BudgetType: COST
        TimeUnit: MONTHLY
        BudgetLimit: {Amount: 10, Unit: USD}
      NotificationsWithSubscribers:
        - Notification:
            NotificationType: ACTUAL
            ComparisonOperator: GREATER_THAN
            Threshold: 80
          Subscribers:
            - {SubscriptionType: EMAIL, Address: !Ref Mail}
Outputs:
  BucketName:
    Value: !Ref LabBucket
```

Das Template definiert zwei Ressourcen. Der Bucket aktiviert Versionierung und Standardverschlüsselung, sperrt jeden öffentlichen Zugriff und trägt Tags für Backup und Kostenzuordnung. Das Budget begrenzt auf 10 US-Dollar monatlich und warnt per E-Mail bei 80 Prozent der tatsächlichen Kosten. Die Adresse kommt als Parameter, damit sie nicht fest im Template steht. Beim Löschen des Stacks wird der leere Bucket mit entfernt; enthält er noch Objekte, muss man ihn zuvor leeren, was ein häufiger Stolperstein ist. Ausgeführt wird es mit `aws cloudformation deploy`, gelöscht mit `aws cloudformation delete-stack`.

### Typische Fehler.

Falsch: Das Lab im Produktivkonto durchzuführen. Falsch: Am Ende nicht aufzuräumen. Falsch: Den Root User für die Arbeit zu verwenden. Falsch: Nur nachzumachen, ohne zu überlegen, *warum* jede Einstellung gesetzt ist.

### Praxisbezug.

Dasselbe Muster, ein paar Ressourcen als Code, abgesichert, überwacht, mit Budget, ist die Grundlage jeder neuen Umgebung in einem Unternehmen. Wer es im Kleinen beherrscht, kann es im Großen wiederholen.

## Übungsaufgaben Modul 12

1.  Nennen Sie die sieben Migrationsmuster und erklären Sie in je einem Satz den Unterschied zwischen Rehost, Replatform und Refactor.

2.  Welche drei Phasen beschreibt AWS für den Weg in die Cloud, und warum gehört eine Landing Zone in die zweite?

3.  Warum ist Multi-AZ-Betrieb kein Ersatz für ein Backup? Nennen Sie ein Beispiel.

4.  Erklären Sie RPO und RTO. Ein System darf höchstens 15 Minuten Daten verlieren und eine Stunde ausfallen. Welche Strategie passt am ehesten?

5.  Ordnen Sie zu: Pilot Light, Warm Standby, Backup and Restore, Multi-Site Active/Active, jeweils nach Kosten (aufsteigend) und typischer Wiederherstellungszeit.

6.  **Praxis:** Schreiben Sie einen AWS-Backup-Plan (JSON und CLI), der stündlich sichert, 7 Tage aufbewahrt und alle Ressourcen mit dem Tag `Backup=stuendlich` auswählt.

7.  **Praxis:** Erweitern Sie das Python-Skript zur Strategiewahl um eine Regel, die Anwendungen mit Datenmengen über 10 TB der Strategie “Daten per Gerät oder DataSync vorab übertragen” zuordnet, und testen Sie sie mit drei Beispielen.

8.  **Praxis:** Schreiben Sie ein CloudFormation-Template für einen S3-Bucket mit Versionierung und Replikationshinweis (Tag), einen Alarm auf die Fehlermeldung Ihrer Wahl und prüfen Sie es mit `aws cloudformation validate-template`.

## Lösungen Modul 12

1.  Retire, Retain, Rehost, Relocate, Repurchase, Replatform, Refactor. Rehost verschiebt unverändert (Lift and Shift), Replatform nimmt kleine Anpassungen vor, um verwaltete Dienste zu nutzen (zum Beispiel RDS statt eigener Datenbank), Refactor baut die Anwendung cloud-nativ neu auf.

2.  Assess (Bewertung), Mobilize (Mobilisierung), Migrate and Modernize. Die Landing Zone mit Konten, Netzwerk, Identitäten und Sicherheitsvorgaben muss stehen, bevor Anwendungen umziehen, sonst entstehen unkontrollierte Einzelumgebungen.

3.  Multi-AZ schützt vor dem Ausfall einer Zone, repliziert aber auch Fehler: Wird eine Tabelle versehentlich gelöscht, ist sie sofort auf allen Kopien weg. Ein Backup erlaubt die Rückkehr zu einem früheren Zustand.

4.  RPO ist die höchste tolerierte Datenverlustspanne, RTO die höchste tolerierte Ausfallzeit. Bei 15 Minuten RPO und einer Stunde RTO passt am ehesten Warm Standby (oder Pilot Light mit kontinuierlicher Datenreplikation, falls Hochfahren in unter einer Stunde gelingt); reines Backup and Restore reicht meist nicht.

5.  Aufsteigend nach Kosten: Backup and Restore (Stunden), Pilot Light (zehn Minuten bis Stunden), Warm Standby (Minuten), Multi-Site Active/Active (nahe null).

6.  ```bash
    cat > plan.json <<'EOT'
    {"BackupPlanName":"stuendlich-7-tage","Rules":[{
     "RuleName":"stuendlich","TargetBackupVaultName":"tresor-prod",
     "ScheduleExpression":"cron(0 * * * ? *)",
     "StartWindowMinutes":60,"CompletionWindowMinutes":120,
     "Lifecycle":{"DeleteAfterDays":7}}]}
    EOT
    planid=$(aws backup create-backup-plan --backup-plan file://plan.json \
      --query BackupPlanId --output text)
    cat > sel.json <<'EOT'
    {"SelectionName":"stuendlich-tag",
     "IamRoleArn":"arn:aws:iam::123456789012:role/service-role/AWSBackupDefaultServiceRole",
     "ListOfTags":[{"ConditionType":"STRINGEQUALS",
       "ConditionKey":"Backup","ConditionValue":"stuendlich"}]}
    EOT
    aws backup create-backup-selection --backup-plan-id "$planid" \
      --backup-selection file://sel.json
    ```

    Der Tresor muss vorher existieren; Rolle und Konto sind Platzhalter.

7.  Beispiellösung:

    ```bash
    python3 - <<'EOT'
    def strategie(a):
        if not a.get("genutzt", True): return "Retire"
        if a.get("tb", 0) > 10: return "Daten vorab per Geraet/DataSync, dann Rehost"
        return "Rehost"
    for t in [{"name":"A","genutzt":False},{"name":"B","tb":25},{"name":"C","tb":1}]:
        print(t["name"], "->", strategie(t))
    EOT
    ```

    Die neue Regel steht vor der Standardregel, damit sie greift; die Ausgabe ist Retire, Gerät/DataSync und Rehost.

8.  Beispiellösung:

    ```yaml
    AWSTemplateFormatVersion: "2010-09-09"
    Resources:
      Daten:
        Type: AWS::S3::Bucket
        Properties:
          VersioningConfiguration: {Status: Enabled}
          Tags: [{Key: Replikation, Value: geplant}]
      FehlerAlarm:
        Type: AWS::CloudWatch::Alarm
        Properties:
          AlarmName: bucket-4xx-fehler
          Namespace: AWS/S3
          MetricName: 4xxErrors
          Dimensions:
            - {Name: BucketName, Value: !Ref Daten}
            - {Name: FilterId, Value: Gesamt}
          Statistic: Sum
          Period: 300
          EvaluationPeriods: 1
          Threshold: 10
          ComparisonOperator: GreaterThanThreshold
          TreatMissingData: notBreaching
    ```

    Der Alarm nutzt die S3-Request-Metriken, die für den Bucket erst aktiviert sein müssen; ohne diese bleibt er ohne Daten. Die Prüfung erfolgt mit `aws cloudformation validate-template --template-body file://vorlage.yaml`. Ein einfacherer Alarm auf eine andere Metrik ist ebenfalls zulässig.
