param(
    [Parameter(Position=1)]
    [string]$Version
)

. (Join-Path $PSScriptRoot "config.ps1")

if (-not $Version.StartsWith("v")) {
    $Version = "v$Version"
}

if (-not $Version) {
    Write-Host "Error: Version parameter is required for use command"
    Write-Host "Usage: psnm use <version>"
    exit 1
}

# Logic to switch to the specified Node.js version
$nodePath = Join-Path $nodeInstallPath $Version
$installedVersions = Get-ChildItem -Path $nodeInstallPath | Where-Object { $_.Name -like "$Version*" }

$selectedVersion = $installedVersions | Sort-Object { [version]($_.Name -replace 'v', '') } -Descending | Select-Object -First 1

if (-not $selectedVersion) {
    Write-Host "Error: No installed Node.js version matching $Version."
    exit 1
}

# Break the PATH environment variable
$currentPath = $env:PATH -split ';'

# Remove the last used version (paths that start with nodeInstallPath/v)
$prefixToFilter = Join-Path $nodeInstallPath "v"
$currentPath = $currentPath | Where-Object { -not $_.StartsWith($prefixToFilter) }

# Insert the new version
$newPath = Join-Path $nodeInstallPath $selectedVersion.Name
$currentPath = @($newPath) + $currentPath

# Join and save the updated PATH
$env:PATH = ($currentPath -join ';')

Write-Host "Switched to Node.js version $($selectedVersion.Name)"
