param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repoRoot = (Resolve-Path $RepoRoot).Path
$gitDir = Join-Path $repoRoot ".git"
$logPath = Join-Path $gitDir "taiyi1-post-commit-debug.log"
$lockPath = Join-Path $gitDir "taiyi1-post-commit-debug.lock"
$pendingPath = Join-Path $gitDir "taiyi1-post-commit-debug.pending"
$fullLockPath = Join-Path $gitDir "taiyi1-full-build.lock"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Message" -Encoding utf8
}

function Invoke-LoggedScript {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments,
        [string]$StepName
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $argumentList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
    $argumentList += $Arguments

    Write-Log "$StepName started."
    try {
        $process = Start-Process -FilePath "powershell.exe" `
            -ArgumentList $argumentList `
            -Wait -PassThru -WindowStyle Hidden `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if ((Get-Item $stdoutPath).Length -gt 0) {
            Get-Content -Path $stdoutPath | Out-File -FilePath $logPath -Append -Encoding utf8
        }

        if ((Get-Item $stderrPath).Length -gt 0) {
            Get-Content -Path $stderrPath | Out-File -FilePath $logPath -Append -Encoding utf8
        }

        $exitCode = $process.ExitCode
        Write-Log "$StepName finished with exit code $exitCode."
        return $exitCode
    }
    finally {
        Remove-Item $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path $lockPath) {
    New-Item -ItemType File -Force -Path $pendingPath | Out-Null
    Write-Log "Debug build already running, marked pending."
    exit 0
}

if (Test-Path $fullLockPath) {
    Write-Log "Full build is running, skip post-commit debug."
    exit 0
}

New-Item -ItemType File -Force -Path $lockPath | Out-Null

try {
    do {
        if (Test-Path $pendingPath) {
            Remove-Item $pendingPath -Force -ErrorAction SilentlyContinue
        }

        $syncExit = Invoke-LoggedScript -ScriptPath (Join-Path $repoRoot "sync_to_wsl.ps1") -Arguments @("-RepoRoot", $repoRoot) -StepName "Debug sync"
        if ($syncExit -ne 0) {
            exit $syncExit
        }

        $buildExit = Invoke-LoggedScript -ScriptPath (Join-Path $repoRoot "build_in_wsl.ps1") -Arguments @("-Mode", "debug") -StepName "WSL debug build"
        if ($buildExit -ne 0) {
            exit $buildExit
        }
    } while (Test-Path $pendingPath)
}
finally {
    Remove-Item $lockPath -Force -ErrorAction SilentlyContinue
}
