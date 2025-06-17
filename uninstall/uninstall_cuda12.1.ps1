# uninstall_cuda12.1.ps1
# This script searches the registry for the uninstall entry for NVIDIA CUDA Development 12.1
# and launches its uninstaller interactively.

function Log-Info($msg) { Write-Host "[INFO] $msg" }
function Log-Warning($msg) { Write-Warning "[WARNING] $msg" }
function Log-Error($msg) { Write-Error -Message "[ERROR] $msg" }

# Registry key for CUDA Development 12.1 (adjust if necessary)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_CUDADevelopment_12.1"

if (Test-Path $regPath) {
    try {
        $uninstallInfo = Get-ItemProperty -Path $regPath
        $uninstallString = $uninstallInfo.UninstallString
        if ($uninstallString) {
            Log-Info "Found CUDA 12.1 uninstall string:"
            Log-Info $uninstallString
            
            # We know the uninstall string from your discovery is:
            # "C:\WINDOWS\SysWOW64\RunDll32.EXE" "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage CUDADevelopment_12.1
            #
            # We'll split it into:
            #   FilePath: "C:\WINDOWS\SysWOW64\RunDll32.EXE"
            #   Arguments: "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage CUDADevelopment_12.1
            
            # (Assuming the uninstall string is exactly the above, we hard-code the values.)
            $filePath = "C:\WINDOWS\SysWOW64\RunDll32.EXE"
            $arguments = '"C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage CUDADevelopment_12.1'
            
            Log-Info "Launching uninstaller interactively..."
            Start-Process -FilePath $filePath -ArgumentList $arguments -Wait
            Log-Info "Uninstaller process completed."
        }
        else {
            Log-Warning "Uninstall string not found in the registry. Please uninstall CUDA Toolkit 12.1 manually via Settings -> Apps."
        }
    }
    catch {
        Log-Error "An error occurred while retrieving uninstall information: $_"
    }
}
else {
    Log-Warning "CUDA Development 12.1 uninstall information not found in the registry. Please uninstall it manually via Settings -> Apps."
}
