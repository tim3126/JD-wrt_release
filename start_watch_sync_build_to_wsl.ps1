param(
    [string]$Distro = "Ubuntu",
    [string]$WslUser = "tim",
    [string]$TargetDir = "/home/tim/src/JD-wrt_release",
    [string]$Model = "jdcloud_er1_libwrt",
    [string]$BuildMode = ""
)

$ErrorActionPreference = "Stop"

$startScript = Join-Path $PSScriptRoot "start_watch_sync_to_wsl.ps1"

$params = @{
    Distro = $Distro
    WslUser = $WslUser
    TargetDir = $TargetDir
    BuildAfterSync = $true
    Model = $Model
}

if ($BuildMode) {
    $params.BuildMode = $BuildMode
}

& $startScript @params
