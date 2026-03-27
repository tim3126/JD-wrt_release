param(
    [string]$Distro = "Ubuntu",
    [string]$WslUser = "tim",
    [string]$TargetDir = "/home/tim/src/JD-wrt_release",
    [string]$Model = "jdcloud_er1_libwrt",
    [string]$BuildMode = ""
)

$ErrorActionPreference = "Stop"

if (Get-Variable PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$buildArgs = @("./build_maintim.sh", $Model)
if ($BuildMode) {
    $buildArgs += $BuildMode
}

$quotedArgs = ($buildArgs | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join " "
$bashScript = @"
set -euo pipefail
cd '$TargetDir'
$quotedArgs
"@

& wsl -d $Distro -u $WslUser bash -lc $bashScript
