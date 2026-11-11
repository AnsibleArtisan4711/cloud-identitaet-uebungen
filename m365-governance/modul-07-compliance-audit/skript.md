# Modul 07 - Compliance, Audit und Risk Management

> **Hinweis zu diesem Kapitel:** Das ist das Kapitel des Skripts „M365 Governance – Lernmodule nach Lehrplan“, aus der LaTeX-Quelle in Markdown umgewandelt (Text und Listings unverändert, Boxen als Zitatblöcke, Aufgaben fortlaufend nummeriert). Die Listings sind **nicht gegen einen echten Tenant ausgeführt**. Die getesteten Fassungen und bekannte Probleme einzelner Listings stehen im [README dieses Moduls](README.md) und in `skripte/`.

**Dauer:** 9 Stunden laut Blatt „Lehrplan in Modulen“. Die acht Lerneinheiten im Blatt „Lehrplan in Details“ summieren sich auf 8 Stunden (8 × 1). Als Richtwert für den Umfang wurde der höhere Wert (9 Stunden) verwendet.  
**Priorität:** 1 (höchste Priorität)

| **Nr.** | **Lerneinheit**            | **Dauer (h)** | **Prio** |
|:--------|:---------------------------|--------------:|---------:|
| 7.1     | Audit Logs                 |             1 |        1 |
| 7.2     | eDiscovery                 |             1 |        1 |
| 7.3     | Compliance Manager         |             1 |        1 |
| 7.4     | Insider Risk               |             1 |        1 |
| 7.5     | Communication Compliance   |             1 |        1 |
| 7.6     | Legal Hold                 |             1 |        2 |
| 7.7     | Regulatory Mapping         |             1 |        2 |
| 7.8     | Compliance-Troubleshooting |             1 |        2 |
|         | **Summe laut Details**     |         **8** |          |
|         | **Dauer laut Modulblatt**  |         **9** |          |

> **Merke: Rechtliche Hinweise und Beispielcode**
>
> Dieses Modul berührt Datenschutz, Arbeitsrecht und Aufbewahrungspflichten. Alle rechtlichen Aussagen dienen der Orientierung und sind keine Rechtsberatung; verbindliche Auskünfte erteilen Rechtsabteilung, Datenschutzbeauftragte und Betriebsrat. Die Funktionen Insider Risk und Communication Compliance verarbeiten personenbezogene Daten von Beschäftigten und dürfen in vielen Organisationen nur mit Beteiligung des Betriebsrats und einer Datenschutz-Folgenabschätzung eingeführt werden. Die Codebeispiele folgen Mustern der Microsoft-Dokumentation und wurden nicht gegen einen echten Tenant ausgeführt.

Während Modul 6 den Schutz der Daten behandelt, geht es hier um den Nachweis und die Untersuchung: Was ist passiert (Audit), wie finden und sichern wir Beweise (eDiscovery, Legal Hold), erfüllen wir unsere Pflichten (Compliance Manager, Regulatory Mapping), und wie erkennen wir Risiken von innen (Insider Risk, Communication Compliance)? Die Rollen und Berechtigungen für diese Funktionen gehören zu den sensibelsten im Tenant und werden in Modul 2 (Rollen, PIM) und Modul 8 (Privileged Access) mitgedacht.

## 7.1 Audit Logs

Ein *Audit-Log* (Überwachungsprotokoll) beantwortet die Frage „Wer hat wann was getan?“. In Microsoft 365 werden Aktivitäten in Exchange, SharePoint, OneDrive, Teams, Entra und vielen weiteren Diensten in einem gemeinsamen Protokoll erfasst, das man *einheitliches Überwachungsprotokoll* (Unified Audit Log) nennt. Jede Aktivität ist ein Eintrag mit Zeitpunkt, Benutzer, Operation (zum Beispiel „Datei gelöscht“, „Freigabelink erstellt“, „Postfach-Regel angelegt“), betroffenem Objekt und Zusatzinformationen. Das Protokoll ist die Grundlage fast jeder Untersuchung: Es klärt, ob ein Vorfall tatsächlich stattgefunden hat, wer beteiligt war und welchen Umfang er hatte.

Zwei Dinge sind für die Governance wichtig. Erstens ist die *Aufbewahrungsdauer* der Protokolleinträge begrenzt und hängt von Lizenz und Konfiguration ab. Das Standardprotokoll hält Einträge deutlich kürzer als das erweiterte (Audit Premium), das längere Aufbewahrung und zusätzliche Ereignisse bietet. Wer ein Ereignis nach Ablauf der Frist untersuchen will, hat Pech. Zweitens muss die Erfassung eingeschaltet sein und die zuständigen Personen brauchen die passende Rolle. Wer das Protokoll durchsuchen darf, ist eine bewusste Entscheidung, denn das Protokoll enthält Informationen über das Verhalten aller Mitarbeitenden.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Überwachungslösungen in Purview beschreibt zwei Stufen, Audit (Standard) und Audit (Premium). Beim Standardprotokoll ist die Aufbewahrungsdauer nach der Dokumentation zum Abrufzeitpunkt 180 Tage; Audit (Premium) erweitert dies je nach Lizenz auf ein Jahr und bietet zusätzlich Aufbewahrungsrichtlinien für Protokolleinträge sowie Ereignisse mit hoher Bedeutung für Untersuchungen (etwa das Lesen von Mails). Die Suche ist im Purview-Portal und per PowerShell (`Search-UnifiedAuditLog`) möglich, außerdem über eine Programmierschnittstelle. Wegen möglicher Änderungen bei Fristen und Lizenzen gilt: Prüfen Sie die Angaben in der aktuellen Dokumentation, bevor Sie sie in einem Nachweiskonzept festschreiben.

Wie sucht man sinnvoll? Die wichtigste Regel lautet: Eingrenzen, bevor man sucht. Ein Zeitraum, ein Benutzer oder eine Operation reduziert die Treffermenge auf ein Maß, das man auswerten kann. Eine Suche über „alle Aktivitäten der letzten 90 Tage“ liefert Hunderttausende Einträge und bringt weder Klarheit noch Geschwindigkeit. Die Treffer enthalten ein Feld `AuditData` mit einer JSON-Struktur, die Einzelheiten wie Dateiname, Website-URL, Client-IP und Benutzer-Agent enthält. Für Auswertungen wandelt man dieses Feld in Objekte um.

Das folgende Skript prüft zunächst, ob die Erfassung eingeschaltet ist, und schaltet sie gegebenenfalls ein. Danach sucht es die Löschvorgänge von Dateien in SharePoint und OneDrive für einen bestimmten Benutzer in den letzten sieben Tagen und gibt eine lesbare Tabelle aus. Das Cmdlet `Search-UnifiedAuditLog` gehört zum Modul `ExchangeOnlineManagement`. Die Parameter `-ResultSize` und `-SessionId` sorgen für saubere Seitenabfrage bei großen Mengen.

**Search-FileDeletions.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Benutzer,
    [int]$Tage = 7
)

Connect-ExchangeOnline

$config = Get-AdminAuditLogConfig
if (-not $config.UnifiedAuditLogIngestionEnabled) {
    Write-Warning "Audit-Erfassung ist ausgeschaltet. Wird eingeschaltet."
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
}

$ende  = (Get-Date).ToUniversalTime()
$start = $ende.AddDays(-$Tage)

$treffer = Search-UnifiedAuditLog -StartDate $start -EndDate $ende `
    -UserIds $Benutzer `
    -Operations FileDeleted, FileRecycled `
    -ResultSize 5000 -SessionId ("del-" + (Get-Date -Format yyyyMMddHHmmss)) `
    -SessionCommand ReturnLargeSet

$treffer | ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{
        Zeit      = $_.CreationDate
        Benutzer  = $_.UserIds
        Operation = $_.Operations
        Datei     = $d.SourceFileName
        Website   = $d.SiteUrl
        ClientIP  = $d.ClientIP
    }
} | Sort-Object Zeit | Format-Table -AutoSize

Write-Host ("Treffer: {0}" -f @($treffer).Count)
```

Die Wirkung der wichtigen Zeilen: `Get-AdminAuditLogConfig` liest, ob die Erfassung läuft; ist sie aus, schaltet `Set-AdminAuditLogConfig` sie ein (bereits erfasste Zeiträume fehlen dann natürlich). Die Zeiten werden in UTC angegeben, weil das Protokoll in UTC arbeitet. `-Operations` begrenzt auf Löschvorgänge. `-SessionCommand ReturnLargeSet` zusammen mit einer `-SessionId` erlaubt wiederholte Abfragen für große Mengen. Die Schleife wandelt das JSON-Feld in Objekte um und baut daraus eine übersichtliche Tabelle.

### Typische Fehler und Stolperfallen.

Ein häufiger Fehler ist, ein Ereignis zu suchen, das gerade erst passiert ist: Protokolleinträge erscheinen mit Verzögerung, und die Suche zeigt sie nicht sofort. Ein zweiter Fehler ist die Zeitzone: Wer Lokalzeit und UTC verwechselt, sucht im falschen Fenster. Ein dritter Fehler ist, eine Treffermenge von 5000 für vollständig zu halten, obwohl die Grenze erreicht wurde. Ein vierter Fehler ist organisatorisch: Wer ohne Anlass im Protokoll nach einer Person sucht, verletzt unter Umständen den Datenschutz.

**Falsch und richtig: Grenze und Zeitraum**

```powershell
# FALSCH: zu grosser Zeitraum, einmalige Abfrage, Grenze unbemerkt
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-90) -EndDate (Get-Date)

# RICHTIG: eingrenzen, UTC, Seitenabfrage fuer grosse Mengen
$r = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-2).ToUniversalTime() `
    -EndDate (Get-Date).ToUniversalTime() -UserIds "anna@contoso.com" `
    -Operations FileDeleted -ResultSize 5000 -SessionId "s1" -SessionCommand ReturnLargeSet
```

Der Vergleich zeigt: Das Gegenbeispiel grenzt Zeitraum, Benutzer und Operation ein, verwendet UTC und die Seitenabfrage. Prüfen Sie immer, ob die Trefferzahl genau 5000 beträgt; dann fehlen möglicherweise weitere Einträge.

### Praxisbezug.

Im Projekt taucht das Audit-Log in drei Rollen auf: als Untersuchungswerkzeug (Vorfall), als Nachweis (Auditor fragt „Wer hat Adminrechte vergeben?“) und als Datenquelle für Monitoring (Modul 9). Legen Sie fest, wer suchen darf, wofür gesucht werden darf und wie Suchen dokumentiert werden. Bei Beschäftigtendaten ist eine Betriebsvereinbarung üblich.

> **Praxisbeispiel**
>
> Nach einer Meldung über verschwundene Projektdateien sucht die Administration im Protokoll nach Löschereignissen der betroffenen Website. Sie findet, dass ein Synchronisierungsclient eines ausgeschiedenen Mitarbeiters 800 Dateien verschoben hat. Die Dateien lassen sich aus dem Papierkorb wiederherstellen. Die Lehre: Ohne Protokoll wäre die Ursache nicht auffindbar gewesen, und ohne Offboarding-Prozess (Modul 2) hätte das Konto gar nicht mehr aktiv sein dürfen.

## 7.2 eDiscovery

*eDiscovery* (electronic discovery, elektronische Beweissicherung) bezeichnet das Auffinden, Sichern, Prüfen und Herausgeben elektronisch gespeicherter Informationen für rechtliche Verfahren, Untersuchungen oder Auskunftsersuchen. Typische Anlässe sind Rechtsstreitigkeiten, interne Ermittlungen, behördliche Anfragen oder Auskunftsrechte von Betroffenen. Der Kern ist ein geordneter Prozess: identifizieren, sichern, sammeln, prüfen, herausgeben. Ein Tool, das nur sucht, genügt dafür nicht; es braucht Zugriffssteuerung, Nachvollziehbarkeit und Unveränderbarkeit der gesicherten Daten.

Microsoft Purview bietet dafür Stufen an. Die Standardstufe arbeitet mit *Fällen* (Cases), in denen man Mitglieder bestimmt, Suchen durchführt und Ergebnisse exportiert. Die Premiumstufe ergänzt Verwaltung von Verwahrern (Custodians), Benachrichtigungen, Prüfungssätze (Review Sets) mit Analysen wie Duplikaterkennung und E-Mail-Threading sowie Funktionen zur Vorbereitung für die Herausgabe. Welche Stufe man braucht, entscheiden Fallhäufigkeit und Datenmenge: Für gelegentliche Anfragen genügt Standard, für Prozessführung mit großen Datenmengen braucht man Premium.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu eDiscovery in Purview ist der Zugriff an Rollen gebunden (zum Beispiel die Rollengruppe eDiscovery-Manager), und Fälle haben eigene Mitglieder, sodass nicht jeder Administrator jeden Fall sehen kann. Suchen können Exchange-Postfächer, SharePoint-Websites, OneDrive-Konten und Teams-Inhalte einbeziehen, und Ergebnisse lassen sich in der Vorschau ansehen oder exportieren. Die Funktionen und Bezeichnungen (klassische Suche, neues Erlebnis, Standard, Premium) haben sich geändert; prüfen Sie daher für Ihren Tenant, welches Erlebnis aktiv ist, und lesen Sie die Lizenzangaben der Dokumentation nach.

Warum gehört das in ein Governance-Modul? Weil eDiscovery das mächtigste Werkzeug zum Lesen fremder Inhalte ist. Mit einer Suche kann man die Postfächer und Dateien aller Mitarbeitenden durchsuchen. Deshalb muss die Governance regeln: Wer darf Fälle anlegen (wenige, benannte Personen), wer genehmigt eine Suche (Rechtsabteilung, Datenschutz), wie wird die Suche begründet und protokolliert, wie lange bleiben Exportdaten bestehen und wo werden sie gespeichert? Ein Export in einen Ordner auf einem Laufwerk ohne Zugriffsbeschränkung ist ein eigenes Datenschutzrisiko. Ebenso wichtig: Die Suche folgt dem Prinzip der Erforderlichkeit, und der Suchumfang ist so eng wie möglich.

Das Skript legt einen Fall an, erstellt eine Suche in einem Postfach nach einem Stichwort in einem Zeitraum, startet sie und gibt eine Schätzung der Trefferzahl aus. Der Fall ist in der Standardstufe der Rahmen für Suche und Export. Die Suchabfrage verwendet die Schlüsselwortabfragesprache (KQL) mit Datumsfilter. Der Export als eigener Schritt wird bewusst nicht automatisiert, denn er soll nach Genehmigung erfolgen.

**New-EDiscoverySearch.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Fall,
    [Parameter(Mandatory)][string]$Postfach,
    [Parameter(Mandatory)][string]$Stichwort,
    [Parameter(Mandatory)][string]$Von,      # z. B. 2026-01-01
    [Parameter(Mandatory)][string]$Bis       # z. B. 2026-06-30
)

Connect-IPPSSession

if (-not (Get-ComplianceCase -Identity $Fall -ErrorAction SilentlyContinue)) {
    New-ComplianceCase -Name $Fall -Description "Angelegt per Skript, Genehmigung siehe Ticket"
}

$abfrage = "($Stichwort) AND (Date>=$Von) AND (Date<=$Bis)"
New-ComplianceSearch -Name "$Fall - Suche 1" -Case $Fall `
    -ExchangeLocation $Postfach -ContentMatchQuery $abfrage
Start-ComplianceSearch -Identity "$Fall - Suche 1"

do {
    Start-Sleep -Seconds 15
    $s = Get-ComplianceSearch -Identity "$Fall - Suche 1"
} while ($s.Status -ne "Completed")

"{0}: {1} Elemente, {2} Bytes" -f $s.Name, $s.Items, $s.Size
```

Das Skript prüft zuerst, ob der Fall existiert, und legt ihn sonst an. Die Abfrage kombiniert Stichwort und Zeitraum. `New-ComplianceSearch` mit `-Case` bindet die Suche an den Fall, damit nur dessen Mitglieder sie sehen. Die Schleife wartet, bis die Suche abgeschlossen ist, und gibt dann Elementzahl und Größe aus. Ein Export würde mit `New-ComplianceSearchAction -Export` folgen, nach Freigabe durch die zuständige Stelle.

### Typische Fehler und Stolperfallen.

Die häufigsten Fehler sind zu breite Suchen („alle Postfächer, kein Zeitraum“), das Fehlen einer Genehmigung, Exporte an unsichere Orte und unvollständige Quellen: Wer nur Exchange durchsucht, übersieht Teams-Chats, Dateien in OneDrive oder gelöschte Elemente. Außerdem gilt: Ohne zusätzliche Sicherung (Legal Hold, Lerneinheit 7.6) kann der Benutzer Inhalte löschen, während die Suche läuft.

**Falsch und richtig: Suchumfang**

```powershell
# FALSCH: alles, ohne Zeitraum, ohne Fall
New-ComplianceSearch -Name "Alles" -ExchangeLocation All -ContentMatchQuery "Vertrag"

# RICHTIG: eng, mit Zeitraum, im Fall, nur die betroffene Person
New-ComplianceSearch -Name "F-2026-14 Suche 1" -Case "F-2026-14" `
    -ExchangeLocation "anna@contoso.com" `
    -ContentMatchQuery "(Vertrag) AND (Date>=2026-01-01) AND (Date<=2026-06-30)"
```

Der Unterschied liegt in Erforderlichkeit und Nachvollziehbarkeit. Die enge Suche erzeugt weniger Daten, weniger Risiko und ein klares Protokoll, das einen Fall belegt.

### Praxisbezug.

In der Praxis wird eDiscovery selten von der IT allein ausgelöst. Typischer Auslöser ist die Rechtsabteilung, ein Datenschutzbeauftragter (Auskunftsanfrage) oder die Revision. Die IT stellt Werkzeug und Rollenvergabe, die anfragende Stelle liefert Zweck und Genehmigung. Ein einfaches Formular „eDiscovery-Antrag“ mit Zweck, Personenkreis, Zeitraum, Genehmigung, Löschfrist für Exportdaten bewährt sich.

## 7.3 Compliance Manager

Wer Compliance nachweisen muss, braucht mehr als technische Einstellungen. Eine Auditorin fragt nicht „Haben Sie DLP?“, sondern „Welche Anforderung der Norm erfüllt das, wer ist verantwortlich, wo ist der Beleg?“. Der *Compliance Manager* in Purview ist ein Werkzeug für genau diese Übersetzung. Er bringt Rechts- und Normenanforderungen (Verordnungen, Standards) in eine Struktur aus *Bewertungen* (Assessments), *Kontrollen* und *Verbesserungsmaßnahmen* (Improvement Actions) und berechnet daraus einen *Compliance-Score*.

Die Begriffe im Zusammenhang: Eine *Vorlage* (Template) enthält die Anforderungen einer Regelung. Aus ihr erzeugt man eine Bewertung für die eigene Organisation. Jede Bewertung hat Kontrollen, die in Maßnahmen heruntergebrochen sind. Maßnahmen sind entweder von Microsoft verwaltet (der Dienst erfüllt sie, mit Nachweis), vom Kunden zu erfüllen (zum Beispiel eine Richtlinie einführen) oder gemeinsam. Für jede Maßnahme kann man Verantwortliche, Status, Testergebnisse und Belege (Dokumente) hinterlegen. Der Score zeigt den Umsetzungsgrad; er ist eine Orientierungsgröße und kein Zertifikat.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation beschreibt den Compliance Manager als Lösung, die Anforderungen in Bewertungen, Kontrollen und Verbesserungsmaßnahmen übersetzt und den Score berechnet. Ausdrücklich weist die Dokumentation darauf hin, dass der Score und die Maßnahmen Orientierung bieten und keine Garantie für die Erfüllung einer Regelung sind; die Verantwortung bleibt bei der Organisation. Welche Vorlagen verfügbar sind und welche Teile kostenfrei oder lizenzpflichtig sind, ändert sich; prüfen Sie dies im Portal und in der Dokumentation.

Wie nutzt man das Werkzeug im Betrieb? Der Einstieg ist eine Auswahl: Welche Regelungen gelten für uns? Für ein Unternehmen in Österreich oder Deutschland sind das mindestens Datenschutz-Grundverordnung, eventuell ISO 27001, branchenspezifische Vorgaben. Zu jeder gewählten Regelung entsteht eine Bewertung. Die Maßnahmen werden Verantwortlichen zugewiesen, die nicht nur in der IT sitzen: Maßnahmen wie „Datenschutzschulung durchführen“ gehören dem Personalbereich. Dann gleicht man ab, welche Maßnahmen durch Konfigurationen der vorherigen Module bereits erfüllt sind (Labels, DLP, Aufbewahrung, Zugriffsüberprüfung), und hinterlegt Belege.

Weil die Oberfläche die Arbeit übernimmt, ist hier PowerShell weniger zentral. Doch auch Bewertungen lassen sich exportieren, und ein Export in eine Tabelle ist die Grundlage für Berichte an die Leitung. Das folgende Skript liest einen solchen Export (CSV) ein und fasst die Maßnahmen nach Status und Verantwortlichem zusammen. Weil die Spaltennamen eines Exports je nach Version abweichen können, sind sie als Parameter vorgesehen; passen Sie sie an Ihre Datei an.

**Summary-ComplianceActions.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Datei,
    [string]$SpalteStatus = "Status",
    [string]$SpalteOwner  = "Owner",
    [string]$SpalteTitel  = "Title"
)

$zeilen = Import-Csv -Path $Datei -Encoding UTF8
if (-not $zeilen) { throw "Datei enthaelt keine Zeilen: $Datei" }

foreach ($spalte in $SpalteStatus, $SpalteOwner, $SpalteTitel) {
    if ($spalte -notin $zeilen[0].PSObject.Properties.Name) {
        throw "Spalte nicht gefunden: $spalte. Vorhanden: " +
              ($zeilen[0].PSObject.Properties.Name -join ", ")
    }
}

"--- Nach Status ---"
$zeilen | Group-Object $SpalteStatus |
    Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize

"--- Offene Massnahmen je Verantwortlichem ---"
$zeilen | Where-Object { $_.$SpalteStatus -notmatch "Implemented|Umgesetzt|Completed" } |
    Group-Object $SpalteOwner | Sort-Object Count -Descending |
    Select-Object Name, Count | Format-Table -AutoSize
```

Das Skript prüft zuerst, ob die Datei Zeilen enthält und ob die verlangten Spalten vorhanden sind, und bricht sonst mit einer verständlichen Meldung ab. Danach gruppiert es nach Status und zählt dann offene Maßnahmen je Verantwortlichem, wobei Statuswerte wie „Implemented“ oder „Umgesetzt“ als erledigt gelten. Das Ergebnis eignet sich als Zahlen für den Quartalsbericht.

### Typische Fehler und Stolperfallen.

Der verbreitetste Fehler ist, den Score als Ziel zu betrachten. Ein hoher Score besagt nicht, dass die Organisation compliant ist, denn Maßnahmen können als umgesetzt markiert sein, ohne dass die Praxis stimmt. Zweitens bleiben Maßnahmen ohne Verantwortliche liegen. Drittens fehlen Belege: Eine Maßnahme ohne Beleg besteht in der Prüfung nicht. Viertens wird Compliance Manager einmalig befüllt und nie gepflegt.

**Falsch und richtig: Datei lesen**

```powershell
# FALSCH: Spaltennamen geraten, keine Pruefung
Import-Csv .\export.csv | Group-Object Status

# RICHTIG: pruefen, ob die Spalte existiert, sonst klar abbrechen
$z = Import-Csv .\export.csv
if ("Status" -notin $z[0].PSObject.Properties.Name) { throw "Spalte Status fehlt" }
$z | Group-Object Status
```

Das Beispiel zeigt die Haltung für Auswertungsskripte: Annahmen über Datenformate werden geprüft, nicht vorausgesetzt. Sonst entsteht ein leeres Ergebnis, das niemand hinterfragt.

### Praxisbezug.

Compliance Manager wird dann wichtig, wenn Kunden oder Auditoren Nachweise verlangen (Lieferantenfragebögen, Zertifizierung, Prüfung durch Revision). Praktisch ist die Verknüpfung mit Regulatory Mapping (Lerneinheit 7.7): Zuerst klärt man, welche Anforderungen bestehen, dann bildet man sie auf Maßnahmen und Belege ab.

## 7.4 Insider Risk

Die meisten Sicherheitswerkzeuge schauen nach außen: Angreifer, Schadsoftware, gestohlene Zugänge. Ein erheblicher Teil der Schäden entsteht jedoch von innen, durch Beschäftigte, die absichtlich oder versehentlich Daten abfließen lassen, Regeln umgehen oder in Konflikt mit der Organisation geraten. *Insider-Risikomanagement* (Insider Risk Management) in Purview erkennt solche Muster über Signale aus der Zusammenarbeit: Dateien, die massenhaft heruntergeladen oder auf externe Medien kopiert werden, E-Mails mit Anhängen an private Adressen, Zugriffe auf ungewöhnlich viele sensible Dateien kurz vor dem Ausscheiden.

Der Aufbau folgt einer Kette. *Richtlinien* werden meist aus Vorlagen erzeugt (zum Beispiel „Datendiebstahl durch ausscheidende Benutzer“, „Datenlecks“, „Verstöße gegen Sicherheitsrichtlinien“). Eine Richtlinie legt fest, welche Benutzer betrachtet werden, welche Indikatoren (Aktivitäten) zählen und mit welcher Gewichtung. Überschreitet das Verhalten Schwellen, entsteht eine *Warnung* (Alert) mit einem Risikowert. Prüfer sichten die Warnung und entscheiden: verwerfen oder einen *Fall* (Case) eröffnen, der weiter untersucht und gegebenenfalls an Personal, Recht oder Sicherheit übergeben wird. Zusätzliche Signale kann ein *HR-Konnektor* liefern, der Kündigungen oder Leistungsdaten aus dem Personalsystem einspeist; so erkennt die Richtlinie die kritische Phase vor dem Ausscheiden.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Insider-Risikomanagement betont Datenschutz als Teil des Entwurfs: Benutzernamen können standardmäßig pseudonymisiert dargestellt werden, es gibt eigene Rollengruppen mit getrennten Aufgaben (Administratoren, Analysten, Prüfer), und Aktionen werden im Überwachungsprotokoll festgehalten. Die Dokumentation weist darauf hin, dass Organisationen vor dem Einsatz rechtliche und arbeitsrechtliche Aspekte prüfen sollten. Welche Indikatoren, Vorlagen und Lizenzvoraussetzungen aktuell gelten, ist im Portal und in der Dokumentation nachzulesen, da sie sich ändern.

Aus Governance-Sicht ist dieses Thema vor allem eine Frage der Verhältnismäßigkeit. Technisch lässt sich vieles erkennen; ob und wie man es darf und wollen sollte, entscheidet die Organisation gemeinsam mit Datenschutz und Arbeitnehmervertretung. Ein tragfähiges Vorgehen umfasst: einen dokumentierten Zweck (Schutz von Betriebsgeheimnissen, nicht allgemeine Leistungskontrolle), eine Betriebsvereinbarung beziehungsweise Einbeziehung des Betriebsrats, eine Datenschutz-Folgenabschätzung, Pseudonymisierung als Standard, ein Vier-Augen-Prinzip beim Aufheben der Pseudonymisierung, kurze Aufbewahrung der Warnungen und klare Eskalationswege. Wird dies übersprungen, ist die Technik ein Vertrauensrisiko und kann rechtlich angreifbar sein (keine Rechtsberatung).

Die Einführung erfolgt stufenweise: zuerst ein Pilot mit einer Richtlinie (zum Beispiel für ausscheidende Benutzer) bei einer kleinen Gruppe, dann die Auswertung der Warnungen auf Fehlalarme, dann Feinjustierung der Schwellen. Der HR-Konnektor liefert Datum von Kündigung und letztem Arbeitstag. Die Daten stammen aus dem Personalsystem und werden als Datei im geforderten Format bereitgestellt. Das folgende Skript bereitet eine solche Datei vor: Es liest einen Export aus dem Personalsystem, prüft die Datumsangaben und schreibt eine CSV im Muster der Dokumentation (Benutzerkennung, Kündigungsdatum, letzter Arbeitstag). Das genaue Spaltenschema und der Upload-Mechanismus des Konnektors sind in der aktuellen Dokumentation zu prüfen; das Skript zeigt das Vorgehen.

**Convert-HrExport.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Eingabe,   # Export aus dem Personalsystem
    [string]$Ausgabe = ".\HR-Konnektor.csv"
)

$ergebnis = foreach ($z in Import-Csv -Path $Eingabe -Delimiter ';' -Encoding UTF8) {
    $kuendigung = $null; $letzter = $null
    if (-not [datetime]::TryParseExact($z.Kuendigung, 'dd.MM.yyyy', $null, 'None', [ref]$kuendigung) -or
        -not [datetime]::TryParseExact($z.LetzterTag, 'dd.MM.yyyy', $null, 'None', [ref]$letzter)) {
        Write-Warning "Datum ungueltig fuer $($z.UPN) - Zeile uebersprungen"
        continue
    }
    if ($letzter -lt $kuendigung) {
        Write-Warning "Letzter Tag vor Kuendigung fuer $($z.UPN) - Zeile uebersprungen"
        continue
    }
    [pscustomobject]@{
        UserPrincipalName = $z.UPN
        ResignationDate   = $kuendigung.ToString('yyyy-MM-dd')
        LastWorkingDate   = $letzter.ToString('yyyy-MM-dd')
    }
}

$ergebnis | Export-Csv -Path $Ausgabe -NoTypeInformation -Encoding UTF8
"{0} Datensaetze geschrieben nach {1}" -f @($ergebnis).Count, $Ausgabe
```

Die Schleife liest die Personalexport-Datei mit Semikolon als Trenner. `TryParseExact` wandelt deutsche Datumsangaben sicher um und liefert bei Fehlern keinen Absturz, sondern eine Warnung mit Überspringen der Zeile. Die zweite Prüfung fängt logisch unmögliche Daten ab. Die Ausgabe nutzt das internationale Datumsformat. Das Beispiel zeigt auch das Datenschutzprinzip der Datensparsamkeit: Es werden nur die drei nötigen Spalten weitergegeben, keine Gehälter oder Beurteilungen.

### Typische Fehler und Stolperfallen.

Die häufigsten Fehler sind organisatorisch: Einführung ohne Betriebsrat, Zweck nicht festgelegt, zu viele Prüfer mit Einsicht, Pseudonymisierung abgeschaltet. Technisch sind es zu niedrige Schwellen (Warnungsflut), falsche Datumsformate im HR-Konnektor und fehlende Abstimmung mit dem Offboarding-Prozess. Ein weiteres Problem sind Fehlinterpretationen: Ein hoher Risikowert ist ein Hinweis, kein Beweis, und darf nicht allein zu arbeitsrechtlichen Maßnahmen führen.

**Falsch und richtig: Datenminimierung**

```powershell
# FALSCH: gesamten Personalexport weitergeben
Copy-Item .\Personalexport.csv .\HR-Konnektor.csv

# RICHTIG: nur benoetigte Spalten, gepruefte Daten
Import-Csv .\Personalexport.csv -Delimiter ';' |
  Select-Object @{n='UserPrincipalName';e={$_.UPN}},
                @{n='ResignationDate';e={([datetime]$_.Kuendigung).ToString('yyyy-MM-dd')}},
                @{n='LastWorkingDate';e={([datetime]$_.LetzterTag).ToString('yyyy-MM-dd')}} |
  Export-Csv .\HR-Konnektor.csv -NoTypeInformation -Encoding UTF8
```

Die Korrektur reduziert die Daten auf das Notwendige. Auch hier gilt, dass das gezeigte Datumsparsing im richtigen Projekt mit Fehlerbehandlung ausgestattet sein sollte, wie im vollständigen Skript oben.

### Praxisbezug.

Im Projekt bekommen Sie das Thema meist von der Sicherheitsleitung oder vom Datenschutz: „Wir wollen Datenabfluss beim Ausscheiden erkennen.“ Ihre Aufgabe ist, die Erwartung zu rahmen: Was wird erkannt, wer sieht was, wie lange, mit welcher Beteiligung der Arbeitnehmervertretung? Die Technik ist in einem Tag eingerichtet, die Governance dahinter braucht Wochen.

## 7.5 Communication Compliance

Nicht nur Dateien, auch Kommunikation unterliegt Regeln: Banken müssen Beratungsgespräche überwachen, Unternehmen wollen Belästigung und Diskriminierung erkennen, Behörden Vertraulichkeit in Schriftverkehr wahren. *Communication Compliance* in Purview analysiert Nachrichten in E-Mail, Teams, Viva Engage und weiteren Kanälen auf unangemessene oder regelwidrige Inhalte und führt Treffer zur Prüfung zu. Wie bei Insider Risk ist die Technik klein im Vergleich zu den Fragen von Recht und Vertrauen.

Eine *Richtlinie* besteht aus drei Entscheidungen. Welche Personen werden überwacht (alle oder bestimmte Gruppen, wobei die Auswahl begründet sein muss)? Welche Kommunikation wird geprüft (Kanäle, Richtung, Mindestlänge, Ausnahmen)? Welche Bedingungen lösen einen Treffer aus (Schlüsselwörter, Klassifizierer für Beleidigung oder Drohung, Typen vertraulicher Informationen, Dateitypen)? Dazu kommen die Prüfer, die Treffer sehen und bearbeiten: Sie können als in Ordnung markieren, eskalieren, Hinweise an die betroffene Person senden oder einen Verstoß melden. Alle Aktionen sind nachvollziehbar.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zu Communication Compliance nennt als Voraussetzungen unter anderem Rollengruppen für Administratoren, Analysten, Prüfer und Betrachter sowie die Möglichkeit, Benutzer zu pseudonymisieren. Sie beschreibt ausdrücklich, dass die Funktion die Einhaltung gesetzlicher und interner Regeln unterstützen soll, und verweist darauf, dass Datenschutz- und Arbeitsrecht der jeweiligen Länder zu beachten sind. Welche Klassifizierer und Kanäle unterstützt werden und welche Lizenzen nötig sind, ändert sich; prüfen Sie das im Portal und in der Dokumentation.

Die wichtigste Entwurfsentscheidung lautet: Welche Gruppen von Menschen und welche Kommunikationsarten sind zulässig überwacht? Der Zweck muss konkret sein (Einhaltung von Wertpapier-Compliance für Handelsbereiche, Schutz vor Belästigung in öffentlichen Kanälen), nicht „alles“. Private Kommunikation, Betriebsratskommunikation und besondere Kategorien (zum Beispiel Gesundheit) verlangen besondere Sorgfalt oder sind auszuschließen. Die Information der Beschäftigten ist verpflichtend im Sinne der Transparenz: Sie müssen wissen, dass und wofür überwacht wird (keine Rechtsberatung, Details mit Datenschutz und Recht klären).

Technisch ist das Berechtigungskonzept ein guter Einstieg. Die Rollengruppen trennen die Aufgaben so, dass die Person, die Richtlinien einrichtet, nicht automatisch die Nachrichten lesen darf. Das Skript prüft die Mitgliedschaften der zugehörigen Rollengruppen und zeigt auf, wer Zugriff hat. Es ist ein typischer Governance-Prüfschritt (Segregation of Duties): Eine Person darf nicht Administrator und Prüfer zugleich sein. Die Namen der Rollengruppen sind der Dokumentation entnommen und sind in Ihrem Tenant zu prüfen.

**Test-CommunicationComplianceRoles.ps1**

```powershell
Connect-IPPSSession

$gruppen = "Communication Compliance Admins",
           "Communication Compliance Analysts",
           "Communication Compliance Investigators",
           "Communication Compliance Viewers"

$zuordnung = foreach ($g in $gruppen) {
    $rg = Get-RoleGroup -Identity $g -ErrorAction SilentlyContinue
    if (-not $rg) { Write-Warning "Rollengruppe nicht gefunden: $g"; continue }
    Get-RoleGroupMember -Identity $g | ForEach-Object {
        [pscustomobject]@{ Gruppe = $g; Mitglied = $_.Name }
    }
}

$zuordnung | Sort-Object Gruppe, Mitglied | Format-Table -AutoSize

"--- Personen in Admin-Gruppe UND Pruefergruppe ---"
$admins = $zuordnung | Where-Object Gruppe -like "*Admins"        | Select-Object -ExpandProperty Mitglied
$pruefer = $zuordnung | Where-Object Gruppe -like "*Investigators" | Select-Object -ExpandProperty Mitglied
$admins | Where-Object { $_ -in $pruefer }
```

Das Skript sammelt die Mitglieder der vier Gruppen, gibt sie als Tabelle aus und bildet am Ende die Schnittmenge aus Administratoren und Prüfern. Eine nicht leere Schnittmenge ist ein Befund für das Berechtigungsreview. Fehlende Gruppen melden eine Warnung statt eines Abbruchs, damit das Skript auch bei abweichenden Namen läuft.

### Typische Fehler und Stolperfallen.

Typische Fehler sind: zu viele Überwachte ohne Zweck, Schlüsselwortlisten, die massenhaft Treffer erzeugen („Vertrag“, „Kunde“), Prüfer ohne Schulung, fehlende Transparenz gegenüber Beschäftigten, keine Löschfrist für Treffer. Wer die Technik als Stimmungsbarometer missbraucht, verliert Vertrauen und riskiert rechtliche Konsequenzen.

**Falsch und richtig: Trennung der Aufgaben**

```powershell
# FALSCH: eine Person in Admin- und Pruefergruppe
Add-RoleGroupMember -Identity "Communication Compliance Admins" -Member "anna@contoso.com"
Add-RoleGroupMember -Identity "Communication Compliance Investigators" -Member "anna@contoso.com"

# RICHTIG: getrennte Personen, Pruefer aus Recht/Personal
Add-RoleGroupMember -Identity "Communication Compliance Admins" -Member "it.admin@contoso.com"
Add-RoleGroupMember -Identity "Communication Compliance Investigators" -Member "recht@contoso.com"
```

Das Gegenbeispiel setzt die Funktionstrennung durch. Ergänzend hilft ein regelmäßiges Berechtigungsreview, wie es in Modul 2 für Rollen beschrieben ist.

### Praxisbezug.

Typische Einsatzfelder sind regulierte Finanzunternehmen (Aufsicht über Handelskommunikation) und Organisationen mit Verhaltenskodex. Vor dem technischen Projekt liegt ein Projekt für Betriebsvereinbarung und Information. Planen Sie die Pilotphase mit Testdaten und einer kleinen, informierten Gruppe.

## 7.6 Legal Hold

Ein *Legal Hold* (rechtliche Sperre, Aufbewahrungspflicht im Verfahren) friert Inhalte ein, die für ein laufendes oder absehbares Verfahren relevant sind. Er verhindert, dass Beweismittel gelöscht oder verändert werden, selbst wenn der Benutzer sie löscht oder eine Aufbewahrungsrichtlinie sie entsorgen würde. Rechtlich entsteht die Pflicht dazu, sobald ein Verfahren absehbar ist; wer zu spät sichert, riskiert Nachteile (keine Rechtsberatung, die Auslösung klärt die Rechtsabteilung). Technisch ist ein Hold eine Aufbewahrung ohne Ablaufdatum, die so lange gilt, bis jemand sie ausdrücklich aufhebt.

In Purview gibt es mehrere Wege. Die zeitgemäße Variante ist die Sperre innerhalb eines eDiscovery-Falls: Man legt eine *Sperrrichtlinie* (Case Hold Policy) für bestimmte Postfächer, OneDrive-Konten, Websites oder Teams an, optional mit Abfrage (nur Inhalte, die dem Stichwort entsprechen). Die zweite Variante betrifft einzelne Postfächer: *Litigation Hold* an einem Postfach. Die dritte sind Aufbewahrungsrichtlinien, die nicht als Legal Hold gedacht sind und deren Dauer endet. Für Verfahren verwendet man Case Holds, weil sie dem Fall zugeordnet sind, nachvollziehbar bleiben und sich gezielt aufheben lassen.

> **Ergänzung aus der Nachrecherche**
>
> Nach der Microsoft-Dokumentation zu eDiscovery werden Sperren in einem Fall angelegt und halten Inhalte in den gewählten Orten zurück; bei Exchange werden Kopien im Ordner „Recoverable Items“ aufbewahrt, bei SharePoint und OneDrive in der Bibliothek „Preservation Hold“ (vergleiche Lerneinheit 6.3). Die Dokumentation weist darauf hin, dass sich die Sperre erst nach einer Verteilungszeit auswirkt und dass man den Status der Sperrrichtlinie prüfen soll, bevor man sich auf den Schutz verlässt. Gelöschte Benutzerkonten und deren Postfächer sind ein eigener Sonderfall (inaktive Postfächer); planen Sie das vor dem Offboarding.

Die Governance-Aufgaben rund um Holds sind Auslösung, Dokumentation und Aufhebung. Wer löst aus? Meist Recht, nicht IT. Wo wird das dokumentiert? Im Fallsystem mit Datum, Auslöser, Umfang. Wer hebt auf und wann? Sperren dürfen nicht vergessen werden, denn eine ewige Sperre widerspricht der Datenminimierung. Daher gehört zu jedem Hold ein Prüftermin und ein Verantwortlicher. Außerdem beeinflusst ein Hold Speicherkosten und Lebenszyklusprozesse: Websites und Teams, die gelöscht werden sollen, bleiben im Hintergrund erhalten.

Das Skript legt einen Fall an, erstellt eine Sperrrichtlinie für zwei Postfächer und eine OneDrive-Adresse und fügt eine Regel ohne Abfrage hinzu (alles halten). Danach prüft es den Verteilungsstatus. Die Sperrrichtlinie gehört zum Fall; die Regel legt den Inhalt fest. Für Teams-Inhalte würde man die zugehörigen Postfächer (Chat-Postfächer der Beteiligten, Gruppenpostfach) und Websites angeben.

**New-CaseHold.ps1**

```powershell
param(
    [Parameter(Mandatory)][string]$Fall,
    [Parameter(Mandatory)][string[]]$Postfaecher,
    [string[]]$OneDriveUrls = @()
)

Connect-IPPSSession

if (-not (Get-ComplianceCase -Identity $Fall -ErrorAction SilentlyContinue)) {
    New-ComplianceCase -Name $Fall
}

$hold = "$Fall - Sperre"
New-CaseHoldPolicy -Name $hold -Case $Fall `
    -ExchangeLocation $Postfaecher `
    -SharePointLocation $OneDriveUrls -Enabled $true
New-CaseHoldRule -Name "$hold - Regel" -Policy $hold   # ohne Abfrage: alles halten

Get-CaseHoldPolicy -Identity $hold -DistributionDetail |
    Select-Object Name, Enabled, DistributionStatus
```

Das Skript legt den Fall bei Bedarf an und bildet eine Sperrrichtlinie aus Postfächern und optionalen Websites. `New-CaseHoldRule` ohne Abfrage bedeutet, dass der gesamte Inhalt der Orte gehalten wird. Die letzte Zeile prüft, ob die Verteilung erfolgreich ist. Zum Aufheben setzt man `Set-CaseHoldPolicy -Enabled $false` beziehungsweise entfernt die Richtlinie nach Freigabe durch Recht.

### Typische Fehler und Stolperfallen.

Der schwerste Fehler ist das Nichtstun: Der Hold wird zu spät eingerichtet, Inhalte sind bereits gelöscht. Der zweite Fehler ist ein unvollständiger Umfang (nur Postfach, nicht OneDrive und Teams). Der dritte ist ein vergessener Hold. Der vierte ist die Annahme, ein Hold verhindere das Löschen sichtbar: Der Benutzer sieht die Datei nicht mehr, aber das System hält die Kopie.

**Falsch und richtig: Umfang und Pruefung**

```powershell
# FALSCH: nur Postfach, Status nie geprueft
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -ExchangeLocation "anna@contoso.com"

# RICHTIG: alle relevanten Orte, danach Verteilungsstatus lesen
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -Enabled $true `
    -ExchangeLocation "anna@contoso.com" `
    -SharePointLocation "https://contoso-my.sharepoint.com/personal/anna_contoso_com"
Get-CaseHoldPolicy "Sperre" -DistributionDetail | Select-Object Name, DistributionStatus
```

Die richtige Variante deckt auch OneDrive ab und liest den Status. Zusätzlich gehört ein Eintrag im Fallsystem dazu, der Umfang und Prüftermin festhält.

### Praxisbezug.

Legal Holds sind Fälle, die selten vorkommen und dann sehr schnell gehen müssen. Üben Sie den Ablauf im Trockenlauf: Wer ruft an, wer legt an, wer bestätigt, wer hebt auf? Eine Seite „Legal-Hold-Runbook“ mit den genauen Schritten (Modul 9) spart im Ernstfall Stunden.

## 7.7 Regulatory Mapping

*Regulatory Mapping* bedeutet, rechtliche und normative Anforderungen systematisch auf technische und organisatorische Maßnahmen abzubilden. Es beantwortet die Frage: Welche Anforderung gilt für uns, welche Maßnahme erfüllt sie, wer ist verantwortlich und welcher Nachweis belegt es? Ohne diese Zuordnung ist Compliance ein Gefühl, mit ihr ist sie überprüfbar. Der Lehrplan nennt keine einzelnen Vorschriften, deshalb behandelt diese Lerneinheit das Verfahren und nennt Beispiele, die in Europa häufig relevant sind.

Typische Regelwerke sind die Datenschutz-Grundverordnung (DSGVO), die unter anderem Rechenschaftspflicht, Verzeichnis der Verarbeitungstätigkeiten, technische und organisatorische Maßnahmen, Meldung von Verletzungen des Schutzes personenbezogener Daten und Betroffenenrechte verlangt; für bestimmte Branchen kommen Anforderungen wie DORA im Finanzsektor oder die NIS-2-Richtlinie für wesentliche und wichtige Einrichtungen hinzu, deren Umsetzung in nationales Recht aktuell zu prüfen ist; als Normen sind ISO/IEC 27001 (Informationssicherheits-Managementsystem) und der Kriterienkatalog C5 des BSI verbreitet. Diese Aufzählung stammt aus allgemeinem Fachwissen und wurde nicht abgerufen; sie ist keine Rechtsberatung, und welche Vorschriften für Sie gelten, klärt die Rechtsabteilung.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zum Compliance Manager nennt Vorlagen für verbreitete Regelwerke und Standards, aus denen Bewertungen erzeugt werden können; die Auswahl und die Bezeichnungen verändern sich laufend. Zusätzlich stellt Microsoft Dokumentation zur Verfügung, wie die eigenen Dienste Anforderungen unterstützen (Service Trust Portal). Eine Abbildung auf Ihre Anforderungen ersetzt das nicht: Die Verantwortung für die Erfüllung bleibt bei der Organisation. Prüfen Sie die aktuelle Liste der Vorlagen im Portal.

Das Verfahren besteht aus fünf Schritten. Erstens: Anwendbare Regelwerke und Ziele festlegen (mit Recht). Zweitens: Anforderungen in Kontrollziele zerlegen („Zugriff auf personenbezogene Daten ist auf Berechtigte beschränkt“). Drittens: Jedem Ziel Maßnahmen zuordnen, die in diesem Kurs vorkommen (Zugriffsüberprüfung aus Modul 2, Labels und DLP aus Modul 6, Audit aus 7.1, Conditional Access aus Modul 8). Viertens: Nachweise und Verantwortliche festlegen. Fünftens: Lücken sichtbar machen und mit einem Plan versehen. Das Ergebnis ist eine *Nachweismatrix*, die in einer Tabelle oder im Compliance Manager gepflegt wird.

Das folgende Skript arbeitet mit einer solchen Matrix als CSV (Spalten: Anforderung, Kontrollziel, Massnahme, Verantwortlich, Nachweis, Status). Es erkennt die typischen Lücken: Anforderungen ohne Maßnahme, Maßnahmen ohne Verantwortlichen, ohne Nachweis oder mit Status „offen“. Es liefert damit eine Prüfliste für das nächste Treffen. Die Eingabe verlangt Spaltennamen, die das Skript zuerst prüft.

**Test-EvidenceMatrix.ps1**

```powershell
param([Parameter(Mandatory)][string]$Datei)

$soll = "Anforderung","Kontrollziel","Massnahme","Verantwortlich","Nachweis","Status"
$z = Import-Csv -Path $Datei -Delimiter ';' -Encoding UTF8
if (-not $z) { throw "Keine Zeilen in $Datei" }

$fehlend = $soll | Where-Object { $_ -notin $z[0].PSObject.Properties.Name }
if ($fehlend) { throw "Spalten fehlen: $($fehlend -join ', ')" }

$luecken = foreach ($r in $z) {
    $grund = @()
    if ([string]::IsNullOrWhiteSpace($r.Massnahme))      { $grund += "keine Massnahme" }
    if ([string]::IsNullOrWhiteSpace($r.Verantwortlich)) { $grund += "kein Verantwortlicher" }
    if ([string]::IsNullOrWhiteSpace($r.Nachweis))       { $grund += "kein Nachweis" }
    if ($r.Status -match "offen|open")                   { $grund += "Status offen" }
    if ($grund) {
        [pscustomobject]@{ Anforderung = $r.Anforderung; Kontrollziel = $r.Kontrollziel
                           Luecke = ($grund -join "; ") }
    }
}

if ($luecken) { $luecken | Format-Table -AutoSize -Wrap } else { "Keine Luecken gefunden." }
"{0} von {1} Zeilen mit Luecken" -f @($luecken).Count, @($z).Count
```

Das Skript prüft die Struktur der Datei, durchläuft jede Zeile und sammelt Lückengründe in einer Liste. Nur Zeilen mit mindestens einem Grund werden ausgegeben. Das Ergebnis dient als Arbeitsliste, und die Zahl der Zeilen mit Lücken wird zur Kennzahl (siehe Modul 9, Governance KPIs).

### Typische Fehler und Stolperfallen.

Der häufigste Fehler ist, Regelwerke zu kopieren statt zu verstehen: Eine Tabelle mit 300 Anforderungen ohne Priorisierung wird nie gepflegt. Zweitens wird die IT allein verantwortlich gemacht, obwohl viele Maßnahmen organisatorisch sind. Drittens werden Nachweise nicht festgehalten, und bei der Prüfung fehlt der Beleg. Viertens werden rechtliche Aussagen ohne Prüfung durch Fachleute übernommen.

**Falsch und richtig: Luecken sichtbar machen**

```powershell
# FALSCH: nur zaehlen, was "erledigt" ist
($z | Where-Object Status -eq "erledigt").Count

# RICHTIG: Luecken mit Grund auflisten
$z | Where-Object { -not $_.Nachweis -or -not $_.Verantwortlich } |
    Select-Object Anforderung, Massnahme
```

Die Korrektur dreht den Blick auf die Lücken, weil nur diese Handlungsbedarf anzeigen. Eine Quote erledigter Punkte beruhigt, hilft aber nicht bei der Arbeit.

### Praxisbezug.

Meist kommt der Auftrag von außen: Ein Kunde verlangt eine Bestätigung nach Norm, eine Prüfung steht an, ein Vorfall führt zur Frage nach Maßnahmen. Wer die Nachweismatrix gepflegt hat, beantwortet solche Fragen in Stunden statt Wochen. Pflegen Sie sie parallel zu den Modulen dieses Kurses: Jede neue Richtlinie bekommt einen Eintrag.

## 7.8 Compliance-Troubleshooting

Compliance-Störungen zeigen sich anders als technische: Niemand ruft an, weil etwas nicht funktioniert, sondern ein Prüfer fragt, ein Nachweis fehlt oder eine Suche liefert zu wenig. Das Vorgehen ist dennoch dasselbe wie im restlichen Betrieb: Erwartung klären, Zustand lesen, eingrenzen, genau eine Änderung, dokumentieren. Die typischen Fehlerbilder in diesem Modul lassen sich in vier Klassen einteilen.

Die erste Klasse betrifft das Audit. Einträge fehlen, weil die Erfassung zum Zeitpunkt ausgeschaltet war, weil der Zeitraum außerhalb der Aufbewahrung liegt, weil die Suche zu breit oder zu spät war (Verzögerung), oder weil das Konto keine Berechtigung zur Suche hat. Die zweite Klasse ist eDiscovery: Suchen liefern keine oder zu wenige Treffer, weil Orte fehlen, die Abfrage zu eng oder falsch formuliert ist (Syntax, Zeitraum, Zeitzone), Inhalte noch nicht indiziert sind oder die suchende Person nicht berechtigt ist. Die dritte Klasse sind Holds: Die Sperre wirkt nicht, weil die Verteilung fehlgeschlagen ist, der Ort nicht erfasst wurde oder der Hold zu spät kam. Die vierte Klasse sind Compliance Manager, Insider Risk und Communication Compliance: Es fehlen Daten, weil Konnektoren nicht laufen, Richtlinien im Testmodus sind oder Rollen nicht zugeordnet wurden.

> **Ergänzung aus der Nachrecherche**
>
> Die Microsoft-Dokumentation zur Überwachungsprotokollsuche weist darauf hin, dass Einträge nicht sofort, sondern mit Verzögerung verfügbar sind, dass für die Suche bestimmte Rollen nötig sind und dass die Erfassung aktiv sein muss. Bei eDiscovery nennt sie Rollen, Fallmitgliedschaft und Suchbedingungen als Prüfpunkte. Konkrete Verzögerungszeiten und Grenzwerte (Trefferzahlen, Exportgrößen) stehen dort zum jeweiligen Stand und werden hier absichtlich nicht als feste Zahlen angegeben.

Ein Beispielfall: „Die Suche nach der E-Mail von Anna liefert nichts, obwohl sie sicher existiert.“ Die Analyse beginnt mit der Erwartung (welcher Zeitraum, welche Wörter), dann mit dem Zustand (Postfach in der Suche? Zeitraum? Berechtigung?), dann mit der Abfrage (Stichwort ohne Anführungszeichen, Datumsformat, Zeitzone). Oft hilft eine Gegenprobe mit einer sehr einfachen Abfrage (nur der Absender), um den Fehler einzugrenzen. Danach erweitert man schrittweise. Dokumentiert wird, was geprüft und was geändert wurde.

Das folgende Skript ist ein Gesundheitscheck, den man vor jeder Untersuchung ausführen kann: Es prüft, ob die Audit-Erfassung aktiv ist, ob in den letzten 24 Stunden Einträge gefunden werden, ob offene Fälle existieren und ob Sperrrichtlinien ohne Erfolgsstatus vorhanden sind. Jede Prüfung gibt eine Zeile mit OK oder Hinweis aus, damit das Ergebnis direkt in ein Ticket kopiert werden kann.

**Test-ComplianceHealth.ps1**

```powershell
Connect-ExchangeOnline
Connect-IPPSSession

function Zeile($name, $ok, $info) {
    "{0,-34} {1,-8} {2}" -f $name, $(if ($ok) { "OK" } else { "HINWEIS" }), $info
}

$cfg = Get-AdminAuditLogConfig
Zeile "Audit-Erfassung" $cfg.UnifiedAuditLogIngestionEnabled `
      "UnifiedAuditLogIngestionEnabled = $($cfg.UnifiedAuditLogIngestionEnabled)"

$probe = Search-UnifiedAuditLog -StartDate (Get-Date).ToUniversalTime().AddDays(-1) `
         -EndDate (Get-Date).ToUniversalTime() -ResultSize 5
Zeile "Audit-Eintraege letzte 24 h" (@($probe).Count -gt 0) "Treffer in Stichprobe: $(@($probe).Count)"

$faelle = Get-ComplianceCase | Where-Object Status -eq "Active"
Zeile "Aktive eDiscovery-Faelle" $true "$(@($faelle).Count) aktiv"

$holds = Get-CaseHoldPolicy -DistributionDetail
$schlecht = $holds | Where-Object { $_.DistributionStatus -ne "Success" }
Zeile "Sperrrichtlinien verteilt" (-not $schlecht) `
      "$(@($holds).Count) gesamt, $(@($schlecht).Count) nicht erfolgreich"
```

Die Hilfsfunktion `Zeile` formatiert jede Prüfung einheitlich. Die Audit-Prüfung sucht in einer kleinen Stichprobe, ob in den letzten 24 Stunden überhaupt Einträge entstehen, was Ausfälle der Erfassung sichtbar macht. Die Fallprüfung zählt aktive Fälle, die Hold-Prüfung zeigt Richtlinien, deren Verteilung nicht erfolgreich ist. Die Ausgabe ist bewusst kurz und für Tickets geeignet.

### Typische Fehler und Stolperfallen.

Die häufigsten Fehler: mit zu viel Hast zu viel ändern, mit einem Administratorkonto testen, das mehr darf als der Betroffene, aus dem Fehlen eines Treffers auf Nichtvorhandensein schließen (statt auf Suchfehler), Beweise durch Nachbearbeitung verändern, Ergebnisse nicht dokumentieren. Gerade bei Untersuchungen gilt: erst sichern (Hold), dann suchen, dann auswerten.

**Falsch und richtig: Reihenfolge**

```powershell
# FALSCH: erst suchen und aufraeumen, Hold "spaeter"
Start-ComplianceSearch -Identity "Suche 1"
# ... Benutzer loescht in der Zwischenzeit ...

# RICHTIG: erst sichern, dann suchen
New-CaseHoldPolicy -Name "Sperre" -Case "F-14" -ExchangeLocation "anna@contoso.com" -Enabled $true
New-CaseHoldRule -Name "Sperre Regel" -Policy "Sperre"
Start-ComplianceSearch -Identity "Suche 1"
```

Das Gegenbeispiel stellt die Reihenfolge richtig: Der Hold sichert, bevor jemand Inhalte entfernen kann. Der Verteilungsstatus des Holds ist vor der Auswertung zu prüfen.

### Praxisbezug.

Legen Sie für die vier Klassen je eine Checkliste an und verlinken Sie sie in den Runbooks (Modul 9). Üben Sie zweimal jährlich einen Ernstfall: Auskunftsersuchen, Legal Hold, Audit-Anfrage. Wer das geübt hat, erkennt in der echten Situation, ob Berechtigungen, Aufbewahrungszeiten oder Abläufe fehlen.

> **Merke**
>
> Compliance ist nachweisbar, wenn drei Dinge zusammenkommen: ein Prozess (wer entscheidet), eine Konfiguration (was wirkt) und ein Beleg (was belegt es). Fehlt eines davon, ist die Compliance nicht belegbar, auch wenn die Technik läuft.

## Übungsaufgaben

**Aufgabe 1 (leicht).** Was beantwortet das einheitliche Überwachungsprotokoll, und warum ist die Aufbewahrungsdauer der Einträge für die Governance wichtig?

**Aufgabe 2 (leicht).** Nennen Sie die Phasen eines eDiscovery-Prozesses und erklären Sie, warum der Suchumfang möglichst eng sein soll.

**Aufgabe 3 (leicht).** Erklären Sie den Unterschied zwischen einer Aufbewahrungsrichtlinie und einem Legal Hold.

**Aufgabe 4 (mittel).** Schreiben Sie eine Audit-Suche, die alle Erstellungen von Freigabelinks (Operation SharingLinkCreated; prüfen Sie den Namen in Ihrer Umgebung) der letzten drei Tage ausgibt, mit Benutzer, Datei und Zeitpunkt.

**Aufgabe 5 (mittel).** Die Betriebsrätin fragt, warum Insider Risk eingeführt werden soll und wie die Beschäftigten geschützt werden. Formulieren Sie fünf Punkte, die Sie in einer Betriebsvereinbarung regeln würden.

**Aufgabe 6 (mittel).** Beschreiben Sie, wie Sie die Funktionstrennung bei Communication Compliance überprüfen und welche Befunde Sie melden.

**Aufgabe 7 (schwer).** Erstellen Sie eine Nachweismatrix mit mindestens sechs Zeilen für die Anforderung „Zugriff auf personenbezogene Daten ist auf Berechtigte beschränkt“ und verweisen Sie auf Maßnahmen aus den Modulen 2, 4, 6 und 7. Nennen Sie Verantwortliche und Nachweise.

**Aufgabe 8 (schwer).** Ein Hold wurde vor sechs Wochen eingerichtet. Jetzt stellt sich heraus, dass die OneDrive-Daten des Beschäftigten fehlen. Beschreiben Sie die Fehlersuche Schritt für Schritt, nennen Sie mögliche Ursachen und die Maßnahmen, die Sie künftig verhindern.

## Lösungen

**Lösung 1.** Das Protokoll beantwortet, wer wann welche Aktivität in welchem Dienst durchgeführt hat. Die Aufbewahrungsdauer bestimmt, wie weit zurück Untersuchungen möglich sind. Ein Ereignis, das älter als die Aufbewahrung ist, lässt sich nicht mehr belegen; die Dauer muss zu den Nachweispflichten und zur Lizenz passen.

**Lösung 2.** Die Phasen sind Identifizieren, Sichern, Sammeln, Prüfen und Herausgeben. Ein enger Suchumfang entspricht dem Grundsatz der Erforderlichkeit, reduziert die Menge verarbeiteter personenbezogener Daten, erleichtert die Prüfung und verringert das Risiko bei Export und Weitergabe.

**Lösung 3.** Eine Aufbewahrungsrichtlinie ist eine Dauerregel zur Datenverwaltung mit definiertem Ende, die flächendeckend wirkt. Ein Legal Hold ist eine gezielte Sperre für einen Fall, die ohne Ablaufdatum gilt, bis jemand sie aufhebt, und die dem Fall zugeordnet ist. Der Hold dient der Beweissicherung, die Richtlinie der laufenden Datenverwaltung.

**Lösung 4.** Ein möglicher Entwurf:

```powershell
Connect-ExchangeOnline
$ende = (Get-Date).ToUniversalTime(); $start = $ende.AddDays(-3)
Search-UnifiedAuditLog -StartDate $start -EndDate $ende `
    -Operations SharingLinkCreated -ResultSize 5000 |
  ForEach-Object {
    $d = $_.AuditData | ConvertFrom-Json
    [pscustomobject]@{ Zeit = $_.CreationDate; Benutzer = $_.UserIds
                       Datei = $d.SourceFileName }
  } | Sort-Object Zeit | Format-Table -AutoSize
```

Das Skript begrenzt den Zeitraum auf drei Tage in UTC, filtert nach der Operation, wandelt das JSON-Feld in Objekte um und gibt eine Tabelle aus. Den genauen Operationsnamen prüft man mit einer Suche ohne Filter in einem kleinen Zeitfenster.

**Lösung 5.** Mögliche Punkte: (1) konkreter Zweck (Schutz von Betriebsgeheimnissen, keine Leistungskontrolle), (2) Pseudonymisierung als Standard und Vier-Augen-Prinzip bei Aufhebung, (3) benannte Rollen und Prüfer mit Schulung, (4) Aufbewahrungsfrist für Warnungen und Fälle, (5) Informationspflicht gegenüber Beschäftigten und Beteiligung des Betriebsrats bei Änderungen. Ergänzend: Verbot, Ergebnisse allein für arbeitsrechtliche Maßnahmen zu verwenden.

**Lösung 6.** Man liest die Mitglieder der vier Rollengruppen aus, bildet die Schnittmenge zwischen Administratoren und Prüfern und meldet jede Überschneidung als Befund. Zusätzlich meldet man Gruppen ohne Mitglied (Prozesslücke), Mitglieder, die nicht mehr im Unternehmen sind, und Personen mit zu breiten Rollen. Das Ergebnis geht in das regelmäßige Berechtigungsreview.

**Lösung 7.** Beispielzeilen: (1) Rollenbasierter Zugriff mit Gruppen, Maßnahme Zugriffsüberprüfung (Modul 2), Verantwortlich IT-Governance, Nachweis Bericht der Überprüfung. (2) Eingeschränkte Freigabe für Websites (Modul 4), Verantwortlich SharePoint-Betrieb, Nachweis Einstellungen und Bericht. (3) Klassifizierung mit Labels (Modul 6), Verantwortlich Compliance, Nachweis Labelrichtlinie. (4) DLP gegen unbefugten Versand (Modul 6), Verantwortlich Compliance, Nachweis Richtlinie und Trefferbericht. (5) Protokollierung von Zugriffen (Lerneinheit 7.1), Verantwortlich Security, Nachweis Audit-Konfiguration. (6) Nachvollziehbare Administration (Modul 8, Privileged Access), Verantwortlich Security, Nachweis PIM-Protokolle. Hinweis: Welche Anforderung konkret gilt, ist rechtlich zu klären.

**Lösung 8.** Vorgehen: (1) Status der Sperrrichtlinie prüfen (Verteilungsstatus, aktiviert). (2) Prüfen, ob die OneDrive-Adresse in der Richtlinie steht und korrekt geschrieben ist. (3) Prüfen, ob der Benutzer ein OneDrive besitzt und ob die Daten dort tatsächlich fehlen oder nur im Papierkorb liegen. (4) Prüfen, wann die Daten gelöscht wurden (Audit) im Verhältnis zum Hold-Beginn. (5) Wiederherstellung aus Papierkorb und gegebenenfalls Preservation-Hold-Bibliothek. Mögliche Ursachen: OneDrive nicht in die Sperre aufgenommen, Verteilungsfehler, Löschung vor dem Hold, Sperre mit Abfrage, die die Dateien nicht erfasst. Künftig verhindert eine Checkliste den Fehler: Umfang aus Postfach, OneDrive, Teams, Statusprüfung nach 24 Stunden, Dokumentation im Fall.
