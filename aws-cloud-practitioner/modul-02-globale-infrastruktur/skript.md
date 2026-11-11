# Modul 2 - Globale Infrastruktur und Bereitstellungsmodelle

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 7 h

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit                       | Dauer (h) |
|----:|:----------------------------------|----------:|
| 2.1 | Regionen und Availability Zones   |         1 |
| 2.2 | Edge Locations und CloudFront     |         1 |
| 2.3 | Multi-AZ vs. Multi-Region         |         1 |
| 2.4 | Service-Verfügbarkeit je Region   |         1 |
| 2.5 | AWS Global Infrastructure Tools   |      0,75 |
| 2.6 | Hybrid- und Cloud-Betriebsmodelle |      0,75 |
| 2.7 | Resilienz-Basics                  |      0,75 |
| 2.8 | Datenresidenz und Standortwahl    |      0,75 |
|     | **Summe**                         |     **7** |

Dieses Modul erklärt, wie AWS weltweit aufgebaut ist und wie man diesen Aufbau nutzt, um Anwendungen schnell, ausfallsicher und rechtskonform zu betreiben. Die Begriffe Region, Availability Zone und Edge Location gehören zum Pflichtwissen für die Prüfung und tauchen in fast jeder späteren Architekturentscheidung wieder auf. Auf das Shared Responsibility Model aus Modul 01 wird hier mehrfach Bezug genommen, auf Hybrid-Verbindungen wird in Modul 06 vertieft eingegangen.

## 2.1 Regionen und Availability Zones

Eine *AWS-Region* ist ein geografisches Gebiet, in dem AWS mehrere voneinander getrennte Rechenzentrumsstandorte betreibt. Beispiele sind Frankfurt (`eu-central-1`), Irland (`eu-west-1`), Stockholm (`eu-north-1`) oder Nord-Virginia (`us-east-1`). Jede Region ist vollständig unabhängig von den anderen: Ein Ausfall oder eine Fehlkonfiguration in Frankfurt wirkt sich nicht auf Irland aus, und Daten, die in einer Region liegen, verlassen diese nicht, solange der Kunde sie nicht aktiv verschiebt oder repliziert.

Innerhalb einer Region gibt es mehrere *Availability Zones* (AZ). Eine Availability Zone besteht aus einem oder mehreren eigenständigen Rechenzentren mit eigener Stromversorgung, Kühlung und Netzwerkanbindung. Die Zonen einer Region liegen weit genug auseinander, dass ein lokales Ereignis wie ein Brand oder Stromausfall nicht alle gleichzeitig trifft, aber nah genug beieinander, dass sie über schnelle, redundante Glasfaserverbindungen mit sehr geringer Latenz verbunden sind. Dadurch kann man Daten synchron zwischen den Zonen spiegeln, ohne dass die Anwendung spürbar langsamer wird. Eine Region hat in der Regel mindestens drei Availability Zones; die genaue Anzahl und die Gesamtzahl der Regionen wächst laufend und ist deshalb in der offiziellen Übersicht nachzuschlagen.

Warum diese Zweiteilung? Die Region beantwortet die Frage “Wo auf der Welt laufen meine Daten und Server?”. Sie bestimmt Latenz zu den Nutzern, rechtliche Rahmenbedingungen, Preise und die Verfügbarkeit von Diensten. Die Availability Zone beantwortet die Frage “Wie überlebe ich den Ausfall eines Standorts?”. Wer seine Server auf mehrere Zonen verteilt, übersteht den Ausfall eines einzelnen Rechenzentrums ohne Unterbrechung. Zusätzlich gibt es *Local Zones*, kleine Erweiterungen von Regionen in Ballungsräumen für sehr niedrige Latenz, und *Wavelength Zones*, die Rechenleistung in 5G-Netze der Mobilfunkanbieter bringen.

Regionen mit Kennungen, die nach März 2019 eingeführt wurden, sind standardmäßig deaktiviert und müssen im Konto aktiviert werden (*Opt-in Regions*). Bei der Auswahl hilft ein Blick auf die Befehle der CLI, die alle Regionen und Zonen auflisten. Das folgende Beispiel zeigt beides.

```bash
aws ec2 describe-regions --all-regions \
  --query 'Regions[].{Name:RegionName,Status:OptInStatus}' --output table
aws ec2 describe-availability-zones --region eu-central-1 \
  --query 'AvailabilityZones[].{Zone:ZoneName,Id:ZoneId,State:State}' \
  --output table
```

Die erste Abfrage listet alle Regionen einschließlich der noch nicht aktivierten und zeigt, ob eine Region als `opt-in-not-required`, `opted-in` oder `not-opted-in` gilt. Die zweite Abfrage listet die Zonen von Frankfurt. Ausgegeben werden sowohl der Name (zum Beispiel `eu-central-1a`) als auch die `ZoneId` (zum Beispiel `euc1-az1`). Das ist wichtig, weil AWS die Zonennamen pro Konto zufällig auf physische Zonen abbildet: Die “1a” meines Kontos muss nicht dieselbe Zone sein wie die “1a” eines anderen Kontos. Wer Konten koordinieren will, nutzt deshalb die Zone-ID.

### Typische Fehler.

Falsch ist die Gleichsetzung “Availability Zone = ein Rechenzentrum”; sie kann aus mehreren Gebäuden bestehen. Falsch ist auch, anzunehmen, dass alle Ressourcen automatisch auf mehrere Zonen verteilt werden. Ein einzelner EC2-Server läuft in genau einer Zone; die Verteilung muss der Kunde entwerfen. Richtig: Für Hochverfügbarkeit mindestens zwei Zonen nutzen.

### Praxisbezug.

Beim Anlegen eines Subnetzes (Modul 06) wählt man ausdrücklich die Zone. Ein Architekt legt je Zone ein Subnetz an und verteilt Server und Datenbanken darauf.

> **Merke**
>
> Region = geografisches Gebiet, unabhängig von anderen Regionen. AZ = ein oder mehrere Rechenzentren in einer Region, getrennt, aber niedrige Latenz. Daten bleiben in der Region, bis der Kunde sie verschiebt.

## 2.2 Edge Locations und CloudFront

Neben den Regionen betreibt AWS ein dichtes Netz von *Edge Locations* (Standorte am Rand des Netzwerks, nahe bei den Endnutzern). Sie sind keine Regionen und führen keine EC2-Server des Kunden aus. Sie dienen dazu, Inhalte auszuliefern und Anfragen schneller zu beantworten, als es aus einer fernen Region möglich wäre. Dahinter liegen zusätzlich *Regional Edge Caches*, größere Zwischenspeicher, die zwischen den Edge Locations und dem Ursprung liegen.

Der wichtigste Dienst, der Edge Locations nutzt, ist *Amazon CloudFront*, ein Content Delivery Network (CDN). Ein CDN speichert Kopien von Inhalten (Bilder, Videos, Skripte, ganze Webseiten) an vielen Orten weltweit und liefert sie von dem Standort, der dem Nutzer am nächsten liegt. Wie funktioniert das? Ein Nutzer in Wien ruft eine Webseite auf, deren Ursprung (*Origin*) ein S3-Bucket in Irland ist. Die Anfrage trifft zunächst die nächstgelegene Edge Location. Hat sie den Inhalt im Cache (*Cache Hit*), antwortet sie sofort. Fehlt er (*Cache Miss*), holt sie ihn vom Ursprung, speichert ihn für die Dauer der eingestellten Lebenszeit (*TTL*, Time to Live) und liefert ihn aus. Der nächste Nutzer in der Nähe bekommt die Kopie bereits aus dem Cache.

Das spart Latenz, entlastet den Ursprung und kann Kosten senken, weil weniger Daten direkt aus der Region fließen. Zusätzlich bietet CloudFront Schutz gegen DDoS-Angriffe (AWS Shield Standard ist ohne Aufpreis enthalten), Verschlüsselung per HTTPS und kann mit AWS WAF kombiniert werden. Ein verwandter Dienst ist *AWS Global Accelerator*: Er hält keinen Inhalt im Cache, sondern leitet Verkehr über das schnelle AWS-Backbone-Netz zur nächstgelegenen gesunden Anwendung. Auch Route 53 nutzt das weltweite Netz für DNS-Antworten.

Das nächste Beispiel zeigt, wie man in der CLI eine Distribution anlegt und später einen veralteten Inhalt aus dem Cache entfernt. Der erste Befehl erzeugt eine einfache Distribution für eine bestehende S3-Domäne, der zweite löscht (*invalidiert*) die Datei `/index.html` in allen Edge Locations.

```bash
aws cloudfront create-distribution \
  --origin-domain-name mein-lernbucket-2026-12345.s3.amazonaws.com \
  --default-root-object index.html
aws cloudfront create-invalidation \
  --distribution-id E1ABCDEFGHIJKL --paths "/index.html"
```

Mit `--origin-domain-name` wird der Ursprung bestimmt, mit `--default-root-object` die Datei, die bei Aufruf der Hauptadresse geliefert wird. Die Distributions-ID im zweiten Befehl ist ein Platzhalter. Ohne Invalidierung würde ein geänderter Inhalt erst nach Ablauf der TTL sichtbar.

### Typische Fehler.

Falsch: “CloudFront beschleunigt auch dynamische Schreibzugriffe automatisch”. Hauptnutzen ist das Cachen lesbarer Inhalte; für dynamische Inhalte hilft vor allem die Anbindung über das AWS-Netz. Ebenfalls falsch: Änderungen an einer Datei sofort erwarten, ohne TTL oder Invalidierung zu beachten. Richtig: Dateien mit Versionsnummer im Namen (zum Beispiel `app.v2.js`) ausliefern, damit kein manueller Eingriff nötig ist.

### Praxisbezug.

Eine Nachrichtenseite liefert Titelbilder und Skripte über CloudFront aus. Bei einem Besucheransturm bleibt der Ursprung entlastet, die Seite lädt weltweit schnell.

## 2.3 Multi-AZ vs. Multi-Region

Resilienz lässt sich auf zwei Ebenen herstellen: über mehrere Availability Zones einer Region oder über mehrere Regionen. Beide Ansätze lösen unterschiedliche Probleme und kosten unterschiedlich viel.

Eine *Multi-AZ-Architektur* verteilt Komponenten auf mindestens zwei Zonen derselben Region. Beispiele sind eine Auto-Scaling-Gruppe, die Server in mehreren Zonen startet, ein Load Balancer, der Verkehr auf Server in mehreren Zonen verteilt, oder eine RDS-Datenbank mit Multi-AZ-Option, die automatisch eine synchrone Kopie in einer anderen Zone hält und bei Ausfall dorthin umschaltet. Dank der geringen Latenz zwischen den Zonen ist das einfach, kostet wenig zusätzlichen Betriebsaufwand und schützt vor dem Ausfall eines Standorts. Es schützt aber nicht vor einem Problem, das eine ganze Region betrifft, etwa eine großflächige Störung eines regionalen Dienstes.

Eine *Multi-Region-Architektur* betreibt die Anwendung in mindestens zwei Regionen. Sie schützt vor dem Ausfall einer gesamten Region, verringert die Latenz für weltweit verteilte Nutzer und erfüllt unter Umständen Anforderungen an die Datenlokalität. Der Preis ist deutlich höher: Daten müssen zwischen Regionen repliziert werden (und das ist asynchron, also mit einer kleinen Verzögerung), Datenübertragung zwischen Regionen kostet Geld, und die Anwendung wird komplexer, etwa wegen Konfliktlösung bei gleichzeitigen Schreibzugriffen. Typische Bausteine sind S3 Cross-Region Replication, DynamoDB Global Tables, Aurora Global Database und Route 53 mit Failover-Routing.

Die Entscheidung folgt den Anforderungen an Verfügbarkeit und Wiederherstellung. Dafür gibt es zwei Kennzahlen, die in Modul 12 vertieft werden: *RTO* (Recovery Time Objective, wie lange darf die Wiederherstellung dauern) und *RPO* (Recovery Point Objective, wie viel Datenverlust ist tolerierbar). Für die meisten Anwendungen genügt Multi-AZ. Multi-Region lohnt sich bei geschäftskritischen Systemen, strengen Vorgaben oder globalem Publikum.

Wie die Verteilung in der Praxis beschrieben wird, zeigt ein Befehl, der eine RDS-Datenbank mit Multi-AZ anlegt, und eine Replikation eines Buckets in eine zweite Region. Zunächst die Datenbank:

```bash
aws rds create-db-instance \
  --db-instance-identifier lern-db \
  --engine mysql --db-instance-class db.t3.micro \
  --allocated-storage 20 \
  --master-username admin --manage-master-user-password \
  --multi-az
```

Der entscheidende Schalter ist `--multi-az`: AWS legt eine zweite Instanz in einer anderen Zone an und hält sie synchron aktuell. `--manage-master-user-password` lässt AWS das Passwort im Secrets Manager verwalten, sodass kein Passwort im Befehl steht. Für Multi-Region würde man zusätzlich in der Zielregion einen Bucket anlegen und per `put-bucket-replication` eine Replikationsregel setzen; dafür müssen beide Buckets versioniert sein.

### Typische Fehler.

Falsch: “Multi-AZ schützt vor Regionsausfällen”. Richtig: Multi-AZ schützt vor dem Ausfall einer Zone, Multi-Region vor dem Ausfall einer Region. Falsch: “Multi-Region bedeutet automatisch, dass alles synchron ist”. Die Replikation zwischen Regionen ist in der Regel asynchron, es kann also Datenverlust im Sekundenbereich geben. Und: Multi-AZ ersetzt keine Backups; ein versehentlich gelöschter Datensatz ist in beiden Zonen gelöscht.

### Praxisbezug.

Ein Online-Shop betreibt seine Datenbank Multi-AZ in Frankfurt und hält zusätzlich eine kleine Notfallumgebung in Irland bereit, die nur im Katastrophenfall hochgefahren wird.

## 2.4 Service-Verfügbarkeit je Region

Nicht alle Dienste und Funktionen stehen in jeder Region zur Verfügung. Neue Dienste starten meist zuerst in großen Regionen wie Nord-Virginia, Irland oder Frankfurt und kommen später in weitere. Auch Preise unterscheiden sich pro Region, manchmal deutlich. Bevor man sich auf eine Region festlegt, sollte man deshalb prüfen, ob die benötigten Dienste dort verfügbar sind.

Die zuverlässigste Quelle ist die offizielle *AWS Regional Services List* (auch Region Table genannt) auf der AWS-Webseite. Zusätzlich kann man die Verfügbarkeit direkt per CLI abfragen. Ein Dienst, der in der Wunschregion fehlt, zwingt zu Kompromissen: andere Region wählen, einen ähnlichen Dienst nutzen oder die Funktion auslagern. Die Abhängigkeiten sind oft indirekt; ein Dienst, der selbst verfügbar ist, kann einen anderen voraussetzen, der es nicht ist.

Außerdem gibt es *globale Dienste*, die keiner einzelnen Region zugeordnet sind, etwa IAM, Route 53, CloudFront oder AWS Organizations. Ihre Steuerungsebene (*Control Plane*) liegt oft in einer bestimmten Region (zum Beispiel Nord-Virginia), was bei Ausfällen relevant sein kann.

Das folgende Beispiel nutzt öffentliche Parameter im Systems Manager Parameter Store, die AWS für die Abfrage der globalen Infrastruktur bereitstellt, und prüft, ob ein bestimmter Dienst in einer Region angeboten wird.

```bash
aws ssm get-parameters-by-path \
  --path /aws/service/global-infrastructure/regions/eu-central-1/services \
  --query 'Parameters[].Name' --region us-east-1 --max-items 20
aws ssm get-parameter \
  --name /aws/service/global-infrastructure/regions/eu-central-1/services/lambda \
  --region us-east-1
```

Die erste Abfrage listet Dienste, die in Frankfurt angeboten werden. Die zweite fragt gezielt nach Lambda; kommt ein Eintrag zurück, existiert der Dienst dort, kommt ein Fehler (`ParameterNotFound`), nicht. Die Parameter sind öffentlich und lassen sich mit gültigen AWS-Zugangsdaten abfragen; hier wird `us-east-1` als Abfrageregion verwendet. Wie bei allen Beispielen gilt: Pfade und Verhalten können sich ändern, im Zweifel gilt die Dokumentation.

### Typische Fehler.

Falsch: Eine Architektur zeichnen, bevor man die Verfügbarkeit geprüft hat; dann scheitert später die Umsetzung. Falsch ist auch, die günstigste Region zu wählen, ohne Latenz und Datenschutz zu berücksichtigen.

### Praxisbezug.

Vor dem Start eines Projekts erstellt das Team eine Liste der geplanten Dienste und prüft jeden für die Zielregion. Das dauert eine halbe Stunde und erspart später Umplanungen.

## 2.5 AWS Global Infrastructure Tools

Wer Anwendungen auf AWS betreibt, muss verstehen, wie er Informationen über Störungen und Wartungen findet. Dazu gibt es mehrere Werkzeuge. Die *Region Table* und die Seite zur globalen Infrastruktur zeigen, welche Regionen und Dienste existieren. Das *AWS Health Dashboard* zeigt, ob AWS-Dienste aktuell gestört sind (*Service Health*, öffentlich einsehbar) und welche Ereignisse das eigene Konto betreffen (*Your Account Health*, nach Anmeldung). Zu letzteren zählen geplante Wartungen, Ablaufdaten (zum Beispiel einer eingestellten Funktion) und Hinweise zu einzelnen Ressourcen.

Ereignisse haben eine Kategorie: “Issue” für laufende Störungen, “Scheduled change” für geplante Wartungen und “Account notification” für Hinweise. Wichtig ist die Unterscheidung zwischen einem Problem von AWS (Region oder Dienst gestört) und einem Problem des eigenen Kontos oder der eigenen Konfiguration. Bei einem Ausfall prüft man deshalb zuerst die Health-Anzeige, bevor man die eigene Anwendung debuggt.

Automatisierung ist möglich: Health-Ereignisse lassen sich über Amazon EventBridge an Benachrichtigungen (SNS, E-Mail, Chat) oder Automatisierungen weiterleiten. Die Health-API ist allerdings nur für Konten mit Business-, Enterprise-On-Ramp- oder Enterprise-Support verfügbar. Das folgende Beispiel zeigt beides: das Abrufen offener Ereignisse und eine Regel, die Health-Ereignisse an ein SNS-Thema schickt.

```bash
aws health describe-events --region us-east-1 \
  --filter eventStatusCodes=open --query 'events[].{Svc:service,Type:eventTypeCode}'
aws events put-rule --name health-ereignisse \
  --event-pattern '{"source":["aws.health"]}'
```

Die erste Zeile fragt offene Ereignisse ab und gibt nur Dienst und Ereignistyp aus; die Health-API erreicht man über die Region `us-east-1`. Die zweite Zeile legt eine EventBridge-Regel an, die auf alle Ereignisse der Quelle `aws.health` reagiert; als Nächstes würde man mit `put-targets` ein SNS-Thema als Ziel eintragen.

### Typische Fehler.

Falsch ist, bei jeder Auffälligkeit die eigene Anwendung zu ändern, ohne den Health-Status zu prüfen. Ebenso falsch: Geplante Wartungen ignorieren, die den Neustart von Instanzen erzwingen; dann überrascht die Störung zur falschen Zeit.

### Praxisbezug.

Ein Betriebsteam leitet Health-Ereignisse in den Teamchat und schaut bei Störungsmeldungen zuerst dort nach, ob AWS selbst ein Problem meldet.

## 2.6 Hybrid- und Cloud-Betriebsmodelle

Aufbauend auf den Deployment-Modellen aus Modul 01 betrachtet diese Einheit die technische Umsetzung. Ein Hybrid-Betrieb verlangt, dass lokales Netzwerk und Cloud wie ein gemeinsames Netz funktionieren. Dafür gibt es zwei Grundbausteine. Ein *Site-to-Site VPN* verbindet das Firmennetz über das öffentliche Internet mit einem virtuellen Netz in AWS, wobei der Datenverkehr verschlüsselt (IPsec) wird. Es ist schnell eingerichtet und günstig, hängt aber von der Qualität der Internetverbindung ab. *AWS Direct Connect* ist eine dedizierte, private Leitung vom Rechenzentrum zu AWS; sie bietet gleichbleibende Latenz und hohe Bandbreite, braucht aber Wochen für die Bereitstellung und verursacht höhere Kosten. Oft kombiniert man beides: Direct Connect als Hauptweg, VPN als Reserve.

Neben der Netzwerkverbindung gibt es Dienste, die AWS-Funktionen in die eigene Umgebung bringen. *AWS Outposts* installiert AWS-Hardware im eigenen Rechenzentrum und betreibt dort AWS-Dienste mit denselben APIs. *AWS Storage Gateway* verbindet lokale Systeme mit Cloud-Speicher, sodass zum Beispiel Backups transparent in S3 landen. *Hybrid DNS* sorgt dafür, dass Namen lokal und in der Cloud gegenseitig aufgelöst werden, was mit Route 53 Resolver möglich ist. Wer Verwaltung vereinheitlichen will, nutzt Systems Manager, um lokale Server wie Cloud-Instanzen zu verwalten.

Als Gegenstück zum Hybridbetrieb dient der reine *Cloud-Betrieb*, bei dem Teams ihr gesamtes Portfolio in AWS fahren. Dazwischen liegt der Weg vieler Unternehmen: Man beginnt hybrid und verschiebt Workloads Schritt für Schritt. Die Entscheidung, was zuerst umzieht, folgt Kriterien wie Komplexität, Abhängigkeiten und Nutzen (siehe Modul 12).

Zur Illustration ein verkürzter Aufbau einer VPN-Verbindung per CLI. Er zeigt die drei beteiligten Objekte: das Gateway auf AWS-Seite, die Beschreibung des lokalen Routers und die Verbindung selbst.

```bash
aws ec2 create-vpn-gateway --type ipsec.1
aws ec2 create-customer-gateway --type ipsec.1 \
  --public-ip 203.0.113.12 --bgp-asn 65000
aws ec2 create-vpn-connection --type ipsec.1 \
  --customer-gateway-id cgw-0123456789abcdef0 \
  --vpn-gateway-id vgw-0123456789abcdef0 \
  --options StaticRoutesOnly=true
```

Das *Virtual Private Gateway* ist der VPN-Endpunkt auf AWS-Seite, das *Customer Gateway* beschreibt den lokalen Router (hier mit der Dokumentations-IP `203.0.113.12`). Die Verbindung verknüpft beide; mit `StaticRoutesOnly=true` werden Routen statisch statt über BGP gepflegt. IDs sind Platzhalter, und in der Praxis fehlen noch Routen und die Konfiguration des lokalen Routers.

### Typische Fehler.

Falsch: “Direct Connect ist verschlüsselt”. Direct Connect ist privat, aber nicht automatisch verschlüsselt; wer Verschlüsselung braucht, setzt zusätzlich VPN oder MACsec ein. Falsch ist auch, das VPN als einzige Verbindung für geschäftskritische Anwendungen ohne Reserve zu nutzen.

### Praxisbezug.

Eine Filiale nutzt VPN, die Zentrale Direct Connect; für Notfälle sind beide gegenseitig als Reserve eingerichtet.

## 2.7 Resilienz-Basics

Resilienz beschreibt die Fähigkeit eines Systems, Störungen zu überstehen und sich davon zu erholen. Drei Begriffe werden oft vermischt und in der Prüfung gern abgefragt. *Hochverfügbarkeit* (High Availability) heißt, dass ein System durch Redundanz möglichst selten ausfällt und eine kurze Unterbrechung bei einem Ausfall akzeptiert werden kann. *Fehlertoleranz* heißt, dass das System bei dem Ausfall einer Komponente ohne spürbare Unterbrechung weiterläuft. Fehlertoleranz ist die strengere Variante und meist teurer. *Disaster Recovery* (Wiederherstellung nach einer Katastrophe) beschreibt, wie ein System nach einem schweren Ausfall, etwa dem einer ganzen Region, wieder in Betrieb genommen wird.

Zentrale Entwurfsregel ist das Erkennen von *Single Points of Failure* (SPOF): Komponenten, deren Ausfall die ganze Anwendung lahmlegt. Ein einzelner Server, eine einzelne Datenbank, ein einzelner Load Balancer, eine einzelne Zone oder eine einzelne Netzwerkverbindung sind typische Beispiele. Man beseitigt sie durch Redundanz: mehrere Server in mehreren Zonen, eine Datenbank mit Standby, Gesundheitsprüfungen und automatischen Austausch defekter Instanzen. Zusätzlich sollten Komponenten voneinander *entkoppelt* sein, damit der Ausfall einer Komponente nicht eine Kettenreaktion auslöst; ein Warteschlangendienst wie SQS puffert zum Beispiel Anfragen, wenn ein nachgelagertes System kurz nicht erreichbar ist.

Ein weiteres Prinzip lautet: “Design for failure”. Man geht davon aus, dass Teile ausfallen werden, und baut die Anwendung so, dass sie damit umgehen kann, anstatt zu hoffen, dass nichts passiert. Dazu gehört auch, die Wiederherstellung zu üben, denn ein Backup, das nie getestet wurde, ist keine Garantie.

Das folgende Beispiel zeigt ein einfaches, resilientes Grundmuster: eine Auto-Scaling-Gruppe, die mindestens zwei Server in verschiedenen Zonen hält und defekte Instanzen automatisch ersetzt.

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-asg \
  --launch-template LaunchTemplateName=web-vorlage,Version='$Latest' \
  --min-size 2 --max-size 6 --desired-capacity 2 \
  --vpc-zone-identifier "subnet-aaaa1111,subnet-bbbb2222" \
  --health-check-type ELB --health-check-grace-period 120
```

`--min-size 2` stellt sicher, dass immer mindestens zwei Server laufen, `--vpc-zone-identifier` nennt Subnetze in verschiedenen Zonen, sodass die Server verteilt starten, und `--health-check-type ELB` sorgt dafür, dass Instanzen, die der Load Balancer als defekt meldet, ersetzt werden. Die Subnetz-IDs und die Startvorlage sind Platzhalter. Diese Gruppe bietet Hochverfügbarkeit gegen den Ausfall einer Zone, aber keine Fehlertoleranz gegen einen Regionsausfall.

### Typische Fehler.

Falsch: Die Datenbank bleibt eine einzelne Instanz, während die Webserver redundant sind; dann ist die Datenbank der SPOF. Falsch ist auch, einen Server mit Handarbeit zu konfigurieren, den man nicht automatisch ersetzen kann. Richtig: Server aus einer Vorlage starten, damit Ersatz in Minuten bereitsteht.

### Praxisbezug.

In einem Architektur-Review wird jede Komponente gefragt: “Was passiert, wenn du ausfällst?” Für jede Antwort “alles steht” braucht es Redundanz.

## 2.8 Datenresidenz und Standortwahl

*Datenresidenz* bezeichnet den Ort, an dem Daten gespeichert werden. Viele Gesetze, Branchenvorschriften und Verträge verlangen, dass bestimmte Daten in bestimmten Ländern oder Wirtschaftsräumen liegen. Für Unternehmen in der EU ist die Datenschutz-Grundverordnung (DSGVO) ein zentraler Rahmen; sie stellt besondere Anforderungen an die Übermittlung personenbezogener Daten in Drittländer. Die Wahl einer europäischen Region ist ein wichtiger Baustein, ersetzt aber keine rechtliche Bewertung.

Die Standortwahl folgt vier Kriterien. *Compliance*: Welche Vorgaben gelten für die Daten? *Latenz*: Wo sitzen die Nutzer? Je näher die Region, desto schneller die Antwort. *Kosten*: Preise unterscheiden sich je Region. *Dienstverfügbarkeit*: Gibt es die benötigten Dienste dort? Die Kriterien stehen oft im Widerspruch, daher ist die Gewichtung eine bewusste Entscheidung, die im Projekt dokumentiert werden sollte.

Aus Sicht des Shared Responsibility Models gilt: AWS stellt die Regionen bereit und bewegt Kundendaten nicht von selbst aus einer gewählten Region heraus; der Kunde entscheidet, wo seine Daten liegen und ob sie repliziert werden. Der Kunde ist dafür verantwortlich, dass seine Konfiguration (zum Beispiel Replikationsregeln oder Backups in andere Regionen) nicht gegen Vorgaben verstößt. Nachweise zu Zertifizierungen stellt AWS Artifact bereit.

Technisch lässt sich die Region sperren. In einer Organization kann man eine Service Control Policy (SCP) einsetzen, die Aktionen außerhalb erlaubter Regionen verbietet. Das folgende Beispiel verbietet alle Aktionen außer in Frankfurt und Irland, mit Ausnahme einiger globaler Dienste.

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "NurEuRegionen",
    "Effect": "Deny",
    "NotAction": ["iam:*", "organizations:*", "route53:*",
                  "cloudfront:*", "support:*", "budgets:*"],
    "Resource": "*",
    "Condition": {
      "StringNotEquals": {
        "aws:RequestedRegion": ["eu-central-1", "eu-west-1"]
      }
    }
  }]
}
```

Die Richtlinie verbietet (`Deny`) alle Aktionen mit Ausnahme der aufgelisteten globalen Dienste (`NotAction`), sobald die angefragte Region nicht Frankfurt oder Irland ist (`StringNotEquals` mit dem Bedingungsschlüssel `aws:RequestedRegion`). Die Liste der Ausnahmen muss zum Einsatzfall passen; fehlen globale Dienste, können Funktionen unbeabsichtigt blockiert werden.

> **Ergänzung aus der Nachrecherche**
>
> Der Hinweis zur DSGVO ist eine allgemeine Einordnung und **keine Rechtsberatung**. Welche Region und welche Schutzmaßnahmen für konkrete personenbezogene Daten zulässig sind, klären Datenschutzbeauftragte oder Rechtsberatung; AWS veröffentlicht dazu Informationen und Vertragsunterlagen, die im Einzelfall zu prüfen sind.

### Typische Fehler.

Falsch: “Eine Region in der EU zu wählen, genügt für DSGVO-Konformität”. Richtig: Es ist ein Baustein; Zugriffsrechte, Verschlüsselung, Verträge und Prozesse gehören dazu. Falsch: Backups ungeprüft in eine Region außerhalb der Vorgaben replizieren lassen.

### Praxisbezug.

Ein Gesundheitsdienst legt Patientendaten ausschließlich in Frankfurt ab, sperrt andere Regionen per SCP und dokumentiert die Entscheidung im Datenschutzkonzept.

## Übungsaufgaben Modul 02

1.  Erklären Sie den Unterschied zwischen einer Region und einer Availability Zone und nennen Sie je ein Auswahlkriterium.

2.  Warum wird in der CLI zusätzlich zur Zonenbezeichnung eine Zone-ID ausgegeben?

3.  Ein Nutzer in Tokio ruft eine Seite auf, deren Ursprung in Frankfurt liegt. Beschreiben Sie den Ablauf mit CloudFront bei Cache Hit und Cache Miss.

4.  Nennen Sie je einen Fall, in dem Multi-AZ genügt, und einen, in dem Multi-Region sinnvoll ist.

5.  Wofür stehen RTO und RPO? Was ist bei einer asynchronen Replikation das Risiko?

6.  **Praxis:** Schreiben Sie CLI-Befehle, die (a) alle Regionen auflisten und (b) die Zonen von Irland mit Name und Zustand anzeigen.

7.  **Praxis:** Schreiben Sie eine SCP, die Aktionen außerhalb von `eu-central-1` verbietet (ohne globale Ausnahmen) und erläutern Sie, warum diese vereinfachte Fassung im Alltag Probleme verursachen kann.

8.  **Praxis:** Nennen Sie drei Single Points of Failure in einer Anwendung mit einem Webserver und einer Datenbank in einer Zone und beschreiben Sie, wie Sie jeden beseitigen.

## Lösungen Modul 02

1.  Eine Region ist ein geografisches Gebiet mit mehreren Zonen (Kriterien: Compliance, Latenz, Kosten, Dienstverfügbarkeit). Eine Availability Zone ist ein oder mehrere Rechenzentren in einer Region (Kriterium: Ausfallsicherheit durch Verteilung auf mehrere Zonen).

2.  Die Zonennamen werden pro Konto zufällig auf physische Zonen abgebildet. Die Zone-ID ist konto-übergreifend eindeutig und ermöglicht die Abstimmung zwischen Konten.

3.  Cache Hit: Die nächste Edge Location liefert die Datei sofort. Cache Miss: Die Edge Location holt die Datei vom Ursprung in Frankfurt, speichert sie für die Dauer der TTL und liefert sie aus; spätere Nutzer in der Nähe erhalten sie aus dem Cache.

4.  Multi-AZ genügt für die meisten Anwendungen, die den Ausfall eines Rechenzentrums überstehen müssen (etwa ein interner Webshop). Multi-Region lohnt bei geschäftskritischen Systemen, die einen Regionsausfall überstehen müssen, oder bei weltweit verteilten Nutzern.

5.  RTO ist die maximal tolerierte Wiederherstellungszeit, RPO der maximal tolerierte Datenverlust (zeitlich). Bei asynchroner Replikation können die letzten Änderungen verloren gehen, wenn die Quelle ausfällt, bevor sie repliziert wurden.

6.  Beispiellösung:

    ```bash
    aws ec2 describe-regions --all-regions --query 'Regions[].RegionName'
    aws ec2 describe-availability-zones --region eu-west-1 \
      --query 'AvailabilityZones[].{Zone:ZoneName,State:State}' --output table
    ```

7.  Beispiellösung:

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Deny",
        "Action": "*",
        "Resource": "*",
        "Condition": {"StringNotEquals": {"aws:RequestedRegion": "eu-central-1"}}
      }]
    }
    ```

    Problem: Globale Dienste (IAM, Route 53, CloudFront, Billing) werden über Endpunkte in anderen Regionen angesprochen und würden blockiert; man muss sie über `NotAction` ausnehmen.

8.  \(1\) Der einzelne Webserver: mehrere Server in mehreren Zonen hinter einem Load Balancer mit Auto Scaling. (2) Die einzelne Datenbank: Multi-AZ-Betrieb mit automatischem Failover und zusätzlich Backups. (3) Die einzelne Zone: Subnetze und Ressourcen in mindestens zwei Zonen anlegen. Optional: der einzelne Load Balancer ist selbst über mehrere Zonen verteilt.
