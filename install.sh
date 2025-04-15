#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} You must use root user to run this script!\n" && exit 1

# check os
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
    echo -e "${red}System version not detected, please contact script author!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Failed to detect architecture, using default: ${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This software does not support 32-bit systems (x86), please use 64-bit systems (x86_64). If detection is incorrect, please contact the author"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or higher!${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar jq -y
    else
        apt install wget curl tar jq -y
    fi
}

# This function will be called after x-ui is installed for security setup
config_after_install() {
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
        
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        
        if [[ x"${config_lang}" == x"en_US" ]]; then
            echo -e "${yellow}Account and password set successfully${plain}"
        else
            echo -e "${yellow}账户密码设定完成${plain}"
        fi
        
        /usr/local/x-ui/x-ui setting -port ${config_port}
        
        if [[ x"${config_lang}" == x"en_US" ]]; then
            echo -e "${yellow}Panel port set successfully${plain}"
        else
            echo -e "${yellow}面板端口设定完成${plain}"
        fi
        
        # Set language
        /usr/local/x-ui/x-ui setting -language ${config_lang}
        
        if [[ x"${config_lang}" == x"en_US" ]]; then
            echo -e "${yellow}Language set successfully${plain}"
        else
            echo -e "${yellow}语言设置完成${plain}"
        fi
    else
        echo -e "${red}Cancelled. All settings will use default values. Please change them promptly after installation.${plain}"
        # Set English as default language even if cancelled
        /usr/local/x-ui/x-ui setting -language "en_US"
    fi
}

# Get available versions from GitHub
get_versions() {
    echo -e "${green}Fetching available x-ui versions...${plain}"
    
    # Get all releases from GitHub API
    all_releases=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases" | jq -r '.[].tag_name' | grep -v 'beta\|alpha\|rc' | sed 's/^v//')
    
    if [[ -z "$all_releases" ]]; then
        echo -e "${red}Failed to fetch release list from GitHub. Please check your network or try again later.${plain}"
        exit 1
    fi
    
    # Sort versions in descending order and get the latest 3
    latest_versions=($(echo "$all_releases" | sort -rV | head -n 3))
    
    if [[ ${#latest_versions[@]} -eq 0 ]]; then
        echo -e "${red}No versions found. Please check the repository.${plain}"
        exit 1
    fi
    
    echo -e "${yellow}Available versions:${plain}"
    for i in "${!latest_versions[@]}"; do
        echo -e "$((i+1)). ${green}${latest_versions[$i]}${plain} ($([ $i -eq 0 ] && echo 'latest' || echo 'older'))"
    done
}

# Choose version to install
choose_version() {
    echo ""
    read -p "Select a version to install (1-${#latest_versions[@]}, default 1): " version_number
    
    if [[ -z "$version_number" ]]; then
        version_number=1
    fi
    
    if ! [[ "$version_number" =~ ^[0-9]+$ ]] || [[ "$version_number" -lt 1 ]] || [[ "$version_number" -gt ${#latest_versions[@]} ]]; then
        echo -e "${red}Invalid input. Using the latest version (1).${plain}"
        version_number=1
    fi
    
    selected_version="${latest_versions[$((version_number-1))]}"
    echo -e "${green}Selected version: ${selected_version}${plain}"
}

# Check for updates and update binaries only if a newer version is available
check_update_binaries() {
    echo -e "${green}Checking for updates...${plain}"
    
    # Get the current installed version
    if [ -f /usr/local/x-ui/x-ui ]; then
        current_version=$(/usr/local/x-ui/x-ui -version 2>/dev/null | awk '{print $2}' | sed 's/^v//')
        echo -e "${yellow}Current installed version: ${current_version}${plain}"
    else
        echo -e "${red}x-ui is not installed. Please run the installation first.${plain}"
        return 1
    fi

    # Get all releases from GitHub API
    all_releases=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases" | jq -r '.[].tag_name' | grep -v 'beta\|alpha\|rc' | sed 's/^v//')
    
    if [[ -z "$all_releases" ]]; then
        echo -e "${red}Failed to fetch release list from GitHub. Please check your network or try again later.${plain}"
        return 1
    fi
    
    # Sort versions in descending order
    latest_versions=($(echo "$all_releases" | sort -rV))
    
    if [[ ${#latest_versions[@]} -eq 0 ]]; then
        echo -e "${red}No versions found. Please check the repository.${plain}"
        return 1
    fi
    
    latest_version="${latest_versions[0]}"
    
    # Compare versions
    if [[ $(echo "$latest_version" | sed 's/\.//g') -le $(echo "$current_version" | sed 's/\.//g') ]]; then
        echo -e "${green}You are already running the latest version (${current_version}).${plain}"
        return 0
    fi
    
    echo -e "${yellow}New version available: ${latest_version}${plain}"
    read -p "Do you want to update the binaries to version ${latest_version}? [y/n]: " update_confirm
    
    if [[ x"${update_confirm}" != x"y" && x"${update_confirm}" != x"Y" ]]; then
        echo -e "${red}Update canceled.${plain}"
        return 0
    fi
    
    # Performing the update
    echo -e "${green}Updating binaries to version ${latest_version}...${plain}"
    
    # Save current working directory
    local orig_dir=$(pwd)
    cd /usr/local/
    
    # Stop x-ui service temporarily
    systemctl stop x-ui
    
    # Download and extract the new version
    version_tag="v${latest_version}"
    
    echo -e "Downloading x-ui ${version_tag} binaries..."
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/ThePieOfSauron/x-ui/releases/download/${version_tag}/x-ui-linux-${arch}-${latest_version}.tar.gz
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to download x-ui ${version_tag}. Please ensure this version exists.${plain}"
        systemctl start x-ui
        cd "$orig_dir"
        return 1
    fi
    
    # Create a temporary directory for extraction
    mkdir -p /usr/local/x-ui-tmp
    tar zxvf x-ui-linux-${arch}.tar.gz -C /usr/local/x-ui-tmp
    
    # Back up current configuration files
    echo -e "${yellow}Backing up configuration...${plain}"
    cp -f /usr/local/x-ui/db/x-ui.db /usr/local/x-ui-tmp/db/ 2>/dev/null || mkdir -p /usr/local/x-ui-tmp/db/
    
    # Copy only the binary files and preserve configuration
    echo -e "${yellow}Updating binaries...${plain}"
    cp -f /usr/local/x-ui-tmp/x-ui /usr/local/x-ui/
    cp -f /usr/local/x-ui-tmp/bin/xray-linux-${arch} /usr/local/x-ui/bin/
    
    # Set executable permissions
    chmod +x /usr/local/x-ui/x-ui
    chmod +x /usr/local/x-ui/bin/xray-linux-${arch}
    
    # Clean up temporary files
    rm -rf /usr/local/x-ui-tmp
    rm -f /usr/local/x-ui-linux-${arch}.tar.gz
    
    # Start the service again
    systemctl start x-ui
    
    echo -e "${green}Update complete! x-ui binaries have been updated to version ${latest_version} while preserving your configuration.${plain}"
    cd "$orig_dir"
    
    return 0
}

install_x-ui() {
    systemctl stop x-ui 2>/dev/null
    cd /usr/local/

    if [ $# == 0 ]; then
        # Get available versions and let user choose
        get_versions
        choose_version
        version_tag="v${selected_version}"
    else
        # Manual version specified from command line
        version_tag="v$1"
        selected_version="$1"
        echo -e "Using specified version: ${version_tag}"
    fi

    echo -e "Starting installation of x-ui ${version_tag}"
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/ThePieOfSauron/x-ui/releases/download/${version_tag}/x-ui-linux-${arch}-${selected_version}.tar.gz
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to download x-ui ${version_tag}. Please ensure this version exists.${plain}"
        exit 1
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/ThePieOfSauron/x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${version_tag}${plain} installation complete. The panel has been started."
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
    echo -e "x-ui check-update - Check for updates and update binaries only"
    echo -e "----------------------------------------------"
}

# Parse command line arguments
if [ $# -gt 0 ]; then
    case $1 in
        "install")
            install_base
            if [ $# -gt 1 ]; then
                install_x-ui $2
            else
                install_x-ui
            fi
            ;;
        "check-update")
            install_base
            check_update_binaries
            ;;
        *)
            echo -e "${red}Unknown command: $1${plain}"
            echo "Usage: $0 [install/check-update] [version]"
            exit 1
            ;;
    esac
else
    # Default behavior - check for existing installation and suggest update if available
    echo -e "${green}Checking for existing installation...${plain}"
    install_base
    
    if [ -f /usr/local/x-ui/x-ui ]; then
        current_version=$(/usr/local/x-ui/x-ui -version 2>/dev/null | awk '{print $2}' | sed 's/^v//')
        if [ -n "$current_version" ]; then
            echo -e "${yellow}Found existing x-ui installation version: ${current_version}${plain}"
            
            # Check for newer version
            all_releases=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases" | jq -r '.[].tag_name' | grep -v 'beta\|alpha\|rc' | sed 's/^v//')
            if [[ -n "$all_releases" ]]; then
                latest_version=$(echo "$all_releases" | sort -rV | head -n 1)
                
                if [[ $(echo "$latest_version" | sed 's/\.//g') -gt $(echo "$current_version" | sed 's/\.//g') ]]; then
                    echo -e "${green}New version available: ${latest_version}${plain}"
                    echo -e "${yellow}You can update just the binaries without changing your configuration.${plain}"
                    read -p "Do you want to update to the latest version? [y/n]: " update_confirm
                    
                    if [[ x"${update_confirm}" == x"y" || x"${update_confirm}" == x"Y" ]]; then
                        check_update_binaries
                        exit 0
                    else
                        echo -e "${yellow}Update skipped.${plain}"
                        read -p "Do you want to perform a fresh installation instead? [y/n]: " fresh_install
                        if [[ x"${fresh_install}" == x"y" || x"${fresh_install}" == x"Y" ]]; then
                            echo -e "${green}Starting fresh installation...${plain}"
                            install_x-ui
                        else
                            echo -e "${yellow}Installation canceled.${plain}"
                            exit 0
                        fi
                    fi
                else
                    echo -e "${green}You are already running the latest version.${plain}"
                    read -p "Do you want to perform a fresh installation anyway? [y/n]: " fresh_install
                    if [[ x"${fresh_install}" == x"y" || x"${fresh_install}" == x"Y" ]]; then
                        echo -e "${green}Starting fresh installation...${plain}"
                        install_x-ui
                    else
                        echo -e "${yellow}Installation canceled.${plain}"
                        exit 0
                    fi
                fi
            else
                echo -e "${red}Failed to check for updates. Proceeding with regular installation.${plain}"
                install_x-ui
            fi
        else
            echo -e "${yellow}Found existing x-ui installation but couldn't determine version.${plain}"
            read -p "Do you want to perform a fresh installation? [y/n]: " fresh_install
            if [[ x"${fresh_install}" == x"y" || x"${fresh_install}" == x"Y" ]]; then
                echo -e "${green}Starting fresh installation...${plain}"
                install_x-ui
            else
                echo -e "${yellow}Installation canceled.${plain}"
                exit 0
            fi
        fi
    else
        echo -e "${green}No existing installation found. Starting fresh installation...${plain}"
        install_x-ui
    fi
fi
