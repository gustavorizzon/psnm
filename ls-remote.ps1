. (Join-Path $PSScriptRoot "config.ps1")
$nodeDistUrl = "$nodeBaseUrl/index.json"
$nodeVersions = Invoke-RestMethod -Uri $nodeDistUrl
$sortedVersions = $nodeVersions | Sort-Object { [version]($_.version -replace 'v') }

Write-Host "Available Node.js versions:"
Write-Host "------------------------"

$sortedVersions | ForEach-Object {
    $ltsLabel = if ($_.lts) { " (LTS)" } else { "" }
    Write-Host "$($_.version)$ltsLabel"
}