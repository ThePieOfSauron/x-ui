@echo off
setlocal enabledelayedexpansion

REM Script to build and package x-ui for Windows
echo Packaging x-ui for Windows...

REM Set Go proxy to bypass potential network restrictions
set GOPROXY=https://goproxy.io,direct

REM Get version number (hardcoded to 0.3.2 for simplicity)
set VERSION=0.3.2

echo Building x-ui version %VERSION% for Windows...

REM Build the binary
"C:\Program Files\Go\bin\go.exe" build -o xui-release.exe -v main.go

REM Create package directory and structure
if exist x-ui rmdir /s /q x-ui
mkdir x-ui
copy xui-release.exe x-ui\xui-release.exe
cd x-ui
ren xui-release.exe x-ui.exe
mkdir bin
cd bin

REM Download Xray and geo files
echo Downloading Xray for Windows...
powershell -Command "Invoke-WebRequest -Uri https://github.com/XTLS/Xray-core/releases/latest/download/Xray-windows-64.zip -OutFile Xray-windows-64.zip"
powershell -Command "Expand-Archive -Path Xray-windows-64.zip -DestinationPath ."
del Xray-windows-64.zip
del geoip.dat
del geosite.dat

echo Downloading geo files...
powershell -Command "Invoke-WebRequest -Uri https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -OutFile geoip.dat"
powershell -Command "Invoke-WebRequest -Uri https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -OutFile geosite.dat"

REM Rename xray binary
ren xray.exe xray-windows-amd64.exe

REM Return to root
cd ..
cd ..

REM Create package directory and name
set PKG_NAME=x-ui-windows-amd64-%VERSION%

REM Create releases directory
if not exist releases mkdir releases

REM Create the ZIP archive
echo Creating archive for Windows...
powershell -Command "Compress-Archive -Path 'x-ui' -DestinationPath '%PKG_NAME%.zip'"
move %PKG_NAME%.zip releases\

REM Cleanup
rmdir /s /q x-ui
del xui-release.exe 2>nul

echo Package for Windows completed: releases\%PKG_NAME%.zip
echo.
echo Package created successfully in the 'releases' directory. 