#!/usr/bin/env pwsh

# Script to install GitHub CLI on Windows
# This is useful for setting up your environment for releases

$ErrorActionPreference = "Stop"

Write-Host "Installing GitHub CLI for Windows..." -ForegroundColor Green

# Temporary directory for downloads
$tempDir = Join-Path $env:TEMP "gh-cli-install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Get the latest release download URL
Write-Host "Finding latest GitHub CLI release..." -ForegroundColor Yellow
$latestReleaseUrl = "https://api.github.com/repos/cli/cli/releases/latest"
$latestReleaseInfo = Invoke-RestMethod -Uri $latestReleaseUrl

$downloadUrl = $latestReleaseInfo.assets | 
               Where-Object { $_.name -like "*windows_amd64.zip" } | 
               Select-Object -ExpandProperty browser_download_url -First 1

if (-not $downloadUrl) {
    Write-Host "Could not find download URL for GitHub CLI" -ForegroundColor Red
    exit 1
}

# Download the ZIP file
$zipPath = Join-Path $tempDir "gh-cli.zip"
Write-Host "Downloading GitHub CLI from: $downloadUrl" -ForegroundColor Yellow
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

# Extract the ZIP
Write-Host "Extracting GitHub CLI..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

# Find the bin directory containing gh.exe
$ghExePath = Get-ChildItem -Path $tempDir -Recurse -Filter "gh.exe" | Select-Object -First 1 -ExpandProperty FullName
if (-not $ghExePath) {
    Write-Host "Could not find gh.exe in the extracted files" -ForegroundColor Red
    exit 1
}

$ghDir = Split-Path -Parent $ghExePath

# Create installation directory
$installDir = Join-Path $env:LOCALAPPDATA "GitHubCLI"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Copy files
Write-Host "Installing GitHub CLI to $installDir..." -ForegroundColor Yellow
Copy-Item -Path (Join-Path $ghDir "*") -Destination $installDir -Recurse -Force

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*GitHubCLI*") {
    Write-Host "Adding GitHub CLI to PATH..." -ForegroundColor Yellow
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
    $env:Path = "$env:Path;$installDir"
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

# Test the installation
Write-Host "Testing GitHub CLI installation..." -ForegroundColor Yellow
try {
    $version = & "$installDir\gh.exe" --version
    Write-Host "GitHub CLI installed successfully: $version" -ForegroundColor Green
    Write-Host "You can now use 'gh' from your terminal. You may need to restart your terminal for changes to take effect." -ForegroundColor Cyan
    Write-Host "To authenticate with GitHub, run: gh auth login" -ForegroundColor Cyan
} catch {
    Write-Host "GitHub CLI installation failed: $_" -ForegroundColor Red
} 