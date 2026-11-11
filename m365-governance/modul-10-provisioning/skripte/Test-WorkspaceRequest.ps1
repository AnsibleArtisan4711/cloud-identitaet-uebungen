# Quelle: Skript „M365 Governance“, Modul 10, Listing 118 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
function Test-WorkspaceRequest {
    param([Parameter(Mandatory)][pscustomobject]$Antrag)

    $fehler = @()
    foreach ($feld in "Name","Zweck","Besitzer1","Besitzer2","Abteilung","Vertraulichkeit") {
        if ([string]::IsNullOrWhiteSpace($Antrag.$feld)) { $fehler += "Pflichtfeld fehlt: $feld" }
    }
    if ($Antrag.Besitzer1 -and $Antrag.Besitzer1 -eq $Antrag.Besitzer2) {
        $fehler += "Die beiden Besitzer muessen verschiedene Personen sein."
    }
    if ($Antrag.Name -and $Antrag.Name.Length -gt 40) { $fehler += "Name laenger als 40 Zeichen." }
    if ($fehler) { return [pscustomobject]@{ Gueltig = $false; Fehler = $fehler; Stufe = $null } }

    $stufe = 1
    if ($Antrag.Gaeste -eq $true)                                  { $stufe = 3 }
    elseif ($Antrag.Vertraulichkeit -in "Vertraulich","Streng")    { $stufe = 3 }
    elseif ($Antrag.Vertraulichkeit -eq "Intern" -and $Antrag.Groesse -gt 200) { $stufe = 2 }

    [pscustomobject]@{ Gueltig = $true; Fehler = @(); Stufe = $stufe }
}

# Beispielaufruf
$antrag = [pscustomobject]@{
    Name = "Projekt Phoenix"; Zweck = "Produktlaunch"; Besitzer1 = "anna@contoso.com"
    Besitzer2 = "ben@contoso.com"; Abteilung = "Vertrieb"; Vertraulichkeit = "Intern"
    Gaeste = $false; Groesse = 12
}
Test-WorkspaceRequest -Antrag $antrag | Format-List
