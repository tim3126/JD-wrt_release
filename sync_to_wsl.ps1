param(
    [string]$Distro = "Ubuntu",
    [string]$WslUser = "tim",
    [string]$TargetDir = "/home/tim/src/JD-wrt_release",
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Convert-ToWslPath {
    param([string]$WindowsPath)

    $normalized = $WindowsPath -replace "\\", "/"
    if ($normalized -notmatch "^([A-Za-z]):/(.+)$") {
        throw "Unsupported Windows path: $WindowsPath"
    }

    $drive = $Matches[1].ToLowerInvariant()
    $rest = $Matches[2]
    return "/mnt/$drive/$rest"
}

$sourceRoot = (Resolve-Path $PSScriptRoot).Path
$sourceWslPath = Convert-ToWslPath $sourceRoot

if (-not $sourceWslPath) {
    throw "Failed to convert Windows path to WSL path."
}

$excludePaths = @(
    ".git/",
    "libwrt/",
    "firmware/",
    "action_build/",
    "configlog/",
    "log.txt"
)

$syncSource = $sourceWslPath.TrimEnd("/") + "/"
$syncTarget = $TargetDir.TrimEnd("/") + "/"
$excludeArgs = ($excludePaths | ForEach-Object { "--exclude=$_" }) -join " "

$bashScript = @"
set -euo pipefail
mkdir -p '$syncTarget'
rsync -a --delete $excludeArgs '$syncSource' '$syncTarget'
"@
$bashScript = $bashScript -replace "`r`n", "`n"

& wsl -d $Distro -u $WslUser bash -lc $bashScript | Out-Null

if (-not $Quiet) {
    Write-Host "Synced to WSL: $TargetDir"
}
