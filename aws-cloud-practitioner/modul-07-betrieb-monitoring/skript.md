# Modul 7 - Betrieb, Monitoring und Troubleshooting

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 9 h

**Priorität:** 2

| Nr. | Lerneinheit                    | Dauer (h) |
|----:|:-------------------------------|----------:|
| 7.1 | CloudWatch Metrics             |         1 |
| 7.2 | CloudWatch Logs                |         1 |
| 7.3 | Alarme und Benachrichtigungen  |         1 |
| 7.4 | CloudTrail                     |         1 |
| 7.5 | AWS Config                     |         1 |
| 7.6 | AWS Health und Trusted Advisor |         1 |
| 7.7 | Incident-Grundlagen            |         1 |
| 7.8 | Fehlerbilder im Betrieb        |         2 |
|     | **Summe**                      |     **9** |

Eine Anwendung in die Cloud zu bringen ist der erste Schritt, sie dauerhaft zuverlässig zu betreiben der zweite. Betrieb bedeutet, jederzeit zu wissen, ob alles funktioniert, bei Abweichungen schnell benachrichtigt zu werden, nachvollziehen zu können, was wann von wem verändert wurde, und bei Störungen strukturiert vorzugehen. Dieses Modul stellt dafür die wichtigsten Dienste vor und trennt sauber, welcher Dienst welche Frage beantwortet: CloudWatch sagt, *wie es der Anwendung geht*, CloudTrail, *wer was getan hat*, AWS Config, *wie etwas konfiguriert war*, und AWS Health, *ob AWS selbst ein Problem hat*. Diese Unterscheidung ist in der Prüfung sehr häufig gefragt. Sicherheitsaspekte der Protokollierung wurden in Modul 08 behandelt, Grundlagen der Fehlersuche bei Compute und Netzwerk in den Modulen 04 und 06.

## 7.1 CloudWatch Metrics

*Amazon CloudWatch* ist der zentrale Überwachungsdienst. Er sammelt *Metriken*: Zeitreihen von Messwerten wie CPU-Auslastung, Netzwerkverkehr, Anzahl der Anfragen oder Fehlerrate. Fast jeder AWS-Dienst veröffentlicht automatisch Metriken in CloudWatch, ohne dass man etwas einrichten muss. Eine Metrik wird durch drei Angaben eindeutig bestimmt: den *Namespace* (Gruppierung, meist der Dienst, zum Beispiel `AWS/EC2`), den *Metriknamen* (zum Beispiel `CPUUtilization`) und optional *Dimensionen* (Schlüssel-Wert-Paare wie `InstanceId=i-0123`, die die Quelle eingrenzen). Messwerte werden zu Zeiträumen (*Period*, zum Beispiel 60 oder 300 Sekunden) zusammengefasst und mit einer *Statistik* wie Durchschnitt, Maximum, Summe oder Perzentil (p99) ausgewertet.

Welche Metriken sind für die wichtigsten Dienste relevant? Bei EC2 sind es CPU-Auslastung, Netzwerk ein und aus, Datenträger-Durchsatz und Statusprüfungen. Standardmäßig veröffentlicht EC2 im Fünf-Minuten-Takt (*Basic Monitoring*); gegen Aufpreis gibt es minütliche Werte (*Detailed Monitoring*). Wichtig: Arbeitsspeicher- und Festplattenbelegung innerhalb der Instanz sieht AWS nicht, weil sie im Betriebssystem liegen; dafür installiert man den *CloudWatch Agent*. Beim Load Balancer sind es Anfragenzahl, Antwortzeit und die Zahl der 5xx-Fehler, bei RDS CPU, freier Speicher und Verbindungen, bei Lambda Aufrufe, Fehler, Dauer und Drosselungen. Bei der Interpretation gilt: Einzelne Spitzen sind selten ein Problem, interessant sind Trends und Zusammenhänge, etwa ob steigende Latenz zusammen mit steigender CPU auftritt.

Eigene Werte lassen sich als *benutzerdefinierte Metriken* veröffentlichen, zum Beispiel die Zahl der Bestellungen pro Minute. Mehrere Metriken fasst man in einem *Dashboard* zusammen, das eine Betriebsübersicht auf einen Blick liefert. Zur Aufbewahrung: CloudWatch behält Daten in gestaffelter Auflösung, hochauflösende Werte kurz, aggregierte Werte über Monate bis etwa fünfzehn Monate. Metriken sind regional.

Das folgende Beispiel liest die CPU-Auslastung einer Instanz der letzten Stunde, veröffentlicht eine eigene Metrik und legt ein einfaches Dashboard an.

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average Maximum

aws cloudwatch put-metric-data --namespace Shop \
  --metric-name Bestellungen --value 12 --unit Count

aws cloudwatch put-dashboard --dashboard-name betrieb \
  --dashboard-body '{"widgets":[{"type":"metric","x":0,"y":0,"width":12,"height":6,"properties":{"metrics":[["AWS/EC2","CPUUtilization","InstanceId","i-0123456789abcdef0"]],"period":300,"stat":"Average","region":"eu-central-1","title":"CPU"}}]}'
```

Die erste Abfrage ruft Durchschnitt und Maximum der CPU in Fünf-Minuten-Abschnitten ab; die Zeitangaben berechnet die Shell mit `date`. Der zweite Befehl schreibt den Wert 12 in die eigene Metrik `Bestellungen` im Namespace `Shop`; eine solche Metrik taucht nach wenigen Minuten in der Console auf. Das Dashboard enthält ein einziges Diagrammfeld. Die Instanz-ID ist ein Platzhalter.

### Typische Fehler.

Falsch: Anzunehmen, CloudWatch zeige automatisch Arbeitsspeicher und Festplattenbelegung von EC2. Falsch: Nur Mittelwerte zu betrachten; ein Durchschnitt von 40 Prozent kann Spitzen von 100 Prozent verbergen. Falsch: Die falsche Region in der Console anzusehen und “keine Daten” zu finden. Falsch: Detaillierte Überwachung überall einzuschalten, ohne die Kosten zu bedenken.

### Praxisbezug.

Ein Betriebsteam hat ein Dashboard mit den Kennzahlen “Anfragen, Fehlerrate, Latenz, Auslastung der Datenbank”, das beim Schichtwechsel als Ausgangspunkt dient.

> **Merke**
>
> CloudWatch Metrics = Messwerte über die Zeit. Namespace, Name, Dimension, Period, Statistik. EC2 liefert standardmäßig alle 5 Minuten, Arbeitsspeicher und Festplatte nur mit dem CloudWatch Agent.

## 7.2 CloudWatch Logs

Metriken sagen, *dass* etwas auffällig ist, Logs sagen, *was* passiert ist. *CloudWatch Logs* sammelt, speichert und durchsucht Protokolldaten von Anwendungen, Betriebssystemen und AWS-Diensten. Die Struktur besteht aus *Log Groups* (eine Gruppe pro Anwendung oder Dienst, mit gemeinsamen Einstellungen wie Aufbewahrung und Zugriffsrechten) und darin *Log Streams* (eine Folge von Einträgen aus einer Quelle, zum Beispiel einer Instanz oder einem Container). Jeder Eintrag hat einen Zeitstempel und eine Nachricht.

Viele Dienste schreiben automatisch Logs: Lambda legt für jede Funktion eine Log Group `/aws/lambda/NAME` an, Flow Logs, API Gateway und Route 53 können nach CloudWatch Logs liefern. Für EC2-Instanzen oder lokale Server installiert man den *CloudWatch Agent*, der Dateien wie `/var/log/messages` oder Anwendungsprotokolle weiterleitet. Wichtig ist die *Aufbewahrung* (Retention): Standardmäßig behält CloudWatch Logs Daten unbegrenzt, was bei großen Mengen teuer wird. Man legt deshalb pro Log Group eine sinnvolle Dauer fest, etwa 30 Tage für Anwendungslogs und länger für Audit-Daten, oder exportiert alte Logs nach S3.

Zur Auswertung dienen mehrere Mittel. *Metric Filters* erzeugen aus Mustern im Log eine Metrik, zum Beispiel die Anzahl der Zeilen mit “ERROR”; daran kann man Alarme knüpfen. *Logs Insights* ist eine Abfragesprache zum interaktiven Durchsuchen und Aggregieren. *Subscription Filters* leiten Logs in Echtzeit an Lambda, Kinesis oder andere Ziele weiter. Strukturierte Logs im JSON-Format lassen sich deutlich besser auswerten als freier Text. Logs können vertrauliche Daten enthalten, deshalb gehören Zugriffsrechte und gegebenenfalls Verschlüsselung mit KMS dazu, und Passwörter oder personenbezogene Daten sollten gar nicht erst protokolliert werden.

Das folgende Beispiel legt eine Log Group mit 30 Tagen Aufbewahrung an, schreibt Einträge, erzeugt einen Metric Filter und fragt mit Logs Insights Fehler ab.

```bash
aws logs create-log-group --log-group-name /shop/anwendung
aws logs put-retention-policy --log-group-name /shop/anwendung \
  --retention-in-days 30
aws logs create-log-stream --log-group-name /shop/anwendung \
  --log-stream-name server-1
aws logs put-log-events --log-group-name /shop/anwendung \
  --log-stream-name server-1 \
  --log-events timestamp=$(date +%s000),message="ERROR Zahlung abgelehnt"

aws logs put-metric-filter --log-group-name /shop/anwendung \
  --filter-name fehler --filter-pattern "ERROR" \
  --metric-transformations metricName=Fehler,metricNamespace=Shop,metricValue=1

aws logs start-query --log-group-name /shop/anwendung \
  --start-time $(date -d '1 hour ago' +%s) --end-time $(date +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'
```

Zuerst entstehen Log Group und Stream, die Aufbewahrung beträgt 30 Tage. `put-log-events` schreibt einen Eintrag mit aktuellem Zeitstempel in Millisekunden. Der Metric Filter zählt jede Zeile mit “ERROR” als Metrik `Fehler`. Die Abfrage mit `start-query` nutzt die Logs-Insights-Syntax: Felder auswählen, filtern, sortieren und begrenzen; das Ergebnis holt man mit `get-query-results` über die zurückgegebene Abfrage-ID. In neueren Versionen der CLI genügt auch `aws logs tail` für die Live-Ansicht.

### Typische Fehler.

Falsch: Aufbewahrung nicht zu setzen und Kosten ansteigen zu lassen. Falsch: Logs nur auf der Instanz zu lassen; mit der Instanz sind sie bei einem Ausfall weg. Falsch: Sensible Daten wie Passwörter zu loggen. Falsch: Ohne einheitliches Format zu loggen, sodass Auswertungen mühsam werden.

### Praxisbezug.

Bei einem Fehlerbericht eines Kunden sucht das Team in Logs Insights nach der Anfrage-ID und sieht sofort, welcher Dienst in welchem Schritt scheiterte.

## 7.3 Alarme und Benachrichtigungen

Niemand will den ganzen Tag auf Dashboards starren. *CloudWatch Alarms* überwachen eine Metrik und lösen Aktionen aus, sobald ein Schwellwert verletzt wird. Ein Alarm hat drei Zustände: `OK` (Wert im Normalbereich), `ALARM` (Schwelle verletzt) und `INSUFFICIENT\_DATA` (nicht genug Daten für eine Bewertung, etwa kurz nach dem Anlegen). Er wird durch Metrik, Statistik, Zeitraum, Schwellwert, Vergleichsoperator und die Zahl der Datenpunkte definiert: “Wenn die durchschnittliche CPU in 3 von 3 aufeinanderfolgenden Fünf-Minuten-Zeiträumen über 80 Prozent liegt”. Mehrere Datenpunkte verhindern Fehlalarme durch kurze Spitzen. Fehlende Daten kann man bewusst als “gut”, “schlecht” oder “ignorieren” behandeln.

Was passiert bei einem Alarm? Meist wird eine Nachricht über *Amazon SNS* (Simple Notification Service) versendet. SNS arbeitet nach dem Muster Veröffentlichen und Abonnieren: Ein *Topic* (Thema) bündelt Empfänger, die *Subscriptions* (Abonnements) sind, zum Beispiel E-Mail, SMS, HTTPS-Endpunkte oder Lambda-Funktionen. Alarme können außerdem Auto Scaling auslösen (Modul 04), EC2-Instanzen stoppen, neu starten oder wiederherstellen und über EventBridge weitere Automatisierungen anstoßen. *Composite Alarms* verknüpfen mehrere Alarme logisch, um Alarmflut zu vermeiden, und *Anomaly Detection* lernt das normale Muster einer Metrik und alarmiert bei Abweichungen statt bei festen Schwellen.

Gute Alarme sind *aussagekräftig und handlungsrelevant*: Jeder Alarm sollte bedeuten, dass jemand etwas tun muss. Alarme, die ständig ohne Folgen auslösen, führen zu Ermüdung, und echte Probleme gehen unter. Typische Schwellwerte betreffen Verfügbarkeit (Fehlerrate und Statusprüfungen), Kapazität (CPU, Speicherplatz, Verbindungen) und Kosten. Für Kosten gibt es zusätzlich AWS Budgets (Modul 11) und den Alarm auf die geschätzten Gebühren; die Metrik `EstimatedCharges` liegt in der Region `us-east-1` und setzt aktivierte Rechnungsbenachrichtigungen voraus.

Das folgende Beispiel legt ein SNS-Topic mit E-Mail-Abonnement und einen CPU-Alarm an.

```bash
TOPIC=$(aws sns create-topic --name betrieb-alarme \
  --query TopicArn --output text)
aws sns subscribe --topic-arn $TOPIC --protocol email \
  --notification-endpoint betrieb@beispiel.de

aws cloudwatch put-metric-alarm --alarm-name web-cpu-hoch \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --statistic Average --period 300 --evaluation-periods 3 \
  --datapoints-to-alarm 3 --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions $TOPIC --ok-actions $TOPIC

aws cloudwatch set-alarm-state --alarm-name web-cpu-hoch \
  --state-value ALARM --state-reason "Test der Benachrichtigung"
```

Das Topic wird erstellt und mit einer E-Mail-Adresse abonniert; der Empfänger muss das Abonnement per Link in einer Bestätigungsmail annehmen, sonst kommen keine Nachrichten. Der Alarm löst aus, wenn der Durchschnitt in drei aufeinanderfolgenden Fünf-Minuten-Zeiträumen über 80 Prozent liegt, benachrichtigt das Topic bei `ALARM` und bei der Rückkehr zu `OK` und behandelt fehlende Daten als unkritisch. Mit `set-alarm-state` setzt man den Zustand manuell, um die Kette zu testen; beim nächsten Messzyklus korrigiert CloudWatch ihn wieder.

### Typische Fehler.

Falsch: Das E-Mail-Abonnement nicht zu bestätigen. Falsch: Schwellen aus dem Bauch zu setzen und nie anzupassen. Falsch: Alarme nur für die Technik, nicht für das Geschäft (zum Beispiel Bestellungen pro Minute fällt auf null). Falsch: Alarme ohne Zuständigen und ohne Handlungsanweisung (Runbook).

### Praxisbezug.

Die Bereitschaft erhält Alarme für “Fehlerrate über 2 Prozent” per Chat und für “Dienst vollständig ausgefallen” zusätzlich per Anruf. Die Dringlichkeit bestimmt den Kanal.

## 7.4 CloudTrail

*AWS CloudTrail* protokolliert die API-Aufrufe in einem Konto und beantwortet damit die Fragen “Wer hat was wann von wo getan?”. Jede Aktion in AWS, ob über Console, CLI, SDK oder andere Dienste, ist ein API-Aufruf; CloudTrail zeichnet ihn mit Zeitpunkt, Identität, Quelladresse, Parametern und Ergebnis auf. Es ist die Grundlage für Sicherheitsanalysen, Fehlersuche und Compliance-Nachweise.

Man unterscheidet Ereignisarten. *Management Events* (auch Control-Plane-Ereignisse) beschreiben Verwaltungsaktionen wie das Anlegen einer Instanz, das Ändern einer Richtlinie oder Anmeldungen an der Console. *Data Events* betreffen Zugriffe auf Daten, etwa das Lesen und Schreiben von S3-Objekten oder Lambda-Aufrufe; sie sind sehr zahlreich und standardmäßig ausgeschaltet. *Insights Events* erkennen ungewöhnliche Aktivität, zum Beispiel einen plötzlichen Anstieg bestimmter Aufrufe. Ohne Einrichtung steht im *Event History* die Verwaltungsaktivität der letzten 90 Tage zur Ansicht und Suche kostenlos bereit. Wer länger aufbewahren, Data Events mitschreiben oder in anderen Diensten auswerten will, legt einen *Trail* an: Er liefert die Ereignisse als Dateien nach S3 und optional in CloudWatch Logs. Ein Trail kann für alle Regionen und für alle Konten einer Organisation gelten (*Organization Trail*). Zur Manipulationserkennung dient die *Log-Dateivalidierung*, und *CloudTrail Lake* ist ein Speicher mit SQL-Abfragen für Ereignisse.

Der Unterschied zu CloudWatch und Config lässt sich an einem Beispiel zeigen: Ein Server wird plötzlich langsam. CloudWatch zeigt die hohe CPU, CloudTrail zeigt, dass jemand vor zehn Minuten die Instanzgröße geändert hat, und AWS Config zeigt, wie die Konfiguration davor aussah. Alle drei ergänzen sich.

Das folgende Beispiel durchsucht den Event History nach dem Löschen einer Security Group und legt einen Trail an.

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=DeleteSecurityGroup \
  --max-results 5 \
  --query 'Events[].{Zeit:EventTime,Wer:Username,Aktion:EventName}'

aws cloudtrail create-trail --name konto-trail \
  --s3-bucket-name mein-trail-bucket-2026 \
  --is-multi-region-trail --enable-log-file-validation
aws cloudtrail start-logging --name konto-trail
aws cloudtrail put-event-selectors --trail-name konto-trail \
  --advanced-event-selectors '[{"Name":"S3Daten","FieldSelectors":[{"Field":"eventCategory","Equals":["Data"]},{"Field":"resources.type","Equals":["AWS::S3::Object"]},{"Field":"resources.ARN","StartsWith":["arn:aws:s3:::mein-lernbucket-2026-12345/"]}]}]'
```

Die erste Abfrage listet die letzten Löschungen von Security Groups mit Zeit, Benutzer und Aktion. Der Trail wird für alle Regionen angelegt, mit Dateivalidierung, und gestartet; der Ziel-Bucket braucht eine Bucket-Policy, die CloudTrail das Schreiben erlaubt. Die letzte Anweisung aktiviert Data Events nur für Objekte eines bestimmten Buckets, um Kosten und Datenmenge zu begrenzen.

### Typische Fehler.

Falsch: Sich auf die 90 Tage des Event History zu verlassen, wenn die Aufbewahrung länger sein muss. Falsch: Data Events für alle Buckets einzuschalten und von der Rechnung überrascht zu werden. Falsch: CloudTrail mit CloudWatch zu verwechseln: CloudTrail protokolliert Aktionen, nicht Leistung. Falsch: Den Trail-Bucket öffentlich oder unverschlüsselt zu lassen oder jedem Administrator Löschrechte zu geben.

### Praxisbezug.

Nach einem Sicherheitsvorfall rekonstruiert das Team anhand von CloudTrail, welche Zugangsdaten verwendet wurden, welche Ressourcen erzeugt wurden und welche Daten gelesen wurden.

> **Merke**
>
> CloudTrail = Wer hat was wann getan (API-Aufrufe). Event History 90 Tage, Trail für längere Aufbewahrung, Data Events optional. CloudWatch = Wie geht es dem System. Config = Wie war es konfiguriert.

## 7.5 AWS Config

*AWS Config* zeichnet die Konfiguration von Ressourcen auf und bewertet sie gegen Regeln. Während CloudTrail einzelne Aktionen festhält, bildet Config den *Zustand* ab: Wie war die Security Group gestern um 14 Uhr eingestellt, welche Regeln hatte sie, was hat sich seitdem geändert? Aus Änderungen entstehen *Configuration Items*, die den Verlauf jeder Ressource als Zeitleiste darstellen. Das hilft bei der Fehlersuche (“Seit wann ist der Port offen?”), bei Audits und bei der Kostenanalyse.

Der zweite Teil sind *Config Rules*: Regeln, die prüfen, ob Ressourcen den Vorgaben entsprechen. Es gibt *verwaltete Regeln* von AWS (zum Beispiel “S3-Buckets dürfen nicht öffentlich lesbar sein”, “EBS-Volumes müssen verschlüsselt sein”, “Root User hat MFA”) und *eigene Regeln* über Lambda-Funktionen. Jede Ressource wird als `COMPLIANT` oder `NON\_COMPLIANT` bewertet. Mit *Conformance Packs* lassen sich ganze Regelwerke (etwa zu bestimmten Standards) als Paket ausrollen, und *Aggregatoren* bündeln Ergebnisse mehrerer Konten und Regionen. Auf Abweichungen kann Config automatisch reagieren: *Remediation* startet über Systems-Manager-Automatisierungen eine Korrektur, etwa das Schließen eines Ports oder das Aktivieren der Verschlüsselung. Wichtig: Config erkennt und meldet, verhindert aber nichts, im Gegensatz zu einer SCP (Modul 08). Config ist regional, kostet nach Zahl der aufgezeichneten Änderungen und Regelauswertungen und muss zuerst eingeschaltet werden (Konfigurations-Recorder).

Das folgende Beispiel schaltet die Aufzeichnung ein, fragt die Historie einer Security Group ab und listet nicht konforme Ressourcen.

```bash
aws configservice put-configuration-recorder --configuration-recorder \
  name=default,roleARN=arn:aws:iam::123456789012:role/config-rolle \
  --recording-group allSupported=true,includeGlobalResourceTypes=true
aws configservice put-delivery-channel --delivery-channel \
  name=default,s3BucketName=mein-config-bucket-2026
aws configservice start-configuration-recorder --configuration-recorder-name default

aws configservice get-resource-config-history \
  --resource-type AWS::EC2::SecurityGroup --resource-id sg-0123456789abcdef0 \
  --limit 3 --query 'configurationItems[].{Zeit:configurationItemCaptureTime,Status:configurationItemStatus}'

aws configservice get-compliance-details-by-config-rule \
  --config-rule-name s3-bucket-public-read-prohibited \
  --compliance-types NON_COMPLIANT
```

Der Recorder zeichnet alle unterstützten Ressourcentypen auf und benötigt eine Rolle sowie einen S3-Bucket für die Lieferung; beide sind Platzhalter. `get-resource-config-history` zeigt die letzten Konfigurationsstände einer Security Group mit Zeitpunkt und Status. Die letzte Abfrage nennt alle Buckets, die gegen die Regel verstoßen; die Regel selbst muss vorher angelegt sein (siehe Modul 08).

### Typische Fehler.

Falsch: Config einzuschalten und die Ergebnisse nicht zu lesen. Falsch: Davon auszugehen, Config verhindere Verstöße. Falsch: Nur in einer Region aufzuzeichnen und Aktivitäten in anderen zu übersehen. Falsch: Alle Ressourcentypen aufzuzeichnen, wenn Kosten eine Rolle spielen, ohne zu prüfen, welche gebraucht werden.

### Praxisbezug.

Ein Auditor fragt, ob Datenbanken über das ganze Jahr verschlüsselt waren. Die Antwort kommt aus dem Konfigurationsverlauf und der Compliance-Zeitleiste von Config, nicht aus einer Momentaufnahme.

## 7.6 AWS Health und Trusted Advisor

Nicht jede Störung liegt an der eigenen Anwendung. *AWS Health* informiert über den Zustand der AWS-Dienste und über Ereignisse, die das eigene Konto betreffen. Es gibt zwei Sichten (Modul 02): die öffentliche Statusanzeige für alle Dienste und die persönliche Sicht (*Your account health*) mit Ereignissen zu den eigenen Ressourcen, etwa geplanten Wartungen, Ablaufdaten oder Ausfällen, die eigene Instanzen betreffen. Ereignisse lassen sich über EventBridge in Benachrichtigungen und Automatisierungen leiten. Die Health-API steht Konten mit den höheren Support-Plänen zur Verfügung.

*AWS Trusted Advisor* prüft das Konto automatisch gegen bewährte Verfahren und gibt Empfehlungen in mehreren Kategorien: Kostenoptimierung (ungenutzte Instanzen, Volumes, Elastic IPs), Sicherheit (offene Ports, fehlende MFA, öffentliche Snapshots), Fehlertoleranz (fehlende Backups, Multi-AZ), Leistung und Service-Limits (Quoten, die fast erreicht sind) sowie Betriebsexzellenz. Ein Tool für den Betrieb ist es, weil es Risiken sichtbar macht, bevor sie zu Störungen werden. Der Umfang hängt vom Support-Plan ab: Mit dem kostenlosen Basic-Plan (und Developer) steht nur ein Kernsatz an Prüfungen zur Verfügung, vor allem zu Sicherheit und Service-Limits; mit Business oder höher gibt es alle Prüfungen sowie programmgesteuerten Zugriff. Welche Pläne künftig gelten, behandelt Modul 11. Ergänzend gibt es *AWS Compute Optimizer* (Größenempfehlungen für Instanzen und andere Ressourcen) und *AWS Cost Anomaly Detection*.

Wichtig ist die Unterscheidung der drei Informationsquellen: Health sagt, ob *AWS* ein Problem hat oder eine Wartung ansteht, Trusted Advisor sagt, ob die *eigene Konfiguration* nicht den Empfehlungen entspricht, und Config sagt, wie sich die Konfiguration *verändert* hat.

Das folgende Beispiel fragt Health-Ereignisse ab und listet Trusted-Advisor-Empfehlungen. Beide APIs benötigen einen geeigneten Support-Plan.

```bash
aws health describe-events --region us-east-1 \
  --filter eventStatusCodes=open,upcoming \
  --query 'events[].{Dienst:service,Typ:eventTypeCode,Region:region}'

aws trustedadvisor list-recommendations --region us-east-1 \
  --status warning \
  --query 'recommendationSummaries[].{Titel:name,Kategorie:pillars}'
```

Die erste Abfrage nennt offene und geplante Ereignisse mit Dienst, Typ und Region. Die zweite listet Trusted-Advisor-Empfehlungen mit Status Warnung, jeweils mit Titel und Kategorie. Bei einem Basic-Plan antwortet die Health-API mit einem Fehler zur Berechtigung; dann bleibt die Console als Quelle.

### Typische Fehler.

Falsch: Bei einem Ausfall zuerst die eigene Anwendung zu debuggen, ohne in AWS Health nachzusehen. Falsch: Trusted-Advisor-Hinweise nie zu lesen. Falsch: Empfehlungen blind umzusetzen; sie sind Hinweise, keine Pflichten (eine “ungenutzte” Instanz kann bewusst Reserve sein).

### Praxisbezug.

Vor einer geplanten Instanzstilllegung meldet AWS Health die Wartung; das Team verschiebt rechtzeitig, statt überrascht zu werden. Monatlich geht jemand die Trusted-Advisor-Liste durch.

## 7.7 Incident-Grundlagen

Ein *Incident* (Störfall) ist ein ungeplantes Ereignis, das einen Dienst unterbricht oder verschlechtert. Technik allein genügt nicht, um damit umzugehen; man braucht klare Rollen, eine Priorisierung und eingeübte Abläufe. Je ruhiger und strukturierter reagiert wird, desto kürzer die Störung.

Der erste Baustein ist die *Priorisierung nach Schweregrad*. Eine übliche Skala: Stufe 1 (kritisch, Produktion ausgefallen oder Datenverlust, sofortige Reaktion rund um die Uhr), Stufe 2 (stark beeinträchtigt, schnelle Reaktion), Stufe 3 (geringfügig, in Arbeitszeit). Der Schweregrad bestimmt, wer informiert wird und wie schnell. Der zweite Baustein sind *Rollen*: eine Person leitet den Einsatz (Incident Commander), andere analysieren und beheben, jemand kommuniziert nach außen und nach innen. So bleibt die Kommunikation von der Fehlersuche getrennt. Der dritte Baustein sind *Kommunikationswege*: Wo trifft sich das Team (ein fester Chatkanal oder eine Telefonbrücke), wie werden Kunden und Management informiert, und wie oft gibt es Zwischenstände?

Zentral sind *Runbooks*: dokumentierte Schritte für bekannte Störungen (“Datenbank voll”, “Dienst antwortet nicht”), die jemand auch nachts um drei Uhr abarbeiten kann. Ein Runbook nennt die Prüfungen, die Befehle und die Eskalationsgrenzen. *Eskalation* bedeutet, rechtzeitig höhere Stufen oder Spezialisten einzubinden, wenn eine Störung nicht in einer festgelegten Zeit gelöst ist; auch AWS Support gehört dazu (Modul 11). Nach der Behebung folgt eine *Nachbetrachtung* (Post-Incident Review): Was war die Ursache, was hat die Erkennung verzögert, was ändern wir? Sie wird ohne Schuldzuweisung geführt, denn das Ziel ist, das System zu verbessern. AWS bietet mit *Systems Manager Incident Manager* ein Werkzeug für Alarme, Einsatzpläne, Eskalation und Dokumentation, und *Systems Manager Automation* führt Runbooks automatisch aus.

Das folgende Beispiel zeigt ein ausführbares Runbook als SSM-Automatisierungsdokument, das eine Instanz neu startet und auf Gesundheit wartet. Ein Alarm kann es automatisch anstoßen.

```bash
cat > runbook.yaml <<'EOT'
schemaVersion: '0.3'
description: Instanz neu starten und auf Status warten
parameters:
  InstanceId:
    type: String
mainSteps:
  - name: neustart
    action: aws:changeInstanceState
    inputs:
      InstanceIds: ['{{ InstanceId }}']
      DesiredState: running
      Force: false
  - name: warten
    action: aws:waitForAwsResourceProperty
    inputs:
      Service: ec2
      Api: DescribeInstanceStatus
      InstanceIds: ['{{ InstanceId }}']
      PropertySelector: '$.InstanceStatuses[0].InstanceStatus.Status'
      DesiredValues: ['ok']
EOT
aws ssm create-document --name Neustart-Instanz \
  --document-type Automation --document-format YAML \
  --content file://runbook.yaml
aws ssm start-automation-execution --document-name Neustart-Instanz \
  --parameters InstanceId=i-0123456789abcdef0
```

Das Dokument beschreibt zwei Schritte: Zuerst wird die Instanz gestartet, dann wartet der Ablauf, bis der Instanz-Statuscheck `ok` meldet. `create-document` speichert es unter dem Namen `Neustart-Instanz`, `start-automation-execution` führt es aus. Eine Ausführungsrolle mit den nötigen EC2-Rechten ist erforderlich; die Instanz-ID ist ein Platzhalter. Die Stärke liegt darin, dass die Handlung nachvollziehbar, wiederholbar und von mehreren Personen identisch ausführbar ist.

### Typische Fehler.

Falsch: Bei einer Störung alle gleichzeitig dieselbe Ursache suchen zu lassen, ohne Rollen und Kommunikation. Falsch: Runbooks nicht zu testen oder zu pflegen. Falsch: Erst nach Stunden zu eskalieren, um “es selbst zu lösen”. Falsch: Nachbetrachtungen mit Schuldzuweisung statt mit Verbesserungen zu verbinden.

### Praxisbezug.

Ein Team übt vierteljährlich eine simulierte Störung (“Game Day”): Der Alarm geht los, die Bereitschaft folgt dem Runbook, und die Lücken in Dokumentation und Berechtigungen zeigen sich vor dem Ernstfall.

## 7.8 Fehlerbilder im Betrieb

Viele Betriebsstörungen in AWS fallen in wenige wiederkehrende Gruppen. Wer sie kennt und für jede die passende Diagnosequelle weiß, löst die meisten Fälle schnell. Die Grundregel lautet: erst eingrenzen, dann ändern, und immer mit Metriken, Logs und Ereignissen belegen.

*AccessDenied* (Zugriff verweigert) ist das häufigste Fehlerbild und wurde in Modul 03 ausführlich behandelt: Identität prüfen, Fehlertext lesen, die Schichten Identitäts-Policy, Ressourcen-Policy, SCP, Boundary und Schlüsselrichtlinie durchgehen, CloudTrail befragen. Ein zweiter Klassiker ist das *Throttling* (Drosselung): AWS begrenzt die Rate der API-Aufrufe und lehnt zu schnelle Anfragen mit Meldungen wie `ThrottlingException` oder `RequestLimitExceeded` ab. Die Abhilfe liegt im Code: Wiederholung mit zunehmenden Wartezeiten (*Exponential Backoff* mit Zufallsanteil), weniger und gebündelte Aufrufe, Caching. Die SDKs und die CLI enthalten solche Wiederholungen bereits.

Ein dritter Fall sind *Quoten* (Service Quotas, früher Limits): Jedes Konto hat pro Region Obergrenzen, zum Beispiel für die Zahl der vCPUs oder Elastic IPs. Wird sie erreicht, schlagen Aufrufe mit Fehlern wie `LimitExceeded`, `VcpuLimitExceeded` oder `InstanceLimitExceeded` fehl. Man erkennt sie am Fehlertext und in der Console unter *Service Quotas*, wo sich Erhöhungen beantragen lassen; manche werden automatisch genehmigt, andere dauern. Frühwarnung bieten CloudWatch-Alarme auf Quotennutzung und Trusted Advisor. Viertens *Netzwerkpfade*: Zeitüberschreitungen weisen auf Routing, Security Groups, NACLs oder DNS hin (Modul 06); Hilfsmittel sind der Reachability Analyzer und die Flow Logs. Fünftens der *Kostenanstieg*: Eine unerwartet hohe Rechnung hat meist einen Verursacher wie vergessene Ressourcen, ein NAT Gateway mit viel Datenverkehr, eine Schleife in einer Lambda-Funktion, unbegrenzt wachsende Logs, Datenübertragung zwischen Regionen oder kompromittierte Zugangsdaten, die Rechenleistung für Kryptomining nutzen. Der *Cost Explorer* (nach Dienst, Region und Tag gruppieren) und die *Cost Anomaly Detection* grenzen die Ursache ein.

Für die erste Diagnose gilt ein einheitliches Vorgehen: Was hat sich geändert (CloudTrail, Config)? Was sagen die Metriken (CloudWatch) im Zeitraum des Problems? Was sagen die Logs? Gibt es Meldungen von AWS (Health)? Erst danach beginnt man mit Änderungen. Und man ändert immer nur eine Sache und beobachtet die Wirkung.

Das folgende Beispiel zeigt nützliche Befehle für diese Fehlerbilder: Quoten abfragen, Kosten nach Dienst auswerten und Fehlerdienste herausfinden.

```bash
aws service-quotas get-service-quota --service-code ec2 \
  --quota-code L-1216C47A \
  --query 'Quota.{Name:QuotaName,Wert:Value}'
aws service-quotas request-service-quota-increase --service-code ec2 \
  --quota-code L-1216C47A --desired-value 128

aws ce get-cost-and-usage \
  --time-period Start=2026-10-01,End=2026-10-24 \
  --granularity DAILY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[-1].Groups[].{Dienst:Keys[0],Kosten:Metrics.UnblendedCost.Amount}'

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --max-results 10 --query 'Events[].{Zeit:EventTime,Wer:Username}'
```

Die erste Abfrage liest die Quote für Standard-On-Demand-Instanzen (der Code `L-1216C47A` gilt dafür; Codes sind in der Dokumentation und in Service Quotas nachzuschlagen) und der zweite Befehl beantragt eine Erhöhung. Die Kostenabfrage zeigt die Tageskosten nach Dienst, was ein plötzliches Ausreißen sichtbar macht; die Zeitraumangaben sind Beispielwerte, der Cost Explorer muss im Konto aktiviert sein. Die letzte Anweisung zeigt, wer zuletzt Instanzen gestartet hat, und führt bei unerwartetem Verbrauch zum Verursacher.

> **Praxisbeispiel**
>
> Montagmorgen: Die Rechnung steigt über das Wochenende um das Fünffache. Der Cost Explorer zeigt EC2 in einer selten genutzten Region, CloudTrail zeigt `RunInstances`-Aufrufe in dieser Region mit den Zugangsdaten eines Entwicklers, und GuardDuty meldet Kryptomining. Die Ursache sind geleakte Zugriffsschlüssel. Maßnahmen: Schlüssel deaktivieren, Instanzen beenden, Zugangsdaten rotieren, Region per SCP sperren und Cost Anomaly Detection einrichten.

### Typische Fehler.

Falsch: Bei Throttling einfach die Last zu erhöhen oder Aufrufe sofort zu wiederholen. Falsch: Quotenerhöhungen erst im Notfall zu beantragen. Falsch: Mehrere Änderungen gleichzeitig vorzunehmen, sodass die Wirkung nicht erkennbar ist. Falsch: Die Kostenursache zu vermuten, statt sie im Cost Explorer zu belegen.

### Praxisbezug.

Ein Bereitschaftsplan führt zu jedem Fehlerbild eine Zeile: Symptom, erste Prüfung, Werkzeug, typische Abhilfe. So wird aus Erfahrung wiederholbares Wissen.

## Übungsaufgaben Modul 07

1.  Welche Frage beantworten CloudWatch, CloudTrail, AWS Config und AWS Health jeweils? Ordnen Sie zu: (a) Wer hat gestern die Security Group geändert? (b) Wie hoch war die CPU zwischen 14 und 15 Uhr? (c) Wie sah die Konfiguration vor der Änderung aus? (d) Ist ein AWS-Dienst in meiner Region gestört?

2.  Warum sieht man Arbeitsspeicher einer EC2-Instanz nicht in CloudWatch, und wie ändert man das?

3.  Erklären Sie die drei Alarmzustände und warum man mehrere Datenpunkte für einen Alarm verlangt.

4.  Was ist der Unterschied zwischen Management Events und Data Events in CloudTrail? Wie lange reicht der Event History?

5.  Nennen Sie fünf Bestandteile eines guten Incident-Prozesses.

6.  **Praxis:** Legen Sie per CLI ein SNS-Topic, eine E-Mail-Subscription und einen Alarm an, der bei mehr als 5 Fehlern in 5 Minuten auslöst (Metrik `Fehler`, Namespace `Shop`).

7.  **Praxis:** Schreiben Sie eine Logs-Insights-Abfrage, die die Zahl der `ERROR`-Zeilen pro 5 Minuten ausgibt, und erläutern Sie jede Klausel.

8.  **Praxis:** Die Rechnung hat sich über Nacht verdoppelt. Beschreiben Sie Ihre Untersuchung mit den passenden Diensten und Befehlen und nennen Sie vier mögliche Ursachen.

## Lösungen Modul 07

1.  \(a\) CloudTrail, (b) CloudWatch Metrics, (c) AWS Config, (d) AWS Health.

2.  Arbeitsspeicher und Dateisystembelegung liegen im Betriebssystem, das AWS nicht einsehen kann (Hypervisor sieht nur CPU, Netzwerk, Datenträger). Man installiert den CloudWatch Agent, der diese Werte als benutzerdefinierte Metriken veröffentlicht.

3.  `OK`: Wert im Normalbereich, `ALARM`: Schwelle verletzt, `INSUFFICIENT\_DATA`: nicht genug Daten. Mehrere Datenpunkte vermeiden Fehlalarme bei kurzen Spitzen, indem der Alarm nur auslöst, wenn die Verletzung anhält.

4.  Management Events sind Verwaltungsaktionen (Anlegen, Ändern, Löschen, Anmeldungen) und werden standardmäßig aufgezeichnet. Data Events sind Zugriffe auf Daten (S3-Objekte, Lambda-Aufrufe), zahlreich, standardmäßig aus und kostenpflichtig. Der Event History zeigt Verwaltungsereignisse der letzten 90 Tage.

5.  Zum Beispiel: Schweregrade, klare Rollen (Incident Commander, Analyse, Kommunikation), feste Kommunikationswege, Runbooks, Eskalationsregeln, Nachbetrachtung ohne Schuldzuweisung, Übungen.

6.  ```bash
    TOPIC=$(aws sns create-topic --name fehler-alarm --query TopicArn --output text)
    aws sns subscribe --topic-arn $TOPIC --protocol email \
      --notification-endpoint betrieb@beispiel.de
    aws cloudwatch put-metric-alarm --alarm-name shop-fehler \
      --namespace Shop --metric-name Fehler --statistic Sum \
      --period 300 --evaluation-periods 1 --threshold 5 \
      --comparison-operator GreaterThanThreshold \
      --treat-missing-data notBreaching --alarm-actions $TOPIC
    ```

    Die Summe über 300 Sekunden größer 5 löst aus; die E-Mail-Subscription muss bestätigt werden.

7.  ```text
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count(*) as fehler by bin(5m)
    | sort fehler desc
    ```

    `fields` wählt Felder, `filter` behält nur Zeilen mit ERROR, `stats count(*) ... by bin(5m)` zählt pro Fünf-Minuten-Fenster, `sort` ordnet absteigend.

8.  Vorgehen: Cost Explorer nach Dienst, dann Region, dann Tag gruppieren (`aws ce get-cost-and-usage` mit `--group-by`); Verursacher in CloudTrail suchen (`RunInstances`, `CreateNatGateway`); GuardDuty-Findings prüfen; Config-Verlauf ansehen; Kostenanomalien (Cost Anomaly Detection) prüfen. Ursachen: geleakte Zugangsdaten und Kryptomining; vergessene Ressourcen oder Testumgebungen; NAT Gateway mit hohem Datenvolumen; Lambda-Schleife; unbegrenzt wachsende Logs; Datenübertragung zwischen Regionen. Maßnahmen: Verursacher abschalten, Zugangsdaten rotieren, Budget-Alarm und Anomaly Detection einrichten.
