# Malware Artifacts

This markdown document will display all of the artifacts created/used within the Malwares phases. This will explain what to look for, the hash values of each artifact, and also provide methods of mitigating this malware's effectiveness by providing names and hashes. There are also some YARA and SIGMA rules to help identify the malware below.

#### List of Artifacts

###### **notepad-8.2.2-installer.exe** - Windows Portable Executable - PowerShell - Compiled with PS2EXE.

* Hash:
* Source: Notepadd++ Website, Download link
* Repository Location: .\larvae\egg.ps1 - PowerShell Script, .\server\static\downloads\notepaddpp-8.2.2-installer.exe

###### notepaddpp-8.2.2-portable.zip - Standard ZIP Archive that contains the artifact above.

* Hash:
* Source: Notepadd++ Website, Download link
* Repository Location: .\server\static\downloads\notepaddpp-8.2.2-portable.zip

###### regsvr32.exe - Custom regsvr32.exe compiled from PS Script (hatch.ps1 - PS2EXE) to exploit CVE-2025-41944 - Privilege Escalation Vulnerability

* Hash:
* Source: Malware Server upon executing notepaddpp-8.2.2-installer.exe
* Repository Location: .\larvae\hatch.ps1 - PowerShell Script,  .\server\payloads\regsvr32.exe

###### notepad-service.exe - Compile binary from Python using Pyinstaller to monitor clipboard and keystrokes and send encrypted to Malware Server

* Hash:
* Source: Malware Server upon successful exploitation of CVE-2025-41944 using custom regsvr32.exe payload and legit Notepad++ installer 8.8.1
* Repository Location: .\
