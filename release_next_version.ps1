# PowerShell script to run the release process through WSL Ubuntu-22.04

# Make the bash script executable first
Write-Host "Making release_linux_amd64.sh executable..."
wsl -d Ubuntu-22.04 chmod +x ./release_linux_amd64.sh

# Execute the release script in WSL Ubuntu-22.04
Write-Host "Running release script in WSL Ubuntu-22.04..."
wsl -d Ubuntu-22.04 ./release_linux_amd64.sh

Write-Host "Release process completed!" 