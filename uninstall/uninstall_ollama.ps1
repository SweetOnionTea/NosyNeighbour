# uninstall_ollama.ps1
# This script uninstalls Ollama using its built-in uninstaller (unins000.exe).
# If the uninstaller is not found, it simply logs a warning and does nothing.

function Log-Info($msg) { Write-Host "[INFO] $msg" }
function Log-Warning($msg) { Write-Warning "[WARNING] $msg" }
function Log-Error($msg) { Write-Error -Message "[ERROR] $msg" }

try {
    # Define the Ollama installation folder and uninstaller path
    $ollamaFolder = "$env:LOCALAPPDATA\Programs\Ollama"
    $uninstallerPath = Join-Path -Path $ollamaFolder -ChildPath "unins000.exe"
    
    if (Test-Path $uninstallerPath) {
        Log-Info "Found Ollama uninstaller at $uninstallerPath."
        Log-Info "Starting Ollama uninstallation..."
        Start-Process -FilePath $uninstallerPath -Wait
        Log-Info "Ollama uninstallation completed."
    }
    else {
        Log-Warning "Ollama uninstaller not found at $uninstallerPath. Skipping uninstallation."
    }
    
    Log-Info "Ollama uninstallation script has completed."
}
catch {
    Log-Error "An error occurred during Ollama uninstallation: $_"
}
