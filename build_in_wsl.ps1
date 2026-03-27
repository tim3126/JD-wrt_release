param(
    [string]$WslRepoRoot = "/home/tim/src/JD-wrt_release-taiyi1",
    [string]$Device = "jdcloud_er1_immwrt",
    [ValidateSet("debug", "full")]
    [string]$Mode = "debug"
)

$ErrorActionPreference = "Stop"

$buildArgs = @("./build.sh", $Device)
if ($Mode -eq "debug") {
    $buildArgs += "debug"
}
$buildCommand = ($buildArgs -join " ")

$script = @"
set -e
cd '$WslRepoRoot'
dos2unix \
  build.sh \
  wrt_core/update.sh \
  wrt_core/modules/*.sh \
  wrt_core/deconfig/jdcloud_er1_immwrt.config \
  wrt_core/patches/cpuusage \
  wrt_core/patches/tempinfo \
  wrt_core/patches/hnatusage \
  wrt_core/patches/smp_affinity \
  wrt_core/patches/990_set_argon_primary \
  wrt_core/patches/991_custom_settings \
  wrt_core/patches/992_set-wifi-uci.sh \
  wrt_core/patches/pbr.user.cmcc \
  wrt_core/patches/pbr.user.cmcc6 >/dev/null 2>&1 || true
bash $buildCommand
ln -sfn '$WslRepoRoot/firmware' /home/tim/firmware-taiyi1
"@

& wsl bash -lc $script
exit $LASTEXITCODE
