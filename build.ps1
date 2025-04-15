# PowerShell build script for x-ui

# Set Go proxy to bypass potential network restrictions
$env:GOPROXY = 'https://goproxy.io,direct'

# Create bin directory if it doesn't exist
if (-not (Test-Path -Path ".\bin")) {
    New-Item -ItemType Directory -Path ".\bin"
}

# Build for Windows
Write-Output "Building x-ui for Windows..."
& 'C:\Program Files\Go\bin\go.exe' build -o .\bin\x-ui.exe

# Check if build was successful
if ($LASTEXITCODE -eq 0) {
    Write-Output "Build successful! Executable is in the bin directory."
} else {
    Write-Output "Build failed with exit code $LASTEXITCODE"
} 