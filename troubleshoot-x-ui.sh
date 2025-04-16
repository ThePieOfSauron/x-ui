#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# Architecture detection
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

# OS detection
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
    release="unknown"
fi

# Install basic tools
install_base() {
    echo -e "${green}Installing basic tools...${plain}"
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar file ldd -y
    else
        apt update
        apt install wget curl tar file ldd -y
    fi
}

# Fix binary permissions
fix_permissions() {
    echo -e "${green}Fixing binary permissions...${plain}"
    if [ -f /usr/local/x-ui/x-ui ]; then
        chmod +x /usr/local/x-ui/x-ui
        echo -e "${green}Set executable permission for x-ui binary${plain}"
    fi
    
    if [ -f /usr/local/x-ui/bin/xray-linux-${arch} ]; then
        chmod +x /usr/local/x-ui/bin/xray-linux-${arch}
        echo -e "${green}Set executable permission for Xray binary${plain}"
    fi
    
    if [ -f /usr/bin/x-ui ]; then
        chmod +x /usr/bin/x-ui
        echo -e "${green}Set executable permission for x-ui command${plain}"
    fi
}

# Fix service file
fix_service_file() {
    echo -e "${green}Checking service file...${plain}"
    if [ ! -f /etc/systemd/system/x-ui.service ]; then
        echo -e "${yellow}Service file missing, attempting to recreate...${plain}"
        if [ -f /usr/local/x-ui/x-ui.service ]; then
            cp -f /usr/local/x-ui/x-ui.service /etc/systemd/system/
            echo -e "${green}Service file recreated from template${plain}"
        else
            cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=x-ui Service
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/usr/local/x-ui/
ExecStart=/usr/local/x-ui/x-ui
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
            echo -e "${green}Service file created manually${plain}"
        fi
        
        systemctl daemon-reload
    else
        echo -e "${green}Service file exists${plain}"
    fi
}

# Check for missing x-ui binary (main cause of 203/EXEC)
check_binary() {
    echo -e "${green}Checking x-ui binary...${plain}"
    
    if [ ! -d /usr/local/x-ui ]; then
        echo -e "${red}x-ui directory not found!${plain}"
        echo -e "${yellow}This indicates x-ui is not installed or the installation is corrupted.${plain}"
        return 1
    fi
    
    if [ ! -f /usr/local/x-ui/x-ui ]; then
        echo -e "${red}x-ui binary not found! This is the direct cause of the 203/EXEC error.${plain}"
        return 1
    fi
    
    echo -e "${green}x-ui binary exists${plain}"
    
    # Check if the binary is executable
    if [ ! -x /usr/local/x-ui/x-ui ]; then
        echo -e "${yellow}x-ui binary is not executable${plain}"
        fix_permissions
    fi
    
    # Check architecture match
    if command -v file > /dev/null 2>&1; then
        binary_info=$(file /usr/local/x-ui/x-ui)
        echo -e "${green}Binary info: ${binary_info}${plain}"
        
        # Check for architecture mismatch
        if [[ "$arch" == "amd64" && ! "$binary_info" =~ "x86-64" ]]; then
            echo -e "${red}Architecture mismatch! You have an arm64 or s390x binary on an amd64 system.${plain}"
            return 1
        elif [[ "$arch" == "arm64" && ! "$binary_info" =~ "aarch64" && ! "$binary_info" =~ "arm64" ]]; then
            echo -e "${red}Architecture mismatch! You have an amd64 or s390x binary on an arm64 system.${plain}"
            return 1
        elif [[ "$arch" == "s390x" && ! "$binary_info" =~ "s390x" ]]; then
            echo -e "${red}Architecture mismatch! You have an amd64 or arm64 binary on a s390x system.${plain}"
            return 1
        fi
    fi
    
    # Check for missing libraries
    echo -e "${green}Checking for missing libraries...${plain}"
    if command -v ldd > /dev/null 2>&1; then
        missing_libs=$(ldd /usr/local/x-ui/x-ui 2>&1 | grep "not found")
        if [ -n "$missing_libs" ]; then
            echo -e "${red}Missing libraries detected:${plain}"
            echo "$missing_libs"
            
            echo -e "${yellow}Installing required libraries...${plain}"
            if [[ x"${release}" == x"centos" ]]; then
                yum install -y glibc glibc-devel
            else
                apt update
                apt install -y libc6 libc6-dev
            fi
        else
            echo -e "${green}All required libraries are available${plain}"
        fi
    else
        echo -e "${yellow}ldd command not found, cannot check for missing libraries${plain}"
    fi
    
    return 0
}

# Download x-ui
download_x_ui() {
    echo -e "${green}Downloading latest version of x-ui...${plain}"
    
    # Get latest version
    latest_version=$(curl -s https://api.github.com/repos/ThePieOfSauron/x-ui/releases/latest | grep "tag_name" | cut -d'"' -f4 | sed 's/v//')
    
    if [ -z "$latest_version" ]; then
        echo -e "${red}Failed to get latest version, using fallback version 0.4.0${plain}"
        latest_version="0.4.0"
    fi
    
    echo -e "${green}Latest version: ${latest_version}${plain}"
    
    # Backup current database
    if [ -f /usr/local/x-ui/db/x-ui.db ]; then
        echo -e "${green}Backing up database...${plain}"
        mkdir -p /tmp/x-ui-backup
        cp /usr/local/x-ui/db/x-ui.db /tmp/x-ui-backup/
    fi
    
    # Stop the service
    systemctl stop x-ui
    
    # Download latest version
    wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/ThePieOfSauron/x-ui/releases/download/v${latest_version}/x-ui-linux-${arch}-${latest_version}.tar.gz
    
    if [ $? -ne 0 ]; then
        echo -e "${red}Failed to download x-ui, please check your network or try again later${plain}"
        return 1
    fi
    
    # Extract
    cd /usr/local/
    rm -rf /usr/local/x-ui
    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    
    # Set permissions
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    
    # Restore database if exists
    if [ -f /tmp/x-ui-backup/x-ui.db ]; then
        echo -e "${green}Restoring database...${plain}"
        mkdir -p /usr/local/x-ui/db
        cp /tmp/x-ui-backup/x-ui.db /usr/local/x-ui/db/
    fi
    
    # Set permissions
    fix_permissions
    
    # Reload and restart service
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    echo -e "${green}x-ui has been reinstalled to version ${latest_version}${plain}"
    
    return 0
}

# Troubleshoot service
troubleshoot_service() {
    echo -e "${green}Starting service troubleshooting...${plain}"
    
    # Fix service file first
    fix_service_file
    
    # Check binary
    if ! check_binary; then
        echo -e "${yellow}Binary issues detected. Would you like to download the latest version? [y/n]${plain}"
        read -p "" download_confirm
        if [[ x"${download_confirm}" == x"y" || x"${download_confirm}" == x"Y" ]]; then
            download_x_ui
        else
            echo -e "${red}Troubleshooting aborted.${plain}"
            return 1
        fi
    fi
    
    # Check SELinux
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
    
    # Try restarting the service
    echo -e "${green}Attempting to restart x-ui service...${plain}"
    systemctl daemon-reload
    systemctl restart x-ui
    
    sleep 3
    
    # Check if service is running
    if systemctl is-active --quiet x-ui; then
        echo -e "${green}Success! x-ui service is now running!${plain}"
        echo -e "${green}You should now be able to access the panel via the web interface.${plain}"
    else
        echo -e "${red}Service failed to start. Checking for more details...${plain}"
        
        # Show detailed logs
        echo -e "${yellow}Service logs:${plain}"
        journalctl -u x-ui --no-pager -n 20
        
        echo -e "\n${red}Troubleshooting failed to resolve the issue.${plain}"
        echo -e "${yellow}Would you like to perform a complete reinstallation? [y/n]${plain}"
        read -p "" full_reinstall
        if [[ x"${full_reinstall}" == x"y" || x"${full_reinstall}" == x"Y" ]]; then
            download_x_ui
        else
            echo -e "${red}Troubleshooting completed, but issues remain.${plain}"
            echo -e "${yellow}Please consider contacting the x-ui developers for assistance.${plain}"
        fi
    fi
}

# Main function
main() {
    echo -e "${green}x-ui Service Troubleshooter${plain}"
    echo -e "${yellow}This script is designed to fix the 203/EXEC error and other common service issues.${plain}"
    echo ""
    
    # Check if root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}Error: This script must be run as root!${plain}"
        exit 1
    fi
    
    # Install base tools
    install_base
    
    # Start troubleshooting
    troubleshoot_service
    
    echo ""
    echo -e "${green}Troubleshooting process completed.${plain}"
}

# Run main function
main 