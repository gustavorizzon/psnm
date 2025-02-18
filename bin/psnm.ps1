param(
    [Parameter(Position=1)]
    [string]$Command,
    [Parameter(Position=2)]
    [string]$CommandArg1
)

if ($Command -eq "help" -or $Command -eq "--help" -or $Command -eq "-h") {
    Write-Host "Available commands:"
    Write-Host "  ls           List installed Node.js versions"
    Write-Host "  ls-remote    List available Node.js versions"
    Write-Host "  install      Install a specific Node.js version"
    Write-Host "  remove       Remove a specific Node.js version"
    Write-Host "  use          Switch to a specific Node.js version"
    Write-Host "  help         Show this help message"
    exit 0
}

. (Join-Path $PSScriptRoot "config\variables.ps1")

if ($Command -eq "ls-remote") {
    . (Join-Path $PSScriptRoot "commands\ls-remote.ps1")
    $ret = ListRemote-NodeVersions
    exit $ret
}

if ($Command -eq "ls") {
    . (Join-Path $PSScriptRoot "commands\ls.ps1")
    $ret = ListInstalled-NodeVersions
    exit $ret
}

if ($Command -eq "install") {
    . (Join-Path $PSScriptRoot "commands\install.ps1")
    $ret = Install-NodeVersion -Version $CommandArg1
    exit $ret
}

if ($Command -eq "remove") {
    . (Join-Path $PSScriptRoot "commands\remove.ps1")
    $ret = Remove-NodeVersion -Version $CommandArg1
    exit $ret
}

if ($Command -eq "use") {
    . (Join-Path $PSScriptRoot "commands\use.ps1")
    $ret = Use-NodeVersion -Version $CommandArg1
    exit $ret
}

Write-Host "Error: Command '$Command' not found."
Write-Host "Use 'psnm help' to see the list of available commands."
exit 1
