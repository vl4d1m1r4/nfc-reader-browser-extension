#!/bin/bash

# NFC Reader Host - macOS Uninstallation Script

set -e

echo "NFC Reader Host - macOS Uninstallation"
echo "======================================="
echo ""

# Variables
APP_PATH="/Applications/nfc-reader-host.app"
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
EDGE_DIR="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
FIREFOX_DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"

# Remove app bundle
if [ -d "$APP_PATH" ]; then
    echo "Removing app bundle (requires sudo)..."
    sudo rm -rf "$APP_PATH"
    echo "✓ App bundle removed"
else
    echo "App bundle not found (already removed?)"
fi

# Remove Chrome manifest
if [ -f "$CHROME_DIR/info.nfcreader.host.json" ]; then
    rm "$CHROME_DIR/info.nfcreader.host.json"
    echo "✓ Chrome manifest removed"
fi

# Remove Edge manifest
if [ -f "$EDGE_DIR/info.nfcreader.host.json" ]; then
    rm "$EDGE_DIR/info.nfcreader.host.json"
    echo "✓ Edge manifest removed"
fi

# Remove Firefox manifest
if [ -f "$FIREFOX_DIR/info.nfcreader.host.json" ]; then
    rm "$FIREFOX_DIR/info.nfcreader.host.json"
    echo "✓ Firefox manifest removed"
fi

echo ""
echo "Uninstallation complete!"
echo "You may need to restart your browser."
echo ""
