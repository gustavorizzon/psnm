# CONSTANTS
$NODE_BASE_URL = "https://nodejs.org/dist" 
$PSNM_HOME = Join-Path $env:LOCALAPPDATA "psnm"
$NODE_INSTALL_PATH = Join-Path $PSNM_HOME "nodejs"
$CONFIG_FILE = Join-Path $PSNM_HOME "config.json"

# SETUP
if (-not (Test-Path $NODE_INSTALL_PATH)) {
  New-Item -ItemType Directory -Path $NODE_INSTALL_PATH -Force | Out-Null
}
$CONFIG = [PSCustomObject]@{}
if (-not (Test-Path $CONFIG_FILE)) {
  $CONFIG | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Force
} else {
  $CONFIG = Get-Content -Path $CONFIG_FILE -Raw | ConvertFrom-Json
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
    throw "Version parameter is required. Usage: psnm install <version>"
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  $nodeDistUrl = "$NODE_BASE_URL/index.json"
  $nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl

  # Filter versions that start with the input version
  $requestedVersions = $nodeVersions | Where-Object { $_.version -like "$Version*" }

  if (-not $requestedVersions) {
    throw "Version $Version not found. To see available versions, run: psnm ls-remote"
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

function Set-DefaultNodeVersion {
  param(
    [Parameter(Position=1, Mandatory=$true)]
    [string]$Version
  )

  if (-not $Version) {
    throw "Version parameter is required. Usage: psnm default <version>"
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  Install-NodeVersion $Version

  $CONFIG | Add-Member -NotePropertyName "defaultVersion" -NotePropertyValue $Version -Force
  $CONFIG | ConvertTo-Json | Set-Content -Path $CONFIG_FILE -Force

  return "Default Node.js version set to $Version"
}

function Get-DefaultNodeVersion {
  if (-not $CONFIG.defaultVersion) {
    return "No default Node.js version set. Use 'psnm default <version>' to set one."
  }
  return $CONFIG.defaultVersion
}

function Uninstall-NodeVersion {
  param(
    [Parameter(Position=1)]
    [string]$Version
  )

  if (-not $Version) {
    throw "Version parameter is required. Usage: psnm remove <version>"
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

function Get-InstalledNodeVersions {
  if (-not (Test-Path $NODE_INSTALL_PATH)) {
    return "No Node.js versions installed"
  }

  $installedVersions = Get-ChildItem -Path $NODE_INSTALL_PATH -Directory | Select-Object -ExpandProperty Name | Sort-Object { [version]($_ -replace 'v') }

  $output = "Installed Node.js versions:`n------------------------`n"
  if ($installedVersions.Count -eq 0) {
    $output += "- No Node.js versions are currently installed.`n"
    $output += "- You can install a version using the command: psnm install <version>`n"
    $output += "- To see available versions, run: psnm ls-remote`n"
  } else {
    $output += ($installedVersions | ForEach-Object { $_ }) -join "`n"
  }
  
  return $output
}

function Get-AvailableNodeVersions {
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
      throw "Version parameter is required for use command. Usage: psnm use <version>"
    }
  }

  if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
  }

  # Logic to switch to the specified Node.js version
  $installedVersions = Get-ChildItem -Path $NODE_INSTALL_PATH | Where-Object { $_.Name -like "$Version*" }
  $selectedVersion = $installedVersions | Sort-Object { [version]($_.Name -replace 'v', '') } -Descending | Select-Object -First 1

  if (-not $selectedVersion) {
    throw "Version $Version is not installed. To install it, run: psnm install $Version"
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

function Invoke-PSNM {
  param (
    [string]$cmdArg1,
    [string]$cmdArg2
  )

  if ($cmdArg1 -eq "help" -or $cmdArg1 -eq "--help") {
    return "Available commands:`n" +
           "  ls           List installed Node.js versions`n" +
           "  ls-remote    List available Node.js versions`n" + 
           "  install      Install a specific Node.js version`n" +
           "  remove       Remove a specific Node.js version`n" +
           "  use          Switch to a specific Node.js version`n" +
           "  default      Set the default Node.js version`n" +
           "  help         Show this help message"
  }

  if ($cmdArg1 -eq "ls-remote") { return Get-AvailableNodeVersions }
  if ($cmdArg1 -eq "ls") { return Get-InstalledNodeVersions }
  if ($cmdArg1 -eq "install") { return Install-NodeVersion -Version $cmdArg2 }
  if ($cmdArg1 -eq "remove") { return Uninstall-NodeVersion -Version $cmdArg2 }
  if ($cmdArg1 -eq "use") { return Use-NodeVersion -Version $cmdArg2 }
  if ($cmdArg1 -eq "default") { 
    if ($cmdArg2) {
      return Set-DefaultNodeVersion -Version $cmdArg2
    }
    return Get-DefaultNodeVersion
  }

  throw "Error: Command '$cmdArg1' not found. Use 'psnm help' to see the list of available commands."
}

# Export only the psnm alias
New-Alias -Name psnm -Value Invoke-PSNM
Export-ModuleMember -Function Invoke-PSNM -Alias psnm
