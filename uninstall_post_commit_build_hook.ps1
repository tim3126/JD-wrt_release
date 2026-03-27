param(
    [string]$RepoRoot = $PSScriptRoot
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path $RepoRoot).Path
$hookPath = Join-Path $repoRoot ".git\hooks\post-commit"

if (Test-Path $hookPath) {
    Remove-Item $hookPath -Force
    Write-Host "Removed post-commit hook:"
    Write-Host $hookPath
} else {
    Write-Host "Post-commit hook not found:"
    Write-Host $hookPath
}
