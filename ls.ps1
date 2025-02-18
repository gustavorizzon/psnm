. (Join-Path $PSScriptRoot "config.ps1")

if (-not (Test-Path $nodeInstallPath)) {
    Write-Host "No Node.js versions installed"
    exit
}

$installedVersions = Get-ChildItem -Path $nodeInstallPath -Directory | Select-Object -ExpandProperty Name | Sort-Object { [version]($_ -replace 'v') }

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
