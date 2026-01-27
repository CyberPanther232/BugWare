# Phases of Attack

### Diagram

![1769476467786](image/phases/1769476467786.png)

### Phase 1. Larvae - Stagers / Initial Access

##### MITRE ATT&CK Mapping

During this phase, two primary MITRE ATT&CK techniques are utilized to gain initial access: Phishing (T1566) and Supply Chain Compromise (T1195).

*   **T1566.001** - Phishing: Spearphishing Attachment
*   **T1566.002** - Phishing: Spearphishing Link
*   **T1195.001** - Supply Chain Compromise: Compromise Software Dependencies and Development Tools
*   **T1195.002** - Supply Chain Compromise: Compromise Software Supply Chain

##### Phase Exploration

This phase focuses on socially engineering the victim into downloading and executing an artifact named `notepaddpp-8.2.2-installer.exe`. This initial stager serves as the catalyst for the infection chain. The executable is compiled from a PowerShell script (`egg.ps1`) using the PS2EXE utility.

```powershell
ps2EXE -InputFile .\larvae\egg.ps1 -OutputFile .\notepaddpp-8.2.2-installer.exe
```

Upon execution, this stager contacts the malware command and control (C2) server (Go HTTP server) to retrieve a secondary PowerShell script named `lay-eggs.ps1`. This script is executed directly in memory, initiating Phase 2.

### Phase 2. Lay Eggs - Execution / Privilege Escalation

##### MITRE ATT&CK Mapping

During this phase, there are four different MITRE ATT&CK techniques utilized during this phase. These techniques/sub-techniques are User Execution of a malicious file (T1204.002), Modify Registry (T1112), Scheduled Task/Job (T1053.005), and Exploitation for Privilege Escalation (T1068).

###### Execution
This phase employs four specific MITRE ATT&CK techniques involving execution, persistence, and privilege escalation.

###### Execution

*   **T1204.002** - User Execution: Malicious File
    *   Execution of `notepaddpp-8.2.2-installer.exe`.

###### Privilege Escalation

*   **T1068** - Exploitation for Privilege Escalation
    *   Exploits CVE-2025-41944 using a legitimate Notepad++ 8.8.1 installer and a custom `regsvr32.exe` payload (compiled from `hatch.ps1`) to escalate privileges to Administrator/SYSTEM.
*   **T1112** - Modify Registry
*   **T1053.005** - Scheduled Task/Job

##### Phase Exploration

In this phase, the malware configures the environment for full infection. It utilizes the legitimate Notepad++ version 8.8.1 installer alongside a malicious `regsvr32.exe` binary downloaded from the C2 server. The `lay-eggs.ps1` script orchestrates the download and execution of these components.

By triggering the installation of Notepad++, the CVE-2025-41944 vulnerability is exploited, allowing the custom `regsvr32.exe` to run with elevated privileges. Once administrative access is secured, the operation transitions to Phase 3.
### Phase 3. Hatch and Grab - Persistence / Collection / C2 / Exfiltration

##### MITRE ATT&CK Mapping

During this final phase, four major tactics from the MITRE ATT&CK framework are employed, utilizing multiple techniques and sub-techniques.

###### Persistence & Defense Evasion

*   **T1112** - Modify Registry
    *   Adds a Run key `HKLM:\Software\Microsoft\Windows\CurrentVersion\Run` for persistence.
*   **T1053.005** - Scheduled Task/Job: Scheduled Task
    *   Creates a system-level scheduled task "NotepaddPlusPlusService" to ensure the payload runs at startup with high privileges.
*   **T1562.001** - Impair Defenses: Disable or Modify Tools (mapped as Selective Exclusion T1679 in context)
    *   Adds `C:\` to the Windows Defender exclusion list to blind local security controls.

###### Collection

*   **T1056.001** - Input Capture: Keylogging
    *   Captures user keystrokes using the Python `pynput` library.
*   **T1115** - Clipboard Data
    *   Monitors and copies text from the system clipboard.
*   **T1074.001** - Data Staged: Local Data Staging
    *   Temporarily stores captured data in specific files within the `%TEMP%` directory before exfiltration.

###### Command and Control & Exfiltration

*   **T1573.002** - Encrypted Channel: Asymmetric Cryptography
    *   Encrypts communications using NaCl (Curve25519) to secure the data in transit and evade network inspection.
*   **T1071.001** - Application Layer Protocol: Web Protocols
    *   Uses standard HTTP POST requests for communication.
*   **T1041** - Exfiltration Over C2 Channel
    *   Sends staged data back to the central command server.

##### Phase Exploration

This phase represents the full compromise of the victim machine. It begins with the execution of the elevated `regsvr32.exe` payload (the "Hatch"), which immediately works to secure its foothold.

1.  **Persistence & Evasion**: The script establishes persistence through two mechanisms: a Registry Run Key and a Scheduled Task running as SYSTEM. Crucially, it attempts to neutralize antivirus defenses by adding the entire `C:\` drive to the Windows Defender exclusion list.
2.  **Service Installation**: It downloads the core espionage agent, `notepad-service.exe`, placing it in a hidden directory structure in `C:\ProgramData\npp\`.
3.  **Surveillance (The "Grab")**: Once launched, the `notepad-service.exe` agent operates silently in the background. It hooks into the keyboard and clipboard APIs, recording every keystroke and copied text snippet.
4.  **Exfiltration**: As data is collected, it is staged locally before being encrypted with high-grade asymmetric cryptography. The agent then unilaterally pushes this information to the C2 server, providing the attacker with a real-time stream of the victim's sensitive information.
