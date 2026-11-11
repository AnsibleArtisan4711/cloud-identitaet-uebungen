# Quelle: Skript „M365 Governance“, Modul 03, Listing 20 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
param([Parameter(Mandatory)][string]$GroupName)   # z. B. "SEC-Team-Ersteller"

Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.Read.All" -NoWelcome

$gruppe = Get-MgGroup -Filter "displayName eq '$GroupName'"
if (-not $gruppe) { throw "Sicherheitsgruppe '$GroupName' nicht gefunden - Abbruch." }
if (@($gruppe).Count -gt 1) { throw "Name nicht eindeutig - Abbruch." }

$vorlage = Get-MgBetaDirectorySettingTemplate | Where-Object { $_.DisplayName -eq "Group.Unified" }
$einst   = Get-MgBetaDirectorySetting | Where-Object { $_.TemplateId -eq $vorlage.Id }

$werte = @(
    @{ Name = "EnableGroupCreation";        Value = "false" },
    @{ Name = "GroupCreationAllowedGroupId"; Value = $gruppe.Id }
)

if (-not $einst) {
    $params = @{ TemplateId = $vorlage.Id; Values = $werte }
    New-MgBetaDirectorySetting -BodyParameter $params | Out-Null
    "Einstellung neu angelegt."
} else {
    Update-MgBetaDirectorySetting -DirectorySettingId $einst.Id -Values $werte
    "Einstellung aktualisiert."
}
"Hinweis: Die Aenderung kann 30 Minuten und laenger bis zur Wirkung brauchen."
