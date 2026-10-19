<div align="center">

> **Strictly for security research:** SpyderByte is provided for authorized security research, defensive testing, and education only. It is **not intended for malicious purposes**, unauthorized access, surveillance, disruption, or damage. Use it only against networks, devices, and test environments that you own or are explicitly authorized to assess. Wireless deauthentication can disrupt other users and may be illegal without permission. The authors are not responsible for misuse, unlawful activity, service interruption, data loss, or damage. Out of caution, I have refrained from including the entire source code of the application and have broken it into snippets below and in my blog.

## Overview

SpyderByte is a Linux-oriented proof of concept for controlled wireless-security research. Its primary workflow is designed to:

- identify a wireless interface and prepare it for monitor-mode capture;
- discover nearby beacon frames while moving across 2.4 GHz channels;
- match a configured network by SSID or BSSID;
- observe EAPOL traffic and write captured packets to a PCAP file; and
- restore the network manager and interface state when the process exits.

This project does not grant permission to test any network. Authorization must be obtained before installation, capture, or transmission of wireless frames. Any use outside legitimate security research is prohibited.

The repository also contains an isolated deauthentication module for lab experimentation. That capability is intentionally not described as a benign scanning feature: it is disruptive and must only be tested in an isolated, authorized environment.

## Project Status

This is an early prototype, not a production-ready assessment platform. The current implementation has no automated test suite, dependency lockfile, CLI argument parser, or package metadata. Review the source before running it in any environment.

## Requirements

SpyderByte currently targets Linux and expects:

- Python 3.11 or newer;
- a compatible wireless adapter with monitor-mode support;
- root privileges for interface changes and packet capture;
- Scapy;
- pandas; and
- the Aircrack-ng and iproute2 command-line tools (`airmon-ng`, `aireplay-ng`, `airodump-ng`, `ip`, and `iw`).

The checked-in `pyenv` directory is machine-specific and should not be treated as a portable environment. Create a fresh virtual environment on the Linux host instead:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install scapy pandas
```

Install the native wireless tools using your distribution's package manager. Package names vary by distribution; consult the official documentation for Aircrack-ng and iproute2.

## Configuration

`main.py` currently reads a `bug.txt` file from a hard-coded path. Before using the prototype, update that path in the source or provide the expected file at the configured location.

The file uses one key per line:

```text
MODE: spyder
SSID: authorized-lab-network
BSSID: 00:11:22:33:44:55
INT_MAC_ADDR:  aa:bb:cc:dd:ee:ff
```

`MODE` supports the implemented values `spyder` and `dos`. A target `SSID` or `BSSID` is required, and `INT_MAC_ADDR` is used to select the wireless interface. Treat these values as lab configuration, not as a security boundary.

## Running In A Lab

Run the application only from an authorized Linux test environment with a disposable adapter and a controlled access point. Keep a second management path available because the program may stop NetworkManager while preparing monitor mode.

```bash
sudo .venv/bin/python main.py
```

The normal research flow writes captured packets to `handshake.cap` when EAPOL traffic is observed. Capture files can contain sensitive material; protect them as confidential test artifacts and delete them according to your lab's retention policy.

Do not run the deauthentication routines against public, shared, or third-party networks. They transmit management frames intended to disconnect clients and can cause real service interruption. This capability is included only to support controlled security research in an isolated lab.

## Repository Layout


| Path            | Purpose                                                                                             |
| ----------------- | ----------------------------------------------------------------------------------------------------- |
| `main.py`       | Main prototype: interface preparation, discovery, channel hopping, capture, and cleanup.            |
| `deauth.py`     | Separate experimental deauthentication and Aircrack-ng helpers.                                     |
| `failsafe.sh`   | Attempts to launch the main program from the original development environment. Review before reuse. |
| `SpyderByte.md` | Project documentation.                                                                              |

## Known Limitations

- Linux-only system commands and service management are used throughout the code.
- Several paths and interface assumptions are hard-coded to the original development machine.
- The runtime depends on globals and incomplete integration between helper functions and the main loop; behavior may require source-level adjustment before it runs successfully.
- Channel handling is limited to the default 2.4 GHz channel range in the current implementation.
- Error recovery is best-effort and should be verified manually after an interrupted run.
- There is no supported Windows execution path, even though the repository may be edited from Windows.
- No automated tests or reproducible dependency specification are included yet.

## Responsible Use

Use this project strictly for defensive security research, authorized penetration testing, interoperability testing, and education. It is not for malicious purposes or unauthorized activity. Maintain documented authorization, follow applicable laws and organizational policies, minimize impact on test systems, and use responsible disclosure practices. Never use captured credentials, frames, or traffic from networks you do not control. Stop testing immediately if authorization is unclear or revoked.

## Contributing

Small, focused improvements are welcome. Before opening a change, please verify it in an isolated lab and include the Linux distribution, Python version, adapter chipset, and required native tool versions in the report. High-value next steps include removing hard-coded paths, adding argument validation, isolating privileged operations, adding cleanup tests, and introducing a reproducible dependency file.

## License

No license file is currently included. Treat the repository as all rights reserved unless the project owner adds explicit licensing terms.
