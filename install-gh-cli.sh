#!/bin/bash

# Script to install GitHub CLI on Linux
# This is useful for setting up your environment for releases

set -e

echo "Installing GitHub CLI for Linux..."

# Check if we're running as root (needed for system-wide installation)
if [ "$EUID" -ne 0 ]; then
  echo "This script requires root privileges for installation."
  echo "Please run with sudo: sudo $0"
  exit 1
fi

# Function to detect Linux distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$DISTRIB_ID
  elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
  elif [ -f /etc/redhat-release ]; then
    DISTRO="rhel"
  else
    DISTRO="unknown"
  fi
  
  echo "Detected distribution: $DISTRO"
}

# Install GitHub CLI based on the distribution
install_gh() {
  case "$DISTRO" in
    ubuntu|debian|pop|mint|kali)
      echo "Installing for Debian/Ubuntu-based system..."
      type -p curl >/dev/null || apt-get install curl -y
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
      && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && apt-get update \
      && apt-get install gh -y
      ;;
      
    fedora|rhel|centos|rocky|alma)
      echo "Installing for RHEL/Fedora-based system..."
      dnf install -y 'dnf-command(config-manager)'
      dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      dnf install -y gh
      ;;
      
    opensuse|suse)
      echo "Installing for openSUSE-based system..."
      zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
      zypper ref
      zypper install -y gh
      ;;
      
    arch|manjaro)
      echo "Installing for Arch-based system..."
      pacman -S github-cli --noconfirm
      ;;
      
    *)
      echo "Unsupported distribution: $DISTRO"
      echo "Installing from binary..."
      install_from_binary
      ;;
  esac
}

# Fallback installation from binary if package manager installation fails
install_from_binary() {
  echo "Installing GitHub CLI from binary..."
  
  # Determine architecture
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64)
      ARCH="amd64"
      ;;
    aarch64|arm64)
      ARCH="arm64"
      ;;
    *)
      echo "Unsupported architecture: $ARCH"
      exit 1
      ;;
  esac
  
  # Create temporary directory
  TMP_DIR=$(mktemp -d)
  cd "$TMP_DIR"
  
  # Get latest release
  echo "Downloading latest GitHub CLI release..."
  LATEST_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep -Po '"tag_name": "v\K[^"]*')
  DOWNLOAD_URL="https://github.com/cli/cli/releases/download/v${LATEST_VERSION}/gh_${LATEST_VERSION}_linux_${ARCH}.tar.gz"
  
  # Download and extract
  curl -LO "$DOWNLOAD_URL"
  tar xf "gh_${LATEST_VERSION}_linux_${ARCH}.tar.gz"
  
  # Install
  cd "gh_${LATEST_VERSION}_linux_${ARCH}"
  cp -r bin/gh /usr/local/bin/
  cp -r share/man/man1/* /usr/local/share/man/man1/
  
  # Cleanup
  cd ..
  rm -rf "$TMP_DIR"
}

# Main script execution
detect_distro
install_gh

# Verify installation
if command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI installed successfully: $(gh --version)"
  echo "To authenticate with GitHub, run: gh auth login"
else
  echo "GitHub CLI installation failed."
  exit 1
fi