# Building x-ui

This document provides instructions for building the x-ui application for different platforms.

## Prerequisites

- Go 1.17 or higher
- Git
- For Linux/macOS: wget, unzip
- For Windows: PowerShell

## Build Scripts

We provide several build scripts for different platforms and use cases:

### Windows

To build on Windows, run the PowerShell script:

```powershell
.\build.ps1
```

This will create `x-ui.exe` in the `bin` directory.

### Linux/macOS

To build on Linux or macOS for your current platform, run:

```bash
chmod +x build.sh
./build.sh
```

This will create `x-ui` in the `bin` directory.

### Cross-platform Build

To build for multiple platforms at once, run:

```bash
chmod +x build_all.sh
./build_all.sh
```

This will create the following executables in the `bin` directory:
- `x-ui-windows-amd64.exe`: Windows x64
- `x-ui-linux-amd64`: Linux x64
- `x-ui-linux-arm64`: Linux ARM64 (e.g., Raspberry Pi)
- `x-ui-darwin-amd64`: macOS Intel
- `x-ui-darwin-arm64`: macOS Apple Silicon (M1/M2)

## Packaging for GitHub Releases

We also provide scripts to package the application for GitHub releases:

### Windows

To package for Windows:

```powershell
.\package.bat
```

This will create a ZIP archive in the `releases` directory.

### Linux/macOS

To package for Linux and other platforms:

```bash
chmod +x package.sh
./package.sh
```

This will create archives for Windows, Linux AMD64, and Linux ARM64 in the `releases` directory.

### What's Included in Packages

Each package includes:
- The x-ui executable for the respective platform
- The latest Xray core binary for the respective platform
- The latest geoip.dat and geosite.dat files
- Service files for Linux packages

## Docker Build

You can also build using Docker:

```bash
docker build -t x-ui .
```

To run the Docker container:

```bash
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    x-ui
```

## Manual Build

If you prefer to build manually:

```bash
# For current platform
go build -o bin/x-ui

# For specific platform
GOOS=linux GOARCH=amd64 go build -o bin/x-ui-linux-amd64
```

## Note on Windows Build

When building on Windows, you may need to use the full path to the Go executable if it's not in your PATH:

```powershell
& 'C:\Program Files\Go\bin\go.exe' build -o .\bin\x-ui.exe
``` 