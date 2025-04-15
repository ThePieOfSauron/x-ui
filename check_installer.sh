#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${yellow}X-UI Installer Check Script${plain}"
echo -e "${yellow}==========================${plain}"
echo ""

# Check if we're running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Error: This script must be run as root${plain}"
    exit 1
else
    echo -e "${green}✓ Running as root${plain}"
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
echo -e "${green}✓ Architecture detected: ${arch}${plain}"

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
echo -e "${green}✓ OS detected: ${release}${plain}"

# Checking connectivity to GitHub
echo -e "${yellow}Checking GitHub connectivity...${plain}"
if curl -s --connect-timeout 5 https://github.com > /dev/null; then
    echo -e "${green}✓ GitHub is accessible${plain}"
else
    echo -e "${red}× Cannot connect to GitHub. Please check your internet connection or if GitHub is blocked in your country${plain}"
    exit 1
fi

# Checking GitHub API rate limit
echo -e "${yellow}Checking GitHub API rate limit...${plain}"
rate_limit_info=$(curl -s https://api.github.com/rate_limit)
remaining=$(echo $rate_limit_info | grep -o '"remaining":[0-9]*' | grep -o '[0-9]*')

if [[ -z "$remaining" ]]; then
    echo -e "${red}× Failed to check GitHub API rate limit${plain}"
else
    if [[ $remaining -eq 0 ]]; then
        echo -e "${red}× GitHub API rate limit exceeded. Please try again later${plain}"
        reset_time=$(echo $rate_limit_info | grep -o '"reset":[0-9]*' | grep -o '[0-9]*')
        if [[ ! -z "$reset_time" ]]; then
            reset_date=$(date -d @$reset_time)
            echo -e "${yellow}  Rate limit will reset at: $reset_date${plain}"
        fi
    else
        echo -e "${green}✓ GitHub API rate limit remaining: $remaining${plain}"
    fi
fi

# Checking latest release from GitHub API
echo -e "${yellow}Checking latest x-ui release...${plain}"
latest_release=$(curl -Ls "https://api.github.com/repos/YOUR_USERNAME/x-ui/releases/latest")
if [[ -z "$latest_release" ]]; then
    echo -e "${red}× Failed to fetch latest release info${plain}"
    exit 1
fi

last_version=$(echo "$latest_release" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [[ ! -n "$last_version" ]]; then
    echo -e "${red}× Failed to extract version tag from release info${plain}"
    exit 1
fi
echo -e "${green}✓ Latest version: ${last_version}${plain}"

# Test downloading the release file
echo -e "${yellow}Testing download of release file...${plain}"
url="https://github.com/YOUR_USERNAME/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
echo -e "${yellow}  URL: ${url}${plain}"

# Only check if the file exists without downloading the whole thing
http_code=$(curl -sI "$url" -o /dev/null -w "%{http_code}")
if [[ "$http_code" == "200" || "$http_code" == "302" ]]; then
    echo -e "${green}✓ Release file exists and is accessible${plain}"
else
    echo -e "${red}× Failed to access release file (HTTP code: $http_code)${plain}"
    echo -e "${red}  URL: ${url}${plain}"
    exit 1
fi

# Check x-ui.sh script
echo -e "${yellow}Testing access to x-ui.sh script...${plain}"
script_url="https://raw.githubusercontent.com/YOUR_USERNAME/x-ui/master/x-ui.sh"
http_code=$(curl -sI "$script_url" -o /dev/null -w "%{http_code}")
if [[ "$http_code" == "200" ]]; then
    echo -e "${green}✓ x-ui.sh script is accessible${plain}"
else
    echo -e "${red}× Failed to access x-ui.sh script (HTTP code: $http_code)${plain}"
    echo -e "${red}  URL: ${script_url}${plain}"
    exit 1
fi

# Check install.sh script
echo -e "${yellow}Testing access to install.sh script...${plain}"
install_url="https://raw.githubusercontent.com/YOUR_USERNAME/x-ui/master/install.sh"
http_code=$(curl -sI "$install_url" -o /dev/null -w "%{http_code}")
if [[ "$http_code" == "200" ]]; then
    echo -e "${green}✓ install.sh script is accessible${plain}"
else
    echo -e "${red}× Failed to access install.sh script (HTTP code: $http_code)${plain}"
    echo -e "${red}  URL: ${install_url}${plain}"
    exit 1
fi

# Check for system dependencies
echo -e "${yellow}Checking for system dependencies...${plain}"
if [[ x"${release}" == x"centos" ]]; then
    if ! command -v wget >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
        echo -e "${yellow}  Some dependencies are missing. They would be installed during actual installation.${plain}"
    else
        echo -e "${green}✓ Required dependencies (wget, curl, tar) are installed${plain}"
    fi
else
    if ! command -v wget >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
        echo -e "${yellow}  Some dependencies are missing. They would be installed during actual installation.${plain}"
    else
        echo -e "${green}✓ Required dependencies (wget, curl, tar) are installed${plain}"
    fi
fi

# Summary
echo ""
echo -e "${yellow}Installation Check Summary${plain}"
echo -e "${yellow}======================${plain}"
echo -e "${green}✓ System requirements check passed${plain}"
echo -e "${green}✓ GitHub connectivity check passed${plain}"
echo -e "${green}✓ Latest version: ${last_version}${plain}"
echo -e "${green}✓ Release file is accessible${plain}"
echo -e "${green}✓ Required scripts are accessible${plain}"
echo ""
echo -e "${green}The installer appears to be working correctly!${plain}"
echo -e "${yellow}To perform the actual installation, run:${plain}"
echo -e "${yellow}bash <(curl -Ls https://raw.githubusercontent.com/YOUR_USERNAME/x-ui/master/install.sh)${plain}"
echo "" 