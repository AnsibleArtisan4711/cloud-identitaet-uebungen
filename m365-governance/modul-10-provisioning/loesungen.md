# Lösungen – Modul 10: Provisioning, Standards und Lifecycle Automation

Die Lösungen stammen aus dem Skript. Es sind *mögliche* Lösungen; bei Konzeptaufgaben zählt die Begründung mehr als die konkrete Wahl.

## Lösung zu Aufgabe 1

Die Stufen sind Antrag, Genehmigung, technische Anlage, Konfiguration nach Standard und Registrierung. Fehlt der Antrag, gibt es keine Pflichtangaben; fehlt die Genehmigung, entstehen riskante Arbeitsbereiche unkontrolliert; fehlt die automatische Anlage, entstehen Fehler und Wartezeiten; fehlt die Konfiguration, sind die Arbeitsbereiche uneinheitlich; fehlt die Registrierung, kennt später niemand den Bestand und der Lebenslauf lässt sich nicht steuern.

## Lösung zu Aufgabe 2

Zwei Besitzer sichern ab, dass bei Ausscheiden oder Abwesenheit einer Person der Arbeitsbereich verwaltbar bleibt. Dienstkonten sind als Besitzer ungeeignet, weil sie keine verantwortliche Person sind, nicht auf Benachrichtigungen reagieren und das Konto selbst ein Angriffsziel ist.

## Lösung zu Aufgabe 3

Schreibschutz (umkehrbar durch Administratoren), Archiv (umkehrbar durch Reaktivierung), vorläufiges Löschen (30 Tage lang wiederherstellbar, die Wiederherstellung kann bis zu ein bis zwei Tage dauern) und endgültiges Löschen (nicht umkehrbar). Ob Aufbewahrungspflichten das Löschen von Inhalten verhindern, ist gesondert zu prüfen.

## Lösung zu Aufgabe 4

Ein Beispiel: Stufe 1 (automatisch): interner Arbeitsbereich, Pflichtangaben vollständig, keine Gäste, Vertraulichkeit „Intern“. Stufe 2 (Führungskraft): sehr großer interner Arbeitsbereich oder abweichende Vorlage. Stufe 3 (Führungskraft plus Datenschutz oder Informationssicherheit): Gäste, „Vertraulich“ oder „Streng vertraulich“, besondere Datenkategorien. Die Stufe darf nicht von den Antragstellern gewählt werden, weil sie ein Interesse an schneller Freigabe haben; sie ergibt sich aus den Angaben nach festen Regeln, die geprüft werden.

## Lösung zu Aufgabe 5

Ein Lösungsvorschlag:

```powershell
function ConvertTo-Nickname {
    param([Parameter(Mandatory)][string]$Text, [int]$Max = 40)
    $t = $Text.ToLower()
    $t = $t -replace 'ä','ae' -replace 'ö','oe' -replace 'ü','ue' -replace 'ß','ss'
    $t = ($t -replace '[^a-z0-9]+','-').Trim('-')
    if ($t.Length -gt $Max) { $t = $t.Substring(0,$Max).TrimEnd('-') }
    if (-not $t) { throw "Kein gueltiges Zeichen im Text." }
    $t
}
ConvertTo-Nickname "Größe & Übung (2026)!"        # groesse-uebung-2026
ConvertTo-Nickname "   --Test--   "                 # test
ConvertTo-Nickname ("a" * 100)                      # 40 mal a
```

Die Funktion ersetzt Umlaute, wandelt alle anderen Zeichen in Bindestriche um, entfernt Randbindestriche, kürzt und meldet einen Fehler, wenn nichts übrig bleibt. Die drei Aufrufe prüfen Sonderzeichen, Randfälle und die Längenbegrenzung.

> **Als Datei:** [`loesungen-skripte/aufgabe-05-nickname.ps1`](loesungen-skripte/aufgabe-05-nickname.ps1) (offline getestet)

## Lösung zu Aufgabe 6

Die Richtlinie kennt keinen Testmodus und wirkt auf alle erfassten Gruppen; eine zu kurze Dauer oder fehlende Besitzer führen zu Löschungen. Mit ausgewählten Gruppen (bis zu 500) beobachtet man Wirkung und Benachrichtigungen ohne großes Risiko. Besitzer erhalten Meldungen 30, 15 und 1 Tag vor dem Ablauf, soweit die Gruppe nicht wegen Aktivität automatisch verlängert wird. Eine nicht verlängerte Gruppe wird einen Tag nach dem Ablaufdatum gelöscht und ist danach 30 Tage lang wiederherstellbar.

## Lösung zu Aufgabe 7

Ein Lösungsvorschlag:

```powershell
Connect-MgGraph -Scopes "Group.Read.All","User.Read.All" -NoWelcome
$gruppen = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified')" -All -Property Id,DisplayName
$befunde = foreach ($g in $gruppen) {
    $aktiv = @(Get-MgGroupOwner -GroupId $g.Id | ForEach-Object {
        $u = Get-MgUser -UserId $_.Id -Property AccountEnabled,Department -ErrorAction SilentlyContinue
        if ($u -and $u.AccountEnabled) { $u }
    })
    if ($aktiv.Count -eq 0) {
        $abt = "unbekannt"
        $m = @(Get-MgGroupMember -GroupId $g.Id -Top 1)
        if ($m) {
            $mu = Get-MgUser -UserId $m[0].Id -Property Department -ErrorAction SilentlyContinue
            if ($mu.Department) { $abt = $mu.Department }
        }
        [pscustomobject]@{ Abteilung = $abt; Gruppe = $g.DisplayName; Id = $g.Id }
    }
}
$befunde | Group-Object Abteilung | ForEach-Object {
    $_.Group | Export-Csv -Path (".\ohne-aktiven-besitzer-{0}.csv" -f $_.Name) -NoTypeInformation -Encoding UTF8
}
```

Das Skript prüft für jede Gruppe, ob mindestens ein Besitzer ein aktives Konto hat. Für Gruppen ohne aktiven Besitzer schätzt es die Abteilung aus dem ersten Mitglied und erzeugt je Abteilung eine Datei. Die Abteilungsermittlung über das erste Mitglied ist eine Näherung; besser ist die Abteilung im Bestandsverzeichnis. Dateinamen mit Sonderzeichen in Abteilungsnamen sollten bereinigt werden.

> **Als Datei:** [`loesungen-skripte/aufgabe-07-ohne-aktiven-besitzer.ps1`](loesungen-skripte/aufgabe-07-ohne-aktiven-besitzer.ps1) (offline getestet)

## Lösung zu Aufgabe 8

Das 404 direkt nach dem Anlegen ist die Replikationsverzögerung: Das Team wird zu früh erzeugt. Die Dokumentation empfiehlt bis zu drei Wiederholungen im Abstand von zehn Sekunden und bei weiterem Misserfolg eine Wartezeit von mindestens 15 Minuten. Das 429 ist Drosselung durch zu viele Anfragen, besonders bei Stapelläufen; die Lösung ist, die Wartezeit aus dem Header zu beachten, Anfragen zu bündeln und Läufe zu verteilen. Die Lösung: eine Wiederholungsfunktion mit Unterscheidung nach Statuscode (siehe Beispiel in 10.8), eine Pause zwischen Anträgen, ein Protokoll je Antrag mit Gruppen-ID und Fehler, und eine Aufräumregel: Gruppen ohne Team, die älter als eine Stunde sind und deren Antrag als fehlgeschlagen gilt, werden gemeldet und nach Prüfung gelöscht oder fortgesetzt. Automatisches Löschen sollte nur für selbst angelegte, noch leere Gruppen erfolgen.
