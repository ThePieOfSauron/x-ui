#!/bin/bash

# GitHub CLI-based Release Script for x-ui
# This script creates a release and uploads assets using GitHub CLI

set -e

# Configuration
VERSION=$(cat config/version 2>/dev/null || echo "0.3.3")
TAG_NAME="v${VERSION}"
RELEASE_NAME="X-UI v${VERSION}"
NOTES="Release version ${VERSION} with improvements and bug fixes"

# Ensure GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not found. Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is logged in
if ! gh auth status &> /dev/null; then
    echo "You are not logged into GitHub. Please run 'gh auth login' first."
    exit 1
fi

# Define version-specific release directory
VERSION_DIR="releases/v${VERSION}"

# Verify the release directory exists
if [ ! -d "$VERSION_DIR" ]; then
    echo "Version directory not found: $VERSION_DIR"
    echo "Did you run 'package.sh' to build the release packages?"
    exit 1
fi

# Create a GitHub release
echo "Creating GitHub release ${TAG_NAME}..."
gh release create "$TAG_NAME" \
    --title "$RELEASE_NAME" \
    --notes "$NOTES" \
    --draft

# Upload SHA256SUMS if it exists
SHA256SUMS_FILE="${VERSION_DIR}/SHA256SUMS"
if [ -f "${SHA256SUMS_FILE}" ]; then
    echo "Uploading SHA256SUMS..."
    gh release upload "$TAG_NAME" "${SHA256SUMS_FILE}"
fi

# Upload release assets
ASSET_PATTERNS=(
    "${VERSION_DIR}/x-ui-linux-amd64-${VERSION}.tar.gz"
    "${VERSION_DIR}/x-ui-linux-arm64-${VERSION}.tar.gz"
    "${VERSION_DIR}/x-ui-windows-amd64-${VERSION}.zip"
)

for ASSET_PATH in "${ASSET_PATTERNS[@]}"; do
    if [ -f "$ASSET_PATH" ]; then
        ASSET_NAME=$(basename "$ASSET_PATH")
        echo "Uploading ${ASSET_NAME}..."
        gh release upload "$TAG_NAME" "$ASSET_PATH"
    else
        echo "Asset not found: $ASSET_PATH"
    fi
done

echo "Release creation and asset upload complete!"
echo "View your release at: https://github.com/$(gh repo view --json nameWithOwner -q '.nameWithOwner')/releases/tag/${TAG_NAME}"
echo "Remember to publish it when ready by removing the draft status." 