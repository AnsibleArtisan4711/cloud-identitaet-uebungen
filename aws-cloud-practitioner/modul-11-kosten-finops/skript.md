# Modul 11 - Kosten, Billing und FinOps

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 8 h

**Priorität:** 2

|  Nr. | Lerneinheit                          | Dauer (h) |
|-----:|:-------------------------------------|----------:|
| 11.1 | AWS Pricing-Grundlagen               |         1 |
| 11.2 | Billing Dashboard                    |         1 |
| 11.3 | Cost Explorer                        |         1 |
| 11.4 | Budgets und Alerts                   |         1 |
| 11.5 | Tags für FinOps                      |         1 |
| 11.6 | Savings Plans und Reserved Instances |         1 |
| 11.7 | AWS Support-Pläne                    |         1 |
| 11.8 | TCO und Business Case                |         1 |
|      | **Summe**                            |     **8** |

Die Cloud macht Ausgaben flexibel, aber auch schwerer vorhersehbar. Wo früher ein Einkauf einmalig geprüft wurde, entstehen heute jede Stunde Kosten durch Entscheidungen vieler Teams. Dieses Modul erklärt, wie AWS abrechnet, wie man Rechnungen liest, Kosten analysiert, begrenzt und zuordnet, und wie man mit Rabattmodellen und einem sauberen Business Case die Ausgaben steuert. Der Sammelbegriff dafür ist *FinOps* (Cloud Financial Management): die Zusammenarbeit von Technik, Finanzen und Geschäft mit dem Ziel, den Wert jedes ausgegebenen Euros zu maximieren. Ein Teil der Prüfungsfragen (Bereich Abrechnung, Preise, Support) stammt aus diesem Modul. Die Kaufoptionen für EC2 aus Modul 04 und die Kostensäule aus Modul 09 werden vorausgesetzt.

## 11.1 AWS Pricing-Grundlagen

Die Preisgestaltung von AWS folgt drei Grundprinzipien. Erstens *Pay-as-you-go*: Man bezahlt nur, was man nutzt, und nur so lange, wie man es nutzt, ohne Mindestlaufzeit und ohne Vorauszahlung (CapEx wird zu OpEx; Modul 01). Zweitens *Save when you reserve*: Wer sich für eine bestimmte Nutzung über ein oder drei Jahre verpflichtet, erhält deutliche Rabatte (Savings Plans und Reservierungen). Drittens *Pay less as you use more*: Viele Dienste haben gestaffelte Preise, bei denen jede weitere Einheit günstiger wird, etwa bei S3-Speicher oder Datenübertragung. Dazu kommt, dass AWS Preissenkungen aus Skaleneffekten regelmäßig weitergibt.

Die Kostenfaktoren lassen sich auf drei Grundbausteine zurückführen. *Compute*: Bei EC2 zählen Instanztyp, Betriebssystem, Region und Kaufoption und die Laufzeit (sekundengenau oder stundengenau); bei Lambda Anzahl und Dauer der Aufrufe. *Speicher*: Menge in Gigabyte pro Monat, Speicherklasse, Anzahl der Anfragen und Abrufe (Modul 05); bei EBS auch die bereitgestellte Größe, unabhängig davon, ob sie belegt ist. *Datenübertragung*: Daten *in* AWS hinein sind in der Regel kostenlos, Daten *aus* AWS ins Internet kosten (es gibt einen monatlichen Gratisanteil), Übertragung zwischen Regionen und teils zwischen Zonen ebenfalls. Weitere versteckte Posten sind NAT Gateways (Stunden und Daten), öffentliche IPv4-Adressen, Load Balancer, Logs und Support. Preise unterscheiden sich je Region deutlich.

Zum Einstieg gibt es den *Free Tier*. Er besteht aus drei Arten von Angeboten: dauerhaft kostenlose Kontingente bestimmter Dienste, zeitlich begrenzte Probeangebote und kostenlose Tests. Für neue Konten hat AWS das Programm im Juli 2025 neu gestaltet.

> **Ergänzung aus der Nachrecherche**
>
> Nach der AWS-Ankündigung vom 16. Juli 2025 erhalten neue Kunden bis zu 200 US-Dollar an Guthaben: 100 US-Dollar bei der Anmeldung und weitere bis zu 100 US-Dollar durch das Ausprobieren von Diensten wie Amazon EC2 und Amazon Bedrock. Neue Kunden wählen bei der Anmeldung einen *kostenlosen Plan*, der nach sechs Monaten oder bei aufgebrauchtem Guthaben endet, je nachdem, was zuerst eintritt; ein Wechsel auf den *kostenpflichtigen Plan* ist mit einem Klick möglich. Über 30 Dienste bleiben dauerhaft im Free Tier. Der Plan gilt in allen Regionen außer GovCloud (US) und China. Details zu Ausnahmen und zum Verhalten nach Ablauf stehen nicht in der abgerufenen Ankündigung und sind auf der Free-Tier-Seite zu prüfen; ältere Anleitungen (zwölf Monate kostenlos) können überholt sein.

Eine einfache Kostenrechnung zeigt das Zusammenspiel der Faktoren. Eine Instanz zu 0,05 US-Dollar pro Stunde, 730 Stunden pro Monat, ergibt rund 36,50 US-Dollar. Dazu ein 100-GiB-Volume zu 0,08 US-Dollar pro GiB und Monat (8 US-Dollar) und 200 GB Datenabfluss zu 0,09 US-Dollar pro GB nach einem Freikontingent. Die Zahlen sind Rechenbeispiele und keine aktuellen Preise; maßgeblich sind die Preisseiten. Vor dem Aufbau lässt sich mit dem *AWS Pricing Calculator* (calculator.aws) ein Schätzwert für ganze Architekturen bilden.

Das folgende Beispiel rechnet ein kleines Kostenmodell nach und fragt die Preisliste per Preis-API ab.

```bash
python3 - <<'EOT'
stunden = 730
instanz = 0.05 * stunden
volume  = 0.08 * 100
daten   = max(0, 200 - 100) * 0.09      # 100 GB Gratisanteil angenommen
summe   = instanz + volume + daten
print(f"Instanz {instanz:.2f}  Volume {volume:.2f}  Daten {daten:.2f}  Summe {summe:.2f} USD")
EOT

aws pricing get-products --service-code AmazonEC2 --region us-east-1 \
  --filters Type=TERM_MATCH,Field=instanceType,Value=t3.micro \
            Type=TERM_MATCH,Field=location,Value="EU (Frankfurt)" \
            Type=TERM_MATCH,Field=operatingSystem,Value=Linux \
            Type=TERM_MATCH,Field=tenancy,Value=Shared \
            Type=TERM_MATCH,Field=preInstalledSw,Value=NA \
            Type=TERM_MATCH,Field=capacitystatus,Value=Used \
  --max-results 1 --query 'PriceList[0]' --output text
```

Das Python-Beispiel summiert die drei Kostenblöcke; der Gratisanteil von 100 GB ist eine Annahme. Die Preis-API (`aws pricing`) liefert die offizielle Preisliste als JSON; sie ist nur in wenigen Regionen erreichbar (hier `us-east-1`), und die Filter müssen alle Eigenschaften eingrenzen, sonst gibt es mehrere Treffer. Die Auswertung der Preisstruktur ist umfangreich; in der Praxis nutzt man den Pricing Calculator.

### Typische Fehler.

Falsch: “Cloud ist immer billiger”; ohne Steuerung steigt die Rechnung. Falsch: Datenübertragung, NAT Gateways und Logs zu übersehen. Falsch: Sich auf alte Preisangaben aus Blogs zu verlassen. Falsch: Ungenutzte Ressourcen zu vergessen, die weiter berechnet werden: Volumes, Snapshots, Elastic IPs, Load Balancer.

### Praxisbezug.

Vor einem Projektstart erstellt das Team mit dem Pricing Calculator eine Schätzung, versieht sie mit Annahmen und vergleicht später die tatsächlichen Kosten. Abweichungen führen zu Verbesserungen der Architektur oder der Schätzung.

> **Merke**
>
> Drei Prinzipien: Pay-as-you-go, Save when you reserve, Pay less as you use more. Haupttreiber: Compute, Speicher, Datenabfluss. Daten hinein meist kostenlos, Daten hinaus kostenpflichtig. Preise unterscheiden sich je Region.

## 11.2 Billing Dashboard

Die *Billing and Cost Management*-Console ist die zentrale Anlaufstelle für alles zur Abrechnung. Das *Dashboard* zeigt auf einen Blick die Kosten des laufenden Monats, die Prognose für den Monatsabschluss, den Vergleich mit dem Vormonat und die Kosten der teuersten Dienste. Aus der Dashboard-Ansicht gelangt man zu den Detailseiten: *Bills* (die Rechnung des Monats nach Dienst und Region aufgeschlüsselt), *Payments* (Zahlungen und hinterlegte Zahlungsmethoden), *Credits* (Gutschriften, etwa aus dem Free Tier), *Cost Explorer*, *Budgets* und *Tags*.

Der Zugriff ist besonders geregelt. Ein neues Konto erlaubt nur dem Root User den Zugriff auf die Billing-Daten; damit auch IAM-Identitäten sie sehen können, muss der Root User den *IAM-Zugriff auf Billing* einmalig aktivieren (Modul 03) und dann über Richtlinien steuern, wer welche Daten sieht. Zu den Rechnungsdaten gehören Gebühren, Steuern (je nach Land) und Gutschriften. Bei Konten in einer Organisation (Modul 03) gilt die *konsolidierte Abrechnung*: Das Verwaltungskonto erhält eine Sammelrechnung für alle Mitgliedskonten und sieht die Kosten je Konto. Außerdem werden Mengenrabatte und Reservierungen über Konten hinweg verrechnet, sodass das Zusammenfassen die Preise senken kann. Mitgliedskonten sehen nur ihre eigenen Kosten.

Für die detaillierte Analyse gibt es den *Cost and Usage Report* (CUR), die ausführlichste Datenquelle: eine tabellarische Datei mit allen Kosten- und Nutzungszeilen pro Ressource und Stunde, die nach S3 geliefert und mit Athena (Modul 05) ausgewertet werden kann. Er wird heute auch über *Data Exports* bereitgestellt. Zur Früherkennung von Auffälligkeiten dient *Cost Anomaly Detection*, das mit Machine Learning ungewöhnliche Ausgaben erkennt und Benachrichtigungen versendet.

Das folgende Beispiel liest Kostendaten per CLI und richtet eine Anomalie-Überwachung ein.

```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-10-01,End=2026-10-24 \
  --granularity MONTHLY --metrics UnblendedCost \
  --query 'ResultsByTime[].Total.UnblendedCost.{Betrag:Amount,Einheit:Unit}'

aws ce get-cost-forecast \
  --time-period Start=2026-10-24,End=2026-11-01 \
  --metric UNBLENDED_COST --granularity MONTHLY \
  --query 'Total.Amount'

aws ce create-anomaly-monitor --anomaly-monitor \
  'MonitorName=dienste,MonitorType=DIMENSIONAL,MonitorDimension=SERVICE'
```

Die erste Abfrage liefert die bisherigen Kosten des Monats in US-Dollar (Cost Explorer rechnet in der Rechnungswährung; bei `UnblendedCost` sind die Preise ohne Mischung über Konten dargestellt). Die zweite schätzt die Kosten bis Monatsende. Der Zeitraum muss in der Zukunft liegen, `End` ist ausgeschlossen. Der letzte Befehl legt eine Überwachung pro Dienst an; für Benachrichtigungen kommt noch ein Abonnement hinzu (`create-anomaly-subscription`). Die Datumswerte sind Beispiele; Cost Explorer muss im Konto aktiviert sein.

### Typische Fehler.

Falsch: Zu glauben, jeder Administrator sehe die Rechnung; ohne aktivierten IAM-Zugriff sieht er sie nicht. Falsch: Die Billing-Seite nur am Monatsende anzusehen. Falsch: Kostendaten in Dollar mit Rechnungsbeträgen in Euro oder Steuer zu verwechseln. Falsch: Die Kontaktdaten und Rechnungsadresse nicht zu pflegen.

### Praxisbezug.

Die Finanzabteilung bekommt monatlich eine Sammelrechnung des Verwaltungskontos, die Teams sehen ihre eigenen Kosten, und eine Anomalie-Meldung vermeidet böse Überraschungen.

## 11.3 Cost Explorer

Der *AWS Cost Explorer* ist das Werkzeug, mit dem man Kosten und Nutzung grafisch analysiert. Man kann Kosten nach Zeitraum (täglich, monatlich), *Dimension* (Dienst, Konto, Region, Instanztyp, Nutzungstyp) und *Tag* gruppieren, filtern und vergleichen. Dadurch beantwortet man Fragen wie “Welcher Dienst ist der größte Kostentreiber?”, “Was hat sich seit dem Vormonat verändert?” oder “Welches Team verursacht den Anstieg?”. Die Oberfläche ist kostenlos; Zugriffe über die API kosten pro Anfrage einen kleinen Betrag. Der Dienst muss einmalig aktiviert werden, danach dauert es bis zu einem Tag, bis Daten erscheinen, und die Daten reichen mehrere Monate zurück.

Zur Analyse gehört die Wahl der richtigen Sicht. Die *Nutzungstyp*-Gruppierung zeigt, *wofür* bezahlt wird (zum Beispiel Datenübertragung, Instanzstunden, Speicher), die *Dienst*-Gruppierung *wo*, und die *Tag*-Gruppierung *wer*. Eine häufige Untersuchung geht in drei Schritten vor: erst nach Dienst gruppieren, um den Verursacher zu finden, dann nach Nutzungstyp, um die Art zu verstehen, dann nach Region, Konto oder Tag, um den Ursprung zu bestimmen. Eine *Prognose* schätzt die Kosten der nächsten Monate aus den bisherigen Daten. Weitere Auswertungen zeigen die *Auslastung* und *Abdeckung* von Reservierungen und Savings Plans und liefern *Rightsizing-Empfehlungen* für zu große Instanzen.

Mit einem Bericht lassen sich Auswertungen speichern und wiederverwenden. Die Datenmenge in Cost Explorer ist aggregiert; für Detailanalysen einzelner Ressourcen nutzt man den Cost and Usage Report. Ergänzend gibt es *Cost Categories*, mit denen man Kosten in eigene, geschäftsnahe Gruppen (zum Beispiel Produkte oder Teams) einteilt.

Das folgende Beispiel gruppiert die Kosten nach Dienst, dann nach Tag und listet Rightsizing-Empfehlungen.

```bash
aws ce get-cost-and-usage \
  --time-period Start=2026-09-01,End=2026-10-01 \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups[?Metrics.UnblendedCost.Amount>`1`].{Dienst:Keys[0],Kosten:Metrics.UnblendedCost.Amount}' \
  --output table

aws ce get-cost-and-usage \
  --time-period Start=2026-09-01,End=2026-10-01 \
  --granularity MONTHLY --metrics UnblendedCost \
  --group-by Type=TAG,Key=Kostenstelle \
  --query 'ResultsByTime[0].Groups[].{Tag:Keys[0],Kosten:Metrics.UnblendedCost.Amount}'

aws ce get-rightsizing-recommendation --service AmazonEC2 \
  --query 'RightsizingRecommendations[].{Id:CurrentInstance.ResourceId,Aktion:RightsizingType}'
```

Die erste Abfrage gruppiert den September nach Dienst und zeigt nur Dienste mit mehr als einem Dollar. Die zweite gruppiert nach dem Tag `Kostenstelle`; der Schlüssel muss zuvor als Kostenverteilungs-Tag aktiviert sein (nächste Einheit), sonst bleibt die Auswertung leer oder unter “ohne Tag”. Die dritte listet Empfehlungen, ob Instanzen verkleinert oder beendet werden können. Zeiträume sind Beispiele.

### Typische Fehler.

Falsch: Nur die Gesamtsumme anzusehen und nicht nach Dienst, Nutzungstyp und Tag zu zerlegen. Falsch: Auf Tag-Auswertungen zu vertrauen, ohne die Tags aktiviert und konsequent gesetzt zu haben. Falsch: Frische Kosten für endgültig zu halten; Daten werden bis zu einem Tag verzögert aktualisiert und Monatsabschlüsse können sich ändern. Falsch: Rightsizing-Empfehlungen ungeprüft umzusetzen.

### Praxisbezug.

Beim monatlichen Kostenreview öffnet das Team Cost Explorer, gruppiert nach Dienst und Tag und fragt für jeden Anstieg: erwartet, erklärbar oder Fehler? So bleibt die Kostenentwicklung verstanden.

## 11.4 Budgets und Alerts

*AWS Budgets* legt Grenzen fest und warnt, wenn Kosten oder Nutzung sie zu überschreiten drohen. Während Cost Explorer rückblickend analysiert, schaut ein Budget voraus und löst Benachrichtigungen aus. Es gibt mehrere Budget-Typen: *Kostenbudgets* (Betrag pro Monat, Quartal oder Jahr), *Nutzungsbudgets* (zum Beispiel Instanzstunden oder Speicher), *Reservierungsbudgets* (Auslastung und Abdeckung von RIs) und *Savings-Plans-Budgets*. Ein Budget kann das ganze Konto oder nur einen Teil betreffen, etwa gefiltert nach Dienst, Tag oder Konto.

Zu jedem Budget gehören *Alarmschwellen*: zum Beispiel eine Warnung bei 80 Prozent der tatsächlichen Kosten, bei 100 Prozent und bei 100 Prozent der *prognostizierten* Kosten. Die Prognose ist wichtig, weil sie warnt, bevor die Grenze erreicht ist. Benachrichtigungen gehen per E-Mail oder über ein SNS-Topic (und von dort an Chat oder Lambda). *Budget Actions* gehen weiter: Bei Überschreiten kann AWS automatisch eine Maßnahme ausführen, etwa eine einschränkende IAM- oder SCP-Richtlinie anhängen oder bestimmte EC2- und RDS-Instanzen stoppen, optional mit Freigabe. Das Überwachen von Budgets und die Benachrichtigungen sind kostenlos; für aktionsfähige Budgets gelten Kontingente und danach tagesbezogene Gebühren, und für zugestellte Berichte fällt eine kleine Gebühr an.

Eine wichtige Einschränkung: Ein Budget *begrenzt* nicht von allein; es warnt und kann Aktionen auslösen, aber ohne Aktion läuft die Nutzung weiter. Zudem sind die Daten leicht verzögert. Für ein hartes Limit braucht man zusätzliche Mechanismen (Aktionen, Quoten, SCPs). Alarme für Kosten in CloudWatch (Modul 07) sind eine Ergänzung, nicht der Ersatz.

Das folgende Beispiel legt ein monatliches Budget von 100 US-Dollar mit zwei Warnungen an.

```bash
cat > budget.json <<'EOT'
{
  "BudgetName": "monatlich-100",
  "BudgetLimit": {"Amount": "100", "Unit": "USD"},
  "TimeUnit": "MONTHLY",
  "BudgetType": "COST"
}
EOT
cat > benachrichtigung.json <<'EOT'
[
  {
    "Notification": {"NotificationType": "ACTUAL",
      "ComparisonOperator": "GREATER_THAN", "Threshold": 80,
      "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "finanzen@beispiel.de"}]
  },
  {
    "Notification": {"NotificationType": "FORECASTED",
      "ComparisonOperator": "GREATER_THAN", "Threshold": 100,
      "ThresholdType": "PERCENTAGE"},
    "Subscribers": [{"SubscriptionType": "EMAIL", "Address": "finanzen@beispiel.de"}]
  }
]
EOT
aws budgets create-budget --account-id 123456789012 \
  --budget file://budget.json \
  --notifications-with-subscribers file://benachrichtigung.json
aws budgets describe-budgets --account-id 123456789012 \
  --query 'Budgets[].{Name:BudgetName,Limit:BudgetLimit.Amount,Ist:CalculatedSpend.ActualSpend.Amount}'
```

Das Budget begrenzt auf 100 US-Dollar pro Monat. Die erste Benachrichtigung geht per E-Mail raus, sobald die *tatsächlichen* Kosten 80 Prozent überschreiten, die zweite, sobald die *prognostizierten* Kosten 100 Prozent überschreiten und damit eine Überschreitung droht. Die Kontonummer ist ein Platzhalter, und die Budgets-API wird über die Region `us-east-1` bereitgestellt, was die CLI automatisch handhabt. `describe-budgets` zeigt Limit und aktuellen Stand.

### Typische Fehler.

Falsch: Nur auf 100 Prozent der tatsächlichen Kosten zu warnen; dann ist es zu spät. Richtig: Mehrere Schwellen und die Prognose nutzen. Falsch: E-Mail-Empfänger, die niemand liest. Falsch: Zu glauben, ein Budget stoppe Ausgaben automatisch. Falsch: Nur ein Gesamtbudget zu haben und keines für einzelne Teams oder Projekte.

### Praxisbezug.

Jedes Projektteam hat ein Budget mit Alarm an seinen Chatkanal; die Entwicklungsumgebung hat zusätzlich eine Aktion, die bei Überschreitung neue Instanzstarts verbietet.

## 11.5 Tags für FinOps

Ohne Zuordnung bleibt eine Rechnung eine Summe. Mit *Tags* (Schlüssel-Wert-Paare an Ressourcen) lassen sich Kosten Teams, Projekten, Umgebungen und Kostenstellen zuordnen. Das ist die Grundlage für *Showback* (Kosten sichtbar machen) und *Chargeback* (intern weiterverrechnen), und es schafft Verantwortung: Wer seine Kosten sieht, geht sorgsamer damit um.

Man unterscheidet vom Benutzer definierte Tags (zum Beispiel `Projekt`, `Owner`, `Umgebung`, `Kostenstelle`) und von AWS erzeugte Tags (zum Beispiel `aws:createdBy`). Ein wichtiger Punkt: Ein Tag wirkt in der Abrechnung erst, wenn es als *Kostenverteilungs-Tag* (Cost Allocation Tag) in der Billing-Console *aktiviert* wird, und es erscheint dann nur für künftige Kosten und mit etwas Verzögerung (bis zu einem Tag). Ältere Kosten lassen sich nachträglich nicht neu zuordnen, auch wenn man das Tag später setzt (Backfill ist nur eingeschränkt möglich). Nicht alle Ressourcen und Kosten (zum Beispiel manche Datenübertragungen) sind taggbar; für solche Fälle bieten *Cost Categories* und Kontostrukturen eine Ergänzung.

Ein *Tagging-Standard* legt fest, welche Schlüssel Pflicht sind, welche Werte erlaubt sind, wie Schreibweisen aussehen (Groß-/Kleinschreibung zählt!) und wer verantwortlich ist. Er wird durch Technik erzwungen: Tag Policies in Organizations (Modul 08), Richtlinien, die das Anlegen ohne Pflicht-Tag verbieten (Modul 10), AWS-Config-Regeln wie `required-tags` und IaC-Vorlagen, die Tags automatisch setzen. Die Kombination aus Struktur (mehrere Konten, Modul 03) und Tags liefert die genaueste Zuordnung.

Das folgende Beispiel setzt Tags, aktiviert sie für die Abrechnung und prüft mit AWS Config, ob Pflicht-Tags fehlen.

```bash
aws ec2 create-tags --resources i-0123456789abcdef0 vol-0123456789abcdef0 \
  --tags Key=Kostenstelle,Value=4711 Key=Owner,Value=team-shop Key=Umgebung,Value=prod

aws ce update-cost-allocation-tags-status --cost-allocation-tags-status \
  TagKey=Kostenstelle,Status=Active TagKey=Umgebung,Status=Active
aws ce list-cost-allocation-tags --status Active \
  --query 'CostAllocationTags[].TagKey'

aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "pflicht-tags",
  "Source": {"Owner": "AWS", "SourceIdentifier": "REQUIRED_TAGS"},
  "InputParameters": "{\"tag1Key\":\"Kostenstelle\",\"tag2Key\":\"Owner\",\"tag3Key\":\"Umgebung\"}"
}'
aws resourcegroupstaggingapi get-resources --tag-filters Key=Umgebung,Values=prod \
  --query 'ResourceTagMappingList[].ResourceARN'
```

Die ersten Zeilen taggen eine Instanz und ihr Volume (beide tragen eigene Tags, denn Tags vererben sich nicht). Der zweite Block aktiviert zwei Tag-Schlüssel für die Abrechnung und listet danach die aktiven. Die Config-Regel prüft für unterstützte Ressourcen, ob die drei Pflicht-Tags vorhanden sind. Zuletzt zeigt die Tagging-API alle Ressourcen mit dem Tag `Umgebung=prod`. IDs sind Platzhalter.

### Typische Fehler.

Falsch: Tags anzulegen, aber nie für die Abrechnung zu aktivieren. Falsch: Uneinheitliche Schreibweisen wie `Owner`, `owner`, `OWNER`; sie zählen als verschiedene Schlüssel. Falsch: Auf freiwilliges Taggen zu hoffen. Falsch: Sensible Informationen in Tags zu speichern; Tags sind in vielen Auswertungen sichtbar.

### Praxisbezug.

Nach der Einführung von Pflicht-Tags und Aktivierung kann das Team im Cost Explorer “Kosten je Kostenstelle” zeigen. Der Anteil nicht zuordenbarer Kosten sinkt von 40 auf unter 5 Prozent, und Gespräche über Verantwortung beruhen auf Daten.

## 11.6 Savings Plans und Reserved Instances

Für stabile, vorhersehbare Last bietet AWS Rabatte gegen eine Verpflichtung. Die Grundidee wurde in Modul 04 vorgestellt; hier folgt die Vertiefung aus Kostensicht.

*Savings Plans* verpflichten zu einem festen Betrag pro Stunde (zum Beispiel 10 US-Dollar Rechenleistung) für ein oder drei Jahre. Alles, was darunter liegt, wird zum reduzierten Preis abgerechnet; darüber hinausgehende Nutzung kostet den normalen Preis (On-Demand). *Compute Savings Plans* sind am flexibelsten: Sie gelten unabhängig von Instanzfamilie, Größe, Region, Betriebssystem und auch für Fargate und Lambda, mit etwas geringerem Rabatt. *EC2 Instance Savings Plans* binden an eine Instanzfamilie in einer Region und bieten dafür einen höheren Rabatt. Daneben gibt es Savings Plans für Machine Learning und für Datenbanken. *Reserved Instances* (RI) reservieren dagegen eine bestimmte Konfiguration (Typ, Region, Betriebssystem); sie gibt es als *Standard* (höchster Rabatt, kaum änderbar, handelbar im RI-Marktplatz) und als *Convertible* (tauschbar gegen andere Konfigurationen, geringerer Rabatt). RIs existieren auch für RDS, ElastiCache und andere Dienste. Die Rabatte reichen laut AWS bis zu etwa zwei Dritteln und mehr gegenüber On-Demand, abhängig von Dienst, Laufzeit und Zahlung; aktuelle Werte stehen auf der Preisseite.

Die Zahlungsoptionen sind *Alle Vorauszahlung* (höchster Rabatt), *Teilweise Vorauszahlung* und *Keine Vorauszahlung* (monatliche Raten, geringster Rabatt). Die wichtigste Frage ist die der Größe: Eine zu hohe Verpflichtung (*Overcommit*) führt dazu, dass man für ungenutzte Rate bezahlt; eine zu niedrige lässt Einsparungen liegen. Man misst deshalb zwei Kennzahlen: *Auslastung* (Utilization: Wie viel der Verpflichtung wird genutzt? Ziel nahe 100 Prozent) und *Abdeckung* (Coverage: Wie viel der Last ist durch Rabatte gedeckt?). Faustregeln: Mit dem sicheren Sockel der Grundlast beginnen, schrittweise ausbauen, Laufzeit nicht über die absehbare Lebensdauer der Anwendung hinaus wählen, und Flexibilität höher gewichten, wenn sich die Architektur noch ändert. Spot (unterbrechbar) und Savings Plans ergänzen sich.

Das folgende Beispiel fragt eine Kaufempfehlung und die Auslastung vorhandener Savings Plans ab.

```bash
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT --lookback-period-in-days THIRTY_DAYS \
  --query 'SavingsPlansPurchaseRecommendation.SavingsPlansPurchaseRecommendationSummary.{Stunde:HourlyCommitmentToPurchase,Ersparnis:EstimatedMonthlySavingsAmount,Prozent:EstimatedSavingsPercentage}'

aws ce get-savings-plans-utilization \
  --time-period Start=2026-09-01,End=2026-10-01 \
  --query 'Total.Utilization.{Auslastung:UtilizationPercentage}'

aws savingsplans describe-savings-plans \
  --query 'savingsPlans[].{Id:savingsPlanId,Typ:savingsPlanType,Stunde:commitment,Ende:end}'
```

Die erste Abfrage nutzt die Nutzung der letzten 30 Tage, um für einen einjährigen Compute Savings Plan ohne Vorauszahlung eine stündliche Verpflichtung und die geschätzte Ersparnis zu errechnen. Sie ist eine Empfehlung, keine Garantie. Die zweite zeigt, wie viel der gekauften Verpflichtung im September tatsächlich genutzt wurde; deutlich unter 100 Prozent weist auf Overcommit hin. Die dritte listet vorhandene Pläne mit Typ, Betrag pro Stunde und Ablaufdatum.

### Typische Fehler.

Falsch: Verpflichtungen aufgrund von Spitzenlast statt Grundlast zu kaufen. Falsch: Dreijahresverträge für Anwendungen mit unklarer Zukunft. Falsch: Die Ablaufdaten nicht zu überwachen, sodass Last plötzlich zum vollen Preis läuft. Falsch: Rabattarten zu verwechseln: Ein Savings Plan ist ein Stundenbetrag, eine Reserved Instance eine bestimmte Konfiguration.

### Praxisbezug.

Ein Team deckt 70 Prozent der Dauerlast mit einem Compute Savings Plan, den Rest mit On-Demand und nächtliche Berechnungen mit Spot. Quartalsweise prüft es Auslastung und Abdeckung und passt an.

## 11.7 AWS Support-Pläne

AWS bietet abgestufte Support-Pläne, die sich in Reaktionszeiten, Kanälen und zusätzlichen Leistungen unterscheiden. Die Wahl richtet sich nach der Bedeutung der Anwendungen für das Geschäft.

In der klassischen Struktur, die in vielen Unterlagen und in der Prüfungsvorbereitung vorkommt, gibt es fünf Pläne. *Basic* ist kostenlos und für alle Konten enthalten: Zugang zu Dokumentation, Whitepapers und Foren, Service Health Dashboard und AWS Health sowie ein Kernsatz an Trusted-Advisor-Prüfungen; technischer Support ist nicht enthalten, nur Hilfe bei Konto- und Abrechnungsfragen. *Developer* ist ein günstiger Einstieg für Tests und Entwicklung: Zugang zu Cloud-Support-Mitarbeitern per E-Mail zu Geschäftszeiten, Antworten innerhalb eines Werktags bei allgemeinen Fragen, bei beeinträchtigten Systemen in kürzerer Zeit. *Business* ist für Produktivsysteme gedacht: rund um die Uhr Zugang per Telefon, Chat und E-Mail, kürzere Reaktionszeiten (bei ausgefallenen Produktionssystemen im Bereich einer Stunde), alle Trusted-Advisor-Prüfungen, die Health-API und Unterstützung bei Drittanbieter-Software. *Enterprise On-Ramp* ergänzt dies um einen Pool von Technical Account Managern und schnellere Reaktion bei geschäftskritischen Ausfällen. *Enterprise* bietet einen dedizierten *Technical Account Manager* (TAM), die schnellsten Reaktionszeiten für geschäftskritische Ausfälle (im Bereich von 15 Minuten), Architekturberatung und Betriebsprüfungen. Die genauen Zeiten und Preise sind in der aktuellen Beschreibung zu prüfen.

> **Ergänzung aus der Nachrecherche**
>
> Nach einer Drittquelle (CloudKeeper-Blog, nicht von AWS; Datum der Ausgabe 16. Juli 2026) strukturiert AWS die Support-Pläne neu: *Basic* bleibt kostenlos, *Business Support+* soll als neuer bezahlter Standardplan die Pläne Developer und Business ersetzen, *Enterprise Support* bleibt für kritische Workloads, und mit *Unified Operations* entsteht eine neue Spitzenstufe mit proaktiver Betreuung. Developer, Business und Enterprise On-Ramp sollen schrittweise bis 2027 auslaufen. Genannt werden Reaktionszeiten von 30, 15 und 5 Minuten bei kritischen Fällen sowie Preise von einem Mindestbetrag pro Monat oder einem Anteil der AWS-Ausgaben (der höhere Wert gilt). Diese Angaben wurden nicht an einer AWS-Originalquelle geprüft. Die Bezeichnungen und Bedingungen sind vor einer Entscheidung auf der AWS-Support-Seite zu verifizieren; für die Prüfung ist zu klären, welche Fassung die jeweilige Prüfungsversion zugrunde legt.

Bei der Auswahl hilft eine einfache Überlegung: Hängt Umsatz oder Sicherheit an der Anwendung, ist 24/7-Zugang zu Ingenieuren mit kurzer Reaktionszeit sinnvoll; für Lernkonten und Experimente genügt Basic oder Developer. Die Kosten sind meist ein Mindestbetrag oder ein Anteil der monatlichen AWS-Ausgaben (der höhere Wert), sodass sie mit der Nutzung steigen. Wichtig sind auch Nebenleistungen: Business und höher schalten alle Trusted-Advisor-Prüfungen und die Health-API frei (Modul 07). Neben dem Plan gibt es AWS Partner Support (über Partner), *AWS re:Post* (Community) und *Managed Services* für ausgelagerten Betrieb.

Der Support wird über *Support-Fälle* abgewickelt, die man mit Schweregrad eröffnet. Eine gute Anfrage enthält Konto, Region, betroffene Ressourcen, Zeitpunkt, Fehlermeldungen, Schritte zur Reproduktion und bereits Geprüftes. Das folgende Beispiel zeigt, wie man einen Fall per CLI eröffnet und verfolgt (die Support-API erfordert einen passenden Plan und ist in `us-east-1` erreichbar).

```bash
aws support describe-severity-levels --region us-east-1 \
  --query 'severityLevels[].{Stufe:code,Name:name}'

aws support create-case --region us-east-1 \
  --subject "RDS Multi-AZ Failover dauert laenger als erwartet" \
  --service-code amazon-relational-database-service \
  --category-code general-guidance --severity-code high \
  --communication-body "Region eu-central-1, Instanz shop-db, Failover um 14:05 UTC, Dauer 9 Minuten. Metriken und Ereignisse angehaengt." \
  --language de

aws support describe-cases --region us-east-1 \
  --query 'cases[].{Id:displayId,Status:status,Betreff:subject}'
```

Die erste Abfrage zeigt, welche Schweregrade der Plan erlaubt (nicht jeder Plan erlaubt alle Stufen). Der zweite Befehl eröffnet einen Fall mit Betreff, betroffenem Dienst, Kategorie und Schweregrad; der Text enthält die wichtigsten Fakten. Die Kategorien und Dienstcodes erhält man über `describe-services`. Die dritte Abfrage listet offene Fälle. Bei Konten mit Basic-Plan antwortet die API mit einer Fehlermeldung zur Berechtigung.

### Typische Fehler.

Falsch: Produktive Kernsysteme ohne passenden Plan zu betreiben und im Ernstfall nur Foren zu haben. Falsch: Den höchsten Plan “für alle Fälle” für alle Konten zu buchen, auch für Tests; der Plan gilt je Konto, und die Kosten können hoch sein. Falsch: Fälle ohne Details zu eröffnen. Falsch: Den Schweregrad zu übertreiben; echte kritische Fälle verlieren an Glaubwürdigkeit.

### Praxisbezug.

Ein Unternehmen bucht den Business-Plan nur für die Produktionskonten und Basic für Entwicklungskonten; bei einem Datenbankproblem ist innerhalb kurzer Zeit ein Ingenieur am Fall.

## 11.8 TCO und Business Case

Wer eine Cloud-Migration begründen muss, vergleicht Kosten. Der Begriff *Total Cost of Ownership* (TCO, Gesamtkosten des Besitzes) bezeichnet die vollständigen Kosten einer Lösung über ihre Lebensdauer. Der Fehler vieler Vergleiche ist, nur den sichtbaren Teil zu betrachten, etwa Serverpreis gegen Instanzpreis. Ein ehrlicher Vergleich bezieht alle Kostenarten ein.

Im lokalen Rechenzentrum gehören dazu: Hardware (Server, Speicher, Netzwerk, Ersatzteile, Abschreibung), Software und Lizenzen, Räume und Infrastruktur (Fläche, Strom, Kühlung, Brandschutz, Zutritt), Personal (Betrieb, Wartung, Rufbereitschaft), Netzwerkanbindung, Sicherheit, Notfallvorsorge und Ausfallrisiken, dazu die Kapazität, die man für Spitzen vorhält, aber selten nutzt. In der Cloud entstehen Kosten für Rechenleistung, Speicher, Datenübertragung, Support, Lizenzen (teils im Preis enthalten), Migration, Schulung, Parallelbetrieb während des Umzugs und den neuen Betrieb (Kostensteuerung, Sicherheit). Zu berücksichtigen sind auch schwer messbare Vorteile: schnellere Bereitstellung, geringere Ausfallrisiken, Agilität, Konzentration auf das Kerngeschäft. Ein Business Case setzt Kosten und Nutzen in Beziehung und zeigt, ab wann sich der Wechsel lohnt.

AWS bietet Werkzeuge für die Schätzung. Der frühere *TCO Calculator* wird in der aktuellen AWS-Dokumentation nicht mehr als eigenes Werkzeug beschrieben; stattdessen verweist AWS auf den *AWS Pricing Calculator* (calculator.aws), mit dem sich Kosten für geplante Architekturen schätzen und für die Gesamtkostenbetrachtung heranziehen lassen. *AWS Migration Evaluator* (früher TSO Logic) ist ein kostenloser Dienst, der die vorhandene Umgebung inventarisiert, Auslastung und Kosten analysiert und mit mehreren künftigen AWS-Konfigurationen vergleicht, einschließlich der Wiederverwendung vorhandener Softwarelizenzen. Das Ergebnis ist eine datenbasierte Grundlage für einen Business Case.

Die folgende Rechnung zeigt das Prinzip eines TCO-Vergleichs über fünf Jahre mit einfachen, frei gewählten Zahlen.

```bash
python3 - <<'EOT'
jahre = 5
# Lokal (Beispielwerte in EUR)
hardware      = 120000           # einmalig, ueber 5 Jahre abgeschrieben
software      = 8000 * jahre     # Lizenzen/Wartung pro Jahr
raeume_strom  = 9000 * jahre
personal      = 0.5 * 70000 * jahre   # 0,5 Stelle fuer Betrieb
lokal = hardware + software + raeume_strom + personal

# Cloud (Beispielwerte in EUR)
laufend    = 3200 * 12 * jahre   # Rechnung pro Monat
support    = 400 * 12 * jahre
migration  = 25000               # einmalig inkl. Schulung, Parallelbetrieb
personal_c = 0.25 * 70000 * jahre
cloud = laufend + support + migration + personal_c

print(f"Lokal: {lokal:,.0f} EUR   Cloud: {cloud:,.0f} EUR   Differenz: {lokal-cloud:,.0f} EUR")
EOT
```

Die Rechnung stellt über fünf Jahre Hardware-Einmalkosten, laufende Lizenz-, Raum- und Personalkosten den Cloud-Posten gegenüber: monatliche Rechnung, Support, einmalige Migrationskosten und geringeren Betriebsaufwand (0,25 statt 0,5 Stellen). Die Werte sind *erfundene Beispielzahlen*; in einem echten Vergleich ersetzt man sie durch gemessene Daten (Auslastung, Preise aus dem Pricing Calculator, Angebote). Entscheidend ist die Struktur: alle Kostenarten, ein fester Zeitraum und nachvollziehbare Annahmen. Zusätzlich sollte man *Sensitivitäten* prüfen: Was passiert, wenn die Last um 30 Prozent steigt oder die Migration länger dauert?

### Typische Fehler.

Falsch: Nur Hardware gegen Instanzpreis zu vergleichen und Personal, Strom und Ausfallrisiko zu vergessen. Falsch: Die Cloud nur mit Vollauslastung zu rechnen, aber die lokale Umgebung mit teurer Reserve; oder umgekehrt. Falsch: Einmalkosten der Migration, Schulung und Parallelbetrieb wegzulassen. Falsch: Die Annahmen nicht zu dokumentieren. Falsch: Den Business Case nach der Entscheidung nie wieder zu prüfen.

### Praxisbezug.

Ein Mittelständler lässt von Migration Evaluator seine 200 Server analysieren. Das Ergebnis zeigt, dass viele Server kaum ausgelastet sind und sich mit kleineren Instanzen und Savings Plans deutlich einsparen lässt, was die Entscheidung der Geschäftsführung stützt.

## Übungsaufgaben Modul 11

1.  Nennen Sie die drei Preisprinzipien von AWS und die drei Haupt-Kostentreiber.

2.  Warum sieht ein IAM-Administrator die Rechnung nicht, und was muss geschehen?

3.  Worin unterscheiden sich Cost Explorer und AWS Budgets?

4.  Was muss man tun, damit ein Tag in der Kostenanalyse erscheint, und warum erscheinen ältere Kosten nicht?

5.  Erklären Sie den Unterschied zwischen Compute Savings Plan, EC2 Instance Savings Plan und Reserved Instance. Was bedeutet Overcommit?

6.  **Praxis:** Legen Sie per CLI ein Budget von 250 US-Dollar mit Warnungen bei 50 Prozent (tatsächlich), 90 Prozent (tatsächlich) und 100 Prozent (prognostiziert) an.

7.  **Praxis:** Schreiben Sie CLI-Befehle, die die Kosten des Vormonats nach Dienst gruppieren und nur Dienste über 10 US-Dollar anzeigen.

8.  **Praxis:** Erstellen Sie ein TCO-Vergleichsmodell (Python) über 3 Jahre mit mindestens fünf Kostenarten lokal und fünf in der Cloud und erläutern Sie zwei Sensitivitäten.

## Lösungen Modul 11

1.  Prinzipien: Pay-as-you-go, Save when you reserve, Pay less as you use more. Haupttreiber: Compute, Speicher, Datenübertragung (ausgehend).

2.  Neue Konten erlauben den Zugriff auf die Billing-Daten nur dem Root User. Der Root User muss den IAM-Zugriff auf Billing und Cost Management einmalig aktivieren; danach vergibt man Rechte per IAM-Richtlinien.

3.  Cost Explorer analysiert Kosten und Nutzung rückblickend und gruppiert nach Dienst, Konto, Tag und so weiter. Budgets setzen eine Grenze, prognostizieren und lösen Benachrichtigungen oder Aktionen aus; sie arbeiten vorausschauend.

4.  Das Tag muss an den Ressourcen gesetzt und in der Billing-Console als Kostenverteilungs-Tag aktiviert werden. Die Zuordnung gilt erst für Kosten ab der Aktivierung (mit Verzögerung); ältere Kosten bleiben ohne Tag, weil die Rechnungsdaten nicht automatisch rückwirkend neu zugeordnet werden.

5.  Compute Savings Plan: Stundenbetrag, gilt flexibel für Instanzfamilien, Regionen, Fargate und Lambda, geringerer Rabatt. EC2 Instance Savings Plan: Stundenbetrag, gebunden an Instanzfamilie und Region, höherer Rabatt. Reserved Instance: Reservierung einer bestimmten Konfiguration (Standard oder Convertible). Overcommit: Verpflichtung höher als die tatsächliche Nutzung; die ungenutzte Rate wird trotzdem bezahlt.

6.  ```bash
    cat > b.json <<'EOT'
    {"BudgetName":"projekt-250","BudgetLimit":{"Amount":"250","Unit":"USD"},
     "TimeUnit":"MONTHLY","BudgetType":"COST"}
    EOT
    cat > n.json <<'EOT'
    [
     {"Notification":{"NotificationType":"ACTUAL","ComparisonOperator":"GREATER_THAN","Threshold":50,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"team@beispiel.de"}]},
     {"Notification":{"NotificationType":"ACTUAL","ComparisonOperator":"GREATER_THAN","Threshold":90,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"team@beispiel.de"}]},
     {"Notification":{"NotificationType":"FORECASTED","ComparisonOperator":"GREATER_THAN","Threshold":100,"ThresholdType":"PERCENTAGE"},"Subscribers":[{"SubscriptionType":"EMAIL","Address":"team@beispiel.de"}]}
    ]
    EOT
    aws budgets create-budget --account-id 123456789012 \
      --budget file://b.json --notifications-with-subscribers file://n.json
    ```

7.  ```bash
    aws ce get-cost-and-usage \
      --time-period Start=2026-09-01,End=2026-10-01 \
      --granularity MONTHLY --metrics UnblendedCost \
      --group-by Type=DIMENSION,Key=SERVICE \
      --query 'ResultsByTime[0].Groups[?Metrics.UnblendedCost.Amount>`10`].{Dienst:Keys[0],Kosten:Metrics.UnblendedCost.Amount}' \
      --output table
    ```

8.  Lösungsansatz: Lokal: Hardware, Lizenzen, Strom/Kühlung/Raum, Personal, Netzwerk; Cloud: laufende Rechnung, Support, Migration, Schulung, Personal. Summe über 36 Monate je Seite. Sensitivitäten: (a) Last steigt um 30 Prozent: Cloud-Kosten steigen proportional, lokale Hardware stößt eventuell an Kapazitätsgrenzen und bräuchte Zusatzinvestition; (b) Savings Plan mit 30 Prozent Rabatt auf den Compute-Anteil senkt die Cloud-Kosten; (c) Migration dauert sechs Monate länger: Parallelbetrieb kostet zusätzlich. Das Ergebnis sollte die Annahmen offenlegen.
