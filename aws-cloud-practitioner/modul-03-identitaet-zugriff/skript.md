# Modul 3 - Identitaet, Zugriff und Account-Struktur

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „AWS Cloud Practitioner (CLF-C02): Lernskript in Modulen“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben und Lösungen als nummerierte Listen). Die Listings (AWS-CLI-Befehle, Richtlinien, Vorlagen, Python) wurden hier **nicht gegen ein AWS-Konto ausgeführt**. Preise, Limits und Servicenamen ändern sich bei AWS laufend; maßgeblich ist die offizielle Dokumentation. Übersicht zum Modul: [README](README.md).

**Dauer:** 9 h

**Priorität:** 1 (höchste)

| Nr. | Lerneinheit                  | Dauer (h) |
|----:|:-----------------------------|----------:|
| 3.1 | Root User und Account-Schutz |         1 |
| 3.2 | IAM Users, Groups und Roles  |         1 |
| 3.3 | Policies und Berechtigungen  |      1,25 |
| 3.4 | Least Privilege              |      1,25 |
| 3.5 | MFA und Passwortregeln       |         1 |
| 3.6 | AWS Organizations            |         1 |
| 3.7 | IAM Identity Center          |         1 |
| 3.8 | Zugriffs-Troubleshooting     |       1,5 |
|     | **Summe**                    |     **9** |

Identität und Zugriff sind die Grundlage jeder Sicherheitsarchitektur in AWS. Dieses Modul erklärt, wer sich bei AWS anmelden kann (Identitäten), was diese Identitäten tun dürfen (Berechtigungen) und wie man viele Konten übersichtlich organisiert. Es setzt das Shared Responsibility Model aus Modul 01 voraus: Die Verwaltung von Identitäten und Zugriffen ist ausdrücklich Aufgabe des Kunden. Der Sicherheitsbereich der Prüfung enthält viele Fragen dazu, und in der Praxis entstehen die meisten Sicherheitsvorfälle durch zu großzügige oder kompromittierte Zugriffsrechte.

## 3.1 Root User und Account-Schutz

Beim Anlegen eines AWS-Kontos entsteht automatisch ein *Root User* (Stammbenutzer), der sich mit der E-Mail-Adresse und dem Passwort des Kontos anmeldet. Er besitzt uneingeschränkten Zugriff auf alle Ressourcen und Einstellungen des Kontos; seine Rechte lassen sich über normale IAM-Richtlinien nicht begrenzen. Genau darin liegt das Risiko: Wer die Root-Zugangsdaten erbeutet, übernimmt das gesamte Konto, kann Daten löschen, teure Ressourcen starten und weitere Zugänge anlegen.

Die zentrale Regel lautet daher, den Root User ausschließlich für wenige Aufgaben zu nutzen, die nur er ausführen kann, und ihn sonst nie zu verwenden. Zu diesen Aufgaben zählen laut AWS-Dokumentation unter anderem die Änderung der Root-Einstellungen eines einzelnen Kontos (E-Mail, Passwort, Zugriffsschlüssel), das Schließen eines eigenständigen Kontos, die Wiederherstellung von IAM-Berechtigungen, wenn der einzige Administrator sich selbst ausgesperrt hat, die Aktivierung des IAM-Zugriffs auf die Abrechnungsseiten, die Konfiguration von MFA Delete bei S3 und das Ändern oder Löschen einer Bucket-Policy, die alle Zugriffe verbietet. Alles andere erledigt man mit einem IAM-Benutzer oder einer Rolle.

Die Schutzmaßnahmen folgen daraus. Erstens wird für den Root User eine Multi-Faktor-Authentifizierung (MFA) eingerichtet, idealerweise mit einem phishing-resistenten Verfahren wie einem Sicherheitsschlüssel oder Passkey. Zweitens verwendet man ein langes, einzigartiges Passwort, das im Passwortmanager liegt. Drittens legt man *keine* Zugriffsschlüssel für den Root User an; existierende Schlüssel werden gelöscht. Viertens ist die E-Mail-Adresse des Root Users ein geschütztes Postfach (am besten ein Gruppenpostfach statt einer persönlichen Adresse), denn über sie lässt sich das Passwort zurücksetzen. Fünftens hinterlegt man aktuelle Kontaktdaten und alternative Kontakte für Abrechnung, Betrieb und Sicherheit, damit AWS im Ernstfall die richtige Person erreicht. Sechstens richtet man eine Alarmierung ein, die bei jeder Root-Anmeldung eine Nachricht erzeugt.

Die letzte Maßnahme lässt sich mit EventBridge und CloudTrail umsetzen: Eine Regel reagiert auf das Anmeldeereignis des Root Users und löst eine Benachrichtigung aus. Das folgende Beispiel zeigt ein Ereignismuster, das auf Root-Anmeldungen an der Console passt, und die Prüfung, ob für den Root User Zugriffsschlüssel oder MFA vorhanden sind.

```bash
aws iam get-account-summary \
  --query 'SummaryMap.{RootMFA:AccountMFAEnabled,RootKeys:AccountAccessKeysPresent}'

aws events put-rule --name root-anmeldung --event-pattern '{
  "detail-type": ["AWS Console Sign In via CloudTrail"],
  "detail": {"userIdentity": {"type": ["Root"]}}
}'
```

Die erste Abfrage zeigt, ob für das Konto MFA beim Root User aktiv ist (`AccountMFAEnabled` gleich 1) und ob Root-Zugriffsschlüssel existieren (`AccountAccessKeysPresent` sollte 0 sein). Die zweite Anweisung erstellt eine EventBridge-Regel, die auf CloudTrail-Anmeldeereignisse reagiert, bei denen der Benutzertyp `Root` ist; mit `put-targets` würde man anschließend ein SNS-Thema als Empfänger festlegen. Anmeldeereignisse der Console werden in der Region `us-east-1` erfasst, die Regel muss gegebenenfalls dort angelegt werden.

> **Ergänzung aus der Nachrecherche**
>
> Laut der offiziellen IAM-Dokumentation können Organisationen Root-Zugriff für Mitgliedskonten *zentral verwalten*: Das Verwaltungskonto kann Root-Passwort, Zugriffsschlüssel und MFA von Mitgliedskonten entfernen und bestimmte privilegierte Aufgaben, etwa das Entfernen einer fehlerhaften Bucket-Policy, ohne Root-Anmeldung durchführen. Neue Mitgliedskonten haben dann standardmäßig keine Root-Zugangsdaten. Diese Funktion verringert die Angriffsfläche in Mehrkonten-Umgebungen.

### Typische Fehler.

Falsch: Das Konto mit dem Root User im Alltag betreiben, weil es “bequemer” ist, oder Root-Zugriffsschlüssel in Skripten zu verwenden. Richtig: Einen IAM-Administrator oder eine Rolle für die tägliche Arbeit nutzen, Root-Schlüssel löschen. Falsch: Die Root-Mailadresse an eine einzelne Person binden; verlässt sie das Unternehmen, ist der Kontozugang gefährdet.

### Praxisbezug.

Beim Aufsetzen eines neuen Kontos steht als erstes eine Checkliste: MFA für Root, Kontakte pflegen, Billing-Zugriff für IAM freischalten, Alarm für Root-Anmeldungen, dann Administratoren über das IAM Identity Center einrichten.

> **Merke**
>
> Root User = uneingeschränkt und nicht begrenzbar. Nur für wenige Sonderaufgaben nutzen, MFA aktivieren, keine Zugriffsschlüssel anlegen, Root-Anmeldungen alarmieren.

## 3.2 IAM Users, Groups und Roles

AWS Identity and Access Management (IAM) ist der Dienst, der Identitäten und Berechtigungen verwaltet. Er ist global, also nicht an eine Region gebunden, und kostenlos. IAM kennt vier Grundobjekte: Benutzer, Gruppen, Rollen und Richtlinien. Die ersten drei sind Identitätstypen, Richtlinien (Policies) legen Rechte fest und sind Thema der nächsten Einheit.

Ein *IAM-Benutzer* (User) steht für eine Person oder Anwendung mit dauerhaften Zugangsdaten: einem Passwort für die Console und optional langlebigen Zugriffsschlüsseln für CLI und SDK. Eine *IAM-Gruppe* bündelt Benutzer; Berechtigungen werden an die Gruppe gehängt und gelten für alle Mitglieder. Eine Gruppe ist keine Identität, mit der man sich anmeldet, und Gruppen lassen sich nicht verschachteln. Eine *IAM-Rolle* (Role) schließlich ist eine Identität ohne eigene dauerhafte Zugangsdaten. Wer die Rolle *annimmt* (*assume*), erhält vom Security Token Service (STS) temporäre Zugangsdaten, die nach Ablauf (Minuten bis Stunden) ungültig werden.

Wozu braucht man Rollen? Es gibt mehrere typische Szenarien. Ein AWS-Dienst, zum Beispiel eine EC2-Instanz oder eine Lambda-Funktion, benötigt Rechte, um auf andere Dienste zuzugreifen; statt Schlüssel im Programm zu hinterlegen, bekommt der Dienst eine Rolle (bei EC2 über ein *Instance Profile*). Ein Benutzer aus einem anderen Konto oder ein Mitarbeiter, der sich über das Firmenverzeichnis anmeldet (*Federation*), nimmt eine Rolle an, um in AWS zu arbeiten. Ein Administrator kann für besonders heikle Aufgaben bewusst in eine Rolle mit höheren Rechten wechseln. In allen Fällen gilt das Prinzip: temporäre Zugangsdaten sind sicherer als langlebige, weil ein gestohlener Schlüssel nur kurz nutzbar ist. Die AWS-Empfehlung lautet entsprechend, Menschen über Federation und Identity Center mit temporären Zugangsdaten arbeiten zu lassen und für Workloads Rollen zu verwenden.

Eine Rolle besteht aus zwei Teilen: der *Vertrauensrichtlinie* (Trust Policy), die festlegt, *wer* die Rolle annehmen darf, und den *Berechtigungsrichtlinien*, die festlegen, *was* die Rolle darf. Das folgende Beispiel legt eine Rolle für EC2-Instanzen an, gibt ihr lesenden Zugriff auf S3 und prüft die Identität.

```bash
aws iam create-group --group-name entwickler
aws iam create-user --user-name anna
aws iam add-user-to-group --user-name anna --group-name entwickler

cat > trust.json <<'EOT'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole" }] }
EOT
aws iam create-role --role-name app-rolle \
  --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name app-rolle \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
```

Die ersten drei Zeilen legen Gruppe und Benutzer an und ordnen den Benutzer zu. Die Datei `trust.json` ist die Vertrauensrichtlinie: Das `Principal`-Feld nennt den Dienst `ec2.amazonaws.com`, der die Rolle annehmen darf, und `sts:AssumeRole` ist die dafür nötige Aktion. `create-role` erzeugt die Rolle aus dieser Datei, `attach-role-policy` hängt die von AWS verwaltete Richtlinie `AmazonS3ReadOnlyAccess` an. Auf einer EC2-Instanz mit dieser Rolle genügt `aws s3 ls`, ohne dass irgendwo ein Schlüssel gespeichert ist.

### Typische Fehler.

Falsch: Zugriffsschlüssel eines IAM-Benutzers in Quellcode oder auf Server zu kopieren; sie landen schnell in Versionsverwaltung oder Logs. Richtig: Rolle am Dienst. Falsch: Rechte direkt an einzelne Benutzer hängen; bei vielen Personen wird es unübersichtlich. Richtig: Gruppen oder Rollen nutzen. Falsch ist auch die Annahme, eine Gruppe könne sich anmelden oder Mitglied einer anderen Gruppe sein.

### Praxisbezug.

Eine Anwendung auf EC2 liest Dateien aus S3. Das Team vergibt eine Instance-Profile-Rolle mit nur diesem Recht; es gibt keine Schlüssel, die rotiert oder geschützt werden müssen.

## 3.3 Policies und Berechtigungen

Eine *Policy* (Richtlinie) ist ein JSON-Dokument, das festlegt, welche Aktionen auf welchen Ressourcen erlaubt oder verboten sind. Ohne Policy darf eine Identität nichts: AWS verweigert standardmäßig jeden Zugriff (*impliziter Deny*), erst eine `Allow`-Anweisung erteilt Rechte, und ein ausdrückliches `Deny` überstimmt jede Erlaubnis.

Eine Policy besteht aus einer `Version` (immer `2012-10-17`) und einer Liste von `Statement`-Blöcken. Jeder Block kennt die Elemente `Effect` (`Allow` oder `Deny`), `Action` (welche API-Aufrufe, zum Beispiel `s3:GetObject`, mit Platzhaltern wie `s3:*`), `Resource` (auf welche Ressourcen, angegeben als ARN, den eindeutigen Amazon Resource Name) und optional `Condition` (unter welchen Umständen, etwa nur von einer bestimmten IP-Adresse oder nur mit MFA). Bei ressourcenbasierten Richtlinien kommt das Element `Principal` hinzu, das angibt, *wer* Zugriff erhält.

Man unterscheidet mehrere Policy-Typen. *Identity-based Policies* hängen an Benutzern, Gruppen oder Rollen und sagen, was diese Identität darf. *Resource-based Policies* hängen an einer Ressource (zum Beispiel einem S3-Bucket) und sagen, wer auf diese Ressource zugreifen darf, auch aus anderen Konten. Dazu kommen *Permissions Boundaries* (setzen für eine Identität eine Obergrenze), *Service Control Policies* (Obergrenze für ganze Konten, siehe die Einheit zu AWS Organizations) und *Session Policies* (Einschränkung für eine einzelne Sitzung). Zu den identitätsbasierten Policies gehören *AWS-verwaltete* Policies (von AWS gepflegt, zum Beispiel `ReadOnlyAccess`), *vom Kunden verwaltete* Policies (eigene, wiederverwendbare) und *Inline-Policies* (fest an eine Identität gebunden).

Die Auswertungslogik ist prüfungsrelevant. Für eine Anfrage gilt: Erstens ist alles verboten, was nicht erlaubt ist. Zweitens gewinnt ein ausdrückliches Deny immer. Drittens muss, wenn Obergrenzen wie eine SCP oder Permissions Boundary im Spiel sind, die Aktion zusätzlich dort erlaubt sein; die Obergrenze verleiht selbst keine Rechte. Viertens genügt innerhalb eines Kontos eine Erlaubnis in einer Resource-based Policy für einen Principal, während bei kontoübergreifendem Zugriff beide Seiten zustimmen müssen.

Das folgende Beispiel ist eine typische identitätsbasierte Policy, die lesenden Zugriff auf einen bestimmten Bucket gewährt und nur über verschlüsselte Verbindungen gilt.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListeBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::mein-lernbucket-2026-12345"
    },
    {
      "Sid": "LeseObjekte",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::mein-lernbucket-2026-12345/*",
      "Condition": {"Bool": {"aws:SecureTransport": "true"}}
    }
  ]
}
```

Der erste Block erlaubt das Auflisten des Buckets selbst; dafür verweist der ARN auf den Bucket ohne Schrägstrich. Der zweite Block erlaubt das Lesen der Objekte; der ARN endet auf `/*`, denn Objekte sind Unterelemente des Buckets. Die `Condition` verlangt, dass die Anfrage über HTTPS erfolgt. Dass Bucket und Objekte unterschiedliche ARNs haben, ist eine der häufigsten Stolperfallen.

### Typische Fehler.

Falsch: `"Action": "*"` mit `"Resource": "*"` als schnelle Lösung. Das ist Administratorzugriff und verletzt Least Privilege. Falsch: Nur `s3:GetObject` auf den Bucket-ARN ohne `/*`; die Anweisung greift dann ins Leere. Richtig: ARN der Objekte mit `/*`. Ein weiterer Fehler: Einem Verbot (`Deny`) mit einer zusätzlichen Erlaubnis begegnen zu wollen; ein ausdrückliches Deny wird nie von einem Allow aufgehoben.

### Praxisbezug.

Beim Lesen fremder Policies prüft man in dieser Reihenfolge: Effect, Action, Resource, Condition. Wer das Muster sicher lesen kann, versteht die meisten Berechtigungsfragen.

## 3.4 Least Privilege

Das Prinzip der geringsten Rechte (*Least Privilege*) besagt, dass jede Identität nur die Berechtigungen erhält, die sie für ihre Aufgabe benötigt, und nicht mehr. Der Gedanke dahinter: Jede unnötige Berechtigung vergrößert den Schaden, wenn Zugangsdaten gestohlen werden oder ein Fehler passiert. Ein Benutzer, der nur einen Bucket lesen darf, kann bei einem Missbrauch nur diesen Bucket lesen.

In der Praxis ist Least Privilege ein Prozess und kein Zustand. Man beginnt häufig mit einer von AWS verwalteten Policy, weil sie schnell Ergebnisse liefert, und verengt die Rechte schrittweise: Aktionen auf die tatsächlich benötigten reduzieren, Ressourcen auf bestimmte ARNs begrenzen, Bedingungen ergänzen. AWS empfiehlt dafür den *IAM Access Analyzer*: Er kann aus den tatsächlichen Zugriffen im CloudTrail-Protokoll eine passende, schlankere Policy generieren. Außerdem zeigt IAM an, wann ein Dienst oder eine Aktion zuletzt genutzt wurde (*Last Accessed Information*), sodass ungenutzte Rechte, Rollen und Benutzer entfernt werden können. Der Access Analyzer prüft außerdem, ob Ressourcen öffentlich oder kontoübergreifend zugänglich sind, und validiert Richtlinien mit über hundert Prüfungen.

Zusätzliche Hilfsmittel sind Bedingungen in Policies (nur aus bestimmten Netzwerken, nur mit MFA, nur in bestimmten Regionen), Permissions Boundaries und, auf Organisationsebene, SCPs. Auch die Trennung von Aufgaben gehört dazu: Wer Entwicklungsumgebungen betreibt, braucht keine Rechte an der Abrechnung, und wer Auswertungen liest, braucht keine Schreibrechte.

Das nächste Beispiel zeigt, wie man ungenutzte Rechte aufspürt: Es erzeugt einen Bericht über zuletzt genutzte Dienste für einen Benutzer und eine Rolle.

```bash
JOB=$(aws iam generate-service-last-accessed-details \
  --arn arn:aws:iam::123456789012:user/anna \
  --query JobId --output text)
aws iam get-service-last-accessed-details --job-id "$JOB" \
  --query 'ServicesLastAccessed[?TotalAuthenticatedEntities>`0`].{Dienst:ServiceNamespace,Zuletzt:LastAuthenticated}' \
  --output table
```

Die erste Anweisung startet einen Auswertungsauftrag für den Benutzer `anna` (die Kontonummer ist ein Platzhalter) und speichert dessen Nummer in der Variable `JOB`. Die zweite fragt das Ergebnis ab und filtert mit JMESPath auf Dienste, die tatsächlich genutzt wurden. Dienste, die gar nicht erscheinen, gehören vermutlich nicht in die Policy und können entfernt werden. Die Auswertung kann einige Sekunden dauern; bei leerer Ausgabe wiederholt man sie.

### Typische Fehler.

Falsch: “Wir vergeben erst Administratorrechte und schränken später ein”; das Später kommt selten. Richtig: Mit minimalen Rechten starten und bei Bedarf ergänzen. Falsch: Nur auf AWS-verwaltete Policies zu setzen, deren Reichweite oft größer ist als nötig. Falsch: Rechte für Personen zu sammeln, die die Abteilung gewechselt haben.

### Praxisbezug.

In regelmäßigen Zugriffsprüfungen (*Access Reviews*) erhalten Verantwortliche eine Liste der Rechte und bestätigen oder streichen sie. Das erfüllt auch Anforderungen aus Standards wie ISO 27001.

> **Merke**
>
> Least Privilege: nur die nötigen Aktionen, auf die nötigen Ressourcen, unter nötigen Bedingungen. Werkzeuge: Access Analyzer, Last Accessed Information, Conditions, Boundaries, SCPs.

## 3.5 MFA und Passwortregeln

Die *Multi-Faktor-Authentifizierung* (MFA) verlangt zusätzlich zum Passwort einen zweiten Nachweis. Authentifizierungsfaktoren lassen sich in “Wissen” (Passwort), “Besitz” (Gerät, Schlüssel) und “Inhärenz” (Biometrie) einteilen. Ein gestohlenes Passwort allein genügt dann nicht. AWS unterstützt als MFA-Typen Passkeys und FIDO2-Sicherheitsschlüssel, Authenticator-Apps (zeitbasierte Einmalcodes, TOTP) und Hardware-TOTP-Token. Die offizielle Empfehlung lautet, für jeden Root-Benutzer und IAM-Benutzer MFA zu verlangen, bevorzugt mit phishing-resistenten Verfahren wie Passkeys oder Sicherheitsschlüsseln.

MFA ist besonders wichtig für privilegierte Zugriffe: den Root User, Administratoren und Benutzer, die Daten löschen oder Konfigurationen ändern dürfen. Zusätzlich kann man MFA für einzelne Aktionen erzwingen, indem man in einer Policy eine Bedingung auf `aws:MultiFactorAuthPresent` setzt. Bei Aufrufen über die CLI muss man dafür temporäre Zugangsdaten mit MFA-Code anfordern (`aws sts get-session-token`).

Neben MFA bestimmt die *Passwortrichtlinie* des Kontos, wie sichere Passwörter für IAM-Benutzer sein müssen: Mindestlänge, Zeichenarten, Ablauf, Wiederverwendungsverbot. Wichtig ist, sie sinnvoll zu bewerten: Moderne Empfehlungen (etwa die der US-Behörde NIST) legen mehr Gewicht auf Länge und Sperrlisten bekannter Passwörter als auf starre Zeichenregeln und raten von erzwungenem regelmäßigem Wechsel ohne konkreten Anlass ab. Ein regelmäßiger Wechsel ist dagegen bei langlebigen Zugriffsschlüsseln sinnvoll, weil diese oft vergessen werden. Noch besser ist es, sie durch Rollen und temporäre Zugangsdaten zu ersetzen.

Das folgende Beispiel legt eine Passwortrichtlinie fest und zeigt, wie man ein virtuelles MFA-Gerät für einen Benutzer anlegt.

```bash
aws iam update-account-password-policy \
  --minimum-password-length 14 \
  --require-symbols --require-numbers \
  --require-uppercase-characters --require-lowercase-characters \
  --password-reuse-prevention 5 --allow-users-to-change-password

aws iam create-virtual-mfa-device --virtual-mfa-device-name anna-mfa \
  --outfile anna-qr.png --bootstrap-method QRCodePNG
```

Die Passwortrichtlinie verlangt 14 Zeichen, mehrere Zeichenklassen und verbietet die Wiederverwendung der letzten fünf Passwörter. Der zweite Befehl erzeugt ein virtuelles MFA-Gerät samt QR-Code, den der Benutzer mit einer Authenticator-App einliest; anschließend aktiviert man das Gerät mit `enable-mfa-device` und zwei aufeinanderfolgenden Codes. Die Bilddatei enthält das Geheimnis und muss danach sicher gelöscht werden.

### Typische Fehler.

Falsch: MFA nur für Administratoren, nicht aber für Root. Falsch: Das MFA-Gerät auf dem gleichen Smartphone wie den Passwortmanager mit Zugriff auf alles zu betreiben, ohne Ersatz zu planen. Richtig: Mindestens zwei MFA-Geräte registrieren, damit ein Verlust nicht zur Aussperrung führt. Falsch ist auch, ausschließlich auf strenge Zeichenregeln zu vertrauen: `Passwort1!` erfüllt sie, ist aber trotzdem schwach.

### Praxisbezug.

In Unternehmen ist MFA Pflicht für alle Anmeldungen am Identity Center; für Break-Glass-Zugänge (Notzugänge) wird ein Hardware-Schlüssel im Tresor aufbewahrt.

## 3.6 AWS Organizations

Mit wachsender Nutzung reicht ein einzelnes Konto nicht mehr aus. Teams, Umgebungen (Entwicklung, Test, Produktion) und Projekte werden in getrennten Konten betrieben, weil das Konto die stärkste Isolationsgrenze in AWS ist: Rechte, Kosten und Fehlerquellen bleiben getrennt. *AWS Organizations* fasst diese Konten zu einer Organisation zusammen und ermöglicht zentrale Verwaltung.

Eine Organisation hat genau ein *Verwaltungskonto* (Management Account), das die Organisation erstellt und Rechnungen bezahlt, und beliebig viele *Mitgliedskonten*. Die Konten werden in einer Hierarchie aus *Organisationseinheiten* (OUs) angeordnet, ähnlich Ordnern, an deren Wurzel die *Root* der Organisation steht. Typisch sind OUs wie “Sicherheit”, “Infrastruktur”, “Workloads/Produktion” und “Workloads/Entwicklung”. Die Organisation bietet *konsolidierte Abrechnung*: Alle Kosten laufen auf einer Rechnung zusammen, und Mengenrabatte und Reservierungen können über Konten hinweg geteilt werden.

Zentral für die Governance sind *Service Control Policies* (SCPs). Eine SCP legt für ein Konto oder eine OU fest, welche Aktionen überhaupt erlaubt sein können, und zwar als Obergrenze. Eine SCP vergibt *keine* Rechte; sie begrenzt lediglich, was IAM-Richtlinien innerhalb der Konten gewähren können. Auch ein Administrator im Konto kann nicht, was die SCP verbietet. Die SCPs gelten nicht für das Verwaltungskonto selbst, weshalb dieses möglichst wenig Ressourcen enthalten sollte. Beispiele für sinnvolle SCPs sind das Verbot, CloudTrail abzuschalten, das Sperren nicht genutzter Regionen oder das Verbot, die Organisation zu verlassen.

Das Beispiel zeigt, wie man eine OU anlegt, eine SCP erstellt, die das Abschalten von CloudTrail verbietet, und sie anhängt.

```bash
ROOT=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
aws organizations create-organizational-unit --parent-id "$ROOT" --name Produktion

cat > scp-cloudtrail.json <<'EOT'
{ "Version": "2012-10-17",
  "Statement": [{ "Sid": "CloudTrailSchuetzen", "Effect": "Deny",
    "Action": ["cloudtrail:StopLogging", "cloudtrail:DeleteTrail"],
    "Resource": "*" }] }
EOT
aws organizations create-policy --name cloudtrail-schuetzen \
  --type SERVICE_CONTROL_POLICY --description "CloudTrail darf nicht abgeschaltet werden" \
  --content file://scp-cloudtrail.json
aws organizations attach-policy --policy-id p-examplepolicyid \
  --target-id ou-examplerootid-exampleouid
```

Zuerst wird die ID der Wurzel ermittelt und darunter die OU `Produktion` angelegt. Die Datei beschreibt eine Verbotsregel für zwei CloudTrail-Aktionen. `create-policy` legt sie als SCP an, `attach-policy` hängt sie an eine OU; `p-...` und `ou-...` sind Platzhalter und stehen in der Ausgabe der vorherigen Befehle. Damit können Konten in dieser OU CloudTrail nicht mehr stoppen, selbst wenn dort jemand Administratorrechte hat.

### Typische Fehler.

Falsch: “Die SCP erteilt Rechte”. Richtig: Sie begrenzt nur. Fehlt eine Erlaubnis in der IAM-Policy, hilft auch eine großzügige SCP nicht. Falsch: Produktion und Entwicklung im selben Konto zu betreiben. Falsch: Workloads im Verwaltungskonto laufen zu lassen, in dem keine SCP wirkt.

### Praxisbezug.

Beim Einrichten einer sogenannten Landing Zone (etwa mit AWS Control Tower) entstehen Konten für Protokolle, Sicherheit und Workloads automatisch mit passenden Leitplanken.

## 3.7 IAM Identity Center

Mit vielen Konten wird die Verwaltung einzelner IAM-Benutzer in jedem Konto unpraktisch. *AWS IAM Identity Center* (früher AWS Single Sign-On) löst das, indem es einen zentralen Ort für die Identitäten der Belegschaft bietet und Zugriff auf alle Konten der Organisation gewährt. Die Anmeldung erfolgt einmal (*Single Sign-On*), danach wählt die Person im *AWS Access Portal* Konto und Rolle aus.

Die Benutzer und Gruppen können im Identity Center selbst verwaltet werden oder aus einem vorhandenen Identitätsanbieter stammen, zum Beispiel Microsoft Entra ID oder Active Directory. Dadurch entfällt das Anlegen eigener Passwörter für AWS, und Vorgaben wie MFA und das Entfernen ausscheidender Mitarbeitender gelten zentral. Der Zugriff wird über *Permission Sets* definiert: Das sind Vorlagen aus verwalteten und eigenen Policies, die in jedem Konto als IAM-Rolle bereitgestellt werden. Eine *Zuweisung* (Assignment) verknüpft eine Gruppe, ein Konto und ein Permission Set: “Die Gruppe Entwickler erhält im Konto Test das Permission Set PowerUser”.

Der Weg des Zugriffs ist damit eine Kette temporärer Zugangsdaten: Person meldet sich an, wählt ein Konto und ein Permission Set, und das Identity Center stellt temporäre Zugangsdaten einer Rolle in diesem Konto aus. Es entstehen keine langlebigen Schlüssel. Für die CLI gibt es eine eigene Anmeldung, die mit dem Browser arbeitet. Das Beispiel zeigt die Einrichtung und Nutzung.

```bash
aws configure sso
# Eingaben: Start-URL, Region des Identity Centers, Konto, Permission Set
aws sso login --profile entwicklung-test
aws s3 ls --profile entwicklung-test
aws sts get-caller-identity --profile entwicklung-test
```

`aws configure sso` fragt nach der Start-URL des Access Portals und erzeugt ein benanntes Profil. `aws sso login` öffnet den Browser zur Anmeldung inklusive MFA und holt temporäre Zugangsdaten. Danach nutzt man das Profil mit `--profile`. Die letzte Zeile zeigt, dass die Identität eine angenommene Rolle ist (der ARN enthält `assumed-role`). Läuft die Sitzung ab, meldet man sich einfach neu an.

### Typische Fehler.

Falsch: Weiterhin pro Konto IAM-Benutzer anlegen, obwohl ein Identity Center zur Verfügung steht. Falsch: Permission Sets mit Administratorrechten an alle Gruppen vergeben. Richtig: Zuweisung an Gruppen (nicht einzelne Benutzer) und Permission Sets nach Aufgabenprofil, zum Beispiel “Nur lesen”, “Entwickler”, “Administrator”.

### Praxisbezug.

Verlässt eine Person die Firma, wird sie im Firmenverzeichnis deaktiviert; damit ist auch jeder AWS-Zugang gesperrt, ohne dass in jedem Konto etwas geändert werden muss.

## 3.8 Zugriffs-Troubleshooting

Ein `AccessDenied`-Fehler gehört zu den häufigsten Meldungen in AWS. Um ihn systematisch zu analysieren, hilft die Kenntnis der Auswertungslogik aus der Einheit zu Policies. Ein Zugriff scheitert, wenn keine Erlaubnis existiert (impliziter Deny) oder wenn ein ausdrückliches Verbot greift. Die Frage lautet daher stets: *Wer* hat *was* auf *welcher Ressource* versucht, und welche Richtlinienschicht blockiert?

Eine bewährte Vorgehensweise besteht aus fünf Schritten. Erstens die Fehlermeldung genau lesen: Neuere Meldungen nennen Identität, Aktion, Ressource und die Art des Verbots (“no identity-based policy allows” bei fehlender Erlaubnis, “explicit deny in a service control policy” bei einem Verbot). Zweitens die Identität prüfen: Mit `aws sts get-caller-identity` stellt man fest, ob man überhaupt die erwartete Rolle benutzt, denn oft ist ein falsches Profil oder ein falsches Konto aktiv. Drittens die Policies der Identität untersuchen und mit dem *IAM Policy Simulator* testen. Viertens die weiteren Schichten betrachten: Ressourcenrichtlinie, SCP, Permissions Boundary, Sitzungs-Policy und Bedingungen wie MFA oder Quell-IP. Fünftens in *AWS CloudTrail* nachsehen: Dort ist der Aufruf samt Fehlercode eingetragen, und bei einigen Diensten liefert der Fehler eine verschlüsselte Meldung, die sich mit `aws sts decode-authorization-message` lesen lässt.

Das folgende Beispiel zeigt die wichtigsten Werkzeuge: Der Simulator beantwortet die Frage, ob eine Identität eine bestimmte Aktion ausführen darf, CloudTrail zeigt, was wirklich passiert ist.

```bash
aws sts get-caller-identity

aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:user/anna \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::mein-lernbucket-2026-12345/bericht.pdf \
  --query 'EvaluationResults[].{Aktion:EvalActionName,Ergebnis:EvalDecision}'

aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetObject \
  --max-results 5 \
  --query 'Events[].{Zeit:EventTime,Benutzer:Username}'
```

Die erste Zeile klärt, welche Identität verwendet wird. Der Simulator wertet die Policies von `anna` für die Aktion aus und liefert `allowed`, `implicitDeny` oder `explicitDeny`; Letzteres weist auf ein Verbot hin, das man gezielt suchen muss. Die dritte Abfrage listet die letzten Aufrufe der Aktion aus dem CloudTrail-Ereignisverlauf. Der Simulator berücksichtigt nicht alle Schichten (zum Beispiel keine SCPs, sofern sie nicht ausdrücklich einbezogen werden), sodass ein “allowed” im Simulator den echten Zugriff nicht garantiert.

> **Praxisbeispiel**
>
> Ein Entwickler meldet “AccessDenied beim Lesen eines Buckets”. Die Analyse zeigt: Die Identity-Center-Rolle erlaubt `s3:GetObject`, die Anfrage kam aber über die falsche Region, und eine SCP verbietet alle Zugriffe außerhalb von Frankfurt. Der Simulator zeigte “allowed”, CloudTrail den Fehler mit Hinweis auf die SCP. Lösung: Anfrage in Frankfurt stellen.

### Typische Fehler.

Falsch: Bei einem Fehler sofort `s3:*` und `Resource: *` einzutragen, “damit es läuft”. Richtig: Die tatsächlich blockierende Schicht finden und gezielt die fehlende Aktion ergänzen. Falsch: Nur die Identitäts-Policy zu prüfen und Ressourcenrichtlinien (Bucket-Policy, KMS-Key-Policy) zu vergessen. Verschlüsselte Objekte benötigen zusätzlich Rechte am KMS-Schlüssel.

### Praxisbezug.

Teams legen für häufige Fehlerbilder ein kurzes Runbook an: Identität prüfen, Fehlermeldung lesen, Simulator, SCP, Ressourcenrichtlinie, CloudTrail. Das spart Eskalationen.

## Übungsaufgaben Modul 03

1.  Nennen Sie drei Schutzmaßnahmen für den Root User und zwei Aufgaben, für die er notwendig ist.

2.  Erklären Sie den Unterschied zwischen IAM-Benutzer und IAM-Rolle. Warum sind temporäre Zugangsdaten sicherer?

3.  Welche Bestandteile hat eine Policy-Anweisung? Was bedeutet “impliziter Deny” und warum überstimmt ein ausdrückliches Deny jedes Allow?

4.  Eine SCP in einer OU verbietet `ec2:*`; im Konto hat ein Administrator `Action: *`. Darf er EC2 nutzen? Begründen Sie.

5.  Was ist der Unterschied zwischen einer Identity-based und einer Resource-based Policy? Nennen Sie ein Beispiel für beide.

6.  **Praxis:** Schreiben Sie eine Policy, die nur das Lesen von Objekten im Bucket `berichte-2026` erlaubt und nur über HTTPS gilt.

7.  **Praxis:** Schreiben Sie CLI-Befehle, die eine Gruppe `auswertung` anlegen, ihr die AWS-Policy `ReadOnlyAccess` geben und den Benutzer `bernd` aufnehmen.

8.  **Praxis:** Ein Benutzer erhält `AccessDenied` beim Aufruf von `aws ec2 describe-instances`. Beschreiben Sie Schritt für Schritt, wie Sie vorgehen, und nennen Sie mindestens vier mögliche Ursachen.

## Lösungen Modul 03

1.  Schutz: MFA aktivieren (am besten Sicherheitsschlüssel), keine Zugriffsschlüssel anlegen, langes einzigartiges Passwort und geschütztes Gruppenpostfach, Alarm bei Anmeldung. Aufgaben: Schließen des eigenen Kontos, Ändern der Root-Einstellungen, Wiederherstellen von IAM-Rechten, Aktivieren des Billing-Zugriffs für IAM.

2.  Ein Benutzer hat langlebige Zugangsdaten (Passwort, Schlüssel); eine Rolle hat keine eigenen und wird angenommen, wobei STS temporäre Zugangsdaten ausstellt. Ein gestohlenes temporäres Token ist nur kurz nutzbar, ein Schlüssel dagegen unbegrenzt, bis jemand ihn bemerkt.

3.  Bestandteile: Effect, Action, Resource, optional Condition (und Principal bei Resource-based). Impliziter Deny: Ohne ausdrückliche Erlaubnis ist alles verboten. Ein ausdrückliches Deny gewinnt immer, damit Sicherheitsvorgaben nicht durch zusätzliche Erlaubnisse ausgehebelt werden können.

4.  Nein. Die SCP ist eine Obergrenze; was sie verbietet, kann keine Policy im Konto erlauben, auch nicht Administratorrechte.

5.  Identity-based hängt an einer Identität (Benutzer, Gruppe, Rolle) und sagt, was sie darf, zum Beispiel `AmazonS3ReadOnlyAccess` an einer Rolle. Resource-based hängt an einer Ressource und enthält einen Principal, zum Beispiel eine Bucket-Policy, die einem anderen Konto Lesezugriff gibt.

6.  Beispiellösung:

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::berichte-2026/*",
        "Condition": {"Bool": {"aws:SecureTransport": "true"}}
      }]
    }
    ```

    Zum Auflisten des Buckets bräuchte man zusätzlich `s3:ListBucket` auf dem Bucket-ARN.

7.  Beispiellösung:

    ```bash
    aws iam create-group --group-name auswertung
    aws iam attach-group-policy --group-name auswertung \
      --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
    aws iam add-user-to-group --user-name bernd --group-name auswertung
    ```

8.  Vorgehen: (1) Fehlermeldung genau lesen (implizit oder ausdrücklich?). (2) `aws sts get-caller-identity`: richtige Identität und richtiges Konto? (3) Policies der Identität prüfen und mit dem Policy Simulator `ec2:DescribeInstances` testen. (4) SCP, Permissions Boundary und Bedingungen prüfen. (5) CloudTrail-Ereignis ansehen. Mögliche Ursachen: keine Erlaubnis in der Policy; SCP verbietet EC2 oder die Region; Permissions Boundary; falsches Profil oder falsches Konto; Bedingung wie MFA oder IP nicht erfüllt; Anfrage in einer nicht aktivierten Region.
