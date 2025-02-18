param(
    [Parameter(Position=1)]
    [string]$Version
)

. (Join-Path $PSScriptRoot "config.ps1")

if (-not $Version) {
    Write-Host "Error: Version parameter is required"
    Write-Host "Usage: remove.ps1 <version>"
    exit 1
}

if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
}

$renamedFolderPath = Join-Path $nodeInstallPath $Version

if (-not (Test-Path $renamedFolderPath)) {
    Write-Host "Error: Node.js version $Version is not installed at $renamedFolderPath."
    exit 1
}

Write-Host "Removing Node.js $Version..."
Remove-Item -Path $renamedFolderPath -Recurse -Force

Write-Host "Node.js $Version has been removed successfully."
