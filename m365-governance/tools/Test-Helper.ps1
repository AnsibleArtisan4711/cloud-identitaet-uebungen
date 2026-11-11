# Test-Helper.ps1 - kleines Test-Hilfsgerüst ohne Pester (läuft in Windows PowerShell 5.1 und PowerShell 7).
# Warum kein Pester? Die Tests sollen ohne Installation laufen. Die Funktionen heißen bewusst anders (Test-Case statt It),
# damit sie sich nicht mit Pester überschneiden, falls Pester später doch genutzt wird.

$script:Bestanden = 0
$script:Fehlgeschlagen = 0

function Test-Case {
    param([Parameter(Mandatory)][string]$Name, [Parameter(Mandatory)][scriptblock]$Body)
    try {
        & $Body
        $script:Bestanden++
        Write-Host "  ok      $Name"
    } catch {
        $script:Fehlgeschlagen++
        Write-Host "  FEHLER  $Name" -ForegroundColor Red
        Write-Host "          $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Assert-Equal {
    param($Expected, $Actual, [string]$Message = '')
    # Listen werden elementweise verglichen (sonst würde -ne die Elemente filtern statt vergleichen).
    if (($Expected -is [array]) -or ($Actual -is [array])) {
        $e = @($Expected); $a = @($Actual)
        $gleich = ($e.Count -eq $a.Count)
        if ($gleich) { for ($i = 0; $i -lt $e.Count; $i++) { if ($e[$i] -ne $a[$i]) { $gleich = $false; break } } }
        if (-not $gleich) { throw "Erwartet <$($e -join ', ')>, erhalten <$($a -join ', ')>. $Message" }
    }
    elseif ($Expected -ne $Actual) { throw "Erwartet <$Expected>, erhalten <$Actual>. $Message" }
}

function Assert-True {
    param($Condition, [string]$Message = 'Bedingung nicht erfüllt.')
    if (-not $Condition) { throw $Message }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Message = '')
    if ($Text -notmatch $Pattern) { throw "Muster <$Pattern> nicht gefunden. $Message`nText:`n$Text" }
}

function Assert-NotMatch {
    param([string]$Text, [string]$Pattern, [string]$Message = '')
    if ($Text -match $Pattern) { throw "Muster <$Pattern> sollte nicht vorkommen. $Message`nText:`n$Text" }
}

function Assert-Throws {
    param([Parameter(Mandatory)][scriptblock]$Body, [string]$Pattern = '')
    $geworfen = $null
    try { & $Body } catch { $geworfen = $_ }
    if (-not $geworfen) { throw 'Es wurde keine Ausnahme ausgelöst.' }
    if ($Pattern -and ($geworfen.Exception.Message -notmatch $Pattern)) {
        throw "Ausnahme passt nicht zu <$Pattern>: $($geworfen.Exception.Message)"
    }
}

function Complete-Tests {
    Write-Host ''
    Write-Host ("Ergebnis: {0} bestanden, {1} fehlgeschlagen" -f $script:Bestanden, $script:Fehlgeschlagen)
    if ($script:Fehlgeschlagen -gt 0) { exit 1 } else { exit 0 }
}

function Invoke-ScriptUnderTest {
    <# Führt ein Skript aus und sammelt Ausgabe, Warnungen, Host-Ausgaben und Fehler getrennt ein. #>
    param([Parameter(Mandatory)][string]$Path, [hashtable]$Arguments = @{})
    if (-not (Test-Path -LiteralPath $Path)) { throw "Skript nicht gefunden: $Path" }
    $global:MockCalls.Clear()
    # Tee-Object sammelt alle Objekte; gleichzeitig wird die Erfolgsausgabe als Text gerendert.
    # (Format-Table/Format-List erzeugen Formatobjekte, die nur im selben Pipeline-Lauf lesbar sind.)
    $ausgabeText = & $Path @Arguments *>&1 | Tee-Object -Variable alle |
        Where-Object { ($_ -isnot [System.Management.Automation.InformationRecord]) -and
                       ($_ -isnot [System.Management.Automation.WarningRecord]) -and
                       ($_ -isnot [System.Management.Automation.ErrorRecord]) } | Out-String -Width 4096
    $ergebnis = [ordered]@{ Output = @(); OutputText = ''; Warnings = @(); Info = @(); Errors = @(); Text = '' }
    foreach ($e in @($alle)) {
        if ($e -is [System.Management.Automation.WarningRecord])         { $ergebnis.Warnings += $e.Message }
        elseif ($e -is [System.Management.Automation.InformationRecord]) { $ergebnis.Info += [string]$e.MessageData }
        elseif ($e -is [System.Management.Automation.ErrorRecord])       { $ergebnis.Errors += $e.ToString() }
        elseif ($null -eq $e)                                            { }
        elseif ($e.GetType().FullName -like 'Microsoft.PowerShell.Commands.Internal.Format.*') { }
        else                                                             { $ergebnis.Output += $e }
    }
    $ergebnis.OutputText = ($ausgabeText -replace "`r`n", "`n").TrimEnd()
    $ergebnis.Text = (@($ergebnis.OutputText) + $ergebnis.Info + $ergebnis.Warnings + $ergebnis.Errors) -join "`n"
    [pscustomobject]$ergebnis
}

function New-TestDirectory {
    $pfad = Join-Path ([System.IO.Path]::GetTempPath()) ("m365test-" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $pfad | Out-Null
    $pfad
}
