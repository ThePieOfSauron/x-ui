#!/bin/bash

# Script Version
SCRIPT_VERSION="1.1.0" # Added version variable

# Display Script Version
echo -e "${green}x-ui Installer Script v${SCRIPT_VERSION}${plain}"

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

# This function specifically addresses binary issues that cause the 203/EXEC error
fix_binary_issues() {
    echo -e "${green}Checking for binary issues that may cause 203/EXEC errors...${plain}"
    
    # Check if x-ui directory exists
    if [ ! -d /usr/local/x-ui ]; then
        echo -e "${red}Error: x-ui directory not found in /usr/local/${plain}"
        echo -e "${yellow}This indicates the installation is incomplete or corrupted.${plain}"
        return 1
    fi
    
    # Check if binary exists
    if [ ! -f /usr/local/x-ui/x-ui ]; then
        echo -e "${red}Error: x-ui binary is missing!${plain}"
        echo -e "${yellow}This is the direct cause of the 203/EXEC error.${plain}"
        return 1
    fi
    
    # Check architecture compatibility
    local binary_arch=""
    if command -v file > /dev/null 2>&1; then
        binary_arch=$(file /usr/local/x-ui/x-ui | grep -o "x86-64\|aarch64\|arm64\|s390x")
        echo -e "${green}Detected binary architecture: ${binary_arch}${plain}"
        echo -e "${green}System architecture: ${arch}${plain}"
        
        # Compare architectures (simplified)
        local mismatch=false
        if [[ "$arch" == "amd64" && "$binary_arch" != *"x86-64"* ]]; then
            mismatch=true
        elif [[ "$arch" == "arm64" && ! ("$binary_arch" == *"aarch64"* || "$binary_arch" == *"arm64"*) ]]; then
            mismatch=true
        elif [[ "$arch" == "s390x" && "$binary_arch" != *"s390x"* ]]; then
            mismatch=true
        fi
        
        if [ "$mismatch" = true ]; then
            echo -e "${red}Architecture mismatch! The binary is not compatible with your system.${plain}"
            echo -e "${yellow}Would you like to download the correct binary for your architecture? [y/n]${plain}"
            read -p "" fix_arch
            if [[ x"${fix_arch}" == x"y" || x"${fix_arch}" == x"Y" ]]; then
                return 1 # Signal to download the correct version
            fi
        fi
    else
        echo -e "${yellow}Warning: 'file' command not found, cannot check binary architecture compatibility.${plain}"
    fi
    
    # Check binary permissions
    if [ ! -x /usr/local/x-ui/x-ui ]; then
        echo -e "${yellow}x-ui binary does not have executable permissions.${plain}"
        echo -e "${green}Setting executable permissions...${plain}"
        chmod +x /usr/local/x-ui/x-ui
        if [ $? -eq 0 ]; then
            echo -e "${green}Permissions fixed successfully.${plain}"
        else
            echo -e "${red}Failed to set executable permissions.${plain}"
            return 1
        fi
    else
        echo -e "${green}x-ui binary has correct executable permissions.${plain}"
    fi
    
    # Check for missing libraries
    echo -e "${green}Checking for missing libraries...${plain}"
    if command -v ldd > /dev/null 2>&1; then
        ldd_output=$(ldd /usr/local/x-ui/x-ui 2>&1)
        
        if echo "$ldd_output" | grep -q "not found"; then
            echo -e "${red}Missing libraries detected:${plain}"
            echo "$ldd_output" | grep "not found"
            echo -e "${yellow}Installing required libraries...${plain}"
            
            if [[ x"${release}" == x"centos" ]]; then
                yum install -y glibc glibc-devel
            else
                apt update
                apt install -y libc6 libc6-dev
            fi
            
            echo -e "${green}Libraries installed. Checking again...${plain}"
            ldd_output=$(ldd /usr/local/x-ui/x-ui 2>&1)
            if echo "$ldd_output" | grep -q "not found"; then
                echo -e "${red}Still missing libraries. May need manual intervention.${plain}"
            else
                echo -e "${green}All required libraries are now available.${plain}"
            fi
        else
            echo -e "${green}All required libraries are available.${plain}"
        fi
    else
        echo -e "${yellow}Warning: 'ldd' command not found, cannot check for missing libraries.${plain}"
    fi
    
    return 0
}

# This function troubleshoots common x-ui service issues
troubleshoot_service() {
    echo -e "${green}Starting x-ui service troubleshooting...${plain}"
    
    # Check if service file exists
    if [ ! -f /etc/systemd/system/x-ui.service ]; then
        echo -e "${red}Error: x-ui service file not found.${plain}"
        echo -e "${yellow}Attempting to recreate service file...${plain}"
        
        if [ -f /usr/local/x-ui/x-ui.service ]; then
            cp -f /usr/local/x-ui/x-ui.service /etc/systemd/system/
            systemctl daemon-reload
            echo -e "${green}Service file has been recreated.${plain}"
        else
            echo -e "${red}Cannot find service template. You may need to reinstall x-ui.${plain}"
            return 1
        fi
    fi
    
    # Check for binary issues (the most common cause of 203/EXEC error)
    if ! fix_binary_issues; then
        echo -e "${yellow}Binary issues detected. Would you like to reinstall x-ui? [y/n]${plain}"
        read -p "" reinstall_confirm
        if [[ x"${reinstall_confirm}" == x"y" || x"${reinstall_confirm}" == x"Y" ]]; then
            # Backup database if it exists
            if [ -f /usr/local/x-ui/db/x-ui.db ]; then
                echo -e "${green}Backing up your database...${plain}"
                mkdir -p /tmp/x-ui-backup
                cp /usr/local/x-ui/db/x-ui.db /tmp/x-ui-backup/
                echo -e "${green}Database backed up to /tmp/x-ui-backup/x-ui.db${plain}"
            fi
            
            install_x-ui
            
            # Restore database if backup exists
            if [ -f /tmp/x-ui-backup/x-ui.db ]; then
                echo -e "${green}Restoring your database...${plain}"
                cp /tmp/x-ui-backup/x-ui.db /usr/local/x-ui/db/
                echo -e "${green}Database restored.${plain}"
                systemctl restart x-ui
            fi
            
            return 0
        fi
    fi
    
    # Check Xray binary
    if [ ! -f /usr/local/x-ui/bin/xray-linux-${arch} ]; then
        echo -e "${red}Error: Xray binary not found!${plain}"
        echo -e "${yellow}This could prevent x-ui from running properly.${plain}"
        echo -e "${yellow}Would you like to reinstall? [y/n]${plain}"
        read -p "" reinstall_xray
        if [[ x"${reinstall_xray}" == x"y" || x"${reinstall_xray}" == x"Y" ]]; then
            install_x-ui
            return 0
        fi
    else
        # Check Xray permissions
        if [ ! -x /usr/local/x-ui/bin/xray-linux-${arch} ]; then
            echo -e "${yellow}Xray binary does not have executable permissions.${plain}"
            echo -e "${green}Setting executable permissions...${plain}"
            chmod +x /usr/local/x-ui/bin/xray-linux-${arch}
            echo -e "${green}Permissions fixed.${plain}"
        fi
    fi
    
    # Check SELinux issues
    if command -v getenforce > /dev/null 2>&1; then
        if [ "$(getenforce)" == "Enforcing" ]; then
            echo -e "${yellow}SELinux is enabled in enforcing mode, which might prevent execution.${plain}"
            echo -e "${yellow}Would you like to temporarily set SELinux to permissive mode? [y/n]${plain}"
            read -p "" selinux_fix
            if [[ x"${selinux_fix}" == x"y" || x"${selinux_fix}" == x"Y" ]]; then
                setenforce 0
                echo -e "${green}SELinux set to permissive mode.${plain}"
                echo -e "${yellow}To make this permanent, edit /etc/selinux/config and set SELINUX=permissive${plain}"
            fi
        fi
    fi
    
    # Try to restart the service
    echo -e "${green}Attempting to restart x-ui service...${plain}"
    systemctl daemon-reload
    systemctl restart x-ui
    
    sleep 2
    
    # Check if service started successfully
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}Success! x-ui service is now running.${plain}"
    else
        echo -e "${red}x-ui service still failing. Let's check the detailed logs:${plain}"
        journalctl -u x-ui --no-pager -n 20
        
        echo -e "\n${yellow}Would you like to perform a complete reinstallation? [y/n]${plain}"
        read -p "" final_reinstall
        if [[ x"${final_reinstall}" == x"y" || x"${final_reinstall}" == x"Y" ]]; then
            # Backup database if it exists
            if [ -f /usr/local/x-ui/db/x-ui.db ]; then
                echo -e "${green}Backing up your database...${plain}"
                mkdir -p /tmp/x-ui-backup
                cp /usr/local/x-ui/db/x-ui.db /tmp/x-ui-backup/
                echo -e "${green}Database backed up to /tmp/x-ui-backup/x-ui.db${plain}"
            fi
            
            install_x-ui
            
            # Restore database if backup exists
            if [ -f /tmp/x-ui-backup/x-ui.db ]; then
                echo -e "${green}Restoring your database...${plain}"
                cp /tmp/x-ui-backup/x-ui.db /usr/local/x-ui/db/
                echo -e "${green}Database restored.${plain}"
                systemctl restart x-ui
            fi
        else
            echo -e "${red}Troubleshooting completed, but issues remain.${plain}"
            echo -e "${yellow}Please consider contacting the x-ui developers for assistance.${plain}"
        fi
    fi
}

# Get available versions from GitHub
get_versions() {
    echo -e "${green}Fetching available x-ui versions...${plain}"
    
    # Get all releases from GitHub API with proper pagination and error handling
    all_releases=""
    page=1
    
    while true; do
        echo -e "${yellow}Fetching releases page ${page}...${plain}"
        temp_releases=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ThePieOfSauron/x-ui/releases?per_page=100&page=${page}")
        
        # Check for API rate limiting or errors
        if echo "$temp_releases" | grep -q "API rate limit exceeded"; then
            echo -e "${red}GitHub API rate limit exceeded. Please try again later.${plain}"
            exit 1
        fi
        
        if echo "$temp_releases" | grep -q "Not Found"; then
            echo -e "${red}Repository not found or no access. Please check the repository URL.${plain}"
            exit 1
        fi
        
        # Check if empty result (end of pages)
        if [ "$temp_releases" = "[]" ] || [ -z "$temp_releases" ]; then
            break
        fi
        
        # Extract tags and append to all_releases
        page_releases=$(echo "$temp_releases" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"v\([^"]*\)"/\1/')
        
        if [ -z "$page_releases" ]; then
            break
        fi
        
        if [ -z "$all_releases" ]; then
            all_releases="$page_releases"
        else
            all_releases="$all_releases"$'\n'"$page_releases"
        fi
        
        # Move to next page
        page=$((page+1))
        
        # Basic safety check to avoid infinite loops (in case API behavior changes)
        if [ $page -gt 10 ]; then
            break
        fi
    done
    
    if [[ -z "$all_releases" ]]; then
        echo -e "${red}Failed to fetch release list from GitHub. Please check your network or try again later.${plain}"
        
        # Fallback to directly checking for the latest version
        echo -e "${yellow}Trying direct method to fetch the latest version...${plain}"
        latest_version=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
        
        if [[ -n "$latest_version" ]]; then
            echo -e "${green}Found latest version: ${latest_version}${plain}"
            latest_versions=("$latest_version")
        else
            echo -e "${red}Could not determine the latest version. Please check manually.${plain}"
            exit 1
        fi
    else
        # Filter out pre-release versions and sort
        all_releases=$(echo "$all_releases" | grep -v 'beta\|alpha\|rc' | sort -rV)
        
        # Get latest 3 versions
        latest_versions=($(echo "$all_releases" | head -n 3))
        
        if [[ ${#latest_versions[@]} -eq 0 ]]; then
            echo -e "${red}No versions found. Please check the repository.${plain}"
            exit 1
        fi
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

    # Get all releases from GitHub API - using improved method with pagination
    all_releases=""
    page=1
    
    while true; do
        echo -e "${yellow}Fetching releases page ${page}...${plain}"
        temp_releases=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ThePieOfSauron/x-ui/releases?per_page=100&page=${page}")
        
        # Check for API rate limiting or errors
        if echo "$temp_releases" | grep -q "API rate limit exceeded"; then
            echo -e "${red}GitHub API rate limit exceeded. Please try again later.${plain}"
            return 1
        fi
        
        if echo "$temp_releases" | grep -q "Not Found"; then
            echo -e "${red}Repository not found or no access. Please check the repository URL.${plain}"
            return 1
        fi
        
        # Check if empty result (end of pages)
        if [ "$temp_releases" = "[]" ] || [ -z "$temp_releases" ]; then
            break
        fi
        
        # Extract tags and append to all_releases
        page_releases=$(echo "$temp_releases" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"v\([^"]*\)"/\1/')
        
        if [ -z "$page_releases" ]; then
            break
        fi
        
        if [ -z "$all_releases" ]; then
            all_releases="$page_releases"
        else
            all_releases="$all_releases"$'\n'"$page_releases"
        fi
        
        # Move to next page
        page=$((page+1))
        
        # Basic safety check to avoid infinite loops (in case API behavior changes)
        if [ $page -gt 10 ]; then
            break
        fi
    done
    
    if [[ -z "$all_releases" ]]; then
        echo -e "${red}Failed to fetch release list from GitHub. Please check your network or try again later.${plain}"
        # Fallback to directly checking for latest version
        echo -e "${yellow}Trying direct method to fetch the latest version...${plain}"
        latest_version=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
        
        if [[ -z "$latest_version" ]]; then
            echo -e "${red}Could not determine the latest version. Please check manually.${plain}"
            return 1
        fi
    else
        # Filter out pre-release versions and sort
        all_releases=$(echo "$all_releases" | grep -v 'beta\|alpha\|rc' | sort -rV)
        latest_version=$(echo "$all_releases" | head -n 1)
    fi
    
    echo -e "${yellow}Latest available version: ${latest_version}${plain}"
    
    # Compare versions - using numeric comparison after removing dots
    current_ver_num=$(echo "$current_version" | sed 's/\.//g')
    latest_ver_num=$(echo "$latest_version" | sed 's/\.//g')
    
    if [[ $latest_ver_num -le $current_ver_num ]]; then
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

# Add the new uninstall function here
uninstall_x-ui() {
    echo -e "${green}Starting x-ui uninstall process...${plain}"
    
    read -p "This will completely remove x-ui and its configuration. Are you sure you want to continue? [y/n]: " uninstall_confirm
    if [[ x"${uninstall_confirm}" != x"y" && x"${uninstall_confirm}" != x"Y" ]]; then
        echo -e "${red}Uninstall canceled.${plain}"
        exit 0
    fi
    
    # Stop the service
    echo -e "${yellow}Stopping x-ui service...${plain}"
    systemctl stop x-ui 2>/dev/null
    
    # Disable the service
    echo -e "${yellow}Disabling x-ui service...${plain}"
    systemctl disable x-ui 2>/dev/null
    
    # Remove service file
    echo -e "${yellow}Removing systemd service file...${plain}"
    rm -f /etc/systemd/system/x-ui.service
    
    # Reload systemd daemon
    echo -e "${yellow}Reloading systemd daemon...${plain}"
    systemctl daemon-reload
    
    # Remove installation directory
    echo -e "${yellow}Removing installation directory: /usr/local/x-ui/...${plain}"
    rm -rf /usr/local/x-ui/
    
    # Remove command alias
    echo -e "${yellow}Removing command alias: /usr/bin/x-ui...${plain}"
    rm -f /usr/bin/x-ui
    
    # Remove backup directory (if exists)
    if [ -d /tmp/x-ui-backup ]; then
        echo -e "${yellow}Removing temporary backup directory: /tmp/x-ui-backup/...${plain}"
        rm -rf /tmp/x-ui-backup/
    fi
    
    echo -e "${green}x-ui uninstallation complete.${plain}"
    echo -e "${yellow}Please note that firewall rules (if any were added manually) might still need to be removed.${plain}"
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
    echo -e "x-ui uninstall    - Completely remove x-ui"
    echo -e "x-ui check-update - Check for updates and update binaries only"
    echo -e "x-ui troubleshoot - Diagnose and fix service issues"
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
        "troubleshoot")
            install_base
            troubleshoot_service
            ;;
        "uninstall")
            uninstall_x-ui
            ;;
        *)
            echo -e "${red}Unknown command: $1${plain}"
            echo "Usage: $0 [install/check-update/troubleshoot/uninstall] [version]"
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
            
            # Check for newer version using improved version detection
            echo -e "${green}Checking for updates...${plain}"
            
            # Use the same improved GitHub API fetching as in check_update_binaries
            all_releases=""
            page=1
            
            while true; do
                echo -e "${yellow}Fetching releases page ${page}...${plain}"
                temp_releases=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ThePieOfSauron/x-ui/releases?per_page=100&page=${page}")
                
                # Check for API rate limiting or errors
                if echo "$temp_releases" | grep -q "API rate limit exceeded"; then
                    echo -e "${red}GitHub API rate limit exceeded. Please try again later.${plain}"
                    echo -e "${yellow}Proceeding with installation using current version.${plain}"
                    break
                fi
                
                if echo "$temp_releases" | grep -q "Not Found"; then
                    echo -e "${red}Repository not found or no access. Please check the repository URL.${plain}"
                    echo -e "${yellow}Proceeding with installation using current version.${plain}"
                    break
                fi
                
                # Check if empty result (end of pages)
                if [ "$temp_releases" = "[]" ] || [ -z "$temp_releases" ]; then
                    break
                fi
                
                # Extract tags and append to all_releases
                page_releases=$(echo "$temp_releases" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"v\([^"]*\)"/\1/')
                
                if [ -z "$page_releases" ]; then
                    break
                fi
                
                if [ -z "$all_releases" ]; then
                    all_releases="$page_releases"
                else
                    all_releases="$all_releases"$'\n'"$page_releases"
                fi
                
                # Move to next page
                page=$((page+1))
                
                # Basic safety check to avoid infinite loops (in case API behavior changes)
                if [ $page -gt 10 ]; then
                    break
                fi
            done
            
            # Determine the latest version
            latest_version=""
            
            if [[ -z "$all_releases" ]]; then
                # Try fallback method for latest version
                latest_version=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
                if [[ -z "$latest_version" ]]; then
                    echo -e "${red}Could not determine the latest version. Using current version for comparison.${plain}"
                    latest_version="$current_version" # Fallback to current version
                fi
            else
                # Filter out pre-release versions and sort
                all_releases=$(echo "$all_releases" | grep -v 'beta\|alpha\|rc' | sort -rV)
                latest_version=$(echo "$all_releases" | head -n 1)
            fi
            
            # Compare versions using numeric comparison
            if [ -n "$latest_version" ]; then
                echo -e "${yellow}Latest available version: ${latest_version}${plain}"
                
                # Convert versions to numeric for comparison
                current_ver_num=$(echo "$current_version" | sed 's/\.//g')
                latest_ver_num=$(echo "$latest_version" | sed 's/\.//g')
                
                if [[ $latest_ver_num -gt $current_ver_num ]]; then
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
