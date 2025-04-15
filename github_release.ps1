#!/usr/bin/env pwsh

# GitHub CLI-based Release Script for x-ui
# This script creates a release and uploads assets using GitHub CLI

# Configuration
$version = "0.3.3"  # Read from config/version
$tagName = "v$version"
$releaseName = "X-UI v$version"
$notes = "Release version $version with improvements and bug fixes"

# Ensure GitHub CLI is installed and authenticated
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "GitHub CLI not found. Please install it from: https://cli.github.com/" -ForegroundColor Red
    exit 1
}

# Check if user is logged in
$authStatus = gh auth status 2>&1
if ($authStatus -match "not logged") {
    Write-Host "You are not logged into GitHub. Please run 'gh auth login' first." -ForegroundColor Red
    exit 1
}

# Set the default repository if not already set
gh repo set-default ThePieOfSauron/x-ui

# Define version-specific release directory
$versionDir = "releases/v$version"

# Verify the release directory exists
if (-not (Test-Path $versionDir)) {
    Write-Host "Version directory not found: $versionDir" -ForegroundColor Red
    Write-Host "Did you run 'package.sh' to build the release packages?" -ForegroundColor Yellow
    exit 1
}

# Create a GitHub release
Write-Host "Creating GitHub release $tagName..." -ForegroundColor Green
gh release create $tagName `
    --title "$releaseName" `
    --notes "$notes" `
    --draft

# Upload SHA256SUMS if it exists
$sha256SumsFile = "$versionDir/SHA256SUMS"
if (Test-Path $sha256SumsFile) {
    Write-Host "Uploading SHA256SUMS..." -ForegroundColor Yellow
    gh release upload $tagName $sha256SumsFile
}

# Upload release assets
$assetPatterns = @(
    "$versionDir/x-ui-linux-amd64-$version.tar.gz",
    "$versionDir/x-ui-linux-arm64-$version.tar.gz",
    "$versionDir/x-ui-windows-amd64-$version.zip"
)

foreach ($assetPath in $assetPatterns) {
    if (Test-Path $assetPath) {
        $assetName = Split-Path $assetPath -Leaf
        Write-Host "Uploading $assetName..." -ForegroundColor Yellow
        gh release upload $tagName $assetPath
    } else {
        Write-Host "Asset not found: $assetPath" -ForegroundColor Red
    }
}

Write-Host "Release creation and asset upload complete!" -ForegroundColor Green
Write-Host "View your release at: https://github.com/ThePieOfSauron/x-ui/releases/tag/$tagName" -ForegroundColor Cyan
Write-Host "Remember to publish it when ready by removing the draft status." -ForegroundColor Yellow 