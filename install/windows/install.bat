@echo off
REM NFC Reader Host - Windows Installation Script
REM This script installs the native messaging host for Chrome, Edge, and Firefox
REM Run as Administrator

echo NFC Reader Host - Windows Installation
echo =====================================
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
set BINARY_NAME=nfc-reader-host.exe
set BINARY_PATH=%INSTALL_DIR%\%BINARY_NAME%

REM Check if binary exists
if not exist "..\..\nfc-reader-host\target\%BINARY_NAME%" (
    echo Error: Native host binary not found!
    echo Please build the native image first using GraalVM on Windows.
    pause
    exit /b 1
)

echo Step 1: Installing binary to %INSTALL_DIR%
echo.

REM Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

REM Copy binary
copy /Y "..\..\nfc-reader-host\target\%BINARY_NAME%" "%BINARY_PATH%" >nul
if %errorLevel% NEQ 0 (
    echo Error: Failed to copy binary
    pause
    exit /b 1
)

echo [OK] Binary installed to %BINARY_PATH%
echo.

REM Get extension ID
echo Step 2: Extension ID Configuration
echo To install for Chrome/Edge, you need the extension ID.
echo You can find it at chrome://extensions/ after loading the unpacked extension.
echo.
set /p EXTENSION_ID="Enter Chrome/Edge extension ID (or press Enter to skip): "

if not "%EXTENSION_ID%"=="" (
    echo Installing Chrome/Edge manifests...
    echo.
    
    REM Create Chrome manifest with extension ID
    powershell -Command "(Get-Content 'info.nfcreader.host.json') -replace 'EXTENSION_ID_PLACEHOLDER', '%EXTENSION_ID%' | Set-Content '%TEMP%\info.nfcreader.host.json'"
    
    REM Chrome registry
    reg add "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\info.nfcreader.host" /ve /t REG_SZ /d "%TEMP%\info.nfcreader.host.json" /f >nul 2>&1
    if %errorLevel% EQU 0 (
        echo [OK] Chrome manifest registered
    ) else (
        echo [SKIP] Chrome not found or already configured
    )
    
    REM Edge registry
    reg add "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host" /ve /t REG_SZ /d "%TEMP%\info.nfcreader.host.json" /f >nul 2>&1
    if %errorLevel% EQU 0 (
        echo [OK] Edge manifest registered
    ) else (
        echo [SKIP] Edge not found or already configured
    )
) else (
    echo Skipping Chrome/Edge installation
)

echo.

REM Firefox
set /p INSTALL_FIREFOX="Install for Firefox? (y/n): "

if /i "%INSTALL_FIREFOX%"=="y" (
    REM Firefox directory
    set FIREFOX_DIR=%APPDATA%\Mozilla\NativeMessagingHosts
    
    if not exist "!FIREFOX_DIR!" mkdir "!FIREFOX_DIR!"
    
    copy /Y "nfcreader.json" "!FIREFOX_DIR!\nfcreader.json" >nul
    if %errorLevel% EQU 0 (
        echo [OK] Firefox manifest installed
    ) else (
        echo [ERROR] Failed to install Firefox manifest
    )
)

echo.
echo =====================================
echo Installation Complete!
echo =====================================
echo.
echo Installed locations:
echo   Binary: %BINARY_PATH%

if not "%EXTENSION_ID%"=="" (
    echo   Chrome: Registry key created
    echo   Edge: Registry key created
)

if /i "%INSTALL_FIREFOX%"=="y" (
    echo   Firefox: %FIREFOX_DIR%\nfcreader.json
)

echo.
echo Next steps:
echo   1. Restart your browser
echo   2. Load the browser extension
echo   3. Test the NFC reader functionality
echo.
echo To verify installation:
echo   "%BINARY_PATH%" list-readers
echo.

pause
