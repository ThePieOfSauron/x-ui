#!/bin/bash

# GitHub Release Upload Script

# Configuration - REPLACE THESE VALUES
REPO="YOUR_USERNAME/x-ui"
VERSION="0.3.5"

# Get GitHub token
echo "Enter your GitHub Personal Access Token:"
read -s TOKEN

# Create release
echo "Creating release v${VERSION}..."
JSON="{\"tag_name\":\"v${VERSION}\",\"name\":\"x-ui v${VERSION}\",\"body\":\"Release version ${VERSION} with improvements and bug fixes\",\"draft\":true,\"prerelease\":false}"

RESPONSE=$(curl -s -H "Authorization: token ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${JSON}" \
    "https://api.github.com/repos/${REPO}/releases")

# Extract upload URL from response
UPLOAD_URL=$(echo "${RESPONSE}" | grep -o '"upload_url": *"[^"]*' | sed 's/"upload_url": *"\([^{]*\){.*}/\1/')

if [ -z "${UPLOAD_URL}" ]; then
    echo "Error: Failed to create release or get upload URL."
    echo "Response: ${RESPONSE}"
    exit 1
fi

echo "Release created! Starting file uploads..."

# Define version-specific release directory
VERSION_DIR="releases/v${VERSION}"

# Check if the version directory exists
if [ ! -d "${VERSION_DIR}" ]; then
    echo "Version-specific directory not found: ${VERSION_DIR}"
    echo "Will try to use files from the main releases directory instead."
    VERSION_DIR="releases"
fi

# Upload SHA256SUMS if it exists
SHA256SUMS_FILE="${VERSION_DIR}/SHA256SUMS"
if [ -f "${SHA256SUMS_FILE}" ]; then
    echo "Uploading SHA256SUMS..."
    curl -s -H "Authorization: token ${TOKEN}" \
        -H "Content-Type: text/plain" \
        --data-binary @"${SHA256SUMS_FILE}" \
        "${UPLOAD_URL}?name=SHA256SUMS"
    echo "Uploaded SHA256SUMS successfully!"
fi

# Upload assets - file patterns to look for
FILE_PATTERNS=(
    "x-ui-linux-amd64-${VERSION}.tar.gz"
    "x-ui-linux-arm64-${VERSION}.tar.gz"
    "x-ui-windows-amd64-${VERSION}.zip"
)

for PATTERN in "${FILE_PATTERNS[@]}"; do
    FILE_PATH="${VERSION_DIR}/${PATTERN}"
    
    # If file doesn't exist in version dir, try main releases dir
    if [ ! -f "${FILE_PATH}" ]; then
        FILE_PATH="releases/${PATTERN}"
        if [ ! -f "${FILE_PATH}" ]; then
            echo "File not found: ${PATTERN}"
            continue
        fi
    fi
    
    FILENAME=$(basename "${FILE_PATH}")
    echo "Uploading ${FILENAME}..."
    
    CONTENT_TYPE="application/gzip"
    if [[ "${FILENAME}" == *.zip ]]; then
        CONTENT_TYPE="application/zip"
    fi
    
    curl -s -H "Authorization: token ${TOKEN}" \
        -H "Content-Type: ${CONTENT_TYPE}" \
        --data-binary @"${FILE_PATH}" \
        "${UPLOAD_URL}?name=${FILENAME}"
    
    echo "Uploaded ${FILENAME} successfully!"
done

echo "All files uploaded successfully!"
echo "Visit https://github.com/${REPO}/releases to publish your release." 