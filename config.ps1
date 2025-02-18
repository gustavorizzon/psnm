# Node.js configuration
$nodeBaseUrl = "https://nodejs.org/dist" 
$nodeInstallPath = Join-Path $env:LOCALAPPDATA "psnm\nodejs"
if (-not (Test-Path $nodeInstallPath)) {
    New-Item -ItemType Directory -Path $nodeInstallPath -Force | Out-Null
}
