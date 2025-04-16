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
            echo -e "${green}Reinstallation would be initiated here.${plain}"
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
            echo -e "${green}Reinstallation would be initiated here.${plain}"
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
            echo -e "${green}Complete reinstallation would be initiated here.${plain}"
        else
            echo -e "${red}Troubleshooting completed, but issues remain.${plain}"
            echo -e "${yellow}Please consider contacting the x-ui developers for assistance.${plain}"
        fi
    fi
}

# Main function
main() {
    echo -e "${green}x-ui Troubleshooter${plain}"
    echo -e "${yellow}This script will diagnose and attempt to fix issues with your x-ui installation.${plain}"
    echo -e "${yellow}Specifically addressing 203/EXEC errors that prevent the service from starting.${plain}"
    echo ""
    
    # Need root privileges
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}Error: This script must be run as root!${plain}"
        exit 1
    fi
    
    troubleshoot_service
}

# Run main function
main 