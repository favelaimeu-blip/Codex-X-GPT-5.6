#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)),
    [string]$ArtifactPath,
    [string]$ReportPath,
    [switch]$SkipCommands,
    [string]$ToolchainRoot = "D:\codex_playground\.toolchains"
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
$checks = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][bool]$Passed,
        [Parameter(Mandatory = $true)][string]$Details
    )
    $script:checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        details = $Details
    })
    $marker = if ($Passed) { "PASS" } else { "FAIL" }
    Write-Host "[$marker] $Name - $Details"
}

function Test-TextContains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Needle,
        [Parameter(Mandatory = $true)][string]$Name
    )
    $text = [System.IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    Add-Check -Name $Name -Passed $text.Contains($Needle) -Details $Needle
}

$tauriPath = Join-Path $ProjectRoot "apps\desktop\src-tauri\tauri.conf.json"
$rootPackagePath = Join-Path $ProjectRoot "package.json"
$desktopPackagePath = Join-Path $ProjectRoot "apps\desktop\package.json"
$cargoTomlPath = Join-Path $ProjectRoot "apps\desktop\src-tauri\Cargo.toml"
$libPath = Join-Path $ProjectRoot "apps\desktop\src-tauri\src\lib.rs"
$constantsPath = Join-Path $ProjectRoot "apps\desktop\src-tauri\src\constants.rs"
$profilesPath = Join-Path $ProjectRoot "apps\desktop\src\modelProfiles.ts"
$promptPath = Join-Path $ProjectRoot "examples\gpt-5.6-sol-unrestricted.md"

foreach ($required in @($tauriPath, $rootPackagePath, $desktopPackagePath, $cargoTomlPath, $libPath, $constantsPath, $profilesPath, $promptPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required project file not found: $required"
    }
}

$tauri = Get-Content -LiteralPath $tauriPath -Raw -Encoding UTF8 | ConvertFrom-Json
$rootPackage = Get-Content -LiteralPath $rootPackagePath -Raw -Encoding UTF8 | ConvertFrom-Json
$desktopPackage = Get-Content -LiteralPath $desktopPackagePath -Raw -Encoding UTF8 | ConvertFrom-Json
$cargoText = [System.IO.File]::ReadAllText($cargoTomlPath, [Text.Encoding]::UTF8)
$cargoVersionMatch = [regex]::Match($cargoText, '(?m)^version\s*=\s*"([^"]+)"')
$cargoVersion = if ($cargoVersionMatch.Success) { $cargoVersionMatch.Groups[1].Value } else { "" }
$rustVersionMatch = [regex]::Match($cargoText, '(?m)^rust-version\s*=\s*"([^"]+)"')
$rustToolchain = if ($rustVersionMatch.Success) { "$($rustVersionMatch.Groups[1].Value)-x86_64-pc-windows-msvc" } else { "stable-x86_64-pc-windows-msvc" }

Add-Check -Name "Unique product name" -Passed ($tauri.productName -eq "Codex-X GPT56") -Details ([string]$tauri.productName)
Add-Check -Name "Unique application identifier" -Passed ($tauri.identifier -eq "com.yynxxxxx.codexx.gpt56") -Details ([string]$tauri.identifier)
Add-Check -Name "GPT56 prerelease version" -Passed ([string]$tauri.version).Contains("gpt56") -Details ([string]$tauri.version)
$versionsMatch = ($rootPackage.version -eq $desktopPackage.version) -and ($rootPackage.version -eq $tauri.version) -and ($rootPackage.version -eq $cargoVersion)
Add-Check -Name "Version synchronization" -Passed $versionsMatch -Details "root=$($rootPackage.version), desktop=$($desktopPackage.version), tauri=$($tauri.version), cargo=$cargoVersion"

Test-TextContains -Path $constantsPath -Needle 'DEFAULT_MODEL: &str = "gpt-5.6-sol"' -Name "Rust default model"
Test-TextContains -Path $profilesPath -Needle 'DEFAULT_MODEL_ID = "gpt-5.6-sol"' -Name "Frontend default model"
Test-TextContains -Path $profilesPath -Needle 'wireApi: "responses"' -Name "Responses API profile"
Test-TextContains -Path $profilesPath -Needle 'reasoningEffort: "medium"' -Name "GPT56 reasoning default"
Test-TextContains -Path $constantsPath -Needle 'gpt-5.6-sol-unrestricted.md' -Name "Bundled GPT56 prompt"
Test-TextContains -Path $libPath -Needle 'std::env::var("CODEX_HOME")' -Name "CODEX_HOME override"
Test-TextContains -Path $libPath -Needle 'std::env::var("CODEXX_HOME")' -Name "CODEXX_HOME override"
Test-TextContains -Path $libPath -Needle 'join(".codexx-gpt56")' -Name "Distinct default app data directory"

$profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
$realCodexHome = Get-NormalizedPath (Join-Path $profile ".codex")
$sandboxRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-x-gpt56-verify-" + [Guid]::NewGuid().ToString("N"))
$codexHome = Join-Path $sandboxRoot "codex"
$codexxHome = Join-Path $sandboxRoot "codexx"
$sandboxNormalized = Get-NormalizedPath $codexHome
$realPrefix = $realCodexHome + [System.IO.Path]::DirectorySeparatorChar
$isolatedPath = -not $sandboxNormalized.Equals($realCodexHome, [StringComparison]::OrdinalIgnoreCase) -and -not $sandboxNormalized.StartsWith($realPrefix, [StringComparison]::OrdinalIgnoreCase)
Add-Check -Name "Temporary CODEX_HOME guard" -Passed $isolatedPath -Details $sandboxNormalized

$managedVariables = @("CARGO_HOME", "CARGO_TARGET_DIR", "RUSTUP_HOME", "RUSTUP_TOOLCHAIN", "CODEX_HOME", "CODEXX_HOME", "CODEXX_GPT56_ISOLATED", "PATH")
$previous = @{}
foreach ($name in $managedVariables) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
}
$vsEnvironmentChanges = $null

try {
    New-Item -ItemType Directory -Force -Path $codexHome, $codexxHome | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $codexHome "config.toml"), "model = `"gpt-5.6-sol`"`r`n", (New-Object Text.UTF8Encoding($false)))

    $cargoHome = Join-Path $ToolchainRoot "cargo"
    $rustupHome = Join-Path $ToolchainRoot "rustup"
    $vsDevCmd = Join-Path $ToolchainRoot "vs-buildtools\Common7\Tools\VsDevCmd.bat"
    $cargoExe = Join-Path $cargoHome "bin\cargo.exe"
    $rustcExe = Join-Path $cargoHome "bin\rustc.exe"
    $rustToolchainPath = Join-Path $rustupHome ("toolchains\" + $rustToolchain)
    Add-Check -Name "Workspace Cargo toolchain" -Passed (Test-Path -LiteralPath $cargoExe -PathType Leaf) -Details $cargoExe
    Add-Check -Name "Workspace Rust toolchain" -Passed (Test-Path -LiteralPath $rustcExe -PathType Leaf) -Details $rustcExe
    Add-Check -Name "Required Rust version" -Passed (Test-Path -LiteralPath $rustToolchainPath -PathType Container) -Details $rustToolchain
    Add-Check -Name "Workspace VS Build Tools" -Passed (Test-Path -LiteralPath $vsDevCmd -PathType Leaf) -Details $vsDevCmd

    $vsEnvironmentChanges = Import-VsDevEnvironment -VsDevCmdPath $vsDevCmd
    $env:CARGO_HOME = $cargoHome
    $env:CARGO_TARGET_DIR = Join-Path $ProjectRoot "apps\desktop\src-tauri\target"
    $env:RUSTUP_HOME = $rustupHome
    $env:RUSTUP_TOOLCHAIN = $rustToolchain
    $env:CODEX_HOME = $codexHome
    $env:CODEXX_HOME = $codexxHome
    $env:CODEXX_GPT56_ISOLATED = "1"
    $env:PATH = (Join-Path $cargoHome "bin") + [System.IO.Path]::PathSeparator + $env:PATH

    Add-Check -Name "Effective CODEX_HOME" -Passed ((Get-NormalizedPath $env:CODEX_HOME) -eq (Get-NormalizedPath $codexHome)) -Details $env:CODEX_HOME
    Add-Check -Name "Effective CODEXX_HOME" -Passed ((Get-NormalizedPath $env:CODEXX_HOME) -eq (Get-NormalizedPath $codexxHome)) -Details $env:CODEXX_HOME
    $linkExe = (Get-Command link.exe -CommandType Application -ErrorAction SilentlyContinue).Source
    Add-Check -Name "MSVC linker environment" -Passed (-not [string]::IsNullOrWhiteSpace($linkExe)) -Details ([string]$linkExe)

    if (-not $SkipCommands) {
        $pnpm = (Get-Command pnpm.cmd -ErrorAction Stop).Source
        Invoke-NativeChecked -FilePath $pnpm -ArgumentList @("--dir", (Join-Path $ProjectRoot "apps\desktop"), "typecheck") -Label "TypeScript typecheck"
        Add-Check -Name "TypeScript typecheck" -Passed $true -Details "completed"

        Invoke-NativeChecked -FilePath $cargoExe -ArgumentList @("test", "--manifest-path", $cargoTomlPath, "--locked") -Label "Rust tests"
        Add-Check -Name "Rust tests" -Passed $true -Details "completed with isolated homes"
    }

    if (-not [string]::IsNullOrWhiteSpace($ArtifactPath)) {
        $ArtifactPath = Get-NormalizedPath $ArtifactPath
        $artifactExists = Test-Path -LiteralPath $ArtifactPath -PathType Leaf
        Add-Check -Name "Portable executable" -Passed $artifactExists -Details $ArtifactPath
        if ($artifactExists) {
            $file = Get-Item -LiteralPath $ArtifactPath
            Add-Check -Name "Portable executable size" -Passed ($file.Length -gt 1MB) -Details ("{0:N0} bytes" -f $file.Length)
            $hash = (Get-FileHash -LiteralPath $ArtifactPath -Algorithm SHA256).Hash
            Add-Check -Name "Portable executable SHA256" -Passed ($hash.Length -eq 64) -Details $hash
        }
    }
}
catch {
    Add-Check -Name "Command execution" -Passed $false -Details $_.Exception.Message
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
    if (Test-Path -LiteralPath $sandboxRoot) {
        $tempRoot = Get-NormalizedPath ([System.IO.Path]::GetTempPath())
        $candidate = Get-NormalizedPath $sandboxRoot
        if ($candidate.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $candidate -Leaf).StartsWith("codex-x-gpt56-verify-")) {
            Remove-Item -LiteralPath $candidate -Recurse -Force
        }
    }
}

$failed = @($checks | Where-Object { -not $_.passed })
$report = [pscustomobject]@{
    projectRoot = $ProjectRoot
    generatedAt = (Get-Date).ToString("o")
    isolated = ($failed.Count -eq 0)
    checks = $checks
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = Join-Path $ProjectRoot "artifacts\gpt56-isolation-report.json"
}
$reportDirectory = Split-Path -Parent $ReportPath
New-Item -ItemType Directory -Force -Path $reportDirectory | Out-Null
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReportPath -Encoding UTF8
Write-Host "Isolation report: $ReportPath"

if ($failed.Count -gt 0) {
    throw "GPT56 isolation verification failed: $($failed.Count) check(s) failed."
}

Write-Host "GPT56 isolation verification passed."
