@echo off
REM Windows post-install script
REM This runs after the MSI/EXE installer completes

setlocal EnableDelayedExpansion

set INSTALL_DIR=%~1
if "%INSTALL_DIR%"=="" set INSTALL_DIR=C:\Program Files\NFC Reader Host

set BINARY_PATH=%INSTALL_DIR%\nfc-reader-host.exe

REM Get extension IDs from environment or use defaults
if "%CHROME_EXTENSION_ID%"=="" (
    set CHROME_EXT_ID=EXTENSION_ID_PLACEHOLDER
) else (
    set CHROME_EXT_ID=%CHROME_EXTENSION_ID%
)

if "%FIREFOX_EXTENSION_ID%"=="" (
    set FIREFOX_EXT_ID=nfc-reader@example.com
) else (
    set FIREFOX_EXT_ID=%FIREFOX_EXTENSION_ID%
)

echo Installing native messaging manifests...

REM Chrome/Edge manifest path (system-wide)
set CHROME_KEY=HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\NativeMessagingHosts\info.nfcreader.host
set EDGE_KEY=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host

REM Firefox manifest path (system-wide)
set FIREFOX_DIR=C:\ProgramData\Mozilla\NativeMessagingHosts
set FIREFOX_MANIFEST=%FIREFOX_DIR%\info.nfcreader.host.json

REM Create Chrome manifest JSON
set CHROME_MANIFEST_DIR=%INSTALL_DIR%\chrome-manifest
if not exist "%CHROME_MANIFEST_DIR%" mkdir "%CHROME_MANIFEST_DIR%"

set MANIFEST_FILE=%CHROME_MANIFEST_DIR%\info.nfcreader.host.json

REM Write Chrome/Edge manifest
(
echo {
echo   "name": "info.nfcreader.host",
echo   "description": "NFC Reader Native Messaging Host",
echo   "path": "%BINARY_PATH:\=\\%",
echo   "type": "stdio",
echo   "allowed_origins": [
echo     "chrome-extension://%CHROME_EXT_ID%/"
echo   ]
echo }
) > "%MANIFEST_FILE%"

REM Register Chrome manifest
reg add "%CHROME_KEY%" /ve /t REG_SZ /d "%MANIFEST_FILE%" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Chrome manifest registered
) else (
    echo [WARNING] Failed to register Chrome manifest
)

REM Register Edge manifest
reg add "%EDGE_KEY%" /ve /t REG_SZ /d "%MANIFEST_FILE%" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Edge manifest registered
) else (
    echo [WARNING] Failed to register Edge manifest
)

REM Create Firefox manifest directory
if not exist "%FIREFOX_DIR%" mkdir "%FIREFOX_DIR%"

REM Write Firefox manifest
(
echo {
echo   "name": "info.nfcreader.host",
echo   "description": "NFC Reader Native Messaging Host",
echo   "path": "%BINARY_PATH:\=\\%",
echo   "type": "stdio",
echo   "allowed_extensions": [
echo     "%FIREFOX_EXT_ID%"
echo   ]
echo }
) > "%FIREFOX_MANIFEST%"

if exist "%FIREFOX_MANIFEST%" (
    echo [OK] Firefox manifest created
) else (
    echo [WARNING] Failed to create Firefox manifest
)

echo.
echo Native messaging manifests installed successfully
echo.
echo IMPORTANT: Update the extension ID in:
echo   - Chrome/Edge: %MANIFEST_FILE%
echo   - Firefox: %FIREFOX_MANIFEST%
echo.
echo Replace EXTENSION_ID_PLACEHOLDER with your actual extension ID.

exit /b 0
