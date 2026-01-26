<#
CuWasp Cleaner Script
This script removes the CuWasp keylogger and its associated files from the system.
#>

# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    CuWasp Cleaner
.DESCRIPTION
    Cleanup utility to remove artifacts left by CuWasp simulations.
.AUTHOR
    CyberPanther232
#>

# Remove registry entries

Write-Host "Removing CuWasp keylogger and associated files..." -ForegroundColor Yellow
try {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_service.exe" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_update_service.exe" -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error removing registry entries: $_" -ForegroundColor Red
}

# Remove keylogger files
Write-Host "Deleting files..." -ForegroundColor Yellow
try {
    Remove-Item "C:\Users\Public\chrome_browser" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\keylog.txt" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\chrome_service.py" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\chrome_update.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\python-3.13.7-embed-amd64.zip" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Temp\get-pip.py" -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error removing files: $_" -ForegroundColor Red
}

try {
    Remove-Item "C:\Temp" -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error removing C:\Temp directory: $_" -ForegroundColor Red
}


# Optional: Remove Python installation if it was only used for the keylogger

try {
    Remove-Item "C:\Users\Public\chrome_browser" -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "Error removing Python installation: $_" -ForegroundColor Red
}

New-Item -Path "C:\Temp" -ItemType Directory -Force | Out-Null
# Remove scheduled tasks if any (uncomment if you used scheduled tasks)
# schtasks /Delete /TN "CuWaspKeylogger" /F

# Stop processes if they are running
Write-Host "Stopping related processes..." -ForegroundColor Yellow
try {
    Get-Process -Name "pythonw" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "python" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "python3.12" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "cmd" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Stop-Process -Force

} catch {
    Write-Host "Error stopping processes: $_" -ForegroundColor Red
}

Write-Host "CuWasp keylogger and associated files have been removed." -ForegroundColor Green
# End of CuWasp Cleaner Script