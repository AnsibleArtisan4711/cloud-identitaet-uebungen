# Modul 6 - Netzwerk, Connectivity und Content Delivery

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 10 h laut Modulübersicht (die Einheiten summieren sich laut Detailblatt auf 9 h)

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit                      | Dauer (h) |
|----:|:---------------------------------|----------:|
| 6.1 | VPC Grundlagen                   |      1,25 |
| 6.2 | Subnetze und Routing             |      1,25 |
| 6.3 | Internet Gateway und NAT Gateway |      1,25 |
| 6.4 | Security Groups und NACLs        |      1,25 |
| 6.5 | VPC Endpoints                    |         1 |
| 6.6 | DNS mit Route 53                 |         1 |
| 6.7 | Hybrid Connectivity              |         1 |
| 6.8 | Netzwerk-Troubleshooting         |         1 |
|     | **Summe der Einheiten**          |     **9** |

> **Merke**
>
> Hinweis zum Lehrplan: Die Modulübersicht nennt 10 Stunden, die Einheiten im Detailblatt ergeben 9 Stunden. Alle acht Einheiten sind vollständig behandelt; die Differenz ist für Übungen und Nacharbeit gedacht.

Jede AWS-Anwendung läuft in einem Netzwerk, und viele Fehler und Sicherheitsvorfälle entstehen dort. Dieses Modul erklärt, wie das virtuelle Netzwerk von AWS aufgebaut ist: von der abgeschlossenen Netzwerkinsel (VPC) über Teilnetze, Routen und Internetzugänge bis zu den Filtern, die Verkehr zulassen oder blockieren. Danach folgen private Zugänge zu AWS-Diensten, DNS, die Anbindung an das eigene Rechenzentrum und die systematische Fehlersuche. Der Content-Delivery-Dienst CloudFront wurde bereits in Modul 02 behandelt und wird hier nur an der passenden Stelle erwähnt. Die Grundbegriffe Region und Availability Zone aus Modul 02 werden vorausgesetzt.

## 6.1 VPC Grundlagen

Eine *Amazon Virtual Private Cloud* (VPC) ist ein logisch isoliertes, privates Netzwerk innerhalb einer AWS-Region, das der Kunde selbst gestaltet. Man kann sich eine VPC wie ein eigenes Firmennetz vorstellen, das zufällig in einem AWS-Rechenzentrum liegt: Es hat einen eigenen Adressbereich, eigene Teilnetze, eigene Routing-Regeln und eigene Firewalls. Ressourcen in verschiedenen VPCs können sich standardmäßig nicht sehen, auch nicht innerhalb desselben Kontos. Eine VPC erstreckt sich über alle Availability Zones einer Region, ihre Teilnetze dagegen liegen jeweils in genau einer Zone.

Der Adressbereich wird als *CIDR-Block* angegeben, zum Beispiel `10.0.0.0/16`. Die Schreibweise besteht aus einer IP-Adresse und der Anzahl der Bits, die das Netz festlegen. Ein IPv4-Adresse hat 32 Bit; bei `/16` sind 16 Bit fest, 16 Bit stehen für Geräte zur Verfügung, was rund 65.000 Adressen ergibt. Bei `/24` sind es 256 Adressen, bei `/28` nur 16. Eine VPC erlaubt Blöcke zwischen `/16` und `/28`. Als Adressbereiche verwendet man die privaten Bereiche nach RFC 1918: `10.0.0.0/8`, `172.16.0.0/12` und `192.168.0.0/16`, die im Internet nicht geroutet werden. Die Planung des Adressraums ist wichtig, weil sich überlappende Bereiche später nicht verbinden lassen (zum Beispiel per VPC Peering oder VPN). Wer mehrere VPCs oder ein lokales Netz koppeln will, plant daher überschneidungsfreie Bereiche.

In jedem Konto und jeder Region legt AWS automatisch eine *Default-VPC* an (Bereich `172.31.0.0/16`), mit je einem öffentlichen Subnetz pro Zone und einem Internetzugang. Sie ist praktisch zum Ausprobieren, aber für ernsthafte Anwendungen legt man eigene VPCs an, damit die Struktur bewusst gestaltet ist. Die Komponenten einer VPC sind Teilnetze (Subnets), Routing-Tabellen, Internet- und NAT-Gateways, Sicherheitsgruppen und Netzwerk-ACLs, Endpunkte und Verbindungen. Dazu kommt *IPv6*: VPCs können zusätzlich zu IPv4 einen globalen IPv6-Bereich erhalten, dessen Adressen öffentlich sind.

Das folgende Beispiel legt eine VPC mit DNS-Unterstützung an und zeigt die Ausgabe der wichtigsten Eigenschaften.

```bash
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lern-vpc}]' \
  --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC --enable-dns-hostnames
aws ec2 describe-vpcs --vpc-ids $VPC \
  --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock,Standard:IsDefault}'
```

`create-vpc` erzeugt die VPC mit dem Bereich `10.0.0.0/16` und liefert ihre ID, die in der Variablen `VPC` gespeichert wird. `--enable-dns-hostnames` sorgt dafür, dass Instanzen mit öffentlicher IP einen DNS-Namen erhalten. Die letzte Abfrage zeigt, dass es sich nicht um die Default-VPC handelt. Eine VPC allein ist noch nicht nutzbar; es fehlen Teilnetze und Verbindungen, die in den nächsten Einheiten entstehen.

### Typische Fehler.

Falsch: Alle VPCs mit `10.0.0.0/16` anzulegen; später ist keine Kopplung möglich. Falsch: Den Block zu klein zu wählen (`/24`), sodass er nicht mehr erweitert werden kann; zusätzliche Blöcke lassen sich zwar nachträglich anfügen, aber das Planen spart Mühe. Falsch: Die Default-VPC für Produktion zu verwenden. Falsch: Anzunehmen, dass zwei VPCs im selben Konto automatisch miteinander reden.

### Praxisbezug.

Ein Unternehmen vergibt jeder Umgebung einen eigenen Bereich (Produktion `10.1.0.0/16`, Test `10.2.0.0/16`, Entwicklung `10.3.0.0/16`) und dokumentiert die Vergabe in einer Adresstabelle, damit später ein Transit Gateway alle verbinden kann.

> **Merke**
>
> VPC = eigenes virtuelles Netz in einer Region. CIDR-Block von /16 bis /28, private RFC-1918-Bereiche, nicht überlappend planen. Default-VPC existiert automatisch, eigene VPCs sind der Normalfall.

## 6.2 Subnetze und Routing

Ein *Subnetz* ist ein Teilbereich des VPC-Adressraums, der in genau einer Availability Zone liegt. Man teilt eine VPC in Subnetze, um Ressourcen nach Aufgabe und Sicherheitsstufe zu trennen und gleichzeitig auf mehrere Zonen zu verteilen. In jedem Subnetz reserviert AWS fünf Adressen (die ersten vier und die letzte); in einem `/24`-Subnetz bleiben also 251 nutzbar.

Man unterscheidet *öffentliche* und *private* Subnetze. Der Unterschied liegt nicht im Namen, sondern in der Routing-Tabelle: Ein Subnetz ist öffentlich, wenn seine Routing-Tabelle eine Route ins Internet über ein Internet Gateway enthält. Ein Subnetz ohne solche Route ist privat. Typisch ist die Dreiteilung: öffentliche Subnetze für Load Balancer, private Subnetze für Anwendungsserver und weitere private Subnetze für Datenbanken, die nie direkt aus dem Internet erreichbar sein sollen.

Eine *Routing-Tabelle* (Route Table) besteht aus Regeln, die einem Zielbereich ein Ziel zuordnen. Jede Tabelle enthält automatisch die Route `local` für den VPC-Bereich, damit alle Teilnetze der VPC untereinander kommunizieren können. Weitere Routen verweisen zum Beispiel für `0.0.0.0/0` (alles) auf ein Internet Gateway, ein NAT Gateway oder eine Verbindung zum Firmennetz. Bei mehreren passenden Routen gewinnt die spezifischste, also mit dem längsten Präfix. Jedes Subnetz ist genau einer Routing-Tabelle zugeordnet; wird keine angegeben, gilt die Haupttabelle der VPC. Es empfiehlt sich, die Haupttabelle privat zu halten und öffentliche Routen nur gezielt zuzuordnen.

Die folgende Skizze zeigt eine typische Aufteilung:

```text
VPC 10.0.0.0/16
 |-- Zone a: oeffentlich 10.0.1.0/24   privat 10.0.11.0/24
 |-- Zone b: oeffentlich 10.0.2.0/24   privat 10.0.12.0/24
 Route (oeffentlich): 10.0.0.0/16 -> local ; 0.0.0.0/0 -> Internet Gateway
 Route (privat):      10.0.0.0/16 -> local ; 0.0.0.0/0 -> NAT Gateway
```

Dieses Muster, mit zwei Zonen für Ausfallsicherheit, ist die Grundlage der meisten AWS-Architekturen. Das Anlegen sieht in der CLI so aus:

```bash
S1=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 \
  --availability-zone eu-central-1a --query Subnet.SubnetId --output text)
S2=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.11.0/24 \
  --availability-zone eu-central-1a --query Subnet.SubnetId --output text)

RT=$(aws ec2 create-route-table --vpc-id $VPC \
  --query RouteTable.RouteTableId --output text)
aws ec2 associate-route-table --route-table-id $RT --subnet-id $S1
aws ec2 describe-route-tables --route-table-ids $RT \
  --query 'RouteTables[].Routes[]'
```

Es werden zwei Subnetze in Zone a angelegt: `S1` soll öffentlich werden, `S2` privat. Eine eigene Routing-Tabelle wird erzeugt und mit `S1` verknüpft; `describe-route-tables` zeigt zunächst nur die `local`-Route. Erst mit dem Internet Gateway aus der nächsten Einheit wird `S1` tatsächlich öffentlich. Die Variable `VPC` stammt aus dem vorigen Beispiel.

### Typische Fehler.

Falsch: Ein Subnetz “öffentlich” zu nennen, ohne die Route zum Internet Gateway anzulegen. Falsch: Alle Ressourcen, auch Datenbanken, in öffentliche Subnetze zu legen. Falsch: Subnetze nur in einer Zone anzulegen und damit die Hochverfügbarkeit zu verspielen. Falsch: Die fünf reservierten Adressen zu vergessen, wenn man kleine Subnetze (`/28`) berechnet.

### Praxisbezug.

Beim Anlegen einer Datenbank verlangt RDS eine *DB-Subnetzgruppe* mit Subnetzen in mindestens zwei Zonen. Hat man von Anfang an private Subnetze in mehreren Zonen angelegt, ist das schnell erledigt.

## 6.3 Internet Gateway und NAT Gateway

Damit eine VPC mit dem Internet sprechen kann, braucht sie ein *Internet Gateway* (IGW). Es ist eine redundante, skalierbare Komponente, die man an die VPC hängt und die zwei Aufgaben übernimmt: Es bietet in der Routing-Tabelle ein Ziel für Internetverkehr und übersetzt die private Adresse einer Instanz in ihre öffentliche Adresse und zurück. Damit eine Instanz erreichbar ist, müssen vier Bedingungen zusammentreffen: ein Internet Gateway an der VPC, eine Route `0.0.0.0/0` zum Gateway in der Routing-Tabelle des Subnetzes, eine öffentliche oder Elastic-IP-Adresse an der Instanz und eine Security Group sowie NACL, die den Verkehr erlauben. Fehlt eine, ist die Verbindung unmöglich. Eine *Elastic IP* ist eine feste öffentliche IPv4-Adresse, die man behalten kann; normale öffentliche Adressen wechseln beim Stoppen der Instanz. Für öffentliche IPv4-Adressen berechnet AWS inzwischen eine Gebühr, daher sollte man sie sparsam verwenden.

Private Ressourcen brauchen oft trotzdem ausgehenden Internetzugang, etwa um Updates zu laden oder externe Dienste aufzurufen, sollen aber nicht von außen erreichbar sein. Dafür gibt es das *NAT Gateway* (Network Address Translation). Es steht in einem *öffentlichen* Subnetz, besitzt eine Elastic IP, und die Routing-Tabelle der privaten Subnetze leitet `0.0.0.0/0` dorthin. Die Instanz im privaten Subnetz sendet Anfragen ans NAT Gateway, das sie mit seiner eigenen öffentlichen Adresse ins Internet weitergibt und Antworten zurückleitet; Verbindungen aus dem Internet zu den privaten Instanzen sind nicht möglich. Ein NAT Gateway ist zonengebunden, für Hochverfügbarkeit legt man deshalb pro Zone eines an. Es kostet pro Betriebsstunde und pro verarbeitetem Gigabyte, was in Rechnungen oft überrascht. Für IPv6 gibt es das *Egress-only Internet Gateway*, das ausgehenden, aber keinen eingehenden Verkehr erlaubt. Eine ältere Alternative zum NAT Gateway ist die *NAT-Instanz*, die man selbst betreibt; sie ist heute kaum noch sinnvoll.

Das folgende Beispiel macht das Subnetz `S1` öffentlich und gibt `S2` über ein NAT Gateway ausgehenden Zugang.

```bash
IGW=$(aws ec2 create-internet-gateway \
  --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
aws ec2 create-route --route-table-id $RT \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 modify-subnet-attribute --subnet-id $S1 --map-public-ip-on-launch

EIP=$(aws ec2 allocate-address --query AllocationId --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id $S1 --allocation-id $EIP \
  --query NatGateway.NatGatewayId --output text)
RT2=$(aws ec2 create-route-table --vpc-id $VPC \
  --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $RT2 \
  --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT
aws ec2 associate-route-table --route-table-id $RT2 --subnet-id $S2
```

Zuerst wird ein Internet Gateway erzeugt, an die VPC gehängt und in der öffentlichen Routing-Tabelle `RT` als Standardroute eingetragen; `--map-public-ip-on-launch` weist neuen Instanzen im Subnetz automatisch eine öffentliche Adresse zu. Danach reserviert man eine Elastic IP, legt das NAT Gateway in `S1` an (dem öffentlichen Subnetz!) und trägt in einer zweiten Tabelle `RT2` die Standardroute für das private Subnetz `S2` ein. Das NAT Gateway braucht einige Minuten, bis es verfügbar ist; vorher schlägt das Anlegen der Route fehl. Variablen stammen aus den vorigen Beispielen.

### Typische Fehler.

Falsch: Das NAT Gateway in ein privates Subnetz zu setzen; es hat dann keinen Weg ins Internet. Falsch: Ein NAT Gateway für alle Zonen zu teilen und damit eine Zone zum Single Point of Failure zu machen. Falsch: Datenbanken öffentliche Adressen zu geben, “damit es geht”. Falsch: Zu vergessen, dass NAT Gateway laufende Kosten verursacht, auch wenn kaum Verkehr fließt.

### Praxisbezug.

Anwendungsserver in privaten Subnetzen laden Updates über ein NAT Gateway, sind aber nur über den Load Balancer im öffentlichen Subnetz erreichbar. Zur Kostensenkung leitet man Verkehr zu S3 und DynamoDB über Gateway-Endpunkte (siehe übernächste Einheit) am NAT Gateway vorbei.

> **Merke**
>
> IGW = Weg ins Internet (Route und öffentliche IP nötig). NAT Gateway = ausgehender Zugang für private Subnetze, steht im öffentlichen Subnetz, zonengebunden, kostet Stunden und Daten.

## 6.4 Security Groups und NACLs

AWS bietet zwei Filterebenen für Netzwerkverkehr. Beide verhalten sich unterschiedlich, und dieser Unterschied ist ein Prüfungsklassiker.

Eine *Security Group* (SG) ist eine virtuelle Firewall auf Ebene der Netzwerkschnittstelle einer Ressource (Instanz, Datenbank, Load Balancer). Sie enthält nur *Erlaubnisregeln*: Eingehend ist alles verboten, was nicht ausdrücklich erlaubt ist, und ausgehend ist standardmäßig alles erlaubt. Verboten-Regeln gibt es nicht. Eine Security Group ist *zustandsbehaftet* (stateful): Wird eine Verbindung eingehend erlaubt, darf die Antwort automatisch zurück, ohne dass eine eigene ausgehende Regel nötig wäre. Regeln können als Quelle nicht nur IP-Bereiche, sondern auch andere Security Groups nennen. Das ist sehr mächtig: “Die Datenbank akzeptiert Port 5432 von der Gruppe der Anwendungsserver” bleibt gültig, egal wie viele Server es gibt und welche Adressen sie haben. Alle Regeln einer Gruppe werden zusammen ausgewertet, und eine Ressource kann mehreren Gruppen angehören.

Eine *Network ACL* (NACL) ist eine Firewall auf Ebene des *Subnetzes*. Sie enthält nummerierte Regeln mit `Allow` oder `Deny`, die in aufsteigender Reihenfolge geprüft werden; die erste passende gewinnt, danach kommt eine nicht entfernbare Regel mit Ablehnung für alles Übrige. Eine NACL ist *zustandslos* (stateless): Eingehender und ausgehender Verkehr werden unabhängig bewertet, Antworten brauchen eine eigene Regel, auch für die kurzlebigen Antwortports (Ephemeral Ports, üblicherweise 1024 bis 65535). Die voreingestellte NACL erlaubt allen Verkehr; neue selbst angelegte NACLs verbieten zunächst alles. Man setzt NACLs gezielt ein, etwa um eine bestimmte Adresse oder einen Bereich zu sperren, was mit Security Groups nicht geht.

|            | Security Group                      | Network ACL                           |
|:-----------|:------------------------------------|:--------------------------------------|
| Ebene      | Netzwerkschnittstelle der Ressource | Subnetz                               |
| Regeln     | nur Allow                           | Allow und Deny, nummeriert            |
| Zustand    | stateful                            | stateless                             |
| Auswertung | alle Regeln zusammen                | der Reihe nach, erste Übereinstimmung |
| Standard   | eingehend aus, ausgehend an         | Standard-NACL: alles erlaubt          |

Das folgende Beispiel richtet das übliche Zwei-Schichten-Muster ein: Der Load Balancer nimmt HTTPS aus dem Internet an, die Anwendungsserver nehmen Verkehr nur vom Load Balancer an.

```bash
SG_ALB=$(aws ec2 create-security-group --group-name alb-sg \
  --description "Load Balancer" --vpc-id $VPC \
  --query GroupId --output text)
SG_APP=$(aws ec2 create-security-group --group-name app-sg \
  --description "Anwendungsserver" --vpc-id $VPC \
  --query GroupId --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_ALB \
  --protocol tcp --port 443 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_APP \
  --protocol tcp --port 8080 --source-group $SG_ALB

# NACL: eine bestimmte Adresse sperren
NACL=$(aws ec2 create-network-acl --vpc-id $VPC \
  --query NetworkAcl.NetworkAclId --output text)
aws ec2 create-network-acl-entry --network-acl-id $NACL --ingress \
  --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny
```

Zwei Gruppen entstehen. Die erste erlaubt eingehend Port 443 aus dem ganzen Internet. Die zweite erlaubt Port 8080 nur von Ressourcen, die der Gruppe des Load Balancers angehören; direkte Zugriffe aus dem Internet sind damit unmöglich. Die NACL-Regel 90 sperrt eine Adresse (aus dem Dokumentationsbereich) vollständig; da die Prüfung der Reihe nach erfolgt, muss die Sperre eine kleinere Nummer haben als eine allgemeine Erlaubnis. Die neue NACL wirkt erst, wenn man sie einem Subnetz zuordnet und zusätzlich alle nötigen Erlaubnisregeln anlegt, da sie sonst alles blockiert.

### Typische Fehler.

Falsch: Port 22 oder 3389 für `0.0.0.0/0` zu öffnen; Verwaltungszugang gehört auf die eigene Adresse oder über Session Manager. Falsch: In einer NACL die Rückrichtung zu vergessen, weil sie zustandslos ist. Falsch: Mit einer Security Group einen Angreifer sperren zu wollen; das geht nur mit NACL oder AWS WAF. Falsch: Alle Ressourcen in einer einzigen Security Group zu bündeln.

### Praxisbezug.

Die meisten Teams arbeiten fast nur mit Security Groups und halten die NACLs im Standard; erst bei Compliance-Vorgaben oder zum Sperren einzelner Adressen kommen spezielle NACL-Regeln hinzu.

## 6.5 VPC Endpoints

Wenn eine Instanz im privaten Subnetz S3 oder DynamoDB nutzt, läuft der Verkehr standardmäßig über das NAT Gateway und das Internet zur öffentlichen Adresse des Dienstes. Das ist unnötig und riskant: Es kostet Geld und der Verkehr verlässt das private Netz. *VPC Endpoints* schaffen einen privaten Weg direkt zu AWS-Diensten, ohne Internet Gateway, NAT Gateway oder öffentliche Adressen. Der Verkehr bleibt im AWS-Netz.

Es gibt zwei Arten. Ein *Gateway Endpoint* existiert nur für Amazon S3 und Amazon DynamoDB. Er wird als Ziel in der Routing-Tabelle eingetragen (statt einer Netzwerkschnittstelle) und ist kostenlos. Ein *Interface Endpoint* (basiert auf AWS PrivateLink) legt in den gewählten Subnetzen eine Netzwerkschnittstelle mit einer privaten IP-Adresse an und funktioniert für sehr viele Dienste (zum Beispiel Systems Manager, Secrets Manager, ECR, CloudWatch) sowie für eigene Dienste und Partnerangebote. Er verursacht Stunden- und Datenkosten. Interface Endpoints sind über Security Groups absicherbar, und mit aktivierter privater DNS-Option lösen die gewohnten Dienstnamen automatisch auf die privaten Adressen auf, sodass keine Änderung am Anwendungscode nötig ist. Zusätzlich kann man Endpunkt-Richtlinien setzen, die einschränken, welche Aktionen und Ressourcen über den Endpunkt erreichbar sind, und in Bucket-Policies mit der Bedingung `aws:SourceVpce` den Zugriff auf einen bestimmten Endpunkt begrenzen.

Das folgende Beispiel erstellt einen Gateway Endpoint für S3 und einen Interface Endpoint für den Systems Manager.

```bash
aws ec2 create-vpc-endpoint --vpc-id $VPC \
  --service-name com.amazonaws.eu-central-1.s3 \
  --vpc-endpoint-type Gateway --route-table-ids $RT2

aws ec2 create-vpc-endpoint --vpc-id $VPC \
  --service-name com.amazonaws.eu-central-1.ssm \
  --vpc-endpoint-type Interface --subnet-ids $S2 \
  --security-group-ids $SG_APP --private-dns-enabled
```

Der erste Befehl erzeugt den Gateway Endpoint für S3 und trägt ihn in der Routing-Tabelle `RT2` ein; ab dann fließen S3-Zugriffe der Instanzen im zugehörigen Subnetz nicht mehr über das NAT Gateway. Der zweite legt einen Interface Endpoint für Systems Manager in `S2` an, mit der Security Group `SG\_APP` und privatem DNS. Die Security Group des Endpunkts muss Port 443 von den Instanzen erlauben. Servicenamen folgen dem Muster `com.amazonaws.REGION.DIENST`.

### Typische Fehler.

Falsch: Einen Gateway Endpoint anzulegen, ihn aber keiner Routing-Tabelle zuzuordnen. Falsch: Einen Interface Endpoint ohne passende Security-Group-Regel für Port 443 zu betreiben. Falsch: Für S3 teure NAT-Gateway-Datenverarbeitung zu bezahlen, obwohl ein kostenloser Gateway Endpoint existiert. Falsch: Anzunehmen, ein Endpunkt erlaube automatisch jeden Zugriff; Berechtigungen bleiben IAM-Sache.

### Praxisbezug.

In Umgebungen ohne Internetzugang (etwa für streng regulierte Daten) laufen Server in Subnetzen ohne NAT und erreichen S3, ECR und Systems Manager ausschließlich über Endpunkte.

## 6.6 DNS mit Route 53

Das *Domain Name System* (DNS) übersetzt Namen wie `shop.beispiel.de` in IP-Adressen. *Amazon Route 53* ist der DNS-Dienst von AWS: hochverfügbar, global über das Edge-Netz verteilt und mit dem Anspruch einer Verfügbarkeit von 100 Prozent für die Namensauflösung. Er erfüllt drei Aufgaben: Domänen registrieren, DNS-Einträge verwalten und die Gesundheit von Zielen prüfen.

Die Einträge liegen in einer *Hosted Zone*, die eine Domäne darstellt. Eine *öffentliche* Hosted Zone beantwortet Anfragen aus dem Internet, eine *private* Hosted Zone nur innerhalb zugeordneter VPCs und eignet sich für interne Namen wie `db.intern.local`. Die gängigen Eintragstypen (Records) sind: `A` (Name zu IPv4-Adresse), `AAAA` (IPv6), `CNAME` (Name zu anderem Namen, nicht für den Zonen-Apex), `MX` (Mail), `TXT` (Text, etwa für Verifizierungen) und `NS` (zuständige Namensserver). Eine Besonderheit von Route 53 ist der *Alias-Eintrag*: Er zeigt kostenfrei auf AWS-Ressourcen wie CloudFront, Load Balancer oder S3-Websites, funktioniert auch am Zonen-Apex (`beispiel.de`) und passt sich automatisch an, wenn sich die Adressen der Ressource ändern.

Spannend wird Route 53 durch die *Routing-Richtlinien*. *Simple* liefert einen Wert. *Weighted* verteilt Anfragen nach Gewichten, etwa 90 Prozent auf die alte, 10 Prozent auf die neue Version. *Latency* sendet Nutzer in die Region mit der geringsten Latenz. *Failover* leitet bei einem ausgefallenen primären Ziel auf ein sekundäres um. *Geolocation* entscheidet nach dem Standort des Nutzers (zum Beispiel Inhalte nach Land), *Geoproximity* nach geografischer Nähe mit einstellbarer Verschiebung, und *Multivalue Answer* liefert mehrere gesunde Adressen. Die Entscheidung stützt sich auf *Health Checks*, die Ziele regelmäßig prüfen und defekte aus den Antworten nehmen. Weil DNS die Voraussetzung für fast jeden Zugriff ist, gilt es als kritische Abhängigkeit: Ein falscher Eintrag oder eine lange TTL (Zeit, die Antworten zwischengespeichert werden) kann ganze Dienste unerreichbar machen.

Das folgende Beispiel legt eine Hosted Zone an und erstellt zwei gewichtete Einträge.

```bash
aws route53 create-hosted-zone --name beispiel.de \
  --caller-reference "lern-$(date +%s)"

cat > aenderung.json <<'EOT'
{ "Changes": [
  { "Action": "UPSERT", "ResourceRecordSet": {
      "Name": "www.beispiel.de", "Type": "A", "TTL": 60,
      "SetIdentifier": "alt", "Weight": 90,
      "ResourceRecords": [{"Value": "203.0.113.10"}] } },
  { "Action": "UPSERT", "ResourceRecordSet": {
      "Name": "www.beispiel.de", "Type": "A", "TTL": 60,
      "SetIdentifier": "neu", "Weight": 10,
      "ResourceRecords": [{"Value": "203.0.113.20"}] } }
] }
EOT
aws route53 change-resource-record-sets \
  --hosted-zone-id Z0123456789ABCDEFGHIJ --change-batch file://aenderung.json
```

`create-hosted-zone` legt die Zone an; die `caller-reference` verhindert versehentliche Doppelanlage. Die Änderungsdatei enthält zwei `A`-Einträge für denselben Namen mit unterschiedlichen `SetIdentifier` und Gewichten 90 und 10; `UPSERT` legt neu an oder aktualisiert. Die IP-Adressen stammen aus dem Dokumentationsbereich, die Zonen-ID ist ein Platzhalter. Nach dem Anlegen der Zone muss man bei der Domainregistrierung die vier zugewiesenen Namensserver eintragen.

### Typische Fehler.

Falsch: Einen CNAME auf den Zonen-Apex zu setzen (nicht erlaubt); dafür nimmt man einen Alias. Falsch: Sehr lange TTL-Werte vor einer Umstellung beizubehalten; die alte Adresse bleibt dann lange im Cache. Falsch: Die Namensserver der Hosted Zone nicht beim Registrar einzutragen. Falsch: Failover einzurichten, ohne einen Health Check zu hinterlegen.

### Praxisbezug.

Bei einer Migration verteilt eine gewichtete Richtlinie anfangs zehn Prozent der Nutzer auf das neue System; bei Fehlern setzt man das Gewicht in Sekunden auf null zurück.

## 6.7 Hybrid Connectivity

In Modul 02 wurden Hybrid-Szenarien begrifflich eingeführt; hier folgt die technische Sicht auf die Verbindungsarten und auf die Verknüpfung mehrerer VPCs.

Das *AWS Site-to-Site VPN* baut zwei verschlüsselte IPsec-Tunnel zwischen dem Firmennetz und der VPC auf. Auf AWS-Seite endet es an einem *Virtual Private Gateway* oder einem Transit Gateway, auf Firmenseite am *Customer Gateway* (dem eigenen Router oder der Firewall). Die Einrichtung dauert Minuten bis Stunden, die Kosten sind gering, aber der Verkehr läuft über das öffentliche Internet, sodass Bandbreite und Latenz schwanken. *AWS Direct Connect* ist eine dedizierte, private Glasfaserverbindung zwischen dem Rechenzentrum und einem AWS-Standort. Sie bietet konstante Latenz und hohe Bandbreite (von 50 Mbit/s über Partner bis zu 100 Gbit/s), umgeht das Internet, braucht aber Wochen bis zur Bereitstellung und ist teurer; sie ist standardmäßig nicht verschlüsselt. Wer höchste Verfügbarkeit braucht, kombiniert zwei Direct-Connect-Leitungen an verschiedenen Standorten oder Direct Connect mit VPN als Reserve.

Zum Verbinden von VPCs gibt es zwei Wege. *VPC Peering* verbindet genau zwei VPCs direkt (auch zwischen Konten und Regionen); es ist einfach und günstig, aber *nicht transitiv*: Ist A mit B und B mit C verbunden, kann A nicht automatisch C erreichen, und die Adressbereiche dürfen sich nicht überlappen. Bei vielen VPCs wird das unübersichtlich. Das *AWS Transit Gateway* ist ein zentraler Verteiler (Hub), an den man beliebig viele VPCs, VPNs und Direct-Connect-Verbindungen anschließt; die Verbindung ist transitiv und lässt sich über Routing-Tabellen steuern. Es verursacht Stunden- und Datenkosten, vereinfacht aber große Umgebungen erheblich. Für die Namensauflösung zwischen lokalem Netz und Cloud nutzt man den *Route 53 Resolver* mit eingehenden und ausgehenden Endpunkten.

Das folgende Beispiel zeigt den Aufbau einer Peering-Verbindung samt der nötigen Routen, die in beiden VPCs eingetragen werden müssen.

```bash
PCX=$(aws ec2 create-vpc-peering-connection \
  --vpc-id vpc-0aaa1111bbb22222c --peer-vpc-id vpc-0ddd3333eee44444f \
  --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PCX

aws ec2 create-route --route-table-id rtb-0aaa1111 \
  --destination-cidr-block 10.2.0.0/16 --vpc-peering-connection-id $PCX
aws ec2 create-route --route-table-id rtb-0ddd3333 \
  --destination-cidr-block 10.1.0.0/16 --vpc-peering-connection-id $PCX
```

Die erste VPC (Bereich `10.1.0.0/16`) fordert die Verbindung zur zweiten (`10.2.0.0/16`) an; die zweite nimmt sie an (im selben Konto genügt der Befehl, bei fremden Konten muss der Eigentümer der anderen Seite akzeptieren). Anschließend braucht jede Seite eine Route zum Bereich der anderen. Security Groups müssen den Verkehr zusätzlich erlauben. Alle IDs sind Platzhalter.

### Typische Fehler.

Falsch: Peering nach dem Anlegen für fertig zu halten, ohne Routen und Security-Group-Regeln einzutragen. Falsch: Transitives Verhalten zu erwarten. Falsch: Direct Connect als verschlüsselt zu betrachten. Falsch: Überlappende CIDR-Bereiche zu koppeln. Falsch: Für kritische Anbindungen nur einen einzelnen Tunnel oder eine einzelne Leitung zu nutzen.

### Praxisbezug.

Ein Konzern mit vierzig VPCs und zwei Rechenzentren verbindet alles über ein Transit Gateway; neue Konten hängen sich per Freigabe an, ohne dass jede Beziehung einzeln eingerichtet werden muss.

## 6.8 Netzwerk-Troubleshooting

Netzwerkfehler wirken oft mysteriös, lassen sich aber systematisch eingrenzen. Der Verkehr durchläuft eine Kette von Stationen, und an jeder kann er scheitern. Man arbeitet die Kette von der Quelle zum Ziel ab: Namensauflösung, Routing, Filter am Ausgang der Quelle, Filter am Eingang des Ziels, schließlich die Anwendung selbst.

Der erste Schritt ist die *Namensauflösung*: Stimmt der DNS-Eintrag, und zeigt er auf die richtige Adresse (`nslookup` oder `dig`)? Danach das *Routing*: Hat das Subnetz der Quelle eine Route zum Ziel (Internet Gateway, NAT, Peering, Endpoint)? Danach die *Filter*: Erlaubt die Security Group der Quelle den ausgehenden Verkehr (meist ja), erlaubt die Security Group des Ziels den eingehenden Verkehr auf dem richtigen Port, und blockiert keine NACL in beiden Richtungen? Zuletzt die Anwendung: Läuft der Dienst und lauscht er auf dem erwarteten Port und der richtigen Adresse (nicht nur `127.0.0.1`)? Eine Zeitüberschreitung (*Timeout*) deutet meist auf Filter oder Routing hin, weil Pakete verworfen werden; eine abgelehnte Verbindung (*Connection refused*) deutet darauf hin, dass das Ziel erreicht wird, aber dort kein Dienst auf dem Port lauscht.

AWS bietet zwei besonders nützliche Werkzeuge. Der *VPC Reachability Analyzer* prüft die Konfiguration zwischen zwei Endpunkten und zeigt, ob und wo ein Pfad blockiert ist (zum Beispiel “Security Group sg-... erlaubt Port 443 nicht”), ohne dass tatsächlich Pakete gesendet werden. *VPC Flow Logs* protokollieren den Netzwerkverkehr an VPC, Subnetz oder Schnittstelle mit Quell- und Zieladresse, Port, Protokoll und der Entscheidung `ACCEPT` oder `REJECT`. Ein `REJECT` im Eingang des Ziels belegt, dass ein Filter blockiert; fehlen Einträge ganz, kamen die Pakete nie an (Routing oder Quellseite). Flow Logs enthalten keine Paketinhalte.

Das folgende Beispiel zeigt das Einrichten von Flow Logs und einer Analyse mit dem Reachability Analyzer.

```bash
aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC \
  --traffic-type REJECT --log-destination-type cloud-watch-logs \
  --log-group-name /vpc/flowlogs \
  --deliver-logs-permission-arn arn:aws:iam::123456789012:role/flowlogs-rolle

PFAD=$(aws ec2 create-network-insights-path --source i-0aaa1111 \
  --destination i-0bbb2222 --protocol tcp --destination-port 5432 \
  --query NetworkInsightsPath.NetworkInsightsPathId --output text)
ANALYSE=$(aws ec2 start-network-insights-analysis \
  --network-insights-path-id $PFAD \
  --query NetworkInsightsAnalysis.NetworkInsightsAnalysisId --output text)
aws ec2 describe-network-insights-analyses \
  --network-insights-analysis-ids $ANALYSE \
  --query 'NetworkInsightsAnalyses[].{Erreichbar:NetworkPathFound,Erklaerung:Explanations[].ExplanationCode}'
```

Der erste Befehl zeichnet alle abgelehnten Verbindungen der VPC in CloudWatch Logs auf; die Rolle muss das Schreiben erlauben (Platzhalter). Der Reachability Analyzer prüft den Pfad von Instanz `i-0aaa1111` zu `i-0bbb2222` auf Port 5432 (PostgreSQL). Das Ergebnis zeigt, ob ein Pfad gefunden wurde und, falls nicht, einen Code wie `ENI\_SG\_RULES\_MISMATCH`, der auf eine fehlende Security-Group-Regel hinweist. Die Analyse kostet pro Durchlauf eine kleine Gebühr.

> **Praxisbeispiel**
>
> Eine Anwendung erreicht die Datenbank nicht (Timeout). Der Reachability Analyzer meldet, dass die Security Group der Datenbank Port 5432 nicht von der Anwendungsgruppe erlaubt. Nach Ergänzung der Regel `--source-group` funktioniert die Verbindung sofort; ohne das Werkzeug wäre die Ursache erst nach längerem Prüfen von Routing, NACLs und Anwendung gefunden worden.

### Typische Fehler.

Falsch: Bei Problemen sofort alle Ports freizugeben. Falsch: Zu vergessen, dass NACLs zustandslos sind und Antwortports erlaubt sein müssen. Falsch: Nur auf der Zielseite zu suchen und die Route der Quelle nicht zu prüfen. Falsch: Flow Logs erst nach dem Vorfall zu aktivieren; sie liefern nur Daten ab dem Einschalten.

### Praxisbezug.

Ein Betriebs-Runbook für “Dienst nicht erreichbar” beginnt mit DNS, prüft Route, Security Groups, NACLs, Flow Logs und endet bei der Anwendung. Diese feste Reihenfolge spart Zeit in Störungen.

## Übungsaufgaben Modul 06

1.  Erklären Sie, woran man ein öffentliches von einem privaten Subnetz unterscheidet.

2.  Wie viele nutzbare Adressen hat ein `/24`-Subnetz in AWS und warum?

3.  Nennen Sie fünf Unterschiede zwischen Security Group und Network ACL.

4.  Wozu dient ein NAT Gateway, wo muss es stehen, und welches Risiko entsteht bei nur einem einzigen für zwei Zonen?

5.  Was ist der Unterschied zwischen Gateway Endpoint und Interface Endpoint? Für welche Dienste gibt es Gateway Endpoints?

6.  **Praxis:** Schreiben Sie die CLI-Befehle für eine VPC `10.10.0.0/16` mit je einem öffentlichen und privaten Subnetz in zwei Zonen (vier Subnetze).

7.  **Praxis:** Schreiben Sie Security-Group-Regeln für eine Drei-Schichten-Anwendung: ALB (HTTPS aus dem Internet), Anwendung (Port 8080 nur vom ALB), Datenbank (Port 5432 nur von der Anwendung).

8.  **Praxis:** Ein Server im privaten Subnetz kann `aws s3 ls` nicht ausführen (Timeout). Beschreiben Sie Ihre Fehlersuche und nennen Sie mindestens vier mögliche Ursachen sowie zwei Lösungswege.

## Lösungen Modul 06

1.  Ein Subnetz ist öffentlich, wenn seine Routing-Tabelle eine Route `0.0.0.0/0` zu einem Internet Gateway enthält (und die Ressourcen eine öffentliche Adresse haben). Ohne diese Route ist es privat.

2.  251, denn AWS reserviert in jedem Subnetz fünf Adressen: Netzwerkadresse, VPC-Router, DNS, reserviert für künftige Nutzung und Broadcast-Adresse.

3.  Ebene (Schnittstelle gegen Subnetz), Regeltyp (nur Allow gegen Allow und Deny), Zustand (stateful gegen stateless), Auswertung (alle Regeln gegen nummerierte Reihenfolge), Quelle kann eine Security Group sein (nur bei SG), Standard (eingehend verboten gegen Standard-NACL erlaubt alles).

4.  Es ermöglicht ausgehenden Internetzugang für private Subnetze, ohne Erreichbarkeit von außen. Es muss in einem öffentlichen Subnetz stehen (mit Elastic IP). Mit nur einem NAT Gateway ist eine Zone Single Point of Failure: Fällt sie aus, verlieren die Server der anderen Zone ihren ausgehenden Zugang; zudem fällt Zonen-übergreifender Datenverkehr an.

5.  Gateway Endpoint: Eintrag in der Routing-Tabelle, kostenlos, nur für S3 und DynamoDB. Interface Endpoint: Netzwerkschnittstelle mit privater IP (PrivateLink), für viele Dienste und eigene Angebote, kostenpflichtig, mit Security Group.

6.  ```bash
    V=$(aws ec2 create-vpc --cidr-block 10.10.0.0/16 --query Vpc.VpcId --output text)
    for spec in "10.10.1.0/24 eu-central-1a" "10.10.2.0/24 eu-central-1b" \
                "10.10.11.0/24 eu-central-1a" "10.10.12.0/24 eu-central-1b"; do
      set -- $spec
      aws ec2 create-subnet --vpc-id $V --cidr-block $1 --availability-zone $2
    done
    ```

    Die ersten beiden Subnetze werden öffentlich (Internet Gateway, Route, öffentliche Routing-Tabelle zuordnen), die anderen beiden privat (eigene Tabelle, ggf. NAT Gateway).

7.  ```bash
    aws ec2 authorize-security-group-ingress --group-id $SG_ALB \
      --protocol tcp --port 443 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id $SG_APP \
      --protocol tcp --port 8080 --source-group $SG_ALB
    aws ec2 authorize-security-group-ingress --group-id $SG_DB \
      --protocol tcp --port 5432 --source-group $SG_APP
    ```

    Die Verweise auf Security Groups statt IP-Bereiche bleiben gültig, auch wenn Server wechseln.

8.  Vorgehen: Fehlermeldung und Region prüfen; Route zum Ziel prüfen (NAT Gateway oder Gateway Endpoint für S3 in der Tabelle des Subnetzes?); NACL in beiden Richtungen; ausgehende Regeln der Security Group; Rolle der Instanz hat S3-Recht (sonst AccessDenied statt Timeout); Flow Logs und Reachability Analyzer. Ursachen: fehlende Route zum NAT Gateway; NAT Gateway im falschen (privaten) Subnetz; Gateway Endpoint nicht der Routing-Tabelle zugeordnet; NACL blockiert; Security Group verbietet ausgehend; falscher Endpoint-Name oder fehlendes privates DNS. Lösungen: Gateway Endpoint für S3 anlegen und der Tabelle zuordnen (kostenlos und privat) oder NAT Gateway im öffentlichen Subnetz mit Route einrichten.
