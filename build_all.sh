#!/bin/bash

# Cross-platform build script for x-ui

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Get version from main.go or config/version
VERSION=$(grep -Po "version\s+=\s+\"\K[^\"]*" main.go 2>/dev/null || cat config/version 2>/dev/null || echo "0.3.4")
echo "Building x-ui version $VERSION"

# Create bin directory if it doesn't exist
if [ ! -d "./bin" ]; then
    mkdir -p ./bin
fi

# Create version-specific release directory
RELEASE_DIR="./releases/v${VERSION}"
mkdir -p "$RELEASE_DIR"

# Function to build and create compressed archive
build_and_compress() {
    local OS=$1
    local ARCH=$2
    local BIN_NAME="x-ui-${OS}-${ARCH}"
    local ARCHIVE_NAME="${BIN_NAME}-${VERSION}"
    local ARCHIVE_EXT="tar.gz"
    
    if [ "$OS" = "windows" ]; then
        BIN_NAME="${BIN_NAME}.exe"
        ARCHIVE_EXT="zip"
    fi
    
    echo "Building x-ui for ${OS} (${ARCH})..."
    GOOS=$OS GOARCH=$ARCH go build -o "./bin/${BIN_NAME}"
    
    # Make Linux and macOS binaries executable
    if [ "$OS" != "windows" ]; then
        chmod +x "./bin/${BIN_NAME}"
    fi
    
    # Create archive
    echo "Creating archive for ${OS} (${ARCH})..."
    if [ "$OS" = "windows" ]; then
        (cd ./bin && zip -q -r "../${RELEASE_DIR}/${ARCHIVE_NAME}.${ARCHIVE_EXT}" "${BIN_NAME}")
    else
        (cd ./bin && tar -czf "../${RELEASE_DIR}/${ARCHIVE_NAME}.${ARCHIVE_EXT}" "${BIN_NAME}")
    fi
    
    echo "Created ${RELEASE_DIR}/${ARCHIVE_NAME}.${ARCHIVE_EXT}"
}

# Build for Windows
build_and_compress "windows" "amd64"

# Build for Linux (amd64)
build_and_compress "linux" "amd64"

# Build for Linux (arm64)
build_and_compress "linux" "arm64"

# Build for macOS (amd64)
build_and_compress "darwin" "amd64"

# Build for macOS (arm64 - Apple Silicon)
build_and_compress "darwin" "arm64"

# Create a checksums file
echo "Creating checksums..."
(cd "${RELEASE_DIR}" && sha256sum * > SHA256SUMS)

echo "All builds completed. Archives are in the ${RELEASE_DIR} directory." 