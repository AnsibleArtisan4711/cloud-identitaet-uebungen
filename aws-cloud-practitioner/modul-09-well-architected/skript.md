# Modul 9 - Architekturprinzipien und Well-Architected

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 8 h

**Priorität:** 2

| Nr. | Lerneinheit                | Dauer (h) |
|----:|:---------------------------|----------:|
| 9.1 | Well-Architected Framework |         1 |
| 9.2 | Operational Excellence     |         1 |
| 9.3 | Security Pillar            |         1 |
| 9.4 | Reliability Pillar         |         1 |
| 9.5 | Performance Efficiency     |         1 |
| 9.6 | Cost Optimization          |         1 |
| 9.7 | Sustainability             |         1 |
| 9.8 | Architekturpatterns        |         1 |
|     | **Summe**                  |     **8** |

Dieses Modul bündelt das Wissen der vorangehenden Module zu einem Denkrahmen. Statt einzelner Dienste geht es um die Frage, was eine *gute* Cloud-Architektur ausmacht und wie man das bewertet. AWS hat dafür das Well-Architected Framework entwickelt, das auf Erfahrungen aus tausenden Kundenprojekten beruht. Es gliedert sich in sechs Säulen, die jeweils eigene Entwurfsprinzipien und typische Fragen mitbringen. Die Säulen Sicherheit, Betrieb und Kosten wurden in den Modulen 03, 07, 08 und 11 bereits fachlich behandelt; hier werden sie als Architekturperspektive zusammengeführt und um die Säulen Zuverlässigkeit, Leistung und Nachhaltigkeit ergänzt. Wo Inhalte bereits ausführlich erklärt sind, wird auf das jeweilige Modul verwiesen.

## 9.1 Well-Architected Framework

Das *AWS Well-Architected Framework* ist ein Katalog bewährter Verfahren, mit dem sich Architekturen systematisch bewerten und verbessern lassen. Es besteht aus sechs *Säulen* (Pillars): Operational Excellence (Betriebsexzellenz), Security (Sicherheit), Reliability (Zuverlässigkeit), Performance Efficiency (Leistungseffizienz), Cost Optimization (Kostenoptimierung) und Sustainability (Nachhaltigkeit). Jede Säule hat Entwurfsprinzipien, Fragen und Best Practices. Das Framework liefert keine fertige Architektur, sondern Fragen, die Schwachstellen sichtbar machen.

Wichtig ist das Verständnis für *Zielkonflikte* (Trade-offs). Die Säulen ziehen oft in verschiedene Richtungen: Höchste Zuverlässigkeit durch Multi-Region-Betrieb kostet Geld und erhöht die Komplexität; niedrigste Kosten durch Spot-Instanzen kann die Zuverlässigkeit mindern. Eine gute Architektur ist deshalb nicht in jeder Säule perfekt, sondern bewusst gewichtet, abhängig von den Anforderungen des Geschäfts. Ein internes Berichtssystem darf andere Prioritäten haben als eine Zahlungsabwicklung.

Das Framework wird in *Reviews* angewendet: Ein Team beantwortet pro Säule Fragen zum Ist-Zustand, erkennt *Risiken* (hoch, mittel) und leitet Verbesserungen ab. Es ist ein Gespräch über die Architektur und kein Prüfstand; Ziel ist Lernen, nicht Bewertung der Beteiligten. Das *AWS Well-Architected Tool*, ein kostenloser Dienst in der Console, führt durch die Fragen, speichert die Antworten, zeigt Risiken und erstellt einen Verbesserungsplan. Zusätzliche *Lenses* (Linsen) ergänzen das Framework für Spezialgebiete, etwa serverlose Anwendungen, SaaS oder maschinelles Lernen. Reviews wiederholt man bei wesentlichen Änderungen.

Die Gestaltungsprinzipien gelten übergreifend. Aus ihnen lassen sich wiederkehrende Leitsätze ableiten: Kapazitätsbedarf nicht raten, sondern messen und skalieren; Produktionstests in realistischen Umgebungen durchführen, weil Umgebungen sich per Code duplizieren lassen; Architekturen automatisieren; Architekturen schrittweise weiterentwickeln (evolutionäre Architektur) und Entscheidungen anhand von Daten treffen; Ausfälle üben (Game Days).

Das folgende Beispiel legt per CLI einen Workload im Well-Architected Tool an und listet die Säulen, damit ein Review gestartet werden kann.

```bash
aws wellarchitected create-workload --workload-name shop-produktion \
  --description "Webshop Produktion" --environment PRODUCTION \
  --lenses wellarchitected --review-owner team-shop@beispiel.de \
  --aws-regions eu-central-1 \
  --pillar-priorities security reliability costOptimization \
  --architectural-design "Web, App und DB in zwei Zonen"

aws wellarchitected list-workloads \
  --query 'WorkloadSummaries[].{Id:WorkloadId,Name:WorkloadName}'
aws wellarchitected list-lens-reviews --workload-id WORKLOAD_ID
```

`create-workload` legt den zu bewertenden Workload an und nennt die Linse (`wellarchitected` ist das Hauptframework), die Region und die wichtigsten Säulen des Teams (`--pillar-priorities`), was dem Gedanken der bewussten Gewichtung entspricht. `list-workloads` zeigt die ID, die man in den folgenden Aufrufen einsetzt (`WORKLOAD\_ID` ist ein Platzhalter). In der Console beantwortet das Team danach die Fragen pro Säule. Die Werte sind Beispiele; einige Parameter sind je nach Version des Dienstes optional.

### Typische Fehler.

Falsch: Das Framework als Zertifizierung oder Checkliste zum Abhaken zu verstehen. Falsch: Das Review nur einmal beim Start zu machen. Falsch: Alle Säulen gleich zu gewichten oder Zielkonflikte zu ignorieren. Falsch: Risiken zu dokumentieren und keine Maßnahmen mit Verantwortlichen zu vereinbaren.

### Praxisbezug.

Vor dem Livegang einer wichtigen Anwendung führt das Team ein Review durch, in dem eine Lücke in der Wiederherstellung auffällt. Sie wird vor dem Start geschlossen, was später im Ernstfall viel Geld spart.

> **Merke**
>
> Sechs Säulen: Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, Sustainability. Das Framework liefert Fragen und Best Practices, keine fertige Architektur. Zielkonflikte sind normal; das Well-Architected Tool unterstützt Reviews.

## 9.2 Operational Excellence

Die Säule *Operational Excellence* beschreibt, wie man Anwendungen so betreibt und weiterentwickelt, dass sie Geschäftswert liefern, und wie man dabei kontinuierlich lernt. Sie erweitert den Betrieb (Modul 07) um den Entwicklungsprozess: Wie wird Software ausgeliefert, wie werden Änderungen kontrolliert, wie werden Fehler gelernt?

Die Entwurfsprinzipien lauten sinngemäß: Betrieb als Code durchführen, also Infrastruktur und Abläufe in Skripten und Vorlagen beschreiben, damit sie wiederholbar und überprüfbar sind; häufige, kleine, umkehrbare Änderungen machen statt seltener großer; Betriebsabläufe regelmäßig verfeinern; Fehler vorhersehen (Pre-Mortem: “Angenommen, es geht schief, wie?”); und aus allen Betriebsereignissen lernen. Dahinter steht die Erfahrung, dass kleine Änderungen leichter zu verstehen, zu testen und zurückzunehmen sind. Ein Rollback-Plan ist dabei Pflicht.

Der Säule werden vier Bereiche zugeordnet: *Organisation* (klare Verantwortung, gemeinsame Ziele, Priorisierung), *Vorbereitung* (Beobachtbarkeit, Standardisierung, Entwurf für Betrieb), *Betrieb* (Zustand verstehen, Ereignisse behandeln) und *Weiterentwicklung* (Lernen aus Vorfällen, Verbesserungen). Technisch heißt das: Infrastructure as Code (Modul 10), CI/CD-Pipelines, Metriken und Alarme (Modul 07), Runbooks und Nachbetrachtungen sowie Kennzahlen, die den Erfolg messen, zum Beispiel Häufigkeit der Auslieferungen, Dauer bis zur Wiederherstellung und Anteil fehlerhafter Änderungen.

Das folgende Beispiel zeigt das Prinzip “Betrieb als Code” an einem kleinen Beispiel: Ein Skript prüft, ob alle laufenden EC2-Instanzen ein Pflicht-Tag `Owner` haben, und meldet Abweichungen.

```bash
#!/bin/bash
# Prueft, ob laufende Instanzen das Tag "Owner" besitzen.
ohne=$(aws ec2 describe-instances \
  --filters Name=instance-state-name,Values=running \
  --query 'Reservations[].Instances[?!not_null(Tags[?Key==`Owner`].Value | [0])].InstanceId' \
  --output text)

if [ -n "$ohne" ]; then
  echo "Instanzen ohne Owner-Tag: $ohne"
  aws sns publish --topic-arn "$TOPIC" \
    --subject "Betrieb: Owner-Tag fehlt" \
    --message "Instanzen ohne Owner-Tag: $ohne"
  exit 1
fi
echo "Alle Instanzen sind korrekt gekennzeichnet."
```

Das Skript fragt alle laufenden Instanzen ab und filtert mit einer JMESPath-Abfrage diejenigen heraus, die keinen Tag-Wert für `Owner` besitzen. Gibt es welche, schickt es eine Nachricht an das SNS-Thema (die Variable `TOPIC` muss gesetzt sein) und endet mit einem Fehlercode, was es für Pipelines geeignet macht. Ein solches Skript, regelmäßig ausgeführt, ersetzt eine Handarbeitsliste und lässt sich versionieren und testen. Die JMESPath-Syntax ist dicht; die Idee zählt: Der Betrieb prüft sich selbst.

### Typische Fehler.

Falsch: Betriebswissen nur in den Köpfen einzelner Personen zu halten. Falsch: Große, seltene Änderungen mit unklarem Rückweg. Falsch: Fehler zu vertuschen oder Schuldige zu suchen, statt zu lernen. Falsch: Zu messen, was einfach ist, statt was den Geschäftswert zeigt.

### Praxisbezug.

Ein Team liefert täglich kleine Änderungen über eine Pipeline aus. Fällt etwas auf, wird die letzte Änderung zurückgenommen, bevor das Problem wächst.

## 9.3 Security Pillar

Die *Sicherheitssäule* beschreibt, wie man Informationen, Systeme und Ressourcen schützt und dabei Geschäftswert liefert. Fachlich ist sie in den Modulen 03, 05, 06 und 08 behandelt; hier steht die Architekturperspektive im Vordergrund und der Verweis auf die Details.

Die Entwurfsprinzipien sind: Eine *starke Identitätsgrundlage* (Least Privilege, zentrale Identitätsverwaltung, keine langlebigen Zugangsdaten; Modul 03), *Nachvollziehbarkeit* (Überwachung, Alarmierung und Prüfung von Aktionen und Änderungen in Echtzeit; Modul 07), *Sicherheit auf allen Ebenen* (Defense in Depth: Netzwerk, Rechenressourcen, Daten, Anwendung), *Automatisierung von Sicherheitsmaßnahmen* (damit sie skalieren und wiederholbar sind), *Schutz von Daten in Ruhe und Transit* (Klassifizierung, Verschlüsselung; Modul 08), *Menschen von Daten fernhalten* (Zugriff über Werkzeuge und Rollen statt direkter Handarbeit) und *Vorbereitung auf Sicherheitsereignisse* (Reaktionspläne und Übungen).

Die Fragen des Frameworks lassen sich auf die Bereiche Identitäts- und Zugriffsmanagement, Erkennung, Schutz der Infrastruktur, Schutz der Daten und Reaktion auf Vorfälle abbilden. Zur Einordnung, wo welcher Dienst eingesetzt wird: Wer darf was (IAM, Organizations), wie bemerke ich Angriffe (CloudTrail, GuardDuty, Security Hub), wie begrenze ich das Netzwerk (VPC, Security Groups, WAF, Shield), wie sichere ich Daten (KMS, S3-Sicherheit, Secrets Manager) und wie reagiere ich (Runbooks, Automatisierung).

Das folgende Beispiel zeigt eine sogenannte “Sicherheits-Stichprobe” per CLI: Wenige Befehle prüfen die Grundlagen quer über mehrere Bereiche und liefern ein erstes Bild.

```bash
echo "Root MFA / Root-Schluessel:"
aws iam get-account-summary \
  --query 'SummaryMap.{MFA:AccountMFAEnabled,RootKeys:AccountAccessKeysPresent}'

echo "Security Groups mit SSH fuer alle:"
aws ec2 describe-security-groups \
  --filters Name=ip-permission.from-port,Values=22 \
            Name=ip-permission.cidr,Values=0.0.0.0/0 \
  --query 'SecurityGroups[].GroupId' --output text

echo "Unverschluesselte EBS-Volumes:"
aws ec2 describe-volumes --filters Name=encrypted,Values=false \
  --query 'Volumes[].VolumeId' --output text

echo "Access Analyzer: aktive externe Zugriffe:"
aws accessanalyzer list-analyzers --query 'analyzers[].name' --output text
```

Die Stichprobe prüft vier Bereiche: Kontoschutz (Root-MFA, Root-Schlüssel), Netzwerk (SSH aus dem ganzen Internet), Daten (unverschlüsselte Volumes) und Erkennung (existiert ein Access Analyzer). Jeder Befehl beantwortet genau eine Frage des Frameworks. Als Dauerlösung gehören solche Prüfungen in AWS Config und Security Hub (Modul 07 und 08), weil man sie dann nicht von Hand ausführen muss. Der Test auf SSH nutzt Filter, die auf Regeln passen; Varianten mit anderen Ports oder IPv6 muss man ergänzen.

### Typische Fehler.

Falsch: Sicherheit als Aufgabe eines einzelnen Teams am Projektende. Falsch: Sich auf eine Schicht zu verlassen. Falsch: Zugriffe von Menschen auf Produktionsdaten ohne Protokoll. Falsch: Reaktionspläne zu schreiben, aber nie zu üben.

### Praxisbezug.

Bei Reviews stellt sich oft heraus, dass Aufzeichnung und Alarmierung fehlen. Ein Angriff würde unbemerkt bleiben. Die Lücke ist günstig zu schließen, aber nur, wenn man sie kennt.

## 9.4 Reliability Pillar

Die Säule *Reliability* (Zuverlässigkeit) beschreibt die Fähigkeit eines Systems, seine Aufgabe korrekt und beständig zu erfüllen, Störungen zu überstehen und sich von ihnen zu erholen. Sie baut auf Hochverfügbarkeit, Fehlertoleranz und Disaster Recovery aus Modul 02 und den Zonen und Regionen aus Modul 02 auf; Backups und Wiederherstellung folgen in Modul 12.

Die Entwurfsprinzipien: *Ausfälle automatisch beheben*, indem man Kennzahlen überwacht und bei Überschreiten Maßnahmen automatisch auslöst (Auto Scaling, Selbstheilung). *Wiederherstellungsverfahren testen*, weil man in der Cloud Ausfälle gefahrlos simulieren kann (zum Beispiel mit AWS Fault Injection Service). *Horizontal skalieren*, um die Wirkung eines Einzelausfalls zu verringern, statt einen großen Server zu betreiben. *Nicht raten, welche Kapazität nötig ist*, sondern messen. Und *Änderungen über Automatisierung* durchführen.

Die Architekturmittel kennt man aus den früheren Modulen: Verteilung über mehrere Availability Zones (Modul 02, 04, 06), Load Balancer und Auto Scaling (Modul 04), Datenbanken mit Multi-AZ (Modul 05), Entkopplung durch Warteschlangen, Gesundheitsprüfungen und DNS-Failover (Modul 06). Dazu kommen drei Themen, die oft übersehen werden. Erstens die *Quoten*: Selbst eine perfekte Architektur scheitert, wenn eine Quote (zum Beispiel vCPUs) im Ernstfall nicht ausreicht, deshalb plant man Reserven ein und überwacht die Nutzung. Zweitens die *Abhängigkeiten*: Je mehr Dienste kritisch voneinander abhängen, desto geringer die Gesamtverfügbarkeit. Zwei Komponenten mit je 99,9 Prozent hintereinander ergeben etwa 99,8 Prozent, denn die Verfügbarkeiten multiplizieren sich. Drittens die *Wiederherstellungsziele*: RTO (wie lange darf es dauern) und RPO (wie viel Datenverlust ist tolerierbar) bestimmen, wie aufwendig die Architektur sein muss.

Das folgende Beispiel zeigt zuerst eine Verfügbarkeitsrechnung und danach einen Alarm, der meldet, wenn hinter dem Load Balancer zu wenige gesunde Ziele übrig sind.

```bash
# Gesamtverfuegbarkeit zweier hintereinander geschalteter Komponenten
python3 -c "print(round(0.999*0.999*100, 3))"        # 99.8
# Parallel (redundant): Ausfall nur, wenn beide ausfallen
python3 -c "print(round((1-(1-0.999)*(1-0.999))*100, 5))"   # 99.9999

# Alarm: weniger als 2 gesunde Ziele hinter dem Load Balancer
aws cloudwatch put-metric-alarm --alarm-name web-gesunde-ziele \
  --namespace AWS/ApplicationELB --metric-name HealthyHostCount \
  --dimensions Name=TargetGroup,Value=targetgroup/web-ziele/def \
               Name=LoadBalancer,Value=app/web-alb/abc \
  --statistic Minimum --period 60 --evaluation-periods 2 \
  --threshold 2 --comparison-operator LessThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:123456789012:betrieb-alarme
```

Die ersten beiden Rechnungen zeigen den Kern: Hintereinander geschaltete Komponenten verschlechtern die Gesamtverfügbarkeit (Multiplikation), parallele redundante Komponenten verbessern sie deutlich, weil beide gleichzeitig ausfallen müssten. Das gilt rechnerisch nur bei unabhängigen Ausfällen; deshalb verteilt man auf verschiedene Zonen. Der Alarm überwacht die Zahl der gesunden Ziele hinter einem Application Load Balancer und löst aus, wenn sie unter zwei fällt, bevor Nutzer etwas bemerken. Namen und ARNs sind Platzhalter.

### Typische Fehler.

Falsch: Hochverfügbarkeit in der Mitte, aber eine einzelne Datenbank oder ein einzelnes NAT Gateway als Single Point of Failure. Falsch: Backups zu erstellen, aber nie eine Wiederherstellung zu testen. Falsch: Quoten nicht zu überwachen. Falsch: Mit Wiederholungen ohne Wartezeit eine ausgelastete Komponente weiter zu überlasten (Retry-Sturm); richtig sind exponentielles Backoff und Begrenzer.

### Praxisbezug.

In einem Game Day schaltet das Team eine Zone ab (mit dem Fault Injection Service). Die Anwendung bleibt erreichbar, und die Monitoring-Alarme lösen wie vorgesehen aus. Genau das beweist die Zuverlässigkeit.

## 9.5 Performance Efficiency

Die Säule *Performance Efficiency* (Leistungseffizienz) fragt, wie man Rechen- und Speicherressourcen effizient einsetzt und die Effizienz beibehält, wenn sich Anforderungen und Technologien ändern. Gemeint ist nicht maximale Geschwindigkeit um jeden Preis, sondern die passende Leistung zum passenden Preis.

Die Entwurfsprinzipien: Fortschrittliche Technologien *demokratisieren*, indem man verwaltete Dienste nutzt, statt komplexe Systeme selbst zu betreiben (zum Beispiel Machine Learning oder Datenbanken als Dienst); *in Minuten global skalieren* durch Bereitstellung in mehreren Regionen und Edge-Standorten (Modul 02); *serverlose Architekturen* verwenden, um Betriebsaufwand zu sparen; *häufiger experimentieren*, weil Umgebungen sich leicht duplizieren lassen; und *mechanisches Verständnis* entwickeln, also wissen, wie die gewählten Dienste funktionieren, damit man sie passend einsetzt.

In der Praxis läuft die Auswahl in vier Schritten ab. Erstens die richtige *Ressource* wählen: Instanzfamilie nach Lastprofil (rechenintensiv, speicherintensiv, GPU), Lambda oder Container statt Servern bei passender Last (Modul 04), und bei Speicher die Art nach Zugriffsmuster (Modul 05). Zweitens die *Größe* anpassen (*Rightsizing*): AWS Compute Optimizer wertet die Auslastung aus und empfiehlt kleinere oder passendere Typen. Drittens *Caching und Nähe zum Nutzer*: CloudFront (Modul 02), ElastiCache und DAX bringen Daten dorthin, wo sie gebraucht werden. Viertens *Messen und überwachen*: Ohne Kennzahlen (Latenz, Durchsatz, Auslastung) bleibt Leistungsoptimierung Raten; man vergleicht vor und nach jeder Änderung.

Das folgende Beispiel fragt die Empfehlungen des Compute Optimizers ab und prüft die Auslastung einer Instanz, um Rightsizing zu begründen.

```bash
aws compute-optimizer update-enrollment-status --status Active

aws compute-optimizer get-ec2-instance-recommendations \
  --query 'instanceRecommendations[].{Id:instanceArn,Befund:finding,Aktuell:currentInstanceType,Vorschlag:recommendationOptions[0].instanceType}'

aws cloudwatch get-metric-statistics --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time $(date -u -d '14 days ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 --statistics Average Maximum
```

Der erste Befehl schaltet den Compute Optimizer ein; belastbare Empfehlungen entstehen erst nach einigen Tagen Beobachtung. Die zweite Abfrage zeigt pro Instanz, ob sie zu groß (`Overprovisioned`), passend oder zu klein ist, und welcher Typ vorgeschlagen wird. Die dritte liefert die Tageswerte der CPU über zwei Wochen als Plausibilitätsprüfung: Liegt das Maximum dauerhaft unter 20 Prozent, ist die Instanz vermutlich überdimensioniert. Bei Speicher und Netzwerk muss man die Werte des CloudWatch Agents einbeziehen.

### Typische Fehler.

Falsch: “Wir nehmen vorsichtshalber die größte Instanz”; das kostet dauerhaft und verbessert wenig. Falsch: Ohne Messung zu optimieren. Falsch: Immer das, was man kennt, zu verwenden, obwohl ein verwalteter Dienst besser passt. Falsch: Leistungsprobleme nur mit größerer Hardware zu lösen, statt Engpässe wie eine fehlende Indexierung zu beseitigen.

### Praxisbezug.

Ein Datenbankwechsel von einer allgemeinen zu einer speicheroptimierten Instanz halbiert die Antwortzeit bei gleichen Kosten, weil die Abfragen speichergebunden sind. Das zeigen die Metriken, nicht die Vermutung.

## 9.6 Cost Optimization

*Cost Optimization* bedeutet, den gewünschten Geschäftswert zum niedrigsten Preis zu erreichen. Es geht nicht darum, “möglichst wenig” auszugeben, sondern ungenutzte, überdimensionierte und ungeeignet bezahlte Ressourcen zu vermeiden. Die Details zu Preisen, Abrechnung und Werkzeugen folgen in Modul 11; hier steht der Architekturgedanke.

Die Entwurfsprinzipien: Eine *Cloud-Finanzverwaltung* (FinOps) aufbauen, in der Teams Kosten sehen und Verantwortung tragen; *Verbrauchsmodell einführen*, also nur zahlen, was man nutzt; *Gesamteffizienz messen*, indem man Kosten mit Geschäftsergebnissen vergleicht (Kosten pro Bestellung statt Gesamtkosten); *Ausgaben für undifferenzierte Schwerarbeit vermeiden*, indem man Managed Services nutzt; und *Kosten analysieren und zuordnen*, damit klar ist, wer was verursacht.

Die wichtigsten Hebel sind: *Rightsizing* (passende Größen), *Kaufoptionen* (Savings Plans oder Reservierungen für stabile Lasten, Spot für unterbrechbare; Modul 04), *Speicherklassen und Lebenszyklus* (S3-Klassen, Löschung; Modul 05), *Abschalten* (Entwicklungs- und Testumgebungen nachts und am Wochenende stoppen), *Architektur* (Serverless oder Managed Services bei schwankender Last, Entkopplung, Caching, Vermeidung teurer Datenübertragung zwischen Zonen und Regionen und über NAT Gateways; Modul 06), *Datenübertragung beachten* (Zugriffe innerhalb einer Zone sind meist günstiger) und *Tagging* für die Zuordnung. Eine einfache Rechnung zeigt die Größenordnung: Ein Entwicklungsserver, der nur werktags von 8 bis 18 Uhr läuft, ist rund 50 Stunden pro Woche aktiv statt 168; die Rechenkosten sinken damit auf etwa 30 Prozent.

Das folgende Beispiel richtet das automatische Abschalten von Entwicklungsinstanzen nach Zeitplan über Tags und eine Lambda-gesteuerte Regel ein; es zeigt hier die einfachste Variante mit einem Zeitplan in EventBridge Scheduler.

```bash
cat > ziel.json <<'EOT'
{
  "Arn": "arn:aws:scheduler:::aws-sdk:ec2:stopInstances",
  "RoleArn": "arn:aws:iam::123456789012:role/scheduler-ec2",
  "Input": "{\"InstanceIds\":[\"i-0123456789abcdef0\"]}"
}
EOT
aws scheduler create-schedule --name dev-abends-stoppen \
  --schedule-expression "cron(0 19 ? * MON-FRI *)" \
  --schedule-expression-timezone "Europe/Vienna" \
  --flexible-time-window Mode=OFF --target file://ziel.json

aws ec2 create-tags --resources i-0123456789abcdef0 \
  --tags Key=Umgebung,Value=dev Key=Owner,Value=team-shop Key=Kostenstelle,Value=4711
```

Der Zeitplan ruft werktags um 19 Uhr (Wiener Zeit) die EC2-Aktion `StopInstances` direkt über das SDK-Ziel des Schedulers auf; eine passende Rolle ist erforderlich (Platzhalter). Ein Gegenstück am Morgen startet die Instanz wieder. Die Tags `Umgebung`, `Owner` und `Kostenstelle` erlauben später, Kosten dem Team zuzuordnen. Das Beispiel zeigt die Richtung; im Alltag nutzt man oft den AWS Instance Scheduler oder Auto Scaling mit Zeitplänen.

### Typische Fehler.

Falsch: Kosten nur monatlich als Gesamtsumme zu betrachten, ohne Zuordnung. Falsch: Eine Reservierung für Last zu kaufen, die man nicht kennt. Falsch: Nicht genutzte Ressourcen wie Volumes, Snapshots, Elastic IPs oder Load Balancer liegen zu lassen. Falsch: Auf der falschen Ebene zu sparen, etwa Backups zu streichen oder Monitoring abzuschalten.

### Praxisbezug.

Ein Team stellt fest, dass 30 Prozent der Rechnung Testumgebungen sind, die nachts laufen. Zeitpläne für Abschaltung und Tags reduzieren das ohne Qualitätsverlust.

## 9.7 Sustainability

Die sechste Säule, *Sustainability* (Nachhaltigkeit), fragt nach den Umweltauswirkungen von Cloud-Arbeitslasten, vor allem nach dem Energieverbrauch und der Ressourceneffizienz. Auch hier gilt das Shared Responsibility Model, in der Ausprägung “Nachhaltigkeit *der* Cloud” und “Nachhaltigkeit *in* der Cloud”: AWS ist für Effizienz und Energieversorgung der Rechenzentren und der Hardware zuständig; der Kunde ist dafür verantwortlich, seine Anwendungen so zu entwerfen und zu betreiben, dass sie möglichst wenig Ressourcen verbrauchen.

Die Entwurfsprinzipien: Die *Auswirkungen verstehen*, indem man die Umweltwirkung der Arbeitslasten misst und Kennzahlen je Geschäftseinheit bildet (etwa Energie pro Transaktion); *Nachhaltigkeitsziele festlegen*; *Auslastung maximieren*, damit gekaufte Hardware nicht leer läuft; *neuere, effizientere Hardware und Software* nutzen (zum Beispiel Graviton-Prozessoren, die für viele Lasten bei gleicher Leistung weniger Energie benötigen); *verwaltete Dienste* einsetzen, weil AWS Ressourcen dort für viele Kunden gemeinsam und effizient betreibt; und *Downstream-Auswirkungen verringern*, etwa durch kleinere Datenmengen und weniger Anforderungen an Endgeräte der Nutzer.

Die Maßnahmen überschneiden sich stark mit der Kostenoptimierung: Überprovisionierung vermeiden, Rightsizing, Auto Scaling, Abschaltzeiten, Lebenszyklus für Daten (nicht mehr benötigte Daten löschen), effiziente Speicherformate, Caching, serverlose Dienste. Zusätzlich kann die Regionswahl eine Rolle spielen, weil der Strommix je Region unterschiedlich ist; sie ist aber nur ein Kriterium neben Latenz, Recht und Kosten. Meist sind Kosten und Nachhaltigkeit Verbündete: Was weniger Ressourcen verbraucht, kostet in der Regel auch weniger, ist aber nicht in jedem Fall dasselbe. AWS stellt mit dem *Customer Carbon Footprint Tool* Auswertungen zu den geschätzten Emissionen der eigenen Nutzung bereit.

Das folgende Beispiel zeigt zwei typische Maßnahmen: den Wechsel auf eine energieeffiziente Instanzfamilie (ARM-basierte Graviton-Instanzen) und das Löschen alter Daten per Lebenszyklusregel.

```bash
# Instanztypen der Graviton-Familie in der Region anzeigen
aws ec2 describe-instance-types \
  --filters Name=processor-info.supported-architecture,Values=arm64 \
            Name=instance-type,Values=m7g.* \
  --query 'InstanceTypes[].{Typ:InstanceType,vCPU:VCpuInfo.DefaultVCpus,RAM:MemoryInfo.SizeInMiB}' \
  --output table

# Alte Daten automatisch loeschen
aws s3api put-bucket-lifecycle-configuration \
  --bucket mein-lernbucket-2026-12345 \
  --lifecycle-configuration '{"Rules":[{"ID":"alte-daten","Status":"Enabled","Filter":{"Prefix":"temp/"},"Expiration":{"Days":30}}]}'
```

Der erste Befehl listet ARM-Instanzen der Reihe `m7g` mit Kernen und Arbeitsspeicher; ob eine Anwendung auf ARM läuft, muss man testen (kompilierte Software und Container-Images müssen für `arm64` verfügbar sein). Die Lebenszyklusregel löscht Objekte unter `temp/` nach 30 Tagen, sodass keine verwaisten Daten dauerhaft Speicherplatz belegen. Beide Maßnahmen senken Ressourcenverbrauch und meist auch Kosten.

### Typische Fehler.

Falsch: Nachhaltigkeit als reine Marketingfrage zu behandeln, ohne Messung. Falsch: Nur die Region nach Strommix zu wählen und Latenz und Datenschutz zu ignorieren. Falsch: Daten ohne Ablaufdatum anzusammeln. Falsch: Verwaiste Entwicklungsumgebungen laufen zu lassen.

### Praxisbezug.

Ein Team ergänzt seine Dashboards um eine Kennzahl “vCPU-Stunden pro tausend Bestellungen”. Sinkt der Wert, wird die Architektur effizienter, was sich auch in der Rechnung zeigt.

## 9.8 Architekturpatterns

Aus den Säulen ergeben sich wiederkehrende Muster, die in vielen AWS-Architekturen auftauchen. Drei stehen im Vordergrund: Entkopplung, Caching und die Trennung von zustandsbehafteten und zustandslosen Komponenten.

*Entkopplung* (Loose Coupling) bedeutet, Komponenten so zu verbinden, dass sie sich nicht direkt voneinander abhängig machen. Statt dass ein Webserver synchron auf die Rechnungserstellung wartet, legt er eine Nachricht in eine *Amazon SQS*-Warteschlange (Simple Queue Service); ein separater Verbraucher arbeitet sie in seinem eigenen Tempo ab. Fällt der Verbraucher aus, bleiben die Nachrichten erhalten; steigt die Last, startet man mehr Verbraucher. SQS gibt es als Standard-Warteschlange (hoher Durchsatz, mindestens einmalige Zustellung, Reihenfolge nicht garantiert) und als FIFO-Warteschlange (strikte Reihenfolge, genau einmal verarbeitet). *Amazon SNS* verteilt Nachrichten nach dem Muster Veröffentlichen und Abonnieren an viele Empfänger gleichzeitig (*Fan-out*), und *Amazon EventBridge* verbindet Dienste über Ereignisse und Regeln. Die Kombination von SNS und SQS (ein Ereignis, mehrere unabhängige Verarbeitungen mit eigenen Warteschlangen) ist ein klassisches Muster.

*Caching* speichert häufig gebrauchte Daten näher beim Verbraucher: im Browser, am Edge mit CloudFront, in der Anwendung mit *Amazon ElastiCache* (verwalteter In-Memory-Speicher mit den Engines Redis-kompatibel und Memcached, zunehmend auch Valkey) und für DynamoDB mit DAX. Das senkt Latenz und Last der Datenbank. Die Kehrseite sind veraltete Daten; man legt eine Gültigkeitsdauer (TTL) fest und überlegt, wann ein Eintrag ungültig gemacht wird.

*Zustandslose (stateless) Komponenten* speichern keine Sitzungs- oder Nutzerdaten lokal; jede Anfrage enthält alles Nötige oder holt es aus einem gemeinsamen Speicher. Dadurch kann man beliebig viele Instanzen hinzufügen oder entfernen (Auto Scaling) und ausgefallene ersetzen, ohne Daten zu verlieren. *Zustandsbehaftete* Teile (Datenbanken, Sitzungsspeicher, Dateien) gehören in dafür gemachte Dienste: RDS, DynamoDB, ElastiCache, S3, EFS. Das ergibt das klassische Dreischichtenmodell mit Load Balancer, zustandslosen Anwendungsservern in mehreren Zonen und verwalteten Datenspeichern.

Das folgende Beispiel zeigt das Entkopplungsmuster: Ein Thema verteilt Bestellereignisse an eine Warteschlange, ein Verbraucher liest sie.

```bash
Q=$(aws sqs create-queue --queue-name rechnungen \
  --attributes VisibilityTimeout=60,MessageRetentionPeriod=345600 \
  --query QueueUrl --output text)
QARN=$(aws sqs get-queue-attributes --queue-url $Q \
  --attribute-names QueueArn --query Attributes.QueueArn --output text)
T=$(aws sns create-topic --name bestellungen --query TopicArn --output text)
aws sns subscribe --topic-arn $T --protocol sqs --notification-endpoint $QARN

aws sns publish --topic-arn $T --message '{"bestellung":4711,"summe":59.90}'

aws sqs receive-message --queue-url $Q --wait-time-seconds 5 \
  --max-number-of-messages 1
aws sqs delete-message --queue-url $Q --receipt-handle HANDLE_AUS_AUSGABE
```

Die Warteschlange behält Nachrichten vier Tage und blendet eine gelesene Nachricht 60 Sekunden aus (`VisibilityTimeout`), damit sie nicht doppelt verarbeitet wird. Das Thema `bestellungen` verteilt jede veröffentlichte Nachricht an die abonnierte Warteschlange; damit SNS in die Warteschlange schreiben darf, muss deren Zugriffsrichtlinie das erlauben (hier ausgelassen). `receive-message` liest mit Langzeitabfrage (*Long Polling*), `delete-message` bestätigt die erfolgreiche Verarbeitung; ohne Löschen erscheint die Nachricht nach Ablauf der Sichtbarkeitsfrist erneut. `HANDLE\_AUS\_AUSGABE` ist ein Platzhalter.

### Typische Fehler.

Falsch: Alle Dienste synchron in Ketten zu verbinden, sodass der langsamste die Gesamtleistung bestimmt. Falsch: Nachrichten nicht idempotent zu verarbeiten; weil SQS mindestens einmal zustellt, kann eine Nachricht doppelt ankommen, und die Verarbeitung muss das vertragen. Falsch: Sitzungsdaten auf einem einzelnen Webserver zu speichern. Falsch: Caches ohne Strategie für Aktualisierung zu verwenden. Falsch: Fehlgeschlagene Nachrichten endlos zu wiederholen statt sie in eine *Dead-Letter-Queue* zu verschieben.

### Praxisbezug.

Ein Shop nimmt Bestellungen schnell an und verarbeitet Rechnung, Lager und E-Mail asynchron über SNS und SQS. In einem Lastsprung bleibt die Seite flott, weil sich Arbeit in den Warteschlangen staut und nacheinander abgebaut wird.

> **Merke**
>
> Entkopplung (SQS, SNS, EventBridge), Caching (CloudFront, ElastiCache, DAX), zustandslose Anwendungsschicht mit zustandsbehafteten Diensten für Daten. SQS-Nachrichten können doppelt ankommen; Verarbeitung idempotent halten.

## Übungsaufgaben Modul 09

1.  Nennen Sie die sechs Säulen des Well-Architected Frameworks und je eine Leitfrage.

2.  Warum sind Zielkonflikte zwischen den Säulen normal? Geben Sie ein Beispiel.

3.  Zwei Komponenten mit je 99,9 Prozent Verfügbarkeit sind (a) hintereinander, (b) parallel redundant geschaltet. Berechnen Sie die Gesamtverfügbarkeit und erklären Sie das Ergebnis.

4.  Erklären Sie den Unterschied zwischen SQS und SNS und nennen Sie den Zweck einer Dead-Letter-Queue.

5.  Was bedeutet “zustandslos” bei einer Anwendungsschicht, und warum ist es für Auto Scaling wichtig?

6.  **Praxis:** Schreiben Sie CLI-Befehle, die eine SQS-Queue mit Dead-Letter-Queue anlegen (Verschiebung nach 3 fehlgeschlagenen Versuchen).

7.  **Praxis:** Schreiben Sie ein Skript, das alle EBS-Volumes im Zustand `available` (nicht angehängt) auflistet und ihre Größe summiert, als Grundlage für eine Kostenoptimierung.

8.  **Praxis:** Führen Sie ein Mini-Review durch: Eine Anwendung läuft auf einer einzelnen EC2-Instanz mit lokaler Datenbank in einer Zone, Backups gibt es nicht. Ordnen Sie je Säule mindestens ein Risiko und eine Maßnahme zu.

## Lösungen Modul 09

1.  Operational Excellence: Wie führen wir Änderungen sicher durch und lernen aus Vorfällen? Security: Wer darf was, wie erkennen wir Angriffe? Reliability: Wie überstehen wir Ausfälle und erholen uns? Performance Efficiency: Passen Ressourcen zur Last? Cost Optimization: Zahlen wir nur für Nötiges? Sustainability: Wie verbrauchen wir möglichst wenig Ressourcen?

2.  Weil Maßnahmen für eine Säule andere belasten können: Multi-Region erhöht Zuverlässigkeit, aber auch Kosten und Komplexität; Spot senkt Kosten, mindert aber die Planbarkeit. Gute Architekturen gewichten bewusst nach den Geschäftsanforderungen.

3.  \(a\) 0,999 mal 0,999 gleich etwa 99,8 Prozent: Beide müssen laufen, die Ausfallwahrscheinlichkeiten addieren sich nahezu. (b) 1 minus (0,001 mal 0,001) gleich 99,9999 Prozent: Es fällt nur aus, wenn beide gleichzeitig ausfallen. Die Rechnung gilt für unabhängige Ausfälle, daher verteilt man auf getrennte Zonen.

4.  SQS ist eine Warteschlange (ein Verbraucher holt Nachrichten ab, Pufferung), SNS ein Publish/Subscribe-Dienst, der eine Nachricht an viele Abonnenten verteilt. Eine Dead-Letter-Queue nimmt Nachrichten auf, die nach einer festgelegten Zahl von Versuchen nicht verarbeitet werden konnten, damit sie nicht endlos kreisen und analysiert werden können.

5.  Zustandslos heißt, dass der Server keine nutzerspezifischen Daten lokal hält; Zustand liegt in gemeinsamen Diensten (Datenbank, Cache, S3). Auto Scaling kann dann Instanzen beliebig hinzufügen und entfernen, ohne dass Sitzungen oder Daten verloren gehen.

6.  ```bash
    DLQ=$(aws sqs create-queue --queue-name auftraege-dlq --query QueueUrl --output text)
    DLQARN=$(aws sqs get-queue-attributes --queue-url $DLQ \
      --attribute-names QueueArn --query Attributes.QueueArn --output text)
    aws sqs create-queue --queue-name auftraege \
      --attributes "{\"RedrivePolicy\":\"{\\\"deadLetterTargetArn\\\":\\\"$DLQARN\\\",\\\"maxReceiveCount\\\":\\\"3\\\"}\"}"
    ```

    Nach drei erfolglosen Empfangsversuchen verschiebt SQS die Nachricht in die Dead-Letter-Queue.

7.  ```bash
    aws ec2 describe-volumes --filters Name=status,Values=available \
      --query 'Volumes[].{Id:VolumeId,GiB:Size,Zone:AvailabilityZone}' --output table
    aws ec2 describe-volumes --filters Name=status,Values=available \
      --query 'sum(Volumes[].Size)'
    ```

    Die zweite Abfrage summiert die Größe in GiB. Vor dem Löschen sollte man Snapshots erstellen und die Besitzer fragen.

8.  Beispiele: Operational Excellence: manuelle Konfiguration, kein Monitoring; Maßnahme: Infrastruktur als Code, CloudWatch-Alarme. Security: öffentliche Adresse, unklare Rechte; Maßnahme: privates Subnetz, Rolle, Verschlüsselung. Reliability: Single Point of Failure, keine Backups; Maßnahme: Multi-AZ, RDS statt lokaler Datenbank, Backups testen. Performance: Instanzgröße geraten; Maßnahme: Messen und Rightsizing. Cost: Dauerbetrieb ohne Plan; Maßnahme: Tags, Budget, Savings Plan bei stabiler Last. Sustainability: Überprovisionierung; Maßnahme: Auslastung messen, passende Größe, Abschaltzeiten für Testumgebungen.
