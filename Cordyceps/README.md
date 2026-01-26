# Cordyceps

## Overview
Cordyceps is a malware simulation framework focusing on payload delivery and staging. It uses a hybrid approach with a Python (Flask) delivery server and PowerShell stagers to demonstrate modern infection chains.

**For Educational and Security Research Purposes Only.**

## Key Components
*   **app.py**: The delivery server that serves payloads.
*   **infect.ps1**: The initial stager script designed to establish access.
*   **spore.ps1**: A secondary payload for downloading tools.
*   **Get-DeviceStats.ps1 / GetDeviceStats.exe**: benign decoy executable.

## Usage
1.  Start the Flask server: `python app.py`
2.  Execute the stager (simulated victim): `powershell -ExecutionPolicy Bypass -File infect.ps1`

## Artifacts
Refer to [Artifacts.md](Artifacts.md) for a list of files associated with this project.
