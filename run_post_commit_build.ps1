param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $RepoRoot).Path
$gitDir = Join-Path $repoRoot ".git"
$logPath = Join-Path $gitDir "taiyi1-post-commit-build.log"
$lockPath = Join-Path $gitDir "taiyi1-post-commit-build.lock"
$pendingPath = Join-Path $gitDir "taiyi1-post-commit-build.pending"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message" -Encoding utf8
}

if (Test-Path $lockPath) {
    New-Item -ItemType File -Force -Path $pendingPath | Out-Null
    Write-Log "Build already running, marked pending."
    exit 0
}

New-Item -ItemType File -Force -Path $lockPath | Out-Null

try {
    do {
        if (Test-Path $pendingPath) {
            Remove-Item $pendingPath -Force -ErrorAction SilentlyContinue
        }

        Write-Log "Sync started."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "sync_to_wsl.ps1") -RepoRoot $repoRoot
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Sync failed with exit code $LASTEXITCODE."
            exit $LASTEXITCODE
        }

        Write-Log "WSL build started."
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repoRoot "build_in_wsl.ps1")
        $buildExit = $LASTEXITCODE
        Write-Log "WSL build finished with exit code $buildExit."

        if ($buildExit -ne 0) {
            exit $buildExit
        }
    } while (Test-Path $pendingPath)
}
finally {
    Remove-Item $lockPath -Force -ErrorAction SilentlyContinue
}
