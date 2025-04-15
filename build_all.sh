#!/bin/bash

# Cross-platform build script for x-ui

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Create bin directory if it doesn't exist
if [ ! -d "./bin" ]; then
    mkdir -p ./bin
fi

# Build for Windows
echo "Building x-ui for Windows (amd64)..."
GOOS=windows GOARCH=amd64 go build -o ./bin/x-ui-windows-amd64.exe

# Build for Linux (amd64)
echo "Building x-ui for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o ./bin/x-ui-linux-amd64

# Build for Linux (arm64)
echo "Building x-ui for Linux (arm64)..."
GOOS=linux GOARCH=arm64 go build -o ./bin/x-ui-linux-arm64

# Build for macOS (amd64)
echo "Building x-ui for macOS (amd64)..."
GOOS=darwin GOARCH=amd64 go build -o ./bin/x-ui-darwin-amd64

# Build for macOS (arm64 - Apple Silicon)
echo "Building x-ui for macOS (arm64)..."
GOOS=darwin GOARCH=arm64 go build -o ./bin/x-ui-darwin-arm64

# Make Linux and macOS binaries executable
chmod +x ./bin/x-ui-linux-amd64 ./bin/x-ui-linux-arm64 ./bin/x-ui-darwin-amd64 ./bin/x-ui-darwin-arm64

echo "All builds completed. Executables are in the bin directory." 