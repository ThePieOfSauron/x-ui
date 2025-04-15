#!/bin/bash

# GitHub Release Upload Script

# Configuration - REPLACE THESE VALUES
REPO="YOUR_USERNAME/x-ui"
VERSION="0.3.3"

# Get GitHub token
echo "Enter your GitHub Personal Access Token:"
read -s TOKEN

# Create release
echo "Creating release ${VERSION}..."
JSON="{\"tag_name\":\"${VERSION}\",\"name\":\"x-ui v${VERSION}\",\"body\":\"Release version ${VERSION} with improvements and bug fixes\",\"draft\":true,\"prerelease\":false}"

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

# Upload assets
FILES=(
    "releases/x-ui-linux-amd64-${VERSION}.tar.gz"
    "releases/x-ui-linux-arm64-${VERSION}.tar.gz"
    "releases/x-ui-windows-amd64-${VERSION}.zip"
)

for FILE in "${FILES[@]}"; do
    FILENAME=$(basename "${FILE}")
    echo "Uploading ${FILENAME}..."
    
    CONTENT_TYPE="application/gzip"
    if [[ "${FILENAME}" == *.zip ]]; then
        CONTENT_TYPE="application/zip"
    fi
    
    curl -s -H "Authorization: token ${TOKEN}" \
        -H "Content-Type: ${CONTENT_TYPE}" \
        --data-binary @"${FILE}" \
        "${UPLOAD_URL}?name=${FILENAME}"
    
    echo "Uploaded ${FILENAME} successfully!"
done

echo "All files uploaded successfully!"
echo "Visit https://github.com/${REPO}/releases to publish your release." 