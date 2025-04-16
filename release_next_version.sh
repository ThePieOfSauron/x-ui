#!/bin/bash

# Comprehensive script to build, release, and publish the next version of x-ui
# This script will:
# 1. Determine and increment the current version
# 2. Build the application for Linux AMD64
# 3. Create and package the release
# 4. Commit and tag version changes
# 5. Create a GitHub release and mark it as latest
# 6. Upload assets to the release
#
# Usage:
#   ./release_next_version.sh [options] [version]
#
# Options:
#   -f, --force    Force rebuild even if version hasn't changed
#
# If version is provided, it will be used instead of auto-incrementing.
# Example: ./release_next_version.sh 1.2.3
# Example: ./release_next_version.sh --force 0.3.6

set -e

# Parse command line options
FORCE=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            VERSION="$1"
            shift
            ;;
    esac
done

echo "===== X-UI RELEASE AUTOMATION ====="
echo "Starting comprehensive release process..."

# Get the current version
CURRENT_VERSION=$(grep -Po "version\s+=\s+\"\K[^\"]*" main.go 2>/dev/null || cat config/version 2>/dev/null || echo "0.0.0")
echo "Current version: $CURRENT_VERSION"

# Determine the new version
if [ -n "$VERSION" ]; then
    # Use the provided version
    NEW_VERSION="$VERSION"
    echo "Using provided version: $NEW_VERSION"
else
    # Parse the version components and auto-increment
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
    NEW_PATCH=$((PATCH + 1))
    NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"
    echo "Next version will be: $NEW_VERSION"
fi

# Check if the version already exists as a GitHub release
if command -v gh &> /dev/null; then
    if gh release view "v${NEW_VERSION}" &>/dev/null; then
        echo "ERROR: Version v${NEW_VERSION} already exists as a GitHub release."
        echo "Please use a higher version number. Release process aborted."
        exit 1
    fi
fi

# Don't proceed if the current version equals the new version
if [ "$CURRENT_VERSION" = "$NEW_VERSION" ] && [ "$FORCE" = false ]; then
    echo "ERROR: Current version is already $NEW_VERSION. Use a higher version number."
    exit 1
fi

# Update version in main.go or config/version
VERSION_FILE=""
if grep -q "version = \"" main.go 2>/dev/null; then
    sed -i "s/version = \"${CURRENT_VERSION}\"/version = \"${NEW_VERSION}\"/" main.go
    echo "Updated version in main.go"
    VERSION_FILE="main.go"
elif [ -f "config/version" ]; then
    echo "$NEW_VERSION" > config/version
    echo "Updated version in config/version"
    VERSION_FILE="config/version"
else
    echo "ERROR: Could not update version in source files"
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

# Configure git to handle line ending issues
git config --global core.autocrlf false

# Commit version changes - only the specific file, not everything
echo "Committing version changes..."
if [ -n "$VERSION_FILE" ]; then
    # Only stage the version file
    git add "$VERSION_FILE" -f
    
    # Skip the commit if there are no changes to the version file
    if git diff --staged --quiet; then
        echo "No changes to commit. The version might already be updated."
    else
        git commit -m "Bump version to ${NEW_VERSION}"
        echo "Changes committed."
    fi
else
    echo "WARNING: No version file to commit."
fi

# Check if the tag already exists
if git tag -l "v${NEW_VERSION}" | grep -q "v${NEW_VERSION}"; then
    echo "ERROR: Git tag v${NEW_VERSION} already exists locally."
    echo "Please use a higher version number. Release process aborted."
    exit 1
fi

# Tag the new version
echo "Creating Git tag v${NEW_VERSION}..."
git tag "v${NEW_VERSION}"
echo "Tag created."

# Push changes to remote, but only if the commit was successful
echo "Pushing changes to remote repository..."
if git rev-parse --verify HEAD >/dev/null 2>&1; then
    # Only push main if we had a commit to push
    if ! git diff --staged --quiet; then
        git push origin main || (echo "ERROR: Failed to push to main. Release process aborted." && exit 1)
    fi
    
    # Push tag
    git push origin "v${NEW_VERSION}" || (echo "ERROR: Failed to push tag. Release process aborted." && exit 1)
    echo "Changes pushed."
else
    echo "ERROR: No commits to push. Release process aborted."
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI not found. Please install it first."
    echo "Visit: https://cli.github.com/"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    echo "ERROR: You are not logged into GitHub. Please run 'gh auth login' first."
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