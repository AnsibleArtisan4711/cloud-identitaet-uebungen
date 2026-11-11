# Invoke-Tests.ps1 - führt die Syntaxprüfung und alle Testdateien (*.tests.ps1) aus.
# Aufruf aus dem Repository-Hauptordner:   pwsh -NoProfile -File tools/Invoke-Tests.ps1
# (unter Windows geht auch:                powershell -NoProfile -File tools\Invoke-Tests.ps1)
param([string]$Root = (Split-Path -Parent $PSScriptRoot))

$hostExe = (Get-Process -Id $PID).Path     # dieselbe PowerShell, die diesen Lauf gestartet hat
$gesamt = 0

Write-Host '== Syntaxprüfung =='
& $hostExe -NoProfile -File (Join-Path $PSScriptRoot 'Test-Syntax.ps1') -Root $Root
if ($LASTEXITCODE -ne 0) { $gesamt++ }

$tests = Get-ChildItem -Path $Root -Recurse -File -Filter *.tests.ps1 | Sort-Object FullName
foreach ($t in $tests) {
    $rel = $t.FullName.Substring($Root.Length).TrimStart('\', '/')
    Write-Host ''
    Write-Host "== $rel =="
    & $hostExe -NoProfile -File $t.FullName
    if ($LASTEXITCODE -ne 0) { $gesamt++ }
}

Write-Host ''
if ($gesamt -gt 0) { Write-Host "$gesamt Prüfschritt(e) fehlgeschlagen." -ForegroundColor Red; exit 1 }
Write-Host 'Alle Prüfschritte bestanden.' -ForegroundColor Green
exit 0
