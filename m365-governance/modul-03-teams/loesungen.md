# Lösungen – Modul 03: Teams Governance und Collaboration Lifecycle

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Die Phasen sind Beantragung und Anlage, Nutzung, Inaktivität, Archivierung und Löschung. Die Archivierung steht vor der Löschung, weil sie reversibel ist: Das Team bleibt lesbar und lässt sich reaktivieren, während die Löschung nach 30 Tagen endgültig wird. So kann man Fehlentscheidungen korrigieren und Aufbewahrungspflichten erfüllen.

## Lösung zu Aufgabe 2

Beim Gastzugriff wird eine externe Person als Gastbenutzer im Verzeichnis geführt und einem Team zugeordnet, etwa eine Beraterin, die im Projektteam Dateien bearbeitet. Beim externen Zugriff chattet oder telefoniert eine Person mit eigenem Konto aus einer anderen Organisation, ohne Mitglied eines Teams zu sein, etwa bei einer Besprechung mit einem Lieferanten. Nur der Gastzugriff gewährt Zugriff auf Inhalte des Teams.

## Lösung zu Aufgabe 3

Es gibt Standardkanäle, private Kanäle und freigegebene Kanäle. Standardkanäle haben keine eigene SharePoint-Website, sie nutzen die des Teams. Private und freigegebene Kanäle haben jeweils eine eigene Website.

## Lösung zu Aufgabe 4

Ein Beispiel: Typkürzel ABT (Abteilung), PRJ (Projekt), KND (Kunde), GRM (Gremium), gefolgt von Bereich und Name, also etwa `PRJ-Vertrieb-Messe2027`. Das Typkürzel erlaubt Sortieren und Filtern, der Bereich ordnet zu, der Name bleibt kurz, damit die Gesamtlänge unter dem technischen Limit von 63 Zeichen bleibt. Die Namensrichtlinie kann ein Präfix wie `[Department]-` automatisch setzen und Wörter wie „test“ oder „admin“ sperren. Sie ersetzt die Konvention nicht, sondern erzwingt den Teil, der sich technisch abbilden lässt. Der Rest wird durch Antragsformular und Bestandsberichte unterstützt.

## Lösung zu Aufgabe 5

Stufe 1: Alle Mitarbeitenden erstellen Teams aus drei bis fünf freigegebenen Vorlagen (Abteilung, Projekt, Gremium) über ein Formular oder die Bereitstellungsfabrik, mit automatischem Namen, zwei Besitzern, Standardlabel ohne Gäste. Stufe 2: Eine Gruppe von Champions darf freie Teams erstellen (Sicherheitsgruppe als erlaubte Erstellergruppe). Stufe 3: Teams mit Gästen oder hoher Vertraulichkeit nur über einen Antrag mit Genehmigung durch Datenschutz oder Sicherheitsbeauftragte, mit Label und Zugriffsüberprüfung.

## Lösung zu Aufgabe 6

Ein mögliches Skript:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","GroupMember.Read.All" -NoWelcome
Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq 'Team')" -All -Property Id,DisplayName |
  ForEach-Object {
    $o = @(Get-MgGroupOwner -GroupId $_.Id).Count
    if ($o -lt 2) {
      $g = @(Get-MgGroupMember -GroupId $_.Id -All |
             Where-Object { $_.AdditionalProperties.userType -eq 'Guest' }).Count
      if ($g -ge 1) { [pscustomobject]@{ Team = $_.DisplayName; Besitzer = $o; Gaeste = $g } }
    }
  } | Format-Table -AutoSize
```

Das Skript zählt zuerst die Besitzer und fragt die Gäste nur dann ab, wenn die Besitzerbedingung erfüllt ist. Das spart Abfragen und beschleunigt den Lauf in großen Tenants. Die Kombination ist ein typischer Risikoindikator: Gäste ohne ausreichende Aufsicht.

> **Als Datei:** [`loesungen-skripte/aufgabe-06-teams-ohne-besitzer-mit-gaesten.ps1`](loesungen-skripte/aufgabe-06-teams-ohne-besitzer-mit-gaesten.ps1) (offline getestet)

## Lösung zu Aufgabe 7

Gastkonten im Team geben den 15 Personen Zugriff auf das gesamte Team und erzeugen 15 Gastobjekte, die bereinigt werden müssen. Ein privater Kanal mit Gästen verlangt trotzdem, dass die Gäste zuerst Teammitglieder sind, und schränkt nur die Sicht im Team ein; die Gäste bleiben im Verzeichnis. Ein freigegebener Kanal mit B2B-Direktverbindung gibt den Partnern nur Zugriff auf den Kanal, sie melden sich mit dem eigenen Konto an, und es entstehen keine Gastobjekte. Empfehlung: freigegebener Kanal, sofern die Partnerorganisation die Direktverbindung zulässt und die benötigten Funktionen unterstützt sind. Voraussetzung ist die gegenseitige Freigabe der Cross-Tenant-Einstellungen. Ansonsten ist der Gastzugriff mit einem dedizierten Projektteam, Befristung über Zugriffspaket und Überprüfung die Rückfalllösung.

## Lösung zu Aufgabe 8

Ein mögliches Vorgehen: Die Eigenschaft `RenewedDateTime` der Gruppe mit dem Grenzdatum vergleichen und jede Entscheidung mit Zeitstempel in eine Datei schreiben.

```powershell
param([Parameter(Mandatory)][string]$CsvPfad, [switch]$Ausfuehren)
Connect-MgGraph -Scopes "TeamSettings.ReadWrite.All","Group.Read.All" -NoWelcome
$grenze = (Get-Date).AddDays(-365)
$log = ".\archivierung-$(Get-Date -Format yyyyMMdd).log"
foreach ($z in Import-Csv $CsvPfad) {
  $g = Get-MgGroup -GroupId $z.TeamId -Property Id,DisplayName,RenewedDateTime
  if ($g.RenewedDateTime -gt $grenze) {
    Add-Content $log "$(Get-Date -Format s) UEBERSPRUNGEN $($g.DisplayName) (juenger als 365 Tage)"
    continue
  }
  if ($Ausfuehren) { Invoke-MgArchiveTeam -TeamId $g.Id }
  Add-Content $log "$(Get-Date -Format s) $(if($Ausfuehren){'ARCHIVIERT'}else{'PROBELAUF'}) $($g.DisplayName)"
}
```

Das Skript schreibt für jede Entscheidung eine Zeile mit Zeitstempel. Dadurch ist nachvollziehbar, warum ein Team archiviert oder übersprungen wurde. Der Probelauf wird ebenfalls protokolliert, sodass ein Mensch die Liste vor dem eigentlichen Lauf prüfen kann.

> **Als Datei:** [`loesungen-skripte/aufgabe-08-archivierung-mit-protokoll.ps1`](loesungen-skripte/aufgabe-08-archivierung-mit-protokoll.ps1) (offline getestet)
