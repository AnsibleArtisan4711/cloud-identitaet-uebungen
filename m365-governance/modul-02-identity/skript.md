# Modul 02 - Identity Governance und Zugriffskontrolle

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 9 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich allerdings nur auf 8 Stunden. Als Richtwert für den Umfang dieses Skripts wurde der höhere Wert (9 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**           | **Dauer (h)** | **Prio** |
|:--------|:--------------------------|--------------:|---------:|
| 2.1     | Entra ID Governance       |             1 |        1 |
| 2.2     | Lifecycle Workflows       |             1 |        1 |
| 2.3     | Access Packages           |             1 |        1 |
| 2.4     | Access Reviews            |             1 |        1 |
| 2.5     | PIM und Adminrollen       |             1 |        1 |
| 2.6     | Gruppen-Governance        |             1 |        2 |
| 2.7     | Guest Access              |             1 |        2 |
| 2.8     | Identity-Troubleshooting  |             1 |        2 |
|         | **Summe laut Details**    |         **8** |          |
|         | **Dauer laut Modulblatt** |         **9** |          |

> **Merke: Lizenzen entscheiden**
>
> Fast alle Funktionen dieses Moduls setzen Lizenzen voraus. Zugriffspakete (Entitlement Management), Zugriffsüberprüfungen und Lifecycle Workflows verlangen laut Microsoft Microsoft Entra ID Governance oder Microsoft Entra Suite, einzelne Funktionen laufen auch mit Microsoft Entra ID P2. Privileged Identity Management benötigt ebenfalls entsprechende Lizenzen. Prüfen Sie vor jedem Konzept die Lizenzlage (Modul 01, Lerneinheit „M365 Workload Landscape“).

## 2.1 Entra ID Governance

Microsoft Entra ID Governance ist der Teil der Microsoft-Plattform, der sich mit dem *Lebenszyklus von Identitäten und Zugriffen* beschäftigt. Während die Anmeldung und der bedingte Zugriff die Frage beantworten, ob sich jemand jetzt anmelden darf, beantwortet Identity Governance die Frage, ob jemand überhaupt Zugriff haben sollte, wie lange und auf wessen Entscheidung hin. Die Microsoft-Dokumentation fasst das in vier Fragen zusammen: Welche Identitäten sollen Zugriff auf welche Ressourcen haben? Was tun diese Identitäten mit ihrem Zugriff? Gibt es organisatorische Kontrollen für die Verwaltung des Zugriffs? Und können Prüfer nachweisen, dass die Kontrollen wirksam sind?

Zur Beantwortung bietet Entra ID Governance drei Lebenszyklen mit jeweils eigenen Werkzeugen an. Der *Identitätslebenszyklus* kümmert sich um Eintritt, Wechsel und Austritt von Personen und nutzt dafür die Anbindung an Personalsysteme und die Lifecycle Workflows (Lerneinheit 2.2). Der *Zugriffslebenszyklus* regelt, wie Personen Zugriff auf Gruppen, Anwendungen und SharePoint-Websites erhalten und wieder verlieren. Dafür gibt es Zugriffspakete im Entitlement Management (Lerneinheit 2.3) und wiederkehrende Zugriffsüberprüfungen (2.4). Der *Lebenszyklus privilegierter Zugriffe* beschäftigt sich mit Administratorrechten und stützt sich auf Privileged Identity Management (2.5). Die folgenden Lerneinheiten dieses Moduls entfalten jeden dieser drei Lebenszyklen, ergänzt um die Gruppen-Governance (2.6), den Umgang mit Gästen (2.7) und die Fehlersuche (2.8).

| **Lebenszyklus**       | **Frage**                                           | **Werkzeuge**                                                 |
|:-----------------------|:----------------------------------------------------|:--------------------------------------------------------------|
| Identität              | Wer gehört zur Organisation, ab wann, bis wann?     | HR-Anbindung, Lifecycle Workflows                             |
| Zugriff                | Worauf darf eine Identität zugreifen und wie lange? | Zugriffspakete, automatische Zuweisung, Zugriffsüberprüfungen |
| Privilegierter Zugriff | Wer darf administrieren, und nur bei Bedarf?        | Privileged Identity Management, Überprüfungen von Rollen      |

Die drei Lebenszyklen der Entra ID Governance

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation „What is Microsoft Entra ID Governance?“ lassen sich die Funktionen für Mitarbeitende, Geschäftspartner und Lieferanten einsetzen. Die Dokumentation nennt für die Automatisierung unter anderem: Inbound-Provisionierung aus HR-Quellen wie Workday und SuccessFactors, Lifecycle Workflows, automatische Zuweisungsrichtlinien im Entitlement Management und Benutzerbereitstellung per SCIM, LDAP und SQL in Anwendungen. Neu in der Dokumentation (Vorschau) ist die Governance für Agentenidentitäten: Jede Agentenidentität braucht einen menschlichen Sponsor, und Agenten werden über dieselben Zugriffspakete verwaltet wie Personen. Zusätzlich nennt die Dokumentation das Modul `Microsoft.Graph.Identity.Governance` für die Automatisierung mit PowerShell.

Warum teilt man Identity Governance in diese Bereiche auf, statt alle Zugriffe einfach über Gruppen zu steuern? Der Grund ist die *Zeitdimension*. Eine Gruppenmitgliedschaft ist ein Zustand ohne Ablaufdatum und ohne Begründung. Sie wird irgendwann gesetzt und irgendwann vergessen. Entra ID Governance fügt jedem Zugriff drei Fragen hinzu, die eine einfache Gruppe nicht beantwortet: Wer hat den Zugriff genehmigt und warum? Bis wann gilt er? Wer prüft regelmäßig, ob er noch gebraucht wird? Genau diese drei Fragen sind es, die Auditoren stellen.

Das Beispielskript verschafft einen Überblick, welche Governance-Funktionen in einem Tenant bereits genutzt werden. Es zählt Kataloge, Zugriffspakete, Zugriffsüberprüfungen und Lifecycle Workflows. Es ist so gebaut, dass es auch in Tenants ohne die nötige Lizenz nicht abbricht, sondern den jeweiligen Fehler als Information ausgibt. Das ist wichtig, weil nicht jede Funktion in jedem Tenant verfügbar ist.

**Get-GovernanceInventory.ps1**

```powershell
Connect-MgGraph -Scopes "EntitlementManagement.Read.All","AccessReview.Read.All","LifecycleWorkflows.Read.All" -NoWelcome

function Get-CountSafe($Name, [scriptblock]$Query) {
    try {
        $n = @(& $Query).Count
        [pscustomobject]@{ Funktion = $Name; Anzahl = $n; Hinweis = "" }
    } catch {
        [pscustomobject]@{ Funktion = $Name; Anzahl = $null; Hinweis = $_.Exception.Message.Split("`n")[0] }
    }
}

@(
  Get-CountSafe "Kataloge"                { Get-MgEntitlementManagementCatalog -All }
  Get-CountSafe "Zugriffspakete"          { Get-MgEntitlementManagementAccessPackage -All }
  Get-CountSafe "Zugriffsueberpruefungen" { Get-MgIdentityGovernanceAccessReviewDefinition -All }
  Get-CountSafe "Lifecycle Workflows"     { Get-MgIdentityGovernanceLifecycleWorkflow -All }
) | Format-Table -AutoSize
```

Die Funktion `Get-CountSafe` bekommt einen Namen und einen Codeblock. Der Block wird mit dem Aufrufoperator `&` ausgeführt, und das Ergebnis wird in eine Liste verpackt und gezählt. Tritt ein Fehler auf, zum Beispiel weil der Tenant nicht lizenziert ist, fängt der `catch`-Block ihn ab und schreibt die erste Zeile der Fehlermeldung in die Spalte „Hinweis“. Das Hauptprogramm ruft die Funktion viermal auf und gibt die Ergebnisse als Tabelle aus. Die Anmeldung fordert drei lesende Berechtigungen an, jeweils für einen Funktionsbereich. Wer das Skript zum ersten Mal ausführt, muss diese Berechtigungen im Browser bestätigen. Dazu ist in vielen Tenants die Zustimmung eines Administrators nötig.

### Typische Fehler und Stolperfallen.

Ein verbreiteter Fehler ist, Entra ID Governance als reines Technikprojekt zu starten. Die Werkzeuge sind schnell konfiguriert, aber ohne klare Entscheidungen (Wer genehmigt? Wie lange gilt Zugriff?) entstehen leere oder falsch eingestellte Zugriffspakete. Der zweite Fehler ist, alles auf einmal einzuführen.

```
FALSCH:  Im Projekt werden Lifecycle Workflows, 40 Zugriffspakete und
          Zugriffsueberpruefungen fuer alle Gruppen gleichzeitig aktiviert.

RICHTIG: Welle 1: Gaeste (Zugriffsueberpruefung + Befristung)
          Welle 2: Administratoren (PIM + Ueberpruefung der Rollen)
          Welle 3: Zugriffspakete fuer 2 bis 3 Pilotprojekte
          Welle 4: Lifecycle Workflows fuer Eintritt und Austritt
```

### Praxisbezug.

In Projekten beginnt man in der Regel mit der Frage, wo das größte Risiko liegt. Das sind fast immer Gäste und Administratoren, weil sie am häufigsten vergessen werden. Das Governance-Dashboard im Microsoft Entra Admin Center, das die Dokumentation als Einstieg nennt, hilft dabei, Zugriffspakete, Überprüfungen, Lifecycle Workflows und PIM an einer Stelle zu finden. Eine Faustregel aus der Praxis: Eine Funktion, für die es keinen benannten Verantwortlichen gibt, wird nicht dauerhaft betrieben.

> **Merke**
>
> Entra ID Governance steuert Identitäten, Zugriffe und privilegierte Rechte über ihre gesamte Lebenszeit. Der Mehrwert gegenüber einfachen Gruppen: Begründung, Ablaufdatum und regelmäßige Überprüfung.

## 2.2 Lifecycle Workflows

Wenn ein Mitarbeiter eintritt, braucht er am ersten Tag ein Konto, die richtigen Gruppen, vielleicht ein Willkommensschreiben und einen temporären Zugangscode. Wenn er die Firma verlässt, müssen sein Konto deaktiviert, seine Zugriffe entzogen und eventuell sein Postfach weitergeleitet werden. Wenn er die Abteilung wechselt, ändern sich seine Berechtigungen. Diese drei Phasen heißen in der Fachsprache *Joiner, Mover, Leaver* (Eintritt, Wechsel, Austritt). In vielen Unternehmen werden sie mit Tickets und E-Mails zwischen Personalabteilung und IT abgewickelt, was zu Verzögerungen und Fehlern führt. Typisches Ergebnis: ein Konto, das noch Monate nach dem Austritt aktiv ist.

Lifecycle Workflows (LCW) sind die Antwort der Microsoft-Plattform auf dieses Problem. Ein *Workflow* besteht aus *Aufgaben* (Tasks) und *Ausführungsbedingungen*. Die Aufgaben sind die konkreten Schritte, zum Beispiel „Konto aktivieren“, „Willkommens-E-Mail senden“, „temporären Zugangspass erzeugen“ oder „Benutzer aus Gruppen entfernen“. Die Ausführungsbedingung legt fest, für wen (Bereich oder Scope) und wann (Auslöser oder Trigger) der Workflow läuft. Das Beispiel aus der Microsoft-Dokumentation: Eine E-Mail an den Vorgesetzten soll sieben Tage vor dem Wert des Attributs `employeeHireDate` neuer Mitarbeiter gesendet werden. Aufgabe: E-Mail senden. Bereich: neue Mitarbeiter. Auslöser: sieben Tage vor dem Eintrittsdatum.

Wichtig für das Verständnis: Der Auslöser basiert auf *Attributen des Benutzerobjekts*. Deshalb steht und fällt die Qualität der Lifecycle Workflows mit der Qualität der Benutzerdaten. Ist das Eintrittsdatum nicht gepflegt, läuft der Workflow nicht, auch wenn er korrekt konfiguriert ist. Der Bereich kann über viele Benutzer- und Erweiterungsattribute eingegrenzt werden, zum Beispiel nach Abteilung. Wo kommen die Attribute her? Typischerweise aus einem Personalsystem über die HR-gesteuerte Bereitstellung (Workday, SAP SuccessFactors), alternativ aus Active Directory oder aus manueller Pflege. In kleineren Organisationen ohne HR-Integration lassen sich die Daten auch per Skript oder Import pflegen.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Lifecycle Workflows nennt als typische Einsatzbereiche: Onboarding und Offboarding mit automatisierten Aufgaben, Verwaltung statischer Gruppen ohne dynamische Regeln (ein Workflow-Bereich legt fest, auf welche Benutzer er wirkt, nicht auf welche Gruppe), Audit und Verlauf der Abläufe im Admin Center, Deaktivierung und Löschung von Konten, automatische Zuweisung und Entfernung von Zugriffspaketen sowie die Integration von Logic Apps für komplexe Szenarien. Pro Tenant sind laut Dokumentation bis zu 100 Workflows und bis zu 100 benutzerdefinierte Aufgabenerweiterungen möglich. Verwendet werden können Workflows nur mit einer Lizenz für Microsoft Entra ID Governance oder Microsoft Entra Suite.

Lifecycle Workflows sind auch ein Werkzeug für *Nachweisbarkeit*. Jeder Lauf wird protokolliert: Für welche Benutzer wurde welche Aufgabe mit welchem Ergebnis ausgeführt? Damit lässt sich einem Auditor zeigen, dass der Austrittsprozess tatsächlich ausgeführt wurde, und nicht nur dokumentiert ist. Das Skript unten zeigt zwei typische Verwaltungsaufgaben: das Anlegen eines Eintritts-Workflows mit einem Bereichsfilter für eine Abteilung, und das Abfragen der bisherigen Läufe. Die Struktur des Workflows folgt dem veröffentlichten Beispiel der Dokumentation. Die beiden Aufgaben-IDs sind die der eingebauten Aufgaben „Konto aktivieren“ und „Willkommens-E-Mail senden“.

**New-JoinerWorkflow.ps1**

```powershell
Connect-MgGraph -Scopes "LifecycleWorkflows.ReadWrite.All" -NoWelcome

$params = @{
    category            = "joiner"
    displayName         = "Eintritt Marketing - Willkommen"
    description         = "Konto aktivieren und Willkommensnachricht senden"
    isEnabled           = $true
    isSchedulingEnabled = $false      # zuerst nur manuell/on demand testen
    executionConditions = @{
        "@odata.type" = "#microsoft.graph.identityGovernance.triggerAndScopeBasedConditions"
        scope = @{
            "@odata.type" = "#microsoft.graph.identityGovernance.ruleBasedSubjectSet"
            rule          = "(department eq 'Marketing')"
        }
        trigger = @{
            "@odata.type"      = "#microsoft.graph.identityGovernance.timeBasedAttributeTrigger"
            timeBasedAttribute = "employeeHireDate"
            offsetInDays       = -1       # einen Tag vor dem Eintrittsdatum
        }
    }
    tasks = @(
        @{ continueOnError = $false; isEnabled = $true
           displayName = "Konto aktivieren"
           taskDefinitionId = "6fc52c9d-398b-4305-9763-15f42c1676fc"; arguments = @() }
        @{ continueOnError = $false; isEnabled = $true
           displayName = "Willkommens-E-Mail senden"
           taskDefinitionId = "70b29d51-b59a-4773-9280-8841dfd3f2ea"; arguments = @() }
    )
}

$wf = New-MgIdentityGovernanceLifecycleWorkflow -BodyParameter $params
"Workflow angelegt: $($wf.Id)"

# Bisherige Laeufe auflisten
Get-MgIdentityGovernanceLifecycleWorkflowRun -WorkflowId $wf.Id | Format-Table Id, ProcessingStatus, StartedDateTime
```

Die Beschreibungsfelder am Anfang sind frei wählbar. Die Eigenschaft `isSchedulingEnabled` steuert, ob der Workflow nach einem Zeitplan automatisch läuft. Hier ist sie bewusst ausgeschaltet, damit der Workflow zunächst nur manuell getestet wird. Das ist eine gute Praxis: Neue Workflows laufen zuerst auf einem oder zwei Testbenutzern. Die Ausführungsbedingung besteht aus dem `scope` (hier: alle Benutzer mit der Abteilung „Marketing“) und dem `trigger` (hier: ein Tag vor dem Wert im Attribut `employeeHireDate`). Das Vorzeichen des Versatzes legt die Richtung fest: Negative Werte bedeuten „vor“ dem Datum, positive „nach“ dem Datum, was bei Austritts-Workflows nützlich ist. Danach folgen zwei Aufgaben. Mit `continueOnError = $false` bricht der Workflow ab, wenn die erste Aufgabe fehlschlägt, statt unvollständig weiterzulaufen. Der Aufruf von `New-MgIdentityGovernanceLifecycleWorkflow` legt den Workflow an. Die letzte Zeile listet die bisherigen Läufe.

Für Tests lässt sich ein Workflow auch *bei Bedarf* für ausgewählte Benutzer starten. Das Beispiel dafür stammt aus der Microsoft-Dokumentation: Mit dem Cmdlet `Initialize-MgIdentityGovernanceLifecycleWorkflow` und den Parametern `WorkflowId` und `BodyParameter` wird der Workflow für eine Liste von Benutzer-IDs gestartet, die im Parameter `subjects` übergeben werden.

### Typische Fehler und Stolperfallen.

Der häufigste Grund für „Der Workflow läuft nicht“ ist ein leeres Attribut. Auch Zeitzonen und Datumsformate verursachen Probleme: Ein Eintrittsdatum, das in einer anderen Zeitzone gepflegt wird, kann den Ablauf um einen Tag verschieben. Ein dritter Fehler ist der Austritts-Workflow ohne Rückfalloption.

```
FALSCH:  Leaver-Workflow loescht das Konto sofort am letzten Arbeitstag.
          -> Postfach, OneDrive-Dateien und Zugriffe der Person sind
             sofort weg, offene Aufgaben und Aufbewahrung ungeklaert.

RICHTIG: Tag 0:   Konto deaktivieren, Sitzungen widerrufen, Zugriffe entziehen
          Tag 30:  Pruefung durch den Vorgesetzten (Datenuebernahme)
          Tag 90:  Konto loeschen (Papierkorb: weitere 30 Tage Wiederherstellung)
```

### Praxisbezug.

Lifecycle Workflows zahlen sich besonders in Organisationen mit häufigem Wechsel aus (Saisonkräfte, Projektpersonal, Schulen). In kleinen Organisationen kann es sinnvoller sein, zunächst nur den Austrittsprozess zu automatisieren, weil dort das Sicherheitsrisiko liegt. Klären Sie vor jedem Workflow: Welches System ist die Quelle der Wahrheit für das Eintrittsdatum und wer ist für die Datenqualität verantwortlich?

> **Merke**
>
> Ein Lifecycle Workflow besteht aus Aufgaben und einer Ausführungsbedingung (Bereich plus zeitbasierter Auslöser auf einem Benutzerattribut). Seine Qualität hängt von der Qualität der Benutzerdaten ab. Neue Workflows werden zuerst an Testbenutzern und on demand geprüft.

## 2.3 Access Packages

Gruppen und Rollen sind ein grobes Mittel, um Zugriff zu steuern. In der Realität braucht jemand für ein Projekt eine Gruppenmitgliedschaft, den Zugriff auf eine Anwendung und eine SharePoint-Website. Jedes dieser Elemente wird getrennt beantragt, getrennt genehmigt und vergessen. Das *Entitlement Management* löst dieses Problem mit dem Konzept des *Zugriffspakets* (Access Package): Ein Zugriffspaket bündelt alle Ressourcen, die jemand für ein Projekt oder eine Aufgabe braucht, und verknüpft sie mit Regeln, die festlegen, wer es anfordern darf, wer es genehmigt und wie lange es gilt.

Die Bausteine lassen sich leicht merken, wenn man sie von oben nach unten betrachtet. Ein *Katalog* ist ein Container, der verwandte Ressourcen und Zugriffspakete enthält. Er ist der Ort der Delegation: Katalogbesitzer dürfen Pakete anlegen. Ein *Zugriffspaket* enthält Ressourcen mit ihren Rollen. Ressourcen können Mitgliedschaften in Sicherheitsgruppen, Mitgliedschaften in Microsoft-365-Gruppen und Teams, Zuweisungen zu Unternehmensanwendungen, Mitgliedschaften in SharePoint-Websites und weitere sein. Eine *Richtlinie* (Policy) legt die Spielregeln fest: Wer darf anfordern (interne Benutzer, bestimmte Gäste, Benutzer aus verbundenen Organisationen), wer genehmigt (Vorgesetzter, Besitzer, mehrstufig), wie lange gilt der Zugriff und ob er verlängert werden darf. Eine *Zuweisung* (Assignment) ist das Ergebnis: Eine Identität besitzt das Paket, in der Regel befristet.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „What is entitlement management?“ beschreibt, dass sich Zugriffspakete über mehrere Richtlinien steuern lassen, zum Beispiel eine für interne Benutzer und eine zweite für externe Verzeichnisse. Neben Anforderungsrichtlinien gibt es Richtlinien für die automatische Zuweisung auf Basis von Attributen sowie Zuweisungen durch Administratoren oder über Lifecycle Workflows. Verbundene Organisationen (Connected Organizations) sind externe Microsoft-Entra-Verzeichnisse oder Domänen, deren Identitäten Zugriff anfordern dürfen. Wird eine externe Identität genehmigt, wird sie automatisch als B2B-Gast eingeladen. Läuft der Zugriff ab und existieren keine weiteren Zuweisungen, kann das Gastkonto automatisch entfernt werden. Für die Funktion ist eine Lizenz für Microsoft Entra ID Governance oder Microsoft Entra Suite erforderlich.

Der besondere Wert von Zugriffspaketen liegt in der *Delegation*. Wie die Dokumentation beschreibt, können Administratoren nicht administrative Personen, zum Beispiel Projektleiter, zu Katalogbesitzern oder Zugriffspaketmanagern machen. Diese definieren im Rahmen ihres Katalogs die Pakete und Regeln selbst, ohne dass die IT jeden Einzelfall bearbeiten muss. Ein nicht administrativer Katalogbesitzer kann nur Ressourcen hinzufügen, die er selbst besitzt. Dadurch bleibt die Verantwortung bei den Fachbereichen, die Leitplanken bleiben aber zentral. Die Dokumentation empfiehlt Zugriffspakete übrigens nicht für alles: Sie ersetzen keine anderen Zuweisungsmechanismen, sondern ergänzen sie für zeitlich begrenzten Zugriff, genehmigungspflichtigen Zugriff, abteilungsübergreifenden Zugriff und die Zusammenarbeit mit externen Organisationen. Basisrechte, die jeder Mitarbeitende braucht, bleiben besser bei dynamischen Gruppen und gruppenbasierter Lizenzierung.

Das folgende Skript bildet die Praxis ab: Es legt für ein bestehendes Zugriffspaket eine Richtlinie an, die interne Mitglieder anfordern lassen, ein Genehmiger bestätigen muss und die nach 180 Tagen abläuft. Das Muster entspricht den Beispielen der Dokumentation. Danach fragt es die aktuellen Zuweisungen ab und exportiert sie als CSV.

**New-AccessPackagePolicy.ps1**

```powershell
Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All" -NoWelcome

$ap = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq 'Marketing Kampagne'"
if (-not $ap) { throw "Zugriffspaket nicht gefunden" }

$params = @{
    displayName        = "Mitarbeiter fordern an - Genehmigung durch Teamleitung"
    description        = "Interne Mitglieder, 180 Tage, 1 Genehmiger"
    allowedTargetScope = "allMemberUsers"
    expiration         = @{ type = "afterDuration"; duration = "P180D" }
    requestorSettings  = @{
        enableTargetsToSelfAddAccess    = $true
        enableTargetsToSelfUpdateAccess = $true
        enableTargetsToSelfRemoveAccess = $true
    }
    requestApprovalSettings = @{
        isApprovalRequiredForAdd    = $true
        isApprovalRequiredForUpdate = $true
        stages = @(
            @{
                durationBeforeAutomaticDenial   = "P7D"
                isApproverJustificationRequired = $false
                isEscalationEnabled             = $false
                primaryApprovers = @(
                    @{ "@odata.type" = "#microsoft.graph.singleUser"; userId = "<Objekt-ID Genehmiger>" }
                )
                fallbackPrimaryApprovers = @()
                escalationApprovers      = @()
                fallbackEscalationApprovers = @()
            }
        )
    }
    accessPackage = @{ id = $ap.Id }
}
New-MgEntitlementManagementAssignmentPolicy -BodyParameter $params | Out-Null

$assignments = @(Get-MgEntitlementManagementAssignment `
    -Filter "accessPackage/id eq '$($ap.Id)' and state eq 'Delivered'" `
    -ExpandProperty target -All)
$assignments | Select-Object Id, @{n='Benutzer';e={$_.Target.DisplayName}}, @{n='UPN';e={$_.Target.PrincipalName}} |
    Export-Csv ".\zuweisungen.csv" -NoTypeInformation -Encoding UTF8
```

Das Skript sucht zuerst das Paket nach seinem Namen und bricht ab, wenn es nicht existiert. Die Richtlinie wird als Hashtabelle aufgebaut. Der Wert `allMemberUsers` beschränkt die Anforderer auf Mitgliedsbenutzer des eigenen Verzeichnisses (keine Gäste). Die Ablaufregel `afterDuration` mit dem ISO-Format `P180D` bedeutet 180 Tage. Die drei `enableTargetsToSelf...`-Schalter erlauben Benutzern, Zugriff für sich selbst anzufordern, zu ändern und zu entfernen. Die Genehmigung hat eine Stufe: Der primäre Genehmiger ist ein einzelner Benutzer, nach sieben Tagen ohne Entscheidung wird die Anfrage automatisch abgelehnt (`durationBeforeAutomaticDenial`). Die Platzhalter für die Objekt-ID müssen ersetzt werden. Im zweiten Teil werden die ausgelieferten Zuweisungen mit dem Zielobjekt (`-ExpandProperty target`) abgefragt und in eine CSV-Datei geschrieben.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, Zugriffspakete ohne Ablauf anzulegen. Dann sind sie nur eine komplizierte Form der Gruppe. Ebenso verbreitet sind Pakete, die viel zu groß sind: Ein „Allgemeines Mitarbeiterpaket“ mit 30 Ressourcen. Wer es anfordert, bekommt mehr, als er braucht. Zugriffspakete sollen sich an Aufgaben und Rollen orientieren. Ein dritter Stolperstein ist die fehlende Überprüfung.

```
FALSCH:  Paket "Alles fuer Marketing": 25 Ressourcen, kein Ablauf,
          keine Ueberpruefung, genehmigt wird automatisch.

RICHTIG: Paket "Kampagne Herbst": Team + Website + 1 App,
          Ablauf 180 Tage, Genehmigung durch Kampagnenleitung,
          Zugriffsueberpruefung nach 90 Tagen (Pruefer: Kampagnenleitung)
```

### Praxisbezug.

In Beratungsprojekten wird mit zwei bis drei Pilotpaketen gestartet: einem Gästepaket (Befristung und Genehmigung durch einen Besitzer), einem Projektpaket und einem Paket für selten benötigte, sensible Rechte. An diesen Beispielen lernen Fachbereiche das Konzept kennen, bevor es breit ausgerollt wird. Die Dokumentation empfiehlt außerdem, vor dem Rollout zu entscheiden, wer Kataloge erstellen darf, und dafür eine Gruppe der „Katalogersteller“ zu nutzen.

> **Merke**
>
> Ein Zugriffspaket bündelt Ressourcen mit Regeln (wer, Genehmigung, Dauer) in einem Katalog. Delegation an Fachbereiche ist das Kernprinzip. Pakete ohne Ablaufdatum und ohne Überprüfung verfehlen den Sinn.

## 2.4 Access Reviews

Zugriff, der einmal genehmigt wurde, bleibt in der Praxis fast immer bestehen, bis jemand ihn bemerkt. Menschen wechseln Projekte, Gäste beenden Kooperationen, Anwendungen werden abgelöst, aber die Mitgliedschaften bleiben. Dieses schleichende Anwachsen von Berechtigungen nennt man *Berechtigungsdrift* oder *Privilege Creep*. Zugriffsüberprüfungen (Access Reviews) sind das Gegenmittel: Sie fragen in regelmäßigen Abständen die Personen, die es wissen müssen, ob ein Zugriff noch gebraucht wird, und entziehen ihn, wenn die Antwort „nein“ lautet oder gar keine Antwort kommt.

Eine Überprüfung besteht aus mehreren Entscheidungen, die man bewusst treffen muss. Erstens der *Gegenstand*: Was wird überprüft? Mitglieder einer Gruppe oder eines Teams, Gäste in Microsoft-365-Gruppen, Zuweisungen zu einer Anwendung, Mitglieder eines Zugriffspakets oder die Zuweisungen zu Microsoft-Entra-Rollen und Azure-Ressourcenrollen. Zweitens die *Prüfer*: Wer entscheidet? Das können die Besitzer der Gruppe sein, bestimmte benannte Personen, die Vorgesetzten der Benutzer oder die Benutzer selbst (Selbstüberprüfung). Drittens die *Wiederholung*: einmalig, wöchentlich, monatlich, vierteljährlich, halbjährlich oder jährlich. Viertens das *Verhalten bei Nichtreaktion*: Wird bei fehlender Antwort der Zugriff entzogen, beibehalten oder auf Basis der Empfehlung des Systems entschieden? Fünftens die *Anwendung der Ergebnisse*: automatisch oder erst nach manueller Bestätigung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation „What are access reviews?“ nennt neben dem Erstellen der Überprüfungen in den Bereichen „Gruppen und Apps“, „Zugriffspakete“ und „Privilegierte Rollen“ folgende Anwendungsfälle: zu viele Benutzer in privilegierten Rollen, Gruppen für Teams, die nicht mehr genutzt werden, sowie Gäste, die nicht mehr gebraucht werden. Zur Entscheidungshilfe bieten Überprüfungen *Empfehlungen*, die auf dem letzten Anmeldezeitpunkt beruhen: Wer sich lange nicht angemeldet hat, wird zum Entfernen vorgeschlagen. Für die Funktion ist eine Lizenz für Microsoft Entra ID Governance oder Microsoft Entra ID P2 vorgesehen. Die genaue Lizenzzuordnung je Szenario ändert sich gelegentlich und sollte vor dem Einsatz in der aktuellen Dokumentation nachgelesen werden.

Warum ist die Wahl der Prüfer so wichtig? Weil sie über die Qualität der Entscheidung bestimmt. Gruppenbesitzer kennen den Zweck der Gruppe, aber nicht unbedingt jedes Mitglied. Vorgesetzte kennen die Aufgaben ihrer Mitarbeitenden, aber nicht die Details einer Anwendung. Bei Gästen ist die Selbstüberprüfung häufig sinnvoll: Der Gast bestätigt, dass er den Zugriff weiter benötigt. Bei privilegierten Rollen sollten nie die Inhaber selbst prüfen. Hier bestimmt man eine unabhängige Person oder ein Gremium. Ein zweiter Qualitätsfaktor ist die Menge: Wer einem Prüfer 400 Zeilen auf einmal vorlegt, bekommt zu 90 Prozent „Alle genehmigen“. Kleine, fachlich zugeschnittene Überprüfungen liefern bessere Ergebnisse als eine große für das ganze Unternehmen.

Das folgende Skript legt eine wiederkehrende Überprüfung für Gäste in allen Microsoft-365-Gruppen an. Die Struktur folgt dem Beispiel aus der Microsoft-Dokumentation für Überprüfungen von Gästen in Gruppen. Die Prüfung läuft vierteljährlich, die Gäste prüfen sich selbst, und wer nicht antwortet, verliert den Zugriff. Aus Sicherheitsgründen werden die Ergebnisse nicht automatisch angewendet, solange die Überprüfung getestet wird.

**New-GuestAccessReview.ps1**

```powershell
Connect-MgGraph -Scopes "AccessReview.ReadWrite.All" -NoWelcome

$params = @{
    displayName         = "Quartalsweise Gaeste-Ueberpruefung"
    descriptionForAdmins = "Alle Gaeste in Microsoft-365-Gruppen, Selbstbestaetigung"
    descriptionForReviewers = "Bitte bestaetigen Sie, dass Sie den Zugriff weiter benoetigen."
    scope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query     = './members/microsoft.graph.user/?$filter=(userType eq ''Guest'')'
        queryType = "MicrosoftGraph"
    }
    instanceEnumerationScope = @{
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query     = "/groups?`$filter=(groupTypes/any(c:c eq 'Unified'))"
        queryType = "MicrosoftGraph"
    }
    reviewers = @(
        @{ query = "./"; queryType = "MicrosoftGraph"; queryRoot = "decisions_target" }
    )
    settings = @{
        mailNotificationsEnabled        = $true
        reminderNotificationsEnabled    = $true
        justificationRequiredOnApproval = $true
        defaultDecisionEnabled          = $true
        defaultDecision                 = "Deny"
        instanceDurationInDays          = 14
        autoApplyDecisionsEnabled       = $false   # erst nach dem Test auf $true setzen
        recommendationsEnabled          = $true
        recurrence = @{
            pattern = @{ type = "absoluteMonthly"; interval = 3 }
            range   = @{ type = "noEnd"; startDate = "2027-01-04" }
        }
    }
}
New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter $params
```

Die Definition hat zwei Bereichsangaben, die man leicht verwechselt. Der `scope` beschreibt, *wer* überprüft wird, hier alle Mitglieder vom Typ Gast. Die `instanceEnumerationScope` beschreibt, *in welchen Containern* gesucht wird, hier in allen Gruppen vom Typ „Unified“, also Microsoft-365-Gruppen. Für jede passende Gruppe entsteht eine eigene Überprüfungsinstanz. Der Prüfer `decisions_target` bedeutet Selbstüberprüfung: Jeder Gast entscheidet über seinen eigenen Zugriff. In den Einstellungen sorgt `defaultDecisionEnabled` zusammen mit `defaultDecision = "Deny"` dafür, dass ohne Reaktion der Zugriff entzogen wird. Die Dauer jeder Instanz beträgt 14 Tage. Die Wiederholung `absoluteMonthly` mit Intervall 3 ergibt einen Quartalsrhythmus. Das Startdatum muss in der Zukunft liegen und sollte vor dem Einsatz angepasst werden. Die Zeichenfolgen in einfachen Anführungszeichen (`'...'`) werden in PowerShell nicht interpretiert, daher stehen die Dollarzeichen dort ohne Escape, während in der doppelt zitierten Zeichenfolge ein Gravis-Zeichen (Backtick) davor steht.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zeigt für diesen Fall auch ein zweites Muster: Überprüfungen inaktiver Gäste in Teams. Dort wird mit dem Filter `(activity/signInActivity/lastSuccessfulSignInDateTime le ...)` auf den letzten erfolgreichen Anmeldezeitpunkt zugegriffen, und Besitzer der Teams entscheiden. Welche Variante besser ist, hängt von der Kultur ab: Die Selbstüberprüfung entlastet die Besitzer, die Prüfung durch Besitzer gibt der Organisation mehr Kontrolle.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist die Überprüfung ohne Konsequenz. Läuft eine Überprüfung nur im Modus „Empfehlung“ und werden Ergebnisse nie angewendet, bleibt der Aufwand ohne Wirkung. Ein zweiter Fehler ist das Gegenteil: Wird bei Nichtreaktion automatisch entzogen, ohne dass Prüfer vorher informiert wurden, bricht Zusammenarbeit ab und die Akzeptanz sinkt. Ein dritter Fehler: Prüfer, die gleichzeitig Betroffene sind.

```
FALSCH:  Ueberpruefung der Global-Administrator-Rolle.
          Pruefer: die Global Administratoren selbst, Standard "Genehmigen".

RICHTIG: Pruefer: Sicherheitsbeauftragte/r und Leitung IT (nicht betroffen)
          Bei Nichtreaktion: Zugriff entziehen
          Ergebnisse automatisch anwenden, Begruendung verpflichtend
```

### Praxisbezug.

Im Projektalltag beginnt man mit der Gästeüberprüfung und der Überprüfung der Administratorrollen, weil beide klar umrissen und aus Sicherheitssicht dringlich sind. Teams- und Gruppenüberprüfungen folgen, sobald die Besitzerpflege (Lerneinheit 2.6) funktioniert, denn eine Überprüfung ohne erreichbare Besitzer läuft ins Leere. Ergebnisse dieser Überprüfungen sind außerdem ein hervorragender Nachweis für Audits und Zertifizierungen.

> **Merke**
>
> Eine Zugriffsüberprüfung legt Gegenstand, Prüfer, Rhythmus, Standardentscheidung und Anwendung der Ergebnisse fest. Ohne Konsequenz bei Nichtreaktion und ohne unabhängige Prüfer bleibt sie wirkungslos.

## 2.5 PIM und Adminrollen

Administratorrechte sind der wertvollste Besitz eines Angreifers. Wer ein Konto mit der Rolle Globaler Administrator übernimmt, kontrolliert den gesamten Tenant. Deshalb gilt das *Prinzip der geringsten Rechte* (Least Privilege): Jede Person erhält nur die Rechte, die sie für ihre Aufgabe braucht, und das nur so lange, wie sie sie braucht. Privileged Identity Management (PIM) setzt dieses Prinzip um, indem es zwischen zwei Zuständen unterscheidet. Eine *berechtigte* (eligible) Zuweisung bedeutet: Die Person darf die Rolle bei Bedarf aktivieren, hat sie aber derzeit nicht. Eine *aktive* Zuweisung bedeutet: Die Rolle ist wirksam. Aktiviert wird per Antrag, häufig mit Begründung, Mehrstufen-Authentifizierung und gegebenenfalls Genehmigung, und die Aktivierung läuft nach einer festgelegten Zeit (typisch ein bis acht Stunden) von selbst ab. Man nennt das *Just-in-Time-Zugriff*.

> **Ergänzung aus der Nachrecherche**
>
> Laut Microsoft-Dokumentation ermöglicht PIM zeitlich begrenzten Zugriff, Genehmigung zur Aktivierung, Erzwingung der Mehrstufen-Authentifizierung, Begründungen, Benachrichtigungen bei Aktivierungen, Zugriffsüberprüfungen und einen Verlaufsnachweis. Das Konzept gilt für Microsoft-Entra-Rollen, für Azure-Ressourcenrollen und mit *PIM für Gruppen* auch für Gruppenmitgliedschaften und -besitz. Die Best-Practices-Seite zu Entra-Rollen empfiehlt: weniger als fünf Globale Administratoren, weniger als zehn privilegierte Rollenzuweisungen, Administratorkonten ausschließlich in der Cloud, Mehrstufen-Authentifizierung für Administratoren und rollenzuweisbare Gruppen anstelle von Einzelzuweisungen. Zwei Notfallkonten (Break-Glass) ohne Bindung an einzelne Personen sind empfohlen. Sie sollen cloudbasiert sein, eine phishing-resistente Anmeldung wie FIDO2 oder zertifikatsbasiert nutzen, von blockierenden Richtlinien des bedingten Zugriffs ausgenommen und dauerhaft aktiv zugewiesen sein. Ihre Anmeldung wird überwacht, und sie werden etwa alle 90 Tage getestet.

Wie sieht der Arbeitsablauf aus? Ein Administrator meldet sich normal an, ohne besondere Rechte. Benötigt er für eine Aufgabe die Rolle Exchange-Administrator, öffnet er PIM, wählt die Rolle, gibt eine Begründung und gegebenenfalls eine Ticketnummer an, bestätigt mit Mehrstufen-Authentifizierung und erhält die Rolle für die eingestellte Dauer. Nach Ablauf verschwindet sie. Jede Aktivierung wird protokolliert, und konfigurierte Empfänger werden benachrichtigt. Für besonders sensible Rollen wie Globaler Administrator fügt man eine Genehmigung durch eine zweite Person hinzu. Zusätzlich lassen sich die Rolleneinstellungen (maximale Dauer, Pflichtfelder) pro Rolle festlegen. Auch hier gilt: Die Einstellungen der Rolle sind die Regeln, die Zuweisungen sind die Anwendung der Regeln auf Personen.

Das folgende Skript verwendet die Graph-Cmdlets für Rollenverwaltung. Es macht eine Person für die Rolle „Exchange-Administrator“ berechtigt (zwölf Monate), aktiviert die Rolle anschließend für vier Stunden und listet die berechtigten Zuweisungen auf. Die Muster stammen aus den Beispielen der Dokumentation.

**PIM-Beispiel.ps1**

```powershell
Connect-MgGraph -Scopes "RoleEligibilitySchedule.ReadWrite.Directory","RoleAssignmentSchedule.ReadWrite.Directory","RoleManagement.Read.Directory" -NoWelcome

$userId = "<Objekt-ID der Person>"
$role   = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Exchange Administrator'"

# 1) Berechtigt machen (zwoelf Monate)
$eligible = @{
    action           = "adminAssign"
    justification    = "Betrieb Exchange Online, Antrag 4711"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId      = $userId
    scheduleInfo     = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration    = @{ type = "afterDuration"; duration = "P365D" }
    }
}
New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $eligible | Out-Null

# 2) Spaeter: die Person aktiviert selbst fuer vier Stunden
$activate = @{
    action           = "selfActivate"
    justification    = "Postfachmigration Abteilung Vertrieb"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId      = $userId
    scheduleInfo     = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration    = @{ type = "afterDuration"; duration = "PT4H" }
    }
}
New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $activate | Out-Null

# 3) Berechtigte Zuweisungen auflisten
Get-MgRoleManagementDirectoryRoleEligibilitySchedule -ExpandProperty "roleDefinition,principal" -All |
    Select-Object @{n='Rolle';e={$_.RoleDefinition.DisplayName}},
                  @{n='Person';e={$_.Principal.AdditionalProperties.userPrincipalName}},
                  @{n='Ablauf';e={$_.ScheduleInfo.Expiration.EndDateTime}}
```

Im ersten Block steht `action = "adminAssign"`: Ein Administrator weist die Berechtigung zu. Die `directoryScopeId` mit dem Wert Schrägstrich bedeutet „im gesamten Verzeichnis“; mit einer Verwaltungseinheit ließe sich die Rolle eingrenzen. Die Dauer `P365D` ist ein Jahr, danach muss die Berechtigung verlängert oder überprüft werden. Im zweiten Block benutzt die Person `selfActivate`. Dieser Aufruf funktioniert nur, wenn die Person im Anmeldekontext handelt und die Regeln der Rolle erfüllt sind (zum Beispiel Mehrstufen-Authentifizierung). Er ist hier der Vollständigkeit halber im selben Skript gezeigt, in der Praxis wird er von der Person selbst im Portal oder über ein eigenes Skript ausgelöst. Die Dauer `PT4H` bedeutet vier Stunden. Der dritte Block fragt die Berechtigungen mit aufgelösten Rollen- und Personennamen ab und eignet sich als Grundlage für eine regelmäßige Auswertung.

Die Zahl der Rollen ist groß, daher lohnt sich eine Auswahlregel. Statt Globaler Administrator zu vergeben, sucht man die spezifischste Rolle, die die Aufgabe abdeckt: Exchange-Administrator für Postfächer, SharePoint-Administrator für Websites, Teams-Administrator für Teams-Richtlinien, Benutzeradministrator für Kennwortrücksetzungen, Berichtsleser für reine Lesezugriffe. Wo selbst das zu grob ist, helfen Verwaltungseinheiten (Administrative Units), die eine Rolle auf eine Teilmenge von Objekten begrenzen, oder benutzerdefinierte Rollen.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, PIM zwar zu aktivieren, aber dauerhaft aktive Zuweisungen bestehen zu lassen. Dann bringt PIM keinen Sicherheitsgewinn. Das zweite Problem: Notfallkonten, die versehentlich unter eine Richtlinie für bedingten Zugriff fallen, mit der sich dann niemand mehr anmelden kann. Das dritte: Aktivierungszeiträume, die so lang sind, dass sie dem Dauerzugriff gleichen.

```
FALSCH:  Rolle "Globaler Administrator" dauerhaft aktiv fuer 9 Personen,
          Aktivierung ohne MFA und ohne Begruendung.

RICHTIG: 2 Notfallkonten (dauerhaft aktiv, ueberwacht, Test alle 90 Tage)
          3 weitere Personen berechtigt, Aktivierung max. 2 Stunden,
          MFA + Begruendung + Genehmigung, Benachrichtigung an Security
```

### Praxisbezug.

In Projekten ist die Bestandsaufnahme der Adminrollen oft der erste Aha-Effekt: Die Auswertung zeigt häufig mehr als zehn Globale Administratoren, darunter Konten ehemaliger Dienstleister. Der Weg dorthin: erst Inventar (Modul 01, Lerneinheit „Rollen und Verantwortlichkeiten“), dann PIM aktivieren, dann Dauerzuweisungen schrittweise in berechtigte Zuweisungen umwandeln, dann eine Zugriffsüberprüfung für Rollen einrichten.

> **Merke**
>
> PIM macht aus Dauerrechten Rechte auf Abruf: berechtigt statt aktiv, zeitlich begrenzt, mit MFA, Begründung und Protokoll. Zwei überwachte Notfallkonten bleiben dauerhaft aktiv.

## 2.6 Gruppen-Governance

Gruppen sind der Kleber der Microsoft-365-Welt. Hinter jedem Team, jeder Teamwebsite, jedem Viva-Engage-Netzwerk und jedem gemeinsamen Postfach steht in der Regel eine Gruppe. Wird die Gruppenerstellung nicht gesteuert, entstehen innerhalb weniger Monate Hunderte unbenannter Gruppen ohne Besitzer, deren Zweck niemand mehr kennt. Gruppen-Governance bedeutet deshalb, fünf Dinge zu regeln: wer Gruppen erstellen darf, wie sie heißen, wer für sie verantwortlich ist, wann sie ablaufen und wie Mitgliedschaften zustande kommen.

Zuerst die Erstellung. Standardmäßig dürfen alle Benutzer Microsoft-365-Gruppen erstellen. Wie die Dokumentation „Manage who can create Microsoft 365 Groups“ beschreibt, lässt sich das auf Mitglieder einer bestimmten Sicherheitsgruppe beschränken. Die Einstellung steckt in einer Verzeichniseinstellung auf Basis der Vorlage `Group.Unified`, mit den Werten `EnableGroupCreation` und `GroupCreationAllowedGroupId`. Administratorrollen sind von der Einschränkung ausgenommen. Das Verzeichnis braucht dafür eine Lizenz Microsoft Entra ID P1 oder P2 für die Mitglieder der Gruppe. Änderungen brauchen mindestens 30 Minuten, bis sie überall wirken. Außerdem zu beachten: Die Einschränkung gilt für Gruppenerstellung über Teams, Planner, SharePoint und Co., doch das Outlook im Web kann Gruppen über eine Postfachrichtlinie weiterhin erlauben, wenn diese nicht angepasst wird.

Dann die *Namenskonvention*. Die Namensrichtlinie von Microsoft 365 setzt Präfixe und Suffixe, die aus festem Text und Attributen des Erstellers bestehen können, etwa `GRP_[Department]_[GroupName]`. Dazu kommt eine Liste gesperrter Wörter. Laut Dokumentation gilt eine Gesamtlänge von 63 Zeichen, und die Liste gesperrter Wörter kann bis zu 5000 Einträge enthalten. Die Rollen Globaler Administrator und Benutzeradministrator sind ausgenommen. Praktisch wichtig: Die Namensrichtlinie greift beim Erstellen, nicht rückwirkend. Bestehende Gruppen müssen separat bereinigt werden.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation „Configure a group expiration policy“ beschreibt die *Ablaufrichtlinie* für Microsoft-365-Gruppen. Sie ist standardmäßig ausgeschaltet. Mögliche Laufzeiten sind 180 Tage, 365 Tage oder ein benutzerdefinierter Wert von mindestens 30 Tagen. Die Richtlinie kann für alle Gruppen oder für ausgewählte Gruppen (bis zu 500) gelten. Besitzer werden 30, 15 und 1 Tag vor Ablauf benachrichtigt, und eine Gruppe wird automatisch verlängert, wenn Aktivität erkannt wird (etwa 35 Tage vor Ablauf). Abgelaufene Gruppen werden zunächst weich gelöscht und lassen sich 30 Tage lang wiederherstellen. Hinweis: Die Ablaufrichtlinie benötigt eine Lizenz Entra ID P1 oder P2 für die betroffenen Mitglieder und funktioniert zusammen mit Aufbewahrungsrichtlinien, die Inhalte vor dem Verlust schützen.

Zur *Besitzerpflege*: Eine Gruppe ohne Besitzer kann niemand verwalten, und Ablaufbenachrichtigungen laufen ins Leere. Als Faustregel hat jede Gruppe mindestens zwei Besitzer. Fehlende Besitzer ist das häufigste Problem in Bestandstenants und wurde bereits in Modul 01 (Operating Model) mit einem Skript ausgewertet. Zur *Mitgliedschaftsart*: Zugewiesene Mitgliedschaften pflegt der Besitzer von Hand, dynamische Mitgliedschaften werden durch eine Regel auf Basis von Benutzerattributen automatisch gepflegt. Dynamische Gruppen sind ideal für Basisrechte („alle Mitarbeitenden der Abteilung Vertrieb“), erfordern aber saubere Attribute. Für Berechtigungen auf Entra-Rollen gibt es *rollenzuweisbare Gruppen*, die bei der Erstellung so markiert werden müssen und deren Mitgliedschaft nur privilegierte Administratoren ändern dürfen.

Das Skript legt eine Ablaufrichtlinie für Microsoft-365-Gruppen an und erzeugt eine dynamische Gruppe für eine Abteilung. Die Cmdlets entsprechen den Beispielen der Dokumentation.

**Gruppen-Governance.ps1**

```powershell
Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.ReadWrite.All" -NoWelcome

# 1) Ablaufrichtlinie: 365 Tage, gilt fuer alle Microsoft-365-Gruppen
$policy = New-MgGroupLifecyclePolicy `
    -GroupLifetimeInDays 365 `
    -ManagedGroupTypes "All" `
    -AlternateNotificationEmails "it-governance@contoso.example"
"Richtlinie angelegt: $($policy.Id)"

# 2) Dynamische Microsoft-365-Gruppe fuer die Abteilung Vertrieb
$grp = New-MgGroup -DisplayName "GRP_Vertrieb_Alle" `
    -MailNickname "grp-vertrieb-alle" `
    -MailEnabled:$true -SecurityEnabled:$false `
    -GroupTypes @("Unified","DynamicMembership") `
    -MembershipRule '(user.department -eq "Vertrieb") and (user.accountEnabled -eq true)' `
    -MembershipRuleProcessingState "On"
"Gruppe angelegt: $($grp.Id)"

# 3) Gruppen ohne zwei Besitzer finden
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All | ForEach-Object {
    $owners = @(Get-MgGroupOwner -GroupId $_.Id)
    if ($owners.Count -lt 2) {
        [pscustomobject]@{ Gruppe = $_.DisplayName; Besitzer = $owners.Count }
    }
} | Sort-Object Besitzer | Format-Table -AutoSize
```

Beim ersten Block gilt `-ManagedGroupTypes "All"`: Die Richtlinie umfasst alle Microsoft-365-Gruppen. Mit dem Wert „Selected“ würde sie nur für Gruppen gelten, die man danach einzeln hinzufügt (Cmdlet `Add-MgGroupToLifecyclePolicy`). Die alternative E-Mail-Adresse erhält Benachrichtigungen für Gruppen ohne Besitzer. Im zweiten Block stehen die Gruppentypen `Unified` (Microsoft-365-Gruppe) und `DynamicMembership` zusammen, und die Regel steht in einfachen Anführungszeichen, damit die doppelten Anführungszeichen in der Regel erhalten bleiben. Die Bedingung `user.accountEnabled -eq true` sorgt dafür, dass deaktivierte Konten nicht Mitglied bleiben. Der Verarbeitungsstatus `On` startet die Regelauswertung sofort. Im dritten Block läuft eine Schleife über alle Gruppen, zählt die Besitzer und gibt nur diejenigen mit weniger als zwei aus.

### Typische Fehler und Stolperfallen.

Ein typischer Fehler ist, die Einschränkung der Gruppenerstellung einzuführen, ohne einen Antragsweg zu bieten. Die Folge: Schatten-IT mit Fremdwerkzeugen. Der zweite Fehler ist, die Ablaufrichtlinie ohne Vorankündigung für alle Gruppen einzuschalten und damit aktive Projektgruppen zu löschen. Der dritte: dynamische Regeln auf Attributen, die nicht gepflegt sind.

```
FALSCH:  Ablauf 180 Tage fuer alle Gruppen, Besitzer unbekannt,
          keine Ankuendigung. Ergebnis: Gruppen werden geloescht.

RICHTIG: 1) Besitzerbericht erstellen, Besitzer nachpflegen
          2) Ablaufrichtlinie zuerst fuer eine Pilotgruppe (Selected)
          3) Ankuendigung, dann Ausweitung auf alle Gruppen
          4) Wiederherstellung (30 Tage) im Betriebshandbuch beschreiben
```

### Praxisbezug.

Die Kombination aus eingeschränkter Erstellung, Namenskonvention und Ablaufrichtlinie bildet das Rückgrat der Gruppen-Governance. In Modul 10 wird daraus eine Bereitstellungsfabrik (Provisioning Factory) mit Antrag, Genehmigung und automatischer Anlage. Hier legen Sie die Grundlagen: Wer darf was, wie heißt es, wer ist verantwortlich und wie lange lebt es.

> **Merke**
>
> Gruppen-Governance regelt Erstellung, Namen, Besitzer, Ablauf und Mitgliedschaft. Richtlinien greifen nur bei neuen Objekten oder mit Verzögerung, deshalb gehört immer eine Bereinigung des Bestands dazu.

## 2.7 Guest Access

Zusammenarbeit über Organisationsgrenzen hinweg ist in Microsoft 365 selbstverständlich. Technisch beruht sie auf *Microsoft Entra B2B* (Business-to-Business). Eine externe Person wird als *Gastbenutzer* im eigenen Verzeichnis angelegt, meldet sich aber mit ihrer eigenen Identität an. Das Gastkonto ist ein Objekt mit dem Benutzertyp „Guest“. Einladungen entstehen durch Freigabe einer Datei, durch Hinzufügen zu einem Team, durch eine Einladung im Entra Admin Center oder durch Zugriffspakete. Danach muss der Gast die Einladung annehmen (Status `PendingAcceptance`), bevor er zugreifen kann.

Die wichtigste Erkenntnis für die Governance: Es gibt *mehrere Ebenen* von Einstellungen, und die restriktivste gewinnt. Die Dokumentation zur externen Freigabe nennt die Hierarchie: Ganz oben stehen die Einstellungen der Entra-Zusammenarbeit (wer darf einladen, welche Domänen sind erlaubt), darunter die organisationsweiten Einstellungen von SharePoint und OneDrive, darunter die Einstellung der einzelnen Website, bei Teams außerdem die Gasteinstellungen von Teams. Das Ergebnis ist immer die strengste Kombination. Wer auf einer Website externe Freigabe erlaubt, auf der Organisationsebene aber nicht, hat sie faktisch nicht. Diese Mehrstufigkeit sollten Sie in Fehlersuchen berücksichtigen (Lerneinheit 2.8).

> **Ergänzung aus der Nachrecherche**
>
> Die Referenzseite „Microsoft 365 guest settings“ fasst Standardwerte zusammen. Laut dieser Seite ist in den kanalübergreifenden Zugriffseinstellungen (Cross-Tenant Access) die B2B-Zusammenarbeit standardmäßig erlaubt, die B2B-Direktverbindung (für Shared Channels) dagegen standardmäßig blockiert. Die externe Freigabe in SharePoint ist laut Übersichtsseite standardmäßig eingeschaltet und kann auf Organisationsebene und je Website eingeschränkt werden. Beachten Sie, dass sich Standardwerte ändern können. Für verbindliche Aussagen immer die aktuelle Seite prüfen. Für DSGVO-Fragen (Auftragsverarbeitung, Drittlandübermittlung, Datensparsamkeit bei Gastdaten) gilt: Das ist eine rechtliche Bewertung im Einzelfall, keine Rechtsberatung. Fragen Sie Ihre Datenschutzbeauftragte.

Ein gesteuerter Gästelebenszyklus hat vier Stationen. *Einladung*: Wer darf einladen? Die Einstellungen reichen von „jeder“ bis „nur bestimmte Administratorrollen“. Eine bewährte Mitte ist: Mitglieder dürfen einladen, aber nur in Domänen auf einer Positivliste, oder die Einladung läuft ausschließlich über Zugriffspakete mit Genehmigung. *Berechtigung*: Gäste sehen standardmäßig weniger im Verzeichnis als Mitglieder, was man bewusst belassen sollte. *Überprüfung*: Regelmäßige Zugriffsüberprüfungen (Lerneinheit 2.4). *Ende*: Wenn der letzte Zugriff endet, soll das Gastkonto verschwinden. Im Entitlement Management lässt sich das automatisieren, bei manuell eingeladenen Gästen nicht. Wichtig: Das Löschen eines Teams entfernt Gäste nicht aus dem Verzeichnis, ein verwaister Gast bleibt also bestehen, bis jemand ihn bereinigt.

Das nächste Skript lädt einen Gast ein und erstellt zwei Auswertungen: ausstehende Einladungen, die älter als 30 Tage sind, und Gäste, die sich seit mehr als 90 Tagen nicht angemeldet haben. Für die Anmeldeinformationen ist eine Lizenz P1 oder P2 erforderlich; ohne die Eigenschaft `SignInActivity` ist die zweite Abfrage nicht möglich.

**Gast-Verwaltung.ps1**

```powershell
Connect-MgGraph -Scopes "User.Invite.All","User.Read.All","AuditLog.Read.All" -NoWelcome

# 1) Gast einladen
New-MgInvitation -InvitedUserEmailAddress "partner@fabrikam.example" `
    -InvitedUserDisplayName "Partner Fabrikam" `
    -InviteRedirectUrl "https://myapps.microsoft.com" `
    -SendInvitationMessage:$true

# 2) Ausstehende Einladungen aelter als 30 Tage
$grenze = (Get-Date).AddDays(-30)
Get-MgUser -Filter "userType eq 'Guest' and externalUserState eq 'PendingAcceptance'" -All `
    -Property Id,DisplayName,Mail,CreatedDateTime,ExternalUserState |
    Where-Object { $_.CreatedDateTime -lt $grenze } |
    Select-Object DisplayName, Mail, CreatedDateTime

# 3) Gaeste ohne Anmeldung seit 90 Tagen
$inaktiv = (Get-Date).AddDays(-90)
Get-MgUser -Filter "userType eq 'Guest'" -All `
    -Property Id,DisplayName,Mail,SignInActivity |
    Where-Object { -not $_.SignInActivity.LastSuccessfulSignInDateTime -or
                   $_.SignInActivity.LastSuccessfulSignInDateTime -lt $inaktiv } |
    Select-Object DisplayName, Mail, @{n='LetzteAnmeldung';e={$_.SignInActivity.LastSuccessfulSignInDateTime}}
```

Der Aufruf `New-MgInvitation` legt das Gastkonto an und versendet auf Wunsch die Einladungsmail, die Umleitungsadresse bestimmt, wohin der Gast nach Annahme gelangt. Die zweite Abfrage nutzt den Filter `externalUserState eq 'PendingAcceptance'` aus der Dokumentation und vergleicht das Anlagedatum mit der Grenze von 30 Tagen. Die dritte fragt zusätzlich die Eigenschaft `SignInActivity` ab. Gäste ohne jede Anmeldung haben keinen Wert, deshalb prüft die Bedingung zuerst auf leeren Wert. Beide Auswertungen lassen sich als Grundlage für Bereinigung und für eine Zugriffsüberprüfung nutzen.

### Typische Fehler und Stolperfallen.

Typisch ist die Annahme, ein Gast sei „harmlos“, weil er nur eingeladen ist. Gäste können je nach Einstellungen Teams und Dateien sehen. Zweiter Fehler: Gäste ohne Verantwortlichen. Wer lädt ein, und wer entfernt den Gast wieder? Dritter Fehler: Domänen-Allowlist und Zugriffspaket widersprechen sich.

```
FALSCH:  Jeder Mitarbeitende darf jede Domaene einladen, kein Sponsor,
          keine Ueberpruefung. Nach zwei Jahren: 1.800 Gaeste, 60 Prozent inaktiv.

RICHTIG: Einladung nur ueber Zugriffspaket (Genehmigung durch Sponsor),
          Befristung 180 Tage, Ueberpruefung quartalsweise,
          Bericht ueber inaktive Gaeste monatlich
```

### Praxisbezug.

Der Gästebestand ist in fast jedem Bestandstenant das größte Aufräumthema. Erst die Bereinigung (Bericht, Überprüfung, Löschung), dann die Prävention (Einladungseinschränkung, Zugriffspakete, Befristung). Die Reihenfolge ist wichtig, weil bei strengeren Einstellungen sonst Kolleginnen und Kollegen ihre laufende Zusammenarbeit verlieren. Die Konfiguration in Teams (Lerneinheit 3.4) und SharePoint (Lerneinheit 4.4) baut auf diesen Grundlagen auf.

> **Merke**
>
> Gäste sind echte Identitäten mit echten Rechten. Mehrere Einstellungsebenen wirken zusammen, die strengste gewinnt. Ein gesteuerter Lebenszyklus umfasst Einladung, Berechtigung, Überprüfung und Ende.

## 2.8 Identity-Troubleshooting

Wenn Benutzer sagen „Ich komme nicht ins Team“, „Meine Einladung funktioniert nicht“ oder „Ich sehe die Rolle nicht“, hilft nur ein systematisches Vorgehen. Das Grundprinzip der Fehlersuche lautet: erst feststellen, was genau passiert, dann die Ebene eingrenzen, dann Protokolle prüfen, dann erst ändern. Bei Identitätsproblemen gibt es drei Informationsquellen. Die *Anmeldeprotokolle* (Sign-in Logs) zeigen jeden Anmeldeversuch mit Ergebnis, Fehlercode und angewendeten Richtlinien des bedingten Zugriffs. Die *Überwachungsprotokolle* (Audit Logs) zeigen Änderungen im Verzeichnis: Wer hat welche Gruppe oder welche Rolle wann geändert? Die *Bereitstellungs- und Workflowprotokolle* zeigen, was bei Lifecycle Workflows oder Zugriffspaketen geschehen ist.

Die häufigsten Fehlerbilder lassen sich einer Ursache zuordnen. Erstens Verzögerung: Viele Änderungen an Verzeichniseinstellungen brauchen Zeit, bei der Einschränkung der Gruppenerstellung mindestens 30 Minuten laut Dokumentation, und Gruppenmitgliedschaften werden in Teams und SharePoint mit Verzögerung wirksam. Zweitens Richtlinienkonflikt: eine Namensrichtlinie lehnt den Namen ab, eine Einladungseinschränkung blockiert die Domäne, eine Richtlinie des bedingten Zugriffs verlangt ein konformes Gerät. Drittens Datenqualität: Ein Lifecycle Workflow läuft nicht, weil das Eintrittsdatum fehlt, eine dynamische Gruppe bleibt leer, weil das Attribut falsch geschrieben ist. Viertens Lizenz: Die Funktion existiert, aber der Benutzer hat nicht die nötige Lizenz. Fünftens Umgehung: Gruppen werden trotz Einschränkung erstellt, weil eine andere Oberfläche (Outlook im Web) nicht mit eingeschränkt wurde.

> **Ergänzung aus der Nachrecherche**
>
> Die Dokumentation zu Anmeldeprotokollen empfiehlt, bei Fehlersuchen die Filter für Benutzer, Anwendung, Status und Zeitraum zu kombinieren. Bei Teams-Gästen ist das Anmeldeprotokoll des Gastes im *Heimat-Tenant* nicht einsehbar, im eigenen Tenant sieht man aber die Gastanmeldungen in die eigenen Ressourcen. Planen Sie außerdem die Aufbewahrungsdauer der Protokolle ein: Sie ist begrenzt und hängt von der Lizenz ab. Für längere Nachweise leiten Sie die Protokolle in einen Log-Analytics-Arbeitsbereich oder eine andere Archivlösung weiter. Ein Spezialfall sind Zugriffsprobleme nach der Annahme einer Einladung. Sie liegen häufig an fehlenden Berechtigungen auf Ressourcenebene und nicht an der Anmeldung.

Das folgende Skript bündelt die wichtigsten Abfragen für den Support: die letzten Anmeldungen einer Person mit Ergebnis und die letzten Verzeichnisänderungen an ihr. Es ist als Hilfsmittel für das Servicedesk-Team gedacht, nicht als Ersatz für das Portal.

**Get-IdentitySupportReport.ps1**

```powershell
param([Parameter(Mandatory)][string]$UserPrincipalName)

Connect-MgGraph -Scopes "AuditLog.Read.All","Directory.Read.All" -NoWelcome

Write-Host "== Letzte Anmeldungen ==" -ForegroundColor Cyan
Get-MgAuditLogSignIn -Filter "userPrincipalName eq '$UserPrincipalName'" -Top 15 |
    Select-Object CreatedDateTime, AppDisplayName,
        @{n='Status';e={ if ($_.Status.ErrorCode -eq 0) {'OK'} else {"Fehler $($_.Status.ErrorCode)"} }},
        @{n='Grund';e={$_.Status.FailureReason}},
        ConditionalAccessStatus |
    Format-Table -AutoSize

Write-Host "== Letzte Verzeichnisaenderungen am Konto ==" -ForegroundColor Cyan
$user = Get-MgUser -UserId $UserPrincipalName
Get-MgAuditLogDirectoryAudit -Filter "targetResources/any(t:t/id eq '$($user.Id)')" -Top 15 |
    Select-Object ActivityDateTime, ActivityDisplayName, Result,
        @{n='Durch';e={$_.InitiatedBy.User.UserPrincipalName}} |
    Format-Table -AutoSize
```

Der Parameter `UserPrincipalName` ist verpflichtend. Der erste Abschnitt fragt die jüngsten 15 Anmeldungen ab und berechnet eine lesbare Statusspalte: Der Fehlercode 0 bedeutet Erfolg, alles andere wird mit dem Code angezeigt. Wichtig ist die Spalte `ConditionalAccessStatus`, die verrät, ob eine Richtlinie des bedingten Zugriffs den Zugriff verhindert hat. Der zweite Abschnitt sucht anhand der Objekt-ID des Kontos die Einträge im Überwachungsprotokoll und zeigt, wer wann was geändert hat. So lässt sich beantworten, ob eine Gruppenmitgliedschaft tatsächlich entfernt wurde und durch wen.

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, sofort zu ändern, statt zu messen: Mitgliedschaft neu setzen, Konto neu anlegen, Lizenz entziehen und wieder zuweisen. Das zerstört Spuren und löst oft das falsche Problem. Zweiter Fehler: Nur einen Ort prüfen. Bei Gästen kann es an Entra, an Teams oder an SharePoint liegen. Dritter Fehler: ohne Notiz und ohne Ticket arbeiten.

```
FALSCH:  "Gast kann nicht ins Team" -> Gast loeschen und neu einladen.

RICHTIG: 1) Einladung angenommen? (externalUserState)
          2) Anmeldeprotokoll: Fehlercode, bedingter Zugriff?
          3) Teams-Gasteinstellungen und Websiteeinstellung pruefen
          4) Mitgliedschaft im Team und Verzoegerung beruecksichtigen
          5) Erst dann aendern, Ergebnis dokumentieren
```

### Praxisbezug.

Ein dokumentierter Entscheidungsbaum spart im Support Stunden. Legen Sie für die zehn häufigsten Fälle je eine Seite im Betriebshandbuch an (Symptom, Prüfschritte, Ursache, Lösung, Eskalation). In Modul 09 (Operational Runbooks) wird dieses Vorgehen systematisch aufgegriffen.

> **Merke**
>
> Erst messen, dann ändern: Anmeldeprotokoll, Überwachungsprotokoll und Workflowprotokoll beantworten die meisten Fragen. Häufige Ursachen sind Verzögerung, Richtlinienkonflikt, Datenqualität, Lizenz und Umgehung.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Nennen Sie die drei Lebenszyklen der Entra ID Governance und ordnen Sie jedem ein Werkzeug zu.

**Aufgabe 2 (leicht).** Erklären Sie in zwei bis drei Sätzen den Unterschied zwischen einer berechtigten (eligible) und einer aktiven Rollenzuweisung in PIM.

**Aufgabe 3 (leicht).** Welche Informationen braucht ein Lifecycle Workflow, damit er bei einem Eintritt automatisch startet? Nennen Sie mindestens drei Bestandteile.

**Aufgabe 4 (mittel).** Ein Projektleiter möchte, dass externe Berater Zugriff auf ein Team und eine SharePoint-Website erhalten, aber nur für drei Monate und nach seiner Genehmigung. Beschreiben Sie, wie Sie das mit Katalog, Zugriffspaket und Richtlinie abbilden.

**Aufgabe 5 (mittel).** Sie sollen eine Zugriffsüberprüfung für die Rolle Globaler Administrator entwerfen. Legen Sie Prüfer, Rhythmus, Standardentscheidung und Anwendung der Ergebnisse fest und begründen Sie jede Wahl.

**Aufgabe 6 (mittel).** Schreiben Sie ein PowerShell-Skript, das alle Microsoft-365-Gruppen mit weniger als zwei Besitzern in eine CSV-Datei `gruppen-ohne-besitzer.csv` exportiert (Spalten: Name, Anzahl Besitzer, Erstellungsdatum).

**Aufgabe 7 (schwer).** Schreiben Sie ein Skript, das alle Gäste findet, die seit mehr als 120 Tagen keine erfolgreiche Anmeldung hatten oder deren Einladung seit mehr als 45 Tagen aussteht, und gibt sie getrennt nach den beiden Kategorien aus.

**Aufgabe 8 (schwer).** Ein Kunde meldet: „Seit gestern können neue Mitarbeitende keine Teams mehr erstellen, aber zwei Administratoren können es noch.“ Beschreiben Sie Ihr Vorgehen und mindestens drei mögliche Ursachen. Nennen Sie, wo Sie jeweils nachsehen.

## Lösungen

**Lösung 1.** Die drei Lebenszyklen sind der Identitätslebenszyklus (Eintritt, Wechsel, Austritt; Werkzeug: Lifecycle Workflows), der Zugriffslebenszyklus (Zugriffspakete und Zugriffsüberprüfungen) und der Lebenszyklus privilegierter Zugriffe (Privileged Identity Management). Wichtig ist die Unterscheidung: Der erste regelt, wer zur Organisation gehört, der zweite, worauf er zugreift, der dritte, wer verwalten darf.

**Lösung 2.** Eine berechtigte Zuweisung erlaubt es der Person, die Rolle bei Bedarf zu aktivieren, sie ist aber nicht wirksam. Eine aktive Zuweisung ist dauerhaft oder zeitlich begrenzt wirksam. PIM erzwingt bei der Aktivierung Maßnahmen wie Mehrstufen-Authentifizierung und Begründung, und die Aktivierung läuft nach der eingestellten Dauer von selbst ab. Dadurch bestehen Rechte nur während des tatsächlichen Bedarfs.

**Lösung 3.** Mindestens nötig sind: ein Bereich (wer ist betroffen, zum Beispiel eine Abteilung), ein zeitbasierter Auslöser auf einem Benutzerattribut (zum Beispiel `employeeHireDate` mit einem Versatz), eine Liste von Aufgaben (Konto aktivieren, Willkommens-E-Mail senden) und gepflegte Benutzerdaten. Ohne ein Eintrittsdatum am Benutzerobjekt läuft der Workflow nicht, auch wenn er korrekt konfiguriert ist.

**Lösung 4.** Im Katalog des Projekts legt man ein Zugriffspaket an, das das Team und die Website enthält (jeweils mit Rolle Mitglied beziehungsweise Besucher). Die Richtlinie lässt Benutzer aus einer verbundenen Organisation oder bestimmte externe Verzeichnisse anfordern, verlangt Genehmigung durch den Projektleiter, setzt den Ablauf auf 90 Tage und aktiviert, dass das Gastkonto nach Ablauf des letzten Zugriffs automatisch entfernt wird. Optional folgt eine Zugriffsüberprüfung nach 60 Tagen. Der Projektleiter wird als Katalogbesitzer delegiert und kann Ressourcen nur hinzufügen, die er selbst besitzt.

**Lösung 5.** Prüfer sollten unabhängige Personen sein, etwa die Sicherheitsbeauftragte und die IT-Leitung, nicht die Administratoren selbst. Der Rhythmus ist vierteljährlich oder bei kleiner Gruppe monatlich. Standardentscheidung bei fehlender Reaktion ist „Zugriff entziehen“, weil eine nicht bestätigte Dauerberechtigung ein Risiko darstellt. Ergebnisse werden automatisch angewendet, mit verpflichtender Begründung. Wichtig: Notfallkonten werden in die Überprüfung einbezogen oder bewusst dokumentiert ausgenommen.

**Lösung 6.** Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "Group.Read.All" -NoWelcome
Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName,CreatedDateTime |
  ForEach-Object {
    $n = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($n -lt 2) {
      [pscustomobject]@{ Name = $_.DisplayName; AnzahlBesitzer = $n; Erstellt = $_.CreatedDateTime }
    }
  } | Export-Csv ".\gruppen-ohne-besitzer.csv" -NoTypeInformation -Encoding UTF8
```

Das Skript filtert auf Microsoft-365-Gruppen, zählt die Besitzer je Gruppe und schreibt nur die Gruppen mit weniger als zwei Besitzern in die CSV-Datei. Das Einpacken mit `@(...)` stellt sicher, dass auch bei null oder einem Besitzer eine Anzahl bestimmt werden kann.

**Lösung 7.** Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "User.Read.All","AuditLog.Read.All" -NoWelcome
$g = Get-MgUser -Filter "userType eq 'Guest'" -All `
     -Property Id,DisplayName,Mail,CreatedDateTime,ExternalUserState,SignInActivity
$inaktiv = $g | Where-Object {
  $_.ExternalUserState -ne 'PendingAcceptance' -and
  ( -not $_.SignInActivity.LastSuccessfulSignInDateTime -or
    $_.SignInActivity.LastSuccessfulSignInDateTime -lt (Get-Date).AddDays(-120) ) }
$offen = $g | Where-Object {
  $_.ExternalUserState -eq 'PendingAcceptance' -and
  $_.CreatedDateTime -lt (Get-Date).AddDays(-45) }
"--- Inaktiv (>120 Tage) ---"; $inaktiv | Select-Object DisplayName, Mail
"--- Einladung offen (>45 Tage) ---"; $offen | Select-Object DisplayName, Mail, CreatedDateTime
```

Die beiden Kategorien werden getrennt gefiltert, damit offene Einladungen nicht als inaktive Gäste doppelt erscheinen. Gäste mit offener Einladung haben naturgemäß keine Anmeldung.

**Lösung 8.** Vorgehen: Zuerst klären, ob sich etwas geändert hat (Überwachungsprotokoll nach Änderungen an Verzeichniseinstellungen in den letzten 24 Stunden filtern). Mögliche Ursachen: Erstens wurde die Einschränkung der Gruppenerstellung auf eine Sicherheitsgruppe aktiviert; Administratorrollen sind ausgenommen, was erklärt, warum zwei Administratoren weiterhin können (Verzeichniseinstellung `Group.Unified` prüfen). Zweitens ist die Änderung noch nicht überall wirksam oder umgekehrt erst jetzt angekommen, da sie mindestens 30 Minuten braucht. Drittens könnte eine Namensrichtlinie oder eine gesperrte Wortliste neue Teams ablehnen (Fehlermeldung des Anlegens ansehen). Viertens könnte eine Teams-Richtlinie oder eine Lizenzänderung die Erstellung verhindern. Das Ergebnis wird im Ticket dokumentiert und die Ursache im Betriebshandbuch ergänzt.
