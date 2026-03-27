param(
    [string]$RepoRoot = $PSScriptRoot,
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

$repoRoot = (Resolve-Path $RepoRoot).Path
$gitDir = Join-Path $repoRoot ".git"
$pendingPath = Join-Path $gitDir "maintim-post-commit-build.pending"
$logPath = Join-Path $gitDir "maintim-post-commit-build.log"
$syncScript = Join-Path $repoRoot "sync_to_wsl.ps1"
$buildScript = Join-Path $repoRoot "build_in_wsl.ps1"
$mutexName = "Global\JDWrtReleaseMaintimPostCommitBuild"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message"
}

if (-not $mutex.WaitOne(0)) {
    Set-Content -Path $pendingPath -Value (Get-Date -Format "o")
    exit 0
}

try {
    do {
        Remove-Item $pendingPath -Force -ErrorAction SilentlyContinue

        $commit = (git -C $repoRoot rev-parse --short HEAD).Trim()
        Write-Log "start sync and build for commit $commit"

        try {
            & $syncScript -Distro $Distro -WslUser $WslUser -TargetDir $TargetDir -Quiet
            Write-Log "sync completed"

            & $buildScript -Distro $Distro -WslUser $WslUser -TargetDir $TargetDir -Model $Model -BuildMode $BuildMode | Out-Null

            if ($LASTEXITCODE -ne 0) {
                throw "build script exited with code $LASTEXITCODE"
            }

            Write-Log "build completed"
        } catch {
            Write-Log "build failed: $($_.Exception.Message)"
        }
    } while (Test-Path $pendingPath)
} finally {
    $mutex.ReleaseMutex() | Out-Null
    $mutex.Dispose()
}
