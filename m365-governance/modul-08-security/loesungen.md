# Lösungen – Modul 08: Security Governance und Secure-by-Design

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Der Secure Score misst den Anteil umgesetzter Sicherheitsmaßnahmen an den möglichen Maßnahmen als Prozentwert. Ein Verlauf zeigt die Wirkung von Maßnahmen und macht Veränderungen sichtbar, die durch neue Maßnahmen von Microsoft entstehen. Ein Einzelwert ohne Vergleich sagt wenig über Fortschritt oder Rückschritt.

## Lösung zu Aufgabe 2

Beispiele: MFA für Administratoren, MFA für alle Benutzer, Legacy-Authentifizierung blockieren, MFA bei Anmelderisiko, konformes Gerät für sensible Anwendungen, Registrierung der Sicherheitsinformationen schützen. Notfallkonten werden ausgenommen, damit bei einer Fehlkonfiguration oder einem Ausfall des zweiten Faktors immer noch ein Administratorzugang bleibt. Ihre Nutzung wird dafür besonders überwacht.

## Lösung zu Aufgabe 3

MFA verlangt mindestens zwei Faktoren; phishing-resistente MFA bindet die Anmeldung zusätzlich kryptografisch an die echte Seite, sodass gefälschte Seiten keine nutzbaren Antworten erhalten. Zur zweiten Gruppe gehört der FIDO2-Schlüssel. SMS und Push-Bestätigung sind nicht phishing-resistent.

## Lösung zu Aufgabe 4

Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome
Get-MgIdentityConditionalAccessPolicy -All |
  Select-Object DisplayName, State,
    @{n='NurBericht'; e={ $_.State -eq 'enabledForReportingButNotEnforced' }} |
  Sort-Object NurBericht -Descending | Format-Table -AutoSize
```

Das Skript liest alle Richtlinien, berechnet eine Spalte für den Berichtsmodus und sortiert Richtlinien im Berichtsmodus nach oben.

> **Als Datei:** [`loesungen-skripte/aufgabe-04-ca-berichtsmodus.ps1`](loesungen-skripte/aufgabe-04-ca-berichtsmodus.ps1) (offline getestet)

## Lösung zu Aufgabe 5

Beispiel: Geräte-PIN mit Mindestlänge (Schutz vor Fremdzugriff), Gerätespeicher verschlüsselt (Schutz bei Verlust), keine Jailbreak- oder Root-Erkennung (Integrität), Mindestversion des Betriebssystems (Sicherheitsupdates). Karenzfrist 24 Stunden, danach Markierung als nicht konform und E-Mail an den Benutzer, nach sieben Tagen Zugriffssperre über bedingten Zugriff. Wichtig ist die Zuweisung an eine Pilotgruppe vor dem breiten Einsatz.

## Lösung zu Aufgabe 6

Schritte: (1) Antrag mit Gerät, Zweck, Dauer. (2) Risikobewertung (Konto mit Kennwort ohne MFA). (3) Genehmigung durch die Fachbereichsleitung und Security. (4) Umsetzung über Ausnahmegruppe mit Ablaufdatum. (5) Überprüfung vor Ablauf. Kompensierend: Zugriff nur von der festen IP-Adresse des Labors, minimale Rechte (nur eine Anwendung), erhöhte Überwachung der Anmeldungen, langes zufälliges Kennwort im Tresor, Austausch des Geräts im Plan.

## Lösung zu Aufgabe 7

Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "startswith(displayName,'SEC-EXC-')" -All
$zeilen = foreach ($g in $gruppen) {
  Get-MgGroupMember -GroupId $g.Id -All | ForEach-Object {
    [pscustomobject]@{ Gruppe = $g.DisplayName; Id = $_.Id }
  }
}
$zeilen | Group-Object Id | Where-Object Count -gt 2 |
  ForEach-Object { [pscustomobject]@{ Id = $_.Name; Gruppen = ($_.Group.Gruppe -join ', ') } }
```

Das Skript sammelt alle Mitgliedschaften, gruppiert nach Konto-ID und zeigt Konten mit mehr als zwei Gruppen samt Gruppennamen.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-ausnahmegruppen.ps1`](loesungen-skripte/aufgabe-07-ausnahmegruppen.ps1) (offline getestet)

## Lösung zu Aufgabe 8

Vorgehen: Zeitpunkt und Anwendung erfragen, Anmeldungen der betroffenen Person im Protokoll suchen, Ergebnis jeder angewendeten Richtlinie lesen, Ursache zuordnen, einzeln beheben und testen. Mögliche Ursachen: (1) Kein registrierter zweiter Faktor, Lösung durch kontrollierte Registrierung mit Temporary Access Pass, keine Ausnahme. (2) Gerät nicht konform, Lösung durch Behebung (Update, Verschlüsselung), keine Ausnahme, höchstens kurze Karenz. (3) Zugriff aus gesperrtem Land auf Dienstreise, Lösung durch befristete, genehmigte Standortausnahme. (4) Altes Mail-Programm mit Altprotokoll, Lösung durch Umstellung auf moderne Anwendung, keine Dauerausnahme. Eine Ausnahme ist angemessen, wenn kein anderer Weg besteht, das Risiko bewertet ist, kompensierende Maßnahmen gelten und eine Frist gesetzt wird.
