param(
    [string]$Distro = "Ubuntu",
    [string]$WslUser = "tim",
    [string]$TargetDir = "/home/tim/src/JD-wrt_release",
    [switch]$BuildAfterSync,
    [string]$Model = "jdcloud_er1_libwrt",
    [string]$BuildMode = ""
)

$ErrorActionPreference = "Stop"

$watchScript = Join-Path $PSScriptRoot "watch_sync_to_wsl.ps1"
$argumentList = @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$watchScript`"",
    "-Distro", $Distro,
    "-WslUser", $WslUser,
    "-TargetDir", $TargetDir
)

if ($BuildAfterSync) {
    $argumentList += "-BuildAfterSync"
    $argumentList += "-Model"
    $argumentList += $Model
    if ($BuildMode) {
        $argumentList += "-BuildMode"
        $argumentList += $BuildMode
    }
}

Start-Process powershell -WorkingDirectory $PSScriptRoot -ArgumentList $argumentList | Out-Null
Write-Host "Watcher started in a new PowerShell window."
