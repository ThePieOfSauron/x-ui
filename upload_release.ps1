# GitHub Release Upload Script

# Configuration
$repo = "YOUR_USERNAME/x-ui"  # Replace with your actual repository
$version = "0.3.5"
$token = Read-Host -Prompt "Enter your GitHub personal access token"

# Create release
$releaseData = @{
    tag_name = "v$version"
    name = "x-ui v$version"
    body = "Release version $version with improvements and bug fixes"
    draft = $true
    prerelease = $false
} | ConvertTo-Json

Write-Host "Creating release v$version..." -ForegroundColor Yellow
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Method Post -Headers @{
    Authorization = "token $token"
    "Content-Type" = "application/json"
} -Body $releaseData

$uploadUrl = $release.upload_url -replace "{.*}$", ""
Write-Host "Release created! Starting file uploads..." -ForegroundColor Green

# Define version-specific release directory
$versionDir = "releases/v$version"

# Check if the version directory exists
if (-not (Test-Path $versionDir)) {
    Write-Host "Version-specific directory not found: $versionDir" -ForegroundColor Red
    Write-Host "Will try to use files from the main releases directory instead." -ForegroundColor Yellow
    $versionDir = "releases"
}

# Upload SHA256SUMS if it exists
$sha256SumsFile = "$versionDir/SHA256SUMS"
if (Test-Path $sha256SumsFile) {
    Write-Host "Uploading SHA256SUMS..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "$uploadUrl`?name=SHA256SUMS" -Method Post -Headers @{
        Authorization = "token $token"
        "Content-Type" = "text/plain"
    } -InFile $sha256SumsFile
    Write-Host "Uploaded SHA256SUMS successfully!" -ForegroundColor Green
}

# Upload assets
$filePatterns = @(
    "x-ui-linux-amd64-$version.tar.gz",
    "x-ui-linux-arm64-$version.tar.gz",
    "x-ui-windows-amd64-$version.zip"
)

foreach ($pattern in $filePatterns) {
    $filePath = "$versionDir/$pattern"
    
    # If file doesn't exist in version dir, try main releases dir
    if (-not (Test-Path $filePath)) {
        $filePath = "releases/$pattern"
        if (-not (Test-Path $filePath)) {
            Write-Host "File not found: $pattern" -ForegroundColor Red
            continue
        }
    }
    
    $fileName = Split-Path $filePath -Leaf
    Write-Host "Uploading $fileName..." -ForegroundColor Yellow
    
    $contentType = "application/gzip"
    if ($fileName -like "*.zip") {
        $contentType = "application/zip"
    }
    
    Invoke-RestMethod -Uri "$uploadUrl`?name=$fileName" -Method Post -Headers @{
        Authorization = "token $token"
        "Content-Type" = $contentType
    } -InFile $filePath
    
    Write-Host "Uploaded $fileName successfully!" -ForegroundColor Green
}

Write-Host "All files uploaded successfully!" -ForegroundColor Green
Write-Host "Visit https://github.com/$repo/releases to publish your release." -ForegroundColor Cyan 