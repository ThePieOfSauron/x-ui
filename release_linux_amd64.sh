#!/bin/bash

# Script to build Linux (amd64) version of x-ui and release to GitHub with 'latest' flag
# Run this script from Windows using WSL Ubuntu-22.04

set -e

# Get the current version
CURRENT_VERSION=$(grep -Po "version\s+=\s+\"\K[^\"]*" main.go 2>/dev/null || cat config/version 2>/dev/null || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

# Parse the version components
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Increment the patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
echo "Next version will be: $NEW_VERSION"

# Update version in main.go or config/version
if grep -q "version = \"" main.go 2>/dev/null; then
    sed -i "s/version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" main.go
    echo "Updated version in main.go"
elif [ -f "config/version" ]; then
    echo "$NEW_VERSION" > config/version
    echo "Updated version in config/version"
else
    echo "Warning: Could not update version in source files"
fi

# Create version-specific release directory
RELEASE_DIR="./releases/v${NEW_VERSION}"
mkdir -p "$RELEASE_DIR"

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Build only for Linux (amd64)
echo "Building x-ui for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o "./bin/x-ui-linux-amd64"
chmod +x "./bin/x-ui-linux-amd64"

# Create archive
ARCHIVE_NAME="x-ui-linux-amd64-${NEW_VERSION}.tar.gz"
echo "Creating archive..."
(cd ./bin && tar -czf "../${RELEASE_DIR}/${ARCHIVE_NAME}" "x-ui-linux-amd64")

# Create SHA256SUMS
echo "Creating checksums..."
(cd "${RELEASE_DIR}" && sha256sum * > SHA256SUMS)

# Commit version changes
git add main.go config/version 2>/dev/null || true
git commit -m "Bump version to ${NEW_VERSION}"
git tag "v${NEW_VERSION}"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Please install it with: sudo apt install gh"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    echo "You are not logged into GitHub. Please run 'gh auth login' first."
    exit 1
fi

# Create GitHub release
echo "Creating GitHub release v${NEW_VERSION}..."
gh release create "v${NEW_VERSION}" \
    --title "X-UI v${NEW_VERSION}" \
    --notes "Release version ${NEW_VERSION}" \
    --latest

# Upload files
echo "Uploading files to GitHub release..."
gh release upload "v${NEW_VERSION}" "${RELEASE_DIR}/${ARCHIVE_NAME}" "${RELEASE_DIR}/SHA256SUMS"

# Push changes to remote
git push origin main
git push origin "v${NEW_VERSION}"

echo "Release v${NEW_VERSION} completed and published as latest on GitHub!"
echo "Linux amd64 binary is available at: ${RELEASE_DIR}/${ARCHIVE_NAME}" 