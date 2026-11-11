# Quelle: Skript „M365 Governance“, Modul 05, Listing 38 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Exchange-Online- und Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
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
