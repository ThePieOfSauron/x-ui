#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
cyan='\033[0;36m'

# Get version and port information
get_version() {
    version=$(/usr/local/x-ui/x-ui -v 2>/dev/null)
    if [ $? -ne 0 ]; then
        version="Unknown"
    fi
}

get_port() {
    port=$(/usr/local/x-ui/x-ui setting -show true 2>/dev/null | grep "port" | awk '{print $2}')
    if [ -z "$port" ]; then
        port="Unknown"
    fi
}

# Get current language setting
get_current_language() {
    current_lang=$(/usr/local/x-ui/x-ui setting -show true 2>/dev/null | grep "language" | awk -F " " '{print $2}')
    if [ -z "$current_lang" ]; then
        current_lang="en_US"
    fi
    echo $current_lang
}

# Load language texts
load_language() {
    curr_lang=$(get_current_language)
    
    # English texts
    if [ "$curr_lang" = "en_US" ]; then
        ERROR_ROOT="Error: You must use root user to run this script!"
        ERROR_OS="OS version not detected, please contact script author!"
        ERROR_CENTOS="Please use CentOS 7 or higher version of the system!"
        ERROR_UBUNTU="Please use Ubuntu 16 or higher version of the system!"
        ERROR_DEBIAN="Please use Debian 8 or higher version of the system!"
        CONFIRM_DEFAULT="[default %s]"
        CONFIRM_YES_NO="[y/n]"
        RESTART_PANEL_CONFIRM="Do you want to restart the panel? Restarting the panel will also restart xray"
        RETURN_MENU="Press enter to return to main menu"
        INSTALL_FORCE_CONFIRM="This function will force reinstall the current latest version, data will not be lost, continue?"
        INSTALL_CANCEL="Cancelled"
        UPDATE_COMPLETE="Update completed, panel has been automatically restarted"
        UNINSTALL_CONFIRM="Are you sure you want to uninstall the panel? xray will also be uninstalled"
        UNINSTALL_SUCCESS="Uninstall successful. If you want to remove this script, exit the script and run 'rm /usr/bin/x-ui -f'"
        RESET_USER_CONFIRM="Are you sure you want to reset the username and password to 'admin'?"
        RESET_USER_SUCCESS="Username and password have been reset to 'admin', please restart the panel now"
        RESET_CONFIG_CONFIRM="Are you sure you want to reset all panel settings? Account data will not be lost, and username and password will not change"
        RESET_CONFIG_SUCCESS="All panel settings have been reset to default values, please restart the panel now and access the panel using the default port '54321'"
        CHECK_CONFIG_ERROR="Failed to get current settings, please check logs"
        SET_PORT_TITLE="Enter port number [1-65535]"
        SET_PORT_CANCEL="Cancelled"
        SET_PORT_SUCCESS="Port setting complete, please restart the panel now and access using the new port %s"
        START_PANEL_ALREADY="Panel is already running, no need to start again. To restart, please select restart"
        START_PANEL_SUCCESS="Panel started successfully"
        STOP_PANEL_ALREADY="Panel already stopped"
        STOP_PANEL_SUCCESS="Panel stopped successfully"
        RESTART_PANEL_SUCCESS="Panel restarted successfully"
        CHECK_PANEL_RUNNING="Running"
        CHECK_PANEL_STOPPED="Stopped"
        CHECK_PANEL_STATUS="Panel status"
        CHECK_PANEL_INFO="x-ui version"
        CHECK_PANEL_PORT="Panel listening port"
        CHECK_PANEL_ERROR="Failed to get panel status"
        ENABLE_AUTOSTART_SUCCESS="Successfully set panel auto-start"
        DISABLE_AUTOSTART_SUCCESS="Successfully canceled panel auto-start"
        SHOW_LOG_INFO="Press Ctrl+C to exit the view"
        MENU_TITLE="x-ui panel management script"
        MENU_INFO1="Current version: %s"
        MENU_INFO2="Current language: %s"
        MENU_INFO3="Visit the panel in your browser at http://your_ip:%s"
        MENU_OPTION_START="Start panel"
        MENU_OPTION_STOP="Stop panel"
        MENU_OPTION_RESTART="Restart panel"
        MENU_OPTION_STATUS="View panel status"
        MENU_OPTION_ENABLE_AUTOSTART="Set panel auto-start"
        MENU_OPTION_DISABLE_AUTOSTART="Cancel panel auto-start"
        MENU_OPTION_SET_PORT="Set panel port"
        MENU_OPTION_LANG="Switch language"
        MENU_OPTION_RESET_USER="Reset username and password"
        MENU_OPTION_RESET_CONFIG="Reset panel settings"
        MENU_OPTION_SHOW_CONFIG="Show current settings"
        MENU_OPTION_VIEW_LOG="View log"
        MENU_OPTION_MIGRATE="Migrate from v2-ui"
        MENU_OPTION_UPDATE="Update panel"
        MENU_OPTION_INSTALL="Install panel"
        MENU_OPTION_UNINSTALL="Uninstall panel"
        MENU_OPTION_EXIT="Exit"
        MENU_CHOICE="Please enter a number"
        MENU_LANG_TITLE="Switch language"
        MENU_LANG_EN="1. English"
        MENU_LANG_CN="2. 简体中文"
        MENU_LANG_HK="3. 繁體中文"
        MENU_LANG_CHOICE="Please select a language (1-3)"
        MENU_LANG_CURRENT="Current language: %s"
        MENU_LANG_CHANGED="Language has been changed to: %s"
    # Simplified Chinese texts
    else
        ERROR_ROOT="错误: 必须使用root用户运行此脚本!"
        ERROR_OS="未检测到系统版本，请联系脚本作者！"
        ERROR_CENTOS="请使用 CentOS 7 或更高版本的系统！"
        ERROR_UBUNTU="请使用 Ubuntu 16 或更高版本的系统！"
        ERROR_DEBIAN="请使用 Debian 8 或更高版本的系统！"
        CONFIRM_DEFAULT="[默认%s]"
        CONFIRM_YES_NO="[y/n]"
        RESTART_PANEL_CONFIRM="是否重启面板，重启面板也会重启 xray"
        RETURN_MENU="按回车返回主菜单"
        INSTALL_FORCE_CONFIRM="本功能会强制重装当前最新版，数据不会丢失，是否继续?"
        INSTALL_CANCEL="已取消"
        UPDATE_COMPLETE="更新完成，已自动重启面板"
        UNINSTALL_CONFIRM="确定要卸载面板吗,xray 也会卸载?"
        UNINSTALL_SUCCESS="卸载成功，如果你想删除此脚本，则退出脚本后运行 'rm /usr/bin/x-ui -f' 进行删除"
        RESET_USER_CONFIRM="确定要将用户名和密码重置为 admin 吗"
        RESET_USER_SUCCESS="用户名和密码已重置为 admin，现在请重启面板"
        RESET_CONFIG_CONFIRM="确定要重置所有面板设置吗，账号数据不会丢失，用户名和密码不会改变"
        RESET_CONFIG_SUCCESS="所有面板设置已重置为默认值，现在请重启面板，并使用默认的 54321 端口访问面板"
        CHECK_CONFIG_ERROR="获取当前设置错误，请检查日志"
        SET_PORT_TITLE="输入端口号[1-65535]"
        SET_PORT_CANCEL="已取消"
        SET_PORT_SUCCESS="设置端口完毕，现在请重启面板，并使用新设置的端口 %s 访问面板"
        START_PANEL_ALREADY="面板已运行，无需再次启动，如需重启请选择重启"
        START_PANEL_SUCCESS="面板启动成功"
        STOP_PANEL_ALREADY="面板已停止"
        STOP_PANEL_SUCCESS="面板停止成功"
        RESTART_PANEL_SUCCESS="面板重启成功"
        CHECK_PANEL_RUNNING="运行中"
        CHECK_PANEL_STOPPED="已停止"
        CHECK_PANEL_STATUS="面板状态"
        CHECK_PANEL_INFO="x-ui 版本"
        CHECK_PANEL_PORT="面板监听端口"
        CHECK_PANEL_ERROR="获取面板状态失败"
        ENABLE_AUTOSTART_SUCCESS="设置开机自启成功"
        DISABLE_AUTOSTART_SUCCESS="取消开机自启成功"
        SHOW_LOG_INFO="按 Ctrl+C 退出查看"
        MENU_TITLE="x-ui 面板管理脚本"
        MENU_INFO1="当前版本: %s"
        MENU_INFO2="当前语言: %s"
        MENU_INFO3="在浏览器中访问面板: http://你的ip:%s"
        MENU_OPTION_START="启动面板"
        MENU_OPTION_STOP="停止面板"
        MENU_OPTION_RESTART="重启面板"
        MENU_OPTION_STATUS="查看面板状态"
        MENU_OPTION_ENABLE_AUTOSTART="设置开机自启"
        MENU_OPTION_DISABLE_AUTOSTART="取消开机自启"
        MENU_OPTION_SET_PORT="设置面板端口"
        MENU_OPTION_LANG="切换语言"
        MENU_OPTION_RESET_USER="重置用户名密码"
        MENU_OPTION_RESET_CONFIG="重置面板设置"
        MENU_OPTION_SHOW_CONFIG="查看当前设置"
        MENU_OPTION_VIEW_LOG="查看日志"
        MENU_OPTION_MIGRATE="迁移 v2-ui 账号数据"
        MENU_OPTION_UPDATE="更新面板"
        MENU_OPTION_INSTALL="安装面板"
        MENU_OPTION_UNINSTALL="卸载面板"
        MENU_OPTION_EXIT="退出"
        MENU_CHOICE="请输入选择"
        MENU_LANG_TITLE="切换语言"
        MENU_LANG_EN="1. English"
        MENU_LANG_CN="2. 简体中文"
        MENU_LANG_HK="3. 繁體中文"
        MENU_LANG_CHOICE="请选择语言 (1-3)"
        MENU_LANG_CURRENT="当前语言: %s"
        MENU_LANG_CHANGED="语言已切换为: %s"
    fi
}

#Add some basic function here
function LOGD() {
    echo -e "${yellow}[DEG] $* ${plain}"
}

function LOGE() {
    echo -e "${red}[ERR] $* ${plain}"
}

function LOGI() {
    echo -e "${green}[INF] $* ${plain}"
}
# check root
[[ $EUID -ne 0 ]] && LOGE "$ERROR_ROOT\n" && exit 1

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
    LOGE "$ERROR_OS\n" && exit 1
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
        LOGE "$ERROR_CENTOS\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        LOGE "$ERROR_UBUNTU\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        LOGE "$ERROR_DEBIAN\n" && exit 1
    fi
fi

# Load language
load_language

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 $(printf "$CONFIRM_DEFAULT" $2): " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 $CONFIRM_YES_NO: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "$RESTART_PANEL_CONFIRM" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}$RETURN_MENU: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -e "  ${green}x-ui update${plain}" && echo
        echo -e "  ${green}0.${plain} Back to Main Menu"
        echo -e "  ${green}1.${plain} Check for latest versions"
        echo -e "  ${green}2.${plain} Update to a specific version"
        echo && read -p "Please enter a number [0-2]: " num

        case "${num}" in
            0) show_menu ;;
            1) check_latest_version ;;
            2) select_version_update ;;
            *) echo -e "${red}Please enter a valid number [0-2]${plain}" ;;
        esac
    else
        install_x-ui $1
    fi
}

check_latest_version() {
    echo -e "Getting available versions from GitHub..."
    latest_version=$(curl -Ls "https://api.github.com/repos/ThePieOfSauron/x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ ! -n "$latest_version" ]]; then
        echo -e "${red}Failed to retrieve latest version, please check your network or try again later${plain}"
        return
    fi
    
    echo -e "Current version: ${green}${version}${plain}"
    echo -e "Latest version: ${green}${latest_version}${plain}"
    
    if [[ "${latest_version}" == "v${version}" ]]; then
        echo -e "You are already running the latest version. No update needed."
        before_show_menu
        return
    fi
    
    confirm "Update to ${latest_version}? [y/n]" "n"
    if [[ $? == 0 ]]; then
        install_x-ui "${latest_version#v}"
    fi
}

select_version_update() {
    echo -e "Getting available versions from GitHub..."
    all_releases=$(curl -s "https://api.github.com/repos/ThePieOfSauron/x-ui/releases" | jq -r '.[].tag_name' | grep -v 'beta\|alpha\|rc' | sed 's/^v//')
    
    if [[ -z "$all_releases" ]]; then
        echo -e "${red}Failed to fetch release list from GitHub. Please check your network or try again later.${plain}"
        before_show_menu
        return
    fi
    
    # Sort versions in descending order and get the latest 5
    latest_versions=($(echo "$all_releases" | sort -rV | head -n 5))
    
    if [[ ${#latest_versions[@]} -eq 0 ]]; then
        echo -e "${red}No versions found. Please check the repository.${plain}"
        before_show_menu
        return
    fi
    
    echo -e "Current version: ${green}${version}${plain}"
    echo -e "${yellow}Available versions:${plain}"
    for i in "${!latest_versions[@]}"; do
        echo -e "$((i+1)). ${green}${latest_versions[$i]}${plain}"
    done
    
    echo ""
    read -p "Select a version to update to (1-${#latest_versions[@]}, default 1): " version_number
    
    if [[ -z "$version_number" ]]; then
        version_number=1
    fi
    
    if ! [[ "$version_number" =~ ^[0-9]+$ ]] || [[ "$version_number" -lt 1 ]] || [[ "$version_number" -gt ${#latest_versions[@]} ]]; then
        echo -e "${red}Invalid input. Using the latest version (1).${plain}"
        version_number=1
    fi
    
    selected_version="${latest_versions[$((version_number-1))]}"
    echo -e "Selected version: ${green}${selected_version}${plain}"
    
    confirm "Update to v${selected_version}? [y/n]" "n"
    if [[ $? == 0 ]]; then
        install_x-ui "${selected_version}"
    fi
}

uninstall() {
    confirm "$UNINSTALL_CONFIRM" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop x-ui
    systemctl disable x-ui
    rm /etc/systemd/system/x-ui.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/x-ui/ -rf
    rm /usr/local/x-ui/ -rf

    echo ""
    echo -e "$UNINSTALL_SUCCESS"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

reset_user() {
    confirm "$RESET_USER_CONFIRM" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -username admin -password admin
    echo -e "$RESET_USER_SUCCESS"
    confirm_restart
}

reset_config() {
    confirm "$RESET_CONFIG_CONFIRM" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    /usr/local/x-ui/x-ui setting -reset
    echo -e "$RESET_CONFIG_SUCCESS"
    confirm_restart
}

check_config() {
    info=$(/usr/local/x-ui/x-ui setting -show true)
    if [[ $? != 0 ]]; then
        LOGE "$CHECK_CONFIG_ERROR"
        show_menu
    fi
    LOGI "${info}"
}

set_port() {
    echo && echo -n -e "$SET_PORT_TITLE: " && read port
    if [[ -z "${port}" ]]; then
        LOGD "$SET_PORT_CANCEL"
        before_show_menu
    else
        /usr/local/x-ui/x-ui setting -port ${port}
        echo -e $(printf "$SET_PORT_SUCCESS" "${green}${port}${plain}")
        confirm_restart
    fi
}

switch_language() {
    echo -e "$MENU_LANG_TITLE"
    echo -e "$MENU_LANG_EN"
    echo -e "$MENU_LANG_CN"
    echo -e "$MENU_LANG_HK"
    read -p "$MENU_LANG_CHOICE: " choice
    case $choice in
        1)
            /usr/local/x-ui/x-ui setting -language en_US
            echo -e $(printf "$MENU_LANG_CHANGED" "English")
            ;;
        2)
            /usr/local/x-ui/x-ui setting -language zh_Hans
            echo -e $(printf "$MENU_LANG_CHANGED" "简体中文")
            ;;
        3)
            /usr/local/x-ui/x-ui setting -language zh_Hant
            echo -e $(printf "$MENU_LANG_CHANGED" "繁體中文")
            ;;
        *)
            echo -e "Invalid option, no changes made"
            ;;
    esac
    load_language
    show_menu
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        LOGI "$START_PANEL_ALREADY"
    else
        systemctl start x-ui
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            LOGI "$START_PANEL_SUCCESS"
        else
            LOGE "Failed to start x-ui"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    check_status
    if [[ $? == 1 ]]; then
        echo ""
        LOGI "$STOP_PANEL_ALREADY"
    else
        systemctl stop x-ui
        sleep 2
        check_status
        if [[ $? == 1 ]]; then
            LOGI "$STOP_PANEL_SUCCESS"
        else
            LOGE "Failed to stop x-ui"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart x-ui
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        LOGI "$RESTART_PANEL_SUCCESS"
    else
        LOGE "Failed to restart x-ui"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status x-ui -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable x-ui
    if [[ $? == 0 ]]; then
        LOGI "$ENABLE_AUTOSTART_SUCCESS"
    else
        LOGE "Failed to enable x-ui auto-start"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable x-ui
    if [[ $? == 0 ]]; then
        LOGI "$DISABLE_AUTOSTART_SUCCESS"
    else
        LOGE "Failed to disable x-ui auto-start"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u x-ui.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

migrate_v2_ui() {
    /usr/local/x-ui/x-ui v2-ui

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    # temporary workaround for installing bbr
    bash <(curl -L -s https://raw.githubusercontent.com/teddysun/across/master/bbr.sh)
    echo ""
    before_show_menu
}

update_shell() {
    wget -O /usr/bin/x-ui -N --no-check-certificate https://github.com/vaxilu/x-ui/raw/master/x-ui.sh
    if [[ $? != 0 ]]; then
        echo ""
        LOGE "Failed to download script, please check if your server can connect to Github"
        before_show_menu
    else
        chmod +x /usr/bin/x-ui
        LOGI "Script upgraded successfully, please run the script again" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    status=$(systemctl status x-ui | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${status}" == "running" ]]; then
        return 0
    else
        return 1
    fi
}

check_enabled() {
    temp=$(systemctl is-enabled x-ui)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        LOGE "面板已安装，请不要重复安装"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        LOGE "请先安装面板"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "$CHECK_PANEL_STATUS: ${green}$CHECK_PANEL_RUNNING${plain}"
            show_enable_status
            ;;
        1)
            echo -e "$CHECK_PANEL_STATUS: ${red}$CHECK_PANEL_STOPPED${plain}"
            show_enable_status
            ;;
    esac
    show_xray_status
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Auto-start when booting: ${green}Yes${plain}"
    else
        echo -e "Auto-start when booting: ${red}No${plain}"
    fi
}

check_xray_status() {
    count=$(ps -ef | grep "xray-linux" | grep -v "grep" | wc -l)
    if [[ count -ne 0 ]]; then
        return 0
    else
        return 1
    fi
}

show_xray_status() {
    status=$(systemctl status x-ui | grep "Active:" | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ "${status}" == "running" ]]; then
        echo -e "$CHECK_PANEL_INFO: ${cyan}v${plain}${red}${version}${plain}"
        echo -e "$CHECK_PANEL_PORT: ${red}${port}${plain}"
    else
        echo -e "$CHECK_PANEL_ERROR"
    fi
}

ssl_cert_issue() {
    echo -E ""
    LOGD "******使用说明******"
    LOGI "该脚本将使用Acme脚本申请证书,使用时需保证:"
    LOGI "1.知晓Cloudflare 注册邮箱"
    LOGI "2.知晓Cloudflare Global API Key"
    LOGI "3.域名已通过Cloudflare进行解析到当前服务器"
    LOGI "4.该脚本申请证书默认安装路径为/root/cert目录"
    confirm "我已确认以上内容[y/n]" "y"
    if [ $? -eq 0 ]; then
        cd ~
        LOGI "安装Acme脚本"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            LOGE "安装acme脚本失败"
            exit 1
        fi
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        LOGD "请设置域名:"
        read -p "Input your domain here:" CF_Domain
        LOGD "你的域名设置为:${CF_Domain}"
        LOGD "请设置API密钥:"
        read -p "Input your key here:" CF_GlobalKey
        LOGD "你的API密钥为:${CF_GlobalKey}"
        LOGD "请设置注册邮箱:"
        read -p "Input your email here:" CF_AccountEmail
        LOGD "你的注册邮箱为:${CF_AccountEmail}"
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            LOGE "修改默认CA为Lets'Encrypt失败,脚本退出"
            exit 1
        fi
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            LOGE "证书签发失败,脚本退出"
            exit 1
        else
            LOGI "证书签发成功,安装中..."
        fi
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
        --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            LOGE "证书安装失败,脚本退出"
            exit 1
        else
            LOGI "证书安装成功,开启自动更新..."
        fi
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            LOGE "自动更新设置失败,脚本退出"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            LOGI "证书已安装且已开启自动更新,具体信息如下"
            ls -lah cert
            chmod 755 $certPath
        fi
    else
        show_menu
    fi
}

show_usage() {
    echo "x-ui management script usage: "
    echo "------------------------------------------"
    echo "x-ui              - Show management menu"
    echo "x-ui start        - Start x-ui panel"
    echo "x-ui stop         - Stop x-ui panel"
    echo "x-ui restart      - Restart x-ui panel"
    echo "x-ui status       - View x-ui status"
    echo "x-ui enable       - Set x-ui to start on boot"
    echo "x-ui disable      - Disable x-ui auto-start"
    echo "x-ui log          - View x-ui logs"
    echo "x-ui v2-ui        - Migrate v2-ui account data to x-ui"
    echo "x-ui update       - Update x-ui panel"
    echo "x-ui install      - Install x-ui panel"
    echo "x-ui uninstall    - Uninstall x-ui panel"
    echo "------------------------------------------"
}

show_menu() {
    local curr_lang=$(get_current_language)
    local lang_display="English"
    if [ "$curr_lang" = "zh_Hans" ]; then
        lang_display="简体中文"
    elif [ "$curr_lang" = "zh_Hant" ]; then
        lang_display="繁體中文"
    fi
    
    echo -e "
  ${green}$MENU_TITLE${plain}
  ${green}$(printf "$MENU_INFO1" "${version}")${plain}
  ${green}$(printf "$MENU_INFO2" "${lang_display}")${plain}
  ——————————————
  ${green}0.${plain} $MENU_OPTION_EXIT
  ${green}1.${plain} $MENU_OPTION_INSTALL
  ${green}2.${plain} $MENU_OPTION_UPDATE
  ${green}3.${plain} $MENU_OPTION_UNINSTALL
  ——————————————
  ${green}4.${plain} $MENU_OPTION_START
  ${green}5.${plain} $MENU_OPTION_STOP
  ${green}6.${plain} $MENU_OPTION_RESTART
  ${green}7.${plain} $MENU_OPTION_STATUS
  ${green}8.${plain} $MENU_OPTION_VIEW_LOG
  ——————————————
  ${green}9.${plain} $MENU_OPTION_ENABLE_AUTOSTART
  ${green}10.${plain} $MENU_OPTION_DISABLE_AUTOSTART
  ${green}11.${plain} $MENU_OPTION_SET_PORT
  ${green}12.${plain} $MENU_OPTION_LANG
  ——————————————
  ${green}13.${plain} $MENU_OPTION_RESET_USER
  ${green}14.${plain} $MENU_OPTION_RESET_CONFIG
  ${green}15.${plain} $MENU_OPTION_SHOW_CONFIG
  ——————————————
  ${green}16.${plain} $MENU_OPTION_MIGRATE
 "
    show_status
    echo && read -p "$MENU_CHOICE [0-16]: " num

    case "${num}" in
        0) exit 0
        ;;
        1) install
        ;;
        2) update
        ;;
        3) uninstall
        ;;
        4) start
        ;;
        5) stop
        ;;
        6) restart
        ;;
        7) status
        ;;
        8) show_log
        ;;
        9) enable
        ;;
        10) disable
        ;;
        11) set_port
        ;;
        12) switch_language
        ;;
        13) reset_user
        ;;
        14) reset_config
        ;;
        15) check_config
        ;;
        16) migrate_v2_ui
        ;;
        *) echo -e "${red}Please enter a valid number [0-16]${plain}"
        ;;
    esac
}

main() {
    get_version
    get_port
    
    if [[ ! -f /etc/systemd/system/x-ui.service ]]; then
        version="v1.0.0"
    fi
    
    if [[ $# > 0 ]]; then
        case $1 in
            "start") start 0
            ;;
            "stop") stop 0
            ;;
            "restart") restart 0
            ;;
            "status") status 0
            ;;
            "enable") enable 0
            ;;
            "disable") disable 0
            ;;
            "log") show_log 0
            ;;
            "v2-ui") migrate_v2_ui 0
            ;;
            "update") update 0
            ;;
            "install") install 0
            ;;
            "uninstall") uninstall 0
            ;;
            *) show_usage
        esac
    else
        show_menu
    fi
}

main "$@"
