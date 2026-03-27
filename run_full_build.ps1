param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$repoRoot = (Resolve-Path $RepoRoot).Path
$gitDir = Join-Path $repoRoot ".git"
$logPath = Join-Path $gitDir "taiyi1-full-build.log"
$fullLockPath = Join-Path $gitDir "taiyi1-full-build.lock"
$debugLockPath = Join-Path $gitDir "taiyi1-post-commit-debug.lock"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Write-Host $line
    Add-Content -Path $logPath -Value $line -Encoding utf8
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
            -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        if ((Get-Item $stdoutPath).Length -gt 0) {
            $stdoutLines = Get-Content -Path $stdoutPath
            $stdoutLines | Out-File -FilePath $logPath -Append -Encoding utf8
            $stdoutLines | Out-Host
        }

        if ((Get-Item $stderrPath).Length -gt 0) {
            $stderrLines = Get-Content -Path $stderrPath
            $stderrLines | Out-File -FilePath $logPath -Append -Encoding utf8
            $stderrLines | Out-Host
        }

        $exitCode = $process.ExitCode
        Write-Log "$StepName finished with exit code $exitCode."
        return $exitCode
    }
    finally {
        Remove-Item $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path $fullLockPath) {
    throw "A full build is already running. Please try again later."
}

if (Test-Path $debugLockPath) {
    throw "A post-commit debug build is already running. Wait for it to finish before starting a full build."
}

New-Item -ItemType File -Force -Path $fullLockPath | Out-Null

try {
    $syncExit = Invoke-LoggedScript -ScriptPath (Join-Path $repoRoot "sync_to_wsl.ps1") -Arguments @("-RepoRoot", $repoRoot) -StepName "Full sync"
    if ($syncExit -ne 0) {
        exit $syncExit
    }

    $buildExit = Invoke-LoggedScript -ScriptPath (Join-Path $repoRoot "build_in_wsl.ps1") -Arguments @("-Mode", "full") -StepName "Full build"
    if ($buildExit -ne 0) {
        exit $buildExit
    }
}
finally {
    Remove-Item $fullLockPath -Force -ErrorAction SilentlyContinue
}
