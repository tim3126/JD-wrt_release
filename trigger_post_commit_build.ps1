param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $RepoRoot).Path
$branch = (git -C $repoRoot branch --show-current).Trim()
if ($branch -ne "taiyi1") {
    exit 0
}

$runScript = Join-Path $repoRoot "run_post_commit_build.ps1"
$escapedRepoRoot = $repoRoot.Replace("'", "''")
$command = "powershell -NoProfile -ExecutionPolicy Bypass -File '$runScript' -RepoRoot '$escapedRepoRoot'"

Start-Process -WindowStyle Hidden -FilePath "powershell.exe" -ArgumentList @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", $runScript,
    "-RepoRoot", $repoRoot
) | Out-Null
