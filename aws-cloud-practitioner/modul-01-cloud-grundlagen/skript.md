# Modul 1 - Cloud-Grundlagen und AWS Architektur

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 8 h

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit                            | Dauer (h) |
|----:|:---------------------------------------|----------:|
| 1.1 | Cloud Computing Grundbegriffe          |         1 |
| 1.2 | AWS Value Proposition                  |         1 |
| 1.3 | Deployment-Modelle                     |         1 |
| 1.4 | Service-Kategorien                     |         1 |
| 1.5 | Shared Responsibility Model            |         1 |
| 1.6 | AWS Management Console                 |         1 |
| 1.7 | AWS Support- und Dokumentationsquellen |         1 |
| 1.8 | Cloud Adoption Denkweise               |         1 |
|     | **Summe**                              |     **8** |

Das erste Modul legt das Fundament für alles Weitere. Wer verstanden hat, was Cloud Computing im Kern ist, warum Unternehmen es nutzen und wer für welchen Teil der Sicherheit verantwortlich ist, kann die späteren Dienste (Rechner, Speicher, Netzwerk) sinnvoll einordnen. Cloud-Konzepte sind ein eigener Prüfungsbereich im CLF-C02, und das Shared Responsibility Model gehört zu den am häufigsten geprüften Themen überhaupt.

## 1.1 Cloud Computing Grundbegriffe

Unter Cloud Computing versteht man die bedarfsgerechte Bereitstellung von IT-Ressourcen wie Rechenleistung, Speicher, Datenbanken oder Netzwerkfunktionen über das Internet, abgerechnet nach tatsächlicher Nutzung. Das National Institute of Standards and Technology (NIST) beschreibt fünf Kerneigenschaften, die auch AWS erfüllt: Der Nutzer kann Ressourcen selbst und ohne menschliche Interaktion mit dem Anbieter anfordern (*On-Demand Self-Service*), sie sind über das Netzwerk mit Standardmechanismen erreichbar (*Broad Network Access*), der Anbieter bündelt Hardware für viele Kunden gleichzeitig (*Resource Pooling*), Kapazität lässt sich schnell vergrößern und verkleinern (*Rapid Elasticity*) und die Nutzung wird gemessen und abgerechnet (*Measured Service*).

Um zu verstehen, warum das so wichtig ist, hilft der Vergleich mit dem klassischen Rechenzentrum. Wer früher einen neuen Server brauchte, musste Budget beantragen, Hardware bestellen, wochenlang auf die Lieferung warten, das Gerät einbauen, verkabeln und installieren. Die Kapazität musste im Voraus für den erwarteten Spitzenbedarf geschätzt werden. Lag die Schätzung zu niedrig, brach die Anwendung unter Last zusammen; lag sie zu hoch, standen teure Maschinen jahrelang ungenutzt herum. In der Cloud wird diese Rechnung umgedreht: Man mietet, was man gerade braucht, und gibt es zurück, wenn es nicht mehr benötigt wird.

Daraus folgt der in der Prüfung viel gefragte Unterschied zwischen *CapEx* und *OpEx*. Capital Expenditure (CapEx) bezeichnet Investitionsausgaben, also den Kauf von Anlagegütern wie Servern, die man über Jahre abschreibt. Operational Expenditure (OpEx) bezeichnet laufende Betriebskosten, etwa die monatliche Rechnung für genutzte Dienste. Cloud-Nutzung verschiebt Ausgaben von CapEx zu OpEx: keine hohe Anfangsinvestition, dafür variable Kosten, die mit der Nutzung steigen und fallen. Dieses Abrechnungsprinzip heißt *Pay-as-you-go*. Es ermöglicht außerdem, mit kleinen Experimenten zu beginnen, weil ein gescheitertes Projekt nur die tatsächlich verbrauchten Stunden kostet.

Eng damit verwandt ist der Begriff der Skalierung. *Vertikale Skalierung* (Scale up) bedeutet, einen einzelnen Rechner größer zu machen, also mehr CPU oder RAM zuzuweisen. *Horizontale Skalierung* (Scale out) bedeutet, mehr gleichartige Rechner nebeneinander zu betreiben und die Last zu verteilen. Die Cloud macht beides einfach, aber horizontale Skalierung ist das typische Muster, weil sie praktisch keine Obergrenze kennt und Ausfälle einzelner Maschinen abfedert. *Elastizität* schließlich meint, dass sich die Kapazität automatisch dem Bedarf anpasst, in beide Richtungen.

Die dritte grundlegende Unterscheidung betrifft die *Servicemodelle*. Bei *Infrastructure as a Service* (IaaS) mietet man virtuelle Hardware (Server, Speicher, Netzwerk) und kümmert sich selbst um Betriebssystem und Anwendung; Beispiel ist Amazon EC2. Bei *Platform as a Service* (PaaS) übernimmt der Anbieter zusätzlich Betriebssystem und Laufzeitumgebung, man liefert nur den Code; Beispiel ist AWS Elastic Beanstalk. Bei *Software as a Service* (SaaS) nutzt man eine fertige Anwendung, zum Beispiel Amazon Chime oder Microsoft 365. Je weiter man in Richtung SaaS geht, desto weniger muss man selbst betreiben, desto weniger kann man aber auch selbst gestalten.

Ein erstes Beispiel macht den Selbstbedienungscharakter greifbar. Mit der AWS Command Line Interface (CLI) lässt sich innerhalb von Sekunden ein Speicherbereich anlegen, ohne dass ein Mensch beim Anbieter etwas freigibt. Das folgende Beispiel legt einen S3-Bucket an, kopiert eine Datei hinein und löscht beides wieder.

```bash
aws s3 mb s3://mein-lernbucket-2026-12345 --region eu-central-1
echo "Hallo Cloud" > hallo.txt
aws s3 cp hallo.txt s3://mein-lernbucket-2026-12345/
aws s3 ls s3://mein-lernbucket-2026-12345/
aws s3 rm s3://mein-lernbucket-2026-12345/hallo.txt
aws s3 rb s3://mein-lernbucket-2026-12345
```

Die erste Zeile (`mb` steht für *make bucket*) erzeugt einen Bucket in der Region Frankfurt; Bucket-Namen sind weltweit eindeutig, deshalb die angehängte Zahl. Die zweite Zeile erzeugt lokal eine Textdatei, `cp` in der dritten Zeile lädt sie hoch, `ls` zeigt den Inhalt, `rm` löscht das Objekt und `rb` (*remove bucket*) entfernt den leeren Bucket. Abgerechnet wird nur der minimale Speicher für die Dauer der Existenz; das ist Pay-as-you-go in der Praxis.

### Typische Fehler.

Häufig wird Cloud mit “Server eines fremden Anbieters” gleichgesetzt. Falsch ist die Annahme “Cloud ist immer billiger”: Ein konstant ausgelasteter Server kann im eigenen Rechenzentrum günstiger sein, die Vorteile der Cloud liegen in Flexibilität, Geschwindigkeit und wegfallendem Hardwarebetrieb. Ebenso falsch ist, Elastizität und Skalierbarkeit gleichzusetzen: Skalierbar ist ein System, das größer werden *kann*; elastisch ist es, wenn es sich automatisch und auch wieder zurück anpasst.

### Praxisbezug.

Ein Webshop erlebt vor Weihnachten das Zehnfache des üblichen Verkehrs. Im eigenen Rechenzentrum müsste die Hardware dafür das ganze Jahr vorgehalten werden. In der Cloud startet man für sechs Wochen zusätzliche Server und bezahlt nur diese Zeit.

> **Merke**
>
> Cloud = On-Demand-Bereitstellung, Selbstbedienung, Abrechnung nach Nutzung. CapEx wird zu OpEx. IaaS, PaaS und SaaS unterscheiden sich darin, wie viel der Kunde selbst betreibt.

## 1.2 AWS Value Proposition

Das Nutzenversprechen (*Value Proposition*) von AWS lässt sich auf wenige Argumente verdichten, die sich auch in den sechs Vorteilen der Cloud wiederfinden, die AWS in seinen Unterlagen nennt: Kapitalkosten werden durch variable Kosten ersetzt, man profitiert von Skaleneffekten, man muss Kapazität nicht mehr raten, Geschwindigkeit und Agilität steigen, man gibt kein Geld mehr für den Betrieb von Rechenzentren aus, und man kann in wenigen Minuten weltweit bereitstellen.

Skaleneffekte (*Economies of Scale*) entstehen, weil AWS Hardware, Strom und Betrieb für Millionen von Kunden bündelt. Der Anbieter kauft in enormen Mengen ein und verteilt Fixkosten auf sehr viele Nutzer; dadurch kann er niedrigere Stückpreise anbieten, als ein einzelnes Unternehmen erreichen würde. Mit dem Wegfall des Kapazitäts-Ratens ist gemeint, dass man nicht mehr Monate im Voraus den Bedarf schätzen muss. Wächst der Bedarf, bestellt man mehr; sinkt er, gibt man Ressourcen zurück.

*Agilität* bedeutet, dass neue Ideen schnell ausprobiert werden können. Statt Wochen auf Hardware zu warten, steht eine Testumgebung in Minuten bereit. Die Zeit bis zur Markteinführung (*Time-to-Market*) sinkt, und Experimente werden billig. Der Punkt “globale Reichweite” bedeutet, dass dieselbe Anwendung in mehreren Regionen der Welt betrieben werden kann, damit Nutzer geringe Latenz erleben; dazu mehr in Modul 02. *Managed Services* schließlich nehmen dem Kunden undifferenzierte Schwerarbeit ab: Eine verwaltete Datenbank wie Amazon RDS wird vom Anbieter gepatcht, gesichert und überwacht, sodass das Team sich auf die Anwendung konzentrieren kann.

Zwei weitere Eigenschaften sind für die Prüfung wichtig. *Hochverfügbarkeit* (High Availability) beschreibt, dass ein System trotz Ausfällen einzelner Komponenten weiterläuft. *Fehlertoleranz* geht einen Schritt weiter und meint, dass ein Ausfall für den Nutzer überhaupt nicht spürbar ist. Beide werden in der Cloud durch Verteilung auf mehrere Standorte erreicht. Dazu kommt *Agilität im Betrieb*: Infrastruktur wird per Code beschrieben und lässt sich beliebig oft identisch aufbauen.

Wie schnell die Kapazität wachsen kann, zeigt ein Beispiel, das mehrere identische Server auf einmal startet. Es nutzt den Befehl `run-instances` der CLI.

```bash
aws ec2 run-instances \
  --image-id ami-0123456789abcdef0 \
  --instance-type t3.micro \
  --count 3 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=lernserver}]'
```

Der Parameter `--image-id` wählt das Abbild (AMI), das auf den Servern laufen soll, `--instance-type` die Größe, `--count 3` verlangt drei identische Maschinen auf einmal und `--tag-specifications` versieht sie mit einem Namensetikett. Die ID im Beispiel ist ein Platzhalter und muss durch eine in der eigenen Region gültige AMI-ID ersetzt werden. Innerhalb von ein bis zwei Minuten laufen drei Server, ohne dass Hardware bestellt wurde.

### Typische Fehler.

Falsch ist die Aussage “AWS übernimmt die Sicherheit komplett”; richtig ist, dass der Kunde die Sicherheit *in* der Cloud verantwortet (siehe Abschnitt Shared Responsibility). Ebenso falsch ist “Managed Service bedeutet, dass ich nichts konfigurieren muss”; Zugriffsrechte, Verschlüsselung und Netzwerkfreigaben bleiben Kundensache.

### Praxisbezug.

Ein Start-up testet eine App-Idee. Mit AWS kostet der Prototyp zwei Wochen lang wenige Euro; scheitert die Idee, bleibt keine Hardware übrig. Ein Konzern nutzt dieselben Mechanismen, um seine Entwicklungsumgebung abends und am Wochenende abzuschalten.

> **Ergänzung aus der Nachrecherche**
>
> Laut dem offiziellen Prüfungsleitfaden umfasst die Prüfung CLF-C02 50 gewertete und 15 ungewertete Fragen; bestanden ist sie bei einem Scaled Score von 700 von 1000 Punkten. Die Bereiche Cloud-Konzepte, Sicherheit, Technologie und Abrechnung werden kompensatorisch bewertet. Dauer und Prozentgewichte der Domänen stammen nicht aus dem abgerufenen Text und sind im offiziellen Leitfaden nachzuprüfen.

## 1.3 Deployment-Modelle

Ein Deployment-Modell beschreibt, wo eine Anwendung läuft und wem die zugrunde liegende Infrastruktur gehört. Man unterscheidet drei Grundformen: die reine Cloud, die Hybrid-Cloud und die lokale Bereitstellung (*On-Premises*).

Bei einer *Cloud-nativen* (oder “All-in”) Bereitstellung läuft die gesamte Anwendung in der Cloud. Sie kann dort von Grund auf neu entwickelt oder aus einer bestehenden Umgebung migriert worden sein. Der Vorteil liegt darin, dass sich die Vorteile der Cloud voll ausschöpfen lassen. Bei *On-Premises* (auch *Private Cloud* genannt, wenn es mit Virtualisierung und Selbstbedienung betrieben wird) liegt alles im eigenen Rechenzentrum. Der Betreiber behält volle Kontrolle, trägt aber alle Kosten und den gesamten Betrieb. Die *Hybrid-Cloud* verbindet beides: Ein Teil der Anwendungen läuft lokal, ein anderer in der Cloud, und beide Teile sind über eine Netzwerkverbindung gekoppelt.

Warum entscheiden sich Unternehmen für Hybrid-Szenarien? Typische Gründe sind regulatorische Auflagen (bestimmte Daten dürfen das Haus nicht verlassen), sehr geringe Latenz zu lokalen Maschinen, vorhandene Altsysteme, die sich nicht sofort verschieben lassen, oder schlicht ein schrittweiser Umzug über mehrere Jahre. Um beides zu verbinden, bietet AWS eine verschlüsselte Verbindung über das Internet (Site-to-Site VPN) oder eine dedizierte, private Leitung (AWS Direct Connect) an; Details folgen in Modul 06. Mit AWS Outposts kann AWS-Infrastruktur sogar im eigenen Rechenzentrum betrieben werden.

Die Entscheidungsfaktoren für ein Modell sind wiederkehrend: Datenschutz und Compliance, Latenz, vorhandene Investitionen, Know-how im Team, Kostenstruktur und Zeitdruck. Eine saubere Entscheidung betrachtet die einzelne Anwendung (*Workload*) und nicht das Unternehmen als Ganzes. Ein Unternehmen kann für eine Webseite voll auf die Cloud setzen und für eine Fertigungssteuerung bewusst lokal bleiben.

Das folgende Beispiel zeigt, wie man in der CLI prüft, welche Verbindungen zum eigenen Netzwerk existieren, und damit ein Hybrid-Szenario sichtbar macht. Es fragt VPN-Verbindungen und Direct-Connect-Verbindungen ab.

```bash
aws ec2 describe-vpn-connections --region eu-central-1 \
  --query 'VpnConnections[].{Id:VpnConnectionId,Status:State}'
aws directconnect describe-connections --region eu-central-1
```

Die erste Zeile listet alle Site-to-Site-VPN-Verbindungen in der Region. Der `--query`-Parameter nutzt die Abfragesprache JMESPath, um aus der Antwort nur Verbindungs-ID und Zustand zu zeigen. Die zweite Zeile zeigt dedizierte Verbindungen. Ist die Ausgabe leer, existiert kein Hybrid-Anschluss; das Konto wird dann rein cloudbasiert betrieben.

### Typische Fehler.

Falsch: “Hybrid heißt, zwei Cloud-Anbieter zu nutzen”; das nennt man *Multi-Cloud*. Richtig: Hybrid verbindet Cloud mit lokaler Infrastruktur. Ebenfalls falsch: “Private Cloud und On-Premises sind dasselbe ohne Ausnahme”; eine Private Cloud setzt Selbstbedienung und Virtualisierung voraus, ein bloßer Serverraum ist keine.

### Praxisbezug.

Eine Bank lässt Kundendaten aus Datenschutzgründen im eigenen Rechenzentrum, betreibt aber die Webseite und die Analyseplattform in AWS und verbindet beides über Direct Connect.

> **Merke**
>
> Cloud-nativ = alles in der Cloud, Hybrid = Cloud plus lokal (VPN oder Direct Connect), On-Premises = alles lokal. Multi-Cloud ist etwas anderes als Hybrid.

## 1.4 Service-Kategorien

AWS bietet weit über zweihundert Dienste an. Um sich nicht zu verlieren, gruppiert man sie in Kategorien. Für die Prüfung genügt es, die großen Gruppen sicher zu beherrschen und jedem typischen Anwendungsfall einen Dienst zuzuordnen.

Zur Kategorie *Compute* gehören Dienste, die Rechenleistung liefern: Amazon EC2 (virtuelle Server), AWS Lambda (Funktionen ohne Serververwaltung), Amazon ECS und EKS (Container). Zu *Storage* zählen Amazon S3 (Objektspeicher), Amazon EBS (Blockspeicher für Server) und Amazon EFS (Dateisystem). Unter *Database* finden sich Amazon RDS (relationale Datenbanken), Amazon DynamoDB (NoSQL) und Amazon Redshift (Data Warehouse). Die Kategorie *Networking and Content Delivery* umfasst Amazon VPC (virtuelles Netzwerk), Amazon Route 53 (DNS) und Amazon CloudFront (Content Delivery Network). *Security, Identity and Compliance* enthält AWS IAM, AWS KMS, Amazon GuardDuty und AWS Shield. Zu *Management and Governance* gehören Amazon CloudWatch, AWS CloudTrail, AWS Config und AWS Organizations. Weitere Kategorien sind Analytics, Machine Learning, Migration und Developer Tools.

Die Zuordnung gelingt am besten über den Anwendungsfall. Soll ein Foto-Archiv gespeichert werden, ist das S3. Soll eine klassische Anwendung mit eigenem Betriebssystem laufen, ist es EC2. Soll eine kleine Funktion nur bei einem Ereignis ausgeführt werden, ist es Lambda. Soll eine relationale Datenbank ohne Wartungsaufwand laufen, ist es RDS. Soll ein Schlüssel zur Verschlüsselung verwaltet werden, ist es KMS. Man sollte außerdem wissen, dass AWS viele Dienste nach einem einheitlichen Muster benennt: “Amazon” steht meist vor eigenständigen Diensten, “AWS” vor Diensten, die eher Funktionen oder Verwaltung betreffen, auch wenn diese Regel nicht ausnahmslos gilt.

Die Dienste lassen sich mit einem Befehl der CLI nach Kategorie erkunden. Das folgende Beispiel nutzt die Hilfe der CLI, um alle verfügbaren Dienstnamen und die Operationen eines einzelnen Dienstes anzuzeigen.

```bash
aws help
aws s3 help
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'
```

Die erste Zeile listet die Dienste, die die CLI kennt, die zweite die Befehle des Dienstes S3. Die dritte Zeile ruft eine konkrete Operation von EC2 auf und gibt nur die Instanz-IDs aus. Dadurch sieht man, dass jeder Dienst eine eigene Befehlsgruppe mit Verben wie `describe`, `create` und `delete` besitzt.

### Typische Fehler.

Verwechslungen betreffen vor allem ähnlich klingende Speicherdienste: S3 ist *kein* Dateisystem, das man wie ein Laufwerk mountet, und EBS lässt sich nicht von mehreren Servern gleichzeitig wie EFS nutzen. Falsch ist auch die Zuordnung von CloudTrail zum Monitoring von Leistung; CloudTrail protokolliert API-Aufrufe, Leistungsdaten liefert CloudWatch.

### Praxisbezug.

In Architekturgesprächen wird nicht über Produktnamen, sondern über Bausteine gesprochen: ein Load Balancer, zwei Server, eine Datenbank, ein Objektspeicher. Wer die Kategorien kennt, findet den passenden Baustein schnell.

## 1.5 Shared Responsibility Model

Das Modell der geteilten Verantwortung (*Shared Responsibility Model*) ist die wichtigste Regel der Cloud-Sicherheit. Es besagt: AWS ist verantwortlich für die Sicherheit *der* Cloud, der Kunde für die Sicherheit *in* der Cloud.

Zur Sicherheit *der* Cloud gehört alles, was der Kunde nicht sieht oder beeinflussen kann: Gebäude und physischer Zugang zu den Rechenzentren, Strom und Kühlung, Server, Speichermedien und Netzwerkhardware sowie die Software, die die Virtualisierung und die Dienste selbst betreibt. Der Kunde muss kein Wachpersonal anheuern oder defekte Festplatten tauschen. Für die Sicherheit *in* der Cloud ist der Kunde zuständig: seine Daten, deren Klassifizierung und Verschlüsselung, die Verwaltung von Identitäten und Zugriffsrechten, die Konfiguration von Firewalls (Security Groups), das Betriebssystem und die Anwendung auf selbst betriebenen Servern sowie das Patchen dieser Software.

Wie die Grenze verläuft, hängt vom Dienst ab. Bei einem Dienst wie Amazon EC2 (IaaS) ist der Kunde auch für das Gast-Betriebssystem, dessen Updates und die Anwendungs-Firewall verantwortlich. Bei einem verwalteten Dienst wie Amazon RDS patcht AWS das Datenbanksystem und das Betriebssystem, der Kunde verwaltet aber weiterhin Zugriffe, Netzwerkfreigabe und Daten. Bei einem abstrakten Dienst wie Amazon S3 oder AWS Lambda kümmert sich AWS um noch mehr, der Kunde bleibt für Daten, Berechtigungen und Code verantwortlich. Manche Kontrollen sind *geteilt*, etwa Patch-Management (AWS patcht die Infrastruktur, der Kunde sein Betriebssystem) oder Konfigurationsmanagement. Andere werden *geerbt*, etwa die physische Sicherheit, die der Kunde komplett von AWS übernimmt.

Wie das in der Praxis aussieht, zeigt ein Beispiel für eine häufige Kundenpflicht: öffentlichen Zugriff auf einen Bucket zu verhindern. Das ist keine Aufgabe von AWS, sondern eine Einstellung, die der Kunde setzt.

```bash
aws s3api put-public-access-block \
  --bucket mein-lernbucket-2026-12345 \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Der Befehl setzt die vier Schalter von *Block Public Access* für den Bucket. Damit kann weder eine fehlerhafte Zugriffsliste (ACL) noch eine zu großzügige Bucket-Policy den Inhalt versehentlich öffentlich machen. AWS stellt die Funktion bereit (Sicherheit der Cloud), aktivieren und prüfen muss sie der Kunde (Sicherheit in der Cloud).

### Typische Fehler.

Falsch ist “Mein Bucket wurde gehackt, also hat AWS versagt”. Meist liegt eine Fehlkonfiguration des Kunden vor, etwa eine öffentliche Freigabe. Falsch ist auch “Bei RDS muss ich nichts mehr absichern”; Passwörter, Netzwerkregeln und Verschlüsselung der Daten bleiben Kundenaufgabe. Richtig ist die Faustregel: *Daten, Zugriffe und Konfiguration gehören immer dem Kunden.*

### Praxisbezug.

Bei Audits fragen Prüfer, wer für welche Kontrolle verantwortlich ist. Das Modell liefert die Antwort und zeigt, welche Nachweise der Kunde bei AWS Artifact abrufen kann und welche er selbst erbringen muss.

> **Merke**
>
> Sicherheit *der* Cloud = AWS (Hardware, Rechenzentrum, Hypervisor). Sicherheit *in* der Cloud = Kunde (Daten, IAM, Konfiguration, Gast-OS bei EC2). Je abstrakter der Dienst, desto mehr übernimmt AWS.

## 1.6 AWS Management Console

Die AWS Management Console ist die webbasierte Oberfläche, über die sich alle Dienste bedienen lassen. Sie eignet sich zum Lernen, Erkunden und für gelegentliche Aufgaben; für wiederholbare Abläufe nutzt man CLI, SDKs oder Infrastructure as Code (Modul 10).

Nach der Anmeldung steht oben eine Suchleiste, über die man Dienste, Funktionen und sogar Dokumentation findet. Das Menü “Services” gruppiert die Dienste nach den Kategorien aus dem vorigen Abschnitt. Besonders wichtig ist rechts oben die *Regionsauswahl*: Die meisten Ressourcen existieren in genau einer Region, und die Console zeigt nur die der gerade gewählten Region an. Wer eine Ressource “verliert”, hat meist die Region gewechselt. Einige Dienste wie IAM, Route 53 oder CloudFront sind global und zeigen unabhängig von der Region dieselben Daten.

Weitere nützliche Elemente sind die *Favoriten*, die den schnellen Zugriff auf häufige Dienste erlauben, das *Billing and Cost Management*-Dashboard (erreichbar über das Konto-Menü), die *CloudShell* und die *Resource Groups* mit dem Tag Editor. Die CloudShell ist eine im Browser laufende Shell mit vorinstallierter CLI und den Rechten des angemeldeten Benutzers; man muss lokal nichts installieren. Resource Groups fassen Ressourcen über Tags zusammen, sodass man Ressourcen eines Projekts gesammelt sieht.

Wer von der Console zur CLI wechseln möchte, muss zuerst Zugangsdaten und eine Standardregion hinterlegen. Das erledigt der folgende Befehl, der nach Zugriffsschlüssel, geheimem Schlüssel, Region und Ausgabeformat fragt.

```bash
aws configure
aws sts get-caller-identity
aws configure get region
```

`aws configure` schreibt die Eingaben in die Dateien `~/.aws/credentials` und `~/.aws/config`. `aws sts get-caller-identity` ist die wichtigste Kontrollfrage: Sie zeigt, mit welcher Identität und in welchem Konto man gerade arbeitet, und ist dadurch das beste Mittel gegen Verwechslungen. Die dritte Zeile zeigt die eingestellte Standardregion.

### Typische Fehler.

Falsch: Mit dem Root-Benutzer arbeiten, weil er “alles darf”. Richtig: Für die tägliche Arbeit einen IAM-Benutzer oder eine Rolle mit eingeschränkten Rechten verwenden und den Root-Benutzer nur für Sonderaufgaben einsetzen (Modul 03). Ein weiterer Klassiker: Ressourcen in der falschen Region anlegen und später vergeblich suchen.

### Praxisbezug.

In Teams hat sich bewährt, Produktions- und Testkonten farblich oder durch Kontoaliasse zu unterscheiden, damit niemand versehentlich in der falschen Umgebung arbeitet.

## 1.7 AWS Support- und Dokumentationsquellen

Wer AWS beherrschen will, muss vor allem wissen, wo verlässliche Antworten zu finden sind, denn die Dienste ändern sich ständig. Die wichtigste Quelle ist die offizielle Dokumentation unter docs.aws.amazon.com. Jeder Dienst hat dort ein Benutzerhandbuch (*User Guide*), eine API-Referenz und häufig Tutorials. Dokumentationsseiten tragen meist ein Datum und lassen sich für die CLI direkt mit dem Befehl `help` nachvollziehen.

Ergänzend gibt es *AWS re:Post*, die Frage-und-Antwort-Plattform der Community mit Beiträgen von AWS-Mitarbeitenden. *Whitepapers* und der *Architecture Center* beschreiben Entwurfsmuster, darunter das Well-Architected Framework (Modul 09). *AWS Skill Builder* bietet kostenlose und kostenpflichtige Kurse, Übungsfragen und Labs, darunter einen offiziellen Vorbereitungskurs für die Cloud-Practitioner-Prüfung. Zusätzlich veröffentlichen *AWS Prescriptive Guidance* und die *AWS Knowledge Center*-Artikel Anleitungen für häufige Probleme.

Für Betrieb und Problemfälle ist das Thema *AWS Support* wichtig, das später ausführlich behandelt wird (Modul 11). Kurz gesagt gibt es die Tarife Basic, Developer, Business und Enterprise mit unterschiedlichen Reaktionszeiten und Leistungen. Auch im kostenlosen Basic-Tarif stehen Dokumentation, Foren, der Service Health Status und Teile von Trusted Advisor bereit.

Wie man gezielt Hilfe zur CLI abruft, zeigt das folgende Beispiel. Es nutzt die eingebaute Dokumentation, die ohne Internetzugang funktioniert.

```bash
aws ec2 run-instances help
aws s3api put-bucket-versioning help | less
aws --version
```

Die ersten beiden Zeilen öffnen die Handbuchseite des jeweiligen Befehls mit Beschreibung, Parametern und Beispielen. Die dritte Zeile zeigt die Version der CLI; das ist hilfreich, wenn ein Befehl aus einer Anleitung bei einer älteren Version nicht existiert.

### Typische Fehler.

Blogbeiträge und Videos veralten schnell; Preise, Limits und Servicenamen ändern sich. Falsch ist, sich auf eine mehrere Jahre alte Anleitung zu verlassen. Richtig ist, Preise auf der offiziellen Preisseite und Limits in der Dokumentation (Service Quotas) zu prüfen. Auch ein Fehler: Als Prüfungsvorbereitung ausschließlich inoffizielle Fragensammlungen zu nutzen, deren Antworten teils falsch sind.

### Praxisbezug.

Im Projekt gilt die Faustregel: erst Dokumentation, dann re:Post, dann Support-Fall. Bei einem Produktionsausfall mit passendem Tarif wird sofort ein Fall eröffnet.

## 1.8 Cloud Adoption Denkweise

Die technische Seite der Cloud ist nur die Hälfte der Aufgabe. Ebenso wichtig ist, wie Organisationen arbeiten: Wer Cloud wie ein altes Rechenzentrum betreibt, verschenkt den Nutzen. AWS beschreibt diese Veränderung im *AWS Cloud Adoption Framework* (CAF), das den Weg in perspektivische Bereiche gliedert: Business, People, Governance, Platform, Security und Operations.

Drei Betriebsprinzipien prägen die Denkweise. Erstens *Standardisierung*: Umgebungen werden nach einheitlichen Vorlagen aufgebaut, statt jedes Mal neu von Hand. Zweitens *Automatisierung*: Wiederkehrende Aufgaben werden skriptgesteuert erledigt, weil Handarbeit fehleranfällig ist und nicht skaliert. Drittens *Governance*: Regeln, Budgets und Freigaben stellen sicher, dass die neu gewonnene Freiheit nicht zu Wildwuchs führt. Dazu gehören Mehrkonten-Strukturen, Tagging und Richtlinien, die in den Modulen 03, 08 und 11 vertieft werden.

Cloud-Nutzen und Risiken gehören zusammen betrachtet. Zum Nutzen zählen Geschwindigkeit, Elastizität und Kostentransparenz. Zu den Risiken zählen Kostenüberraschungen durch vergessene Ressourcen, Sicherheitslücken durch Fehlkonfiguration, Abhängigkeit von einem Anbieter (*Vendor Lock-in*) und Wissenslücken im Team. Wer die Verantwortlichkeiten aus dem Shared Responsibility Model kennt, kann diese Risiken gezielt benennen und zuordnen. Eine reife Organisation baut deshalb parallel zur Technik Fähigkeiten auf: Schulungen, ein Cloud-Kompetenzteam und klare Zuständigkeiten.

Ein einfaches Beispiel für Governance durch Automatisierung ist das Erzwingen von Tags. Mit dem Resource Groups Tagging API lässt sich prüfen, welche Ressourcen kein Pflicht-Tag tragen.

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Projekt \
  --query 'ResourceTagMappingList[].ResourceARN'
aws ec2 create-tags --resources i-0123456789abcdef0 \
  --tags Key=Projekt,Value=Lernplattform Key=Owner,Value=team-a
```

Die erste Anweisung listet alle Ressourcen, die das Tag `Projekt` besitzen. Die zweite versieht eine Instanz mit zwei Tags. Wenn jede Ressource Projekt und Besitzer trägt, lassen sich später Kosten zuordnen und Verantwortliche finden. Die Instanz-ID ist wieder ein Platzhalter.

### Typische Fehler.

Falsch: “Lift and Shift reicht, dann ist die Cloud-Migration fertig”. Ein reiner Umzug ohne Anpassung nutzt Elastizität und Managed Services kaum. Falsch ist auch, Governance “später” einzuführen; nachträglich Tags, Konten und Regeln zu ordnen ist deutlich aufwendiger.

### Praxisbezug.

Ein Unternehmen richtet ein kleines Cloud-Center-of-Excellence ein, das Vorlagen, Sicherheitsvorgaben und Schulungen bereitstellt. Projektteams dürfen dann selbstständig arbeiten, aber innerhalb klar definierter Leitplanken.

## Übungsaufgaben Modul 01

1.  Erklären Sie in zwei Sätzen den Unterschied zwischen CapEx und OpEx und nennen Sie für jeden ein Beispiel.

2.  Ordnen Sie zu, ob es sich um IaaS, PaaS oder SaaS handelt: Amazon EC2, AWS Elastic Beanstalk, Amazon Chime.

3.  Ein Unternehmen darf Kundendaten nicht außerhalb des eigenen Hauses speichern, möchte aber die Analyse in der Cloud betreiben. Welches Deployment-Modell passt und welche AWS-Verbindungsmöglichkeiten kommen infrage?

4.  Welche der folgenden Aufgaben liegt bei AWS, welche beim Kunden? (a) Austausch defekter Festplatten, (b) Patchen des Betriebssystems einer EC2-Instanz, (c) Verschlüsselung von Daten in S3, (d) Zutrittskontrolle zum Rechenzentrum.

5.  Ordnen Sie den Anwendungsfällen einen Dienst zu: Foto-Archiv, relationale Datenbank ohne Wartung, Funktion nach Ereignis, Schlüsselverwaltung, DNS.

6.  **Praxis:** Schreiben Sie CLI-Befehle, die einen Bucket in Frankfurt anlegen, Block Public Access aktivieren und mit `get-public-access-block` prüfen.

7.  **Praxis:** Schreiben Sie einen Befehl, der alle EC2-Instanzen eines Kontos mit `--query` nur mit ID und Zustand ausgibt.

8.  **Praxis:** Ein Webshop hat im Jahr 10 Server im Dauerbetrieb, zu Weihnachten kurzfristig 40. Begründen Sie in einem kurzen Text, warum Pay-as-you-go und Elastizität hier Vorteile bringen, und nennen Sie einen Gegenfall, in dem die Cloud nicht günstiger wäre.

## Lösungen Modul 01

1.  CapEx sind einmalige Investitionen in Anlagegüter (Server kaufen), OpEx sind laufende Kosten (monatliche Rechnung für genutzte Cloud-Dienste). Die Cloud verschiebt Ausgaben von CapEx zu OpEx.

2.  EC2 ist IaaS, Elastic Beanstalk ist PaaS, Amazon Chime ist SaaS. Der Unterschied liegt darin, wie viel der Kunde betreibt: bei IaaS auch das Betriebssystem, bei PaaS nur den Code, bei SaaS nichts.

3.  Hybrid-Cloud. Die Verbindung kann per Site-to-Site VPN (über das Internet, verschlüsselt) oder AWS Direct Connect (dedizierte Leitung, stabilere Latenz) hergestellt werden. Die sensiblen Daten bleiben lokal.

4.  \(a\) AWS, (b) Kunde, (c) Kunde (Aktivierung und Schlüsselwahl; AWS stellt die Funktion bereit), (d) AWS. Faustregel: Alles unterhalb des Hypervisors und im Gebäude gehört AWS, Daten, Zugriffe und Konfiguration dem Kunden.

5.  Foto-Archiv: S3; relationale Datenbank: RDS; Funktion nach Ereignis: Lambda; Schlüsselverwaltung: KMS; DNS: Route 53.

6.  Beispiellösung:

    ```bash
    aws s3 mb s3://mein-lernbucket-2026-12345 --region eu-central-1
    aws s3api put-public-access-block --bucket mein-lernbucket-2026-12345 \
      --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
    aws s3api get-public-access-block --bucket mein-lernbucket-2026-12345
    ```

    Die letzte Zeile bestätigt, dass alle vier Schalter auf `true` stehen.

7.  Beispiellösung:

    ```bash
    aws ec2 describe-instances \
      --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name}' \
      --output table
    ```

    Der Ausdruck wählt über zwei Listenebenen (Reservations und Instances) die Felder aus; `--output table` formatiert die Ausgabe lesbar.

8.  Ohne Cloud müssten 40 Server das ganze Jahr vorgehalten werden, obwohl 30 davon nur wenige Wochen gebraucht werden (hohe CapEx, niedrige Auslastung). Mit Pay-as-you-go und Elastizität startet man die 30 zusätzlichen Server nur zu Spitzenzeiten und bezahlt nur diese Stunden. Gegenfall: Eine Anwendung mit konstant hoher, gut vorhersehbarer Auslastung kann im eigenen Rechenzentrum oder mit Reservierungen billiger sein; die Cloud bietet dann vor allem Geschwindigkeit, nicht Kostenvorteil.
