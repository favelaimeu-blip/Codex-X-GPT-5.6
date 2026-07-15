#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ExePath,
    [string]$DataRoot,
    [switch]$Wait
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Assert-OutsideRealCodexHome {
    param([Parameter(Mandatory = $true)][string]$Candidate)

    $profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrWhiteSpace($profile)) {
        throw "Cannot resolve the Windows user profile for the isolation guard."
    }

    $realCodexHome = Get-NormalizedPath (Join-Path $profile ".codex")
    $candidatePath = Get-NormalizedPath $Candidate
    $prefix = $realCodexHome + [System.IO.Path]::DirectorySeparatorChar
    if ($candidatePath.Equals($realCodexHome, [StringComparison]::OrdinalIgnoreCase) -or
        $candidatePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to use the active user Codex directory: $candidatePath"
    }
}

$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$portableRoot = Split-Path -Parent $scriptDirectory
if (-not (Test-Path -LiteralPath (Join-Path $portableRoot "Codex-X GPT-5.6.exe"))) {
    # When this source script is run directly, its parent is the repository root.
    $portableRoot = $scriptDirectory
}

if ([string]::IsNullOrWhiteSpace($ExePath)) {
    $candidates = @(
        (Join-Path $portableRoot "Codex-X GPT-5.6.exe"),
        (Join-Path $portableRoot "codex-x.exe"),
        (Join-Path $portableRoot "Codex-X.exe")
    )
    $ExePath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
}

if ([string]::IsNullOrWhiteSpace($ExePath) -or -not (Test-Path -LiteralPath $ExePath -PathType Leaf)) {
    throw "Codex-X GPT-5.6 executable not found. Pass -ExePath explicitly or keep this launcher beside the portable executable."
}

$ExePath = Get-NormalizedPath $ExePath
$portableRoot = Split-Path -Parent $ExePath
if ([string]::IsNullOrWhiteSpace($DataRoot)) {
    $DataRoot = Join-Path $portableRoot "data"
}
$DataRoot = Get-NormalizedPath $DataRoot

$codexHome = Join-Path $DataRoot "codex"
$codexxHome = Join-Path $DataRoot "codexx"
Assert-OutsideRealCodexHome -Candidate $codexHome

New-Item -ItemType Directory -Force -Path $codexHome, $codexxHome | Out-Null

$managedVariables = @("CODEX_HOME", "CODEXX_HOME", "CODEXX_GPT56_ISOLATED")
$previous = @{}
foreach ($name in $managedVariables) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}

try {
    # These variables are inherited only by the child process. They are not
    # written to the registry and do not change the user's global environment.
    $env:CODEX_HOME = $codexHome
    $env:CODEXX_HOME = $codexxHome
    $env:CODEXX_GPT56_ISOLATED = "1"

    Write-Host "Starting Codex-X GPT-5.6 in isolated mode"
    Write-Host "  CODEX_HOME : $codexHome"
    Write-Host "  CODEXX_HOME: $codexxHome"

    $process = Start-Process -FilePath $ExePath -WorkingDirectory $portableRoot -PassThru
    if ($Wait) {
        $process.WaitForExit()
        exit $process.ExitCode
    }
}
finally {
    foreach ($name in $managedVariables) {
        $oldValue = $previous[$name]
        if ($null -eq $oldValue) {
            Remove-Item -LiteralPath "Env:$name" -ErrorAction SilentlyContinue
        }
        else {
            [Environment]::SetEnvironmentVariable($name, $oldValue, "Process")
        }
    }
}

