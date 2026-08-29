#requires -Version 5.1

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$CodexHome = $(
        if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
            $env:CODEX_HOME
        }
        else {
            Join-Path $HOME '.codex'
        }
    ),
    [switch]$Uninstall,
    [switch]$SkipProcessCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$promptFileName = 'sol-day1-2026-07-09.md'
$expectedPromptSha256 = 'E9778714D505F3DD04D44DB4394024C5FAB5BF6554FC9FAA3CDF9CF776B63BB9'
$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourcePrompt = Join-Path $repositoryRoot "prompts\$promptFileName"
$resolvedCodexHome = [System.IO.Path]::GetFullPath($CodexHome)
$configPath = Join-Path $resolvedCodexHome 'config.toml'
$installedPrompt = Join-Path $resolvedCodexHome $promptFileName
$tomlPromptPath = ([System.IO.Path]::GetFullPath($installedPrompt)).Replace('\', '/')
$managedLine = "model_instructions_file = `"$tomlPromptPath`""

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
}

function Backup-File {
    param([Parameter(Mandatory)][string]$Path)
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
    $backupPath = "$Path.bak-first-love-sol-$stamp"
    Copy-Item -LiteralPath $Path -Destination $backupPath
    $backupPath
}

function Split-TopLevelToml {
    param([AllowEmptyString()][string]$Text)
    $header = [regex]::Match($Text, '(?m)^[ \t]*\[')
    if ($header.Success) {
        return [pscustomobject]@{
            Prefix = $Text.Substring(0, $header.Index)
            Suffix = $Text.Substring($header.Index)
        }
    }
    [pscustomobject]@{
        Prefix = $Text
        Suffix = ''
    }
}

function Set-TopLevelInstructionPath {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$Line
    )

    $newline = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $parts = Split-TopLevelToml -Text $Text
    $prefix = $parts.Prefix
    $suffix = $parts.Suffix
    $pattern = '(?m)^[ \t]*model_instructions_file[ \t]*=[^\r\n]*'
    $matches = [regex]::Matches($prefix, $pattern)
    if ($matches.Count -gt 1) {
        throw 'config.toml contains more than one top-level model_instructions_file entry.'
    }

    if ($matches.Count -eq 1) {
        $prefix = [regex]::Replace($prefix, $pattern, $Line)
        return $prefix + $suffix
    }

    $trimmed = $prefix.TrimEnd("`r", "`n")
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        $nextPrefix = $Line + $newline
    }
    else {
        $nextPrefix = $trimmed + $newline + $Line + $newline
    }
    if (-not [string]::IsNullOrEmpty($suffix)) {
        $nextPrefix += $newline
    }
    $nextPrefix + $suffix
}

function Remove-TopLevelInstructionPath {
    param(
        [AllowEmptyString()][string]$Text,
        [Parameter(Mandatory)][string]$ExpectedLine
    )

    $parts = Split-TopLevelToml -Text $Text
    $prefix = $parts.Prefix
    $suffix = $parts.Suffix
    $pattern = '(?m)^[ \t]*model_instructions_file[ \t]*=[^\r\n]*(?:\r?\n|$)'
    $matches = [regex]::Matches($prefix, $pattern)
    if ($matches.Count -eq 0) {
        return $Text
    }
    if ($matches.Count -gt 1) {
        throw 'config.toml contains more than one top-level model_instructions_file entry.'
    }
    if ($matches[0].Value.Trim() -cne $ExpectedLine) {
        throw 'The top-level model_instructions_file points to another file; refusing to remove it.'
    }
    $prefix.Remove($matches[0].Index, $matches[0].Length) + $suffix
}

function Assert-CodexDesktopStopped {
    if ($SkipProcessCheck -or $env:OS -ne 'Windows_NT') {
        return
    }

    $running = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ieq 'ChatGPT.exe' -or
        ($_.Name -ieq 'codex.exe' -and $_.CommandLine -match '(?:^|\s)app-server(?:\s|$)')
    })
    if ($running.Count -gt 0) {
        throw 'Codex Desktop is running. Exit the app and tray process, then run this script again.'
    }
}

Assert-CodexDesktopStopped

if ($Uninstall) {
    $configBackup = $null
    if (Test-Path -LiteralPath $configPath) {
        $currentConfig = [System.IO.File]::ReadAllText($configPath)
        $nextConfig = Remove-TopLevelInstructionPath -Text $currentConfig -ExpectedLine $managedLine
        if ($nextConfig -cne $currentConfig -and $PSCmdlet.ShouldProcess($configPath, 'Remove First Love Sol configuration')) {
            $configBackup = Backup-File -Path $configPath
            [System.IO.File]::WriteAllText(
                $configPath,
                $nextConfig,
                [System.Text.UTF8Encoding]::new($false)
            )
        }
    }

    $promptRemoved = $false
    if (Test-Path -LiteralPath $installedPrompt) {
        $installedHash = Get-Sha256 -Path $installedPrompt
        if ($installedHash -eq $expectedPromptSha256) {
            if ($PSCmdlet.ShouldProcess($installedPrompt, 'Remove verified First Love Sol prompt')) {
                Remove-Item -LiteralPath $installedPrompt
                $promptRemoved = $true
            }
        }
        else {
            Write-Warning 'The installed prompt was modified, so it was preserved.'
        }
    }

    [pscustomobject]@{
        Mode = 'Uninstall'
        Config = $configPath
        ConfigBackup = $configBackup
        PromptRemoved = $promptRemoved
        RestartRequired = $true
    }
    return
}

if (-not (Test-Path -LiteralPath $sourcePrompt)) {
    throw "Bundled prompt not found: $sourcePrompt"
}
$sourceHash = Get-Sha256 -Path $sourcePrompt
if ($sourceHash -ne $expectedPromptSha256) {
    throw "Bundled prompt hash mismatch. Expected $expectedPromptSha256, received $sourceHash."
}

if (-not (Test-Path -LiteralPath $resolvedCodexHome)) {
    if ($PSCmdlet.ShouldProcess($resolvedCodexHome, 'Create Codex home directory')) {
        [void](New-Item -ItemType Directory -Force -Path $resolvedCodexHome)
    }
}

$promptBackup = $null
$promptInstalled = $false
if (Test-Path -LiteralPath $installedPrompt) {
    $installedHash = Get-Sha256 -Path $installedPrompt
    if ($installedHash -ne $expectedPromptSha256) {
        if ($PSCmdlet.ShouldProcess($installedPrompt, 'Back up and replace prompt')) {
            $promptBackup = Backup-File -Path $installedPrompt
            Copy-Item -LiteralPath $sourcePrompt -Destination $installedPrompt -Force
            $promptInstalled = $true
        }
    }
}
elseif ($PSCmdlet.ShouldProcess($installedPrompt, 'Install verified prompt')) {
    Copy-Item -LiteralPath $sourcePrompt -Destination $installedPrompt
    $promptInstalled = $true
}

$currentConfig = if (Test-Path -LiteralPath $configPath) {
    [System.IO.File]::ReadAllText($configPath)
}
else {
    ''
}
$nextConfig = Set-TopLevelInstructionPath -Text $currentConfig -Line $managedLine
$configBackup = $null
$configChanged = $nextConfig -cne $currentConfig
if ($configChanged -and $PSCmdlet.ShouldProcess($configPath, 'Configure First Love Sol instructions')) {
    if (Test-Path -LiteralPath $configPath) {
        $configBackup = Backup-File -Path $configPath
    }
    [System.IO.File]::WriteAllText(
        $configPath,
        $nextConfig,
        [System.Text.UTF8Encoding]::new($false)
    )
}

if (Test-Path -LiteralPath $installedPrompt) {
    $writtenHash = Get-Sha256 -Path $installedPrompt
    if ($writtenHash -ne $expectedPromptSha256) {
        throw "Installed prompt hash mismatch: $writtenHash"
    }
}

[pscustomobject]@{
    Mode = 'Install'
    CodexHome = $resolvedCodexHome
    Config = $configPath
    ConfigChanged = $configChanged
    ConfigBackup = $configBackup
    Prompt = $installedPrompt
    PromptInstalled = $promptInstalled
    PromptBackup = $promptBackup
    PromptSha256 = $expectedPromptSha256
    RestartRequired = $true
}
