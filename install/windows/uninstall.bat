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
set BINARY_PATH=%INSTALL_DIR%\nfc-reader-host.exe
set FIREFOX_DIR=%APPDATA%\Mozilla\NativeMessagingHosts

REM Remove binary and directory
if exist "%BINARY_PATH%" (
    echo Removing binary...
    del /F /Q "%BINARY_PATH%"
    rmdir "%INSTALL_DIR%" 2>nul
    echo [OK] Binary removed
) else (
    echo Binary not found (already removed?)
)

REM Remove Chrome registry key
reg delete "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.nfcreader.host" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Chrome manifest removed
)

REM Remove Edge registry key
reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.nfcreader.host" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Edge manifest removed
)

REM Remove Firefox manifest
if exist "%FIREFOX_DIR%\nfcreader.json" (
    del /F /Q "%FIREFOX_DIR%\nfcreader.json"
    echo [OK] Firefox manifest removed
)

REM Remove temp manifest file
if exist "%TEMP%\com.nfcreader.host.json" (
    del /F /Q "%TEMP%\com.nfcreader.host.json"
)

echo.
echo Uninstallation complete!
echo You may need to restart your browser.
echo.

pause
