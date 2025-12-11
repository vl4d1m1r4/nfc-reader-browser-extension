#!/bin/bash

# NFC Reader Host - Linux Installation Script
# This script installs the native messaging host for Chrome/Chromium, Edge, and Firefox

set -e

echo "NFC Reader Host - Linux Installation"
echo "====================================="
echo ""

# Check if running as root (we don't want that for user-specific installations)
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this script as root/sudo for user installation."
    echo "If you want system-wide installation, modify the paths accordingly."
    exit 1
fi

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="nfc-reader-host"
JPACKAGE_DIR="nfc-reader-host"
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/nfc-reader"
WRAPPER_PATH="$INSTALL_DIR/$BINARY_NAME"

# Chrome/Chromium paths
CHROME_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
CHROMIUM_DIR="$HOME/.config/chromium/NativeMessagingHosts"
EDGE_DIR="$HOME/.config/microsoft-edge/NativeMessagingHosts"

# Firefox path
FIREFOX_DIR="$HOME/.mozilla/native-messaging-hosts"

# Check if jpackage app exists
if [ ! -d "$SCRIPT_DIR/../../nfc-reader-host/target/jpackage/$JPACKAGE_DIR" ]; then
    echo "Error: jpackage application not found!"
    echo "Please build the project first:"
    echo "  cd .. && ./build-linux.sh"
    exit 1
fi

echo "Step 1: Installing to $LIB_DIR"
echo "This step requires sudo privileges..."

# Copy entire jpackage directory
sudo mkdir -p "$LIB_DIR"
sudo cp -r "$SCRIPT_DIR/../../nfc-reader-host/target/jpackage/$JPACKAGE_DIR" "$LIB_DIR/"

# Create symlink to binary
sudo ln -sf "$LIB_DIR/$JPACKAGE_DIR/bin/$BINARY_NAME" "$WRAPPER_PATH"

echo "✓ Self-contained application installed to $LIB_DIR/$JPACKAGE_DIR"
echo "✓ Symlink created at $WRAPPER_PATH"
echo ""

# Get extension ID from user (for Chrome/Edge)
echo "Step 2: Extension ID Configuration"
echo "To install for Chrome/Edge, you need the extension ID."
echo "You can find it at chrome://extensions/ after loading the unpacked extension."
echo ""
read -p "Enter Chrome/Edge extension ID (or press Enter to skip): " EXTENSION_ID

if [ -n "$EXTENSION_ID" ]; then
    # Create Chrome manifest
    echo "Installing Chrome/Chromium/Edge manifests..."
    
    # Chrome
    mkdir -p "$CHROME_DIR"
    sed "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/g" "$SCRIPT_DIR/info.nfcreader.host.json" > "$CHROME_DIR/info.nfcreader.host.json"
    echo "✓ Chrome manifest installed"
    
    # Chromium
    mkdir -p "$CHROMIUM_DIR"
    sed "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/g" "$SCRIPT_DIR/info.nfcreader.host.json" > "$CHROMIUM_DIR/info.nfcreader.host.json"
    echo "✓ Chromium manifest installed"
    
    # Edge
    mkdir -p "$EDGE_DIR"
    sed "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/g" "$SCRIPT_DIR/info.nfcreader.host.json" > "$EDGE_DIR/info.nfcreader.host.json"
    echo "✓ Edge manifest installed"
else
    echo "Skipping Chrome/Edge installation"
fi

echo ""

# Firefox
echo "Step 3: Firefox Installation"
read -p "Install for Firefox? (y/n): " INSTALL_FIREFOX

if [ "$INSTALL_FIREFOX" = "y" ] || [ "$INSTALL_FIREFOX" = "Y" ]; then
    echo ""
    echo "For Firefox, you need the extension ID from the manifest."
    echo "Default is: nfc@nfcreader.info"
    read -p "Enter Firefox extension ID (or press Enter for default): " FIREFOX_EXTENSION_ID
    
    if [ -z "$FIREFOX_EXTENSION_ID" ]; then
        FIREFOX_EXTENSION_ID="nfc@nfcreader.info"
    fi
    
    mkdir -p "$FIREFOX_DIR"
    sed "s/nfc@nfcreader.info/$FIREFOX_EXTENSION_ID/g" "$SCRIPT_DIR/nfcreader.json" > "$FIREFOX_DIR/info.nfcreader.host.json"
    echo "✓ Firefox manifest installed with extension ID: $FIREFOX_EXTENSION_ID"
fi

echo ""
echo "====================================="
echo "Installation Complete!"
echo "====================================="
echo ""
echo "Installed locations:"
echo "  Application: $LIB_DIR/$JPACKAGE_DIR"
echo "  Binary: $WRAPPER_PATH"
if [ -n "$EXTENSION_ID" ]; then
    echo "  Chrome: $CHROME_DIR/info.nfcreader.host.json"
    echo "  Chromium: $CHROMIUM_DIR/info.nfcreader.host.json"
    echo "  Edge: $EDGE_DIR/info.nfcreader.host.json"
fi
if [ "$INSTALL_FIREFOX" = "y" ] || [ "$INSTALL_FIREFOX" = "Y" ]; then
    echo "  Firefox: $FIREFOX_DIR/info.nfcreader.host.json"
fi
echo ""
echo "Next steps:"
echo "  1. Restart your browser"
echo "  2. Load the browser extension"
echo "  3. Test the NFC reader functionality"
echo ""
echo "To verify installation:"
echo "  $BINARY_NAME list-readers"
echo ""
