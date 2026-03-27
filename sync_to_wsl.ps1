param(
    [string]$RepoRoot = (Resolve-Path ".").Path,
    [string]$WslTargetDir = "/home/tim/src/JD-wrt_release-taiyi1"
)

$ErrorActionPreference = "Stop"

$repoRootWin = (Resolve-Path $RepoRoot).Path
$normalizedRepoRoot = $repoRootWin -replace '\\', '/'
if ($normalizedRepoRoot -match '^(?<drive>[A-Za-z]):(?<path>/.*)?$') {
    $drive = $Matches['drive'].ToLower()
    $subPath = $Matches['path']
    if (-not $subPath) {
        $subPath = ""
    }
    $repoRootWsl = "/mnt/$drive$subPath"
} else {
    throw "Unable to convert repo path to WSL path: $repoRootWin"
}

$syncScript = @"
set -e
mkdir -p '$WslTargetDir'
rsync -a --delete \
  --exclude .git \
  --exclude imm-nss \
  --exclude firmware \
  --exclude log.txt \
  '$repoRootWsl/' \
  '$WslTargetDir/'
cd '$WslTargetDir'
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
"@

& wsl bash -lc $syncScript
if ($LASTEXITCODE -ne 0) {
    throw "sync_to_wsl failed with exit code $LASTEXITCODE"
}
