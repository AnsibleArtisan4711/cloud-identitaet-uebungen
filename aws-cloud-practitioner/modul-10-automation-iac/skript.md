# Modul 10 - Automation, Deployment und IaC Grundlagen

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 9 h

**Priorität:** 2

|  Nr. | Lerneinheit                | Dauer (h) |
|-----:|:---------------------------|----------:|
| 10.1 | AWS CLI Grundlagen         |         1 |
| 10.2 | SDKs und APIs              |         1 |
| 10.3 | CloudFormation Grundlagen  |      1,25 |
| 10.4 | Terraform-Überblick        |         1 |
| 10.5 | Systems Manager            |      1,25 |
| 10.6 | Deployment Services        |         1 |
| 10.7 | Automation Governance      |      1,25 |
| 10.8 | Automation-Troubleshooting |      1,25 |
|      | **Summe**                  |     **9** |

In den bisherigen Modulen entstanden Ressourcen meist per Einzelbefehl oder Mausklick. Das genügt zum Lernen, aber nicht für den Betrieb: Handarbeit ist langsam, fehleranfällig, schwer zu wiederholen und nicht nachvollziehbar. Dieses Modul zeigt den Weg zur Automatisierung. Man beginnt mit den Schnittstellen (CLI, SDK, API), geht über die deklarative Beschreibung ganzer Umgebungen (Infrastructure as Code mit CloudFormation und Terraform), den Betrieb ohne direkten Serverzugriff (Systems Manager) und die automatische Auslieferung von Software (CI/CD) und endet bei der Frage, wie man Automatisierung kontrolliert und Fehler darin findet. Das Prinzip “Betrieb als Code” aus Modul 09 wird damit konkret.

## 10.1 AWS CLI Grundlagen

Die *AWS Command Line Interface* (CLI) ist ein Werkzeug, mit dem man AWS-Dienste aus der Kommandozeile bedient. Sie ist in den bisherigen Modulen ständig verwendet worden; hier wird ihr Aufbau systematisch erklärt. Ein Befehl besteht aus dem Programm `aws`, dem Dienst, der Operation und den Parametern: `aws ec2 describe-instances --region eu-central-1`. Fast jede Aktion, die die Console anbietet, steht auch als CLI-Befehl zur Verfügung, weil beide dieselbe API verwenden. Die aktuelle Version heißt CLI v2; eine browserbasierte Variante ohne Installation ist die *AWS CloudShell*.

Zur Konfiguration dienen zwei Dateien im Benutzerverzeichnis: `~/.aws/config` (Region, Ausgabeformat, Profile) und `~/.aws/credentials` (Zugangsdaten). Mit *Profilen* verwaltet man mehrere Identitäten oder Konten nebeneinander und wählt sie mit `--profile NAME` oder der Umgebungsvariable `AWS\_PROFILE`. Die CLI sucht Zugangsdaten in einer festen Reihenfolge: zuerst Befehlsparameter, dann Umgebungsvariablen (`AWS\_ACCESS\_KEY\_ID` und weitere), dann Profile (auch IAM-Identity-Center-Anmeldungen), und zuletzt Rollen, die der Umgebung zugewiesen sind, etwa die Instanzrolle einer EC2-Instanz oder die Ausführungsrolle in CloudShell. Wegen dieser Reihenfolge gilt: Auf Servern keine Schlüssel hinterlegen, sondern Rollen verwenden (Modul 03). Mit `aws sts get-caller-identity` prüft man jederzeit, wer man gerade ist.

Nützliche Werkzeuge im Alltag sind der Parameter `--query` (JMESPath-Ausdruck zum Filtern der JSON-Antwort), `--output` (`json`, `table`, `text`, `yaml`), Hilfe über `aws DIENST OPERATION help`, die Option `--dry-run` bei vielen EC2-Befehlen (prüft nur die Berechtigung, ohne etwas zu tun), sowie die `wait`-Befehle, die blockieren, bis ein Zustand erreicht ist. Bei langen Listen wird automatisch seitenweise abgefragt (*Pagination*). Mit `--generate-cli-skeleton` erzeugt man eine Eingabevorlage, die man mit `--cli-input-json` wieder einliest, was bei komplexen Befehlen lesbarer ist als lange Zeilen.

Das folgende Beispiel zeigt eine typische Arbeitssitzung mit Profilen, Abfrage, Probelauf und Warten.

```bash
aws configure --profile test            # Schluessel, Region, Format eingeben
aws configure list --profile test       # zeigt, woher Werte kommen
aws sts get-caller-identity --profile test

aws ec2 describe-instances --profile test --region eu-central-1 \
  --query 'Reservations[].Instances[].{Id:InstanceId,Typ:InstanceType,Status:State.Name}' \
  --output table

aws ec2 run-instances --image-id ami-0123456789abcdef0 \
  --instance-type t3.micro --dry-run --profile test
aws ec2 wait instance-running --instance-ids i-0123456789abcdef0 --profile test
echo "Instanz laeuft"
```

Die ersten Befehle legen ein Profil `test` an und zeigen, welche Einstellungen woher stammen (hilfreich bei verwirrenden Abweichungen). Die Abfrage listet Instanzen als Tabelle mit nur drei Feldern. Der Probelauf mit `--dry-run` antwortet entweder mit `DryRunOperation` (Berechtigung vorhanden, es wurde nichts gestartet) oder mit `UnauthorizedOperation`; beides ist die erwartete “Antwort”. Der `wait`-Befehl blockiert, bis die Instanz läuft, und eignet sich für Skripte, die auf den nächsten Zustand angewiesen sind. IDs sind Platzhalter.

### Typische Fehler.

Falsch: Langlebige Zugriffsschlüssel auf Servern zu hinterlegen. Falsch: Befehle ohne Prüfung von Profil und Region auszuführen und in der falschen Umgebung zu arbeiten. Falsch: Zugangsdaten als Klartext in Skripte oder Verlaufsdateien zu schreiben. Falsch: `--query` mit der Filterung der Ausgabe in der Shell zu verwechseln; `--query` wirkt auf Clientseite nach dem Abruf, `--filters` schon auf Serverseite.

### Praxisbezug.

Wartungsskripte, die abends Instanzen stoppen oder Berichte erzeugen, bestehen oft nur aus wenigen CLI-Zeilen. Sie laufen unter einer Rolle mit minimalen Rechten.

> **Merke**
>
> CLI = Kommandozeile für jede AWS-API. Profile, Reihenfolge der Zugangsdaten (Parameter, Umgebung, Profile, Rollen), `--query`, `--dry-run`, `wait`. Immer mit `get-caller-identity` prüfen, wer man ist.

## 10.2 SDKs und APIs

Hinter jeder Aktion in AWS steht eine *API*: eine definierte Schnittstelle, die Anfragen entgegennimmt und beantwortet. Die Console, die CLI und alle Dienste sprechen mit denselben Programmierschnittstellen; sie basieren auf HTTPS-Aufrufen, die mit den Zugangsdaten signiert werden (*Signature Version 4*). Jeder Aufruf wird authentifiziert, gegen IAM-Richtlinien geprüft und in CloudTrail protokolliert (Modul 07). Weil alles eine API ist, lässt sich alles automatisieren.

Direkte HTTPS-Aufrufe mit eigener Signatur wären mühsam. Deshalb gibt es *SDKs* (Software Development Kits) für viele Sprachen: Python (*Boto3*), JavaScript/TypeScript, Java, .NET, Go, Ruby, PHP, Rust und weitere. Ein SDK übernimmt Signierung, Zugangsdaten-Suche (dieselbe Reihenfolge wie die CLI), Wiederholungen bei vorübergehenden Fehlern, Seitenweises Abrufen und Fehlerbehandlung. Man programmiert dann gegen Objekte und Funktionen statt gegen HTTP. Anwendungen auf AWS erhalten ihre Zugangsdaten über Rollen, sodass im Code keine Schlüssel vorkommen.

Typische Automatisierungen sind Aufräumskripte (ungenutzte Volumes löschen), Berichte, Reaktionen auf Ereignisse (Lambda-Funktionen) und die Integration von AWS-Diensten in eigene Anwendungen (Dateien in S3 ablegen, Nachrichten in SQS legen). Gute Skripte folgen einigen Regeln: Sie sind *idempotent* (mehrfaches Ausführen führt zum gleichen Ergebnis und schadet nicht), behandeln Fehler (Drosselung, fehlende Rechte), schreiben Protokolle und laufen mit minimalen Rechten. Zur Wahl zwischen CLI und SDK: Für kurze, lineare Abläufe genügt die CLI; sobald Logik, Schleifen, Fehlerbehandlung und Tests gefragt sind, ist ein SDK besser.

Das folgende Beispiel zeigt ein kleines Python-Skript mit Boto3, das nicht angehängte EBS-Volumes findet und optional Snapshots erstellt. Es nutzt einen Paginator und Fehlerbehandlung.

```python
import sys
import boto3
from botocore.exceptions import ClientError

ec2 = boto3.client("ec2", region_name="eu-central-1")
trocken = "--ausfuehren" not in sys.argv   # ohne Option nur anzeigen

paginator = ec2.get_paginator("describe_volumes")
seiten = paginator.paginate(
    Filters=[{"Name": "status", "Values": ["available"]}])

for seite in seiten:
    for vol in seite["Volumes"]:
        vid, groesse = vol["VolumeId"], vol["Size"]
        print(f"Nicht angehaengt: {vid} ({groesse} GiB)")
        if trocken:
            continue
        try:
            ec2.create_snapshot(
                VolumeId=vid,
                Description="Sicherung vor Bereinigung",
                TagSpecifications=[{"ResourceType": "snapshot",
                    "Tags": [{"Key": "Quelle", "Value": vid}]}])
            print("  Snapshot angestossen")
        except ClientError as fehler:
            print("  Fehler:", fehler.response["Error"]["Code"])
```

Das Skript erzeugt einen Client für EC2 in Frankfurt; die Zugangsdaten holt Boto3 selbstständig aus der Umgebung. Der `paginator` liest Ergebnisse seitenweise, sodass auch Tausende Volumes funktionieren. Ohne die Kommandozeilenoption `--ausfuehren` läuft es als reiner Probelauf; das ist ein einfaches Sicherheitsnetz. Beim Ausführen legt es für jedes freie Volume einen Snapshot an, und `ClientError` fängt Fehler wie `UnauthorizedOperation` ab. Das Skript löscht bewusst nichts. Ein Löschschritt gehört in einen separaten, bestätigten Lauf.

### Typische Fehler.

Falsch: Zugangsdaten im Quelltext oder im Repository. Falsch: Skripte, die bei Fehlern still weiterlaufen oder bei Wiederholung doppelte Ressourcen erzeugen. Falsch: Die Paginierung zu vergessen; man verarbeitet dann nur die erste Seite (oft 50 bis 1000 Einträge). Falsch: Ohne Probelauf direkt zu löschen.

### Praxisbezug.

Ein Lambda-Skript reagiert auf einen EventBridge-Zeitplan, sucht jede Nacht ungetaggte Ressourcen und meldet sie dem Team. Das kostet Cent-Beträge und ersetzt manuelle Kontrollen.

## 10.3 CloudFormation Grundlagen

*Infrastructure as Code* (IaC) bedeutet, Infrastruktur in Textdateien zu beschreiben, die versioniert, geprüft und automatisch ausgeführt werden, statt sie von Hand zu erzeugen. Die Vorteile sind Wiederholbarkeit (die gleiche Umgebung für Test und Produktion), Nachvollziehbarkeit (Änderungen stehen in der Versionsverwaltung), Geschwindigkeit und die Möglichkeit, Umgebungen vollständig zu löschen und neu aufzubauen. *AWS CloudFormation* ist der AWS-eigene IaC-Dienst. Man beschreibt den gewünschten Endzustand deklarativ, also *was* es geben soll, nicht *wie* es zu erstellen ist, und CloudFormation ermittelt die nötigen Schritte und deren Reihenfolge selbst.

Die Beschreibung heißt *Template* (Vorlage), geschrieben in YAML oder JSON. Die wichtigsten Abschnitte sind `Parameters` (Eingaben, die man beim Start angibt), `Mappings` und `Conditions` (Auswahllogik), `Resources` (die eigentlichen Ressourcen; der einzige Pflichtabschnitt) und `Outputs` (Ausgabewerte wie URLs oder IDs). Innerhalb des Templates verweist man mit eingebauten Funktionen aufeinander: `!Ref` liefert den Bezeichner einer Ressource oder den Wert eines Parameters, `!GetAtt` ein Attribut, `!Sub` setzt Variablen in Texte ein. Aus Abhängigkeiten erkennt CloudFormation die Reihenfolge, zum Beispiel erst die VPC, dann das Subnetz.

Die Ausführung eines Templates erzeugt einen *Stack* (Stapel): die Gesamtheit der daraus entstandenen Ressourcen als verwaltbare Einheit. Löscht man den Stack, werden alle zugehörigen Ressourcen gelöscht. Änderungen am Template wendet man auf den Stack an. Vorher kann man ein *Change Set* (Änderungsvorschau) erzeugen, das zeigt, welche Ressourcen hinzukommen, sich ändern oder ersetzt werden; Ersetzung bedeutet, dass eine Ressource gelöscht und neu erzeugt wird, was bei Datenbanken Datenverlust bedeuten kann, und deshalb verdient die Vorschau besondere Aufmerksamkeit. Schlägt ein Vorgang fehl, macht CloudFormation ihn automatisch rückgängig (*Rollback*). Weitere Funktionen sind *Drift-Erkennung* (zeigt manuelle Abweichungen vom Template), *Nested Stacks* (Vorlagen aus Vorlagen) und *StackSets* (Rollout über viele Konten und Regionen). CloudFormation selbst kostet nichts; bezahlt werden die erzeugten Ressourcen.

Das folgende Beispiel beschreibt einen verschlüsselten, versionierten S3-Bucket mit Ausgabe und zeigt Prüfung, Vorschau und Rollout.

```bash
cat > bucket.yaml <<'EOT'
AWSTemplateFormatVersion: '2010-09-09'
Description: Versionierter, verschluesselter Bucket
Parameters:
  Umgebung:
    Type: String
    AllowedValues: [dev, test, prod]
    Default: dev
Resources:
  DatenBucket:
    Type: AWS::S3::Bucket
    Properties:
      VersioningConfiguration:
        Status: Enabled
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      Tags:
        - Key: Umgebung
          Value: !Ref Umgebung
Outputs:
  BucketName:
    Value: !Ref DatenBucket
  BucketArn:
    Value: !GetAtt DatenBucket.Arn
EOT

aws cloudformation validate-template --template-body file://bucket.yaml
aws cloudformation deploy --template-file bucket.yaml \
  --stack-name daten-bucket --parameter-overrides Umgebung=dev
aws cloudformation describe-stacks --stack-name daten-bucket \
  --query 'Stacks[0].Outputs'
aws cloudformation delete-stack --stack-name daten-bucket
```

Das Template definiert einen Parameter mit erlaubten Werten und eine Ressource vom Typ `AWS::S3::Bucket` mit Versionierung, Verschlüsselung, Sperre öffentlichen Zugriffs und einem Tag, dessen Wert aus dem Parameter stammt. Der Bucket-Name wird bewusst nicht festgelegt; CloudFormation vergibt einen eindeutigen Namen, was Namenskonflikte vermeidet. `validate-template` prüft die Syntax. `deploy` erzeugt einen Change Set und führt ihn aus (beim ersten Mal wird der Stack angelegt, später aktualisiert). Die Ausgaben liefern Namen und ARN. `delete-stack` entfernt alles wieder; ein Bucket mit Inhalt muss vorher geleert werden, sonst schlägt das Löschen fehl.

### Typische Fehler.

Falsch: Ressourcen eines Stacks von Hand zu ändern; das erzeugt Drift und die nächste Aktualisierung überschreibt oder scheitert. Falsch: Feste Namen für Ressourcen zu vergeben, die eine Ersetzung verhindern. Falsch: Change Sets nicht zu lesen und eine Ersetzung der Datenbank zu übersehen. Falsch: Ein ganzes System in ein einziges riesiges Template zu schreiben. Falsch: Passwörter als Parameter im Klartext zu übergeben; stattdessen auf Secrets Manager verweisen.

### Praxisbezug.

Ein Team beschreibt Netzwerk, Datenbank und Anwendung als Templates im Repository. Eine neue Testumgebung entsteht per Knopfdruck und wird nach dem Test gelöscht, was Kosten spart und Reproduzierbarkeit schafft.

> **Merke**
>
> CloudFormation = deklarative IaC. Template (YAML/JSON) → Stack. Change Set zeigt die Wirkung vorher, Rollback bei Fehlern, Drift-Erkennung bei manuellen Änderungen, StackSets für viele Konten. Kosten entstehen nur für die Ressourcen.

## 10.4 Terraform-Überblick

*Terraform* von HashiCorp ist ein weit verbreitetes IaC-Werkzeug, das nicht auf AWS beschränkt ist. Es nutzt eine eigene deklarative Sprache (HCL, HashiCorp Configuration Language) und ist über *Provider* erweiterbar, die jeweils eine Plattform ansprechen: AWS, Azure, Google Cloud, aber auch GitHub, Kubernetes oder DNS-Anbieter. Das macht es attraktiv, wenn mehrere Plattformen mit einem einheitlichen Werkzeug verwaltet werden sollen. Wegen einer Lizenzänderung im Jahr 2023 gibt es außerdem den Fork *OpenTofu*, der weitgehend kompatibel arbeitet; für die Prinzipien dieses Abschnitts macht das keinen Unterschied.

Der Arbeitsablauf folgt vier Schritten. `terraform init` lädt die benötigten Provider. `terraform plan` vergleicht die Beschreibung mit dem tatsächlichen Zustand und zeigt, was hinzukommen, sich ändern oder verschwinden würde, vergleichbar mit dem Change Set. `terraform apply` führt die Änderungen aus. `terraform destroy` entfernt alles. Entscheidend ist der *State* (Zustandsdatei): Terraform speichert darin, welche realen Ressourcen zu welchen Beschreibungen gehören, und berechnet daraus die Unterschiede. Der State enthält mitunter sensible Werte und ist wichtig für die Zusammenarbeit. Deshalb legt man ihn in einen gemeinsamen, gesicherten *Remote Backend*, typischerweise einen verschlüsselten, versionierten S3-Bucket, mit einer Sperre gegen gleichzeitige Änderungen (klassisch über eine DynamoDB-Tabelle, neuere Versionen unterstützen eine Sperre direkt in S3). Das ist ein Unterschied zu CloudFormation: Dort verwaltet AWS den Zustand, bei Terraform ist der Anwender dafür verantwortlich.

Zur Abgrenzung: CloudFormation ist ein AWS-Dienst, tief integriert, neue AWS-Funktionen sind oft früh verfügbar, es ist ohne zusätzliche Installation nutzbar, und der Zustand wird von AWS gehalten. Terraform ist plattformübergreifend, hat eine große Gemeinschaft und wiederverwendbare Module, verlangt aber die Verwaltung des States. Welches besser ist, hängt vom Umfeld ab; für die Prüfung genügt es, beide als IaC-Werkzeuge einzuordnen und die Unterschiede zu kennen. Beide ersetzen nicht das Wissen über die Dienste, sie automatisieren nur deren Bereitstellung.

Das folgende Beispiel beschreibt in HCL eine VPC mit einem Subnetz und führt den Ablauf aus.

```bash
mkdir tf-demo && cd tf-demo
cat > main.tf <<'EOT'
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "eu-central-1"
}

variable "umgebung" {
  type    = string
  default = "dev"
}

resource "aws_vpc" "haupt" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "tf-${var.umgebung}", Umgebung = var.umgebung }
}

resource "aws_subnet" "privat" {
  vpc_id            = aws_vpc.haupt.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "eu-central-1a"
  tags              = { Name = "privat-${var.umgebung}" }
}

output "vpc_id" {
  value = aws_vpc.haupt.id
}
EOT
terraform init
terraform plan -out=plan.bin
terraform apply plan.bin
terraform destroy
```

Der Block `terraform` legt den benötigten Provider und eine Versionsspanne fest, `provider` wählt die Region. Die Variable `umgebung` macht die Vorlage wiederverwendbar. Die zwei Ressourcen verweisen aufeinander (`aws\_vpc.haupt.id`), woraus Terraform die Reihenfolge ableitet. `plan -out` speichert den geprüften Plan, `apply plan.bin` führt genau diesen Plan aus, und `destroy` räumt auf. Die Provider-Version kann abweichen; aktuelle Angaben stehen in der Dokumentation.

### Typische Fehler.

Falsch: Den State lokal oder gar im Repository abzulegen, besonders wenn mehrere Personen arbeiten. Falsch: `apply` ohne `plan` auszuführen. Falsch: Ressourcen außerhalb von Terraform zu ändern (Drift). Falsch: Geheimnisse im Klartext in Dateien und im State zu belassen, ohne dessen Zugriff zu schützen. Falsch: Terraform und CloudFormation dieselben Ressourcen verwalten zu lassen.

### Praxisbezug.

Ein Unternehmen mit AWS und einem zweiten Anbieter nutzt Terraform für beides; ein reiner AWS-Betrieb setzt oft auf CloudFormation oder das AWS CDK, das aus Programmiersprachen CloudFormation-Templates erzeugt.

## 10.5 Systems Manager

*AWS Systems Manager* (SSM) ist eine Sammlung von Werkzeugen zur Verwaltung von Servern und Anwendungen, in AWS und lokal. Zentral ist der *SSM Agent*, ein kleines Programm, das auf vielen Amazon-Linux- und Windows-AMIs bereits installiert ist. Er verbindet sich ausgehend (per HTTPS) mit Systems Manager und führt Aufträge aus. Voraussetzung ist eine Instanzrolle mit der Richtlinie `AmazonSSMManagedInstanceCore` und ein Netzwerkweg zum Dienst (über Internet, NAT oder VPC-Endpunkte; Modul 06). Instanzen, die diese Bedingungen erfüllen, heißen *Managed Instances*.

Die wichtigsten Funktionen: Der *Session Manager* öffnet eine Shell auf einer Instanz über die Console oder CLI, ohne SSH-Schlüssel, ohne offenen Port 22 und ohne Bastion-Host; der Zugriff wird über IAM gesteuert, und Sitzungen lassen sich protokollieren. Das ist sicherer als klassisches SSH oder RDP. *Run Command* führt Befehle oder Skripte auf vielen Instanzen gleichzeitig aus, ausgewählt per Tags. *Patch Manager* installiert Betriebssystem-Updates nach Zeitplan und Regeln und bewertet die Patchkonformität. *State Manager* stellt sicher, dass Instanzen dauerhaft eine gewünschte Konfiguration haben. Der *Parameter Store* speichert Konfigurationswerte und verschlüsselte Geheimnisse (Modul 08). *Automation* führt vordefinierte oder eigene Runbooks aus, *Inventory* sammelt Informationen über installierte Software, und *Maintenance Windows* legen Wartungsfenster fest. Viele dieser Funktionen sind ohne zusätzliche Gebühren nutzbar, einzelne kosten extra.

Die Stärke zeigt sich im Betrieb ohne Zugangs-Wildwuchs: Statt Schlüssel zu verteilen und Ports zu öffnen, erhält eine Person das Recht `ssm:StartSession` für Instanzen mit bestimmten Tags, und jeder Zugriff ist in CloudTrail und optional im Sitzungsprotokoll nachvollziehbar. Das erfüllt Least Privilege und erleichtert Audits.

Das folgende Beispiel öffnet eine Sitzung, führt einen Befehl auf allen Instanzen mit einem bestimmten Tag aus und fragt Patch-Daten ab.

```bash
aws ssm describe-instance-information \
  --query 'InstanceInformationList[].{Id:InstanceId,Agent:PingStatus,OS:PlatformName}' \
  --output table

aws ssm start-session --target i-0123456789abcdef0

aws ssm send-command --document-name AWS-RunShellScript \
  --targets Key=tag:Umgebung,Values=dev \
  --parameters 'commands=["df -h /","uptime"]' \
  --comment "Festplatte und Last pruefen"

aws ssm describe-instance-patch-states \
  --instance-ids i-0123456789abcdef0 \
  --query 'InstancePatchStates[].{Fehlt:MissingCount,Fehler:FailedCount}'
```

Die erste Abfrage zeigt, welche Instanzen vom Systems Manager verwaltet werden und ob der Agent erreichbar ist (`Online`); fehlt eine Instanz, liegt es meist an Rolle oder Netzwerk. `start-session` öffnet die Shell (das Session-Manager-Plugin der CLI muss installiert sein). `send-command` führt zwei Befehle auf allen Instanzen mit dem Tag `Umgebung=dev` aus; die Ergebnisse holt man mit `list-command-invocations` oder in der Console. Die letzte Abfrage nennt fehlende und fehlgeschlagene Patches. Die Instanz-ID ist ein Platzhalter.

### Typische Fehler.

Falsch: Instanzen ohne passende Rolle zu starten und sich zu wundern, dass sie nicht verwaltet werden. Falsch: SSH weiterhin offen zu lassen, obwohl Session Manager möglich ist. Falsch: Patchen von Hand und ohne Nachweis. Falsch: Befehle per Run Command ohne Tags-Einschränkung auf alle Instanzen zu senden.

### Praxisbezug.

Ein Betrieb schließt Port 22 in allen Security Groups. Wartungszugriffe laufen über Session Manager, Patches über einen wöchentlichen Plan, und ein Auditor sieht in den Protokollen, wer wann auf welcher Instanz war.

## 10.6 Deployment Services

*CI/CD* fasst Praktiken zusammen, mit denen Software automatisiert gebaut, getestet und ausgeliefert wird. *Continuous Integration* bedeutet, Änderungen häufig in ein gemeinsames Repository einzuspielen und bei jeder Änderung automatisch zu bauen und zu testen. *Continuous Delivery* bedeutet, dass jede erfolgreiche Änderung jederzeit auslieferbar ist, meist mit einer manuellen Freigabe vor der Produktion. *Continuous Deployment* liefert ohne manuellen Schritt aus. Das Ergebnis ist eine *kontrollierte Lieferkette*: schnell, wiederholbar und nachvollziehbar, statt von Hand mit Kopieren und Hoffen.

AWS bietet dafür die Entwicklerdienste, die jeweils eine Stufe abdecken. *AWS CodeCommit* ist ein verwaltetes Git-Repository. *AWS CodeBuild* baut und testet Code in kurzlebigen Containern, gesteuert durch eine Datei `buildspec.yml`, und bezahlt wird nach Build-Minuten. *AWS CodeDeploy* liefert Anwendungen auf EC2, Lambda oder Container aus, mit Strategien wie *rollende* Updates (Server nacheinander), *Blue/Green* (neue Umgebung parallel aufbauen, Verkehr umschalten, bei Problemen zurückschalten) und *Canary* (erst ein kleiner Teil des Verkehrs). *AWS CodePipeline* verbindet die Stufen zu einem Ablauf mit Quelle, Build, Test, Freigabe und Bereitstellung. Hinzu kommt *AWS CodeArtifact* als Paket-Repository. Als gleichwertige Alternativen werden oft GitHub, GitLab oder Jenkins eingesetzt, die sich in AWS integrieren lassen.

> **Ergänzung aus der Nachrecherche**
>
> CodeCommit war ab Juli 2024 für neue Kunden nicht mehr verfügbar (AWS kündigte an, den Dienst zurückzustellen). Laut dem AWS-DevOps-Blog kehrte CodeCommit am 24. November 2025 in die allgemeine Verfügbarkeit zurück, Neuanmeldungen sind wieder möglich, und Preise und SLA blieben unverändert. Ob der Dienst eingesetzt wird, ist eine Frage der Strategie; viele Teams nutzen GitHub oder GitLab. Aktuelle Aussagen stehen in der AWS-Dokumentation.

Das folgende Beispiel zeigt eine `buildspec.yml` für CodeBuild und eine `appspec.yml` für CodeDeploy auf EC2. Beide gehören ins Repository.

```bash
cat > buildspec.yml <<'EOT'
version: 0.2
phases:
  install:
    runtime-versions:
      python: 3.12
  pre_build:
    commands:
      - pip install -r requirements.txt
  build:
    commands:
      - python -m pytest tests/
      - zip -r app.zip app/ appspec.yml scripts/
artifacts:
  files:
    - app.zip
EOT

cat > appspec.yml <<'EOT'
version: 0.0
os: linux
files:
  - source: app/
    destination: /opt/shop
hooks:
  ApplicationStop:
    - location: scripts/stop.sh
      timeout: 60
  AfterInstall:
    - location: scripts/install_deps.sh
  ApplicationStart:
    - location: scripts/start.sh
  ValidateService:
    - location: scripts/health.sh
      timeout: 60
EOT

aws codepipeline list-pipelines --query 'pipelines[].name'
aws codepipeline start-pipeline-execution --name shop-pipeline
aws codepipeline get-pipeline-state --name shop-pipeline \
  --query 'stageStates[].{Stufe:stageName,Status:latestExecution.status}'
```

Die `buildspec.yml` beschreibt Phasen: Laufzeit wählen, Abhängigkeiten installieren, Tests ausführen (schlägt ein Test fehl, bricht der Build ab) und das Paket erzeugen. Die `appspec.yml` sagt CodeDeploy, wohin die Dateien kommen und welche Skripte in welchen Phasen laufen; `ValidateService` prüft, ob die neue Version gesund ist, sonst wird zurückgerollt. Die Befehle darunter listen Pipelines, starten sie und zeigen den Status je Stufe. Die Pipeline `shop-pipeline` und alle Skripte sind Beispiele.

### Typische Fehler.

Falsch: Ohne automatische Tests auszuliefern. Falsch: Zugangsdaten im Repository oder in der Build-Konfiguration. Falsch: Eine Pipeline mit Administratorrechten auszustatten; die Rolle sollte nur das Nötigste dürfen. Falsch: Keine Rückfallstrategie zu haben. Falsch: Jede Änderung von Hand an der Produktion zu machen, am Prozess vorbei.

### Praxisbezug.

Ein Team liefert mehrmals täglich aus. Jede Änderung durchläuft Build, Tests und eine Canary-Auslieferung; zeigt der Alarm erhöhte Fehlerraten, wird automatisch zurückgerollt.

## 10.7 Automation Governance

Automatisierung vervielfacht die Wirkung von Entscheidungen: Ein guter Prozess wird schnell überall angewendet, ein fehlerhafter ebenso schnell. Deshalb braucht Automatisierung *Governance*, also Regeln und Kontrollen, die sicherstellen, dass nur Richtiges automatisiert und Wichtiges nicht umgangen wird. Das knüpft an die Leitplanken aus Modul 08 an.

Vier Themen stehen im Mittelpunkt. Erstens *Standards und Namensregeln*: einheitliche Namen für Ressourcen und verbindliche *Tags* (Owner, Kostenstelle, Umgebung). Sie ermöglichen Kostenzuordnung (Modul 11), Verantwortlichkeit und gezielte Automatisierung. Man erzwingt sie technisch, etwa mit Tag Policies, mit SCPs oder IAM-Richtlinien, die das Anlegen ohne Pflicht-Tag verbieten, und mit AWS-Config-Regeln, die fehlende Tags melden. Zweitens *Freigabeprozesse*: Änderungen an Produktion durchlaufen eine Pipeline mit manueller Freigabe, Vier-Augen-Prinzip und Nachvollziehbarkeit statt direkter Handänderung. Drittens *Drift und manuelle Änderungen*: Wer Ressourcen am Code vorbei ändert, macht den Code unwahr; die nächste Bereitstellung überschreibt die Änderung oder scheitert, und niemand weiß, was wirklich läuft. Gegenmittel sind Drift-Erkennung (CloudFormation, AWS Config), eingeschränkte Konsolenrechte in Produktion und der Grundsatz, dass Änderungen nur über die Pipeline erfolgen. Viertens *Berechtigungen der Automatisierung*: Pipelines und Skripte laufen mit Rollen nach Least Privilege, und es gibt klare Zuständigkeiten. Vorgefertigte, geprüfte Bausteine bietet *AWS Service Catalog*: Teams bestellen genehmigte Produkte (Vorlagen) in Selbstbedienung, ohne die Regeln zu umgehen.

Das folgende Beispiel zeigt zwei Kontrollen: eine SCP, die das Starten von Instanzen ohne Tag `Owner` verhindert, und die Drift-Erkennung eines Stacks.

```bash
cat > scp-tags.json <<'EOT'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "InstanzNurMitOwnerTag",
    "Effect": "Deny",
    "Action": "ec2:RunInstances",
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {"Null": {"aws:RequestTag/Owner": "true"}}
  }]
}
EOT
aws organizations create-policy --name owner-tag-pflicht \
  --type SERVICE_CONTROL_POLICY --description "Owner-Tag Pflicht" \
  --content file://scp-tags.json

ID=$(aws cloudformation detect-stack-drift --stack-name daten-bucket \
  --query StackDriftDetectionId --output text)
aws cloudformation describe-stack-drift-detection-status \
  --stack-drift-detection-id $ID
aws cloudformation describe-stack-resource-drifts --stack-name daten-bucket \
  --stack-resource-drift-status-filters MODIFIED DELETED
```

Die SCP verbietet `RunInstances`, wenn die Anfrage das Tag `Owner` nicht enthält (`Null` gleich `true` bedeutet: Schlüssel fehlt). Wer Instanzen startet, muss das Tag also mitgeben, sonst scheitert der Aufruf; dadurch ist jede Instanz einem Verantwortlichen zugeordnet. Hinweis: Auch Auto Scaling und Pipelines müssen das Tag setzen, sonst werden sie blockiert, daher vorher in einer Test-OU prüfen. Die Drift-Erkennung startet eine Prüfung des Stacks, zeigt ihren Status und listet geänderte oder gelöschte Ressourcen mit den Unterschieden.

### Typische Fehler.

Falsch: Governance nur als Dokument zu schreiben und nicht technisch durchzusetzen. Falsch: Pflicht-Tags so streng zu erzwingen, dass legitime Automatisierung blockiert wird, ohne Ausnahmeprozess. Falsch: Entwickler dauerhaft mit Administratorrechten in Produktion arbeiten zu lassen, “nur für Notfälle”. Falsch: Drift zu ignorieren, bis die Aktualisierung scheitert.

### Praxisbezug.

Eine Plattform-Gruppe bietet über den Service Catalog geprüfte Vorlagen für Webanwendungen an. Teams bekommen in Minuten eine konforme Umgebung, und die Sicherheit prüft nicht jede einzeln.

## 10.8 Automation-Troubleshooting

Wenn eine Automatisierung scheitert, ist das Muster meist ähnlich: Es gibt eine Meldung, sie verweist auf eine Ursache, und diese lässt sich in den Protokollen des Werkzeugs finden. Fehler lassen sich typischerweise in drei Gruppen einteilen: Fehler im *Template oder Code* (Syntax, falsche Eigenschaft, Verweis auf Unbekanntes), Fehler bei den *Berechtigungen* (die ausführende Rolle darf eine Aktion nicht, die man im Template nicht sieht) und Fehler in der *Umgebung* (falsche Region, Quote erreicht, Namenskonflikt, Abhängigkeit fehlt, Ressource existiert schon).

Bei CloudFormation ist der erste Anlaufpunkt die Liste der *Stack-Ereignisse*: Sie zeigt in zeitlicher Reihenfolge, welche Ressource in welchem Zustand ist, und bei `CREATE\_FAILED` den *Statusgrund* im Klartext, zum Beispiel “Bucket name already exists” oder “not authorized to perform”. Die erste fehlgeschlagene Ressource ist meist die Ursache; spätere Fehler sind oft Folgefehler. Nach einem Fehler beim Anlegen geht der Stack in den Zustand `ROLLBACK\_COMPLETE`, aus dem man ihn nur löschen und neu anlegen kann. Bei einem fehlgeschlagenen Update stellt CloudFormation den alten Stand wieder her (`UPDATE\_ROLLBACK\_COMPLETE`); bleibt das Zurückrollen selbst hängen (`UPDATE\_ROLLBACK\_FAILED`), hilft `continue-update-rollback`, gegebenenfalls unter Überspringen der problematischen Ressource. Das Löschen scheitert oft an nicht leeren Buckets oder an Abhängigkeiten (`DELETE\_FAILED`). Bei Terraform zeigt `plan` die meisten Probleme vorher, `apply` bricht mit der Fehlermeldung des AWS-Aufrufs ab, und ausführliche Protokolle erhält man mit der Umgebungsvariable `TF\_LOG=DEBUG`.

Berechtigungsfehler untersucht man mit CloudTrail (Modul 03 und 07): Welcher Aufruf wurde mit welcher Rolle abgelehnt? Dabei ist wichtig, *welche Identität* die Aktion ausführt: bei CloudFormation die Rolle des Aufrufers oder eine angegebene Servicerolle, bei Pipelines die Pipeline-Rolle, bei Skripten die Rolle der Umgebung. Bei Regionsfehlern prüft man, ob Template, Profil und Umgebungsvariablen dieselbe Region meinen, und bei Quotenfehlern die Service Quotas (Modul 07).

Das folgende Beispiel zeigt die typische Diagnose eines fehlgeschlagenen Stacks.

```bash
aws cloudformation describe-stacks --stack-name meine-app \
  --query 'Stacks[0].StackStatus'

aws cloudformation describe-stack-events --stack-name meine-app \
  --query 'StackEvents[?contains(ResourceStatus,`FAILED`)].{Zeit:Timestamp,Ressource:LogicalResourceId,Grund:ResourceStatusReason}' \
  --output table

# Stack im Zustand ROLLBACK_COMPLETE: loeschen und neu anlegen
aws cloudformation delete-stack --stack-name meine-app
aws cloudformation wait stack-delete-complete --stack-name meine-app

# Update-Rollback haengt: fortsetzen und Problemressource ueberspringen
aws cloudformation continue-update-rollback --stack-name meine-app \
  --resources-to-skip ProblemRessource

aws cloudformation validate-template --template-body file://vorlage.yaml
```

Die erste Abfrage nennt den Stack-Status. Die zweite listet nur die fehlgeschlagenen Ereignisse mit Zeit, logischem Namen der Ressource und dem Grund; die oberste (zeitlich früheste) Zeile ist meist die eigentliche Ursache. Ein Stack in `ROLLBACK\_COMPLETE` wird gelöscht und danach nach Korrektur neu angelegt. Hängt ein Update-Rollback, setzt `continue-update-rollback` ihn fort; mit `--resources-to-skip` werden problematische Ressourcen übersprungen (nur nach Prüfung der Folgen). `validate-template` entdeckt Syntaxfehler vor dem Rollout. Namen wie `meine-app` und `ProblemRessource` sind Beispiele.

> **Praxisbeispiel**
>
> Ein Stack für eine Webanwendung scheitert mit `CREATE\_FAILED` bei der Datenbank, Grund: “The security group does not belong to the VPC”. Das Template verweist auf eine Security Group aus der Default-VPC statt der neuen VPC. Nach Korrektur des Verweises (`!Ref` auf die richtige Gruppe) und Neuanlage funktioniert alles. Ohne die Stack-Ereignisse hätte man den Fehler an der falschen Stelle gesucht.

### Typische Fehler.

Falsch: Den letzten Fehler im Protokoll für die Ursache zu halten; er ist oft nur Folge. Falsch: Nach einem Fehler dieselbe Vorlage unverändert erneut auszuführen. Falsch: Rollbacks zu überspringen, ohne zu wissen, welche Ressourcen dadurch inkonsistent werden. Falsch: Direkt in der Produktion zu testen; besser ist ein Probelauf in einer Testumgebung mit demselben Template.

### Praxisbezug.

Teams legen eine Prüfliste für Automatisierungsfehler an: Statusgrund lesen, Identität prüfen, Region und Quoten prüfen, erste fehlgeschlagene Ressource suchen, CloudTrail befragen, in der Testumgebung nachstellen.

## Übungsaufgaben Modul 10

1.  In welcher Reihenfolge sucht die CLI nach Zugangsdaten, und warum sollte man auf Servern Rollen statt Schlüsseln nutzen?

2.  Erklären Sie den Unterschied zwischen `--query` und `--filters` und nennen Sie je ein Beispiel.

3.  Was ist Infrastructure as Code, und welche vier Vorteile hat es?

4.  Worin unterscheiden sich CloudFormation und Terraform im Umgang mit dem Zustand?

5.  Warum ist der Session Manager sicherer als SSH?

6.  **Praxis:** Schreiben Sie ein CloudFormation-Template für eine SQS-Warteschlange mit Dead-Letter-Queue (maxReceiveCount 3) und geben Sie die Queue-URL als Output aus.

7.  **Praxis:** Schreiben Sie ein Boto3-Skript, das alle S3-Buckets auflistet und für jeden ausgibt, ob Versionierung aktiv ist.

8.  **Praxis:** Ein Stack steht in `ROLLBACK\_COMPLETE`. Beschreiben Sie Ihre Diagnose und die Schritte bis zum erfolgreichen Rollout.

## Lösungen Modul 10

1.  Befehlsparameter, Umgebungsvariablen, Profile (inklusive Identity Center), zuletzt Rollen der Umgebung (Instanzrolle, Ausführungsrolle). Rollen liefern temporäre Zugangsdaten, die automatisch rotieren; Schlüssel sind langlebig, können in Repositories oder Logs gelangen und müssen verwaltet werden.

2.  `--query` filtert die JSON-Antwort auf der Clientseite nach dem Abruf (JMESPath), zum Beispiel `--query 'Reservations[].Instances[].InstanceId'`. `--filters` wirkt serverseitig und reduziert, was AWS überhaupt zurückliefert, zum Beispiel `--filters Name=instance-state-name,Values=running`.

3.  Infrastruktur wird in versionierten Dateien beschrieben und automatisch ausgeführt. Vorteile: Wiederholbarkeit, Nachvollziehbarkeit (Versionsverwaltung), Geschwindigkeit, Möglichkeit zum vollständigen Auf- und Abbau ohne Handarbeit; auch Tests und Reviews werden möglich.

4.  CloudFormation: AWS verwaltet den Zustand im Stack, kein zusätzlicher Speicher nötig. Terraform: Der Anwender verwaltet die State-Datei, sollte sie in einem gesicherten Remote Backend (zum Beispiel S3) mit Sperre ablegen und vor unbefugtem Zugriff schützen.

5.  Kein offener Port 22/3389, keine Verteilung von SSH-Schlüsseln, Zugriff über IAM-Richtlinien steuerbar, jede Sitzung in CloudTrail und optional im Sitzungsprotokoll nachvollziehbar, MFA über die Anmeldung möglich.

6.  ```bash
    AWSTemplateFormatVersion: '2010-09-09'
    Resources:
      AuftraegeDLQ:
        Type: AWS::SQS::Queue
      Auftraege:
        Type: AWS::SQS::Queue
        Properties:
          RedrivePolicy:
            deadLetterTargetArn: !GetAtt AuftraegeDLQ.Arn
            maxReceiveCount: 3
    Outputs:
      QueueUrl:
        Value: !Ref Auftraege
    ```

    `!Ref` auf eine SQS-Queue liefert deren URL; `!GetAtt` liefert den ARN der Dead-Letter-Queue.

7.  ```python
    import boto3
    from botocore.exceptions import ClientError
    s3 = boto3.client("s3")
    for b in s3.list_buckets()["Buckets"]:
        name = b["Name"]
        try:
            status = s3.get_bucket_versioning(Bucket=name).get("Status", "Nie aktiviert")
        except ClientError as e:
            status = "Fehler: " + e.response["Error"]["Code"]
        print(name, "->", status)
    ```

    Bei Buckets in anderen Regionen kann ein regionsspezifischer Client nötig sein.

8.  Diagnose: Stack-Ereignisse nach `FAILED` filtern; die zeitlich erste fehlgeschlagene Ressource und ihren Statusgrund lesen; Ursache beheben (Syntax, Berechtigung der ausführenden Rolle, Region, Quote, Namenskonflikt). Dann: `delete-stack` und `wait stack-delete-complete`, Template mit `validate-template` prüfen, erneut `deploy`, bei Bedarf zuerst mit Change Set und in einer Testumgebung. Der Stack in `ROLLBACK\_COMPLETE` lässt sich nicht aktualisieren, nur löschen.
