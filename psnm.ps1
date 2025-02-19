param(
    [Parameter(Position=1)]
    [string]$cmdArg1,
    [Parameter(Position=2)]
    [string]$cmdArg2
)

# VARIABLES
$NODE_BASE_URL = "https://nodejs.org/dist" 
$NODE_INSTALL_PATH = Join-Path $env:LOCALAPPDATA "psnm\nodejs"
if (-not (Test-Path $NODE_INSTALL_PATH)) {
    New-Item -ItemType Directory -Path $NODE_INSTALL_PATH -Force | Out-Null
}

# TYPES
Add-Type -AssemblyName System.IO.Compression.FileSystem

# COMMANDS FUNCTIONS
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

function ListInstalled-NodeVersions {
    if (-not (Test-Path $NODE_INSTALL_PATH)) {
        Write-Host "No Node.js versions installed"
        exit
    }

    $installedVersions = Get-ChildItem -Path $NODE_INSTALL_PATH -Directory | Select-Object -ExpandProperty Name | Sort-Object { [version]($_ -replace 'v') }

    Write-Host "Installed Node.js versions:"
    Write-Host "------------------------"
    if ($installedVersions.Count -eq 0) {
        Write-Host "- No Node.js versions are currently installed."
        Write-Host "- You can install a version using the command: psnm install <version>"
        Write-Host "- To see available versions, run: psnm ls-remote"
    } else {
        $installedVersions | ForEach-Object {
            Write-Host $_
        }
    }

    return 0
}

function ListRemote-NodeVersions {
    $nodeDistUrl = "$NODE_BASE_URL/index.json"
    $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl
    $sortedVersions = $nodeVersions | Sort-Object { [version]($_.version -replace 'v') }

    Write-Host "Available Node.js versions:"
    Write-Host "------------------------"

    $sortedVersions | ForEach-Object {
        $ltsLabel = if ($_.lts) { " (LTS)" } else { "" }
        Write-Host "$($_.version)$ltsLabel"
    }

    return 0
}

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

if ($cmdArg1 -eq "help" -or $cmdArg1 -eq "--help" -or $cmdArg1 -eq "-h") {
    Write-Host "Available commands:"
    Write-Host "  ls           List installed Node.js versions"
    Write-Host "  ls-remote    List available Node.js versions"
    Write-Host "  install      Install a specific Node.js version"
    Write-Host "  remove       Remove a specific Node.js version"
    Write-Host "  use          Switch to a specific Node.js version"
    Write-Host "  help         Show this help message"
    exit 0
}

if ($cmdArg1 -eq "ls-remote") { exit ListRemote-NodeVersions }
if ($cmdArg1 -eq "ls") { exit ListInstalled-NodeVersions }
if ($cmdArg1 -eq "install") { exit Install-NodeVersion -Version $cmdArg2 }
if ($cmdArg1 -eq "remove") { exit Remove-NodeVersion -Version $cmdArg2 }
if ($cmdArg1 -eq "use") { exit Use-NodeVersion -Version $cmdArg2 }

if ($cmdArg1) { Write-Host "Error: Command '$cmdArg1' not found." }
Write-Host "Use 'psnm help' to see the list of available commands."
exit 1
