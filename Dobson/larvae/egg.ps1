# Test for internet connectivity
function Test-InternetConnection {
    try {
        $request = [System.Net.WebRequest]::Create("http://www.google.com")
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-InternetConnection)) {
    Write-Error "No internet connection detected. Please check your network settings."
    exit 1
}

# Run Larvae Script
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('http://localhost:8080/lay-eggs.ps1'))
exit 0