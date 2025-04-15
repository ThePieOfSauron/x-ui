# GitHub Release Upload Script

# Configuration
$repo = "YOUR_USERNAME/x-ui"  # Replace with your actual repository
$version = "0.3.3"
$token = Read-Host -Prompt "Enter your GitHub personal access token"

# Create release
$releaseData = @{
    tag_name = $version
    name = "x-ui v$version"
    body = "Release version $version with improvements and bug fixes"
    draft = $true
    prerelease = $false
} | ConvertTo-Json

Write-Host "Creating release $version..." -ForegroundColor Yellow
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases" -Method Post -Headers @{
    Authorization = "token $token"
    "Content-Type" = "application/json"
} -Body $releaseData

$uploadUrl = $release.upload_url -replace "{.*}$", ""
Write-Host "Release created! Starting file uploads..." -ForegroundColor Green

# Upload assets
$files = @(
    "releases\x-ui-linux-amd64-$version.tar.gz",
    "releases\x-ui-linux-arm64-$version.tar.gz",
    "releases\x-ui-windows-amd64-$version.zip"
)

foreach ($file in $files) {
    $fileName = Split-Path $file -Leaf
    Write-Host "Uploading $fileName..." -ForegroundColor Yellow
    
    $contentType = "application/gzip"
    if ($fileName -like "*.zip") {
        $contentType = "application/zip"
    }
    
    Invoke-RestMethod -Uri "$uploadUrl`?name=$fileName" -Method Post -Headers @{
        Authorization = "token $token"
        "Content-Type" = $contentType
    } -InFile $file
    
    Write-Host "Uploaded $fileName successfully!" -ForegroundColor Green
}

Write-Host "All files uploaded successfully!" -ForegroundColor Green
Write-Host "Visit https://github.com/$repo/releases to publish your release." -ForegroundColor Cyan 