#!/bin/bash

# NFC Reader Host - Linux Uninstallation Script

set -e

echo "NFC Reader Host - Linux Uninstallation"
echo "======================================="
echo ""

# Variables
INSTALL_DIR="/usr/local/lib/nfc-reader"
BINARY_SYMLINK="/usr/local/bin/nfc-reader-host"
CHROME_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
CHROMIUM_DIR="$HOME/.config/chromium/NativeMessagingHosts"
EDGE_DIR="$HOME/.config/microsoft-edge/NativeMessagingHosts"
FIREFOX_DIR="$HOME/.mozilla/native-messaging-hosts"

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing installation directory (requires sudo)..."
    sudo rm -rf "$INSTALL_DIR"
    echo "✓ Installation directory removed"
else
    echo "Installation directory not found (already removed?)"
fi

# Remove symlink
if [ -L "$BINARY_SYMLINK" ]; then
    echo "Removing symlink (requires sudo)..."
    sudo rm "$BINARY_SYMLINK"
    echo "✓ Symlink removed"
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
if [ -f "$FIREFOX_DIR/info.nfcreader.host.json" ]; then
    rm "$FIREFOX_DIR/info.nfcreader.host.json"
    echo "✓ Firefox manifest removed"
fi

echo ""
echo "Uninstallation complete!"
echo "You may need to restart your browser."
echo ""
