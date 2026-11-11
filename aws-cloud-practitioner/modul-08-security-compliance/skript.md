# Modul 8 - Security, Compliance und Governance

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 10 h laut Modulübersicht (die Einheiten summieren sich laut Detailblatt auf 9 h)

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit              | Dauer (h) |
|----:|:-------------------------|----------:|
| 8.1 | Security-by-Design       |      1,25 |
| 8.2 | Verschlüsselung und KMS  |      1,25 |
| 8.3 | Secrets Management       |         1 |
| 8.4 | Threat Detection         |      1,25 |
| 8.5 | Security Hub             |      1,25 |
| 8.6 | Compliance Programme     |         1 |
| 8.7 | Governance mit Policies  |         1 |
| 8.8 | Security-Troubleshooting |         1 |
|     | **Summe der Einheiten**  |     **9** |

> **Merke**
>
> Hinweis zum Lehrplan: Die Modulübersicht nennt 10 Stunden, die Einheiten im Detailblatt ergeben 9 Stunden. Alle acht Einheiten sind vollständig behandelt; die Differenz ist für Übungen und Nacharbeit gedacht.

Sicherheit ist bei AWS “Job Zero”: Sie hat Vorrang vor allem anderen, aber sie ist keine Einzelmaßnahme, sondern ein Zusammenspiel aus Architektur, Verschlüsselung, Erkennung, Nachweisen und Regeln. Dieses Modul fasst zusammen, was in den vorigen Modulen verteilt vorkam, und ergänzt, was noch fehlt: die Schlüsselverwaltung, den sicheren Umgang mit Zugangsdaten, die automatische Erkennung von Bedrohungen, zentrale Auswertung, Compliance-Nachweise und Leitplanken für ganze Organisationen. Der Sicherheitsbereich ist einer der gewichtigsten Teile der Prüfung. Das Shared Responsibility Model (Modul 01), IAM (Modul 03), S3-Sicherheit (Modul 05) und Netzwerkfilter (Modul 06) werden vorausgesetzt.

## 8.1 Security-by-Design

*Security-by-Design* bedeutet, Sicherheitsanforderungen von Anfang an in Architektur und Entwicklung einzubauen, statt sie am Ende aufzusetzen. Nachträgliche Sicherheit ist teuer, lückenhaft und stört den Betrieb. Wer früh fragt “Wer darf was, wo liegen die Daten, was passiert beim Angriff?”, entscheidet anders als jemand, der erst vor dem Livegang an Sicherheit denkt.

Zwei Leitprinzipien tragen den Ansatz. *Defense in Depth* (gestaffelte Verteidigung) setzt mehrere unabhängige Schutzschichten ein, sodass der Ausfall einer Schicht nicht zum Totalschaden führt. In AWS sind das etwa: Identität und Zugriff (IAM, MFA), Netzwerk (VPC, Subnetze, Security Groups, NACLs, WAF), Rechenressourcen (gepatchte Betriebssysteme, Inspector), Daten (Verschlüsselung, Backups, Versionierung) sowie Erkennung und Reaktion (CloudTrail, GuardDuty, Security Hub). Das zweite Prinzip ist *Least Privilege* (Modul 03): jede Identität nur mit den nötigen Rechten. Dazu kommen *Verschlüsselung überall* (in Transit und at Rest), *Nachvollziehbarkeit* (alles protokollieren), *Automatisierung* (Prüfungen und Korrekturen per Code statt Handarbeit), *Minimierung der Angriffsfläche* (keine unnötigen offenen Ports, keine öffentlichen Adressen) und das Vorbereiten auf Vorfälle (Incident Response).

Das Well-Architected Framework fasst die Sicherheitssäule in sieben Gestaltungsprinzipien zusammen, unter anderem: eine starke Identitätsgrundlage, Nachvollziehbarkeit, Sicherheit auf allen Ebenen, automatisierte Sicherheitsmechanismen, Daten in Transit und Ruhe schützen, Menschen von Daten fernhalten und Sicherheitsereignisse vorbereiten. Für den Alltag hilft eine Prüffrage pro Bereich: Identität (Wer hat Zugriff, ohne langlebige Schlüssel?), Netzwerk (Was ist aus dem Internet erreichbar, und muss es das sein?), Daten (Sind sie verschlüsselt, gesichert, klassifiziert?), Betrieb (Wer bemerkt einen Angriff, und was geschieht dann?).

Das folgende Beispiel zeigt eine kleine Sicherheitsgrundlage für ein neues Konto, die mehrere Schichten abdeckt: Protokollierung, Verschlüsselungsstandard und Schutz vor öffentlichen Buckets.

```bash
# 1. Protokollierung aller API-Aufrufe in allen Regionen
aws cloudtrail create-trail --name konto-trail \
  --s3-bucket-name mein-trail-bucket-2026 --is-multi-region-trail \
  --enable-log-file-validation
aws cloudtrail start-logging --name konto-trail

# 2. Standardverschluesselung fuer neue EBS-Volumes in dieser Region
aws ec2 enable-ebs-encryption-by-default

# 3. Oeffentlichen Bucket-Zugriff fuer das ganze Konto sperren
aws s3control put-public-access-block --account-id 123456789012 \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Der Trail zeichnet Verwaltungsaktionen in allen Regionen auf, die Dateivalidierung macht Manipulationen erkennbar; der Ziel-Bucket braucht eine passende Bucket-Policy für CloudTrail (nicht gezeigt). `enable-ebs-encryption-by-default` sorgt dafür, dass alle neuen EBS-Volumes der Region verschlüsselt werden; die Einstellung gilt pro Region. Der dritte Befehl blockiert öffentlichen Zugriff auf alle Buckets des Kontos. Kontonummer und Namen sind Platzhalter. Die Befehle stehen für drei Schichten: Erkennung, Daten und Netzwerk-/Zugriffsgrenzen.

### Typische Fehler.

Falsch: Sicherheit als letzte Aufgabe vor dem Livegang. Falsch: Sich auf eine einzige Schicht zu verlassen, etwa “Wir haben eine Firewall”. Falsch: Protokollierung erst nach einem Vorfall einzuschalten. Falsch: Sicherheitsregeln nur als Dokument zu führen statt sie automatisiert zu erzwingen.

### Praxisbezug.

Bei einem Architektur-Review wird jede Komponente nach den Schichten gefragt: Wie komme ich hinein, wer bemerkt es, wie begrenze ich den Schaden? Sicherheitsfragen im Entwurf sind günstig, im Betrieb teuer.

> **Merke**
>
> Security-by-Design = Sicherheit von Anfang an. Defense in Depth = mehrere unabhängige Schichten. Least Privilege, Verschlüsselung überall, Protokollierung, Automatisierung, kleine Angriffsfläche, Vorfälle vorbereiten.

## 8.2 Verschlüsselung und KMS

Verschlüsselung macht Daten für Unbefugte unlesbar. Man unterscheidet *Verschlüsselung in Transit* (während der Übertragung, meist per TLS/HTTPS) und *Verschlüsselung at Rest* (auf dem Speichermedium, zum Beispiel in S3, EBS oder RDS). Die meisten AWS-Dienste unterstützen beides; at Rest ist bei vielen Diensten bereits Standard, bei anderen muss man sie beim Anlegen wählen. Verschlüsselung ersetzt keine Zugriffsrechte, sie ergänzt sie: Sie schützt vor dem Lesen der Rohdaten (etwa bei entwendeten Datenträgern oder falsch freigegebenen Snapshots) und liefert Kontrolle darüber, wer den Schlüssel verwenden darf.

Zentral ist der *AWS Key Management Service* (KMS), der Schlüssel erzeugt, speichert und für andere Dienste bereitstellt. Die Schlüssel verlassen KMS nie unverschlüsselt; KMS führt Verschlüsselung und Entschlüsselung selbst aus oder gibt kurzlebige Datenschlüssel heraus. Man unterscheidet drei Arten von KMS-Schlüsseln: *AWS-eigene Schlüssel* (von AWS für Dienste verwaltet, für den Kunden unsichtbar), *AWS-verwaltete Schlüssel* (zum Beispiel `aws/s3`, im Konto sichtbar, werden von AWS rotiert, ihre Richtlinie lässt sich nicht ändern) und *vom Kunden verwaltete Schlüssel* (Customer Managed Keys), bei denen der Kunde Richtlinie, Rotation, Aktivierung und Löschung selbst steuert und jede Nutzung in CloudTrail nachvollziehen kann. Wer Prüfern nachweisen muss, wer wann welchen Schlüssel nutzen durfte, wählt eigene Schlüssel.

Der Zugriff auf einen Schlüssel wird durch die *Key Policy* bestimmt, zusätzlich zu IAM-Richtlinien; ohne passende Erlaubnis in der Key Policy (direkt oder über die Freigabe für IAM) gibt es keinen Zugriff, selbst für Administratoren. Das ist eine häufige Fehlerquelle. Große Datenmengen werden per *Envelope Encryption* geschützt: KMS erzeugt einen Datenschlüssel, mit dem die Daten lokal verschlüsselt werden, und verschlüsselt diesen Datenschlüssel mit dem KMS-Schlüssel; der verschlüsselte Datenschlüssel wird neben den Daten gespeichert. Das ist schneller, weil KMS nur kleine Datenmengen (bis 4 Kilobyte direkt) verarbeitet. Die automatische *Schlüsselrotation* erzeugt regelmäßig neues Schlüsselmaterial, während alte Daten weiter lesbar bleiben; sie lässt sich für Kundenschlüssel aktivieren. Das Löschen eines Schlüssels ist mit einer Wartezeit von 7 bis 30 Tagen versehen, weil darauf verschlüsselte Daten danach unwiederbringlich verloren sind. Für Zertifikate (Verschlüsselung in Transit) gibt es *AWS Certificate Manager* (ACM), und wer exklusive Hardware-Module braucht, kann *AWS CloudHSM* nutzen.

Das folgende Beispiel legt einen Kundenschlüssel mit Alias an, aktiviert die Rotation und verschlüsselt und entschlüsselt einen kleinen Text.

```bash
KEY=$(aws kms create-key --description "Lernschluessel" \
  --query KeyMetadata.KeyId --output text)
aws kms create-alias --alias-name alias/lern --target-key-id $KEY
aws kms enable-key-rotation --key-id $KEY

echo -n "geheim" > klartext.txt
aws kms encrypt --key-id alias/lern --plaintext fileb://klartext.txt \
  --query CiphertextBlob --output text | base64 --decode > chiffre.bin
aws kms decrypt --ciphertext-blob fileb://chiffre.bin \
  --query Plaintext --output text | base64 --decode

aws s3api put-bucket-encryption --bucket mein-lernbucket-2026-12345 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/lern"}}]}'
```

`create-key` erzeugt den Schlüssel, der Alias `alias/lern` vermeidet die lange ID. `enable-key-rotation` schaltet die automatische Rotation ein. `encrypt` verschlüsselt die Datei (die Ausgabe ist Base64, die Pipe wandelt sie in Binärdaten), `decrypt` braucht keinen Schlüsselhinweis, da das Chiffrat ihn enthält, und liefert den Klartext zurück. Der letzte Befehl stellt den Bucket so ein, dass neue Objekte standardmäßig mit diesem Schlüssel verschlüsselt werden. Die Entschlüsselung beim Lesen verlangt dann auch Rechte am Schlüssel.

### Typische Fehler.

Falsch: Zu glauben, Verschlüsselung allein schütze vor jedem Zugriff; wer Leserecht und Schlüsselrecht besitzt, sieht die Daten. Falsch: Einen Schlüssel zu löschen, ohne zu prüfen, welche Daten darauf angewiesen sind. Falsch: Die Key Policy so zu ändern, dass niemand mehr Zugriff hat. Falsch: Den Klartext oder Schlüssel in Quellcode oder Logs zu speichern.

### Praxisbezug.

Ein Unternehmen verschlüsselt Datenbank, Volumes und Buckets mit je einem eigenen Kundenschlüssel pro Datenklasse. Die Sicherheitsabteilung verwaltet die Schlüssel, die Entwickler dürfen sie nur nutzen, nicht verändern oder löschen.

## 8.3 Secrets Management

Zugangsdaten wie Datenbankpasswörter, API-Schlüssel oder Tokens (zusammen *Secrets*) dürfen weder im Quellcode noch in Konfigurationsdateien im Klartext liegen. Hartcodierte Zugangsdaten landen in Versionsverwaltungen, Logs, Screenshots und Backups, und ein einmal veröffentlichtes Geheimnis ist verloren. Außerdem lassen sie sich schwer wechseln, wenn sie an vielen Stellen verteilt sind.

AWS bietet zwei Dienste für die zentrale Ablage. *AWS Secrets Manager* speichert Geheimnisse verschlüsselt (mit KMS), regelt den Zugriff über IAM, protokolliert Abrufe in CloudTrail und kann Geheimnisse automatisch *rotieren*: Für RDS, Redshift und andere Dienste gibt es fertige Rotationsfunktionen (Lambda), die das Passwort in der Datenbank und im Geheimnis gleichzeitig ändern. Dafür fallen Kosten pro Geheimnis und Monat sowie pro Abruf an. Der *Systems Manager Parameter Store* speichert Konfigurationswerte und, als Typ `SecureString`, verschlüsselte Geheimnisse; die Standardstufe ist kostenlos. Eine automatische Rotation bringt er nicht von sich aus mit. Als Faustregel gilt: Secrets Manager für Zugangsdaten mit Rotationsbedarf, Parameter Store für einfache Konfigurationen und günstige verschlüsselte Werte.

Die Anwendung ruft das Geheimnis zur Laufzeit ab, mit einer IAM-Rolle, die genau dieses Geheimnis lesen darf. So gibt es im Code nur den Namen, nicht den Inhalt. Wer die Rolle nicht hat, erhält das Passwort nicht, und wer das Passwort rotiert, muss keinen Code ändern, wenn die Anwendung bei jedem Start oder in kurzen Abständen neu abruft. Auch für Verbindungen zwischen Diensten sind Rollen vorzuziehen, weil gar kein Passwort nötig ist (Modul 03).

Das folgende Beispiel legt ein Geheimnis an, liest es und speichert zum Vergleich einen verschlüsselten Parameter.

```bash
aws secretsmanager create-secret --name prod/shop/db \
  --description "Datenbankzugang Shop" \
  --secret-string '{"username":"dbadmin","password":"AendereMich-123!"}'
aws secretsmanager get-secret-value --secret-id prod/shop/db \
  --query SecretString --output text
aws secretsmanager rotate-secret --secret-id prod/shop/db \
  --rotation-lambda-arn arn:aws:lambda:eu-central-1:123456789012:function:rotation \
  --rotation-rules AutomaticallyAfterDays=30

aws ssm put-parameter --name /shop/api-key --type SecureString \
  --value "abc123" --key-id alias/lern
aws ssm get-parameter --name /shop/api-key --with-decryption \
  --query Parameter.Value --output text
```

`create-secret` legt das Geheimnis als JSON an; der Name enthält eine Struktur (`prod/shop/db`), die sich für IAM-Richtlinien nach Pfad eignet. `get-secret-value` liest den Inhalt, `rotate-secret` richtet eine Rotation alle 30 Tage über eine Lambda-Funktion ein (hier ein Platzhalter-ARN). Die letzten beiden Befehle legen einen verschlüsselten Parameter an und lesen ihn mit Entschlüsselung. Das Passwort im Beispiel ist nur zur Demonstration und nie in echten Befehlen zu verwenden, denn Befehle landen in der Shell-Historie; besser sind Dateien oder Eingaben ohne Anzeige.

### Typische Fehler.

Falsch: Passwörter in Konfigurationsdateien im Repository, in AMIs, in Umgebungsvariablen oder im Lambda-Code. Falsch: Geheimnisse mit `Resource: *` für jede Rolle lesbar zu machen. Falsch: Beim Abrufen den Wert zu protokollieren. Falsch: Eine Rotation einzuschalten, ohne dass die Anwendung die neuen Werte abruft; sie verliert dann die Verbindung.

### Praxisbezug.

Ein Team nutzt für RDS die verwaltete Masterpasswort-Funktion (`--manage-master-user-password`) mit Secrets Manager; die Anwendung liest das Geheimnis beim Start, das Passwort wird automatisch rotiert, und niemand kennt es im Klartext.

## 8.4 Threat Detection

Auch gut abgesicherte Umgebungen werden angegriffen oder fehlkonfiguriert. Deshalb gehören Dienste zur Erkennung von Bedrohungen zum Standardbaukasten. Sie lassen sich nach ihrer Aufgabe ordnen.

*Amazon GuardDuty* ist der Dienst zur kontinuierlichen Bedrohungserkennung. Er wertet ohne eigene Agenten Datenquellen aus, darunter CloudTrail-Ereignisse, VPC Flow Logs und DNS-Protokolle, und kann zusätzlich Aktivitäten in S3, EKS, Lambda und Datenträgern auf Schadsoftware untersuchen. Mit Machine Learning, Anomalieerkennung und Bedrohungslisten findet er auffällige Muster, etwa Zugriffe von bekannten bösartigen Adressen, ungewöhnliche API-Aufrufe, Kryptomining auf Instanzen oder Zugangsdaten, die von einem untypischen Ort genutzt werden. Die Ergebnisse (*Findings*) haben einen Schweregrad und eine Beschreibung; GuardDuty greift nicht von sich aus in die Umgebung ein, sondern meldet, was dann per EventBridge Benachrichtigungen oder automatische Reaktionen auslösen kann. Er lässt sich in Minuten einschalten, ohne Infrastruktur zu verändern.

*Amazon Inspector* sucht nach Schwachstellen: Er scannt EC2-Instanzen, Container-Images in ECR und Lambda-Funktionen kontinuierlich auf bekannte Sicherheitslücken (CVEs) und unbeabsichtigte Netzwerkerreichbarkeit und bewertet sie nach Risiko. *Amazon Detective* hilft bei der Untersuchung: Er sammelt und verknüpft Protokolldaten zu einer Grafik, damit man die Ursache und den Umfang eines Findings nachvollziehen kann. *Amazon Macie* findet sensible Daten, etwa personenbezogene Informationen, in S3. Zum Schutz vor Angriffen von außen dienen *AWS Shield* (Standard schützt automatisch und kostenlos vor gängigen DDoS-Angriffen, Advanced bietet erweiterten Schutz und Unterstützung) und *AWS WAF* (eine Web Application Firewall mit Regeln gegen typische Angriffe wie SQL-Injection). *AWS Firewall Manager* verwaltet solche Regeln zentral über Konten hinweg. Das richtige Vorgehen bei einem Finding hängt vom Schweregrad ab: Hohe Befunde (etwa kompromittierte Zugangsdaten) werden sofort eingedämmt, indem man Schlüssel deaktiviert, Instanzen isoliert (Security Group ohne Zugriff) und Beweise sichert, bevor man sie löscht.

Das folgende Beispiel schaltet GuardDuty ein, ruft Findings ab und verbindet sie mit einer Benachrichtigung.

```bash
DET=$(aws guardduty create-detector --enable \
  --query DetectorId --output text)
aws guardduty create-sample-findings --detector-id $DET \
  --finding-types Recon:EC2/PortProbeUnprotectedPort

aws guardduty list-findings --detector-id $DET \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'
aws guardduty get-findings --detector-id $DET --finding-ids FINDING_ID \
  --query 'Findings[].{Typ:Type,Schwere:Severity,Titel:Title}'

aws events put-rule --name guardduty-hoch \
  --event-pattern '{"source":["aws.guardduty"],"detail-type":["GuardDuty Finding"],"detail":{"severity":[{"numeric":[">=",7]}]}}'
```

`create-detector` aktiviert GuardDuty in der Region; er muss pro Region (und ggf. pro Konto) eingeschaltet werden. `create-sample-findings` erzeugt harmlose Beispielbefunde zum Üben. `list-findings` filtert nach Schweregrad ab 7 (hoch); die ID des Findings aus der Ausgabe setzt man bei `get-findings` ein (`FINDING\_ID` ist ein Platzhalter). Die EventBridge-Regel reagiert auf schwere Findings; als Ziel würde man ein SNS-Thema oder eine Lambda-Funktion eintragen.

### Typische Fehler.

Falsch: GuardDuty einzuschalten und die Findings nie zu lesen. Falsch: Detektoren nur in einer Region zu aktivieren; Angreifer nutzen gern ungenutzte Regionen. Falsch: Inspector mit GuardDuty zu verwechseln (Schwachstellen gegen Bedrohungen). Falsch: Bei einem Vorfall die betroffene Instanz sofort zu löschen und damit Beweise zu vernichten.

### Praxisbezug.

Ein Sicherheitsteam leitet Findings ab Schweregrad hoch per EventBridge an den Bereitschaftschat und startet eine Lambda-Funktion, die die betroffene Instanz in eine isolierte Security Group verschiebt.

> **Merke**
>
> GuardDuty = Bedrohungen erkennen (CloudTrail, Flow Logs, DNS). Inspector = Schwachstellen scannen. Detective = Ursachen untersuchen. Macie = sensible Daten in S3. Shield und WAF = Schutz vor DDoS und Webangriffen.

## 8.5 Security Hub

Wer GuardDuty, Inspector, Macie und weitere Dienste in mehreren Konten und Regionen betreibt, hat schnell hunderte Meldungen an verschiedenen Orten. *AWS Security Hub* führt sie an einer Stelle zusammen. Es sammelt Findings aus AWS-Diensten und Partnerprodukten in einem einheitlichen Format (dem *AWS Security Finding Format*, ASFF), priorisiert sie und stellt ein Gesamtbild des Sicherheitszustands dar. Es kann Daten aus allen Konten einer Organisation in einem delegierten Administratorkonto bündeln.

Zusätzlich führt Security Hub eigene *Kontrollen* aus. Eine Kontrolle ist eine automatisierte Prüfung einer Konfiguration, zum Beispiel “Hat der Root User MFA?”, “Sind S3-Buckets öffentlich?” oder “Ist die Verschlüsselung von EBS-Volumes aktiv?”. Kontrollen sind zu *Standards* gebündelt, etwa den *AWS Foundational Security Best Practices*, dem *CIS AWS Foundations Benchmark*, *PCI DSS* oder *NIST SP 800-53*. Das Ergebnis ist je Kontrolle bestanden oder nicht bestanden, und eine Gesamtbewertung zeigt den Reifegrad. Die Prüfungen basieren auf AWS Config; dieses muss daher aktiviert sein. Das Konzept bildet *kontinuierliche Bewertung* ab: Nicht einmal im Jahr prüfen, sondern permanent, damit Fehlkonfigurationen binnen Minuten auffallen.

Security Hub kann über EventBridge automatisierte Reaktionen anstoßen, etwa eine öffentlich gewordene Datei zurücksetzen oder ein Ticket erzeugen. Das Produkt wird von AWS laufend weiterentwickelt; Bezeichnungen und Funktionsumfang können sich daher ändern, und für aktuelle Details gilt die Dokumentation. Prüfungsrelevant ist die Rolle: zentrale Sicht, Prüfung nach Standards, Aggregation und Priorisierung.

Das folgende Beispiel schaltet Security Hub mit einem Standard ein, listet fehlgeschlagene Kontrollen und fragt einen Standard ab.

```bash
aws securityhub enable-security-hub --enable-default-standards
aws securityhub get-enabled-standards \
  --query 'StandardsSubscriptions[].StandardsArn'

aws securityhub get-findings \
  --filters '{"ComplianceStatus":[{"Value":"FAILED","Comparison":"EQUALS"}],"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}]}' \
  --max-items 10 \
  --query 'Findings[].{Titel:Title,Ressource:Resources[0].Id}'
```

`enable-security-hub` aktiviert den Dienst mit den Standardstandards. `get-enabled-standards` zeigt, welche Standards aktiv sind. Die Abfrage mit `get-findings` liefert aktive Findings, die kritisch sind und bei denen die Kontrolle fehlgeschlagen ist; die Ausgabe nennt Titel und betroffene Ressource. Bis die ersten Ergebnisse da sind, kann es eine Weile dauern, da die Prüfungen im Hintergrund laufen.

### Typische Fehler.

Falsch: Security Hub zu aktivieren, ohne AWS Config einzuschalten; die Kontrollen liefern dann keine Ergebnisse. Falsch: Alle Findings gleich zu behandeln, statt nach Schweregrad zu priorisieren. Falsch: Das Ziel “100 Prozent Score” zu verfolgen und dabei bewusst akzeptierte Ausnahmen nicht zu dokumentieren; sie lassen sich unterdrücken und begründen. Falsch: Security Hub als Schutzmaßnahme zu betrachten; es erkennt und meldet, es verhindert nichts.

### Praxisbezug.

Ein Sicherheitsteam sieht im Security Hub einer Organisation alle kritischen Findings aller Konten. Wöchentlich bearbeitet es die Top-Befunde, und die Verbesserungen werden am Score sichtbar.

## 8.6 Compliance Programme

*Compliance* bedeutet, dass ein Unternehmen gesetzliche, branchenspezifische und vertragliche Vorgaben einhält und das nachweisen kann. Für Cloud-Nutzer stellt sich die Frage: Wie belege ich einem Prüfer, dass die Plattform, auf der ich arbeite, sicher ist? Nach dem Shared Responsibility Model gilt die Compliance *der* Cloud für AWS, die Compliance *in* der Cloud (Konfiguration, Daten, Prozesse) für den Kunden.

AWS lässt seine Infrastruktur und Dienste von unabhängigen Prüfern nach einer Vielzahl von Standards und Programmen zertifizieren und bestätigen. Dazu zählen unter anderem ISO 27001 (Informationssicherheits-Management), SOC 1, 2 und 3 (Prüfberichte über Kontrollen), PCI DSS (Kartenzahlungen), der deutsche C5-Katalog des BSI sowie branchenspezifische Programme etwa für das Gesundheitswesen. Welche Dienste in den Geltungsbereich eines Programms fallen, veröffentlicht AWS in Übersichten; nicht jeder Dienst ist in jedem Programm enthalten. Die Existenz eines Zertifikats für AWS bedeutet nicht, dass die Anwendung des Kunden automatisch konform ist.

Den Zugriff auf die Nachweise regelt *AWS Artifact*: ein Self-Service-Portal in der Console, in dem man Compliance-Berichte (zum Beispiel SOC-Berichte, ISO-Zertifikate) herunterladen und Vereinbarungen annehmen kann, etwa einen Auftragsverarbeitungs-Zusatz oder eine Vereinbarung für Gesundheitsdaten (BAA). Manche Berichte erfordern zuvor die Annahme einer Vertraulichkeitsvereinbarung. Der Kunde ist für seinen Teil selbst verantwortlich und muss eigene Nachweise erbringen: dass Zugriffsrechte nach dem Prinzip der geringsten Rechte vergeben sind, Daten verschlüsselt werden, Änderungen nachvollziehbar sind. Dabei helfen *AWS Config* (Konfigurationsverlauf und Regeln, sogenannte Conformance Packs), *AWS CloudTrail* (Aktivitätsprotokoll), *Security Hub* (Standards) und *AWS Audit Manager* (sammelt Nachweise automatisiert für Audits).

Eine einfache Rechnung verdeutlicht den Aufteilungsgedanken: Verlangt ein Standard 50 Kontrollen, fallen vielleicht 20 davon in den Bereich physischer und infrastruktureller Sicherheit (durch AWS erfüllt und per Bericht belegbar), während 30 die eigene Konfiguration betreffen (vom Kunden zu erfüllen und zu belegen). Die Zahlen sind ein Denkbeispiel.

Das folgende Beispiel zeigt, wie man Regeln aus AWS Config zur Compliance-Prüfung einrichtet und das Ergebnis liest.

```bash
aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "s3-bucket-public-read-prohibited",
  "Source": {"Owner": "AWS", "SourceIdentifier": "S3_BUCKET_PUBLIC_READ_PROHIBITED"}
}'
aws configservice put-config-rule --config-rule '{
  "ConfigRuleName": "encrypted-volumes",
  "Source": {"Owner": "AWS", "SourceIdentifier": "ENCRYPTED_VOLUMES"}
}'
aws configservice describe-compliance-by-config-rule \
  --query 'ComplianceByConfigRules[].{Regel:ConfigRuleName,Status:Compliance.ComplianceType}'
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name encrypted-volumes --compliance-types NON_COMPLIANT
```

Zwei verwaltete Regeln werden angelegt: Buckets dürfen nicht öffentlich lesbar sein, und Volumes müssen verschlüsselt sein. AWS Config muss dafür aufzeichnen (ein Konfigurations-Recorder ist erforderlich). Die Abfragen zeigen je Regel `COMPLIANT` oder `NON\_COMPLIANT` und die betroffenen Ressourcen. Solche Auswertungen dienen als Nachweis gegenüber Prüfern.

> **Ergänzung aus der Nachrecherche**
>
> Hinweis zur Rechtslage: Anforderungen wie die DSGVO oder branchenspezifische Vorgaben gelten für den Kunden als Verantwortlichen; AWS stellt Verträge, Berichte und Funktionen bereit. Dieser Abschnitt ist **keine Rechtsberatung**. Welche Programme und Nachweise im Einzelfall nötig sind, klärt die Compliance- oder Rechtsabteilung anhand der aktuellen Unterlagen auf der AWS-Seite zu Compliance und in AWS Artifact; die Zahl und der Geltungsbereich der Programme ändern sich laufend.

### Typische Fehler.

Falsch: “AWS ist ISO-zertifiziert, also sind wir es auch”. Falsch: Einen Bericht zu laden und zu verwenden, ohne zu prüfen, ob der benötigte Dienst im Geltungsbereich liegt. Falsch: Nachweise erst bei der Prüfung zusammenzusuchen; kontinuierliche Sammlung ist deutlich effizienter.

### Praxisbezug.

Vor einer ISO-27001-Zertifizierung lädt das Team die AWS-Bescheinigung aus Artifact, legt eigene Nachweise aus AWS Config und CloudTrail daneben und dokumentiert die Zuständigkeiten nach Shared Responsibility.

## 8.7 Governance mit Policies

*Governance* bezeichnet Regeln, Verantwortlichkeiten und Kontrollen, die dafür sorgen, dass Cloud-Nutzung sicher, kostenbewusst und im Sinne des Unternehmens geschieht. In einer Organisation mit vielen Konten und Teams reicht es nicht, jedem Team Empfehlungen mitzugeben; Regeln müssen technisch durchgesetzt werden, ohne die Teams zu bremsen. Man spricht von *Guardrails* (Leitplanken): Sie halten Teams in einem sicheren Bereich, lassen darin aber Freiheit.

Das wichtigste Werkzeug sind die Richtlinientypen von AWS Organizations (Modul 03). *Service Control Policies* (SCPs) legen die maximal erlaubten Aktionen für Konten fest, zum Beispiel “Region nur Frankfurt und Irland”, “CloudTrail nicht abschaltbar”, “keine Root-Anmeldung”, “keine bestimmten teuren Instanztypen”. *Tag Policies* legen fest, welche Tag-Schlüssel und Werte erlaubt sind (zum Beispiel `Umgebung` nur mit `prod`, `test`, `dev`) und helfen so bei Kostenzuordnung. *Backup Policies* setzen zentral Sicherungspläne durch, und *AI-Opt-out-Richtlinien* steuern die Datennutzung für Dienste. Ergänzend gibt es *Permissions Boundaries* auf IAM-Ebene, *AWS Config Rules* zum Erkennen und Korrigieren von Abweichungen und *AWS Control Tower*, das eine empfohlene Mehrkonten-Umgebung (Landing Zone) mit vorgefertigten Guardrails aufbaut. Control Tower unterscheidet vorbeugende Guardrails (verhindern, meist per SCP) und erkennende Guardrails (melden, meist per AWS Config).

Eine gute Governance folgt einem Muster: Erst die Leitplanken definieren (vorbeugend, wo ein Verstoß nicht tragbar wäre, erkennend, wo er behebbar ist), dann Ausnahmen über einen dokumentierten Prozess zulassen, schließlich die Wirksamkeit messen. Vorbeugende Regeln sollten sparsam und gut getestet sein, weil sie legitime Arbeit blockieren können, wenn sie zu breit sind. Üblich ist, SCPs zunächst in einer Testorganisationseinheit zu erproben.

Das folgende Beispiel legt eine SCP an, die das Verlassen der Organisation und das Ändern der Protokollierung verbietet, sowie eine Tag Policy.

```bash
cat > scp-leitplanken.json <<'EOT'
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "OrgNichtVerlassen", "Effect": "Deny",
     "Action": "organizations:LeaveOrganization", "Resource": "*"},
    {"Sid": "ProtokollSchuetzen", "Effect": "Deny",
     "Action": ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail",
                "config:StopConfigurationRecorder"],
     "Resource": "*"}
  ]
}
EOT
aws organizations create-policy --name leitplanken \
  --type SERVICE_CONTROL_POLICY --description "Basisschutz" \
  --content file://scp-leitplanken.json

cat > tags.json <<'EOT'
{ "tags": { "Umgebung": {
    "tag_key": {"@@assign": "Umgebung"},
    "tag_value": {"@@assign": ["prod", "test", "dev"]} } } }
EOT
aws organizations create-policy --name tag-umgebung \
  --type TAG_POLICY --description "Erlaubte Umgebungswerte" \
  --content file://tags.json
```

Die SCP verbietet drei Gruppen von Aktionen: das Verlassen der Organisation, das Abschalten von CloudTrail und das Anhalten der Konfigurationsaufzeichnung. Sie wird erst wirksam, wenn man sie mit `attach-policy` an eine OU oder ein Konto hängt (Modul 03). Die Tag Policy legt für den Schlüssel `Umgebung` fest, dass nur drei Werte zulässig sind; sie prüft die Konformität, verhindert aber nicht automatisch falsche Tags, außer man erzwingt sie zusätzlich. Die Syntax von Tag Policies ist eigen (`@@assign`) und in der Dokumentation beschrieben.

### Typische Fehler.

Falsch: SCPs als Berechtigung zu verstehen; sie begrenzen nur. Falsch: Eine breite Deny-SCP ohne Test auf die gesamte Organisation anzuwenden und Teams damit zu blockieren. Falsch: Regeln nur zu dokumentieren und nicht durchzusetzen. Falsch: Ausnahmen ohne Prozess zu vergeben und damit die Leitplanken aufzuweichen.

### Praxisbezug.

Bei der Einführung einer Landing Zone legt ein Plattformteam Guardrails fest, damit neue Teams in Minuten ein Konto bekommen, das automatisch protokolliert, verschlüsselt und auf zulässige Regionen beschränkt ist.

## 8.8 Security-Troubleshooting

Sicherheitsprobleme zeigen sich auf zwei Weisen: Etwas funktioniert nicht, weil Sicherheitsmechanismen es blockieren (zu viel Schutz), oder etwas ist zugänglich, das es nicht sein sollte (zu wenig Schutz). Beides lässt sich mit denselben Werkzeugen eingrenzen, die man bereits kennt: CloudTrail für das Was und Wer, IAM Access Analyzer für ungewollte Offenheit und Security Hub für die Gesamtsicht.

*Blockierter Zugriff* wurde in Modul 03 systematisch behandelt. Im Sicherheitsumfeld kommen typische zusätzliche Ursachen hinzu: Eine Key Policy erlaubt dem Aufrufer die Nutzung des KMS-Schlüssels nicht (zu erkennen an `AccessDenied` bei `kms:Decrypt` oder `kms:GenerateDataKey`, obwohl die S3-Rechte stimmen), eine SCP verbietet die Aktion oder Region, eine VPC-Endpunkt-Richtlinie oder Bucket-Policy mit `aws:SourceVpce` schließt die Anfrage aus, oder Block Public Access hebt eine öffentliche Freigabe auf. *Ungewollte Öffentlichkeit* entdeckt man mit dem *IAM Access Analyzer*: Er untersucht Ressourcenrichtlinien (Buckets, Rollen, Schlüssel, Queues, Funktionen) und meldet, welche Ressourcen von außerhalb des Kontos oder der Organisation oder öffentlich zugänglich sind. Dazu kommt der Test mit den S3-eigenen Prüfungen (*Block Public Access*-Status, Bucket-Richtlinienstatus) und Netzwerkprüfungen (Security Groups mit `0.0.0.0/0` auf Verwaltungsports) durch Config-Regeln oder Security Hub.

Bei einem vermuteten Vorfall folgt man einem Ablauf: erkennen (GuardDuty- oder Security-Hub-Finding), eingrenzen (betroffene Identität oder Ressource ermitteln, mit CloudTrail die Aktionen der letzten Stunden und Tage ansehen), eindämmen (Schlüssel deaktivieren, Sitzungen widerrufen, Instanz isolieren), beheben (Ursache schließen, Zugangsdaten rotieren) und lernen (Regeln und Automatisierung verbessern). Beweise wie Snapshots und Logs sichert man, bevor man Ressourcen verändert.

Das folgende Beispiel zeigt die wichtigsten Befehle: einen Access Analyzer einrichten, Findings lesen, kompromittierte Schlüssel deaktivieren und CloudTrail durchsuchen.

```bash
aws accessanalyzer create-analyzer --analyzer-name konto-analyse --type ACCOUNT
aws accessanalyzer list-findings \
  --analyzer-arn arn:aws:access-analyzer:eu-central-1:123456789012:analyzer/konto-analyse \
  --filter '{"status":{"eq":["ACTIVE"]}}' \
  --query 'findings[].{Ressource:resource,Typ:resourceType,Oeffentlich:isPublic}'

aws iam update-access-key --user-name anna \
  --access-key-id AKIAEXAMPLEKEY12345 --status Inactive

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=anna \
  --start-time 2026-10-23T00:00:00Z \
  --query 'Events[].{Zeit:EventTime,Aktion:EventName}' --max-results 20
```

Der Analyzer untersucht das Konto (Typ `ACCOUNT`) und meldet extern zugängliche Ressourcen; die Abfrage zeigt, welche Ressource öffentlich ist. Der Zugriffsschlüssel von `anna` wird auf `Inactive` gesetzt, was ihn sofort unbrauchbar macht, ohne ihn zu löschen (nützlich als Beweismittel und zum Wiederherstellen bei Fehlalarm). Die Suche in CloudTrail listet die Aktionen des Benutzers seit dem angegebenen Zeitpunkt. Der Schlüssel und der ARN sind Platzhalter.

> **Praxisbeispiel**
>
> Ein Entwickler bekommt beim Hochladen in einen verschlüsselten Bucket `AccessDenied`, obwohl seine Rolle `s3:PutObject` darf. CloudTrail zeigt, dass der Fehler im Aufruf `kms:GenerateDataKey` auftritt; die Key Policy des Kundenschlüssels erlaubt seiner Rolle die Nutzung nicht. Nach Ergänzung der Rolle in der Key Policy (oder Freigabe über IAM) funktioniert der Upload. Der Fehler lag nicht bei S3, sondern bei der Verschlüsselung.

### Typische Fehler.

Falsch: Bei `AccessDenied` das Recht zu erweitern, ohne die blockierende Schicht (SCP, Key Policy, Endpunkt) zu finden. Falsch: Bei einem Vorfall Logs oder Instanzen zu löschen. Falsch: Verdächtige Schlüssel nur zu löschen statt zuerst zu deaktivieren und die Aktivität zu untersuchen. Falsch: Access-Analyzer-Findings zu ignorieren, weil “es ja schon immer so war”.

### Praxisbezug.

Ein Runbook “Verdacht auf kompromittierte Zugangsdaten” enthält die Schritte: Schlüssel deaktivieren, aktive Sitzungen der Rolle ungültig machen (Richtlinie mit Zeitpunkt der Sitzungsausstellung), CloudTrail für 90 Tage prüfen, Schlüssel rotieren, Meldung nach internen Regeln.

## Übungsaufgaben Modul 08

1.  Erklären Sie Defense in Depth und nennen Sie fünf Schutzschichten einer AWS-Umgebung.

2.  Worin unterscheiden sich AWS-eigene, AWS-verwaltete und vom Kunden verwaltete KMS-Schlüssel? Wann wählt man den Kundenschlüssel?

3.  Wann nimmt man Secrets Manager, wann den Parameter Store? Nennen Sie einen Vorteil der Rotation.

4.  Ordnen Sie zu: (a) Kryptomining auf einer Instanz erkennen, (b) Schwachstellen in einem Container-Image finden, (c) personenbezogene Daten in S3 aufspüren, (d) Ergebnisse mehrerer Dienste zentral prüfen, (e) SOC-Bericht von AWS herunterladen.

5.  Warum bedeutet ein ISO-27001-Zertifikat von AWS nicht automatisch, dass die eigene Anwendung konform ist?

6.  **Praxis:** Legen Sie per CLI einen Kundenschlüssel mit Alias an, aktivieren Sie die Rotation und stellen Sie einen Bucket auf Standardverschlüsselung mit diesem Schlüssel um.

7.  **Praxis:** Schreiben Sie eine SCP, die jede Aktion des Root Users in Mitgliedskonten verbietet und das Abschalten von GuardDuty untersagt. Erläutern Sie, wo sie wirkt und wo nicht.

8.  **Praxis:** Ein Upload in einen KMS-verschlüsselten Bucket scheitert mit `AccessDenied`. Beschreiben Sie Ihre Analyse mit Befehlen und nennen Sie vier mögliche Ursachen.

## Lösungen Modul 08

1.  Mehrere unabhängige Schutzschichten, sodass der Ausfall einer Schicht nicht zum Totalschaden führt. Schichten: Identität und Zugriff (IAM, MFA), Netzwerk (VPC, Security Groups, NACLs, WAF), Rechenressourcen (Patches, Inspector), Daten (Verschlüsselung, Backups), Erkennung und Reaktion (CloudTrail, GuardDuty, Security Hub).

2.  AWS-eigene: für Dienste intern, unsichtbar. AWS-verwaltete: im Konto sichtbar, Rotation und Richtlinie von AWS. Kundenverwaltet: volle Kontrolle über Key Policy, Rotation, Löschung und Nutzungsnachweis. Kundenschlüssel wählt man bei Nachweispflichten, feingranularer Zugriffskontrolle, kontoübergreifender Nutzung oder Trennung nach Datenklassen.

3.  Secrets Manager für Zugangsdaten mit automatischer Rotation (zum Beispiel Datenbank), kostet pro Geheimnis. Parameter Store für Konfigurationen und einfache verschlüsselte Werte (SecureString), Standardstufe kostenlos. Rotation begrenzt den Schaden gestohlener Zugangsdaten, weil sie nur eine begrenzte Zeit gültig sind.

4.  \(a\) GuardDuty, (b) Inspector, (c) Macie, (d) Security Hub, (e) AWS Artifact.

5.  Das Zertifikat belegt die Kontrollen von AWS für die Infrastruktur und die abgedeckten Dienste (Sicherheit *der* Cloud). Konfiguration, Daten, Zugriffsrechte und Prozesse des Kunden (Sicherheit *in* der Cloud) muss der Kunde selbst absichern und belegen; außerdem muss der genutzte Dienst im Geltungsbereich liegen.

6.  ```bash
    KEY=$(aws kms create-key --query KeyMetadata.KeyId --output text)
    aws kms create-alias --alias-name alias/daten --target-key-id $KEY
    aws kms enable-key-rotation --key-id $KEY
    aws s3api put-bucket-encryption --bucket mein-lernbucket-2026-12345 \
      --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/daten"}}]}'
    ```

7.  ```json
    {
      "Version": "2012-10-17",
      "Statement": [
        {"Sid": "KeinRoot", "Effect": "Deny", "Action": "*", "Resource": "*",
         "Condition": {"StringLike": {"aws:PrincipalArn": "arn:aws:iam::*:root"}}},
         {"Sid": "GuardDutyAn", "Effect": "Deny",
         "Action": ["guardduty:DeleteDetector", "guardduty:DisassociateFromMasterAccount",
                    "guardduty:UpdateDetector"],
         "Resource": "*"}
      ]
    }
    ```

    Wirkung: in den Mitgliedskonten der OU, an die die SCP gehängt ist, auch für Administratoren. Nicht wirksam: im Verwaltungskonto der Organisation (SCPs gelten dort nicht) und für Aktionen, die die SCP nicht nennt. Hinweis: Wer Root-Aufgaben in Mitgliedskonten doch braucht, nutzt die zentrale Verwaltung des Root-Zugriffs über das Verwaltungskonto; die SCP sollte vor dem Einsatz in einer Test-OU geprüft werden.

8.  Analyse: (1) `aws sts get-caller-identity`, richtige Rolle? (2) CloudTrail: Welche Aktion scheitert, S3 oder KMS (`aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=GenerateDataKey`)? (3) Key Policy mit `aws kms get-key-policy --key-id ... --policy-name default` prüfen. (4) Policy Simulator für `kms:GenerateDataKey`. (5) SCPs, Endpunkt-Richtlinien und Bucket-Policy prüfen. Ursachen: Key Policy erlaubt die Rolle nicht; IAM-Rolle hat keine KMS-Rechte; SCP verbietet die KMS-Aktion oder Region; Schlüssel deaktiviert oder zur Löschung vorgemerkt; Bucket-Policy verlangt eine andere Verschlüsselung; Schlüssel in einer anderen Region.
