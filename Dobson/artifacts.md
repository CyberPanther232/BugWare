# Malware Artifacts

This markdown document will display all of the artifacts created/used within the Malwares phases. This will explain what to look for, the hash values of each artifact, and also provide methods of mitigating this malware's effectiveness by providing names and hashes. There are also some YARA and SIGMA rules to help identify the malware below.

#### List of Artifacts

###### **notepad-8.2.2-installer.exe** - Windows Portable Executable - PowerShell - Compiled with PS2EXE.

* Hash: `57EDE46355ECEE761AAE19239B51B37D89E4F50E9E18EE48D31107578C175570`
* Source: Notepadd++ Website, Download link
* Repository Location: .\larvae\egg.ps1 - PowerShell Script, .\server\static\downloads\notepaddpp-8.2.2-installer.exe

###### notepaddpp-8.2.2-portable.zip - Standard ZIP Archive that contains the artifact above.

* Hash: (Hash not available)
* Source: Notepadd++ Website, Download link
* Repository Location: .\server\static\downloads\notepaddpp-8.2.2-portable.zip

###### regsvr32.exe - Custom regsvr32.exe compiled from PS Script (hatch.ps1 - PS2EXE) to exploit CVE-2025-41944 - Privilege Escalation Vulnerability

* Hash: `EA1B5E3BE48A2BD872D3B6A2DDF39D170655F3CBF6E65C495878766E23527858`
* Source: Malware Server upon executing notepaddpp-8.2.2-installer.exe
* Repository Location: .\larvae\hatch.ps1 - PowerShell Script,  .\server\payloads\regsvr32.exe

###### notepad-service.exe - Compile binary from Python using Pyinstaller to monitor clipboard and keystrokes and send encrypted to Malware Server

* Hash: `E636E3096CE8F5EEBECF49550DACF34020B16E1535E25EF5A05E84BC10585971`
* Source: Malware Server upon successful exploitation of CVE-2025-41944 using custom regsvr32.exe payload and legit Notepad++ installer 8.8.1
* Repository Location: .\Dobson\server\payloads\notepad-service.exe
