# Quelle: Skript „M365 Governance“, Modul 10, Lösung zu Aufgabe 5 (Code unverändert übernommen, nur dieser Kopf ergänzt).
# Status: offline getestet (simulierte Graph-Cmdlets), nicht gegen einen echten Tenant ausgeführt. Siehe docs/kennzeichnung.md.
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
