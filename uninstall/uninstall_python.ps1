# uninstall_python.ps1
# This script uninstalls Python 3.10 (version 3.10.10) using Chocolatey.
choco uninstall python --version=3.10.10 -y
Write-Host "Python 3.10 has been uninstalled via Chocolatey."
