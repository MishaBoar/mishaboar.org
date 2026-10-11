#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Build', 'Serve', 'Setup')]
    [string]$Action = 'Build',

    [ValidateRange(1024, 65535)]
    [int]$Port = 1313
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitOperatingSystem) {
    throw 'This helper requires 64-bit Windows. See README.md for other platforms.'
}

# Keep this version aligned with .github/workflows/gh-pages.yml.
$hugoVersion = '0.126.2'
$root = Split-Path -Parent $PSScriptRoot
$toolDir = Join-Path $root ".tools/hugo/$hugoVersion"
$hugo = Join-Path $toolDir 'hugo.exe'
$buildDir = Join-Path $root '.build'
$destination = Join-Path $buildDir 'public'
if ($Action -eq 'Serve') {
    $destination = Join-Path $buildDir 'preview'
}
$cacheDir = Join-Path $buildDir 'cache'
$resourceDir = Join-Path $buildDir 'resources'

if (-not (Test-Path -LiteralPath $hugo -PathType Leaf)) {
    $asset = "hugo_extended_${hugoVersion}_windows-amd64.zip"
    $releaseUrl = "https://github.com/gohugoio/hugo/releases/download/v$hugoVersion"
    $archive = Join-Path $toolDir $asset
    $checksumFile = Join-Path $toolDir 'checksums.txt'
    New-Item -ItemType Directory -Path $toolDir -Force | Out-Null
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Write-Host "Downloading Hugo Extended $hugoVersion from the official release..."
    Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/hugo_${hugoVersion}_checksums.txt" -OutFile $checksumFile -TimeoutSec 60
    $checksums = Get-Content -LiteralPath $checksumFile -Raw
    $pattern = '(?m)^([a-fA-F0-9]{64})\s+\*?' + [regex]::Escape($asset) + '\r?$'
    $checksum = [regex]::Match([string]$checksums, $pattern)
    if (-not $checksum.Success) {
        throw "The official checksum list does not contain $asset."
    }

    Invoke-WebRequest -UseBasicParsing -Uri "$releaseUrl/$asset" -OutFile $archive -TimeoutSec 180
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $checksum.Groups[1].Value) {
        throw 'Hugo download checksum mismatch. The archive was not extracted or executed.'
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $toolDir -Force
}

$versionOutput = & $hugo version
if ($LASTEXITCODE -ne 0 -or $versionOutput -notmatch ('^hugo v' + [regex]::Escape($hugoVersion) + '[-+ ]') -or $versionOutput -notmatch '\+extended\b') {
    throw "Expected Hugo Extended $hugoVersion at $hugo. Found: $versionOutput"
}
Write-Host $versionOutput
if ($Action -eq 'Setup') {
    return
}

New-Item -ItemType Directory -Path $destination, $cacheDir, $resourceDir -Force | Out-Null
$hugoArgs = @('--source', $root, '--destination', $destination, '--cacheDir', $cacheDir, '--noBuildLock')

# Keep generated resources out of the tracked source and restore the caller's setting.
$previousResourceDir = $env:HUGO_RESOURCEDIR
try {
    $env:HUGO_RESOURCEDIR = $resourceDir
    if ($Action -eq 'Serve') {
        Write-Host "Preview: http://localhost:$Port/ (Ctrl+C to stop)"
        & $hugo server @hugoArgs --bind 127.0.0.1 --port $Port --baseURL "http://localhost:$Port/" --disableFastRender
    } else {
        & $hugo @hugoArgs --environment production --minify
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Hugo $Action failed with exit code $LASTEXITCODE."
    }
} finally {
    $env:HUGO_RESOURCEDIR = $previousResourceDir
}

if ($Action -eq 'Build') {
    Write-Host "Built site: $destination"
}
