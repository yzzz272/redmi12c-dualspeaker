#Requires -Version 7.0
<#
  Builds dist/earth-dual-speaker-v0.1.0-experimental.zip.

  The patched /vendor/etc/audio_device.xml is generated from the public device
  baseline (config/stock/audio_device.xml) by appending exactly four kctl lines
  to the speaker_output turnon/turnoff paths. Every other byte is preserved, and
  the script refuses to build if that is not the case.
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
$BaselinePath = Join-Path $Root 'config/stock/audio_device.xml'
$ModuleDir = Join-Path $Root 'module'
$DistDir = Join-Path $Root 'dist'
$ZipPath = Join-Path $DistDir 'earth-dual-speaker-v0.1.0-experimental.zip'
$ZipShaPath = "$ZipPath.sha256"

$PatchedRelPath = 'system/vendor/etc/audio_device.xml'
$PatchedPath = Join-Path $ModuleDir $PatchedRelPath
$CustomizePath = Join-Path $ModuleDir 'customize.sh'
$ModulePropPath = Join-Path $ModuleDir 'module.prop'
$MetaInfRelDir = 'META-INF/com/google/android'
$MetaInfDir = Join-Path $ModuleDir $MetaInfRelDir

$BaselineSha256 = '0d173c2bf7db1b8669926f23135596114f243458697c5dbfc2fa4572a88b56ba'
$ModuleInstallerSha256 = 'bcf4b1d9913f3af17755569c853e0b5a75b8005f6a18eb3f86dadcc0e968c29d'
$MagiskLicenseSha256 = '589ed823e9a84c56feb95ac58e7cf384626b9cbf4fda2a907bc36e103de1bad2'
$ApacheLicenseSha256 = 'cfc7749b96f63bd31c3c42b5c471bf756814053e847c10f3eb003417bc523d30'

$UpstreamModuleInstaller = Join-Path $Root 'provenance/upstream/module_installer.sh'
$UpstreamLicense = Join-Path $Root 'provenance/upstream/LICENSE-GPL-3.0.txt'
$NoticeSource = Join-Path $Root 'provenance/NOTICE-module_installer.txt'
$UpstreamApacheLicense = Join-Path $Root 'provenance/upstream/LICENSE-APACHE-2.0.txt'
$BaselineNoticeSource = Join-Path $Root 'provenance/NOTICE-audio_device_xml.txt'

$UpdaterScriptText = "#MAGISK`n"

# Exact module-relative paths allowed in the ZIP; anything else fails the build.
$ExpectedModuleFiles = @(
    'META-INF/com/google/android/audio_device.xml.LICENSE-Apache-2.0.txt'
    'META-INF/com/google/android/audio_device.xml.NOTICE.txt'
    'META-INF/com/google/android/update-binary'
    'META-INF/com/google/android/update-binary.LICENSE-GPL-3.0.txt'
    'META-INF/com/google/android/update-binary.NOTICE.txt'
    'META-INF/com/google/android/updater-script'
    'customize.sh'
    'module.prop'
    $PatchedRelPath
) | Sort-Object -CaseSensitive

# The four lines this module is allowed to add, and nothing else.
$TurnOnPathLine = '        <path name="speaker_output" value="turnon">'
$TurnOnDacLine = '            <kctl name="DAC In Mux" value="Normal Path" />'
$TurnOnLolLine = '            <kctl name="LOL Mux" value="Playback" />'
$TurnOnGainLine = '            <kctl name="Handset_PGA_GAIN" value="4Db" />'
$TurnOnRcvLine = '            <kctl name="RCV Mux" value="Voice Playback" />'
$TurnOffPathLine = '        <path name="speaker_output" value="turnoff">'
$TurnOffLolLine = '            <kctl name="LOL Mux" value="Open" />'
$TurnOffRcvLine = '            <kctl name="RCV Mux" value="Open" />'
$TurnOffGainLine = '            <kctl name="Handset_PGA_GAIN" value="8Db" />'
$PathEndLine = '        </path>'

function Get-Sha256Hex {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Read-Utf8NoBomText {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "$Path starts with a UTF-8 BOM"
    }
    return [System.Text.UTF8Encoding]::new($false).GetString($bytes)
}

function Write-Utf8NoBomText {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text
    )
    $dir = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    [System.IO.File]::WriteAllBytes($Path, [System.Text.UTF8Encoding]::new($false).GetBytes($Text))
}

function Assert-LfNoBom {
    param([Parameter(Mandatory)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0) { throw "$Path is empty" }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        throw "$Path has a UTF-8 BOM"
    }
    if ($bytes -contains 0x0D) { throw "$Path contains CR bytes (expected LF only)" }
    if ($bytes[$bytes.Length - 1] -ne 0x0A) { throw "$Path does not end with a newline" }
}

function Find-SingleLineIndex {
    param(
        # Split text keeps a trailing empty element, so empty strings are legal here.
        [Parameter(Mandatory)][AllowEmptyString()][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory)][string]$Exact
    )
    $hits = [System.Collections.Generic.List[int]]::new()
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ([string]::Equals($Lines[$i], $Exact, [System.StringComparison]::Ordinal)) { $hits.Add($i) }
    }
    if ($hits.Count -ne 1) {
        throw "Expected exactly one line '$Exact', found $($hits.Count)"
    }
    return $hits[0]
}

function Assert-Line {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory)][int]$Index,
        [Parameter(Mandatory)][string]$Exact
    )
    if ($Index -lt 0 -or $Index -ge $Lines.Count) {
        throw "Line index $Index is out of range (expected '$Exact')"
    }
    if (-not [string]::Equals($Lines[$Index], $Exact, [System.StringComparison]::Ordinal)) {
        throw "Unexpected line at index ${Index}: '$($Lines[$Index])' (expected '$Exact')"
    }
}

function New-PatchedXmlText {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$BaselineText)

    if ($BaselineText.Contains("`r")) { throw 'Baseline audio_device.xml contains CR characters' }

    $lines = [System.Collections.Generic.List[string]]::new([string[]]($BaselineText -split "`n"))

    $turnOnStart = Find-SingleLineIndex -Lines $lines -Exact $TurnOnPathLine
    Assert-Line -Lines $lines -Index ($turnOnStart + 1) -Exact $TurnOnDacLine
    Assert-Line -Lines $lines -Index ($turnOnStart + 2) -Exact $TurnOnLolLine
    Assert-Line -Lines $lines -Index ($turnOnStart + 3) -Exact $PathEndLine

    $turnOffStart = Find-SingleLineIndex -Lines $lines -Exact $TurnOffPathLine
    Assert-Line -Lines $lines -Index ($turnOffStart + 1) -Exact $TurnOffLolLine
    Assert-Line -Lines $lines -Index ($turnOffStart + 2) -Exact $PathEndLine

    if ($turnOffStart -le $turnOnStart) { throw 'speaker_output turnoff must follow turnon' }

    # Insert later block first so the earlier index stays valid.
    $lines.InsertRange(($turnOffStart + 2), [string[]]@($TurnOffRcvLine, $TurnOffGainLine))
    $lines.InsertRange(($turnOnStart + 3), [string[]]@($TurnOnGainLine, $TurnOnRcvLine))

    return ($lines -join "`n")
}

function Get-XmlSignature {
    param(
        [Parameter(Mandatory)][System.Xml.XmlNode]$Node,
        [Parameter(Mandatory)][int]$Depth
    )
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($child in $Node.ChildNodes) {
        if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
            $attrs = foreach ($attr in $child.Attributes) { "$($attr.Name)=$($attr.Value)" }
            $out.Add(('{0}{1}[{2}]' -f ('  ' * $Depth), $child.Name, ($attrs -join ';')))
            foreach ($line in (Get-XmlSignature -Node $child -Depth ($Depth + 1))) { $out.Add($line) }
        }
        elseif ($child.NodeType -eq [System.Xml.XmlNodeType]::Comment) {
            $out.Add(('{0}#comment:{1}' -f ('  ' * $Depth), $child.Value.Trim()))
        }
    }
    return $out
}

function Import-XmlDocument {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Label)
    $doc = [System.Xml.XmlDocument]::new()
    $doc.PreserveWhitespace = $true
    try {
        $doc.LoadXml($Text)
    }
    catch {
        throw "$Label is not well-formed XML: $($_.Exception.Message)"
    }
    return $doc
}

function Remove-KctlNode {
    param(
        [Parameter(Mandatory)][System.Xml.XmlDocument]$Doc,
        [Parameter(Mandatory)][string]$PathName,
        [Parameter(Mandatory)][string]$PathValue,
        [Parameter(Mandatory)][string]$KctlName,
        [Parameter(Mandatory)][string]$KctlValue
    )
    $paths = $Doc.SelectNodes("//mixercontrol/path[@name='$PathName' and @value='$PathValue']")
    if ($paths.Count -ne 1) { throw "Expected one path $PathName/$PathValue, found $($paths.Count)" }
    $nodes = $paths[0].SelectNodes("kctl[@name='$KctlName' and @value='$KctlValue']")
    if ($nodes.Count -ne 1) { throw "Expected one kctl $KctlName=$KctlValue in $PathName/$PathValue, found $($nodes.Count)" }
    [void]$paths[0].RemoveChild($nodes[0])
}

function Get-KctlChildren {
    param(
        [Parameter(Mandatory)][System.Xml.XmlDocument]$Doc,
        [Parameter(Mandatory)][string]$PathName,
        [Parameter(Mandatory)][string]$PathValue
    )
    $paths = $Doc.SelectNodes("//mixercontrol/path[@name='$PathName' and @value='$PathValue']")
    if ($paths.Count -ne 1) { throw "Expected one path $PathName/$PathValue, found $($paths.Count)" }
    return @($paths[0].SelectNodes('kctl'))
}

function Get-ZipExternalAttributes {
    param([Parameter(Mandatory)][int]$UnixMode)
    $shifted = [uint32]([uint32]$UnixMode -shl 16)
    return [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes($shifted), 0)
}

function Set-ZipUnixPlatform {
    # .NET writes "version made by" with platform 0 (MS-DOS), which makes Unix
    # unzip tools ignore the permission bits. Flag every central directory
    # record as Unix (platform 3) so update-binary stays executable in recovery.
    param([Parameter(Mandatory)][string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $eocd = -1
    for ($i = $bytes.Length - 22; $i -ge 0; $i--) {
        if ($bytes[$i] -eq 0x50 -and $bytes[$i + 1] -eq 0x4B -and $bytes[$i + 2] -eq 0x05 -and $bytes[$i + 3] -eq 0x06) {
            $eocd = $i
            break
        }
    }
    if ($eocd -lt 0) { throw 'ZIP end-of-central-directory record not found' }

    $entryCount = [System.BitConverter]::ToUInt16($bytes, $eocd + 10)
    $offset = [int][System.BitConverter]::ToUInt32($bytes, $eocd + 16)
    for ($n = 0; $n -lt $entryCount; $n++) {
        if (-not ($bytes[$offset] -eq 0x50 -and $bytes[$offset + 1] -eq 0x4B -and $bytes[$offset + 2] -eq 0x01 -and $bytes[$offset + 3] -eq 0x02)) {
            throw "ZIP central directory entry $n has an unexpected signature"
        }
        $bytes[$offset + 5] = 3
        $nameLength = [System.BitConverter]::ToUInt16($bytes, $offset + 28)
        $extraLength = [System.BitConverter]::ToUInt16($bytes, $offset + 30)
        $commentLength = [System.BitConverter]::ToUInt16($bytes, $offset + 32)
        $offset += 46 + $nameLength + $extraLength + $commentLength
    }
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

# ---------------------------------------------------------------- generate ---

Write-Host '== earth dual speaker module build ==' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $BaselinePath)) { throw "Baseline not found: $BaselinePath" }
$baselineHash = Get-Sha256Hex -Path $BaselinePath
if ($baselineHash -ne $BaselineSha256) {
    throw "Baseline audio_device.xml hash mismatch: $baselineHash (expected $BaselineSha256)"
}
$baselineText = Read-Utf8NoBomText -Path $BaselinePath
$patchedText = New-PatchedXmlText -BaselineText $baselineText
Write-Utf8NoBomText -Path $PatchedPath -Text $patchedText
$patchedHash = Get-Sha256Hex -Path $PatchedPath
Write-Host "baseline sha256 : $baselineHash"
Write-Host "patched  sha256 : $patchedHash"

# META-INF content is copied from the pinned upstream sources only.
if ((Get-Sha256Hex -Path $UpstreamModuleInstaller) -ne $ModuleInstallerSha256) {
    throw "provenance/upstream/module_installer.sh does not match the pinned upstream hash"
}
if ((Get-Sha256Hex -Path $UpstreamLicense) -ne $MagiskLicenseSha256) {
    throw "provenance/upstream/LICENSE-GPL-3.0.txt does not match the pinned upstream hash"
}
if ((Get-Sha256Hex -Path $UpstreamApacheLicense) -ne $ApacheLicenseSha256) {
    throw "provenance/upstream/LICENSE-APACHE-2.0.txt does not match the pinned upstream hash"
}
if (-not (Test-Path -LiteralPath $NoticeSource)) { throw "Missing $NoticeSource" }
if (-not (Test-Path -LiteralPath $BaselineNoticeSource)) { throw "Missing $BaselineNoticeSource" }

New-Item -ItemType Directory -Path $MetaInfDir -Force | Out-Null
Copy-Item -LiteralPath $UpstreamModuleInstaller -Destination (Join-Path $MetaInfDir 'update-binary') -Force
Copy-Item -LiteralPath $UpstreamLicense -Destination (Join-Path $MetaInfDir 'update-binary.LICENSE-GPL-3.0.txt') -Force
Copy-Item -LiteralPath $NoticeSource -Destination (Join-Path $MetaInfDir 'update-binary.NOTICE.txt') -Force
Copy-Item -LiteralPath $UpstreamApacheLicense -Destination (Join-Path $MetaInfDir 'audio_device.xml.LICENSE-Apache-2.0.txt') -Force
Copy-Item -LiteralPath $BaselineNoticeSource -Destination (Join-Path $MetaInfDir 'audio_device.xml.NOTICE.txt') -Force
Write-Utf8NoBomText -Path (Join-Path $MetaInfDir 'updater-script') -Text $UpdaterScriptText

# --------------------------------------------------------------- validate ---

Write-Host '-- validating module tree'
if (-not (Test-Path -LiteralPath $CustomizePath)) { throw "Missing $CustomizePath" }

$actualFiles = Get-ChildItem -LiteralPath $ModuleDir -Recurse -File |
    ForEach-Object { $_.FullName.Substring($ModuleDir.Length + 1).Replace('\', '/') } |
    Sort-Object -CaseSensitive
$missing = $ExpectedModuleFiles | Where-Object { $actualFiles -notcontains $_ }
$unexpected = $actualFiles | Where-Object { $ExpectedModuleFiles -notcontains $_ }
if ($missing) { throw "Missing module files: $($missing -join ', ')" }
if ($unexpected) { throw "Unexpected module files: $($unexpected -join ', ')" }

$emptyDirs = Get-ChildItem -LiteralPath $ModuleDir -Recurse -Directory |
    Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force) }
if ($emptyDirs) { throw "Empty directories in module tree: $($emptyDirs.FullName -join ', ')" }

Write-Host '-- validating line endings and encodings'
foreach ($rel in @(
        'customize.sh'
        'module.prop'
        'META-INF/com/google/android/update-binary'
        'META-INF/com/google/android/updater-script'
        'META-INF/com/google/android/update-binary.NOTICE.txt'
        'META-INF/com/google/android/audio_device.xml.NOTICE.txt'
        'META-INF/com/google/android/audio_device.xml.LICENSE-Apache-2.0.txt'
    )) {
    Assert-LfNoBom -Path (Join-Path $ModuleDir $rel)
}
Assert-LfNoBom -Path $PatchedPath

Write-Host '-- validating module.prop'
$propText = Read-Utf8NoBomText -Path $ModulePropPath
$prop = @{}
foreach ($line in ($propText -split "`n")) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -notmatch '^([a-zA-Z]+)=(.*)$') { throw "module.prop has a malformed line: '$line'" }
    $prop[$Matches[1]] = $Matches[2]
}
foreach ($key in @('id', 'name', 'version', 'versionCode', 'author', 'description')) {
    if (-not $prop.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($prop[$key])) {
        throw "module.prop is missing '$key'"
    }
}
if ($prop['id'] -notmatch '^[a-zA-Z][a-zA-Z0-9._-]+$') { throw "module.prop id is invalid: $($prop['id'])" }
if ($prop['id'] -ne 'earth_dual_speaker') { throw "module.prop id must be earth_dual_speaker, got $($prop['id'])" }
if ($prop['version'] -ne 'v0.1.0-experimental') { throw "module.prop version must be v0.1.0-experimental, got $($prop['version'])" }
if ($prop['versionCode'] -ne '1') { throw "module.prop versionCode must be 1, got $($prop['versionCode'])" }

Write-Host '-- validating updater-script'
$updaterScript = Read-Utf8NoBomText -Path (Join-Path $MetaInfDir 'updater-script')
if ($updaterScript -ne $UpdaterScriptText) { throw 'updater-script must contain only the string #MAGISK' }

Write-Host '-- validating update-binary provenance'
if ((Get-Sha256Hex -Path (Join-Path $MetaInfDir 'update-binary')) -ne $ModuleInstallerSha256) {
    throw 'module update-binary does not match the pinned upstream module_installer.sh'
}
if ((Get-Sha256Hex -Path (Join-Path $MetaInfDir 'update-binary.LICENSE-GPL-3.0.txt')) -ne $MagiskLicenseSha256) {
    throw 'module GPL-3.0 license copy does not match the pinned upstream LICENSE'
}

Write-Host '-- validating overlay provenance'
if ((Get-Sha256Hex -Path (Join-Path $MetaInfDir 'audio_device.xml.LICENSE-Apache-2.0.txt')) -ne $ApacheLicenseSha256) {
    throw 'module Apache-2.0 license copy does not match the pinned upstream LICENSE'
}
if ((Get-Sha256Hex -Path (Join-Path $MetaInfDir 'audio_device.xml.NOTICE.txt')) -ne (Get-Sha256Hex -Path $BaselineNoticeSource)) {
    throw 'module overlay notice does not match provenance/NOTICE-audio_device_xml.txt'
}
$baselineNoticeText = Read-Utf8NoBomText -Path $BaselineNoticeSource
foreach ($needle in @($BaselineSha256, $patchedHash, '87007ad3e1ada83423abe0d560809b9a1c8ffda9', 'Apache License 2.0')) {
    if (-not $baselineNoticeText.Contains($needle)) {
        throw "provenance/NOTICE-audio_device_xml.txt is missing '$needle'"
    }
}

Write-Host '-- validating customize.sh guards'
$customizeText = Read-Utf8NoBomText -Path $CustomizePath
foreach ($pair in @(
        @{ Name = 'BASELINE_SHA256'; Value = $BaselineSha256 }
        @{ Name = 'PATCHED_SHA256'; Value = $patchedHash }
    )) {
    $match = [regex]::Match($customizeText, "(?m)^$($pair.Name)=""([0-9a-f]{64})""$")
    if (-not $match.Success) { throw "customize.sh does not declare $($pair.Name)" }
    if ($match.Groups[1].Value -ne $pair.Value) {
        throw "customize.sh $($pair.Name) is $($match.Groups[1].Value), expected $($pair.Value)"
    }
}
foreach ($needle in @('ro.product.device', 'ro.lineage.version', 'uname -r', 'e1d7983c7a49', 'abort')) {
    if (-not $customizeText.Contains($needle)) { throw "customize.sh is missing the guard token '$needle'" }
}
foreach ($needle in @('NOT SAFETY RATED', 'media volume 3/15', 'ringtone', 'speakerphone', 'install time', 'BEFORE any ROM, OTA or kernel change')) {
    if (-not $customizeText.Contains($needle)) { throw "customize.sh is missing the required install message '$needle'" }
}

# No runtime work of any kind: no reboot, no exit, no mixer/property access, no boot scripts.
$codeLines = @($customizeText -split "`n" | Where-Object { $_ -notmatch '^\s*#' })
foreach ($command in @('reboot', 'exit')) {
    $hit = $codeLines | Where-Object { $_ -match "^\s*$([regex]::Escape($command))\b" }
    if ($hit) { throw "customize.sh must not call '$command': $($hit[0].Trim())" }
}
foreach ($token in @('tinymix', 'resetprop', 'magiskpolicy', 'setprop', 'service.sh', 'post-fs-data.sh', 'action.sh', 'uninstall.sh')) {
    $hit = $codeLines | Where-Object { $_ -match [regex]::Escape($token) }
    if ($hit) { throw "customize.sh must not reference '$token': $($hit[0].Trim())" }
}

Write-Host '-- validating patched XML'
$patchedDoc = Import-XmlDocument -Text $patchedText -Label 'patched audio_device.xml'
$baselineDoc = Import-XmlDocument -Text $baselineText -Label 'baseline audio_device.xml'

$turnOnKctl = Get-KctlChildren -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnon'
if ($turnOnKctl.Count -ne 4) { throw "speaker_output/turnon must have 4 kctl nodes, found $($turnOnKctl.Count)" }
$turnOnExpected = @(
    'DAC In Mux=Normal Path'
    'LOL Mux=Playback'
    'Handset_PGA_GAIN=4Db'
    'RCV Mux=Voice Playback'
)
for ($i = 0; $i -lt $turnOnExpected.Count; $i++) {
    $actual = "$($turnOnKctl[$i].GetAttribute('name'))=$($turnOnKctl[$i].GetAttribute('value'))"
    if (-not [string]::Equals($actual, $turnOnExpected[$i], [System.StringComparison]::Ordinal)) {
        throw "speaker_output/turnon node $i is $actual, expected $($turnOnExpected[$i])"
    }
}

$turnOffKctl = Get-KctlChildren -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnoff'
if ($turnOffKctl.Count -ne 3) { throw "speaker_output/turnoff must have 3 kctl nodes, found $($turnOffKctl.Count)" }
$turnOffExpected = @(
    'LOL Mux=Open'
    'RCV Mux=Open'
    'Handset_PGA_GAIN=8Db'
)
for ($i = 0; $i -lt $turnOffExpected.Count; $i++) {
    $actual = "$($turnOffKctl[$i].GetAttribute('name'))=$($turnOffKctl[$i].GetAttribute('value'))"
    if (-not [string]::Equals($actual, $turnOffExpected[$i], [System.StringComparison]::Ordinal)) {
        throw "speaker_output/turnoff node $i is $actual, expected $($turnOffExpected[$i])"
    }
}

$gainCount = ([regex]::Matches($patchedText, 'Handset_PGA_GAIN')).Count
if ($gainCount -ne 2) { throw "Expected exactly 2 Handset_PGA_GAIN occurrences, found $gainCount" }
$baselineRcvCount = ([regex]::Matches($baselineText, '"RCV Mux"')).Count
$patchedRcvCount = ([regex]::Matches($patchedText, '"RCV Mux"')).Count
if ($patchedRcvCount -ne ($baselineRcvCount + 2)) {
    throw "RCV Mux occurrence count changed by $($patchedRcvCount - $baselineRcvCount), expected +2"
}
# Microphone / ADC controls must never be touched (PGA L/R Mux are the mic PGAs in this XML).
foreach ($mic in @('Audio_PGA1', 'Audio_PGA2', 'PGA L Mux', 'PGA R Mux', 'ADC L Mux', 'ADC R Mux')) {
    if (([regex]::Matches($patchedText, [regex]::Escape($mic))).Count -ne ([regex]::Matches($baselineText, [regex]::Escape($mic))).Count) {
        throw "$mic occurrences changed"
    }
}

$baselinePathCount = $baselineDoc.SelectNodes('//mixercontrol/path').Count
$patchedPathCount = $patchedDoc.SelectNodes('//mixercontrol/path').Count
if ($baselinePathCount -ne $patchedPathCount) {
    throw "Path count changed: $baselinePathCount -> $patchedPathCount"
}

# Strict semantic diff: drop the four expected nodes, then the trees must match.
Remove-KctlNode -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnon' -KctlName 'Handset_PGA_GAIN' -KctlValue '4Db'
Remove-KctlNode -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnon' -KctlName 'RCV Mux' -KctlValue 'Voice Playback'
Remove-KctlNode -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnoff' -KctlName 'RCV Mux' -KctlValue 'Open'
Remove-KctlNode -Doc $patchedDoc -PathName 'speaker_output' -PathValue 'turnoff' -KctlName 'Handset_PGA_GAIN' -KctlValue '8Db'

$patchedSignature = Get-XmlSignature -Node $patchedDoc.DocumentElement -Depth 0
$baselineSignature = Get-XmlSignature -Node $baselineDoc.DocumentElement -Depth 0
if ($patchedSignature.Count -ne $baselineSignature.Count) {
    throw "Semantic tree size differs after removing the four expected nodes: $($patchedSignature.Count) vs $($baselineSignature.Count)"
}
for ($i = 0; $i -lt $baselineSignature.Count; $i++) {
    if (-not [string]::Equals($patchedSignature[$i], $baselineSignature[$i], [System.StringComparison]::Ordinal)) {
        throw "Semantic tree differs at node $i : '$($patchedSignature[$i])' vs '$($baselineSignature[$i])'"
    }
}

# Byte preservation: undoing the four appended lines must reproduce the baseline.
$reverted = $patchedText.
    Replace(($TurnOnGainLine + "`n" + $TurnOnRcvLine + "`n"), '').
    Replace(($TurnOffRcvLine + "`n" + $TurnOffGainLine + "`n"), '')
if (-not [string]::Equals($reverted, $baselineText, [System.StringComparison]::Ordinal)) {
    throw 'Removing the appended lines does not reproduce the baseline byte-for-byte'
}
$addedLineCount = (($patchedText -split "`n").Count) - (($baselineText -split "`n").Count)
if ($addedLineCount -ne 4) { throw "Expected exactly 4 added lines, found $addedLineCount" }

# -------------------------------------------------------------------- zip ---

Write-Host '-- building ZIP'
if (-not (Test-Path -LiteralPath $DistDir)) { New-Item -ItemType Directory -Path $DistDir -Force | Out-Null }
foreach ($old in @($ZipPath, $ZipShaPath)) {
    if (Test-Path -LiteralPath $old) { Remove-Item -LiteralPath $old -Force }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$fixedTimestamp = [DateTimeOffset]::new(2009, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
$fileStream = [System.IO.File]::Create($ZipPath)
try {
    $archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($rel in $ExpectedModuleFiles) {
            $source = Join-Path $ModuleDir $rel
            $entry = $archive.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedTimestamp
            $unixMode = if ($rel -eq 'META-INF/com/google/android/update-binary') { 0x81ED } else { 0x81A4 }
            $entry.ExternalAttributes = Get-ZipExternalAttributes -UnixMode $unixMode
            $entryStream = $entry.Open()
            try {
                $payload = [System.IO.File]::ReadAllBytes($source)
                $entryStream.Write($payload, 0, $payload.Length)
            }
            finally {
                $entryStream.Dispose()
            }
        }
    }
    finally {
        $archive.Dispose()
    }
}
finally {
    $fileStream.Dispose()
}
Set-ZipUnixPlatform -Path $ZipPath

Write-Host '-- verifying ZIP'
$zipArchive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
try {
    $entryNames = @($zipArchive.Entries | ForEach-Object { $_.FullName })
    if ($entryNames.Count -ne $ExpectedModuleFiles.Count) {
        throw "ZIP has $($entryNames.Count) entries, expected $($ExpectedModuleFiles.Count)"
    }
    foreach ($name in $entryNames) {
        if ($name.Contains('\')) { throw "ZIP entry uses a backslash: $name" }
        if ($ExpectedModuleFiles -notcontains $name) { throw "Unexpected ZIP entry: $name" }
        if ($name -match '^(module|earth_dual_speaker)/') { throw "ZIP entry is nested under a top-level folder: $name" }
    }
    foreach ($rel in $ExpectedModuleFiles) {
        if ($entryNames -notcontains $rel) { throw "ZIP is missing entry: $rel" }
        $entry = $zipArchive.GetEntry($rel)
        $stream = $entry.Open()
        try {
            $buffer = [System.IO.MemoryStream]::new()
            $stream.CopyTo($buffer)
            $zipBytes = $buffer.ToArray()
        }
        finally {
            $stream.Dispose()
        }
        $sourceBytes = [System.IO.File]::ReadAllBytes((Join-Path $ModuleDir $rel))
        if (-not [System.Linq.Enumerable]::SequenceEqual([byte[]]$zipBytes, [byte[]]$sourceBytes)) {
            throw "ZIP entry content differs from module file: $rel"
        }
    }
}
finally {
    $zipArchive.Dispose()
}

$zipHash = Get-Sha256Hex -Path $ZipPath
$zipSize = (Get-Item -LiteralPath $ZipPath).Length
Write-Utf8NoBomText -Path $ZipShaPath -Text ("{0}  {1}`n" -f $zipHash, (Split-Path -Leaf $ZipPath))

Write-Host ''
Write-Host 'BUILD OK' -ForegroundColor Green
Write-Host "zip            : $ZipPath"
Write-Host "zip bytes      : $zipSize"
Write-Host "zip sha256     : $zipHash"
Write-Host "entries        : $($ExpectedModuleFiles.Count)"
Write-Host "baseline sha256: $BaselineSha256"
Write-Host "patched  sha256: $patchedHash"
