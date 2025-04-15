#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${yellow}X-UI Mock Installation Script${plain}"
echo -e "${yellow}===========================${plain}"
echo ""

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Error: This script must be run as root${plain}"
    exit 1
else
    echo -e "${green}[1/8] Running as root${plain}"
fi

# Determine architecture
arch=$(arch)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${yellow}Warning: Architecture not detected, using default: ${arch}${plain}"
fi
echo -e "${green}[2/8] Architecture detected: ${arch}${plain}"

# Check OS type
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
echo -e "${green}[3/8] OS detected: ${release}${plain}"

# Mock dependency installation
echo -e "${green}[4/8] Installing dependencies (mock)...${plain}"
sleep 1
echo -e "${green}  ✓ Dependencies installed${plain}"

# Mock download of latest version
echo -e "${green}[5/8] Fetching latest version (mock)...${plain}"
sleep 1
echo -e "${green}  ✓ Latest version: v0.3.2${plain}"

# Mock download of release file
echo -e "${green}[6/8] Downloading release files (mock)...${plain}"
sleep 2
echo -e "${green}  ✓ Release files downloaded${plain}"

# Mock extraction and setup
echo -e "${green}[7/8] Extracting and setting up (mock)...${plain}"
sleep 2
echo -e "${green}  ✓ Files extracted and permissions set${plain}"
echo -e "${green}  ✓ Service files configured${plain}"

# Mock configuration
echo -e "${green}[8/8] Configuring x-ui (mock)...${plain}"
echo -e "${yellow}For security reasons, you need to set a username, password, and port after installation${plain}"
read -p "Continue? [y/n]: " config_confirm
if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
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
    
    if [[ x"${config_lang}" == x"en_US" ]]; then
        read -p "Please set your account username: " config_account
        echo -e "${yellow}Your account username will be set to: ${config_account}${plain}"
        read -p "Please set your account password: " config_password
        echo -e "${yellow}Your account password will be set to: ${config_password}${plain}"
        read -p "Please set the panel access port: " config_port
        echo -e "${yellow}Your panel access port will be set to: ${config_port}${plain}"
        echo -e "${yellow}Confirming settings, applying changes...${plain}"
    else
        read -p "请设置您的账户名: " config_account
        echo -e "${yellow}您的账户名将设定为: ${config_account}${plain}"
        read -p "请设置您的账户密码: " config_password
        echo -e "${yellow}您的账户密码将设定为: ${config_password}${plain}"
        read -p "请设置面板访问端口: " config_port
        echo -e "${yellow}您的面板访问端口将设定为: ${config_port}${plain}"
        echo -e "${yellow}确认设定, 设定中...${plain}"
    fi
    
    sleep 1
    echo -e "${green}  ✓ Account and password set (mock)${plain}"
    sleep 1
    echo -e "${green}  ✓ Panel port set (mock)${plain}"
    sleep 1
    echo -e "${green}  ✓ Language set (mock)${plain}"
else
    echo -e "${red}Cancelled. All settings will use default values. Please change them promptly after installation.${plain}"
fi

# Mock service startup
echo -e "${green}Starting x-ui service (mock)...${plain}"
sleep 2
echo -e "${green}x-ui v0.3.2 mock installation complete. The panel has been started.${plain}"
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
echo -e "This was a mock installation. No actual changes were made to your system."
echo -e "To perform the actual installation, run:"
echo -e "bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)" 