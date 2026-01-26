# Cordyceps Artifacts

This document lists the artifacts found within the Cordyceps project, used for educational research into malware staging and delivery.

## Artifact List

### **GetDeviceStats.exe**

* **Description**: Compiled executable of `Get-DeviceStats.ps1`. Acts as a decoy or benign tool that may beacon out or collect system info.
* **Type**: Windows Portable Executable (PE)
* **Hash (SHA256)**: `6A433747F980F5E7563FE3B2FD3E1F08872622E77071A3E8AEA74095FE04D32F`
* **Source**: Compiled from `Get-DeviceStats.ps1` using tools like PS2EXE.
* **Repository Location**: `.\Cordyceps\GetDeviceStats.exe`

### **regsvr32.exe**

* **Description**: Custom executable masking as `regsvr32.exe`. Used to exploit CVE-2025-41944.
* **Type**: Windows Portable Executable (PE)
* **Hash (SHA256)**: `01A2AAF0A42BD174810182771B0287BE0EC8F36BE83EEB1A99D73C01FBE54BD7`
* **Source**: Generated payload for training purposes.
* **Repository Location**: `.\Cordyceps\regsvr32.exe`

### **infect.ps1**

* **Description**: Initial access stager script. Disables defenses (simulated) and establishes C2 connection.
* **Type**: PowerShell Script
* **Hash (SHA256)**: `D968482C2FCA9A8D55FDED6C895CB862F8C0EDDE63500D39DA00CD4529F1E7F8`
* **Source**: Repository Source
* **Repository Location**: `.\Cordyceps\infect.ps1`

### **spore.ps1**

* **Description**: Secondary payload script. Downloads additional tools (e.g., Notepad++, custom tools).
* **Type**: PowerShell Script
* **Hash (SHA256)**: `2BE8DEC3924D0E8B18144F4C9E5CC85C599E1C1A1EBF15F25167E4388078CE0C`
* **Source**: Repository Source
* **Repository Location**: `.\Cordyceps\spore.ps1`
