@echo off
REM Windows post-install script
REM This runs after the MSI/EXE installer completes

setlocal EnableDelayedExpansion

set INSTALL_DIR=%~1
if "%INSTALL_DIR%"=="" set INSTALL_DIR=C:\Program Files\NFC Reader Host

set BINARY_PATH=%INSTALL_DIR%\nfc-reader-host.exe
set MANIFEST_DIR=%LOCALAPPDATA%\NFCReader
set RESOURCE_DIR=%INSTALL_DIR%\app

echo Installing native messaging manifests...

REM Chrome/Edge manifest path (per-user)
set CHROME_KEY=HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\NativeMessagingHosts\info.nfcreader.host
set EDGE_KEY=HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host

REM Firefox manifest path (per-user)
set FIREFOX_KEY=HKEY_CURRENT_USER\SOFTWARE\Mozilla\NativeMessagingHosts\info.nfcreader.host
set FIREFOX_DIR=%APPDATA%\Mozilla\NativeMessagingHosts

REM Create manifest directory
if not exist "!MANIFEST_DIR!" mkdir "!MANIFEST_DIR!"

set MANIFEST_FILE=!MANIFEST_DIR!\info.nfcreader.host.json

REM Copy Chrome manifest template and update path
if exist "%RESOURCE_DIR%\info.nfcreader.host.json" (
    powershell -Command "(Get-Content '%RESOURCE_DIR%\info.nfcreader.host.json') -replace 'C:\\\\Program Files\\\\NFCReader\\\\nfc-reader-host.exe', '%BINARY_PATH:\=\\%' | Set-Content '!MANIFEST_FILE!'"
) else (
    echo Warning: Manifest template not found at %RESOURCE_DIR%\info.nfcreader.host.json
    exit /b 1
)

REM Register Chrome manifest
reg add "%CHROME_KEY%" /ve /t REG_SZ /d "!MANIFEST_FILE!" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Chrome manifest registered
) else (
    echo [WARNING] Failed to register Chrome manifest
)

REM Register Edge manifest
reg add "%EDGE_KEY%" /ve /t REG_SZ /d "!MANIFEST_FILE!" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Edge manifest registered
) else (
    echo [WARNING] Failed to register Edge manifest
)

REM Create Firefox manifest directory
if not exist "!FIREFOX_DIR!" mkdir "!FIREFOX_DIR!"

set FIREFOX_MANIFEST=!FIREFOX_DIR!\info.nfcreader.host.json

REM Create Firefox manifest (convert allowed_origins to allowed_extensions)
powershell -Command "$content = (Get-Content '%RESOURCE_DIR%\info.nfcreader.host.json' -Raw) -replace 'C:\\\\Program Files\\\\NFCReader\\\\nfc-reader-host.exe', '%BINARY_PATH:\=\\%' -replace '\"allowed_origins\"', '\"allowed_extensions\"' -replace 'chrome-extension://([^/]+)/', '$1'; $content | Set-Content '!FIREFOX_MANIFEST!'"
echo   "type": "stdio",

if exist "!FIREFOX_MANIFEST!" (
    echo [OK] Firefox manifest created
) else (
    echo [WARNING] Failed to create Firefox manifest
)

REM Register Firefox manifest in registry
reg add "%FIREFOX_KEY%" /ve /t REG_SZ /d "!FIREFOX_MANIFEST!" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Firefox manifest registered in registry
) else (
    echo [WARNING] Failed to register Firefox manifest in registry
)

echo.
echo Native messaging manifests installed successfully
echo.
echo Manifest locations:
echo   - Chrome/Edge: !MANIFEST_FILE!
echo   - Firefox: !FIREFOX_MANIFEST!

exit /b 0
