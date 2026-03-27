param(
    [string]$WslRepoRoot = "/home/tim/src/JD-wrt_release-taiyi1",
    [string]$Device = "jdcloud_er1_immwrt",
    [string]$Mode = ""
)

$ErrorActionPreference = "Stop"

$buildArgs = @("./build.sh", $Device)
if ($Mode) {
    $buildArgs += $Mode
}
$buildCommand = ($buildArgs -join " ")

$script = @"
set -e
cd '$WslRepoRoot'
dos2unix build.sh wrt_core/update.sh wrt_core/modules/*.sh wrt_core/deconfig/jdcloud_er1_immwrt.config >/dev/null 2>&1 || true
bash $buildCommand
ln -sfn '$WslRepoRoot/firmware' /home/tim/firmware-taiyi1
"@

& wsl bash -lc $script
exit $LASTEXITCODE
