#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$OutputRoot,
    [string]$ToolchainRoot = "D:\codex_playground\.toolchains",
    [switch]$InstallDependencies,
    [switch]$SkipChecks,
    [switch]$NativeInstaller,
    [switch]$NoZip,
    [switch]$KeepSandbox
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Invoke-NativeChecked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Label
    )
    Write-Host "==> $Label"
    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
}

function Import-VsDevEnvironment {
    param([Parameter(Mandatory = $true)][string]$VsDevCmdPath)

    if (-not (Test-Path -LiteralPath $VsDevCmdPath -PathType Leaf)) {
        throw "VS Build Tools environment script not found: $VsDevCmdPath"
    }

    $command = "call `"$VsDevCmdPath`" -no_logo -arch=x64 -host_arch=x64 >nul && set"
    $lines = & $env:ComSpec /d /s /c $command
    if ($LASTEXITCODE -ne 0) {
        throw "VsDevCmd.bat failed with exit code $LASTEXITCODE."
    }

    $changes = @{}
    foreach ($line in $lines) {
        if ($line -notmatch '^([^=]+)=(.*)$') { continue }
        $name = $Matches[1]
        $value = $Matches[2]
        $changes[$name] = [pscustomobject]@{
            value = [Environment]::GetEnvironmentVariable($name, "Process")
        }
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
    return $changes
}

function Restore-EnvironmentChanges {
    param([hashtable]$Changes)
    if ($null -eq $Changes) { return }
    foreach ($name in $Changes.Keys) {
        $oldValue = $Changes[$name].value
        if ($null -eq $oldValue) {
            [Environment]::SetEnvironmentVariable($name, $null, "Process")
        }
        else {
            [Environment]::SetEnvironmentVariable($name, [string]$oldValue, "Process")
        }
    }
}

$ProjectRoot = Get-NormalizedPath $ProjectRoot
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $ProjectRoot "artifacts"
}
$OutputRoot = Get-NormalizedPath $OutputRoot

$desktopRoot = Join-Path $ProjectRoot "apps\desktop"
$cargoToml = Join-Path $desktopRoot "src-tauri\Cargo.toml"
$tauriConfig = Join-Path $desktopRoot "src-tauri\tauri.conf.json"
$launcherSource = Join-Path $ProjectRoot "scripts\start-gpt56-isolated.ps1"
$verificationScript = Join-Path $ProjectRoot "scripts\verify-gpt56-isolation.ps1"
foreach ($required in @($cargoToml, $tauriConfig, $launcherSource, $verificationScript)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required file not found: $required"
    }
}

$tauri = Get-Content -LiteralPath $tauriConfig -Raw -Encoding UTF8 | ConvertFrom-Json
$version = [string]$tauri.version
$cargoText = [System.IO.File]::ReadAllText($cargoToml, [Text.Encoding]::UTF8)
$rustVersionMatch = [regex]::Match($cargoText, '(?m)^rust-version\s*=\s*"([^"]+)"')
$rustToolchain = if ($rustVersionMatch.Success) { "$($rustVersionMatch.Groups[1].Value)-x86_64-pc-windows-msvc" } else { "stable-x86_64-pc-windows-msvc" }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$releaseRoot = Join-Path $OutputRoot ("Codex-X-GPT56-{0}-{1}" -f $version, $stamp)
$portableRoot = Join-Path $releaseRoot "portable"
$prebuildReportPath = Join-Path $releaseRoot "gpt56-prebuild-report.json"
$reportPath = Join-Path $releaseRoot "gpt56-isolation-report.json"

$cargoHome = Join-Path $ToolchainRoot "cargo"
$rustupHome = Join-Path $ToolchainRoot "rustup"
$vsDevCmd = Join-Path $ToolchainRoot "vs-buildtools\Common7\Tools\VsDevCmd.bat"
$cargoExe = Join-Path $cargoHome "bin\cargo.exe"
$rustcExe = Join-Path $cargoHome "bin\rustc.exe"
foreach ($tool in @($cargoExe, $rustcExe)) {
    if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
        throw "Workspace Rust toolchain is incomplete: $tool"
    }
}
$rustToolchainPath = Join-Path $rustupHome ("toolchains\" + $rustToolchain)
if (-not (Test-Path -LiteralPath $rustToolchainPath -PathType Container)) {
    throw "Required workspace Rust toolchain is missing: $rustToolchainPath"
}

$pnpm = (Get-Command pnpm.cmd -ErrorAction Stop).Source
$profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$realCodexHome = Get-NormalizedPath (Join-Path $profile ".codex")
$sandboxRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-x-gpt56-build-" + [Guid]::NewGuid().ToString("N"))
$codexHome = Join-Path $sandboxRoot "codex"
$codexxHome = Join-Path $sandboxRoot "codexx"
$sandboxCodex = Get-NormalizedPath $codexHome
$realPrefix = $realCodexHome + [System.IO.Path]::DirectorySeparatorChar
if ($sandboxCodex.Equals($realCodexHome, [StringComparison]::OrdinalIgnoreCase) -or $sandboxCodex.StartsWith($realPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Isolation guard rejected CODEX_HOME: $sandboxCodex"
}

$managedVariables = @("CARGO_HOME", "CARGO_TARGET_DIR", "RUSTUP_HOME", "RUSTUP_TOOLCHAIN", "CODEX_HOME", "CODEXX_HOME", "CODEXX_GPT56_ISOLATED", "PATH")
$previous = @{}
foreach ($name in $managedVariables) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}
$vsEnvironmentChanges = $null

try {
    New-Item -ItemType Directory -Force -Path $codexHome, $codexxHome, $releaseRoot | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $codexHome "config.toml"), "model = `"gpt-5.6-sol`"`r`n", (New-Object Text.UTF8Encoding($false)))

    $vsEnvironmentChanges = Import-VsDevEnvironment -VsDevCmdPath $vsDevCmd

    $env:CARGO_HOME = $cargoHome
    $env:CARGO_TARGET_DIR = Join-Path $desktopRoot "src-tauri\target"
    $env:RUSTUP_HOME = $rustupHome
    $env:RUSTUP_TOOLCHAIN = $rustToolchain
    $env:CODEX_HOME = $codexHome
    $env:CODEXX_HOME = $codexxHome
    $env:CODEXX_GPT56_ISOLATED = "1"
    $env:PATH = (Join-Path $cargoHome "bin") + [System.IO.Path]::PathSeparator + $env:PATH

    Write-Host "Isolated build environment"
    Write-Host "  CODEX_HOME : $env:CODEX_HOME"
    Write-Host "  CODEXX_HOME: $env:CODEXX_HOME"
    Write-Host "  CARGO_HOME : $env:CARGO_HOME"
    Write-Host "  RUSTUP_HOME: $env:RUSTUP_HOME"
    Write-Host "  VS Dev Cmd : $vsDevCmd"

    $linkExe = (Get-Command link.exe -CommandType Application -ErrorAction Stop).Source
    Write-Host "  MSVC linker : $linkExe"
    Invoke-NativeChecked -FilePath $cargoExe -ArgumentList @("--version") -Label "Cargo preflight"
    Invoke-NativeChecked -FilePath $rustcExe -ArgumentList @("--version") -Label "Rust preflight"
    Invoke-NativeChecked -FilePath $pnpm -ArgumentList @("--version") -Label "pnpm preflight"

    if ($InstallDependencies) {
        Invoke-NativeChecked -FilePath $pnpm -ArgumentList @("install", "--frozen-lockfile") -Label "Install workspace dependencies"
    }
    elseif (-not (Test-Path -LiteralPath (Join-Path $desktopRoot "node_modules\.bin\tauri.cmd") -PathType Leaf)) {
        throw "Desktop dependencies are missing. Re-run with -InstallDependencies."
    }

    if (-not $SkipChecks) {
        & $verificationScript -ProjectRoot $ProjectRoot -ReportPath $prebuildReportPath -ToolchainRoot $ToolchainRoot
        if ($LASTEXITCODE -ne 0) {
            throw "Pre-build isolation verification failed."
        }
    }

    $buildArguments = @("--dir", $desktopRoot, "exec", "tauri", "build")
    if (-not $NativeInstaller) {
        $buildArguments += "--no-bundle"
    }
    Invoke-NativeChecked -FilePath $pnpm -ArgumentList $buildArguments -Label "Build Codex-X GPT56"

    $targetRelease = Join-Path $desktopRoot "src-tauri\target\release"
    $executableCandidates = @(
        (Join-Path $targetRelease "codex-x.exe"),
        (Join-Path $targetRelease "Codex-X GPT56.exe")
    )
    $builtExecutable = $executableCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($builtExecutable)) {
        throw "Build completed but the release executable was not found under $targetRelease."
    }

    New-Item -ItemType Directory -Force -Path $portableRoot | Out-Null
    $portableExecutable = Join-Path $portableRoot "Codex-X GPT56.exe"
    Copy-Item -LiteralPath $builtExecutable -Destination $portableExecutable -Force
    Copy-Item -LiteralPath $launcherSource -Destination (Join-Path $portableRoot "Start-Codex-X-GPT56.ps1") -Force
    Copy-Item -LiteralPath (Join-Path $ProjectRoot "GPT56_OPTIMIZATION.md") -Destination (Join-Path $portableRoot "GPT56_OPTIMIZATION.md") -Force
    Copy-Item -LiteralPath (Join-Path $ProjectRoot "LICENSE") -Destination (Join-Path $portableRoot "LICENSE") -Force

    $cmdLauncher = @'
@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Codex-X-GPT56.ps1"
endlocal
'@
    [System.IO.File]::WriteAllText((Join-Path $portableRoot "Launch-Codex-X-GPT56.cmd"), $cmdLauncher, [Text.Encoding]::ASCII)

    $portableReadme = @"
Codex-X GPT56 $version - isolated portable build

Start with: Launch-Codex-X-GPT56.cmd

The launcher sets process-local paths:
  CODEX_HOME  = .\data\codex
  CODEXX_HOME = .\data\codexx

Do not launch the EXE directly if you want guaranteed separation from the
currently installed Codex/ChatGPT configuration. The launcher does not change
registry or user-level environment variables.
"@
    [System.IO.File]::WriteAllText((Join-Path $portableRoot "README-PORTABLE.txt"), $portableReadme, (New-Object Text.UTF8Encoding($false)))

    & $verificationScript -ProjectRoot $ProjectRoot -ArtifactPath $portableExecutable -ReportPath $reportPath -SkipCommands -ToolchainRoot $ToolchainRoot
    if ($LASTEXITCODE -ne 0) {
        throw "Post-build artifact verification failed."
    }

    $hash = (Get-FileHash -LiteralPath $portableExecutable -Algorithm SHA256).Hash
    [System.IO.File]::WriteAllText((Join-Path $portableRoot "SHA256.txt"), "$hash  Codex-X GPT56.exe`r`n", [Text.Encoding]::ASCII)

    if (-not $NoZip) {
        $zipPath = Join-Path $releaseRoot ("Codex-X-GPT56-{0}-portable.zip" -f $version)
        Compress-Archive -Path (Join-Path $portableRoot "*") -DestinationPath $zipPath -CompressionLevel Optimal -Force
        Write-Host "Portable ZIP: $zipPath"
    }

    if ($NativeInstaller) {
        $bundleRoot = Join-Path $targetRelease "bundle"
        if (Test-Path -LiteralPath $bundleRoot -PathType Container) {
            Copy-Item -LiteralPath $bundleRoot -Destination (Join-Path $releaseRoot "native-installers") -Recurse -Force
        }
    }

    Write-Host "Build completed."
    Write-Host "Portable folder: $portableRoot"
    if (-not $SkipChecks) {
        Write-Host "Pre-build test report: $prebuildReportPath"
    }
    Write-Host "Isolation report: $reportPath"
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
    Restore-EnvironmentChanges -Changes $vsEnvironmentChanges

    if (-not $KeepSandbox -and (Test-Path -LiteralPath $sandboxRoot)) {
        $tempRoot = Get-NormalizedPath ([System.IO.Path]::GetTempPath())
        $candidate = Get-NormalizedPath $sandboxRoot
        if ($candidate.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $candidate -Leaf).StartsWith("codex-x-gpt56-build-")) {
            Remove-Item -LiteralPath $candidate -Recurse -Force
        }
    }
    elseif ($KeepSandbox) {
        Write-Host "Build sandbox retained at: $sandboxRoot"
    }
}
