# Modul 05 - Exchange und Kommunikations-Governance

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 8 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich ebenfalls auf 8 Stunden (8 × 1); hier gibt es keine Abweichung.  
**Priorität:** 2 (mittlere Priorität)

| **Nr.** | **Lerneinheit**           | **Dauer (h)** | **Prio** |
|:--------|:--------------------------|--------------:|---------:|
| 5.1     | Mailbox Governance        |             1 |        1 |
| 5.2     | Distribution Lists        |             1 |        1 |
| 5.3     | Microsoft 365 Groups      |             1 |        1 |
| 5.4     | Mail Flow Rules           |             1 |        1 |
| 5.5     | Shared Mailboxes          |             1 |        1 |
| 5.6     | Retention für Mail        |             1 |        2 |
| 5.7     | External Sender Controls  |             1 |        2 |
| 5.8     | Exchange-Troubleshooting  |             1 |        2 |
|         | **Summe laut Details**    |         **8** |          |
|         | **Dauer laut Modulblatt** |         **8** |          |

> **Merke: Exchange Online PowerShell und Beispielcode**
>
> Die Beispiele dieses Moduls verwenden das Modul `ExchangeOnlineManagement`. Mit `Connect-ExchangeOnline` baut man die Verbindung zu Exchange Online auf; für Retention und Compliance wird zusätzlich `Connect-IPPSSession` gebraucht (Modul 6). Die Beispiele folgen den Mustern der Microsoft-Dokumentation, wurden aber nicht gegen einen echten Tenant ausgeführt. Änderungen an Nachrichtenfluss und Postfächern wirken sofort auf die tägliche Arbeit aller Beschäftigten: Testen Sie in einem Testtenant, und legen Sie neue Regeln zuerst im Testmodus an.

E-Mail ist in den meisten Organisationen der wichtigste Kommunikationskanal und zugleich der häufigste Angriffsweg. Dieses Modul behandelt, wie man Postfächer, Verteiler, Gruppen und Nachrichtenfluss so ordnet, dass sie beherrschbar bleiben. Die Aufbewahrung von Inhalten wurde grundsätzlich in Modul 6 behandelt; hier wird sie auf Mail angewendet (Lerneinheit 5.6). Die Schutzfunktionen gegen Phishing und Schadsoftware (Defender für Office 365) stehen in Modul 8.4, die Gruppen als Basis für Teams in Modul 3.

## 5.1 Mailbox Governance

Ein Postfach (Mailbox) ist der Speicherort für E-Mails, Kalender, Kontakte und Aufgaben eines Benutzers oder einer gemeinsam genutzten Ressource. Governance bedeutet hier, dass der Bestand der Postfächer bekannt ist, dass jeder Typ eine verständliche Aufgabe hat und dass Konfigurationen, die Risiken erzeugen (Weiterleitungen nach außen, überfüllte Postfächer, fehlende Protokollierung), regelmäßig geprüft werden. Exchange Online kennt mehrere Postfachtypen: Benutzerpostfächer, freigegebene Postfächer (Lerneinheit 5.5), Ressourcenpostfächer für Räume und Geräte, und Postfächer, die zu Microsoft-365-Gruppen gehören (Lerneinheit 5.3). Wer die Typen nicht auseinanderhält, vergibt falsche Lizenzen und falsche Rechte.

Drei Dinge machen ein Postfach zum Governance-Thema. Erstens der Speicher: Jedes Postfach hat eine Obergrenze, und es gibt ein Archivpostfach für ältere Inhalte. Zweitens die Weiterleitung: Ein Benutzer oder ein Angreifer kann Mail automatisch an eine externe Adresse weiterleiten lassen, was ein klassischer Weg ist, um Informationen abzuziehen. Drittens die Nachvollziehbarkeit: Die Protokollierung von Postfachzugriffen (Mailbox Auditing) gehört zu den Grundlagen jeder Untersuchung (Modul 7.1). Hinzu kommt der Lebenszyklus: Was passiert mit dem Postfach, wenn jemand ausscheidet, und wer darf auf ein Postfach zugreifen, wenn die Person nicht erreichbar ist?

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu den Grenzen in Exchange Online nennt für das Archivpostfach zunächst 100 GB, bei aktivierter automatisch erweiterter Archivierung bis zu 1,5 TB einschließlich des Ordners „Recoverable Items“. Eine Aufbewahrungsrichtlinie verschiebt Nachrichten nach der Dokumentation nur dann automatisch ins Archiv, wenn das Hauptpostfach größer als 10 MB ist. Zudem darf ein Archivpostfach nur Mail einer einzelnen Person oder Einheit mit Lizenz speichern; Sammelarchive durch Kopien in ein gemeinsames Postfach sind ausdrücklich untersagt. Die Standardgrenzen und Lizenzbedingungen ändern sich; prüfen Sie sie in der aktuellen Dokumentation, bevor Sie sie in einem Konzept festschreiben.

Ein tragfähiges Konzept legt fest: Für jeden Postfachtyp gibt es eine Namenskonvention und einen Verantwortlichen. Weiterleitungen nach außen sind standardmäßig nicht erlaubt und nur mit Ausnahmeprozess (Modul 8.7) möglich. Der Postfachbestand wird vierteljährlich ausgewertet: Typ, Größe, Archivstatus, Weiterleitung, letzte Anmeldung. Postfächer ausgeschiedener Personen werden nach festem Ablauf behandelt: Übergabe an den Vorgesetzten für einen begrenzten Zeitraum, dann Löschung oder Umwandlung in ein freigegebenes Postfach, immer abgestimmt mit der Aufbewahrung (Lerneinheit 5.6) und mit eventuellen rechtlichen Sperren (Modul 7.6).

Das folgende Skript erstellt ein Inventar aller Postfächer mit den governance-relevanten Merkmalen und weist auf Weiterleitungen nach außen hin. Es liest die Postfächer mit `Get-Mailbox`, ergänzt je Postfach die Größe über `Get-MailboxStatistics` und schreibt eine CSV-Datei. Die Eigenschaften `ForwardingAddress` und `ForwardingSmtpAddress` zeigen Weiterleitungen, die ein Administrator gesetzt hat. Weiterleitungen über Posteingangsregeln des Benutzers erfasst das Skript nicht, dafür gibt es eine eigene Abfrage (siehe Lösung zu Aufgabe 6).

**Export-MailboxInventory.ps1**

```powershell
param([string]$Ausgabe = ".\Postfachinventar.csv")

Connect-ExchangeOnline

$postfaecher = Get-Mailbox -ResultSize Unlimited
if (-not $postfaecher) { throw "Keine Postfaecher gefunden." }

$inventar = foreach ($p in $postfaecher) {
    $stat = Get-MailboxStatistics -Identity $p.ExchangeGuid.ToString() -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Anzeigename    = $p.DisplayName
        Adresse        = $p.PrimarySmtpAddress
        Typ            = $p.RecipientTypeDetails
        GroesseMB      = if ($stat) { [math]::Round($stat.TotalItemSize.Value.ToMB(), 0) } else { $null }
        ArchivAktiv    = $p.ArchiveStatus
        LitigationHold = $p.LitigationHoldEnabled
        WeiterleitungIntern = $p.ForwardingAddress
        WeiterleitungExtern = $p.ForwardingSmtpAddress
        LetzteAnmeldung = if ($stat) { $stat.LastLogonTime } else { $null }
    }
}

$inventar | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
"{0} Postfaecher exportiert nach {1}" -f @($inventar).Count, $Ausgabe

$extern = $inventar | Where-Object { $_.WeiterleitungExtern }
if ($extern) {
    Write-Warning "$(@($extern).Count) Postfaecher mit Weiterleitung an eine SMTP-Adresse:"
    $extern | Select-Object Adresse, WeiterleitungExtern | Format-Table -AutoSize
}
```

Die Schleife holt für jedes Postfach die Statistik, wobei `-ErrorAction SilentlyContinue` verhindert, dass ein einzelnes defektes Postfach das ganze Skript abbricht. Die Größe wird mit `ToMB()` in Megabyte umgerechnet. Der Tabelleneintrag enthält Typ, Archivstatus, Haltestatus, Weiterleitungen und letzte Anmeldung. Am Ende zeigt das Skript Postfächer mit Weiterleitung an eine SMTP-Adresse getrennt an, denn diese sind der wichtigste Befund. Bei sehr vielen Postfächern dauert der Lauf lange; dann teilt man ihn nach Typ auf.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, dass niemand den Bestand kennt: Es gibt Postfächer ohne Besitzer, abgemeldete Postfächer mit Lizenz und Testpostfächer aus alten Projekten. Zweitens bleiben Weiterleitungen, die für eine Urlaubsvertretung eingerichtet wurden, jahrelang bestehen. Drittens wird die Größe erst beachtet, wenn ein Postfach voll ist und die Person keine Mail mehr empfängt. Viertens wird nicht zwischen Benutzer- und freigegebenem Postfach unterschieden, und jemand legt Verträge in einem persönlichen Postfach ab.

**Falsch und richtig: Weiterleitungen**

```powershell
# FALSCH: Weiterleitung "mal eben" fuer Urlaub nach extern setzen, keine Frist
Set-Mailbox -Identity anna@contoso.com -ForwardingSmtpAddress "anna.privat@example.com"

# RICHTIG: intern an Vertretung weiterleiten, ohne Kopie im eigenen Postfach zu verlieren
Set-Mailbox -Identity anna@contoso.com -ForwardingAddress "vertretung@contoso.com" `
    -DeliverToMailboxAndForward $true
# Frist im Ticket festhalten und nach der Rueckkehr wieder entfernen
```

Der Unterschied: Die richtige Variante bleibt in der Organisation, behält eine Kopie im Postfach und wird dokumentiert. Eine Weiterleitung an eine private Adresse verlässt den Schutzbereich aller Richtlinien aus Modul 6.

### Praxisbezug.

In der Praxis beginnt jedes Exchange-Governance-Projekt mit diesem Inventar. Es deckt in der Regel verwaiste Postfächer, vergessene Weiterleitungen und falsche Lizenzen auf, und die Einsparungen finanzieren oft das Projekt. Planen Sie den Lauf als wiederkehrende Aufgabe (Modul 11), und berichten Sie die Zahl der externen Weiterleitungen als Kennzahl (Modul 9.8).

## 5.2 Distribution Lists

Eine *Verteilerliste* (Distribution List, auch Verteilergruppe) ist eine E-Mail-Adresse, hinter der mehrere Empfänger stehen: Wer an „vertrieb@contoso.com“ schreibt, erreicht alle Mitglieder. Verteilerlisten sind das älteste Gruppenkonzept von Exchange und in vielen Organisationen in großer Zahl vorhanden, oft mit unklarem Zweck und veralteten Mitgliedern. Sie sind reine Mailfunktionen: Sie haben keinen gemeinsamen Dateispeicher, keinen Kalender und keinen Chatraum. Genau dafür gibt es Microsoft-365-Gruppen (Lerneinheit 5.3). Verteilerlisten bleiben aber sinnvoll, wenn nur eine Adresse für viele Empfänger gebraucht wird, etwa „alle-mitarbeitende“.

Man unterscheidet mehrere Arten. Die klassische Verteilergruppe hat feste Mitglieder, die jemand pflegt. Die *dynamische Verteilergruppe* bestimmt ihre Mitglieder bei jeder Zustellung anhand einer Abfrage, zum Beispiel „alle Benutzer der Abteilung Vertrieb“, und braucht deshalb keine Pflege, wohl aber saubere Attribute im Verzeichnis (Modul 2). Die *E-Mail-aktivierte Sicherheitsgruppe* kann zugleich für Berechtigungen und als Verteiler dienen. Die richtige Wahl hängt vom Zweck ab: Wer eine Gruppe für Berechtigungen braucht, nimmt eine Sicherheitsgruppe, wer Zusammenarbeit will, eine Microsoft-365-Gruppe, und wer nur eine Adresse braucht, eine Verteilerliste.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zur Namensrichtlinie für Microsoft-365-Gruppen gilt diese Richtlinie nicht für Verteilergruppen in Exchange Online; für sie gibt es eine eigene Namensrichtlinie in Exchange. Die Dokumentation zu Verteilergruppen beschreibt außerdem Einstellungen wie die Verwaltung durch Besitzer, Beitrittsregeln und die Einschränkung, wer an die Liste senden darf. Ob Ihre Organisation Verteilerlisten künftig auf Microsoft-365-Gruppen migrieren will, ist eine Architekturentscheidung; für den Übergang gibt es in Exchange eine Möglichkeit, eine Verteilergruppe in eine Microsoft-365-Gruppe zu aktualisieren, deren Voraussetzungen in der aktuellen Dokumentation zu prüfen sind.

Governance für Verteilerlisten beantwortet fünf Fragen. Wer ist Besitzer, und gibt es eine Vertretung? Wer darf an die Liste senden (nur intern, nur Mitglieder, jeder)? Wer darf beitreten (nur durch Besitzer, nach Genehmigung)? Ist die Liste im Adressbuch sichtbar? Und wann wird sie überprüft oder gelöscht? Ohne Antworten entstehen Listen, die bis in die Geschäftsleitung zugestellt werden, an die aber auch externe Absender schreiben dürfen, was Spam und Phishing verbreitet. Ein weiterer Risikopunkt ist die Schachtelung: Listen in Listen führen dazu, dass niemand mehr weiß, wer eine Nachricht tatsächlich erhält.

Das Skript prüft alle Verteilergruppen auf diese Punkte. Es meldet Listen ohne Besitzer, Listen, die externe Absender annehmen, Listen ohne Mitglieder und Listen, die in mehr als einer Ebene verschachtelt sind, soweit sich das aus den Mitgliedern ergibt. Es verwendet `Get-DistributionGroup` und `Get-DistributionGroupMember`. Die Eigenschaft `RequireSenderAuthenticationEnabled` steuert, ob nur authentifizierte (interne) Absender senden dürfen.

**Test-DistributionGroups.ps1**

```powershell
Connect-ExchangeOnline

$gruppen = Get-DistributionGroup -ResultSize Unlimited
if (-not $gruppen) { Write-Host "Keine Verteilergruppen gefunden."; return }

$befunde = foreach ($g in $gruppen) {
    $mitglieder = @(Get-DistributionGroupMember -Identity $g.Identity -ResultSize Unlimited -ErrorAction SilentlyContinue)
    $verschachtelt = @($mitglieder | Where-Object { $_.RecipientType -like "*Group*" }).Count
    $probleme = @()
    if (-not $g.ManagedBy -or @($g.ManagedBy).Count -eq 0) { $probleme += "kein Besitzer" }
    if (-not $g.RequireSenderAuthenticationEnabled)         { $probleme += "externe Absender erlaubt" }
    if ($mitglieder.Count -eq 0)                            { $probleme += "keine Mitglieder" }
    if ($verschachtelt -gt 0)                               { $probleme += "verschachtelt ($verschachtelt)" }
    if ($probleme) {
        [pscustomobject]@{ Gruppe = $g.PrimarySmtpAddress; Mitglieder = $mitglieder.Count
                           Befund = ($probleme -join "; ") }
    }
}

if ($befunde) { $befunde | Sort-Object Gruppe | Format-Table -AutoSize -Wrap }
"{0} von {1} Verteilergruppen mit Befund." -f @($befunde).Count, @($gruppen).Count
```

Für jede Gruppe liest das Skript die Mitglieder (mit Fehlerunterdrückung, damit eine defekte Gruppe nicht alles stoppt) und sammelt Befunde in einer Liste. Der Operator `-like "*Group*"` erkennt Mitglieder, die selbst Gruppen sind. Das Ergebnis zeigt nur Gruppen mit mindestens einem Befund. Bei Tausenden Gruppen dauert die Abfrage lange, deshalb läuft sie als geplante Aufgabe außerhalb der Arbeitszeit.

### Typische Fehler und Stolperfallen.

Verteilerlisten wuchern: Für jedes Projekt entsteht eine neue, keine wird gelöscht. Zweitens bleiben Listen für Führungskräfte offen für externe Absender. Drittens wird eine Liste als Berechtigungsgruppe zweckentfremdet, was in der Verwaltung zu Verwirrung führt. Viertens sind Besitzer ausgeschieden, und niemand pflegt die Liste mehr.

**Falsch und richtig: Absenderbeschraenkung**

```powershell
# FALSCH: Liste der Geschaeftsleitung nimmt Mail von jedem entgegen
New-DistributionGroup -Name "Geschaeftsleitung" -PrimarySmtpAddress gl@contoso.com

# RICHTIG: nur authentifizierte Absender, Besitzer gesetzt, im Adressbuch verborgen
New-DistributionGroup -Name "Geschaeftsleitung" -PrimarySmtpAddress gl@contoso.com `
    -ManagedBy "assistenz@contoso.com" -MemberJoinRestriction Closed
Set-DistributionGroup -Identity gl@contoso.com -RequireSenderAuthenticationEnabled $true `
    -HiddenFromAddressListsEnabled $true
```

Die korrigierte Variante setzt einen Besitzer, schließt den freien Beitritt, erlaubt nur authentifizierte Absender und verbirgt die Liste. Ob Verbergen im Adressbuch sinnvoll ist, hängt vom Zweck ab; als Schutz vor gezielten Angriffen ersetzt es keine Absenderbeschränkung.

### Praxisbezug.

Im Projekt starten Sie mit einer Bereinigung: Listen ohne Besitzer oder Mitglieder werden mit den Fachbereichen geklärt und gelöscht. Danach legen Sie fest, dass neue Zusammenarbeit in Microsoft-365-Gruppen entsteht und Verteilerlisten nur für reine Adressfunktionen. Das senkt die Zahl der Listen, die gepflegt werden müssen.

## 5.3 Microsoft 365 Groups

Eine *Microsoft-365-Gruppe* ist ein gemeinsamer Arbeitsbereich mit Identität: Sie bringt ein gemeinsames Postfach, einen Kalender, eine SharePoint-Website, einen Planner und auf Wunsch ein Team in Microsoft Teams mit. Mitgliedschaft und Besitz in der Gruppe bestimmen zugleich die Rechte in all diesen Diensten. Sie ist deshalb der Baustein, auf dem Teams, Viva Engage-Communities und viele Websites aufbauen, und ein Kernthema der Governance, das in den Modulen 2, 3 und 4 schon aus anderen Blickwinkeln auftauchte. Hier steht der Exchange-Blick im Vordergrund: Das Gruppenpostfach, die Sichtbarkeit im Adressbuch, die Absenderregeln und die Namensgebung.

Zwei Steuerungen aus der Microsoft-Dokumentation sind zentral. Die *Namensrichtlinie* (Naming Policy) erzwingt Präfixe und Suffixe und sperrt Wörter. Die *Ablaufrichtlinie* (Expiration Policy) lässt Gruppen nach einer festgelegten Zeit auslaufen, wenn niemand sie bestätigt. Beide verhindern Wildwuchs: Sie sorgen dafür, dass man Gruppen findet und dass unbenutzte Gruppen verschwinden. Die Standardeinstellung erlaubt allen Benutzern, Gruppen zu erstellen, was ohne Gegenmaßnahmen zu verwaisten und inaktiven Gruppen führt.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Namensrichtlinie nennt folgende Eckdaten: Die Richtlinie besteht aus einer Präfix-Suffix-Vorgabe und einer Liste gesperrter Wörter. Präfixe und Suffixe können feste Zeichenfolgen oder Benutzerattribute wie Abteilung, Firma, Büro, Bundesland, Land oder Titel sein; Erweiterungsattribute werden nicht unterstützt. Die Gesamtlänge einschließlich des Gruppennamens ist auf 63 Zeichen begrenzt. Gesperrte Wörter werden ohne Beachtung der Groß- und Kleinschreibung und nur bei exakter Übereinstimmung geprüft (keine Teilwortsuche), die Liste darf bis zu 5000 Begriffe enthalten. Einige Administratorrollen sind von der Richtlinie ausgenommen, darunter der Globale Administrator und der Benutzeradministrator. Die Richtlinie setzt eine Microsoft-Entra-ID-P1-Lizenz voraus und gilt für Gruppen in allen Arbeitslasten (Outlook, Teams, SharePoint, Planner, Viva Engage), jedoch nicht für Verteilergruppen. Nach der Dokumentation zur Gruppenerstellung ist die Erstellung standardmäßig für alle Benutzer erlaubt und kann eingeschränkt werden; die Ablaufrichtlinie bewertet die Aktivität in Teams, SharePoint und Outlook, um Gruppen zu erneuern.

Die Namensrichtlinie ist ein gutes Beispiel für eine Regel, die erst im Zusammenspiel Wirkung entfaltet. Ein Präfix wie „GRP“ plus Abteilung macht aus „Projekt Phoenix“ einen Namen, der im Adressbuch auffindbar und sortierbar ist. Die gesperrte Wortliste verhindert Namen mit „CEO“ oder „Payroll“ durch normale Benutzer. Beachten Sie die Grenze: Sie gilt für Benutzer, nicht für ausgenommene Administratoren, und sie verhindert nicht die Umbenennung durch Teams-Besitzer innerhalb der Regeln. Außerdem entsteht bei Attributen als Platzhalter ein Qualitätsproblem: Fehlt bei einem Benutzer die Abteilung, erscheint der Platzhalter oder bleibt leer.

Das folgende Skript liest die Gruppeneinstellung für die Namensrichtlinie aus und setzt Präfix-Suffix-Vorgabe und gesperrte Wörter. Es folgt dem Muster aus der Microsoft-Dokumentation mit den Beta-Cmdlets für Verzeichniseinstellungen: Es liest die Einstellung „Group.Unified“, bildet die Parameter und aktualisiert die Einstellung. Existiert noch keine solche Einstellung im Tenant, muss sie zuerst aus der Vorlage erzeugt werden; das Skript meldet das und bricht ab, statt zu raten.

**Set-GroupNamingPolicy.ps1**

```powershell
param(
    [string]$Muster  = "GRP_[GroupName]_[Department]",
    [string]$Gesperrt = "Payroll,CEO,Gehalt"
)

Connect-MgGraph -Scopes "Directory.ReadWrite.All" -NoWelcome

$einstellung = Get-MgBetaDirectorySetting | Where-Object DisplayName -eq "Group.Unified"
if (-not $einstellung) {
    throw "Keine Einstellung 'Group.Unified' vorhanden. Zuerst aus der Vorlage anlegen (siehe Dokumentation zu Gruppeneinstellungen)."
}

"Aktuelle Werte:"
$einstellung.Values | Where-Object Name -in "PrefixSuffixNamingRequirement","CustomBlockedWordsList" |
    Format-Table Name, Value -AutoSize

if ($Muster -notmatch "\[GroupName\]") { throw "Das Muster muss [GroupName] enthalten." }

$parameter = @{
    values = @(
        @{ name = "PrefixSuffixNamingRequirement"; value = $Muster }
        @{ name = "CustomBlockedWordsList";        value = $Gesperrt }
    )
}
Update-MgBetaDirectorySetting -DirectorySettingId $einstellung.Id -BodyParameter $parameter
"Namensrichtlinie gesetzt: $Muster"
```

Das Skript sucht die Einstellung mit dem Anzeigenamen „Group.Unified“, zeigt die aktuellen Werte und prüft, dass das Muster den Platzhalter für den Gruppennamen enthält, was die Dokumentation verlangt. Danach schreibt es beide Werte in einem Aufruf. Wichtig: Der Aufruf ersetzt die genannten Einstellungen; andere Werte der Einstellung bleiben unberührt, solange sie nicht in der Liste stehen. Prüfen Sie nach dem Lauf in Outlook oder Teams, ob ein neuer Gruppenname das Präfix erhält.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, die Namensrichtlinie nachträglich einzuführen und anzunehmen, bestehende Gruppen würden umbenannt: Die Richtlinie wirkt bei Anlage und bei Änderungen, nicht rückwirkend auf alle Namen. Zweitens wird die Lizenzfrage übersehen. Drittens werden Attribute als Platzhalter genutzt, die nicht für alle Benutzer gepflegt sind. Viertens wird zwar die Namensrichtlinie, nicht aber die Frage geklärt, wer Gruppen erstellen darf.

**Falsch und richtig: Muster pruefen**

```powershell
# FALSCH: Muster ohne [GroupName] - die Einstellung funktioniert nicht
$muster = "GRP_[Department]"

# RICHTIG: Platzhalter fuer den Gruppennamen ist Pflicht
$muster = "GRP_[GroupName]_[Department]"
if ($muster -notmatch "\[GroupName\]") { throw "Muster ungueltig" }
```

Die einfache Prüfung verhindert, dass eine ungültige Vorgabe gespeichert wird. Das Skript oben enthält diese Prüfung bereits.

### Praxisbezug.

Gruppen sind der Ort, an dem Governance-Entscheidungen der Module 3, 4 und 5 zusammenlaufen. Legen Sie gemeinsam fest: wer Gruppen erstellen darf (Self-Service mit Richtlinie oder über die Bereitstellungsfabrik aus Modul 10), wie sie heißen, wann sie ablaufen und wie Besitzer erinnert werden. Messen Sie den Anteil der Gruppen mit mindestens zwei Besitzern.

## 5.4 Mail Flow Rules

Eine *Nachrichtenflussregel* (Mail Flow Rule, auch Transportregel) prüft Nachrichten, während sie durch Exchange Online laufen, und führt bei einer Übereinstimmung eine Aktion aus: einen Haftungsausschluss anhängen, eine Kopie an eine Compliance-Adresse senden, eine Nachricht in Quarantäne legen, einen Header setzen oder die Zustellung ablehnen. Eine Regel besteht aus Bedingungen (wann), Aktionen (was) und Ausnahmen (wann nicht). Dazu kommen eine Priorität, ein Modus und ein Aktivierungszeitraum. Weil die Regeln auf jede Nachricht der gesamten Organisation wirken, sind sie mächtig und zugleich gefährlich: Eine falsch formulierte Regel kann Mail verzögern, umleiten oder löschen.

Die Reihenfolge entscheidet. Regeln werden nach ihrer Priorität von der niedrigsten Zahl aufwärts abgearbeitet, und eine Regel kann die Verarbeitung weiterer Regeln anhalten. Zwei Regeln, die dasselbe Merkmal prüfen, verhalten sich deshalb je nach Reihenfolge unterschiedlich. Ein bewährtes Muster ist, Regeln in Gruppen zu ordnen: zuerst Sicherheitsregeln (Blockieren, Quarantäne), dann Compliance-Regeln, dann kosmetische Regeln wie Signaturen. Jede Regel erhält einen sprechenden Namen und einen Kommentar mit Zweck, Besitzer und Änderungsdatum, denn Exchange führt keine Änderungshistorie der Regeln.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu Nachrichtenflussregeln können Änderungen an einer Regel bis zu 30 Minuten dauern, bis sie wirksam werden. Außerdem ist die Größe einer Regel begrenzt: Überschreitet sie das Limit (in der Dokumentation zur Fehlermeldung „Regel zu groß“ ist von 8 KB die Rede), lässt sich die Regel nicht anlegen oder speichern, und man teilt sie auf mehrere Regeln auf. Für Regeln gibt es ferner einen Testmodus (mit oder ohne Richtlinientipp), bevor sie auf „Erzwingen“ gestellt werden. Prüfen Sie die aktuellen Grenzwerte in der Dokumentation, bevor Sie eine Regel mit sehr langen Wortlisten planen.

Zum Verständnis hilft ein Gedankenmodell: Jede Regel ist ein Filter am Eingang des Postverteilers. Die Bedingung beschreibt, welche Nachrichten passieren sollen, die Aktion, was mit ihnen geschieht. Daraus folgt eine wichtige Faustregel: Je enger die Bedingung, desto kleiner das Risiko. Eine Regel „Alle Nachrichten an extern“ ist fast immer falsch, eine Regel „Nachrichten von extern, die den Absendernamen eines Mitarbeiters imitieren“ dagegen sehr gezielt.

Das folgende Beispiel legt eine Regel an, die externe Nachrichten, deren Anzeigename mit dem eines Geschäftsleitungsmitglieds übereinstimmt, mit einem Hinweis versieht und zunächst nur im Testmodus mit Richtlinientipp läuft. Das Skript prüft zuerst, ob schon eine Regel gleichen Namens existiert, und legt sie dann an. Den Namen der Geschäftsleitung ersetzt man durch die tatsächlichen Anzeigenamen.

**New-ImpersonationWarningRule.ps1**

```powershell
param([string]$Name = "Warnung: Absender imitiert Geschaeftsleitung")

Connect-ExchangeOnline

if (Get-TransportRule -Identity $Name -ErrorAction SilentlyContinue) {
    throw "Regel '$Name' existiert bereits."
}

$anzeigenamen = "Erika Mustermann","Max Beispiel"

New-TransportRule -Name $Name `
    -FromScope NotInOrganization `
    -HeaderMatchesMessageHeader "From" `
    -HeaderMatchesPatterns $anzeigenamen `
    -PrependSubject "[EXTERN] " `
    -SetAuditSeverity High `
    -Mode AuditAndNotify `
    -Comments "Zweck: Phishing-Hinweis. Besitzer: Messaging-Team. Angelegt: Testmodus." `
    -Priority 0

Get-TransportRule -Identity $Name | Format-List Name, State, Mode, Priority
```

Der Parameter `-FromScope NotInOrganization` begrenzt die Regel auf externe Absender. Die Bedingung vergleicht den Kopfzeilenwert „From“ mit den Namen. Die Aktion stellt dem Betreff eine Markierung voran. Mit `-Mode AuditAndNotify` wird die Regel zunächst nur protokolliert und meldet Treffer, ohne zu verändern; erst nach der Auswertung stellt man sie auf `Enforce`. Beachten Sie, dass der genaue Parametersatz je nach Exchange-Version variiert; prüfen Sie die Syntax mit `Get-Help New-TransportRule`.

### Typische Fehler und Stolperfallen.

Die häufigsten Fehler sind zu breite Bedingungen, falsche Prioritäten und fehlende Ausnahmen. Ebenso verbreitet ist, Regeln direkt im Erzwingungsmodus anzulegen. Weitere Stolpersteine: Regeln werden nach Wochen nicht mehr verstanden, weil Zweck und Besitzer fehlen, und mehrere Regeln hängen denselben Haftungsausschluss mehrfach an, weil die Verarbeitung nicht angehalten wird.

**Falsch und richtig: Regeln einfuehren**

```powershell
# FALSCH: breite Regel direkt erzwingen, ohne Test und ohne Ausnahme
New-TransportRule -Name "Alles an extern blockieren" -FromScope InOrganization `
    -SentToScope NotInOrganization -RejectMessageReasonText "Nicht erlaubt" -Mode Enforce

# RICHTIG: eng gefasst, mit Ausnahme, zuerst im Testmodus
New-TransportRule -Name "Vertrauliche Betreffs nicht nach extern" `
    -FromScope InOrganization -SentToScope NotInOrganization `
    -SubjectContainsWords "VERTRAULICH" `
    -ExceptIfSentTo "partner@example.com" `
    -RejectMessageReasonText "Vertrauliche Mails duerfen die Organisation nicht verlassen." `
    -Mode AuditAndNotify -Comments "Testmodus bis zur Auswertung"
```

Die korrigierte Fassung begrenzt die Wirkung auf einen Betreff, kennt eine begründete Ausnahme und läuft nur im Test. Nach einer Woche wertet man die Treffer aus, bevor man umschaltet. Wortbasierte Erkennung ist für echte Schutzwirkung ohnehin nur zweite Wahl; die Erkennung vertraulicher Inhalte gehört in Purview DLP (Modul 6.2).

### Praxisbezug.

In der Praxis sind Mail-Flow-Regeln oft über Jahre gewachsen, und niemand weiß mehr, welche noch gebraucht wird. Exportieren Sie sie regelmäßig als Konfigurationsstand (Modul 11.3), dokumentieren Sie Zweck und Besitzer, und räumen Sie jährlich auf. Für Ausnahmen von Regeln gilt der Prozess aus Modul 8.7.

## 5.5 Shared Mailboxes

Ein *freigegebenes Postfach* (Shared Mailbox) ist ein Postfach ohne eigenen Benutzer, auf das mehrere Personen zugreifen, zum Beispiel „info@“, „support@“ oder „rechnungen@“. Es hat keine eigenen Anmeldedaten im normalen Gebrauch: Die berechtigten Personen öffnen es über ihr eigenes Konto und können in seinem Namen lesen, senden oder beides. Damit eignet es sich für Funktionsadressen, bei denen es egal sein soll, welche Person gerade antwortet.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation zu freigegebenen Postfächern benötigt ein freigegebenes Postfach keine eigene Lizenz, solange es unter 50 GB bleibt; benötigt es mehr Speicher, ein Archiv oder bestimmte Compliance-Funktionen (etwa Aufbewahrung mit Litigation Hold), braucht es eine passende Exchange-Online-Lizenz. Die Dokumentation empfiehlt außerdem, die direkte Anmeldung am freigegebenen Postfach zu blockieren, weil das zugehörige Benutzerkonto sonst ein unnötiges Angriffsziel ist. Die Zugriffsrechte werden über Berechtigungen am Postfach vergeben (Vollzugriff, Senden als, Senden im Auftrag). Die genauen Lizenzgrenzen und Funktionen sollten Sie vor einer Entscheidung in der aktuellen Dokumentation prüfen.

Drei Berechtigungen sind zu unterscheiden. *Vollzugriff* erlaubt das Lesen und Verwalten des Postfachinhalts. *Senden als* lässt eine Person mit der Postfachadresse als Absender senden, ohne dass der Empfänger den wirklichen Absender sieht. *Senden im Auftrag* zeigt den Absender als „Person im Auftrag von Postfach“. Welche Berechtigung passt, ist eine Frage der Nachvollziehbarkeit: Für Kundenservice-Postfächer ist „im Auftrag“ transparenter, für anonyme Funktionsadressen genügt „Senden als“. Berechtigungen sollten an Gruppen vergeben werden, nicht an Einzelpersonen, damit der Zugriff über die Gruppenmitgliedschaft (und deren Überprüfung, Modul 2.6) steuerbar bleibt.

Das Skript legt ein freigegebenes Postfach an, vergibt Rechte an eine Sicherheitsgruppe und blockiert die direkte Anmeldung am zugehörigen Konto. Das Blockieren geschieht in Entra ID und nicht in Exchange; das Skript verwendet dafür Microsoft Graph und setzt voraus, dass das Konto bereits existiert.

**New-SharedMailboxGoverned.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Name,
    [Parameter(Mandatory)][string]$Adresse,
    [Parameter(Mandatory)][string]$Berechtigtengruppe
)

Connect-ExchangeOnline
Connect-MgGraph -Scopes "User.ReadWrite.All" -NoWelcome

New-Mailbox -Shared -Name $Name -DisplayName $Name -PrimarySmtpAddress $Adresse | Out-Null

Add-MailboxPermission -Identity $Adresse -User $Berechtigtengruppe `
    -AccessRights FullAccess -AutoMapping $false | Out-Null
Add-RecipientPermission -Identity $Adresse -Trustee $Berechtigtengruppe `
    -AccessRights SendAs -Confirm:$false | Out-Null

# Direkte Anmeldung am Konto des Postfachs blockieren
Update-MgUser -UserId $Adresse -AccountEnabled:$false

Get-MailboxPermission -Identity $Adresse |
    Where-Object { $_.User -ne "NT AUTHORITY\SELF" } |
    Format-Table User, AccessRights, IsInherited -AutoSize
```

Das Skript beginnt mit dem Anlegen des Postfachs und vergibt Vollzugriff und Senden-als-Recht an die Gruppe. Der Parameter `-AutoMapping $false` verhindert, dass das Postfach automatisch in Outlook bei allen Berechtigten erscheint, was bei großen Gruppen sonst die Anmeldung verlangsamt. Danach wird das Konto deaktiviert, und eine Kontrollausgabe zeigt die vergebenen Rechte. Neue Berechtigungen brauchen nach der Dokumentation eine gewisse Zeit, bis Outlook sie anzeigt.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, ein freigegebenes Postfach über 50 GB wachsen zu lassen und erst dann zu bemerken, dass eine Lizenz fehlt. Zweitens bleibt die Anmeldung am Konto offen, oft mit einem schwachen Kennwort, das niemand verwaltet. Drittens werden Rechte an Einzelpersonen vergeben, die später die Abteilung wechseln. Viertens wird das Postfach für Kundenkontakte genutzt, ohne dass klar ist, wer Mails beantwortet.

**Falsch und richtig: Berechtigungen**

```powershell
# FALSCH: Rechte an einzelne Personen, AutoMapping an
Add-MailboxPermission -Identity info@contoso.com -User anna@contoso.com -AccessRights FullAccess

# RICHTIG: Rechte an eine Gruppe, deren Mitglieder regelmaessig geprueft werden
Add-MailboxPermission -Identity info@contoso.com -User "SG-Postfach-Info" `
    -AccessRights FullAccess -AutoMapping $false
```

Mit der Gruppenlösung ändert sich beim Wechsel einer Person nur die Gruppenmitgliedschaft, nicht das Postfach. Zugleich lässt sich die Gruppe in der Zugriffsüberprüfung der Entra ID Governance behandeln.

### Praxisbezug.

Funktionspostfächer sind im Alltag häufig, und ihre Berechtigungen werden selten überprüft. Nehmen Sie sie in das Inventar aus Lerneinheit 5.1 auf, vergeben Sie einen Besitzer, und prüfen Sie halbjährlich die Gruppenmitglieder. Für Teams, die gemeinsam an Anfragen arbeiten, ist oft ein Team mit Kanal oder ein Ticketsystem besser geeignet als ein freigegebenes Postfach.

## 5.6 Retention für Mail

Die Grundlagen der Aufbewahrung (Aufbewahrungsrichtlinien, Aufbewahrungsbezeichnungen, Holds) stehen in Modul 6.3; hier geht es um die Besonderheiten bei Mail. Ein Exchange-Postfach besitzt neben dem sichtbaren Inhalt einen versteckten Bereich, den Ordner „Recoverable Items“ (Wiederherstellbare Elemente). Löscht ein Benutzer eine Nachricht aus dem Ordner „Gelöschte Elemente“, landet sie dort und bleibt für einen einstellbaren Zeitraum wiederherstellbar. Wird eine Aufbewahrung oder ein Hold angewandt, behält der Ordner die Nachricht auch nach dem Löschen und ändert sie nicht unbemerkt. Dieser Mechanismus macht Aufbewahrung für Mail überhaupt erst wirksam.

Ein zweiter Begriff ist die *Messaging Records Management* (MRM), die ältere Exchange-eigene Aufbewahrungsfunktion mit Aufbewahrungsrichtlinien und -tags im Postfach. Sie ist von den Purview-Richtlinien zu unterscheiden. Beide können nebeneinander existieren, und im Konfliktfall gewinnt die längere Aufbewahrung beziehungsweise das Löschen wird verhindert, solange eine Purview-Aufbewahrung greift. Für neue Konzepte empfiehlt sich, die Aufbewahrung konsequent in Purview zu regeln und MRM auf das Verschieben ins Archiv zu beschränken.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zur Wiederherstellbarkeit von Postfachelementen beträgt die Standardaufbewahrung gelöschter Elemente 14 Tage, einstellbar bis höchstens 30 Tage; für Details und Ausnahmen ist die aktuelle Dokumentation zu „Recoverable Items“ maßgeblich. Die Aufbewahrung in Purview (Modul 6.3) verlängert die Verweildauer über diese Grenzen hinaus, indem gelöschte Elemente im Ordner gehalten werden. Wie viel Speicher der Ordner einnehmen darf, hängt von Lizenz und Hold ab. Dieser Absatz beruht auf allgemeinem Fachwissen und dem Hinweis der Lizenz- und Grenzwertseiten; die Zahlen sind vor der Verwendung zu prüfen.

Praktisch bedeutet das: Eine Aufbewahrungsrichtlinie für Exchange wirkt auf den gesamten Postfachbereich, kann aber auch auf einzelne Postfächer eingeschränkt werden. Das Archivpostfach (Lerneinheit 5.1) ergänzt sie, indem ältere Mail dorthin verschoben wird. Ausgeschiedene Mitarbeiter sind ein Sonderfall: Wird das Benutzerkonto gelöscht, wird das Postfach nach der Standardfrist endgültig entfernt, es sei denn, ein Hold oder eine Aufbewahrungsrichtlinie hält es als „inaktives Postfach“ weiter vor. Inaktive Postfächer sind der saubere Weg, Mail ausgeschiedener Personen aufzubewahren, ohne eine Lizenz zu vergeben.

Das Skript zeigt die Aufbewahrungseinstellungen zweier Bereiche: den Zeitraum für gelöschte Elemente je Postfach und die Postfächer mit Litigation Hold. Außerdem listet es inaktive Postfächer. Es liest nur und ändert nichts, eignet sich also als Bestandsaufnahme vor dem Konzept.

**Get-MailRetentionOverview.ps1**

```powershell
Connect-ExchangeOnline

"== Aufbewahrung gelöschter Elemente (Abweichung vom Standard) =="
Get-Mailbox -ResultSize Unlimited |
    Where-Object { $_.RetainDeletedItemsFor.Days -ne 14 } |
    Select-Object PrimarySmtpAddress, RetainDeletedItemsFor |
    Format-Table -AutoSize

"== Postfaecher mit Litigation Hold =="
Get-Mailbox -ResultSize Unlimited -Filter "LitigationHoldEnabled -eq `$true" |
    Select-Object PrimarySmtpAddress, LitigationHoldDuration, LitigationHoldDate |
    Format-Table -AutoSize

"== Inaktive Postfaecher =="
Get-Mailbox -InactiveMailboxOnly -ResultSize Unlimited |
    Select-Object DisplayName, PrimarySmtpAddress, WhenSoftDeleted |
    Format-Table -AutoSize
```

Die drei Abfragen entsprechen den drei Fragen eines Aufbewahrungskonzepts: Wo weicht die Frist vom Standard ab, wo besteht ein Hold, und welche Postfächer existieren nur noch zu Aufbewahrungszwecken. Im ersten Block ist 14 Tage der Standardwert; wenn Ihr Tenant einen anderen Standard hat, passen Sie den Vergleichswert an.

### Typische Fehler und Stolperfallen.

Ein klassischer Fehler ist, Aufbewahrung mit Backup zu verwechseln: Aufbewahrung bewahrt Inhalte für Compliance, sie ersetzt keine Sicherung gegen Verlust oder Manipulation (Modul 12.6). Zweitens wird ein Holdzeitraum beim Austritt vergessen, und Postfächer wachsen unbegrenzt. Drittens kollidieren MRM-Tags und Purview-Richtlinien, ohne dass jemand es merkt. Viertens wird die Wiederherstellung durch Benutzer nicht erklärt, und die Servicedesk-Anfragen häufen sich.

**Falsch und richtig: Hold begrenzen**

```powershell
# FALSCH: unbegrenzter Litigation Hold fuer alle, ohne Dokumentation
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -LitigationHoldEnabled $true

# RICHTIG: Hold fuer bestimmte Personen mit Dauer und Grund
Set-Mailbox -Identity anna@contoso.com -LitigationHoldEnabled $true `
    -LitigationHoldDuration 730 -LitigationHoldOwner "Rechtsabteilung" `
    -RetentionComment "Verfahren Az. 2026-17"
```

Der unbegrenzte Hold für alle verbraucht Speicher und erzeugt Aufbewahrungspflichten ohne Rechtsgrundlage. Die korrigierte Fassung nennt Dauer, Eigentümer und Grund. Ob und wie lange Mail aufbewahrt werden muss, ist eine rechtliche Frage (Handels- und Steuerrecht, Datenschutz); dieses Skript ist keine Rechtsberatung.

### Praxisbezug.

Verknüpfen Sie den Ausscheideprozess mit der Aufbewahrung: Das Postfach geht in einen definierten Zustand (inaktiv, umgewandelt, gelöscht), und die Entscheidung wird im Ticket festgehalten. Bei Rechtsstreitigkeiten arbeiten Sie mit der Rechtsabteilung zusammen (Modul 7.6).

## 5.7 External Sender Controls

Unter *External Sender Controls* versteht man alle Maßnahmen, die Mails von außerhalb der Organisation erkennbar machen, einschränken oder prüfen. Das Ziel ist, dass Beschäftigte auf einen Blick erkennen, ob eine Nachricht von außen kommt, und dass Absender, die sich als interne Personen ausgeben, es schwerer haben. Das ist die erste Verteidigungslinie gegen Phishing mit gefälschtem Absendernamen, die in Modul 8.4 mit den technischen Filtern ergänzt wird.

Zu den Maßnahmen gehören mehrere Schichten. Erstens die Kennzeichnung in Outlook: Exchange kann externe Absender mit einem Hinweis markieren. Zweitens Nachrichtenflussregeln (Lerneinheit 5.4), die den Betreff markieren oder bestimmte Konstellationen blockieren. Drittens die Absenderbeschränkungen an Gruppen und Verteilerlisten (Lerneinheiten 5.2 und 5.3), damit externe Personen nicht an interne Verteiler schreiben. Viertens die Authentifizierung der Absenderdomänen mit SPF, DKIM und DMARC, die für die eigene Domäne verhindert, dass Dritte in deren Namen senden. Fünftens die Regeln zum Umgang mit externen Weiterleitungen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt für die Kennzeichnung externer Absender die Einstellung `ExternalInOutlook` im Cmdlet `Set-ExternalInOutlook`. Damit wird bei Mail von externen Absendern in Outlook ein Kennzeichen „Extern“ angezeigt; über eine Liste lassen sich einzelne Absender oder Domänen ausnehmen. Welche Outlook-Clients die Kennzeichnung unterstützen, steht in der aktuellen Dokumentation und ändert sich mit den Clientversionen. Details zu SPF, DKIM und DMARC sowie zu den Schutzfunktionen in Defender für Office 365 gehören in Modul 8.4; die Konfiguration der Domänenauthentifizierung hier ist allgemeines Fachwissen und wurde nicht abgerufen.

Die Kennzeichnung ist bewusst einfach: Sie ersetzt keine Filterung, sondern schärft die Aufmerksamkeit. Ihr Nutzen hängt davon ab, dass Beschäftigte wissen, was das Kennzeichen bedeutet, und dass es nicht zu oft erscheint. Wenn fast jede Mail „Extern“ trägt, weil Partnerorganisationen ständig schreiben, stumpft die Wirkung ab. Deshalb sind Ausnahmen für feste, vertrauenswürdige Partner sinnvoll, sie sollten aber dokumentiert und regelmäßig überprüft werden.

Das folgende Skript zeigt den Zustand der Kennzeichnung, schaltet sie ein und trägt eine Ausnahme ein. Danach prüft es die Authentifizierung der eigenen Domänen, indem es per DNS-Abfrage nachsieht, ob ein SPF- und ein DMARC-Eintrag vorhanden sind. Die DNS-Abfrage nutzt `Resolve-DnsName`, das nur unter Windows verfügbar ist.

**Set-ExternalSenderControls.ps1**

```powershell
Connect-ExchangeOnline

Get-ExternalInOutlook | Format-List Enabled, AllowList

Set-ExternalInOutlook -Enabled $true
Set-ExternalInOutlook -AllowList @{Add = "partner.example.com"}

"== Authentifizierung eigener Domaenen =="
foreach ($d in Get-AcceptedDomain | Where-Object { $_.DomainType -eq "Authoritative" }) {
    $name = $d.DomainName.ToString()
    $spf   = Resolve-DnsName -Name $name -Type TXT -ErrorAction SilentlyContinue |
             Where-Object { $_.Strings -like "v=spf1*" }
    $dmarc = Resolve-DnsName -Name "_dmarc.$name" -Type TXT -ErrorAction SilentlyContinue |
             Where-Object { $_.Strings -like "v=DMARC1*" }
    [pscustomobject]@{ Domain = $name; SPF = [bool]$spf; DMARC = [bool]$dmarc }
}
```

Die ersten Zeilen zeigen den Ist-Zustand, schalten die Kennzeichnung ein und tragen die Partnerdomäne in die Ausnahmeliste ein. Die Schleife geht über alle eigenen Domänen und prüft, ob jeweils ein SPF-Eintrag und ein DMARC-Eintrag im DNS vorhanden sind. Das Skript prüft nur die Existenz, nicht die Qualität der Richtlinie; ein DMARC-Eintrag mit der Richtlinie `p=none` schützt nicht. Die Bewertung der Richtlinie folgt in Modul 8.4.

### Typische Fehler und Stolperfallen.

Der erste Fehler ist, sich auf die Kennzeichnung allein zu verlassen und Training und Filter zu vernachlässigen. Der zweite ist eine zu lange Ausnahmeliste, die den Hinweis wertlos macht. Der dritte ist, SPF so zu pflegen, dass beim Hinzufügen neuer Absenderdienste die Obergrenze an DNS-Abfragen überschritten wird. Der vierte sind Verteilerlisten, die externe Absender annehmen.

**Falsch und richtig: Ausnahmeliste**

```powershell
# FALSCH: ganze Top-Level-Domain-Gruppen pauschal ausnehmen
Set-ExternalInOutlook -AllowList @{Add = "gmail.com","outlook.com"}

# RICHTIG: nur namentlich bekannte Partnerdomaenen, mit Dokumentation im Ticket
Set-ExternalInOutlook -AllowList @{Add = "partner.example.com"}
```

Öffentliche Maildienste auszunehmen hebt das Kennzeichen für genau die Absender auf, von denen die meisten Betrugsversuche ausgehen. Eine Ausnahme gilt nur für Partner, mit denen eine Vereinbarung besteht.

### Praxisbezug.

Beginnen Sie mit der Kennzeichnung und einer Schulung, die erklärt, was „Extern“ bedeutet und was man bei Verdacht tut (melden, nicht klicken). Messen Sie später die Zahl der gemeldeten Verdachtsmails als Kennzahl der Aufmerksamkeit (Modul 9.8). Die Ausnahmen gehören in den Prozess aus Modul 8.7.

## 5.8 Exchange-Troubleshooting

Wenn Mail nicht ankommt oder nicht rausgeht, ist die Frage meist dieselbe: Wo ist die Nachricht geblieben? Das Troubleshooting folgt einem festen Vorgehen. Zuerst klärt man den Fall genau: Wer hat wann an wen gesendet, mit welcher Fehlermeldung? Dann verfolgt man den Weg der Nachricht mit der Nachrichtenablaufverfolgung (Message Trace), die für jede Nachricht zeigt, ob sie zugestellt, verzögert, abgelehnt, in Quarantäne gelegt oder von einer Regel verändert wurde. Aus dem Ergebnis ergibt sich die Ursache.

Die Fehlermeldungen von Mailsystemen folgen einem Muster. Ein *Non-Delivery Report* (NDR, Unzustellbarkeitsbericht) enthält einen Statuscode in der Form „5.x.x“ für dauerhafte und „4.x.x“ für vorübergehende Fehler. Die Ziffernfolge sagt, was schiefging: Empfänger unbekannt, Postfach voll, Nachricht zu groß, Absender nicht berechtigt, Richtlinie blockiert. Wer den Code lesen kann, spart sich oft die Suche, weil die Ursache schon im NDR steht. Typische Ursachen sind außerdem Verzögerungen nach Änderungen: Geänderte Berechtigungen und Nachrichtenflussregeln wirken nicht sofort (Lerneinheit 5.4), neue Postfächer erscheinen verspätet im Adressbuch.

Eine zweite Gruppe sind Probleme auf Clientseite: Outlook erkennt eine Berechtigung nicht, das Profil ist beschädigt, die Synchronisation hängt. Hier hilft die Frage, ob dasselbe Postfach im Browser (Outlook im Web) funktioniert. Funktioniert es dort, liegt der Fehler im Client, funktioniert es nicht, im Dienst oder in der Konfiguration. Diese einfache Trennung verkürzt viele Untersuchungen. Dritte Gruppe: Dienststörungen, die man in der Dienstintegrität sieht (Modul 9.6).

> **Ergänzung aus der Nachrecherche**
>
> In der Microsoft-Dokumentation zum Nachrichtenfluss wird die Nachrichtenablaufverfolgung als zentrales Werkzeug beschrieben. Die einfache Verfolgung deckt in der Regel einen zurückliegenden Zeitraum von wenigen Tagen ab, die erweiterte Verfolgung (historische Suche) einen längeren Zeitraum und liefert dafür als Bericht zeitversetzt. Die genauen Zeiträume und Grenzen der Cmdlets wechseln mit Dienstversionen; prüfen Sie sie in der aktuellen Dokumentation. Dieser Absatz stützt sich auf allgemeines Fachwissen, nicht auf eine abgerufene Seite.

Das Skript fragt die Ablaufverfolgung für einen Absender oder Empfänger der letzten zwei Tage ab und zeigt Status und Betreff. Anschließend führt es für abweichende Zustände eine Detailabfrage aus, die die einzelnen Ereignisse der Nachricht liefert. So sieht man etwa, ob eine Regel zugriff oder ob der Empfangsserver die Annahme verweigerte.

**Trace-MailProblem.ps1**

```powershell
param(
    [string]$Absender,
    [string]$Empfaenger,
    [int]$Tage = 2
)
if (-not $Absender -and -not $Empfaenger) { throw "Absender oder Empfaenger angeben." }

Connect-ExchangeOnline

$param = @{ StartDate = (Get-Date).AddDays(-$Tage); EndDate = Get-Date }
if ($Absender)   { $param.SenderAddress    = $Absender }
if ($Empfaenger) { $param.RecipientAddress = $Empfaenger }

$ergebnis = Get-MessageTrace @param
if (-not $ergebnis) { Write-Host "Keine Nachrichten im Zeitraum gefunden."; return }

$ergebnis | Sort-Object Received -Descending |
    Select-Object Received, SenderAddress, RecipientAddress, Subject, Status |
    Format-Table -AutoSize -Wrap

foreach ($m in $ergebnis | Where-Object Status -notin "Delivered") {
    "--- Details: $($m.Subject) ($($m.Status))"
    Get-MessageTraceDetail -MessageTraceId $m.MessageTraceId -RecipientAddress $m.RecipientAddress |
        Select-Object Date, Event, Detail | Format-Table -AutoSize -Wrap
}
```

Das Skript baut die Parameter dynamisch, damit nur die angegebenen Filter verwendet werden. Mit `Get-MessageTrace` holt es die Nachrichten, sortiert sie und zeigt Status und Betreff. Für alle Nachrichten, die nicht den Status „Delivered“ haben, ruft es `Get-MessageTraceDetail` auf. Die Ereignisse im Detail erklären, ob etwa eine Transportregel, eine Spamfilterung oder eine Zustellverzögerung schuld ist. Die genaue Form dieser Cmdlets kann sich ändern (Microsoft hat die Verfolgung in den vergangenen Jahren weiterentwickelt); prüfen Sie die aktuelle Syntax in der Dokumentation.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, ohne Verfolgung zu raten und dann Einstellungen zu ändern, was den Fall verschleiert. Zweitens wird der Zeitraum zu kurz oder zu lang gewählt. Drittens wird die Meldung des Benutzers („Mail kam nicht an“) nicht präzisiert; manche Mail liegt im Junk-Ordner oder ist in der Quarantäne. Viertens wird die Fehlerursache nicht dokumentiert und ein späterer, gleicher Fall beginnt wieder bei null.

**Falsch und richtig: Vorgehen**

```powershell
# FALSCH: Regel einfach loeschen, weil "vielleicht die Regel schuld ist"
Remove-TransportRule -Identity "Vertrauliche Betreffs nicht nach extern" -Confirm:$false

# RICHTIG: erst nachweisen, welches Ereignis die Nachricht beeinflusst hat
$m = Get-MessageTrace -SenderAddress anna@contoso.com -StartDate (Get-Date).AddDays(-1) -EndDate (Get-Date)
$m | ForEach-Object {
    Get-MessageTraceDetail -MessageTraceId $_.MessageTraceId -RecipientAddress $_.RecipientAddress
} | Select-Object Event, Detail
```

Die richtige Vorgehensweise sammelt Belege, bevor etwas verändert wird. Erst wenn die Verfolgung die Regel als Ursache zeigt, wird sie angepasst, und die Änderung wird im Ticket festgehalten.

### Praxisbezug.

Legen Sie für häufige Fälle einen Entscheidungsbaum an (Mail kommt nicht an, Mail geht nicht raus, Berechtigung fehlt, Outlook hängt) und machen Sie daraus Runbooks (Modul 9.7). So können auch Mitarbeiter der ersten Ebene den Fall eingrenzen, bevor sie ihn an die Experten übergeben.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Erklären Sie in eigenen Worten den Unterschied zwischen einer Verteilerliste, einer Microsoft-365-Gruppe und einem freigegebenen Postfach. Nennen Sie je ein Beispiel für den passenden Einsatz.

**Aufgabe 2 (leicht).** Welche drei Berechtigungen kennt ein freigegebenes Postfach, und worin unterscheiden sich „Senden als“ und „Senden im Auftrag“? Warum sollte man Rechte an Gruppen statt an Personen vergeben?

**Aufgabe 3 (leicht).** Nennen Sie vier Risiken, die ein unverwaltetes Exchange-System erzeugt, und ordnen Sie jedem eine Lerneinheit dieses Moduls zu, in der es behandelt wird.

**Aufgabe 4 (mittel).** Eine Nachrichtenflussregel mit Priorität 5 hängt einen Haftungsausschluss an, eine zweite mit Priorität 2 blockiert Nachrichten mit dem Wort „VERTRAULICH“. In welcher Reihenfolge werden sie abgearbeitet, und was folgt daraus für eine Nachricht, die beides enthält? Wie ändern Sie das Verhalten, wenn der Ausschluss trotzdem angehängt werden soll?

**Aufgabe 5 (mittel).** Schreiben Sie ein Skript, das alle Postfächer mit einer Weiterleitung an eine SMTP-Adresse außerhalb der eigenen Domänen ausgibt. Erklären Sie, warum die Eigenschaft am Postfach nicht alle Weiterleitungen erfasst.

**Aufgabe 6 (mittel).** Entwerfen Sie ein Namenskonzept für Microsoft-365-Gruppen mit Präfix, Platzhaltern und gesperrten Wörtern. Welche Grenzen der Namensrichtlinie müssen Sie bei der Planung beachten?

**Aufgabe 7 (schwer).** Schreiben Sie ein Skript, das für alle freigegebenen Postfächer die Berechtigten ermittelt, einzelne Personen von Gruppen unterscheidet und eine Liste der Postfächer ausgibt, bei denen Rechte direkt an Personen vergeben sind.

**Aufgabe 8 (schwer).** Ein Benutzer meldet: „Mails von einem Kunden kommen seit gestern nicht mehr an.“ Beschreiben Sie in mindestens sechs Schritten Ihr Vorgehen vom ersten Gespräch bis zur dokumentierten Lösung. Nennen Sie die Werkzeuge, die Sie einsetzen, und mögliche Ursachen.

## Lösungen

**Lösung 1.** Eine Verteilerliste ist eine reine Adresse für mehrere Empfänger, etwa „alle-vertrieb“. Eine Microsoft-365-Gruppe ist ein Arbeitsbereich mit Postfach, Kalender, Dateispeicher und optional einem Team, etwa für ein Projekt. Ein freigegebenes Postfach ist ein Postfach ohne eigene Person für eine Funktion, etwa „info@“. Die Wahl richtet sich nach dem Zweck: nur Adresse, Zusammenarbeit oder gemeinsame Bearbeitung eingehender Anfragen.

**Lösung 2.** Die drei Berechtigungen sind Vollzugriff, Senden als und Senden im Auftrag. Bei „Senden als“ erscheint nur die Postfachadresse, bei „Senden im Auftrag“ wird die sendende Person mit genannt. Rechte an Gruppen erleichtern Wechsel, Überprüfung und Nachvollziehbarkeit, weil nur die Gruppenmitgliedschaft geändert wird.

**Lösung 3.** Mögliche Risiken: Weiterleitungen nach außen (5.1), Verteilerlisten mit offenen Absendern (5.2), Gruppen ohne Besitzer oder Ablauf (5.3), Regeln ohne Dokumentation (5.4), überfüllte oder unverwaltete freigegebene Postfächer (5.5), fehlende Aufbewahrung bei Austritt (5.6), nicht erkennbare externe Absender (5.7), nicht nachvollziehbare Zustellprobleme (5.8).

**Lösung 4.** Die Regel mit Priorität 2 wird zuerst abgearbeitet, denn niedrigere Zahlen haben Vorrang. Enthält die Nachricht das Wort, wird sie blockiert, und die zweite Regel sieht sie nicht mehr. Soll der Ausschluss trotzdem angehängt werden, tauscht man die Prioritäten, achtet darauf, dass die Blockregel nicht den Ausschluss braucht, oder baut den Ausschluss als Teil der Blockmeldung ein. Die Änderung wirkt erst nach einer Wartezeit von bis zu 30 Minuten (Ergänzung in 5.4).

**Lösung 5.** Ein Lösungsvorschlag:

```powershell
Connect-ExchangeOnline
$eigene = (Get-AcceptedDomain).DomainName | ForEach-Object { $_.ToString().ToLower() }
Get-Mailbox -ResultSize Unlimited | Where-Object { $_.ForwardingSmtpAddress } | ForEach-Object {
    $ziel = ($_.ForwardingSmtpAddress.ToString() -replace '^smtp:','').ToLower()
    $domain = $ziel.Split('@')[-1]
    if ($domain -notin $eigene) {
        [pscustomobject]@{ Postfach = $_.PrimarySmtpAddress; Ziel = $ziel }
    }
}
```

Das Skript sammelt die eigenen Domänen, filtert Postfächer mit Weiterleitung, entfernt das Präfix „smtp:“ und vergleicht die Zieldomäne. Die Eigenschaft erfasst nur vom Administrator gesetzte Weiterleitungen; Posteingangsregeln des Benutzers, die an externe Adressen weiterleiten, stehen in den Regeln des Postfachs und werden mit `Get-InboxRule` abgefragt.

**Lösung 6.** Ein Beispiel: Präfix „GRP“, Platzhalter für den Gruppennamen und die Abteilung, also „GRP\_\[GroupName\]\_\[Department\]“. Gesperrte Wörter: „CEO“, „Payroll“, „Gehalt“. Zu beachten sind die Gesamtlänge von 63 Zeichen, die exakte Wortübereinstimmung bei gesperrten Wörtern, die Ausnahme bestimmter Administratorrollen, die Lizenzanforderung und die Qualität der Attribute, die als Platzhalter dienen.

**Lösung 7.** Ein Lösungsvorschlag:

```powershell
Connect-ExchangeOnline
Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited | ForEach-Object {
    $pm = $_
    $personen = Get-MailboxPermission -Identity $pm.PrimarySmtpAddress |
        Where-Object { $_.User -notlike "NT AUTHORITY*" -and -not $_.IsInherited -and -not $_.Deny } |
        ForEach-Object {
            $r = Get-Recipient -Identity $_.User -ErrorAction SilentlyContinue
            if ($r -and $r.RecipientTypeDetails -in "UserMailbox","MailUser") { $_.User }
        }
    if ($personen) { [pscustomobject]@{ Postfach = $pm.PrimarySmtpAddress; DirektBerechtigt = ($personen -join "; ") } }
}
```

Das Skript ermittelt die Berechtigungen jedes freigegebenen Postfachs, schließt Systemkonten und geerbte Rechte aus und prüft über den Empfängertyp, ob ein Benutzer oder eine Gruppe berechtigt ist. Direkt berechtigte Personen werden aufgelistet und können in Gruppenrechte überführt werden.

**Lösung 8.** Ein möglicher Ablauf: (1) Fall präzisieren: Absender, Empfänger, Zeitpunkt, Fehlermeldung, ob einzelne oder alle Mails betroffen sind. (2) Junk-Ordner, Quarantäne und Regeln des Benutzers prüfen. (3) Nachrichtenablaufverfolgung nach Absenderadresse und Zeitraum durchführen. (4) Je nach Status die Details abfragen: wurde die Nachricht abgelehnt, von einer Transportregel verändert, gefiltert oder gar nicht empfangen? (5) Ursache beheben, zum Beispiel Ausnahme für einen Absender in der Filterung, Anpassung einer Regel oder Korrektur der Absenderdomäne beim Kunden (SPF, DMARC). (6) Lösung mit dem Benutzer testen, Fall im Ticket dokumentieren und, falls häufig, ein Runbook ergänzen. Mögliche Ursachen: Absenderdomäne neu auf einer Sperrliste, Kunde hat DMARC-Richtlinie verschärft, Regel blockiert wegen Schlüsselwort, Postfach des Empfängers voll, Dienststörung.
