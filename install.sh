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
        yum install wget curl tar -y
    else
        apt install wget curl tar -y
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

install_x-ui() {
    systemctl stop x-ui
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/YOUR_USERNAME/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to detect x-ui version, possibly exceeding Github API limits. Please try again later or manually specify the version.${plain}"
            exit 1
        fi
        echo -e "Detected latest x-ui version: ${last_version}, starting installation"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz https://github.com/YOUR_USERNAME/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download x-ui. Please ensure your server can download from Github.${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/YOUR_USERNAME/x-ui/releases/download/${last_version}/x-ui-linux-${arch}.tar.gz"
        echo -e "Starting installation of x-ui v$1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-${arch}.tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download x-ui v$1. Please ensure this version exists.${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-${arch}.tar.gz
    rm x-ui-linux-${arch}.tar.gz -f
    cd x-ui
    chmod +x x-ui bin/xray-linux-${arch}
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/YOUR_USERNAME/x-ui/master/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui v${last_version}${plain} installation complete. The panel has been started."
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
}

echo -e "${green}Starting installation${plain}"
install_base
install_x-ui $1
