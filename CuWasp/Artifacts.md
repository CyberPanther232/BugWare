# CuWasp Artifacts

This document lists the artifacts found within the CuWasp (Cuckoo's Wasp) project, used for educational research into social engineering and persistence mechanisms.

## Artifact List

### **chrome_update.exe**
*   **Description**: Malicious executable masquerading as a Chrome browser update.
*   **Type**: Windows Portable Executable (PE)
*   **Hash (SHA256)**: `1C2603E536C90A3585B94FF128FDDD8A2EE893A02D3178EBC17BAB6E7ACD71D7`
*   **Source**: Generated from `chrome_update_generator.c`.
*   **Repository Location**: `.\CuWasp\payloads\chrome_update.exe`

### **chrome_update.ps1**
*   **Description**: PowerShell script payload initiated by the fake update to establish persistence or inject code.
*   **Type**: PowerShell Script
*   **Hash (SHA256)**: `2E523A61FB5856804781A6C0A7A58E745CC2D3CDE2DFC5FE1AC3F26C24B11EF8`
*   **Source**: Repository Source
*   **Repository Location**: `.\CuWasp\payloads\chrome_update.ps1`

### **chrome_service.py**
*   **Description**: Python script functioning as a keylogger, disguised as a support service.
*   **Type**: Python Script
*   **Hash (SHA256)**: `43B9F0454D0618852499D38477ED76C5CB25981047933731FA93C912521196B2`
*   **Source**: Repository Source
*   **Repository Location**: `.\CuWasp\payloads\chrome_service.py`
