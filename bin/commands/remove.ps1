function Remove-NodeVersion {
    param(
        [Parameter(Position=1)]
        [string]$Version
    )

    if (-not $Version) {
        Write-Host "Error: Version parameter is required"
        Write-Host "Usage: psnm remove <version>"
        return 1
    }

    if (-not $Version.StartsWith("v")) {
        $Version = "v$Version"
    }

    $renamedFolderPath = Join-Path $NODE_INSTALL_PATH $Version

    if (-not (Test-Path $renamedFolderPath)) {
        Write-Host "Error: Node.js version $Version is not installed at $renamedFolderPath."
        return 1
    }

    Write-Host "Removing Node.js $Version..."
    Remove-Item -Path $renamedFolderPath -Recurse -Force

    Write-Host "Node.js $Version has been removed successfully."
    return 0
}

