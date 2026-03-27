param(
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$runnerScript = Join-Path $RepoRoot "run_post_commit_build.ps1"
$argumentList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$runnerScript`"",
    "-RepoRoot", "`"$RepoRoot`""
)

Start-Process powershell -WorkingDirectory $RepoRoot -WindowStyle Minimized -ArgumentList $argumentList | Out-Null
