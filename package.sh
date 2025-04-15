#!/bin/bash

# Script to build and package x-ui for different platforms for GitHub releases
set -e

VERSION=$(grep -Po "version\s+=\s+\"\K[^\"]*" main.go 2>/dev/null || cat config/version 2>/dev/null || echo "0.3.4")
echo "Packaging x-ui version $VERSION"

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Create cache directory for Xray binaries
CACHE_DIR="./xray_cache"
mkdir -p "$CACHE_DIR"

# Create version-specific release directory
RELEASE_DIR="./releases/v${VERSION}"
mkdir -p "$RELEASE_DIR"

# Function to build and package for a specific platform
build_and_package() {
    local OS=$1
    local ARCH=$2
    local XRAY_SUFFIX=$3
    local PKG_NAME="x-ui-${OS}-${ARCH}-${VERSION}"
    local ARCHIVE_EXT="tar.gz"
    
    if [ "$OS" = "windows" ]; then
        ARCHIVE_EXT="zip"
    fi
    
    echo "Building for $OS/$ARCH..."
    
    # Build the binary
    if [ "$OS" = "windows" ]; then
        GOOS=$OS GOARCH=$ARCH go build -o xui-release.exe -v main.go
    else
        GOOS=$OS GOARCH=$ARCH go build -o xui-release -v main.go
    fi
    
    # Create package directory
    mkdir -p "x-ui"
    
    # Copy binary and scripts
    cp xui-release* "x-ui/"
    cp x-ui.service "x-ui/" 2>/dev/null || true
    cp x-ui.sh "x-ui/" 2>/dev/null || true
    
    # Rename binary
    if [ "$OS" = "windows" ]; then
        mv "x-ui/xui-release.exe" "x-ui/x-ui.exe"
    else
        mv "x-ui/xui-release" "x-ui/x-ui"
    fi
    
    # Create bin directory and download Xray
    mkdir -p "x-ui/bin"
    cd "x-ui/bin"
    
    # Determine the Xray zip filename and cache location
    local XRAY_ZIP_NAME=""
    if [ "$OS" = "windows" ]; then
        XRAY_ZIP_NAME="Xray-windows-64.zip"
    else
        XRAY_ZIP_NAME="Xray-${OS}-${XRAY_SUFFIX}.zip"
    fi
    local CACHE_ZIP_PATH="../../${CACHE_DIR}/${XRAY_ZIP_NAME}"
    
    # Download geo files from cache or from internet
    local GEO_IP_CACHE="../../${CACHE_DIR}/geoip.dat"
    local GEO_SITE_CACHE="../../${CACHE_DIR}/geosite.dat"
    
    # Download appropriate Xray binary or use cached version
    echo "Checking for Xray for $OS/$ARCH..."
    if [ -f "$CACHE_ZIP_PATH" ]; then
        echo "Using cached Xray binary from $CACHE_ZIP_PATH"
        cp "$CACHE_ZIP_PATH" .
    else
        echo "Downloading Xray for $OS/$ARCH..."
        if [ "$OS" = "windows" ]; then
            wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-windows-64.zip
            # Save to cache
            cp Xray-windows-64.zip "$CACHE_ZIP_PATH"
        else
            wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-${OS}-${XRAY_SUFFIX}.zip
            # Save to cache
            cp Xray-${OS}-${XRAY_SUFFIX}.zip "$CACHE_ZIP_PATH"
        fi
    fi
    
    # Extract the Xray zip
    if [ "$OS" = "windows" ]; then
        unzip -q Xray-windows-64.zip
        rm -f Xray-windows-64.zip
    else
        unzip -q Xray-${OS}-${XRAY_SUFFIX}.zip
        rm -f Xray-${OS}-${XRAY_SUFFIX}.zip
    fi
    
    # Remove the default geo files that come with Xray
    rm -f geoip.dat geosite.dat
    
    # Download or use cached geo files
    if [ -f "$GEO_IP_CACHE" ]; then
        echo "Using cached geoip.dat"
        cp "$GEO_IP_CACHE" .
    else
        echo "Downloading geoip.dat..."
        wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
        # Save to cache
        cp geoip.dat "$GEO_IP_CACHE"
    fi
    
    if [ -f "$GEO_SITE_CACHE" ]; then
        echo "Using cached geosite.dat"
        cp "$GEO_SITE_CACHE" .
    else
        echo "Downloading geosite.dat..."
        wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
        # Save to cache
        cp geosite.dat "$GEO_SITE_CACHE"
    fi
    
    # Rename xray binary
    if [ "$OS" = "windows" ]; then
        mv xray.exe xray-windows-amd64.exe
    else
        mv xray xray-${OS}-${ARCH}
    fi
    
    # Return to root directory
    cd ../..
    
    # Create the archive
    echo "Creating archive for $OS/$ARCH..."
    if [ "$OS" = "windows" ]; then
        zip -q -r "${PKG_NAME}.zip" "x-ui"
    else
        tar -czf "${PKG_NAME}.tar.gz" "x-ui"
    fi
    
    # Move to version-specific release directory
    mv "${PKG_NAME}.${ARCHIVE_EXT}" "${RELEASE_DIR}/"
    
    # Also create a copy in the main releases directory (for backward compatibility)
    cp "${RELEASE_DIR}/${PKG_NAME}.${ARCHIVE_EXT}" "releases/"
    
    # Cleanup
    rm -rf "x-ui"
    rm -f xui-release*
    
    echo "Package for $OS/$ARCH completed: ${RELEASE_DIR}/${PKG_NAME}.${ARCHIVE_EXT}"
}

# Build for Linux (amd64)
build_and_package "linux" "amd64" "64"

# Build for Linux (arm64)
build_and_package "linux" "arm64" "arm64-v8a"

# Build for Windows (amd64)
build_and_package "windows" "amd64" "64"

# Create a VERSION file in the release directory
echo "$VERSION" > "${RELEASE_DIR}/VERSION"

# Create a checksum file for all files in the release directory
echo "Creating checksums..."
cd "${RELEASE_DIR}"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum * > SHA256SUMS
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 * > SHA256SUMS
fi
cd ../..

echo "All packages created successfully in the 'releases' directory"
echo "Version-specific packages are available in: ${RELEASE_DIR}" 