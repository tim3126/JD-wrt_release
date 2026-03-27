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
find . -type f \( -name '*.sh' -o -path './.git/hooks/*' \) -print0 | xargs -0r dos2unix -q
$quotedArgs
"@
$bashScript = $bashScript -replace "`r`n", "`n"

& wsl -d $Distro -u $WslUser bash -lc $bashScript
