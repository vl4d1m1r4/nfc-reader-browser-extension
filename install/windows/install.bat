@echo off
setlocal enabledelayedexpansion
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
set JPACKAGE_DIR=nfc-reader-host
set INSTALL_DIR=C:\Program Files\NFCReader
set MANIFEST_DIR=%LOCALAPPDATA%\NFCReader
set BINARY_NAME=nfc-reader-host.exe
set BINARY_PATH=%INSTALL_DIR%\%BINARY_NAME%

REM Check if jpackage app exists
if not exist "..\..\nfc-reader-host\target\jpackage\%JPACKAGE_DIR%" (
    echo Error: jpackage application not found!
    echo Please build the project first:
    echo   cd ../.. ^&^& build.sh
    pause
    exit /b 1
)

echo Step 1: Installing self-contained application to %INSTALL_DIR%
echo.

REM Remove old installation if exists
if exist "%INSTALL_DIR%" (
    echo Removing previous installation...
    rd /s /q "%INSTALL_DIR%"
)

REM Create installation directory and copy entire jpackage directory
mkdir "%INSTALL_DIR%"
xcopy /E /I /Y "..\..\nfc-reader-host\target\jpackage\%JPACKAGE_DIR%\*" "%INSTALL_DIR%" >nul
if %errorLevel% NEQ 0 (
    echo Error: Failed to copy application files
    pause
    exit /b 1
)

echo [OK] Self-contained application installed to %INSTALL_DIR%
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
    
    REM Create manifest directory
    if not exist "!MANIFEST_DIR!" mkdir "!MANIFEST_DIR!"
    
    REM Create Chrome manifest with extension ID and correct binary path
    powershell -Command "(Get-Content 'info.nfcreader.host.json') -replace 'EXTENSION_ID_PLACEHOLDER', '%EXTENSION_ID%' -replace 'C:/Program Files/NFCReader/nfc-reader-host.exe', '%BINARY_PATH:\=/%' | Set-Content '!MANIFEST_DIR!\info.nfcreader.host.json'"
    
    REM Chrome registry
    reg add "HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\info.nfcreader.host" /ve /t REG_SZ /d "!MANIFEST_DIR!\info.nfcreader.host.json" /f >nul 2>&1
    if %errorLevel% EQU 0 (
        echo [OK] Chrome manifest registered
    ) else (
        echo [SKIP] Chrome not found or already configured
    )
    
    REM Edge registry
    reg add "HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host" /ve /t REG_SZ /d "!MANIFEST_DIR!\info.nfcreader.host.json" /f >nul 2>&1
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
    
    REM Update Firefox manifest with correct binary path
    powershell -Command "(Get-Content 'nfcreader.json') -replace 'C:/Program Files/NFCReader/nfc-reader-host.exe', '%BINARY_PATH:\=/%' | Set-Content '!FIREFOX_DIR!\info.nfcreader.host.json'"
    
    REM Firefox on Windows also needs registry key
    reg add "HKEY_CURRENT_USER\Software\Mozilla\NativeMessagingHosts\info.nfcreader.host" /ve /t REG_SZ /d "!FIREFOX_DIR!\info.nfcreader.host.json" /f >nul 2>&1
    
    if %errorLevel% EQU 0 (
        echo [OK] Firefox manifest installed and registry key created
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
    echo   Firefox: %FIREFOX_DIR%\info.nfcreader.host.json
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
