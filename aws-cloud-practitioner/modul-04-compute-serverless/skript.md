# Modul 4 - Compute und Serverless Grundlagen

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 10 h laut Modulübersicht (die Einheiten summieren sich laut Detailblatt auf 9 h)

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit                      | Dauer (h) |
|----:|:---------------------------------|----------:|
| 4.1 | EC2 Grundlagen                   |      1,25 |
| 4.2 | EC2 Pricing-Optionen             |         1 |
| 4.3 | Auto Scaling                     |      1,25 |
| 4.4 | Elastic Load Balancing           |      1,25 |
| 4.5 | Lambda Grundlagen                |      1,25 |
| 4.6 | Container-Überblick              |         1 |
| 4.7 | Elastic Beanstalk und App Runner |         1 |
| 4.8 | Compute-Fehlerbilder             |         1 |
|     | **Summe der Einheiten**          |     **9** |

> **Merke**
>
> Hinweis zum Lehrplan: Die Modulübersicht nennt 10 Stunden, die Einheiten im Detailblatt ergeben nur 9 Stunden. Dieses Skript behandelt alle acht Einheiten vollständig; die Differenz von einer Stunde wird für die Übungsaufgaben und die Nacharbeit genutzt.

Compute bezeichnet alle Dienste, die Rechenleistung bereitstellen. AWS bietet dafür ein Spektrum von maximaler Kontrolle (virtuelle Server, bei denen man das Betriebssystem selbst verwaltet) bis zu maximaler Abstraktion (Funktionen, bei denen man nur noch Code liefert). Je weiter man in Richtung Abstraktion geht, desto mehr Betrieb übernimmt AWS, aber desto weniger kann man selbst bestimmen. Dieses Modul führt entlang dieses Spektrums: zuerst EC2 und seine Bausteine für Skalierung und Lastverteilung, dann Lambda, Container und die Plattformdienste. Das Shared Responsibility Model (Modul 01) verändert sich dabei: Bei EC2 patcht der Kunde das Betriebssystem, bei Lambda nicht mehr.

## 4.1 EC2 Grundlagen

Amazon Elastic Compute Cloud (EC2) stellt virtuelle Server bereit, genannt *Instanzen*. Eine Instanz ist ein Computer mit Prozessoren, Arbeitsspeicher, Speicher und Netzwerk, der auf einem physischen Host im Rechenzentrum läuft und von AWS per Virtualisierung (dem *Nitro-System*) in Scheiben geteilt wird. Man bekommt Administratorrechte auf dem Gastbetriebssystem und kann praktisch jede Software installieren. EC2 ist deshalb der klassische IaaS-Dienst und die richtige Wahl, wenn man ein bestimmtes Betriebssystem, besondere Software oder volle Kontrolle braucht.

Vier Begriffe prägen die Arbeit mit EC2. Das *Amazon Machine Image* (AMI) ist die Vorlage, aus der eine Instanz gestartet wird; es enthält Betriebssystem, vorinstallierte Software und Konfiguration. AWS, Dritthersteller und man selbst können AMIs bereitstellen; ein selbst gebautes AMI erlaubt es, identische Server schnell zu vervielfältigen. Der *Instance Type* bestimmt die Hardware-Ausstattung. Er hat einen Namen wie `m7g.large`: Der Buchstabe gibt die Familie an (`t` und `m` für allgemeine Zwecke, `c` für rechenintensive, `r` für speicherintensive, `i` für speicheroptimierte Workloads mit schnellen lokalen Platten, `p` und `g` für Beschleuniger wie GPUs), die Zahl die Generation, optionale Buchstaben Besonderheiten (`g` für Graviton-Prozessoren von AWS, `a` für AMD), und die Größe (`micro` bis `xlarge` und darüber) die Menge an Ressourcen. Das *Key Pair* besteht aus einem öffentlichen Schlüssel, den AWS in die Instanz einträgt, und einem privaten Schlüssel, den man behält und mit dem man sich per SSH (Linux) anmeldet oder das Windows-Passwort entschlüsselt. Die *Security Group* ist die virtuelle Firewall der Instanz und legt fest, welcher Verkehr erlaubt ist (Modul 06).

Eine Instanz durchläuft Zustände. Nach dem Start ist sie `pending`, dann `running`. Im Zustand `stopped` fallen keine Rechenkosten mehr an (Speicher wird weiter berechnet), die Instanz kann später wieder starten; dabei wechselt gewöhnlich die öffentliche IP-Adresse. Bei `terminated` wird die Instanz endgültig gelöscht. Als Speicher dient entweder ein *EBS-Volume* (persistenter Blockspeicher, überlebt das Stoppen) oder ein *Instance Store* (physisch am Host, sehr schnell, aber beim Stoppen verloren). Beim Start kann man ein *User-Data-Skript* mitgeben, das beim ersten Boot Software installiert und konfiguriert. Über den *Instance Metadata Service* kann die Instanz Informationen über sich selbst abfragen, und *IMDSv2* wird empfohlen, weil es gegen bestimmte Angriffe besser geschützt ist.

Das folgende Beispiel startet einen kleinen Webserver mit User-Data-Skript. Das Skript installiert Apache und schreibt eine Startseite.

```bash
cat > userdata.sh <<'EOT'
#!/bin/bash
dnf install -y httpd
echo "Hallo von EC2" > /var/www/html/index.html
systemctl enable --now httpd
EOT

aws ec2 run-instances \
  --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --instance-type t3.micro \
  --key-name mein-schluessel \
  --security-group-ids sg-0123456789abcdef0 \
  --subnet-id subnet-0123456789abcdef0 \
  --metadata-options HttpTokens=required \
  --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=webserver}]'
```

Das Skript beginnt mit `\#!/bin/bash` und läuft beim ersten Start mit Administratorrechten: Es installiert Apache (`httpd`), erzeugt die Startseite und startet den Dienst dauerhaft. Beim Befehl wird das aktuelle Amazon-Linux-Abbild nicht als feste ID, sondern über einen öffentlichen SSM-Parameter aufgelöst; so zeigt das Beispiel auch in der Zukunft auf ein gültiges AMI. `--key-name` verweist auf ein vorhandenes Key Pair, Security Group und Subnetz sind Platzhalter. `HttpTokens=required` erzwingt IMDSv2. Ruft man nach dem Start die öffentliche IP-Adresse im Browser auf, erscheint die Startseite, vorausgesetzt, die Security Group erlaubt Port 80.

### Typische Fehler.

Falsch: Eine Instanz zu stoppen und dann zu erwarten, dass Daten im Instance Store noch da sind. Richtig: Persistente Daten auf EBS oder S3 ablegen. Falsch: Den privaten Schlüssel zu verlieren oder per E-Mail zu versenden. Falsch: Eine Instanz “zu terminieren”, wenn man nur ausschalten wollte; terminieren löscht sie. Falsch: Die Security Group für SSH mit `0.0.0.0/0` offen zu lassen; besser ist die eigene IP oder der Zugriff über den Systems Manager Session Manager.

### Praxisbezug.

Eine Fachanwendung, die ein bestimmtes Windows-Server-Betriebssystem benötigt und sich nicht in Container oder Funktionen umbauen lässt, läuft auf EC2; Patches des Betriebssystems liegen in der Verantwortung des Kunden.

> **Merke**
>
> EC2 = virtuelle Server (IaaS). AMI = Vorlage, Instance Type = Hardware, Key Pair = Zugang, Security Group = Firewall. Stoppen spart Rechenkosten, Terminieren löscht. Instance Store ist flüchtig, EBS bleibt erhalten.

## 4.2 EC2 Pricing-Optionen

Die Kosten einer EC2-Instanz hängen vom Kaufmodell ab. Wer die Modelle kennt, kann für dieselbe Rechenleistung deutlich weniger bezahlen. Es gibt fünf Hauptmodelle, die in der Prüfung regelmäßig gegenübergestellt werden.

*On-Demand* bedeutet Bezahlung nach Nutzung ohne Bindung. Für Linux- und Windows-Instanzen wird in der Regel sekundengenau abgerechnet, mit einer Mindestdauer von 60 Sekunden; für einige Betriebssysteme gilt stundengenau. On-Demand ist ideal für kurze, unvorhersehbare Lasten, Tests und Neuentwicklungen, aber die teuerste Variante pro Stunde. *Reserved Instances* (RI) und *Savings Plans* sind Verpflichtungen auf eine ein- oder dreijährige Nutzung, die im Gegenzug Rabatte von bis zu etwa zwei Dritteln gegenüber On-Demand bringen können; die genaue Höhe hängt von Laufzeit, Zahlungsoption und Instanzfamilie ab und ist auf der Preisseite zu prüfen. Savings Plans sind flexibler: Man verpflichtet sich zu einem Betrag pro Stunde (zum Beispiel zehn US-Dollar Rechenleistung pro Stunde), der unabhängig von Instanzfamilie, Region oder sogar Dienst (bei den Compute Savings Plans auch Fargate und Lambda) angerechnet wird. Reserved Instances binden dagegen an bestimmte Merkmale wie Instanzfamilie und Region, was sie weniger flexibel macht.

*Spot Instances* nutzen freie Kapazität von AWS zu stark reduzierten Preisen, laut AWS mit Rabatten von bis zu etwa 90 Prozent. Der Haken: AWS kann die Instanz mit einer Vorwarnung von zwei Minuten zurückfordern. Spot eignet sich daher für unterbrechbare, zustandslose oder wiederholbare Aufgaben wie Batch-Verarbeitung, Rendering oder Tests, aber nicht für Datenbanken oder einzelne, kritische Server. *Dedicated Hosts* und *Dedicated Instances* reservieren physische Server für einen Kunden, etwa wenn Softwarelizenzen an Sockets oder Kerne gebunden sind oder Compliance-Vorgaben eigene Hardware verlangen. Dazu kommen *Capacity Reservations*, die Kapazität in einer bestimmten Zone garantieren, ohne Rabatt zu geben.

Die Wahl richtet sich nach dem Lastprofil. Eine konstant laufende Produktionsumgebung ist ein Fall für Savings Plans oder Reservierungen. Eine schwankende Last wird mit On-Demand abgedeckt, ein Grundstock mit Rabatt. Ein nächtlicher Berechnungsauftrag, der sich unterbrechen lässt, läuft auf Spot. Eine einfache Rechnung zeigt die Wirkung: Kostet eine Instanz On-Demand 0,10 US-Dollar pro Stunde und das Jahr hat rund 8760 Stunden, ergeben sich etwa 876 US-Dollar; mit einem Rabatt von 40 Prozent wären es rund 526 US-Dollar. Die Zahlen sind ein Rechenbeispiel, keine Preisangabe.

Das folgende Beispiel zeigt, wie man die aktuellen Spot-Preise abfragt und eine Spot-Instanz anfordert.

```bash
aws ec2 describe-spot-price-history \
  --instance-types t3.micro --product-descriptions "Linux/UNIX" \
  --max-items 3 --region eu-central-1 \
  --query 'SpotPriceHistory[].{Zone:AvailabilityZone,Preis:SpotPrice}'

aws ec2 run-instances --image-id ami-0123456789abcdef0 \
  --instance-type t3.micro \
  --instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=one-time}'
```

Die erste Abfrage zeigt die jüngsten Marktpreise pro Zone. Die zweite startet eine Instanz mit dem Marktmodell Spot; ohne Höchstpreis gilt der aktuelle Marktpreis, begrenzt durch den On-Demand-Preis. Die AMI-ID ist ein Platzhalter. Wird die Kapazität zurückgefordert, beendet AWS die Instanz.

### Typische Fehler.

Falsch: Spot für eine einzelne Datenbankinstanz einzusetzen. Falsch: Für eine Anwendung, die nur wenige Wochen läuft, einen dreijährigen Plan abzuschließen; man zahlt dann für ungenutzte Zeit. Falsch: Reservierungen als flexibel zu betrachten; sie binden. Richtig: Zuerst die Nutzung messen und dann für den stabilen Anteil Savings Plans kaufen.

### Praxisbezug.

Ein Team deckt 60 Prozent der Grundlast mit Savings Plans ab, den Rest mit On-Demand und verlegt Nachtberechnungen auf Spot. Das Cost Explorer (Modul 11) zeigt, ob die Reservierungen ausgelastet sind.

> **Merke**
>
> On-Demand = flexibel, teuer. RI/Savings Plans = 1 oder 3 Jahre Bindung, Rabatt für stabile Last. Spot = bis etwa 90 Prozent günstiger, kann unterbrochen werden. Dedicated = eigene Hardware (Lizenzen, Compliance).

## 4.3 Auto Scaling

Ein einzelner Server ist ein Risiko: Fällt er aus, steht die Anwendung. Und wenn die Last schwankt, ist er mal zu klein und mal zu groß. *Amazon EC2 Auto Scaling* löst beide Probleme, indem es eine Gruppe von Instanzen verwaltet. Es ersetzt defekte Instanzen automatisch (Selbstheilung) und passt die Anzahl der Instanzen an die Last an (Elastizität).

Die Grundlage bildet die *Auto Scaling Group* (ASG). Sie wird durch drei Zahlen gesteuert: das Minimum (so viele Instanzen laufen mindestens), das Maximum (so viele dürfen höchstens laufen, was auch Kostenobergrenze ist) und die gewünschte Kapazität (*Desired Capacity*), die aktuell angestrebt wird. Die Gruppe benutzt eine *Launch Template* (Startvorlage), die AMI, Instance Type, Security Groups, User Data und weitere Parameter enthält, sowie eine Liste von Subnetzen, idealerweise in mehreren Availability Zones. AWS verteilt die Instanzen gleichmäßig auf die Zonen und startet bei Ausfall einer Zone Ersatz in den übrigen.

Wie entscheidet die Gruppe, wann sie wächst oder schrumpft? Dafür gibt es *Skalierungsrichtlinien*. Bei der *Target Tracking*-Richtlinie gibt man ein Ziel vor, zum Beispiel “halte die durchschnittliche CPU-Auslastung bei 50 Prozent”, und AWS regelt selbstständig. Bei *Step Scaling* definiert man Stufen, die an Alarme geknüpft sind (bei 70 Prozent ein Server mehr, bei 90 Prozent drei mehr). *Scheduled Scaling* passt die Kapazität zu festen Zeiten an, etwa für bekannte Lastspitzen, und *Predictive Scaling* nutzt Machine Learning, um die Last vorherzusagen. Die Kennzahlen kommen aus Amazon CloudWatch. Nach einer Skalierungsaktion verhindert eine Abkühlzeit (*Cooldown*), dass sofort die nächste Änderung folgt, bevor die neue Instanz Wirkung zeigt.

Außerdem prüft die Gruppe die Gesundheit der Instanzen. Standardmäßig nutzt sie die EC2-Statusprüfungen; ist die Gruppe an einen Load Balancer gebunden, kann sie auch dessen Gesundheitsprüfung verwenden (`ELB`-Health-Check), was Anwendungsfehler erkennt, die EC2 allein nicht sieht. Bei Verkleinerung wählt die Gruppe nach einer Regel (standardmäßig unter anderem zur Zonenbalance und ältester Startvorlage) aus, welche Instanz beendet wird. Wichtig: Auto Scaling selbst kostet nichts, bezahlt werden die gestarteten Ressourcen.

Das folgende Beispiel erzeugt eine Launch Template, eine ASG über zwei Zonen und eine Target-Tracking-Richtlinie auf 50 Prozent CPU.

```bash
aws ec2 create-launch-template --launch-template-name web-vorlage \
  --launch-template-data '{"ImageId":"ami-0123456789abcdef0","InstanceType":"t3.micro","SecurityGroupIds":["sg-0123456789abcdef0"]}'

aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-asg \
  --launch-template LaunchTemplateName=web-vorlage,Version='$Latest' \
  --min-size 2 --max-size 6 --desired-capacity 2 \
  --vpc-zone-identifier "subnet-aaaa1111,subnet-bbbb2222"

aws autoscaling put-scaling-policy --auto-scaling-group-name web-asg \
  --policy-name cpu-50 --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":50.0}'
```

Die Launch Template legt fest, wie jede neue Instanz aussieht. Die Gruppe hält mindestens zwei und höchstens sechs Instanzen in zwei Subnetzen (also zwei Zonen) und startet anfangs zwei. Die Richtlinie sorgt dafür, dass bei höherer durchschnittlicher CPU-Auslastung Instanzen hinzukommen und bei niedriger wieder abgebaut werden, immer zwischen Minimum und Maximum. AMI-, Security-Group- und Subnetz-IDs sind Platzhalter.

### Typische Fehler.

Falsch: Das Minimum auf 1 zu setzen und trotzdem Hochverfügbarkeit zu erwarten; während des Ersatzes ist die Anwendung unterbrochen. Falsch: Zu enge Maxima, sodass die Gruppe bei Lastspitzen nicht mehr wächst. Falsch: Zustandsbehaftete Anwendungen (Sitzungen oder Dateien lokal im Server) hinter Auto Scaling zu betreiben; neue Instanzen kennen die Daten nicht. Richtig: Zustand in externe Dienste auslagern, wie DynamoDB, ElastiCache oder S3.

### Praxisbezug.

Ein Webshop startet mit zwei Servern, wächst während einer Aktion automatisch auf zehn und fällt danach zurück; der Betrieb muss nicht eingreifen.

## 4.4 Elastic Load Balancing

Läuft eine Anwendung auf mehreren Servern, muss jemand die Anfragen verteilen. *Elastic Load Balancing* (ELB) übernimmt diese Aufgabe: Es nimmt Anfragen unter einer einzigen Adresse entgegen und leitet sie an gesunde Ziele weiter. Der Load Balancer ist selbst über mehrere Availability Zones verteilt und ersetzt dadurch den einzelnen Server als Eintrittspunkt.

AWS bietet mehrere Typen. Der *Application Load Balancer* (ALB) arbeitet auf Schicht 7 des OSI-Modells (Anwendungsebene) und versteht HTTP und HTTPS. Er kann nach Pfad (`/api`), Host (`shop.beispiel.de`) oder Header entscheiden, unterstützt WebSockets und eignet sich für Webanwendungen und Container-Dienste. Der *Network Load Balancer* (NLB) arbeitet auf Schicht 4 (TCP, UDP, TLS), bewältigt extrem hohe Lasten mit sehr geringer Latenz und kann feste IP-Adressen (Elastic IPs) nutzen; er passt zu Spielen, IoT oder Protokollen jenseits von HTTP. Der *Gateway Load Balancer* (GWLB) verteilt Verkehr an Appliances von Drittanbietern, etwa Firewalls. Der *Classic Load Balancer* ist veraltet und für neue Projekte nicht mehr vorgesehen.

Die zentralen Bausteine sind *Listener*, *Target Groups* und *Health Checks*. Ein Listener wartet auf einem Port und Protokoll (zum Beispiel HTTPS 443) und wendet Regeln an. Eine Target Group ist eine Gruppe von Zielen (EC2-Instanzen, IP-Adressen, Lambda-Funktionen, Container), an die weitergeleitet wird. Der Health Check ruft regelmäßig einen Pfad (etwa `/health`) auf; antwortet ein Ziel nicht mit einem Erfolgscode, nimmt der Load Balancer es aus der Verteilung, bis es wieder gesund ist. Zusammen mit Auto Scaling ergibt sich das Standardmuster: Der Load Balancer verteilt, Auto Scaling hält die Anzahl der gesunden Server. TLS-Zertifikate lassen sich über AWS Certificate Manager (ACM) kostenlos bereitstellen und am Load Balancer terminieren.

Das folgende Beispiel baut einen Application Load Balancer mit einer Target Group und einem Listener.

```bash
aws elbv2 create-load-balancer --name web-alb --type application \
  --subnets subnet-aaaa1111 subnet-bbbb2222 \
  --security-groups sg-0aaaaaaaaaaaaaaaa

aws elbv2 create-target-group --name web-ziele --protocol HTTP --port 80 \
  --vpc-id vpc-0123456789abcdef0 --health-check-path /health

aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/web-alb/abc \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/web-ziele/def
```

Der erste Befehl erstellt den Load Balancer über zwei Subnetze (zwei Zonen) mit einer eigenen Security Group. Der zweite legt die Target Group an, die auf Port 80 prüft und für den Gesundheitscheck den Pfad `/health` verwendet. Der dritte erzeugt einen Listener, der alle Anfragen an die Target Group weiterleitet; die ARNs sind Platzhalter und stehen in den Ausgaben der vorherigen Befehle. Die Auto Scaling Group wird anschließend mit `--target-group-arns` an die Target Group gebunden.

### Typische Fehler.

Falsch: Den Load Balancer nur in einer Zone zu betreiben. Falsch: Den Health-Check-Pfad auf eine Seite zu setzen, die eine Anmeldung verlangt (liefert dann 302 oder 401 und alle Ziele gelten als defekt). Falsch: Die Security Group der Instanzen so zu setzen, dass sie nur Anfragen aus dem Internet statt vom Load Balancer erlaubt; richtig ist, die Instanz-Security-Group auf die Security Group des Load Balancers zu begrenzen.

### Praxisbezug.

Ein ALB leitet `/api/*` an eine Gruppe von Containern und alle übrigen Anfragen an einen Webserver, und beide sind über dieselbe Domain erreichbar.

## 4.5 Lambda Grundlagen

*AWS Lambda* führt Code aus, ohne dass man Server bereitstellt oder verwaltet. Man lädt eine Funktion hoch, legt fest, was sie auslöst, und AWS kümmert sich um alles Weitere: Betriebssystem, Skalierung, Hochverfügbarkeit, Patches. Das Modell heißt *serverlos* (Serverless), weil der Kunde keine Server sieht, obwohl es sie natürlich gibt. Lambda bedient sich dem Prinzip der *ereignisgesteuerten Verarbeitung*: Die Funktion läuft nur, wenn ein Ereignis eintrifft.

Auslöser (*Event Sources*) sind zahlreich. Eine Funktion kann von einem Datei-Upload in S3, einem HTTP-Aufruf über API Gateway, einer Nachricht in einer SQS-Warteschlange, einem Zeitplan in EventBridge oder einem Datenbank-Ereignis in DynamoDB gestartet werden. Typische Einsatzfälle sind Automatisierung (zum Beispiel nachts nicht benötigte Server stoppen), APIs, Datenverarbeitung (Bilder verkleinern, sobald sie hochgeladen werden) und Verarbeitung von Nachrichten. Jede Funktion hat eine *Ausführungsrolle*, die festlegt, was sie in AWS tun darf, und folgt damit dem Least-Privilege-Prinzip aus Modul 03.

Zu den wichtigsten Eigenschaften zählen: Die Ausführungsdauer ist auf höchstens 15 Minuten pro Aufruf begrenzt; der Arbeitsspeicher lässt sich zwischen 128 MB und 10 GB einstellen, wobei die CPU-Leistung proportional mitwächst. Abgerechnet wird nach Anzahl der Aufrufe und der Laufzeit in Millisekunden, multipliziert mit dem Speicher (GB-Sekunden); läuft nichts, kostet es nichts, und ein monatliches Gratiskontingent ist enthalten. Ein *Kaltstart* (Cold Start) beschreibt die Verzögerung beim ersten Aufruf, wenn eine neue Ausführungsumgebung vorbereitet werden muss; er fällt bei latenzempfindlichen Anwendungen ins Gewicht. Lambda skaliert automatisch durch parallele Ausführung, begrenzt durch Kontingente (*Concurrency*). Unterstützt werden Sprachen wie Python, Node.js, Java, .NET, Go, Ruby oder eigene Laufzeiten, außerdem Container-Images.

Das folgende Beispiel zeigt eine einfache Python-Funktion, deren Bereitstellung per CLI und einen Testaufruf.

```bash
cat > lambda_function.py <<'EOT'
def lambda_handler(event, context):
    name = event.get("name", "Welt")
    return {"statusCode": 200, "body": "Hallo " + name}
EOT
zip funktion.zip lambda_function.py

aws lambda create-function --function-name hallo \
  --runtime python3.12 --handler lambda_function.lambda_handler \
  --zip-file fileb://funktion.zip \
  --role arn:aws:iam::123456789012:role/lambda-ausfuehrung

aws lambda invoke --function-name hallo \
  --cli-binary-format raw-in-base64-out \
  --payload '{"name":"Anna"}' antwort.json
cat antwort.json
```

Die Funktion `lambda\_handler` ist der Einstiegspunkt; `event` enthält die Eingabedaten und `context` Informationen zur Ausführung. Beim Anlegen legt `--handler` fest, welche Funktion in welcher Datei aufgerufen wird (`datei.funktion`), `--runtime` die Sprachversion und `--role` die Ausführungsrolle (ein Platzhalter-ARN; die Rolle benötigt mindestens das Recht, Logs zu schreiben). Der Aufruf mit `invoke` übergibt eine Eingabe und schreibt die Antwort in die Datei. Die Laufzeitversion ändert sich im Lauf der Zeit; aktuelle Versionen stehen in der Dokumentation.

### Typische Fehler.

Falsch: Lambda für Aufgaben einzusetzen, die länger als 15 Minuten laufen; dafür eignen sich Container oder EC2. Falsch: Datenbankverbindungen bei jedem Aufruf neu aufzubauen. Falsch: Der Funktion Administratorrechte zu geben. Falsch: Lambda mit “unendlich skalierbar und immer billiger” gleichzusetzen; bei konstant hoher Last kann ein Server günstiger sein, und Kontingente begrenzen die Parallelität.

### Praxisbezug.

Sobald ein Foto in einen S3-Bucket hochgeladen wird, erzeugt eine Lambda-Funktion eine Vorschau und trägt Metadaten in eine DynamoDB-Tabelle ein. Es gibt keinen Server, der dafür bereitstehen oder gepatcht werden muss.

> **Merke**
>
> Lambda = ereignisgesteuert, serverlos, maximal 15 Minuten, Abrechnung nach Aufrufen und Laufzeit. Kaltstart kann Latenz erzeugen. Ausführungsrolle regelt die Rechte.

## 4.6 Container-Überblick

Ein *Container* verpackt eine Anwendung samt ihrer Abhängigkeiten (Bibliotheken, Laufzeitumgebung, Konfiguration) in ein einheitliches Paket, das überall gleich läuft. Anders als eine virtuelle Maschine bringt ein Container kein eigenes Betriebssystem mit, sondern teilt sich den Kernel des Hosts; deshalb startet er in Sekunden und braucht weniger Ressourcen. Das löst das klassische Problem “Bei mir lief es doch”: Entwicklung, Test und Produktion nutzen dasselbe Abbild (*Image*).

Containerabbilder liegen in einer Registry; bei AWS ist das *Amazon Elastic Container Registry* (ECR). Um viele Container zu betreiben, braucht man einen *Orchestrator*, der entscheidet, auf welchem Rechner welcher Container läuft, ausgefallene Container neu startet, skaliert und Updates ausrollt. AWS bietet zwei Orchestratoren. *Amazon Elastic Container Service* (ECS) ist die AWS-eigene, einfach gehaltene Lösung. *Amazon Elastic Kubernetes Service* (EKS) ist verwaltetes Kubernetes, der Quasi-Standard der Branche; er bietet große Flexibilität und Portabilität, ist aber komplexer.

Die zweite Frage lautet: Auf welchen Rechnern laufen die Container? Entweder auf EC2-Instanzen, die man selbst verwaltet, oder auf *AWS Fargate*, der serverlosen Laufumgebung für Container. Mit Fargate gibt man nur CPU und Speicher pro Container an, AWS stellt die Rechner bereit, patcht und skaliert sie. Das verschiebt die Verantwortung im Shared Responsibility Model weiter in Richtung AWS. Zusammengefasst: ECS oder EKS bestimmen *wie orchestriert wird*, EC2 oder Fargate *wo es läuft*.

Das folgende Beispiel zeigt ein minimales Dockerfile und die Schritte, ein Abbild nach ECR zu schieben und mit Fargate zu starten.

```bash
cat > Dockerfile <<'EOT'
FROM public.ecr.aws/docker/library/python:3.12-slim
WORKDIR /app
COPY app.py .
CMD ["python", "app.py"]
EOT

aws ecr create-repository --repository-name hallo-app
aws ecr get-login-password | docker login --username AWS \
  --password-stdin 123456789012.dkr.ecr.eu-central-1.amazonaws.com
docker build -t hallo-app .
docker tag hallo-app:latest 123456789012.dkr.ecr.eu-central-1.amazonaws.com/hallo-app:latest
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/hallo-app:latest

aws ecs create-cluster --cluster-name lern-cluster
```

Das Dockerfile beschreibt das Abbild: Basis ist ein Python-Image, `WORKDIR` legt das Arbeitsverzeichnis fest, `COPY` kopiert die Anwendung, und `CMD` bestimmt den Startbefehl. Danach wird ein ECR-Repository angelegt, die Anmeldung am Registry-Server geschieht mit einem temporären Passwort von AWS, und das Abbild wird gebaut, markiert und hochgeladen. Der Cluster ist die logische Gruppe, in der später Dienste und Aufgaben (*Tasks*) laufen; dafür fehlt noch eine Task-Definition, die Image, CPU, Speicher und Ports beschreibt, und ein Service, der die gewünschte Anzahl von Tasks hält. Kontonummer und Region sind Platzhalter.

### Typische Fehler.

Falsch: Container wie virtuelle Maschinen zu behandeln und Daten im Container zu speichern; beim Ersetzen sind sie weg. Richtig: Zustand in Volumes oder Datenbanken auslagern. Falsch: Images mit eingebackenen Passwörtern zu bauen. Falsch: Kubernetes zu wählen, obwohl ECS genügen würde. Falsch: “Fargate ist ein Orchestrator”; Fargate ist die Laufumgebung, der Orchestrator bleibt ECS oder EKS.

### Praxisbezug.

Ein Team zerlegt eine große Anwendung in kleine Dienste, packt jeden in ein Container-Image und betreibt sie auf ECS mit Fargate hinter einem Application Load Balancer; Updates werden ohne Ausfall nacheinander ausgerollt.

## 4.7 Elastic Beanstalk und App Runner

Nicht jedes Team will Server, Load Balancer und Skalierung einzeln konfigurieren. Plattformdienste (PaaS) nehmen diese Arbeit ab. *AWS Elastic Beanstalk* ist der klassische Vertreter: Man lädt seinen Anwendungscode hoch (zum Beispiel als ZIP für Java, Python, Node.js, .NET oder PHP oder als Docker-Container), und Beanstalk erstellt automatisch die nötige Umgebung mit EC2-Instanzen, Auto Scaling, Load Balancer und Überwachung. Der Kunde behält Zugriff auf die darunterliegenden Ressourcen und kann sie anpassen. Beanstalk selbst kostet nichts, bezahlt werden die erzeugten Ressourcen.

*AWS App Runner* geht noch einen Schritt weiter in Richtung Einfachheit: Man gibt ein Container-Image oder ein Code-Repository an, und der Dienst baut, stellt bereit, versieht die Anwendung mit einer HTTPS-Adresse, überwacht sie und skaliert sie nach Anfragen, bis hin zu Ruhezeiten mit minimalen Kosten. Es gibt praktisch keine Infrastruktur, die man sieht. Eine verwandte, noch einfachere Lösung für kleine Projekte ist *Amazon Lightsail*, das vorkonfigurierte virtuelle Server, Datenbanken und Netzwerk zu festen monatlichen Preisen bündelt.

Wie unterscheiden sich die Dienste von EC2 und von Container-Plattformen? Bei EC2 verwaltet der Kunde alles oberhalb der Hardware. Beanstalk automatisiert den Aufbau, lässt aber vollen Zugriff auf Instanzen und Einstellungen. ECS und EKS bieten feinere Kontrolle über Container-Architekturen mit mehr Einrichtungsaufwand. App Runner minimiert den Aufwand und die Wahlmöglichkeiten. Die Auswahl hängt davon ab, wie viel Kontrolle man braucht und wie viel Betrieb man abgeben möchte.

Das folgende Beispiel zeigt den Weg mit Beanstalk über die Elastic Beanstalk CLI (ein separates Werkzeug) und die Erstellung eines App-Runner-Dienstes aus einem Container-Image.

```bash
# Elastic Beanstalk (EB CLI)
eb init meine-app --platform python-3.12 --region eu-central-1
eb create test-umgebung
eb deploy
eb open

# App Runner aus einem ECR-Image
aws apprunner create-service --service-name hallo-runner \
  --source-configuration '{"ImageRepository":{"ImageIdentifier":"123456789012.dkr.ecr.eu-central-1.amazonaws.com/hallo-app:latest","ImageRepositoryType":"ECR","ImageConfiguration":{"Port":"8080"}},"AuthenticationConfiguration":{"AccessRoleArn":"arn:aws:iam::123456789012:role/apprunner-ecr-zugriff"}}'
```

`eb init` richtet das Projekt ein, `eb create` erstellt eine komplette Umgebung (Instanzen, Load Balancer, Auto Scaling), `eb deploy` lädt eine neue Version hoch, und `eb open` öffnet die Anwendung im Browser. Bei App Runner genügt ein einziger Befehl mit dem Pfad zum Image und der Rolle, die den Abruf aus ECR erlaubt; der Container muss auf dem angegebenen Port (hier 8080) lauschen. Namen, Konto-ID und Rolle sind Platzhalter. Die Plattformversionen ändern sich, der aktuelle Name steht in der Dokumentation.

### Typische Fehler.

Falsch: Beanstalk-Ressourcen von Hand zu verändern und beim nächsten Deployment zu überraschen; Änderungen sollten über die Konfiguration von Beanstalk erfolgen. Falsch: Beanstalk als “kostenlos” anzusehen; die Ressourcen darunter kosten Geld. Falsch: Eine Umgebung nach dem Test nicht zu löschen; sie läuft weiter und verursacht Kosten.

### Praxisbezug.

Ein kleines Team, das eine Webanwendung ohne Infrastrukturkenntnisse live bringen will, wählt Beanstalk oder App Runner. Muss es später feiner steuern, wechselt es zu ECS oder EC2.

## 4.8 Compute-Fehlerbilder

Fehler bei Compute-Diensten lassen sich in wenige Gruppen einteilen. Wer sie kennt, findet die Ursache meist in Minuten. Bei EC2 beginnt die Analyse mit der Frage: Startet die Instanz nicht, läuft sie, aber ist nicht erreichbar, oder läuft sie und die Anwendung antwortet nicht?

*Startfehler* äußern sich als Fehler beim `run-instances`-Aufruf oder als Instanz, die von `pending` sofort auf `terminated` geht. Häufige Meldungen sind `InstanceLimitExceeded` (Kontingent, zum Beispiel für vCPUs, ausgeschöpft; Abhilfe: Erhöhung über Service Quotas), `InsufficientInstanceCapacity` (aktuell keine Kapazität für den Typ in der Zone; Abhilfe: anderen Typ oder andere Zone wählen) und Fehler bei verschlüsselten Volumes, wenn der Schlüssel (KMS) nicht verwendet werden darf. Den Grund einer Beendigung zeigt `describe-instances` im Feld `StateReason`.

*Netzwerkfehler* sind der häufigste Grund für “Instanz nicht erreichbar”: Die Security Group erlaubt den Port nicht, die Network ACL blockiert, das Subnetz hat keine Route zum Internet Gateway, die Instanz besitzt keine öffentliche IP-Adresse, oder man benutzt den falschen Benutzernamen oder einen privaten Schlüssel mit zu offenen Dateirechten (SSH verlangt auf Linux `chmod 400`). *Statusprüfungen* helfen bei der Eingrenzung: Die *System-Statusprüfung* betrifft den Host (AWS-Seite, Abhilfe oft Stoppen und Starten, damit die Instanz auf einen anderen Host wandert), die *Instanz-Statusprüfung* die Software und das Betriebssystem (Kundenseite, zum Beispiel Kernel-Fehler oder volles Dateisystem). *Health-Check-Probleme* bei Load Balancern entstehen durch falschen Pfad oder Port, eine Security Group, die den Load Balancer nicht zulässt, oder eine Anwendung, die zu langsam startet (daher die Anlaufzeit *Grace Period* in Auto Scaling).

Bei Lambda sind die typischen Fehler: Zeitüberschreitung (`Task timed out`, Laufzeit der Funktion erhöhen oder Code verbessern), zu wenig Speicher (`Runtime exited with error: signal: killed`, mehr Speicher), fehlende Rechte (`AccessDeniedException` aus der Ausführungsrolle) und Drosselung (`TooManyRequestsException`, Parallelitätskontingent). Die Diagnosequellen sind *CloudWatch Logs* (jede Lambda-Ausführung schreibt dort), *CloudWatch Metrics* (Aufrufe, Fehler, Dauer, Drosselungen) und bei EC2 zusätzlich die Konsolenausgabe der Instanz.

Das folgende Beispiel zeigt die wichtigsten Befehle zur Diagnose.

```bash
aws ec2 describe-instance-status --instance-ids i-0123456789abcdef0 \
  --query 'InstanceStatuses[].{Sys:SystemStatus.Status,Inst:InstanceStatus.Status}'

aws ec2 get-console-output --instance-id i-0123456789abcdef0 --output text | tail -n 30

aws ec2 describe-instances --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[].Instances[].StateReason.Message'

aws logs tail /aws/lambda/hallo --since 15m
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/web-ziele/def
```

Die erste Abfrage zeigt, ob System- und Instanzprüfung bestehen. Die zweite gibt die letzten Zeilen der Konsolenausgabe aus, in der Boot-Fehler sichtbar werden. Die dritte nennt den Grund einer Beendigung. Mit `logs tail` liest man die Lambda-Logs der letzten fünfzehn Minuten, und `describe-target-health` zeigt für jedes Ziel einer Target Group, ob es gesund ist und, falls nicht, warum (zum Beispiel `Target.Timeout`). Die IDs sind Platzhalter.

### Typische Fehler.

Falsch: Bei “Instanz nicht erreichbar” sofort eine neue Instanz zu starten, ohne Security Group, Route und Statusprüfungen zu prüfen. Falsch: Lambda-Timeouts mit dem Maximalwert zu beheben, ohne die Ursache (zum Beispiel einen blockierten Netzwerkaufruf) zu suchen. Falsch: Logs nicht zu aktivieren; ohne Logs bleibt man blind.

### Praxisbezug.

Ein Bereitschaftsteam arbeitet eine feste Reihenfolge ab: Läuft die Instanz? Besteht die Statusprüfung? Ist der Load-Balancer-Check gesund? Was steht im Log? Jede Antwort grenzt die Ursache ein.

## Übungsaufgaben Modul 04

1.  Erklären Sie die Begriffe AMI, Instance Type und Key Pair mit je einem Satz.

2.  Ordnen Sie dem Lastprofil das passende Preismodell zu: (a) Datenbank-Server rund um die Uhr für drei Jahre, (b) nächtliche, unterbrechbare Batch-Berechnung, (c) kurzer Test für zwei Tage, (d) Software mit sockelgebundener Lizenz.

3.  Was bedeuten Minimum, Maximum und Desired Capacity einer Auto Scaling Group? Warum sollte das Minimum für Hochverfügbarkeit mindestens 2 sein?

4.  Worin unterscheiden sich Application Load Balancer und Network Load Balancer? Nennen Sie für beide einen typischen Einsatz.

5.  Nennen Sie drei Eigenschaften von AWS Lambda, die man bei der Entscheidung für oder gegen Lambda berücksichtigen sollte.

6.  **Praxis:** Schreiben Sie eine Lambda-Funktion in Python, die einen Namen aus dem Ereignis liest und eine Begrüßung zurückgibt, und die CLI-Befehle zum Anlegen und Testen.

7.  **Praxis:** Schreiben Sie das User-Data-Skript und die `run-instances`-Parameter, mit denen eine Instanz einen Webserver mit der Seite “Willkommen” startet. Welche Regel benötigt die Security Group?

8.  **Praxis:** Eine EC2-Instanz hinter einem ALB wird als `unhealthy` gemeldet. Beschreiben Sie Ihr Vorgehen und nennen Sie vier mögliche Ursachen. Nennen Sie außerdem die CLI-Befehle, mit denen Sie die Gesundheit der Ziele prüfen.

## Lösungen Modul 04

1.  AMI: Vorlage mit Betriebssystem und Software, aus der Instanzen starten. Instance Type: Hardware-Ausstattung (CPU, RAM, Netzwerk) und Familie. Key Pair: Schlüsselpaar für die Anmeldung, der private Teil bleibt beim Benutzer.

2.  \(a\) Savings Plan oder Reserved Instance mit drei Jahren; (b) Spot, weil unterbrechbar und günstig; (c) On-Demand, weil kurz und ohne Bindung; (d) Dedicated Host, weil die Lizenz an Sockel oder Kerne gebunden ist.

3.  Minimum: kleinste Zahl laufender Instanzen; Maximum: Obergrenze (auch Kostenschutz); Desired: aktuell angestrebte Zahl. Bei Minimum 1 ist die Anwendung unterbrochen, solange ein Ersatz startet; ab zwei Instanzen in zwei Zonen übersteht sie den Ausfall einer Instanz oder Zone.

4.  ALB: Schicht 7, HTTP/HTTPS, Routing nach Pfad oder Host, geeignet für Webanwendungen und Container-APIs. NLB: Schicht 4, TCP/UDP, sehr hohe Last und geringe Latenz, feste IP-Adressen, geeignet für Spiele oder nicht-HTTP-Protokolle.

5.  Zum Beispiel: maximal 15 Minuten Laufzeit; Abrechnung nach Aufrufen und Laufzeit (kostet nichts im Leerlauf); Kaltstarts können Latenz erzeugen; Skalierung ist automatisch, aber durch Kontingente begrenzt; AWS verwaltet Betriebssystem und Patches.

6.  Beispiellösung:

    ```bash
    cat > lambda_function.py <<'EOT'
    def lambda_handler(event, context):
        name = event.get("name", "Welt")
        return {"statusCode": 200, "body": "Hallo " + name}
    EOT
    zip funktion.zip lambda_function.py
    aws lambda create-function --function-name begruessung \
      --runtime python3.12 --handler lambda_function.lambda_handler \
      --zip-file fileb://funktion.zip \
      --role arn:aws:iam::123456789012:role/lambda-ausfuehrung
    aws lambda invoke --function-name begruessung \
      --cli-binary-format raw-in-base64-out \
      --payload '{"name":"Max"}' antwort.json && cat antwort.json
    ```

    Der Handler liest `name` mit einem Standardwert, damit die Funktion auch ohne Eingabe funktioniert.

7.  Beispiellösung:

    ```bash
    cat > ud.sh <<'EOT'
    #!/bin/bash
    dnf install -y httpd
    echo "Willkommen" > /var/www/html/index.html
    systemctl enable --now httpd
    EOT
    aws ec2 run-instances --image-id ami-0123456789abcdef0 \
      --instance-type t3.micro --user-data file://ud.sh \
      --security-group-ids sg-0123456789abcdef0 --subnet-id subnet-0123456789abcdef0
    ```

    Die Security Group braucht eine eingehende Regel für TCP Port 80 (HTTP), zum Beispiel aus dem Internet oder besser nur vom Load Balancer; für Wartung wäre Port 22 nur von der eigenen IP oder besser Session Manager.

8.  Vorgehen: (1) `aws elbv2 describe-target-health --target-group-arn ...` zeigt Grund wie Timeout oder falschen Antwortcode. (2) Health-Check-Pfad und Port in der Target Group prüfen. (3) Security Group der Instanz: erlaubt sie den Load Balancer (Quelle: Security Group des ALB)? (4) Auf der Instanz prüfen, ob die Anwendung läuft und auf dem Port lauscht, Logs lesen. (5) `describe-instance-status`: bestehen die Statusprüfungen? Ursachen: falscher Pfad oder Port; Security Group blockiert; Anwendung nicht gestartet oder Absturz; Anwendung startet langsamer als der Check (Grace Period); Pfad verlangt Anmeldung und liefert 302/401; volles Dateisystem.
