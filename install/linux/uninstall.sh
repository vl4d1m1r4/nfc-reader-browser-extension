#!/bin/bash

# NFC Reader Host - Linux Uninstallation Script

set -e

echo "NFC Reader Host - Linux Uninstallation"
echo "======================================="
echo ""

# Variables
BINARY_PATH="/usr/local/bin/nfc-reader-host"
CHROME_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
CHROMIUM_DIR="$HOME/.config/chromium/NativeMessagingHosts"
EDGE_DIR="$HOME/.config/microsoft-edge/NativeMessagingHosts"
FIREFOX_DIR="$HOME/.mozilla/native-messaging-hosts"

# Remove binary
if [ -f "$BINARY_PATH" ]; then
    echo "Removing binary (requires sudo)..."
    sudo rm "$BINARY_PATH"
    echo "✓ Binary removed"
else
    echo "Binary not found (already removed?)"
fi

# Remove Chrome manifest
if [ -f "$CHROME_DIR/info.nfcreader.host.json" ]; then
    rm "$CHROME_DIR/info.nfcreader.host.json"
    echo "✓ Chrome manifest removed"
fi

# Remove Chromium manifest
if [ -f "$CHROMIUM_DIR/info.nfcreader.host.json" ]; then
    rm "$CHROMIUM_DIR/info.nfcreader.host.json"
    echo "✓ Chromium manifest removed"
fi

# Remove Edge manifest
if [ -f "$EDGE_DIR/info.nfcreader.host.json" ]; then
    rm "$EDGE_DIR/info.nfcreader.host.json"
    echo "✓ Edge manifest removed"
fi

# Remove Firefox manifest
if [ -f "$FIREFOX_DIR/nfcreader.json" ]; then
    rm "$FIREFOX_DIR/nfcreader.json"
    echo "✓ Firefox manifest removed"
fi

echo ""
echo "Uninstallation complete!"
echo "You may need to restart your browser."
echo ""
