# CuWasp (Cuckoo's Wasp)

## Overview
CuWasp represents a sophisticated social engineering simulation mimicking a legitimate software update (specifically a Chrome browser update) to deliver payloads and establish persistence.

**For Educational and Security Research Purposes Only.**

## Key Components
*   **CuWaspServer.py**: The C2 server handling update requests and exfiltration.
*   **chrome_update_generator.c**: C source code for creating the deceptive executable.
*   **chrome_service.py**: A python-based keylogger payload disguised as a service.
*   **chrome_update.ps1**: Persistence mechanism script.

## Scenario
1.  User visits a compromised page or is directed to `chrome_update.html`.
2.  User downloads and runs `chrome_update.exe`.
3.  The executable attempts to establish persistence and connect back to the C2.

## Artifacts
Refer to [Artifacts.md](Artifacts.md) for a list of files associated with this project.
