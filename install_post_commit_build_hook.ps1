param(
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $RepoRoot).Path
$hookPath = Join-Path $repoRoot ".git\hooks\post-commit"
$hookContent = @'
#!/bin/sh
repo_root="$(git rev-parse --show-toplevel)"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repo_root/trigger_post_commit_build.ps1" -RepoRoot "$repo_root" >/dev/null 2>&1 &
exit 0
'@

[System.IO.File]::WriteAllText($hookPath, $hookContent, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Installed post-commit hook:"
Write-Host $hookPath
