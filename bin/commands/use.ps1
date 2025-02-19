function Use-NodeVersion {
    param(
        [Parameter(Position=1)]
        [string]$Version
    )

    if (-not $Version) {
        $nodeVersionFile = Join-Path (Get-Location) ".node-version"
        $nvmrcFile = Join-Path (Get-Location) ".nvmrc"

        if (Test-Path $nodeVersionFile) {
            $Version = (Get-Content $nodeVersionFile | Select-Object -First 1).Trim()
        } elseif (Test-Path $nvmrcFile) {
            $Version = (Get-Content $nvmrcFile | Select-Object -First 1).Trim()
        } else {
            Write-Host "Error: Version parameter is required for use command"
            Write-Host "Usage: psnm use <version>"
            return 1
        }
    }

    if (-not $Version.StartsWith("v")) {
        $Version = "v$Version"
    }

    # Logic to switch to the specified Node.js version
    $nodePath = Join-Path $NODE_INSTALL_PATH $Version
    $installedVersions = Get-ChildItem -Path $NODE_INSTALL_PATH | Where-Object { $_.Name -like "$Version*" }

    $selectedVersion = $installedVersions | Sort-Object { [version]($_.Name -replace 'v', '') } -Descending | Select-Object -First 1

    if (-not $selectedVersion) {
        Write-Host "Error: No installed Node.js version matching $Version."
        Write-Host "To install the missing version, run: psnm install $Version"
        return 1
    }

    # Break the PATH environment variable
    $currentPath = $env:PATH -split ';'

    # Remove the last used version (paths that start with nodeInstallPath/v)
    $prefixToFilter = Join-Path $NODE_INSTALL_PATH "v"
    $currentPath = $currentPath | Where-Object { -not $_.StartsWith($prefixToFilter) }

    # Insert the new version
    $newPath = Join-Path $NODE_INSTALL_PATH $selectedVersion.Name
    $currentPath = @($newPath) + $currentPath

    # Join and save the updated PATH for current PowerShell session
    $env:PATH = ($currentPath -join ';')

    Write-Host "Switched to Node.js version $($selectedVersion.Name)"
}
