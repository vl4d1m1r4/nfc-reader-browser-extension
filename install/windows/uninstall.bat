@echo off
REM NFC Reader Host - Windows Uninstallation Script
REM Run as Administrator

echo NFC Reader Host - Windows Uninstallation
echo =========================================
echo.

REM Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Error: This script requires Administrator privileges.
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

REM Variables
set INSTALL_DIR=C:\Program Files\NFCReader
set MANIFEST_DIR=%LOCALAPPDATA%\NFCReader
set FIREFOX_DIR=%APPDATA%\Mozilla\NativeMessagingHosts

REM Remove entire installation directory
if exist "%INSTALL_DIR%" (
    echo Removing installation directory...
    rd /s /q "%INSTALL_DIR%"
    echo [OK] Installation directory removed
) else (
    echo Installation directory not found (already removed?)
)

REM Remove manifest directory
if exist "%MANIFEST_DIR%" (
    echo Removing manifest directory...
    rd /s /q "%MANIFEST_DIR%"
    echo [OK] Manifest directory removed
)

REM Remove Chrome registry key
reg delete "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\info.nfcreader.host" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Chrome manifest removed
)

REM Remove Edge registry key
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Edge manifest removed
)

REM Remove Firefox manifest
if exist "%FIREFOX_DIR%\info.nfcreader.host.json" (
    del /F /Q "%FIREFOX_DIR%\info.nfcreader.host.json"
    echo [OK] Firefox manifest removed
)

REM Remove Firefox registry key
reg delete "HKEY_CURRENT_USER\Software\Mozilla\NativeMessagingHosts\info.nfcreader.host" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Firefox registry key removed
)

echo.
echo Uninstallation complete!
echo You may need to restart your browser.
echo.

pause
