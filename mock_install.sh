#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# This script simulates the actual installation without making system changes
# Useful for testing the installer UI without actually installing anything

echo -e "${green}[1/8] Checking system requirements (mock)...${plain}"
sleep 1
echo -e "${green}  ✓ Running as root${plain}"
sleep 0.5

# Detect system
echo -e "${green}[2/8] Detecting system (mock)...${plain}"
sleep 1
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}× System version not detected${plain}"
    exit 1
fi
echo -e "${green}  ✓ Detected: ${release}${plain}"
sleep 0.5

# Detect architecture
echo -e "${green}[3/8] Detecting CPU architecture (mock)...${plain}"
sleep 1
arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
else
    arch="amd64"
    echo -e "${yellow}! Architecture not explicitly detected, defaulting to: ${arch}${plain}"
fi
echo -e "${green}  ✓ Architecture: ${arch}${plain}"
sleep 0.5

# Mock installing dependencies
echo -e "${green}[4/8] Installing dependencies (mock)...${plain}"
sleep 1
echo -e "${green}  ✓ Installed: wget, curl, tar, jq${plain}"
sleep 0.5

# Mock download of available versions
echo -e "${green}[5/8] Fetching available x-ui versions (mock)...${plain}"
sleep 1

# Display mock version options
echo -e "${yellow}Available versions:${plain}"
echo -e "1. ${green}0.3.3${plain} (latest)"
echo -e "2. ${green}0.3.2${plain} (older)"
echo -e "3. ${green}0.3.1${plain} (older)"

# Ask user to select version
echo ""
read -p "Select a version to install (1-3, default 1): " version_number

if [[ -z "$version_number" ]]; then
    version_number=1
fi

if ! [[ "$version_number" =~ ^[0-9]+$ ]] || [[ "$version_number" -lt 1 ]] || [[ "$version_number" -gt 3 ]]; then
    echo -e "${red}Invalid input. Using the latest version (1).${plain}"
    version_number=1
fi

case $version_number in
    1) selected_version="0.3.3" ;;
    2) selected_version="0.3.2" ;;
    3) selected_version="0.3.1" ;;
esac

echo -e "${green}  ✓ Selected version: ${selected_version}${plain}"
sleep 0.5

# Mock download
echo -e "${green}[6/8] Downloading x-ui v${selected_version} (mock)...${plain}"
sleep 2
echo -e "${green}  ✓ Downloaded: x-ui-linux-${arch}-${selected_version}.tar.gz${plain}"
sleep 0.5

# Mock installation
echo -e "${green}[7/8] Installing x-ui (mock)...${plain}"
sleep 2
echo -e "${green}  ✓ Extracted files${plain}"
sleep 0.5
echo -e "${green}  ✓ Set executable permissions${plain}"
sleep 0.5
echo -e "${green}  ✓ Installed systemd service${plain}"
sleep 0.5

# Mock configuration
echo -e "${green}[8/8] Configuring x-ui (mock)...${plain}"
sleep 1

# Language selection
echo -e "${yellow}Please select your preferred language:${plain}"
echo -e "1. English (default)"
echo -e "2. 简体中文 (Simplified Chinese)"
echo -e "3. 繁體中文 (Traditional Chinese)"
read -p "Please enter your choice [1-3] (default: 1): " config_language
case $config_language in
    2)
        config_lang="zh_Hans"
        echo -e "${yellow}Language set to: Simplified Chinese${plain}"
        ;;
    3)
        config_lang="zh_Hant"
        echo -e "${yellow}Language set to: Traditional Chinese${plain}"
        ;;
    *)
        config_lang="en_US"
        echo -e "${yellow}Language set to: English${plain}"
        ;;
esac

# Account setup
if [[ x"${config_lang}" == x"en_US" ]]; then
    read -p "Please set your account username: " config_account
    echo -e "${yellow}Your account username will be set to: ${config_account}${plain}"
    read -p "Please set your account password: " config_password
    echo -e "${yellow}Your account password will be set to: ${config_password}${plain}"
    read -p "Please set the panel access port: " config_port
    echo -e "${yellow}Your panel access port will be set to: ${config_port}${plain}"
else
    read -p "请设置您的账户名: " config_account
    echo -e "${yellow}您的账户名将设定为: ${config_account}${plain}"
    read -p "请设置您的账户密码: " config_password
    echo -e "${yellow}您的账户密码将设定为: ${config_password}${plain}"
    read -p "请设置面板访问端口: " config_port
    echo -e "${yellow}您的面板访问端口将设定为: ${config_port}${plain}"
fi

sleep 2
echo -e "${green}  ✓ Configuration completed${plain}"
sleep 0.5

# Mock summary
echo -e "${green}x-ui v${selected_version} installation completed successfully (mock)${plain}"
echo -e ""
echo -e "x-ui management script usage: "
echo -e "----------------------------------------------"
echo -e "x-ui              - Show management menu"
echo -e "x-ui start        - Start x-ui panel"
echo -e "x-ui stop         - Stop x-ui panel"
echo -e "x-ui restart      - Restart x-ui panel"
echo -e "x-ui status       - View x-ui status"
echo -e "x-ui enable       - Set x-ui to start on boot"
echo -e "x-ui disable      - Cancel x-ui auto-start"
echo -e "x-ui log          - View x-ui logs"
echo -e "x-ui v2-ui        - Migrate v2-ui account data to x-ui"
echo -e "x-ui update       - Update x-ui panel"
echo -e "x-ui install      - Install x-ui panel"
echo -e "x-ui uninstall    - Uninstall x-ui panel"
echo -e "----------------------------------------------"

echo -e ""
echo -e "${yellow}This was a mock installation. No actual changes were made to your system.${plain}" 