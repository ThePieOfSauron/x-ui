#!/bin/bash

# Shell build script for x-ui

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Create bin directory if it doesn't exist
if [ ! -d "./bin" ]; then
    mkdir -p ./bin
fi

# Determine OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture to Go architecture names
case $ARCH in
    x86_64)
        GOARCH=amd64
        ;;
    aarch64|arm64)
        GOARCH=arm64
        ;;
    *)
        GOARCH=$ARCH
        ;;
esac

# Build for the current platform
echo "Building x-ui for $OS/$GOARCH..."
export CGO_ENABLED=1
go build -o ./bin/x-ui -v main.go

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "Build successful! Executable is in the bin directory."
    
    # Make the binary executable
    chmod +x ./bin/x-ui
else
    echo "Build failed with exit code $?"
fi 