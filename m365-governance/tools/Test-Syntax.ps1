# Test-Syntax.ps1 - prüft, dass alle PowerShell-Dateien syntaktisch lesbar sind und alle JSON-Dateien gültig sind.
# Das ist die schwächste Prüfung: Sie beweist NICHT, dass ein Skript gegen einen echten Tenant funktioniert.
param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$fehler = 0
$dateien = Get-ChildItem -Path $Root -Recurse -File -Include *.ps1, *.psm1, *.json |
    Where-Object { $_.FullName -notmatch '[\\/](\.git|node_modules)[\\/]' }

foreach ($d in $dateien) {
    $rel = $d.FullName.Substring($Root.Length).TrimStart('\', '/')
    if ($d.Extension -eq '.json') {
        try { Get-Content -LiteralPath $d.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null }
        catch { Write-Host "FEHLER  $rel : $($_.Exception.Message)" -ForegroundColor Red; $fehler++ }
        continue
    }
    $tokens = $null; $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile($d.FullName, [ref]$tokens, [ref]$errs) | Out-Null
    if ($errs -and $errs.Count -gt 0) {
        foreach ($e in $errs) { Write-Host ("FEHLER  {0}:{1} {2}" -f $rel, $e.Extent.StartLineNumber, $e.Message) -ForegroundColor Red }
        $fehler++
    }
}

Write-Host ("Syntaxprüfung: {0} Dateien, {1} mit Fehlern" -f @($dateien).Count, $fehler)
if ($fehler -gt 0) { exit 1 } else { exit 0 }
