# x-ui

A multi-protocol, multi-user Xray panel

# Features

- System status monitoring
- Support for multiple users and protocols with web-based visual operation
- Supported protocols: vmess, vless, trojan, shadowsocks, dokodemo-door, socks, http
- Support for configuring more transport options
- Traffic statistics, traffic limiting, and expiration time limit
- Customizable Xray configuration templates
- Support for HTTPS panel access (bring your own domain + SSL certificate)
- Support for one-click SSL certificate application and automatic renewal
- Multilingual support (English, Simplified Chinese, Traditional Chinese)
- More advanced configuration options available in the panel

# Language Settings

X-UI supports multiple languages:
- English (default)
- Simplified Chinese
- Traditional Chinese

You can change the language in one of the following ways:
1. During installation, select your preferred language
2. Use the command line: `x-ui setting -language [language_code]`
   - Available language codes: `en_US`, `zh_Hans`, `zh_Hant`
3. Switch language via the CLI menu: `x-ui`, then select "Switch language"

# Installation & Upgrade

```
bash <(curl -Ls https://raw.githubusercontent.com/ThePieOfSauron/x-ui/master/install.sh)
```

## Manual Installation & Upgrade

1. First, download the latest compressed package from https://github.com/ThePieOfSauron/x-ui/releases, usually choose the `amd64` architecture
2. Then upload this compressed package to the `/root/` directory of your server, and log in to the server using the `root` user

> If your server CPU architecture is not `amd64`, replace `amd64` in the command with your architecture

```
cd /root/
rm x-ui/ /usr/local/x-ui/ /usr/bin/x-ui -rf
tar zxvf x-ui-linux-amd64.tar.gz
chmod +x x-ui/x-ui x-ui/bin/xray-linux-* x-ui/x-ui.sh
cp x-ui/x-ui.sh /usr/bin/x-ui
cp -f x-ui/x-ui.service /etc/systemd/system/
mv x-ui/ /usr/local/
systemctl daemon-reload
systemctl enable x-ui
systemctl restart x-ui
```

## Docker Installation

> This docker tutorial and docker image are provided by [Chasing66](https://github.com/Chasing66)

1. Install docker

```shell
curl -fsSL https://get.docker.com | sh
```

2. Install x-ui

```shell
mkdir x-ui && cd x-ui
docker run -itd --network=host \
    -v $PWD/db/:/etc/x-ui/ \
    -v $PWD/cert/:/root/cert/ \
    --name x-ui --restart=unless-stopped \
    enwaiax/x-ui:latest
```

> Build your own image

```shell
docker build -t x-ui .
```

## SSL Certificate Application

> This feature and tutorial are provided by [FranzKafkaYu](https://github.com/FranzKafkaYu)

The script has a built-in SSL certificate application feature. To use this script to apply for a certificate, the following conditions must be met:

- Know your Cloudflare registered email
- Know your Cloudflare Global API Key
- The domain has been resolved to the current server through Cloudflare

Method to obtain Cloudflare Global API Key:
    ![](media/bda84fbc2ede834deaba1c173a932223.png)
    ![](media/d13ffd6a73f938d1037d0708e31433bf.png)

When using, simply enter the `domain`, `email`, and `API KEY`, as shown in the diagram below:
        ![](media/2022-04-04_141259.png)

Notes:

- This script uses DNS API for certificate application
- Let's Encrypt is used as the default CA
- The certificate installation directory is /root/cert
- All certificates applied using this script are wildcard domain certificates

## Telegram Bot Usage (In development, not yet available)

> This feature and tutorial are provided by [FranzKafkaYu](https://github.com/FranzKafkaYu)

X-UI supports daily traffic notifications, panel login alerts, and other features through a Telegram bot. To use the Telegram bot, you need to apply for one yourself.
For a specific application tutorial, you can refer to [blog link](https://coderfan.net/how-to-use-telegram-bot-to-alarm-you-when-someone-login-into-your-vps.html)
Usage instructions: Set the bot-related parameters in the panel backend, specifically including:

- Telegram bot Token
- Telegram bot ChatId
- Telegram bot periodic run time, using crontab syntax  

Reference syntax:
- 30 * * * * * //Notify at the 30th second of every minute
- @hourly      //Hourly notification
- @daily       //Daily notification (at midnight)
- @every 8h    //Notification every 8 hours  

Telegram notification content:
- Node traffic usage
- Panel login alerts
- Node expiration reminders
- Traffic warning alerts  

More features are being planned...

## Recommended Systems

- CentOS 7+
- Ubuntu 16+
- Debian 8+

# Common Issues

## Migrating from v2-ui

First, install the latest version of x-ui on the server where v2-ui is installed, then use the following command to migrate. This will migrate `all inbound account data` from v2-ui on this machine to x-ui. `Panel settings and username/password will not be migrated`.

> After successful migration, please `close v2-ui` and `restart x-ui`, otherwise there will be `port conflicts` between v2-ui inbounds and x-ui inbounds.

```
x-ui v2-ui
```

## Issue Closed

Various basic questions lead to high blood pressure.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/vaxilu/x-ui.svg)](https://starchart.cc/vaxilu/x-ui)

## Release Management

### Automated Releases with GitHub CLI

We've added scripts to simplify the release process using GitHub CLI:

#### Prerequisites

- Install GitHub CLI: https://cli.github.com/
- Authenticate with `gh auth login`

#### For Windows Users

```powershell
# Make sure you've built the packages first
./package.sh  # or use WSL

# Then create and upload the release
./github_release.ps1
```

#### For Linux/macOS Users

```bash
# Make sure you've built the packages first
./package.sh

# Then create and upload the release
chmod +x github_release.sh
./github_release.sh
```

#### GitHub Actions

You can also trigger a release through GitHub Actions by:

1. Creating a tag with the version format `v0.3.3` and pushing it
2. Manually triggering the workflow from the Actions tab
