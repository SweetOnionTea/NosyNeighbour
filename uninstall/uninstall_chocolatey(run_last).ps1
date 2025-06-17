# uninstall_chocolatey.ps1
# This script uninstalls Chocolatey by deleting its installation folders:
#   C:\ProgramData\chocolatey
#   C:\ProgramData\ChocolateyHttpCache

function Log-Info($msg) { Write-Host "[INFO] $msg" }
function Log-Warning($msg) { Write-Warning "[WARNING] $msg" }
function Log-Error($msg) { Write-Error -Message "[ERROR] $msg" }

try {
    $chocoFolder = "C:\ProgramData\chocolatey"
    $cacheFolder = "C:\ProgramData\ChocolateyHttpCache"

    if (Test-Path $chocoFolder) {
        Log-Info "Deleting Chocolatey folder: $chocoFolder"
        Remove-Item $chocoFolder -Recurse -Force
        Log-Info "Chocolatey folder deleted."
    }
    else {
        Log-Info "Chocolatey folder not found."
    }

    if (Test-Path $cacheFolder) {
        Log-Info "Deleting Chocolatey HTTP cache folder: $cacheFolder"
        Remove-Item $cacheFolder -Recurse -Force
        Log-Info "Chocolatey HTTP cache folder deleted."
    }
    else {
        Log-Info "Chocolatey HTTP cache folder not found."
    }
}
catch {
    Log-Error "An error occurred during Chocolatey uninstallation: $_"
}
