<#
.SYNOPSIS
    Update-Artifacts.ps1
    Automates the discovery and documentation of artifacts within the BugWare repository.

.DESCRIPTION
    This script scans the repository for interesting artifact files (exe, ps1, py, js, dll, etc.).
    It calculates their SHA256 hashes and updates (or creates) an Artifacts.json file 
    containing metadata about each artifact. This helps track changes and new additions.

.AUTHOR
    CyberPanther232 (Automated by GitHub Copilot)

.EXAMPLE
    .\Update-Artifacts.ps1
#>

$Projects = @(
    "C2",
    "Cordyceps",
    "CuWasp",
    "CVE-2025-54100",
    "Dobson",
    "logins",
    "RustyTick",
    "Spicebush"
)

$ArtifactExtensions = @(".exe", ".ps1", ".py", ".js", ".dll", ".c", ".go", ".rs")
$OutputFile = "Artifacts.json"
$RepoRoot = Get-Location

$ArtifactsRegistry = @()

Write-Host "Starting Artifact Discovery..." -ForegroundColor Cyan

foreach ($Project in $Projects) {
    if (Test-Path $Project) {
        Write-Host "Scanning project: $Project" -ForegroundColor Yellow
        $Files = Get-ChildItem -Path $Project -Recurse -File | Where-Object { $ArtifactExtensions -contains $_.Extension }

        foreach ($File in $Files) {
            $RelativePath = $File.FullName.Substring($RepoRoot.Path.Length + 1)
            
            # Calculate Hash
            $HashObj = Get-FileHash -Path $File.FullName -Algorithm SHA256
            $Hash = $HashObj.Hash

            # Create Artifact Object
            $Artifact = [PSCustomObject]@{
                Project      = $Project
                Name         = $File.Name
                Path         = $RelativePath
                Extension    = $File.Extension
                SHA256       = $Hash
                LastModified = $File.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                Size         = $File.Length
            }

            $ArtifactsRegistry += $Artifact
            Write-Host "  Found: $($File.Name)" -ForegroundColor Gray
        }
    }
}

# Export to JSON
$ArtifactsRegistry | ConvertTo-Json -Depth 3 | Set-Content $OutputFile
Write-Host "Artifact discovery complete. Registry saved to $OutputFile" -ForegroundColor Green
