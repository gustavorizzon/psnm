# CONSTANTS
$NODE_BASE_URL = "https://nodejs.org/dist" 
$PSNM_HOME = Join-Path $env:LOCALAPPDATA "psnm"
$NODE_INSTALL_PATH = Join-Path $PSNM_HOME "nodejs"
$CONFIG_FILE = Join-Path $PSNM_HOME "config.json"

# SETUP
$CONFIG = @{}
if (-not (Test-Path $CONFIG_FILE)) {
  $CONFIG | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Force
} else {
  $CONFIG = Get-Content -Path $CONFIG_FILE -Raw | ConvertFrom-Json
}
if (-not (Test-Path $NODE_INSTALL_PATH)) {
  New-Item -ItemType Directory -Path $NODE_INSTALL_PATH -Force | Out-Null
}

# TYPES
Add-Type -AssemblyName System.IO.Compression.FileSystem

# COMMANDS FUNCTIONS
function Set-DefaultNodeVersion {
  param(
    [Parameter(Position=1, Mandatory=$true)]
    [string]$Version
  )

  if (-not $Version) {
    throw "Version parameter is required. Usage: Set-DefaultNodeVersion <version>"
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  $CONFIG.defaultVersion = $Version
  $CONFIG | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Force

  return "Default Node.js version set to $Version"
}

function Install-NodeVersion {
  param(
    [Parameter(Position=1)]
    [string]$Version
  )

  if (-not $Version) {
    throw "Version parameter is required. Usage: Install-NodeVersion <version>"
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  $nodeDistUrl = "$NODE_BASE_URL/index.json"
  $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl

  # Filter versions that start with the input version
  $requestedVersions = $nodeVersions | Where-Object { $_.version -like "$Version*" }

  if (-not $requestedVersions) {
    throw "Version $Version not found. To see available versions, run: List-AvailableNodeVersions"
  }

  # Get the maximum version from the filtered results
  $requestedVersion = $requestedVersions | Sort-Object -Property { [version]($_.version -replace 'v', '') } -Descending | Select-Object -First 1
  $Version = $requestedVersion.version

  $extractedPath = Join-Path $NODE_INSTALL_PATH $Version
  if (Test-Path $extractedPath) {
    return "Node.js $Version is already installed at $extractedPath."
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
    return $false
  }

  Write-Host "Installing Node.js $Version..."
  [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $NODE_INSTALL_PATH)
  Remove-Item $downloadPath

  # Renames extracted folder to only vx.x.x
  $extractedFolderPath = Join-Path $NODE_INSTALL_PATH $versionExtendedName
  $renamedFolderPath = Join-Path $NODE_INSTALL_PATH $Version
  Rename-Item -Path $extractedFolderPath -NewName $renamedFolderPath -Force

  return "Node.js $Version has been installed successfully"
}

function Remove-NodeVersion {
  param(
    [Parameter(Position=1)]
    [string]$Version
  )

  if (-not $Version) {
    throw "Error: Version parameter is required. Usage: Remove-NodeVersion <version>"
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  $renamedFolderPath = Join-Path $NODE_INSTALL_PATH $Version

  if (-not (Test-Path $renamedFolderPath)) {
    throw "Node.js version $Version is not installed at $renamedFolderPath."
  }

  Remove-Item -Path $renamedFolderPath -Recurse -Force

  return "Node.js $Version has been removed successfully."
}

function List-InstalledNodeVersions {
  if (-not (Test-Path $NODE_INSTALL_PATH)) {
    return "No Node.js versions installed"
  }

  $installedVersions = Get-ChildItem -Path $NODE_INSTALL_PATH -Directory | Select-Object -ExpandProperty Name | Sort-Object { [version]($_ -replace 'v') }

  $output = "Installed Node.js versions:`n------------------------`n"
  if ($installedVersions.Count -eq 0) {
    $output += "- No Node.js versions are currently installed.`n"
    $output += "- You can install a version using the command: Install-NodeVersion <version>`n"
    $output += "- To see available versions, run: List-AvailableNodeVersions`n"
  } else {
    $output += ($installedVersions | ForEach-Object { $_ }) -join "`n"
  }
  
  return $output
}

function List-AvailableNodeVersions {
  $nodeDistUrl = "$NODE_BASE_URL/index.json"
  $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl
  $sortedVersions = $nodeVersions | Sort-Object { [version]($_.version -replace 'v') }

  $output = "Available Node.js versions:`n------------------------`n"
  $output += ($sortedVersions | ForEach-Object {
    $ltsLabel = if ($_.lts) { " (LTS)" } else { "" }
    "$($_.version)$ltsLabel"
  }) -join "`n"

  return $output
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
      throw "Version parameter is required for use command. Usage: Use-NodeVersion <version>"
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
    throw "Version $Version is not installed. To install it, run: Install-NodeVersion $Version"
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

  return "Switched to Node.js version $($selectedVersion.Name)"
}

# POST SETUP
if ($CONFIG.defaultVersion) {
  Use-NodeVersion $CONFIG.defaultVersion 
}