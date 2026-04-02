#!/usr/bin/env pwsh
[CmdletBinding(PositionalBinding=$false)]
param(
    [Parameter(Mandatory=$false)]
    [Alias('c')]
    [string]$Config,

    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Files
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-IniSections {
    param([string]$Path)

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Config file '$Path' not found."
    }

    $sections = [ordered]@{}
    $current = ''
    $lines = Get-Content -Path $Path -ErrorAction Stop
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#') -or $trimmed.StartsWith(';')) {
            continue
        }
        if ($trimmed.StartsWith('[') -and $trimmed.EndsWith(']')) {
            $current = $trimmed.Substring(1, $trimmed.Length - 2).Trim()
            if (-not $sections.Contains($current)) {
                $sections[$current] = [ordered]@{}
            }
            continue
        }
        $splitIndex = $line.IndexOf('=')
        if ($splitIndex -lt 0) {
            continue
        }
        $key = $line.Substring(0, $splitIndex).Trim()
        $value = $line.Substring($splitIndex + 1).Trim()
        if (-not $sections.Contains($current)) {
            $sections[$current] = [ordered]@{}
        }
        $sections[$current][$key] = $value
    }

    return $sections
}

function ConvertTo-List {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return $Value.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries) |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' }
}

function Parse-Assignments {
    param([string]$Value)

    $result = @()
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $result
    }

    $entries = ConvertTo-List -Value $Value
    foreach ($entry in $entries) {
        $parts = $entry.Split('|', 2)
        if ($parts.Count -ne 2) {
            continue
        }
        $original = $parts[0].Trim()
        $anonymized = $parts[1].Trim()
        if ($original -and $anonymized) {
            $result += [pscustomobject]@{ original = $original; anonymized = $anonymized }
        }
    }

    return $result
}

function Find-FullPairByOriginal {
    param(
        [object[]]$Pairs,
        [string]$OriginalValue
    )

    if (-not $Pairs -or [string]::IsNullOrWhiteSpace($OriginalValue)) {
        return $null
    }

    foreach ($pair in $Pairs) {
        if (-not $pair) { continue }
        if ([string]::IsNullOrWhiteSpace($pair.original)) { continue }
        if ([string]::Equals($pair.original, $OriginalValue, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $pair
        }
    }

    return $null
}

function Get-AutoFullName {
    param(
        [pscustomobject]$Config,
        [string]$OriginalValue
    )

    $slug = ($OriginalValue -replace '[^0-9A-Za-z]+', '-').Trim('-')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        $slug = 'auto'
    }
    $base = "auto-$slug"
    $name = $base
    $suffix = 2
    while ($Config.pairs.full | Where-Object { $_.name -eq $name }) {
        $name = "{0}-{1}" -f $base, $suffix
        $suffix++
    }
    return $name
}

function Add-HintFullPair {
    param(
        [pscustomobject]$Config,
        [string]$OriginalValue,
        [string]$AnonymizedValue
    )

    $name = Get-AutoFullName -Config $Config -OriginalValue $OriginalValue
    $pair = [pscustomobject]@{
        name = $name
        original = $OriginalValue
        anonymized = $AnonymizedValue
    }
    $Config.pairs.full = @($Config.pairs.full + $pair)
    return $pair
}

function Convert-HintAssignmentsToFull {
    param([pscustomobject]$Config)

    foreach ($hint in $Config.pairs.hints) {
        if (-not $hint) { continue }
        if (-not $hint.PSObject.Properties.Match('assignments')) { continue }
        foreach ($assignment in $hint.assignments) {
            if (-not ($assignment.original -and $assignment.anonymized)) { continue }
            $existing = Find-FullPairByOriginal -Pairs $Config.pairs.full -OriginalValue $assignment.original
            if (-not $existing) {
                Add-HintFullPair -Config $Config -Hint $hint -OriginalValue $assignment.original -AnonymizedValue $assignment.anonymized | Out-Null
            }
        }
        $hint.assignments = @()
    }
}

function Get-ConfigObject {
    param([string]$Path)

    $sections = Read-IniSections -Path $Path
    $config = [pscustomobject]@{
        direction_markers = [pscustomobject]@{ original = @() }
        pairs = [pscustomobject]@{
            full = @()
            hints = @()
        }
    }

    if ($sections.Keys -contains 'direction_markers') {
        $section = $sections['direction_markers']
        if ($section.Keys -contains 'original') {
            $config.direction_markers.original = ConvertTo-List -Value $section['original']
        }
    }

    foreach ($sectionName in $sections.Keys) {
        if ($sectionName -like 'full.*') {
            $name = $sectionName.Substring(5)
            if (-not $name) { $name = 'entry' }
            $section = $sections[$sectionName]
            $config.pairs.full += [pscustomobject]@{
                name = $name
                original = if ($section.Keys -contains 'original') { $section['original'] } else { $null }
                anonymized = if ($section.Keys -contains 'anonymized') { $section['anonymized'] } else { $null }
            }
        }
        elseif ($sectionName -like 'hint.*') {
            $name = $sectionName.Substring(5)
            if (-not $name) { $name = 'entry' }
            $section = $sections[$sectionName]
            $assignments = if ($section.Keys -contains 'assignments') { Parse-Assignments -Value $section['assignments'] } else { @() }
            $hintObj = [pscustomobject]@{
                name = $name
                hint = if ($section.Keys -contains 'hint') { $section['hint'] } else { $null }
                prefix = if ($section.Keys -contains 'prefix') { $section['prefix'] } else { $null }
                width = if ($section.Keys -contains 'width') { [int]$section['width'] } else { $null }
                next_index = if ($section.Keys -contains 'next_index') { [int]$section['next_index'] } else { $null }
                assignments = $assignments
            }
            $config.pairs.hints += $hintObj
        }
    }

    Convert-HintAssignmentsToFull -Config $config
    return $config
}

function Ensure-ConfigShape {
    param([pscustomobject]$Config)

    if (-not $Config.PSObject.Properties.Match('direction_markers')) {
        $Config | Add-Member -NotePropertyName 'direction_markers' -NotePropertyValue ([pscustomobject]@{original=@()})
    }
    elseif (-not $Config.direction_markers.PSObject.Properties.Match('original')) {
        $Config.direction_markers | Add-Member -NotePropertyName 'original' -NotePropertyValue @()
    }

    if (-not $Config.PSObject.Properties.Match('pairs')) {
        $Config | Add-Member -NotePropertyName 'pairs' -NotePropertyValue ([pscustomobject]@{full=@(); hints=@()})
    } else {
        if (-not $Config.pairs.PSObject.Properties.Match('full')) {
            $Config.pairs | Add-Member -NotePropertyName 'full' -NotePropertyValue @()
        }
        if (-not $Config.pairs.PSObject.Properties.Match('hints')) {
            $Config.pairs | Add-Member -NotePropertyName 'hints' -NotePropertyValue @()
        }
    }
}

function Save-ConfigObject {
    param(
        [pscustomobject]$Config,
        [string]$Path
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $markerLine = if ($Config.direction_markers.original) { $Config.direction_markers.original -join ',' } else { '' }
    $lines.Add('[direction_markers]')
    $lines.Add("original=$markerLine")
    $lines.Add('')

    foreach ($pair in $Config.pairs.full) {
        $name = if ($pair.name) { $pair.name } else { 'entry' }
        $lines.Add("[full.$name]")
        $lines.Add("original=$($pair.original)")
        $lines.Add("anonymized=$($pair.anonymized)")
        $lines.Add('')
    }

    foreach ($hint in $Config.pairs.hints) {
        $name = if ($hint.name) { $hint.name } else { 'entry' }
        $lines.Add("[hint.$name]")
        $lines.Add("hint=$($hint.hint)")
        $lines.Add("prefix=$($hint.prefix)")
        $widthValue = if ($hint.width) { $hint.width } else { 4 }
        $nextValue = if ($hint.next_index) { $hint.next_index } else { 1 }
        $lines.Add("width=$widthValue")
        $lines.Add("next_index=$nextValue")
        $lines.Add('')
    }

    $content = ($lines -join [Environment]::NewLine).TrimEnd()
    Set-Content -Path $Path -Value $content
}

function Get-DirectionFromMarkers {
    param(
        [string]$Text,
        [string[]]$Markers
    )

    if (-not $Markers -or $Markers.Count -eq 0) {
        return 'Unknown'
    }

    foreach ($marker in $Markers) {
        if ([string]::IsNullOrWhiteSpace($marker)) {
            continue
        }
        $pattern = [regex]::Escape($marker)
        if ([System.Text.RegularExpressions.Regex]::IsMatch($Text, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            return 'Original'
        }
    }

    return 'Unknown'
}

function Detect-DirectionFromFullPairs {
    param(
        [string]$Text,
        [object[]]$Pairs
    )

    if (-not $Pairs -or $Pairs.Count -eq 0) {
        return 'None'
    }

    $originalHit = $false
    $anonymHit = $false

    foreach ($pair in $Pairs) {
        if (-not $pair) { continue }
        if ($pair.original -and -not $originalHit) {
            $pattern = [System.Text.RegularExpressions.Regex]::new([regex]::Escape($pair.original), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($pattern.IsMatch($Text)) {
                $originalHit = $true
            }
        }
        if ($pair.anonymized -and -not $anonymHit) {
            $patternB = [System.Text.RegularExpressions.Regex]::new([regex]::Escape($pair.anonymized), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($patternB.IsMatch($Text)) {
                $anonymHit = $true
            }
        }

        if ($originalHit -and $anonymHit) {
            break
        }
    }

    if ($originalHit -and -not $anonymHit) { return 'Original' }
    if ($anonymHit -and -not $originalHit) { return 'Anonymized' }
    if ($originalHit -and $anonymHit) { return 'Ambiguous' }
    return 'Unknown'
}

function Apply-FullReplacements {
    param(
        [string]$InputText,
        [object[]]$Pairs,
        [ValidateSet('Original','Anonymized')]
        [string]$Direction
    )

    if (-not $Pairs) {
        return ,@($InputText, 0)
    }
    $result = $InputText
    $total = 0

    foreach ($pair in $Pairs) {
        if (-not ($pair.PSObject.Properties.Match('original') -and $pair.PSObject.Properties.Match('anonymized'))) {
            continue
        }
        $from = if ($Direction -eq 'Original') { $pair.original } else { $pair.anonymized }
        $to = if ($Direction -eq 'Original') { $pair.anonymized } else { $pair.original }

        if ([string]::IsNullOrWhiteSpace($from) -or [string]::IsNullOrWhiteSpace($to)) {
            continue
        }

        $regex = [System.Text.RegularExpressions.Regex]::new([regex]::Escape($from), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $matches = $regex.Matches($result)
        if ($matches.Count -eq 0) {
            continue
        }
        $result = $regex.Replace($result, $to)
        $total += $matches.Count
    }

    return ,@($result, $total)
}

function Get-NextHintValue {
    param([pscustomobject]$Hint)

    $prefix = if ($Hint.PSObject.Properties.Match('prefix') -and $Hint.prefix) { [string]$Hint.prefix } else { 'HINT' }
    $width = if ($Hint.PSObject.Properties.Match('width') -and $Hint.width) { [int]$Hint.width } else { 4 }
    $next = if ($Hint.PSObject.Properties.Match('next_index') -and $Hint.next_index) { [int]$Hint.next_index } else { 1 }

    $value = $prefix + $next.ToString(("D{0}" -f $width))
    $Hint.next_index = $next + 1
    return $value
}

function Apply-HintAnonymization {
    param(
        [string]$InputText,
        [object[]]$Hints,
        [pscustomobject]$Config,
        [ref]$ConfigChanged
    )

    if (-not $Hints) {
        return ,@($InputText, 0)
    }
    $result = $InputText
    $total = 0

    for ($i = 0; $i -lt $Hints.Count; $i++) {
        $entry = $Hints[$i]
        if (-not $entry) { continue }
        if (-not $entry.PSObject.Properties.Match('hint')) { continue }

        $hintPattern = [string]$entry.hint
        if ([string]::IsNullOrWhiteSpace($hintPattern)) { continue }

        try {
            $regex = [System.Text.RegularExpressions.Regex]::new($hintPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
        catch {
            throw "Ungültiges Regex in hint '$($entry.name)': $($_.Exception.Message)"
        }
        $matches = $regex.Matches($result)
        if ($matches.Count -eq 0) { continue }
        Write-Verbose ("[hint:{0}] matches={1}" -f $entry.name, $matches.Count)

        $uniqueOrder = New-Object System.Collections.Generic.List[string]
        $uniqueMap = @{}
        foreach ($m in $matches) {
            if (-not $m.Value -or $m.Value.Length -eq 0) { continue }
            $key = $m.Value.ToLowerInvariant()
            if (-not $uniqueMap.ContainsKey($key)) {
                $uniqueMap[$key] = $true
                $null = $uniqueOrder.Add($m.Value)
            }
        }

        foreach ($originalValue in $uniqueOrder) {
            $existingPair = Find-FullPairByOriginal -Pairs $Config.pairs.full -OriginalValue $originalValue
            if ($existingPair) {
                $replacement = $existingPair.anonymized
            } else {
                $replacement = Get-NextHintValue -Hint $entry
                Add-HintFullPair -Config $Config -OriginalValue $originalValue -AnonymizedValue $replacement | Out-Null
                $ConfigChanged.Value = $true
            }

            $patternExact = [System.Text.RegularExpressions.Regex]::new([regex]::Escape($originalValue), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $matchesExact = $patternExact.Matches($result)
            if ($matchesExact.Count -eq 0) {
                continue
            }
            Write-Verbose ("[hint:{0}] replacing {1} occurrences of {2} with {3}" -f $entry.name, $matchesExact.Count, $originalValue, $replacement)
            $result = $patternExact.Replace($result, $replacement)
            $total += $matchesExact.Count
        }
    }

    return ,@($result, $total)
}

if (-not $Files -or $Files.Count -eq 0) {
    throw 'Please provide at least one file to process.'
}

if (-not $Config) {
    $defaultConfig = Join-Path -Path (Get-Location) -ChildPath 'deannon.ini'
    if (Test-Path -Path $defaultConfig -PathType Leaf) {
        $Config = $defaultConfig
    } else {
        throw 'Missing --config/-Config and no deannon.ini in the current directory.'
    }
}

$configObject = Get-ConfigObject -Path $Config
Ensure-ConfigShape -Config $configObject
$configChanged = $false
$stats = @()

foreach ($file in $Files) {
    if (-not (Test-Path -Path $file -PathType Leaf)) {
        Write-Warning "File '$file' not found. Skipping."
        continue
    }

    $text = Get-Content -Path $file -Raw
    $directionStatus = Detect-DirectionFromFullPairs -Text $text -Pairs $configObject.pairs.full
    $direction = $null

    switch ($directionStatus) {
        'Original' { $direction = 'Original' }
        'Anonymized' { $direction = 'Anonymized' }
        'Ambiguous' {
            Write-Warning "File '$file' enthält sowohl Original- als auch anonymisierte Tokens; überspringe."
            continue
        }
        'Unknown' {
            $markerDirection = Get-DirectionFromMarkers -Text $text -Markers $configObject.direction_markers.original
            if ($markerDirection -eq 'Original') {
                $direction = 'Original'
            } else {
                Write-Warning "Datei '$file' konnte keiner Richtung zugeordnet werden (keine passenden full-Paare)."
                continue
            }
        }
        'None' {
            $markerDirection = Get-DirectionFromMarkers -Text $text -Markers $configObject.direction_markers.original
            if ($markerDirection -eq 'Original') {
                $direction = 'Original'
            } else {
                Write-Warning "Datei '$file' übersprungen: keine full-Paare konfiguriert und keine direction_markers gefunden."
                continue
            }
        }
    }

    switch ($direction) {
        'Original' {
            $fullResult = Apply-FullReplacements -InputText $text -Pairs $configObject.pairs.full -Direction 'Original'
            $hintResult = Apply-HintAnonymization -InputText $fullResult[0] -Hints $configObject.pairs.hints -Config $configObject -ConfigChanged ([ref]$configChanged)
            $finalText = $hintResult[0]
            $fullCount = $fullResult[1]
            $hintCount = $hintResult[1]
            $mode = 'anonymized'
        }
        'Anonymized' {
            $fullResult = Apply-FullReplacements -InputText $text -Pairs $configObject.pairs.full -Direction 'Anonymized'
            $finalText = $fullResult[0]
            $fullCount = $fullResult[1]
            $hintCount = 0
            $mode = 'deanonymized'
        }
        Default {
            Write-Warning "Datei '$file' konnte nicht klassifiziert werden; überspringe."
            continue
        }
    }

    if ($finalText -ne $text) {
        Set-Content -Path $file -Value $finalText -NoNewline
    }

    $stats += [pscustomobject]@{
        file = $file
        direction = $mode
        full = $fullCount
        hints = $hintCount
    }
}

if ($configChanged) {
    Save-ConfigObject -Config $configObject -Path $Config
}

foreach ($stat in $stats) {
    Write-Host ("[{0}] {1} replacements: full={2}, hints={3}" -f $stat.file, $stat.direction, $stat.full, $stat.hints)
}
