[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Get-Location) 'sol-day1-2026-07-09.md'),
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('System.Net.Http.HttpClient' -as [type])) {
    Add-Type -AssemblyName System.Net.Http
}

$commit = '3380969a29134630d56feb6218e8e8dcc5e8196d'
$sourceUri = "https://raw.githubusercontent.com/openai/codex/$commit/codex-rs/models-manager/models.json"
$expectedSourceSha256 = 'DCAB00231A5178A9C84B7AEF4CC06A1E1359E37EE0DD7E69D5822C4B1DE723B1'
$expectedPromptSha256 = 'E9778714D505F3DD04D44DB4394024C5FAB5BF6554FC9FAA3CDF9CF776B63BB9'

function Get-BytesSha256 {
    param([Parameter(Mandatory)][byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

$client = [System.Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.UserAgent.ParseAdd('first-love-sol/1.0')
try {
    $sourceBytes = $client.GetByteArrayAsync($sourceUri).GetAwaiter().GetResult()
}
finally {
    $client.Dispose()
}

$sourceSha256 = Get-BytesSha256 -Bytes $sourceBytes
if ($sourceSha256 -ne $expectedSourceSha256) {
    throw "Upstream source hash mismatch. Expected $expectedSourceSha256, received $sourceSha256."
}

$sourceText = [System.Text.Encoding]::UTF8.GetString($sourceBytes)
$catalog = $sourceText | ConvertFrom-Json
$matches = @($catalog.models | Where-Object { $_.slug -eq 'gpt-5.6-sol' })
if ($matches.Count -ne 1) {
    throw "Expected exactly one gpt-5.6-sol model record, found $($matches.Count)."
}

$model = $matches[0]
$template = [string]$model.model_messages.instructions_template
$base = [string]$model.base_instructions
if ($template -cne $base) {
    throw 'The upstream instructions_template and base_instructions fields are not identical.'
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$promptBytes = $utf8NoBom.GetBytes($template)
$promptSha256 = Get-BytesSha256 -Bytes $promptBytes
if ($promptSha256 -ne $expectedPromptSha256) {
    throw "Extracted prompt hash mismatch. Expected $expectedPromptSha256, received $promptSha256."
}

$targetPath = [System.IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $targetPath) {
    $existingSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetPath).Hash
    if ($existingSha256 -eq $expectedPromptSha256) {
        Write-Host "Already verified: $targetPath"
        Write-Host "SHA-256: $existingSha256"
        return
    }
    if (-not $Force) {
        throw "Output exists with a different hash. Use -Force to create a backup and replace it: $targetPath"
    }
    $backupPath = "$targetPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $targetPath -Destination $backupPath
}
else {
    $parent = Split-Path -Parent $targetPath
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        [void](New-Item -ItemType Directory -Force -Path $parent)
    }
}

[System.IO.File]::WriteAllBytes($targetPath, $promptBytes)
$writtenSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetPath).Hash
if ($writtenSha256 -ne $expectedPromptSha256) {
    throw "Post-write hash mismatch: $writtenSha256"
}

Write-Host "Extracted: $targetPath"
if ($null -ne (Get-Variable -Name backupPath -ErrorAction SilentlyContinue)) {
    Write-Host "Backup: $backupPath"
}
Write-Host "Source: $sourceUri"
Write-Host "SHA-256: $writtenSha256"
