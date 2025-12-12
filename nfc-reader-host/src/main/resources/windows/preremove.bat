@echo off
REM Windows uninstall script for native messaging manifests
REM This is called by the MSI/EXE installer during uninstallation

setlocal EnableDelayedExpansion

echo Removing native messaging manifests...

REM Chrome/Edge manifest registry keys
set CHROME_KEY=HKEY_CURRENT_USER\SOFTWARE\Google\Chrome\NativeMessagingHosts\info.nfcreader.host
set EDGE_KEY=HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host

REM Manifest directories
set MANIFEST_DIR=%LOCALAPPDATA%\NFCReader
set FIREFOX_DIR=%APPDATA%\Mozilla\NativeMessagingHosts

REM Remove Chrome registry key
reg delete "%CHROME_KEY%" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Chrome manifest registry entry removed
) else (
    echo [INFO] Chrome manifest registry entry not found
)

REM Remove Edge registry key
reg delete "%EDGE_KEY%" /f >nul 2>&1
if %errorLevel% EQU 0 (
    echo [OK] Edge manifest registry entry removed
) else (
    echo [INFO] Edge manifest registry entry not found
)

REM Remove manifest files
if exist "%MANIFEST_DIR%\info.nfcreader.host.json" (
    del /f /q "%MANIFEST_DIR%\info.nfcreader.host.json" >nul 2>&1
    echo [OK] Chrome/Edge manifest file removed
)

if exist "%FIREFOX_DIR%\info.nfcreader.host.json" (
    del /f /q "%FIREFOX_DIR%\info.nfcreader.host.json" >nul 2>&1
    echo [OK] Firefox manifest file removed
)

REM Remove manifest directory if empty
if exist "%MANIFEST_DIR%" (
    rmdir "%MANIFEST_DIR%" >nul 2>&1
)

echo.
echo Native messaging manifests removed successfully

exit /b 0
