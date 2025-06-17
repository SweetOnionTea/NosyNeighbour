# uninstall_ffmpeg.ps1
# This script uninstalls ffmpeg using Chocolatey.
choco uninstall ffmpeg-full -y
Write-Host "ffmpeg has been uninstalled via Chocolatey."
