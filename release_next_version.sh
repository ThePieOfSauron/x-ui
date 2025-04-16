#!/bin/bash

# Comprehensive script to build, release, and publish the next version of x-ui
# This script will:
# 1. Determine and increment the current version
# 2. Build the application for Linux AMD64
# 3. Create and package the release
# 4. Commit and tag version changes
# 5. Create a GitHub release and mark it as latest
# 6. Upload assets to the release

set -e

echo "===== X-UI RELEASE AUTOMATION ====="
echo "Starting comprehensive release process..."

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
    exit 1
fi

# Set Go proxy to bypass potential network restrictions
export GOPROXY=https://goproxy.io,direct

# Create version-specific release directory
RELEASE_DIR="./releases/v${NEW_VERSION}"
mkdir -p "$RELEASE_DIR"
echo "Created release directory: $RELEASE_DIR"

# Build for Linux (amd64)
echo "Building x-ui for Linux (amd64)..."
GOOS=linux GOARCH=amd64 go build -o "./bin/x-ui-linux-amd64"
chmod +x "./bin/x-ui-linux-amd64"
echo "Build completed."

# Create archive
ARCHIVE_NAME="x-ui-linux-amd64-${NEW_VERSION}.tar.gz"
echo "Creating archive: $ARCHIVE_NAME..."
(cd ./bin && tar -czf "../${RELEASE_DIR}/${ARCHIVE_NAME}" "x-ui-linux-amd64")
echo "Archive created."

# Create SHA256SUMS
echo "Creating checksums..."
(cd "${RELEASE_DIR}" && sha256sum * > SHA256SUMS)
echo "Checksums created."

# Configure Git if needed
if ! git config user.email >/dev/null 2>&1; then
    echo "Setting up Git user information..."
    git config --global user.email "x-ui-release@github.com"
    git config --global user.name "X-UI Release Bot"
fi

# Commit version changes
echo "Committing version changes..."
git add main.go config/version 2>/dev/null || true
git commit -m "Bump version to ${NEW_VERSION}"
echo "Changes committed."

# Tag the new version
echo "Creating Git tag v${NEW_VERSION}..."
git tag "v${NEW_VERSION}"
echo "Tag created."

# Push changes to remote
echo "Pushing changes to remote repository..."
git push origin main
git push origin "v${NEW_VERSION}"
echo "Changes pushed."

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI not found. Please install it first."
    echo "Visit: https://cli.github.com/"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    echo "Error: You are not logged into GitHub. Please run 'gh auth login' first."
    exit 1
fi

# Create GitHub release
echo "Creating GitHub release v${NEW_VERSION}..."
gh release create "v${NEW_VERSION}" \
    --title "X-UI v${NEW_VERSION}" \
    --notes "Release version ${NEW_VERSION}" \
    --latest
echo "GitHub release created."

# Upload files to release
echo "Uploading files to GitHub release..."
gh release upload "v${NEW_VERSION}" "${RELEASE_DIR}/${ARCHIVE_NAME}" "${RELEASE_DIR}/SHA256SUMS" --clobber
echo "Files uploaded."

echo "===== RELEASE PROCESS COMPLETED ====="
echo "Version ${NEW_VERSION} has been built, packaged, and published as the latest release."
echo "Release URL: https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')/releases/tag/v${NEW_VERSION}" 