# Quelle: Skript „M365 Governance“, Modul 10, Listing 123 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
function ConvertTo-Slug {
    param([string]$Text)
    $t = $Text.ToLower()
    $t = $t -replace 'ä','ae' -replace 'ö','oe' -replace 'ü','ue' -replace 'ß','ss'
    $t = $t -replace '[^a-z0-9]+','-'
    $t.Trim('-')
}

function New-WorkspaceName {
    param(
        [Parameter(Mandatory)][ValidateSet("PRJ","ABT","GRM","KND")][string]$Typ,
        [Parameter(Mandatory)][ValidateLength(2,5)][string]$Abteilung,
        [Parameter(Mandatory)][string]$Freitext,
        [int]$MaxLaenge = 50
    )

    $slug = ConvertTo-Slug $Freitext
    $basis = "{0}-{1}-{2}" -f $Typ, $Abteilung.ToUpper(), $slug
    if ($basis.Length -gt $MaxLaenge) { $basis = $basis.Substring(0, $MaxLaenge).TrimEnd('-') }

    $name = $basis
    $nr = 1
    while (Get-MgGroup -Filter "mailNickname eq '$(ConvertTo-Slug $name)'" -ErrorAction SilentlyContinue) {
        $nr++
        $suffix = "-$nr"
        $name = $basis.Substring(0, [math]::Min($basis.Length, $MaxLaenge - $suffix.Length)) + $suffix
    }

    [pscustomobject]@{ Anzeigename = $name; Nickname = (ConvertTo-Slug $name) }
}

# Beispiel
New-WorkspaceName -Typ PRJ -Abteilung VER -Freitext "Produktlaunch Frühjahr"
