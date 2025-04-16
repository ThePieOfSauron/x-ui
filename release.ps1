# PowerShell script to run the comprehensive release process through WSL
# 
# Usage:
#   .\release.ps1 [-Version <version>]
#
# Parameters:
#   -Version    Optional specific version to use (must be higher than current)
#
# Examples:
#   .\release.ps1
#   .\release.ps1 -Version 1.2.3
#
# Note: This script will always increment the version number and
# will never update an already published version.

param (
    [string]$Version,
    [switch]$Force
)

# Execute the release script in WSL
Write-Host "Running comprehensive release process in WSL..."
if ($Version) {
    Write-Host "Using provided version: $Version"
}
if ($Force) {
    Write-Host "Force flag enabled: Will rebuild even if version hasn't changed"
}

# Prepare the bash command
$bashCommand = "cd /mnt/c/Sandbox/x-ui && chmod +x ./release_next_version.sh && ./release_next_version.sh"

# Add flags and parameters
if ($Force) {
    $bashCommand += " --force"
}
if ($Version) {
    $bashCommand += " $Version"
}

# Run the command in WSL
$result = wsl -d Ubuntu-22.04 bash -c $bashCommand
$exitCode = $LASTEXITCODE

# Display results and provide guidance
if ($exitCode -ne 0) {
    Write-Host "Release process failed with exit code: $exitCode" -ForegroundColor Red
    Write-Host "Please check the error messages above." -ForegroundColor Red
    
    # Check if the error was about an existing version
    if ($result -match "already exists as a GitHub release") {
        Write-Host "The version you specified already exists. Try a higher version number." -ForegroundColor Yellow
        
        # Get current version using a simpler approach
        $currentVersionCmd = "cd /mnt/c/Sandbox/x-ui && cat config/version 2>/dev/null"
        $currentVersion = wsl -d Ubuntu-22.04 bash -c $currentVersionCmd
        
        # Suggest next version
        if ($currentVersion -match "(\d+)\.(\d+)\.(\d+)") {
            $major = [int]$matches[1]
            $minor = [int]$matches[2]
            $patch = [int]$matches[3] + 1
            $suggestedVersion = "$major.$minor.$patch"
            Write-Host "Suggested next version: $suggestedVersion" -ForegroundColor Green
            Write-Host "Try running: .\release.ps1 -Version $suggestedVersion" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Release process completed successfully!" -ForegroundColor Green
}

exit $exitCode 