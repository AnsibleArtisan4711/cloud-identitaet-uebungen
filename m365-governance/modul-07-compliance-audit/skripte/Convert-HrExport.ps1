# Quelle: Skript „M365 Governance“, Modul 07, Listing 72 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: Logik offline getestet mit erfundenen CSV-Testdaten, aber an einer Kopie mit geändertem Anfangswert: Das Original scheitert in PowerShell 7 und in Windows PowerShell 5.1 an [datetime]::TryParseExact (siehe README dieses Moduls, Abschnitt "Hinweise"). Nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
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
