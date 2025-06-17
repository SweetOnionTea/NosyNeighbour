# Advanced Configuration Flags
# Modify these only if you are an advanced user who fully understands the implications.
# Change them only if you have already installed the corresponding component,
# or if you know that installing it will cause conflicts or issues on your system.
$skip_cuda12_1   = $false  
$skip_ffmpeg      = $false
$skip_python3_10  = $false
$skip_ollama      = $false
$skip_llama3_2    = $false  # Skip downloading the llama3.2 model. (Depends on Ollama being installed.)
$skip_venv_setup  = $false  # Skip creating the virtual environment and installing Python dependencies. (Depends on Python 3.10 being installed.)

# Select the type of Python virtual environment setup:
# $true  = Use CUDA12.1-enabled PyTorch in the python virtual environment
# $false = Use CPU-only PyTorch in the python virtual environment
$use_cuda12_1_torch   = $true

# ==============================
# Global Log Functions
# ==============================
function Log-Info($msg) { Write-Host "[INFO] $msg" }
function Log-Warning($msg) { Write-Warning "[WARNING] $msg" }
function Log-Error($msg) { Write-Error "[ERROR] $msg" }

##############################################
# Function: Install CUDA 12.1 (Compiler Only)
##############################################
function Install-CUDA121 {
    try {
        $cudaEnv = [Environment]::GetEnvironmentVariable("CUDA_PATH_V12_1")
        $cudaDir = "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.1\bin"
        if ($cudaEnv -and (Test-Path $cudaDir)) {
            Log-Info "CUDA 12.1 appears to be installed."
            return
        }
        Log-Info "CUDA 12.1 not found. Proceeding with installation..."
        $cudaInstallerUrl = "https://developer.download.nvidia.com/compute/cuda/12.1.0/network_installers/cuda_12.1.0_windows_network.exe"
        $installerPath = "$env:TEMP\cuda_12.1.0_windows_network.exe"
        
        Log-Info "Downloading CUDA 12.1 installer..."
        Invoke-WebRequest -Uri $cudaInstallerUrl -OutFile $installerPath
        Log-Info "CUDA 12.1 installer downloaded successfully."
        
        Log-Info "Starting CUDA 12.1 installation (compiler only) silently..."
        Start-Process -FilePath $installerPath -ArgumentList "-s nvcc_12.1"
        Log-Info "Sleeping for 2 minutes"
        Start-Sleep -Seconds 120

        # Set a timeout (e.g., 5 minutes)
        $timeoutSeconds = 300
        $startTime = Get-Date
        $cudaInstalled = $false

        while ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds -lt $timeoutSeconds) {
            Start-Sleep -Seconds 10
            $cudaEnvNew = [Environment]::GetEnvironmentVariable("CUDA_PATH_V12_1")
            if ($cudaEnvNew -or (Test-Path $cudaDir)) {
                $cudaInstalled = $true
                break
            }
        }

        if ($cudaInstalled) {
            Log-Info "CUDA 12.1 installed successfully."
        } else {
            Log-Warning "CUDA 12.1 installation did not complete within $timeoutSeconds seconds."
        }
        
        try {
            Remove-Item $installerPath -Force
            Log-Info "CUDA installer removed."
        }
        catch {
            Log-Warning "Failed to remove CUDA installer: $($_.Exception.Message)"
        }
    }
    catch {
        Log-Error "An error occurred while installing CUDA 12.1: $_"
        throw $_
    }
}

##############################################
# Function: Install Chocolatey
##############################################
function Install-Chocolatey {
    try {
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            # Check if Chocolatey folder exists and is empty
            $chocoFolder = "C:\ProgramData\chocolatey"
            if (Test-Path $chocoFolder) {
                $files = Get-ChildItem -Path $chocoFolder -Recurse -Force -ErrorAction SilentlyContinue
                if ($files.Count -eq 0) {
                    Log-Info "Chocolatey folder exists but is empty. Deleting folder..."
                    Remove-Item $chocoFolder -Recurse -Force
                    Log-Info "Empty Chocolatey folder deleted."
                }
            }
            Log-Info "Chocolatey is not installed. Installing Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            Log-Info "Chocolatey installation completed."
        }
        else {
            Log-Info "Chocolatey is already installed."
        }
    }
    catch {
        Log-Error "Failed to install Chocolatey: $_"
        throw $_
    }
}

##############################################
# Function: Silently install ffmpeg via Chocolatey
##############################################
function Install-FFmpeg {
    try {
        if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
            Log-Info "Installing ffmpeg silently..."
            choco install ffmpeg-full -y --no-progress | Out-Null
            Log-Info "ffmpeg installed successfully."
        }
        else {
            Log-Info "ffmpeg is already installed."
        }
    }
    catch {
        Log-Error "Failed to install ffmpeg: $_"
        throw $_
    }
}

##############################################
# Function: Silently install Python 3.10 via Chocolatey
##############################################
function Install-Python310 {
    try {
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            Log-Info "Python is not installed. Installing Python 3.10 silently..."
            choco install python --version=3.10.10 -y --no-progress --package-parameters "/quiet /norestart" | Out-Null
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
            Log-Info "Python 3.10 installation completed."
        }
        else {
            $pythonVersionOutput = & python --version 2>&1
            if ($pythonVersionOutput -notmatch "3\.10") {
                Log-Info "A version of Python other than 3.10 is installed. Installing Python 3.10 silently..."
                choco install python --version=3.10.10 -y --no-progress --package-parameters "/quiet /norestart" | Out-Null
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
                Log-Info "Python 3.10 installation completed."
            }
            else {
                Log-Info "Python 3.10 is already installed: $pythonVersionOutput"
            }
        }
    }
    catch {
        Log-Error "Failed to install Python 3.10: $_"
        throw $_
    }
}

##############################################
# Function: Install Ollama using official installer (silent)
##############################################
function Install-Ollama {
    try {
        $directInstallerUrl = "https://ollama.com/download/OllamaSetup.exe"
        $installerPath = "$env:TEMP\OllamaSetup.exe"
        $ollamaExePath = "$env:LOCALAPPDATA\Programs\Ollama\ollama app.exe"
    
        if ((Test-Path $ollamaExePath) -and (Get-Command "ollama" -ErrorAction SilentlyContinue)) {
            Log-Info "Ollama is already fully installed."
            return
        }
    
        try {
            Log-Info "Downloading Ollama installer..."
            Invoke-WebRequest -Uri $directInstallerUrl -OutFile $installerPath
            Log-Info "Installer downloaded successfully."
        }
        catch {
            Log-Error "Failed to download the installer: $($_.Exception.Message)"
            return
        }
    
        try {
            Log-Info "Starting Ollama installation (silent)..."
            Start-Process -FilePath $installerPath -ArgumentList "/silent"
            Log-Info "Sleeping for 2 minutes to ensure Ollama installs properly..."
            Start-Sleep -Seconds 120
    
            Log-Info "Monitoring for ollama.exe..."
            $timeoutSeconds = 300
            $startTime = Get-Date
    
            while ($null -eq (Get-Process -Name "ollama" -ErrorAction SilentlyContinue)) {
                Start-Sleep -Seconds 10
                $elapsedSeconds = (New-TimeSpan -Start $startTime -End (Get-Date)).TotalSeconds
                if ($elapsedSeconds -gt $timeoutSeconds) {
                    Log-Warning "ollama.exe process did not start within the timeout period. Attempting to launch manually..."
                    Start-Process -FilePath $ollamaExePath
                    Start-Sleep -Seconds 10  # Give a moment for manual launch
                    if ($null -eq (Get-Process -Name "ollama" -ErrorAction SilentlyContinue)) {
                        Log-Warning "Manual launch of ollama.exe failed."
                        return
                    }
                    else {
                        Log-Info "ollama.exe launched manually and is now running."
                        break
                    }
                }
            }
            Log-Info "ollama.exe process started successfully."
        }
        catch {
            Log-Error "Failed to install Ollama: $($_.Exception.Message)"
            return
        }
    
        try {
            Remove-Item $installerPath -Force
            Log-Info "Installer removed."
        }
        catch {
            Log-Warning "Failed to remove the installer: $($_.Exception.Message)"
        }
    }
    catch {
        Log-Error "An error occurred in Install-Ollama: $_"
        throw $_
    }
}

##############################################
# Function: Download the llama3.2 Model using Ollama Command
##############################################
function Download-LlamaModel {
    try {
        Log-Info "Checking if llama3.2 model is installed using 'ollama show llama3.2'..."
        $showOutput = & ollama show llama3.2 2>&1
        if ($showOutput -match "not found") {
            Log-Info "llama3.2 model not found. Proceeding to download with 'ollama pull llama3.2'..."
            $pullOutput = & ollama pull llama3.2 2>&1
            Log-Info "llama3.2 model downloaded successfully. Output:"
            Log-Info $pullOutput
        }
        else {
            Log-Info "llama3.2 model is already installed. Output from 'ollama show llama3.2':"
            Log-Info $showOutput
        }
    }
    catch {
        Log-Error "Failed to download or verify llama3.2 model: $_"
        throw $_
    }
}

##############################################
# Function: Create Python Virtual Environment using Python 3.10 and Install Dependencies
##############################################
function Setup-Venv {
    param(
        [string]$ProjectPath = (Get-Location),
        [string]$RequirementsFile = ""
    )
    try {
        $venvPath = Join-Path -Path $ProjectPath -ChildPath "venv"
        if (-not (Test-Path $venvPath)) {
            Log-Info "Creating Python virtual environment at '$venvPath' with Python 3.10..."
            # Use Windows Python launcher for version 3.10
            py -3.10 -m venv $venvPath
            Log-Info "Virtual environment created."
        }
        else {
            Log-Info "Virtual environment already exists at '$venvPath'."
        }
        $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            Log-Info "Activating virtual environment..."
            . $activateScript
        }
        else {
            Log-Warning "Activation script not found at '$activateScript'."
        }
        Log-Info "Upgrading pip..."
        python -m pip install --upgrade pip
        # If $use_cuda12_1_torch is true, install CUDA-enabled torch packages before installing the rest
        if ($use_cuda12_1_torch) {
            Log-Info "Installing CUDA-enabled PyTorch packages..."
            python -m pip install torch==2.1.2 torchaudio==2.1.2 --index-url https://download.pytorch.org/whl/cu121
        }
        if ($RequirementsFile -ne "") {
            if (Test-Path $RequirementsFile) {
                Log-Info "Installing dependencies from $RequirementsFile..."
                python -m pip install -r $RequirementsFile
                Log-Info "Dependencies installed successfully."
            }
            else {
                Log-Warning "$RequirementsFile not found in the current directory."
            }
        }
        else {
            Log-Info "No requirements file specified; skipping Python dependencies installation."
        }
    }
    catch {
        Log-Error "Error setting up the virtual environment: $_"
        throw $_
    }
}

##############################################
# Function: Update config.py with the correct WHISPER_DEVICE
##############################################
function Update-Config {
    try {
        $configFile = "config.py"
        if (Test-Path $configFile) {
            $content = Get-Content $configFile -Raw
            # Use a here-string to define the regex pattern
            $pattern = @"
WHISPER_DEVICE\s*=\s*([""'])[^\1]*?\1
"@.Trim()
            if ($use_cuda12_1_torch) {
                $newContent = $content -replace $pattern, 'WHISPER_DEVICE = "cuda"'
                Log-Info "Updated config.py: WHISPER_DEVICE set to cuda."
            }
            else {
                $newContent = $content -replace $pattern, 'WHISPER_DEVICE = "cpu"'
                Log-Info "Updated config.py: WHISPER_DEVICE set to cpu."
            }
            Set-Content -Path $configFile -Value $newContent
        }
        else {
            Log-Warning "config.py not found. Skipping update of WHISPER_DEVICE."
        }
    }
    catch {
        Log-Error "Error updating config.py: $_"
        throw $_
    }
}

##############################################
# Main Script Execution
##############################################
try {
    # Install CUDA 12.1 if not skipped
    if (-not $skip_cuda12_1) {
        Install-CUDA121
    }
    else {
        Log-Info "Skipping CUDA 12.1 installation as per configuration."
    }

    # If both skip_ffmpeg and skip_python3.10 are true, skip Chocolatey installation.
    if (-not ($skip_ffmpeg -and $skip_python3_10)) {
        Install-Chocolatey
    }
    else {
        Log-Info "Skipping Chocolatey installation since skip_ffmpeg and skip_python3.10 are set to true."
    }

    if (-not $skip_ffmpeg) {
        Install-FFmpeg
    }
    else {
        Log-Info "Skipping ffmpeg installation as per configuration."
    }

    if (-not $skip_python3_10) {
        Install-Python310
    }
    else {
        Log-Info "Skipping Python 3.10 installation as per configuration."
    }

    $pythonVer = python --version
    Log-Info "Python version: $pythonVer"

    if (-not $skip_ollama) {
        Install-Ollama
    }
    else {
        Log-Info "Skipping Ollama installation as per configuration."
    }

    if (-not $skip_llama3_2) {
        Download-LlamaModel
    }
    else {
        Log-Info "Skipping llama3.2 model download as per configuration. (Note: This depends on Ollama being installed.)"
    }

    if (-not $skip_venv_setup) {
        $reqFile = "requirements.txt"
        Log-Info "Using requirements file: $reqFile"
        Setup-Venv -ProjectPath (Get-Location) -RequirementsFile $reqFile
    }
    else {
        Log-Info "Skipping virtual environment setup as per configuration. (Note: This depends on Python 3.10 being installed.)"
    }
    
    # Update config.py with the correct WHISPER_DEVICE value based on $use_cuda12_1_torch
    Update-Config

    Log-Info "Setup complete. You can now run your application by executing 'python main.py' in the activated virtual environment."
}
catch {
    Log-Error "Installation script encountered an error: $_"
    exit 1
}
