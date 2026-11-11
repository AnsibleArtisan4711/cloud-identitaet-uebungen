# Modul 5 - Storage, Datenbanken und Datenplattformen

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 10 h laut Modulübersicht (die Einheiten summieren sich laut Detailblatt auf 9 h)

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit             | Dauer (h) |
|----:|:------------------------|----------:|
| 5.1 | S3 Grundlagen           |      1,25 |
| 5.2 | S3 Storage Classes      |      1,25 |
| 5.3 | S3 Security             |      1,25 |
| 5.4 | EBS und Snapshots       |         1 |
| 5.5 | EFS und FSx             |         1 |
| 5.6 | RDS Grundlagen          |      1,25 |
| 5.7 | DynamoDB Grundlagen     |      1,25 |
| 5.8 | Analytics-Überblick     |      0,75 |
|     | **Summe der Einheiten** |     **9** |

> **Merke**
>
> Hinweis zum Lehrplan: Die Modulübersicht nennt 10 Stunden, die Einheiten im Detailblatt ergeben 9 Stunden. Alle acht Einheiten sind vollständig behandelt; die Differenz ist für Übungen und Nacharbeit gedacht.

Daten sind der Kern fast jeder Anwendung, und AWS bietet für jede Art von Daten einen eigenen Dienst. Die Kunst besteht darin, den richtigen auszuwählen: Dateien und Objekte gehören in S3, Festplatten für Server sind EBS, gemeinsam genutzte Dateisysteme sind EFS oder FSx, strukturierte Daten mit Beziehungen liegen in RDS, extrem skalierbare Schlüssel-Wert-Daten in DynamoDB, und große Auswertungen laufen über Redshift, Athena und Verwandte. Dieses Modul erklärt jeden Baustein, seine Stärken, seine Grenzen und die Sicherheits- und Kostenaspekte. Querverweise: Verschlüsselung und Schlüssel werden in Modul 08 vertieft, Backup und Wiederherstellung in Modul 12.

## 5.1 S3 Grundlagen

*Amazon Simple Storage Service* (S3) ist der Objektspeicher von AWS. Er speichert beliebige Dateien (Fotos, Videos, Backups, Logs, Webseiten, Datensätze) als *Objekte* in *Buckets*. Ein Bucket ist ein Container mit einem weltweit eindeutigen Namen, der einer bestimmten Region angehört. Ein Objekt besteht aus den Daten, einem *Key* (dem Namen, der zugleich als Pfad wirkt, zum Beispiel `berichte/2026/umsatz.pdf`), Metadaten und optional einer Versionsnummer. Ein einzelnes Objekt kann bis zu fünf Terabyte groß sein; die Zahl der Objekte in einem Bucket ist unbegrenzt.

Was bedeutet “Objektspeicher” im Unterschied zu anderen Speicherarten? Beim *Blockspeicher* (EBS) wird eine Festplatte in feste Blöcke zerlegt, die ein Betriebssystem formatiert und direkt beschreibt. Ein *Dateisystem* (EFS) bietet Verzeichnisse und Dateien mit Zugriffsrechten, die mehrere Rechner gleichzeitig einbinden. Ein *Objektspeicher* kennt keine Verzeichnisse im eigentlichen Sinn, sondern eine flache Struktur aus Schlüsseln; Zugriff erfolgt über eine HTTP-API (GET, PUT, DELETE) und nicht über ein eingebundenes Laufwerk. Dafür skaliert er praktisch unbegrenzt, ist sehr günstig und von überall erreichbar. Daten werden automatisch auf mehrere Rechenzentren (Zonen) einer Region verteilt; AWS nennt für S3 Standard eine Haltbarkeit von 99,999999999 Prozent (elf Neunen) über das Jahr, was bedeutet, dass der Verlust eines Objekts extrem unwahrscheinlich ist. Haltbarkeit ist nicht dasselbe wie Verfügbarkeit: Sie sagt, dass Daten nicht verloren gehen, nicht, dass der Dienst jede Sekunde antwortet.

Zu den Standardfunktionen gehört das *Versioning*. Ist es aktiviert, legt S3 bei jedem Überschreiben oder Löschen eine neue Version an, statt das Alte zu zerstören; ein Löschen setzt nur eine Löschmarkierung. So lassen sich versehentlich gelöschte oder überschriebene Dateien wiederherstellen. Weitere Funktionen sind statisches Webhosting, Ereignisbenachrichtigungen (zum Beispiel Lambda starten, wenn eine Datei eintrifft), Replikation in andere Buckets oder Regionen und Multipart-Upload für große Dateien. S3 ist stark konsistent: Nach einem erfolgreichen Schreiben liefert jedes folgende Lesen den neuen Stand.

Das folgende Beispiel legt einen Bucket mit Versionierung an, lädt eine Datei hoch, überschreibt sie und zeigt beide Versionen.

```bash
B=mein-lernbucket-2026-12345
aws s3api create-bucket --bucket $B --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1
aws s3api put-bucket-versioning --bucket $B \
  --versioning-configuration Status=Enabled

echo "Version 1" > notiz.txt
aws s3 cp notiz.txt s3://$B/notizen/notiz.txt
echo "Version 2" > notiz.txt
aws s3 cp notiz.txt s3://$B/notizen/notiz.txt

aws s3api list-object-versions --bucket $B --prefix notizen/ \
  --query 'Versions[].{Key:Key,Id:VersionId,Neueste:IsLatest}'
```

`create-bucket` legt den Bucket in Frankfurt an; außerhalb von `us-east-1` muss die Region zusätzlich als `LocationConstraint` angegeben werden. `put-bucket-versioning` schaltet die Versionierung ein. Die beiden Uploads verwenden denselben Key `notizen/notiz.txt`, der Schrägstrich ist nur Teil des Namens, S3 zeigt ihn in der Console als Ordner an. `list-object-versions` zeigt, dass zwei Versionen vorhanden sind und nur eine davon die neueste ist. Mit `--version-id` kann man eine ältere Version herunterladen.

### Typische Fehler.

Falsch: S3 wie ein Laufwerk zu betrachten und Datenbankdateien oder ständig veränderte Blöcke dort abzulegen; dafür eignet sich EBS. Falsch: Verzeichnisse “anlegen” zu wollen; man legt Objekte mit Präfix an. Falsch: Davon auszugehen, dass Versionierung kostenlos ist; jede Version belegt Speicher und wird berechnet, deshalb gehören Lebenszyklusregeln dazu. Falsch: Einen nicht eindeutigen Bucket-Namen zu erwarten; der Name muss weltweit eindeutig sein.

### Praxisbezug.

Eine Anwendung speichert Nutzer-Uploads in S3 statt auf dem Webserver. Dadurch sind die Webserver zustandslos und lassen sich beliebig vervielfachen (Modul 04), und die Daten überleben jeden Serverausfall.

> **Merke**
>
> S3 = Objektspeicher über HTTP-API, Buckets sind regional und weltweit eindeutig benannt, Objekte bis 5 TB, elf Neunen Haltbarkeit, Versioning schützt vor versehentlichem Überschreiben und Löschen.

## 5.2 S3 Storage Classes

Nicht alle Daten werden gleich oft gebraucht, und AWS bepreist den Speicher entsprechend. Eine *Storage Class* legt fest, wie Objekte gespeichert werden und was Speicher, Abruf und Mindestlaufzeit kosten. Je seltener man auf Daten zugreift, desto günstiger ist der Speicherplatz, desto teurer ist aber der Abruf und desto länger kann er dauern.

*S3 Standard* ist die Voreinstellung für häufig genutzte Daten mit geringer Latenz. *S3 Intelligent-Tiering* verschiebt Objekte automatisch zwischen Zugriffsstufen je nach tatsächlicher Nutzung und ist ideal, wenn das Zugriffsmuster unbekannt oder wechselnd ist; dafür fällt eine kleine Überwachungsgebühr pro Objekt an. *S3 Standard-IA* (Infrequent Access) ist für Daten gedacht, die selten gelesen, aber bei Bedarf sofort gebraucht werden, zum Beispiel Backups; sie liegt in mehreren Zonen. *S3 One Zone-IA* speichert nur in einer Zone, ist dadurch billiger und eignet sich für leicht wiederherstellbare Daten, überlebt aber den Ausfall dieser Zone nicht. Für Archive gibt es die *S3 Glacier*-Klassen: *Glacier Instant Retrieval* (Abruf in Millisekunden, für selten gelesene Archive), *Glacier Flexible Retrieval* (Abruf in Minuten bis Stunden) und *Glacier Deep Archive* (die günstigste Klasse, Abruf typischerweise innerhalb von Stunden bis etwa einem halben Tag, für Daten, die man über Jahre aufbewahren muss und kaum liest, etwa aus rechtlichen Gründen).

Kostenfaktoren sind also: Speicherpreis pro Gigabyte und Monat, Preis pro Abruf, Abrufgebühr pro Gigabyte, Mindestspeicherdauer (bei den IA-Klassen 30 Tage, bei den Glacier-Klassen mindestens 90 beziehungsweise 180 Tage) und Datenübertragung ins Internet. Wer Objekte früher löscht, zahlt trotzdem die Mindestdauer. Die genauen Preise stehen auf der AWS-Preisseite und ändern sich.

Statt Daten von Hand zu verschieben, nutzt man *Lebenszyklusregeln* (Lifecycle Rules). Eine Regel legt fest, dass Objekte nach einer bestimmten Anzahl Tage in eine günstigere Klasse wechseln und nach einer weiteren Frist gelöscht werden. Das folgende Beispiel verschiebt Logdateien nach 30 Tagen in Standard-IA, nach 90 Tagen in Glacier Flexible Retrieval und löscht sie nach einem Jahr.

```bash
cat > lifecycle.json <<'EOT'
{
  "Rules": [{
    "ID": "logs-archivieren",
    "Status": "Enabled",
    "Filter": {"Prefix": "logs/"},
    "Transitions": [
      {"Days": 30, "StorageClass": "STANDARD_IA"},
      {"Days": 90, "StorageClass": "GLACIER"}
    ],
    "Expiration": {"Days": 365}
  }]
}
EOT
aws s3api put-bucket-lifecycle-configuration \
  --bucket mein-lernbucket-2026-12345 \
  --lifecycle-configuration file://lifecycle.json
```

Die Regel gilt nur für Objekte mit dem Präfix `logs/`. `Transitions` beschreibt die Wechsel (der Schlüssel `GLACIER` steht für Glacier Flexible Retrieval), `Expiration` das Löschen nach 365 Tagen. Der Befehl wendet die Regel auf den Bucket an. Zu beachten ist, dass sehr kleine Objekte beim Wechsel in IA-Klassen nicht immer günstiger werden, weil eine Mindestgröße für die Abrechnung gilt.

### Typische Fehler.

Falsch: Ein Archiv in Glacier Deep Archive zu legen und dann kurzfristig Zugriff zu erwarten. Falsch: Millionen kleiner Dateien in eine IA-Klasse zu verschieben und dabei die Mindestgröße zu ignorieren. Falsch: One Zone-IA für einzige Kopien wichtiger Daten. Richtig: Zugriffsmuster bestimmen, bei Unsicherheit Intelligent-Tiering nutzen, und alles Übrige per Lebenszyklusregel automatisieren.

### Praxisbezug.

Ein Unternehmen speichert Rechnungsdokumente zehn Jahre. Im ersten Monat liegen sie in Standard, nach einem Jahr in Glacier Instant Retrieval, nach drei Jahren in Deep Archive. Die Speicherkosten sinken so deutlich, ohne dass jemand Dateien umlagern muss.

## 5.3 S3 Security

S3-Fehlkonfigurationen gehören zu den bekanntesten Ursachen für öffentlich gewordene Daten. Nach dem Shared Responsibility Model (Modul 01) stellt AWS die Mittel zum Schutz bereit, der Kunde muss sie richtig einsetzen. Die Schutzschichten lassen sich in Zugriffsregelung, Verschlüsselung und Überwachung gliedern.

Zur Zugriffsregelung dienen IAM-Policies (was darf eine Identität), *Bucket Policies* (eine Ressourcenrichtlinie am Bucket, die auch Zugriff für andere Konten und Dienste regeln kann) und, historisch, *ACLs*. Neue Buckets haben ACLs standardmäßig deaktiviert (Einstellung *Bucket owner enforced*), und der Zugriff soll über Policies laufen. Eine zentrale Absicherung ist *Block Public Access*: vier Schalter, die auf Bucket- oder Kontoebene verhindern, dass Bucket oder Objekte öffentlich zugänglich werden, selbst wenn eine fehlerhafte Policy es erlauben würde. Neue Buckets haben diese Schalter heute standardmäßig aktiv; man sollte sie nur für Ausnahmen wie bewusst öffentliche Webseiten ändern, und dann besser über CloudFront ausliefern. *Presigned URLs* erlauben es, einer Person zeitlich begrenzten Zugriff auf ein einzelnes Objekt zu geben, ohne den Bucket zu öffnen.

Bei der Verschlüsselung unterscheidet man *in Transit* (Übertragung per HTTPS/TLS) und *at Rest* (gespeicherte Daten). S3 verschlüsselt neue Objekte standardmäßig serverseitig mit von S3 verwalteten Schlüsseln (SSE-S3). Alternativen sind SSE-KMS (Schlüssel im AWS Key Management Service, mit Nutzungsprotokoll und eigener Zugriffsregelung) und SSE-C (Schlüssel vom Kunden mitgegeben). Ergänzend gibt es *Object Lock* für unveränderliche Speicherung (WORM, Write Once Read Many) und *MFA Delete*, das für das Löschen von Versionen einen zweiten Faktor verlangt. Zur Überwachung dienen CloudTrail-Datenereignisse, S3-Serverzugriffsprotokolle, Amazon Macie (findet sensible Daten) und IAM Access Analyzer (findet öffentlich oder kontoübergreifend zugängliche Buckets).

Eine übliche Absicherung ist eine Bucket Policy, die unverschlüsselte Zugriffe ablehnt. Das folgende Beispiel zeigt sie zusammen mit dem Aktivieren von Block Public Access.

```bash
B=mein-lernbucket-2026-12345
aws s3api put-public-access-block --bucket $B \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

cat > policy.json <<'EOT'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "NurHttps",
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": ["arn:aws:s3:::mein-lernbucket-2026-12345",
                 "arn:aws:s3:::mein-lernbucket-2026-12345/*"],
    "Condition": {"Bool": {"aws:SecureTransport": "false"}}
  }]
}
EOT
aws s3api put-bucket-policy --bucket $B --policy file://policy.json
aws s3 presign s3://$B/notizen/notiz.txt --expires-in 600
```

Der erste Befehl setzt die vier Schalter von Block Public Access. Die Policy verweigert (`Deny`) allen Anfragenden alle S3-Aktionen auf Bucket und Objekten, wenn die Verbindung nicht verschlüsselt ist (`aws:SecureTransport` gleich `false`); das erzwingt HTTPS. Der letzte Befehl erzeugt eine temporäre Adresse, die zehn Minuten lang (600 Sekunden) den Download dieses einen Objekts erlaubt.

### Typische Fehler.

Falsch: Bucket “öffentlich” zu machen, um ein Zugriffsproblem schnell zu lösen. Richtig: Die genaue Ursache in Rollen- und Bucket-Policy suchen (Modul 03). Falsch: Zu glauben, dass ein schwer zu erratender Bucket-Name Schutz bietet. Falsch: Eine Policy mit `"Principal": "*"` und `Allow` zu schreiben, ohne Bedingungen. Falsch: Verschlüsselung mit Zugriffsschutz zu verwechseln; wer die Berechtigung hat, liest die Daten entschlüsselt.

### Praxisbezug.

In Sicherheitsprüfungen werden zuerst alle Buckets nach öffentlichem Zugriff durchsucht. Mit Block Public Access auf Kontoebene und einem Access-Analyzer-Alarm lässt sich das Risiko organisationsweit abfangen.

> **Merke**
>
> S3 absichern: Block Public Access, Zugriff über Policies, HTTPS erzwingen, Verschlüsselung (SSE-S3 Standard, SSE-KMS bei Bedarf), Versioning, Object Lock, Überwachung mit CloudTrail, Macie, Access Analyzer.

## 5.4 EBS und Snapshots

*Amazon Elastic Block Store* (EBS) liefert persistente Festplatten für EC2-Instanzen. Ein *Volume* verhält sich wie ein angeschlossenes Laufwerk, das das Betriebssystem formatiert und mit Dateisystemen versieht. Es überlebt das Stoppen der Instanz und kann auf Wunsch auch ohne die Instanz bestehen bleiben. Ein Volume liegt in genau einer Availability Zone und lässt sich nur an Instanzen derselben Zone anhängen; um Daten in eine andere Zone zu bringen, nutzt man Snapshots. Die Daten werden innerhalb der Zone redundant gespeichert.

Es gibt mehrere Volume-Typen. SSD-basierte Typen eignen sich für Betriebssysteme, Datenbanken und andere Anwendungen mit vielen kleinen Zugriffen: `gp3` ist die allgemeine Standardwahl, bei der Größe, Durchsatz und IOPS (Ein-/Ausgabeoperationen pro Sekunde) unabhängig eingestellt werden können; `io2` ist für anspruchsvolle Datenbanken mit garantierten hohen IOPS gedacht. HDD-basierte Typen sind günstiger für große, sequentielle Datenmengen: `st1` für Durchsatz (zum Beispiel Datenanalyse) und `sc1` für selten genutzte Daten. Volumes lassen sich im Betrieb vergrößern und der Typ ändern, ohne die Instanz zu stoppen, danach muss man das Dateisystem im Betriebssystem erweitern. EBS-Volumes können mit KMS-Schlüsseln verschlüsselt werden; das betrifft auch Snapshots und aus ihnen erzeugte Volumes.

Ein *Snapshot* ist eine Momentaufnahme eines Volumes, die AWS in S3 verwaltet (nicht als sichtbare Objekte im eigenen Bucket). Der erste Snapshot kopiert alle verwendeten Blöcke, spätere sind *inkrementell*: Sie speichern nur, was sich seit dem letzten Snapshot geändert hat, und verhalten sich beim Wiederherstellen trotzdem wie vollständige Abbilder. Aus einem Snapshot lässt sich ein neues Volume erstellen, auch in einer anderen Zone, und der Snapshot kann in eine andere Region kopiert und mit anderen Konten geteilt werden. Mit Amazon Data Lifecycle Manager oder AWS Backup lassen sich Snapshots automatisieren.

Das folgende Beispiel legt ein Volume an, hängt es an eine Instanz, erstellt einen Snapshot und stellt daraus in einer anderen Zone ein neues Volume her.

```bash
aws ec2 create-volume --availability-zone eu-central-1a \
  --size 20 --volume-type gp3 --encrypted \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=daten}]'
aws ec2 attach-volume --volume-id vol-0123456789abcdef0 \
  --instance-id i-0123456789abcdef0 --device /dev/sdf

aws ec2 create-snapshot --volume-id vol-0123456789abcdef0 \
  --description "Sicherung vor Update"
aws ec2 create-volume --availability-zone eu-central-1b \
  --snapshot-id snap-0123456789abcdef0 --volume-type gp3
```

Das erste Volume ist 20 GiB groß, vom Typ gp3 und verschlüsselt, und liegt in Zone `eu-central-1a`; die Zone muss mit der Zone der Instanz übereinstimmen. `attach-volume` hängt es als Gerät `/dev/sdf` an. Im Betriebssystem muss man es noch formatieren (zum Beispiel `mkfs`) und einbinden (`mount`). Der Snapshot sichert den Stand; das letzte Volume wird aus dem Snapshot in der Zone `eu-central-1b` erzeugt, was einen Zonenwechsel ermöglicht. IDs sind Platzhalter.

### Typische Fehler.

Falsch: Anzunehmen, dass ein EBS-Volume automatisch in mehreren Zonen verfügbar ist. Falsch: Snapshots als einziges Backup ohne Test der Wiederherstellung zu betrachten. Falsch: Beim Terminieren einer Instanz zu vergessen, dass das Root-Volume standardmäßig mit gelöscht wird (Schalter *Delete on Termination*). Falsch: Unbenutzte Volumes und alte Snapshots liegen zu lassen; sie verursachen weiter Kosten.

### Praxisbezug.

Vor einem Betriebssystem-Update erstellt das Team einen Snapshot; geht etwas schief, wird aus ihm ein neues Volume erzeugt und die Instanz in Minuten zurückgesetzt.

## 5.5 EFS und FSx

Manchmal brauchen mehrere Server gleichzeitig Zugriff auf dieselben Dateien, etwa Webserver, die gemeinsame Uploads teilen. Ein EBS-Volume ist dafür ungeeignet, weil es an eine Instanz gebunden ist. Dafür gibt es verwaltete Dateisysteme.

*Amazon Elastic File System* (EFS) ist ein elastisches Dateisystem für Linux auf Basis des NFS-Protokolls. Es wächst und schrumpft automatisch mit der Datenmenge, man bezahlt nur den genutzten Platz. EFS ist standardmäßig regional: Die Daten liegen redundant in mehreren Zonen, und Instanzen in jeder dieser Zonen können es gleichzeitig einbinden (mounten). Es eignet sich für Webinhalte, Entwicklungsumgebungen, Home-Verzeichnisse und Container, die gemeinsame Daten benötigen. Es gibt Speicherklassen (Standard, Infrequent Access, Archive) und Lebenszyklusverwaltung, die selten gelesene Dateien automatisch in günstigere Klassen verschiebt.

*Amazon FSx* ist eine Familie verwalteter Dateisysteme für spezielle Anforderungen. *FSx for Windows File Server* bietet echte Windows-Dateifreigaben (SMB-Protokoll) mit Active-Directory-Integration. *FSx for Lustre* liefert ein sehr schnelles Dateisystem für Hochleistungsberechnungen und maschinelles Lernen. *FSx for NetApp ONTAP* und *FSx for OpenZFS* bieten bekannte Funktionen dieser Systeme in der Cloud. Zur Auswahl hilft die Frage: Linux und einfach? EFS. Windows und SMB? FSx for Windows. Hochleistungsberechnung? FSx for Lustre.

Im Vergleich der drei Speicherarten (siehe Tabelle) ergibt sich ein klares Bild.

|                  | S3                       | EBS                               | EFS                  |
|:-----------------|:-------------------------|:----------------------------------|:---------------------|
| Art              | Objekt                   | Block                             | Datei (NFS)          |
| Zugriff          | HTTP-API                 | von einer Instanz (in einer Zone) | von vielen Instanzen |
| Skalierung       | unbegrenzt               | feste Größe, vergrößerbar         | wächst automatisch   |
| Typische Nutzung | Archive, Medien, Backups | Betriebssystem, Datenbank         | gemeinsame Dateien   |

Das folgende Beispiel erzeugt ein EFS-Dateisystem, legt einen Mountpunkt in einem Subnetz an und zeigt, wie man es auf einer Linux-Instanz einbindet.

```bash
aws efs create-file-system --encrypted --performance-mode generalPurpose \
  --tags Key=Name,Value=gemeinsam
aws efs create-mount-target --file-system-id fs-0123456789abcdef0 \
  --subnet-id subnet-aaaa1111 --security-groups sg-0123456789abcdef0

# auf der Linux-Instanz:
sudo dnf install -y amazon-efs-utils
sudo mkdir -p /mnt/efs
sudo mount -t efs -o tls fs-0123456789abcdef0:/ /mnt/efs
df -h /mnt/efs
```

Das Dateisystem wird verschlüsselt angelegt. Ein *Mount Target* ist der Netzwerkzugang in einem Subnetz (je Zone eines); die zugehörige Security Group muss den NFS-Port 2049 von den Instanzen erlauben. Die Befehle darunter laufen auf der Instanz: Das Hilfspaket `amazon-efs-utils` bringt den Mount-Typ `efs` mit, `-o tls` verschlüsselt die Übertragung, und `df` bestätigt das eingebundene Dateisystem. Die IDs sind Platzhalter.

### Typische Fehler.

Falsch: EFS mit Windows-Servern einbinden zu wollen; dafür gibt es FSx for Windows. Falsch: Die Security Group des Mount Targets zu vergessen, was zu Zeitüberschreitungen beim Mounten führt. Falsch: EFS als Ersatz für lokale Hochleistungs-Festplatten bei einer Datenbank zu verwenden, wo Latenz entscheidend ist.

### Praxisbezug.

Mehrere WordPress-Server hinter einem Load Balancer teilen sich über EFS dasselbe Verzeichnis für Uploads, sodass jeder Server dieselben Dateien sieht.

## 5.6 RDS Grundlagen

*Amazon Relational Database Service* (RDS) betreibt relationale Datenbanken als verwalteten Dienst. Relationale Datenbanken speichern Daten in Tabellen mit Zeilen und Spalten, verknüpfen sie über Schlüssel und werden per SQL abgefragt. Sie sind die richtige Wahl, wenn Daten klare Beziehungen haben und Transaktionen mit Konsistenzgarantien (ACID) nötig sind, etwa bei Bestellungen oder Buchungen.

RDS unterstützt mehrere Datenbank-Engines: MySQL, PostgreSQL, MariaDB, Oracle, Microsoft SQL Server und Db2. Daneben gibt es *Amazon Aurora*, eine von AWS entwickelte, mit MySQL und PostgreSQL kompatible Engine mit höherer Leistung und Ausfallsicherheit; ihr Speicher verteilt sich automatisch über mehrere Zonen. Was nimmt RDS dem Kunden ab? Es installiert und patcht die Datenbanksoftware, richtet Backups ein, überwacht, ersetzt defekte Hardware und ermöglicht Hochverfügbarkeit per Knopfdruck. Was bleibt beim Kunden? Das Datenbankschema, die Abfragen und Indizes, die Wahl der Instanzgröße, Benutzerverwaltung, Netzwerkzugriff, Verschlüsselung und Parameter. Auf das Betriebssystem der Datenbank-Instanz hat man keinen Zugriff, das ist der Preis der Verwaltung.

Zentrale Funktionen sind drei. *Multi-AZ* erzeugt eine Standby-Instanz in einer anderen Zone, die synchron mitgeschrieben wird; fällt die Hauptinstanz aus, wechselt RDS automatisch dorthin. Es dient der Ausfallsicherheit, nicht der Leistung, da die Standby-Instanz keine Leseanfragen bedient (bei der Multi-AZ-Variante mit zwei lesbaren Standbys gilt das eingeschränkt). *Read Replicas* sind asynchron aktualisierte Kopien, die Leseanfragen aufnehmen und damit die Leistung steigern; sie können auch in anderen Regionen liegen. *Backups*: Automatische Sicherungen mit Aufbewahrung von einem bis 35 Tagen ermöglichen die Wiederherstellung auf einen beliebigen Zeitpunkt (*Point-in-Time Recovery*); zusätzlich kann man manuelle Snapshots erstellen, die bestehen bleiben, bis man sie löscht. Verschlüsselung wird über KMS aktiviert und lässt sich nachträglich nur über einen Snapshot-Umweg einschalten, weshalb man sie gleich beim Anlegen wählt.

Das folgende Beispiel legt eine PostgreSQL-Datenbank mit Multi-AZ, Verschlüsselung und siebentägigen Sicherungen an, erzeugt eine Read Replica und einen manuellen Snapshot.

```bash
aws rds create-db-instance --db-instance-identifier shop-db \
  --engine postgres --db-instance-class db.t3.medium \
  --allocated-storage 50 --storage-encrypted \
  --master-username dbadmin --manage-master-user-password \
  --multi-az --backup-retention-period 7 \
  --db-subnet-group-name privat-subnetze \
  --vpc-security-group-ids sg-0123456789abcdef0 \
  --no-publicly-accessible

aws rds create-db-instance-read-replica \
  --db-instance-identifier shop-db-lesen --source-db-instance-identifier shop-db
aws rds create-db-snapshot --db-instance-identifier shop-db \
  --db-snapshot-identifier shop-db-vor-update
```

`--storage-encrypted` verschlüsselt die Daten, `--multi-az` legt die Standby-Instanz an, und `--backup-retention-period 7` hält die automatischen Sicherungen sieben Tage. `--manage-master-user-password` lässt AWS das Administratorpasswort im Secrets Manager verwalten. `--no-publicly-accessible` verhindert, dass die Datenbank eine öffentliche Adresse erhält; sie ist nur aus dem privaten Netz erreichbar. Die Gruppe `privat-subnetze` (eine DB-Subnetzgruppe) und die Security Group sind Platzhalter. Die Read Replica erhält eine eigene Adresse, an die man Leseabfragen richtet.

### Typische Fehler.

Falsch: Multi-AZ als Leistungsverbesserung zu betrachten oder als Backup. Richtig: Multi-AZ = Ausfallsicherheit, Read Replica = Lesen skalieren, Backups = Wiederherstellung nach Fehlern. Falsch: Die Datenbank öffentlich erreichbar zu machen. Falsch: Eine RDS-Instanz für unstrukturierte, extrem skalierende Schlüssel-Wert-Daten einzusetzen, wofür DynamoDB besser passt.

### Praxisbezug.

Ein Webshop nutzt RDS Multi-AZ für Bestellungen und eine Read Replica für Berichte, damit lange Auswertungen die Bestellabwicklung nicht bremsen.

> **Merke**
>
> RDS = verwaltete relationale Datenbank. Multi-AZ = Standby für Ausfälle (synchron). Read Replica = Lesen skalieren (asynchron). Automatische Backups 1 bis 35 Tage mit Point-in-Time Recovery. Aurora = AWS-eigene, leistungsstarke Variante.

## 5.7 DynamoDB Grundlagen

*Amazon DynamoDB* ist eine vollständig verwaltete, serverlose NoSQL-Datenbank für Schlüssel-Wert- und Dokumentdaten. NoSQL steht für “nicht nur SQL”: Statt starrer Tabellen mit festem Schema und Verknüpfungen speichert man Elemente, die sich in ihren Feldern unterscheiden dürfen, und greift gezielt über Schlüssel zu. Dafür bietet DynamoDB konstante Antwortzeiten im einstelligen Millisekundenbereich, praktisch unbegrenzte Skalierung und keinerlei Verwaltung von Servern, Patches oder Kapazität im herkömmlichen Sinn.

Eine *Tabelle* enthält *Items* (Elemente, vergleichbar mit Zeilen) mit *Attributen* (Feldern). Jedes Item hat einen *Primärschlüssel*, der entweder aus einem *Partition Key* allein oder aus Partition Key und *Sort Key* besteht. Der Partition Key bestimmt, auf welcher physischen Partition das Item liegt; deshalb sollte er viele verschiedene Werte haben, damit die Last gleichmäßig verteilt wird (zum Beispiel eine Kunden-ID statt einer Konstanten). Der Sort Key ordnet Items innerhalb derselben Partition und ermöglicht Bereichsabfragen, zum Beispiel alle Bestellungen eines Kunden in einem Zeitraum. Abfragen über andere Attribute lösen *Sekundärindizes* (Global oder Local Secondary Index).

Für den Durchsatz gibt es zwei Abrechnungsmodi. Im *On-Demand*-Modus zahlt man pro Lese- und Schreibzugriff, ohne etwas planen zu müssen; das passt zu unvorhersehbaren Lasten. Im *Provisioned*-Modus legt man die gewünschten Lese- und Schreibeinheiten fest, kann Auto Scaling nutzen und spart bei stabiler Last. Weitere Funktionen sind *Global Tables* (automatische Replikation über mehrere Regionen), *Point-in-Time Recovery*, *TTL* (Items laufen automatisch ab), Streams (Änderungsereignisse, die zum Beispiel Lambda auslösen) und der Cache *DAX*, der Antwortzeiten in den Mikrosekundenbereich bringt. Daten sind standardmäßig verschlüsselt.

Das folgende Beispiel legt eine Tabelle an, schreibt Items und fragt sie ab.

```bash
aws dynamodb create-table --table-name Bestellungen \
  --attribute-definitions AttributeName=KundenId,AttributeType=S \
                          AttributeName=Datum,AttributeType=S \
  --key-schema AttributeName=KundenId,KeyType=HASH \
               AttributeName=Datum,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

aws dynamodb put-item --table-name Bestellungen --item \
  '{"KundenId":{"S":"K100"},"Datum":{"S":"2026-10-01"},"Summe":{"N":"59.90"}}'

aws dynamodb query --table-name Bestellungen \
  --key-condition-expression "KundenId = :k AND Datum >= :d" \
  --expression-attribute-values '{":k":{"S":"K100"},":d":{"S":"2026-10-01"}}'
```

Die Tabelle hat als Partition Key (`HASH`) die `KundenId` und als Sort Key (`RANGE`) das `Datum`; nur Schlüsselattribute werden vorab definiert, alle anderen Felder sind frei. `PAY\_PER\_REQUEST` schaltet On-Demand ein. `put-item` schreibt ein Item, wobei jeder Wert mit seinem Datentyp (`S` für Text, `N` für Zahl) angegeben wird. Die `query`-Anfrage holt alle Bestellungen von Kunde K100 ab dem 1. Oktober; sie ist effizient, weil sie über Schlüssel arbeitet. Ein `scan`, der die ganze Tabelle liest, wäre bei großen Tabellen langsam und teuer.

### Typische Fehler.

Falsch: DynamoDB wie eine relationale Datenbank mit Joins zu benutzen; Joins gibt es nicht, man modelliert Daten nach den Abfragen. Falsch: Einen Partition Key mit wenigen Werten zu wählen (“Hot Partition”), sodass eine Partition überlastet wird. Falsch: Regelmäßig `scan` zu verwenden. Richtig: Zugriffsmuster zuerst festlegen und danach Schlüssel und Indizes entwerfen.

### Praxisbezug.

Ein Online-Spiel speichert Spielstände pro Spieler in DynamoDB; die Zugriffe sind einfach (Spieler-ID), die Last schwankt stark, und niemand muss Datenbankserver betreuen.

## 5.8 Analytics-Überblick

Auswertungen über große Datenmengen haben andere Anforderungen als das Tagesgeschäft einer Anwendung. Transaktionsdatenbanken (OLTP, Online Transaction Processing) wie RDS oder DynamoDB verarbeiten viele kleine Lese- und Schreibzugriffe auf einzelne Datensätze. Analytische Systeme (OLAP, Online Analytical Processing) lesen dagegen riesige Datenmengen und berechnen Summen, Trends und Zusammenhänge. Deshalb trennt man beides: Eine Auswertung, die eine Bestelldatenbank komplett durchsucht, würde den Shop ausbremsen.

Die wichtigsten Dienste lassen sich grob so einordnen. *Amazon Redshift* ist ein Data Warehouse: eine spaltenorientierte Datenbank, die für komplexe SQL-Abfragen über sehr große Datenmengen optimiert ist. *Amazon Athena* fragt Daten direkt in S3 mit SQL ab, ohne Server oder Ladevorgang; abgerechnet wird nach der gescannten Datenmenge, weshalb komprimierte, spaltenorientierte Formate (zum Beispiel Parquet) und Partitionierung Kosten senken. *AWS Glue* ist ein ETL-Dienst (Extract, Transform, Load): Er entdeckt Daten, führt Katalog über sie und transformiert sie. *Amazon Kinesis* verarbeitet Datenströme in Echtzeit, etwa Klickdaten, Sensorwerte oder Logs. *Amazon EMR* betreibt Big-Data-Frameworks wie Spark oder Hadoop, *Amazon OpenSearch Service* ermöglicht Volltextsuche und Log-Analyse, und *Amazon QuickSight* erzeugt Dashboards für Geschäftsanwender.

Ein typisches Muster ist der *Data Lake*: Rohdaten aus vielen Quellen landen in S3, Glue katalogisiert sie, Athena oder Redshift werten sie aus, QuickSight stellt die Ergebnisse dar. So bleibt der Speicher günstig und flexibel, und die Auswertung wird getrennt skaliert.

Das folgende Beispiel zeigt eine Athena-Abfrage direkt auf Dateien in S3. Zuerst wird eine Tabelle definiert, dann abgefragt.

```bash
aws athena start-query-execution \
  --query-string "CREATE EXTERNAL TABLE IF NOT EXISTS umsatz (datum string, region string, betrag double) ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' LOCATION 's3://mein-lernbucket-2026-12345/umsatz/' TBLPROPERTIES ('skip.header.line.count'='1')" \
  --query-execution-context Database=default \
  --result-configuration OutputLocation=s3://mein-lernbucket-2026-12345/ergebnisse/

aws athena start-query-execution \
  --query-string "SELECT region, SUM(betrag) AS summe FROM umsatz GROUP BY region ORDER BY summe DESC" \
  --query-execution-context Database=default \
  --result-configuration OutputLocation=s3://mein-lernbucket-2026-12345/ergebnisse/
```

Die erste Abfrage legt eine externe Tabelle an, die auf CSV-Dateien im angegebenen S3-Pfad zeigt; die Daten werden nicht kopiert. `OutputLocation` bestimmt, wo Athena die Ergebnisse ablegt. Die zweite Abfrage berechnet den Umsatz je Region. Das Ergebnis holt man mit `get-query-results` anhand der zurückgegebenen Abfrage-ID. Es entstehen Kosten nach gescannter Datenmenge, daher sollte man die Beispieldaten klein halten.

### Typische Fehler.

Falsch: Auswertungen direkt auf der Produktionsdatenbank laufen zu lassen. Falsch: Redshift für wenige kleine Abfragen einzusetzen, die Athena billiger beantwortet. Falsch: Rohe, unkomprimierte CSV-Dateien in sehr großen Mengen mit Athena zu scannen, ohne Partitionierung. Falsch: Kinesis mit einem Speicherdienst zu verwechseln; es transportiert und verarbeitet Ströme.

### Praxisbezug.

Ein Händler lässt Kassendaten nachts in S3 sammeln, Athena berechnet Tagesumsätze, QuickSight zeigt sie der Geschäftsführung. Die Shop-Datenbank bleibt unberührt.

## Übungsaufgaben Modul 05

1.  Erklären Sie den Unterschied zwischen Objekt-, Block- und Dateispeicher und ordnen Sie S3, EBS und EFS zu.

2.  Welche S3-Storage-Class wählen Sie für (a) Daten mit unbekanntem Zugriffsmuster, (b) ein rechtlich vorgeschriebenes Zehn-Jahres-Archiv, (c) Backups, die selten, aber sofort gebraucht werden?

3.  Nennen Sie vier Maßnahmen, einen S3-Bucket abzusichern.

4.  Was ist der Unterschied zwischen Multi-AZ und Read Replica bei RDS? Wofür dient welche?

5.  Wozu dient ein Partition Key in DynamoDB und warum sollte er viele verschiedene Werte haben?

6.  **Praxis:** Schreiben Sie eine Lebenszyklusregel, die Objekte mit dem Präfix `backup/` nach 60 Tagen nach Glacier Instant Retrieval verschiebt und nach 3 Jahren löscht.

7.  **Praxis:** Schreiben Sie die CLI-Befehle, um ein verschlüsseltes 50-GiB-gp3-Volume in `eu-central-1a` anzulegen, einen Snapshot zu erstellen und aus ihm ein Volume in `eu-central-1b` herzustellen.

8.  **Praxis:** Entwerfen Sie eine DynamoDB-Tabelle für Kundenbestellungen: Schlüssel, Beispiel-Item und eine Abfrage, die alle Bestellungen eines Kunden im Oktober 2026 liefert.

## Lösungen Modul 05

1.  Objektspeicher (S3): flache Struktur aus Schlüsseln, Zugriff über HTTP-API, unbegrenzt skalierbar. Blockspeicher (EBS): Festplatte für eine Instanz, vom Betriebssystem formatiert. Dateispeicher (EFS): gemeinsames Dateisystem mit Verzeichnissen für viele Rechner (NFS).

2.  \(a\) Intelligent-Tiering. (b) Glacier Deep Archive. (c) Standard-IA (oder Glacier Instant Retrieval bei noch selteneren Zugriffen).

3.  Zum Beispiel: Block Public Access, Zugriff über Policies mit Least Privilege, HTTPS erzwingen, Verschlüsselung (SSE-S3 oder SSE-KMS), Versioning, Object Lock, Protokollierung mit CloudTrail, Access Analyzer und Macie zur Überwachung.

4.  Multi-AZ: synchrone Standby-Instanz in anderer Zone für automatischen Failover (Ausfallsicherheit). Read Replica: asynchrone, lesbare Kopie zur Entlastung der Hauptinstanz bei Leseabfragen (Leistung), auch regionsübergreifend möglich.

5.  Der Partition Key bestimmt die Partition, auf der ein Item liegt. Viele verschiedene Werte verteilen die Last gleichmäßig; wenige Werte führen zu überlasteten Partitionen (Hot Partition) und Drosselung.

6.  ```json
    {
      "Rules": [{
        "ID": "backup-archiv",
        "Status": "Enabled",
        "Filter": {"Prefix": "backup/"},
        "Transitions": [{"Days": 60, "StorageClass": "GLACIER_IR"}],
        "Expiration": {"Days": 1095}
      }]
    }
    ```

    Angewendet mit `aws s3api put-bucket-lifecycle-configuration --bucket NAME --lifecycle-configuration file://regel.json`. Drei Jahre entsprechen 1095 Tagen.

7.  ```bash
    aws ec2 create-volume --availability-zone eu-central-1a \
      --size 50 --volume-type gp3 --encrypted
    aws ec2 create-snapshot --volume-id vol-0123456789abcdef0
    aws ec2 create-volume --availability-zone eu-central-1b \
      --snapshot-id snap-0123456789abcdef0 --volume-type gp3
    ```

    Das Volume aus dem verschlüsselten Snapshot ist wieder verschlüsselt. IDs sind Platzhalter und stammen aus den Ausgaben.

8.  Partition Key `KundenId` (Text), Sort Key `Datum` im Format `JJJJ-MM-TT`, damit sich Bereiche sortieren lassen. Beispiel-Item:

    ```text
    {"KundenId":{"S":"K100"},"Datum":{"S":"2026-10-15"},"Summe":{"N":"59.90"}}
    ```

    Abfrage mit der Schlüsselbedingung `KundenId = :k AND Datum BETWEEN :a AND :b` und den Werten `:a` gleich `2026-10-01` und `:b` gleich `2026-10-31`. Das ist eine effiziente Schlüsselabfrage statt eines Scans.
