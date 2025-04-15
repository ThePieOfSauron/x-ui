# Testing the X-UI Installer

This directory contains scripts for testing the x-ui installer before actually deploying it to a production environment.

## Available Test Scripts

### 1. check_installer.sh

This script verifies that all the necessary components for the installer are available and accessible. It checks:

- System requirements and architecture
- GitHub connectivity and API rate limits
- Latest release information
- Availability of installation files
- Required system dependencies

**Usage:**
```bash
# Run as root
sudo bash check_installer.sh
```

### 2. mock_install.sh

This script simulates the installation process without actually making changes to your system. It's useful for:

- Testing the user interface and flow of the installer
- Checking the language selection process
- Testing the user input collection for credentials and port settings
- Walking through the entire installation process safely

**Usage:**
```bash
# Run as root
sudo bash mock_install.sh
```

## Testing Strategy

1. **Preliminary Testing**: Run `check_installer.sh` first to ensure all resources are available.
2. **UI and Flow Testing**: Run `mock_install.sh` to walk through the installation process in a safe manner.
3. **Real Installation Testing**: Only after both tests pass successfully, proceed with the actual installation in a test environment.

## Notes

- These scripts check against the vaxilu repository as configured in the installer.
- The actual installation script was modified to use vaxilu's binaries while maintaining ThePieOfSauron branding in the UI.
- GitHub API has rate limits. If you encounter errors about rate limits, wait for an hour before trying again.

## Running in a Test Environment

For testing the actual installation, consider using a disposable environment like a Docker container or a virtual machine. Example using Docker:

```bash
# Pull a suitable image
docker pull ubuntu:20.04

# Run container with privileged mode (needed for systemd)
docker run --privileged -it ubuntu:20.04 /bin/bash

# Install basic tools
apt update && apt install -y curl wget sudo

# Run the installer check
curl -O https://raw.githubusercontent.com/ThePieOfSauron/x-ui/main/check_installer.sh
chmod +x check_installer.sh
sudo bash check_installer.sh

# If the check passes, try the mock installation
curl -O https://raw.githubusercontent.com/ThePieOfSauron/x-ui/main/mock_install.sh
chmod +x mock_install.sh
sudo bash mock_install.sh

# Finally, if all tests pass, run the actual installer
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
``` 