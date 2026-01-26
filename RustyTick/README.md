# RustyTick

## Overview
RustyTick is a data exfiltration toolkit written in Rust. It demonstrates how modern languages can be used to create performant agents for identifying and compressing target data.

**For Educational and Security Research Purposes Only.**

## Key Components
*   **rustytick**: The client-side agent that searches for files (like .csv or .txt) and zips them.
*   **rustyTickReceiver**: The server-side component that listens for incoming exfiltrated data.

## Usage
1.  **Receiver**: Start the receiver to listen for connections.
    *   `cd rustyTickReceiver && cargo run`
2.  **Agent**: Compile and run the agent on the target.
    *   `cd rustytick && cargo run`

## Artifacts
Refer to [Artifacts.md](Artifacts.md) for a list of files associated with this project.
