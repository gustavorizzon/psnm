Add-Type -AssemblyName System.IO.Compression.FileSystem

function Install-NodeVersion {
    param(
        [Parameter(Position=1)]
        [string]$Version
    )

    if (-not $Version) {
        Write-Host "Error: Version parameter is required"
        Write-Host "Usage: psnm install <version>"
        Write-Host "To see available versions, run: psnm ls-remote"
        return 1
    }

    if (-not $Version.StartsWith("v")) {
        $Version = "v$Version"
    }

    $nodeDistUrl = "$NODE_BASE_URL/index.json"
    $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl

    # Filter versions that start with the input version
    $requestedVersions = $nodeVersions | Where-Object { $_.version -like "$Version*" }

    if (-not $requestedVersions) {
        Write-Host "Error: Version $Version not found"
        Write-Host "To see available versions, run: psnm ls-remote"
        return 1
    }

    # Get the maximum version from the filtered results
    $requestedVersion = $requestedVersions | Sort-Object -Property { [version]($_.version -replace 'v', '') } -Descending | Select-Object -First 1
    $Version = $requestedVersion.version

    $extractedPath = Join-Path $NODE_INSTALL_PATH $Version
    if (Test-Path $extractedPath) {
        Write-Host "Node.js $Version is already installed at $extractedPath."
        return 0
    }

    $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
    $versionExtendedName = "node-$Version-win-$arch"
    $downloadUrl = "$NODE_BASE_URL/$Version/$versionExtendedName.zip"
    $downloadPath = Join-Path $env:TEMP "$versionExtendedName.zip"

    Write-Host "Downloading Node.js $Version ($arch)..."
    try {
        if (-not (Test-Path $downloadPath)) {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($downloadUrl, $downloadPath)
        } else {
            Write-Host "Node.js $Version has already been downloaded."
        }
    } catch {
        Write-Host "Error: Failed to download Node.js $Version"
        Write-Host "URL attempted: $downloadUrl"
        return 1
    }

    Write-Host "Installing Node.js $Version..."
    [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $NODE_INSTALL_PATH)
    Remove-Item $downloadPath

    # Renames extracted folder to only vx.x.x
    $extractedFolderPath = Join-Path $NODE_INSTALL_PATH $versionExtendedName
    $renamedFolderPath = Join-Path $NODE_INSTALL_PATH $Version
    Rename-Item -Path $extractedFolderPath -NewName $renamedFolderPath -Force

    Write-Host "Node.js $Version has been installed successfully"
    
    return 0
}
