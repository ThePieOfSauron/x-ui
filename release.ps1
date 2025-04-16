# PowerShell script to run the comprehensive release process through WSL

# Make the bash script executable
Write-Host "Making release_next_version.sh executable..."
wsl -d Ubuntu-22.04 chmod +x ./release_next_version.sh

# Execute the release script in WSL
Write-Host "Running comprehensive release process in WSL..."
wsl -d Ubuntu-22.04 ./release_next_version.sh

Write-Host "Process completed. Check the output above for any errors or issues." 