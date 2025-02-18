param(
    [Parameter(Position=1)]
    [string]$Command,
    [Parameter(Position=2)]
    [string]$Version
)

if ($Command -eq "help" -or $Command -eq "--help" -or $Command -eq "-h") {
    Write-Host "Available commands:"
    Write-Host "  ls           List installed Node.js versions"
    Write-Host "  ls-remote    List available Node.js versions"
    Write-Host "  install      Install a specific Node.js version"
    Write-Host "  remove       Remove a specific Node.js version"
    Write-Host "  use          Switch to a specific Node.js version"
    Write-Host "  help         Show this help message"
    exit
}

if ($Command -eq "ls-remote") {
    & "$PSScriptRoot\ls-remote.ps1"
    exit
}

if ($Command -eq "ls") {
    & "$PSScriptRoot\ls.ps1"
    exit
}

if ($Command -eq "install") {
    if (-not $Version) {
        Write-Host "Error: Version parameter is required for install command"
        Write-Host "Usage: psnm install <version>"
        exit 1
    }
    & "$PSScriptRoot\install.ps1" $Version
    exit
}

if ($Command -eq "remove") {
    if (-not $Version) {
        Write-Host "Error: Version parameter is required for remove command"
        Write-Host "Usage: psnm remove <version>"
        exit 1
    }
    & "$PSScriptRoot\remove.ps1" $Version
    exit
}

if ($Command -eq "use") {
    if (-not $Version) {
        Write-Host "Error: Version parameter is required for use command"
        Write-Host "Usage: psnm use <version>"
        exit 1
    }
    & "$PSScriptRoot\use.ps1" $Version
    exit
}


Write-Host "Error: Command '$Command' not found."
Write-Host "Use 'psnm help' to see the list of available commands."
exit 1
