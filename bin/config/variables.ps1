# Node.js configuration
$NODE_BASE_URL = "https://nodejs.org/dist" 
$NODE_INSTALL_PATH = Join-Path $env:LOCALAPPDATA "psnm\nodejs"
if (-not (Test-Path $NODE_INSTALL_PATH)) {
    New-Item -ItemType Directory -Path $NODE_INSTALL_PATH -Force | Out-Null
}
