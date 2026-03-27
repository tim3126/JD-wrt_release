param(
    [string]$Distro = "Ubuntu",
    [string]$WslUser = "tim",
    [string]$TargetDir = "/home/tim/src/JD-wrt_release",
    [int]$DebounceMilliseconds = 1500,
    [switch]$BuildAfterSync,
    [string]$Model = "jdcloud_er1_libwrt",
    [string]$BuildMode = ""
)

$ErrorActionPreference = "Stop"

$sourceRoot = (Resolve-Path $PSScriptRoot).Path.TrimEnd("\")
$syncScript = Join-Path $PSScriptRoot "sync_to_wsl.ps1"
$buildScript = Join-Path $PSScriptRoot "build_in_wsl.ps1"

function Should-SkipPath {
    param([string]$FullPath)

    if (-not $FullPath.StartsWith($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    $relative = $FullPath.Substring($sourceRoot.Length).TrimStart("\")
    if (-not $relative) {
        return $false
    }

    $relative = $relative -replace "/", "\\"

    return (
        $relative -eq "log.txt" -or
        $relative -like ".git\*" -or
        $relative -eq ".git" -or
        $relative -like "libwrt\*" -or
        $relative -eq "libwrt" -or
        $relative -like "firmware\*" -or
        $relative -eq "firmware" -or
        $relative -like "action_build\*" -or
        $relative -eq "action_build" -or
        $relative -like "configlog\*" -or
        $relative -eq "configlog"
    )
}

function Invoke-Sync {
    & $syncScript -Distro $Distro -WslUser $WslUser -TargetDir $TargetDir -Quiet
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] Synced to WSL"
}

function Invoke-Build {
    & $buildScript -Distro $Distro -WslUser $WslUser -TargetDir $TargetDir -Model $Model -BuildMode $BuildMode
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] Build finished"
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $sourceRoot
$watcher.Filter = "*"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::FileName `
    -bor [System.IO.NotifyFilters]::DirectoryName `
    -bor [System.IO.NotifyFilters]::LastWrite `
    -bor [System.IO.NotifyFilters]::CreationTime `
    -bor [System.IO.NotifyFilters]::Size

Write-Host "Watching: $sourceRoot"
Write-Host "Target:   $TargetDir"
if ($BuildAfterSync) {
    Write-Host "Build:    enabled ($Model $BuildMode)".TrimEnd()
}
Write-Host "Press Ctrl+C to stop"

Invoke-Sync
if ($BuildAfterSync) {
    Invoke-Build
}

while ($true) {
    $change = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
    if ($change.TimedOut) {
        continue
    }

    $fullPath = if ($change.Name) {
        Join-Path $sourceRoot $change.Name
    } else {
        $sourceRoot
    }

    if (Should-SkipPath $fullPath) {
        continue
    }

    Start-Sleep -Milliseconds $DebounceMilliseconds

    while ($true) {
        $pending = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::All, $DebounceMilliseconds)
        if ($pending.TimedOut) {
            break
        }

        $pendingPath = if ($pending.Name) {
            Join-Path $sourceRoot $pending.Name
        } else {
            $sourceRoot
        }

        if (-not (Should-SkipPath $pendingPath)) {
            continue
        }
    }

    Invoke-Sync
    if ($BuildAfterSync) {
        Invoke-Build
    }
}
