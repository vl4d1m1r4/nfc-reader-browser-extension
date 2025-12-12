#!/bin/bash

# NFC Reader Host - macOS Installation Script
# This script installs the native messaging host for Chrome, Edge, and Firefox

set -e

echo "NFC Reader Host - macOS Installation"
echo "====================================="
echo ""

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="nfc-reader-host.app"
BINARY_NAME="nfc-reader-host"
INSTALL_DIR="/Applications"
APP_PATH="$INSTALL_DIR/$APP_NAME"
BINARY_PATH="$APP_PATH/Contents/MacOS/$BINARY_NAME"

# Chrome/Edge paths
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
EDGE_DIR="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"

# Firefox path
FIREFOX_DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"

# Check if jpackage app bundle exists
if [ ! -d "$SCRIPT_DIR/../../nfc-reader-host/target/jpackage/$APP_NAME" ]; then
    echo "Error: jpackage application bundle not found!"
    echo "Please build the project first:"
    echo "  cd ../.. && ./build.sh"
    exit 1
fi

echo "Step 1: Installing app bundle to $INSTALL_DIR"

# Remove old installation if exists
if [ -d "$APP_PATH" ]; then
    echo "Removing previous installation..."
    sudo rm -rf "$APP_PATH"
fi

# Copy entire app bundle to /Applications
sudo cp -R "$SCRIPT_DIR/../../nfc-reader-host/target/jpackage/$APP_NAME" "$APP_PATH"

echo "✓ Self-contained app bundle installed to $APP_PATH"
echo ""

# Note about code signing
echo "Note: On macOS, you may need to allow the binary to run:"
echo "  System Preferences > Security & Privacy > General"
echo "  Click 'Allow' when prompted about nfc-reader-host"
echo ""

# Get extension ID from user (for Chrome/Edge)
echo "Step 2: Extension ID Configuration"
echo "To install for Chrome/Edge, you need the extension ID."
echo "You can find it at chrome://extensions/ after loading the unpacked extension."
echo ""
read -p "Enter Chrome/Edge extension ID (or press Enter to skip): " EXTENSION_ID

if [ -n "$EXTENSION_ID" ]; then
    # Create Chrome manifest with correct binary path
    echo "Installing Chrome/Edge manifests..."
    
    # Chrome
    mkdir -p "$CHROME_DIR"
    sed "s|EXTENSION_ID_PLACEHOLDER|$EXTENSION_ID|g" "$SCRIPT_DIR/info.nfcreader.host.json" | \
        sed "s|/usr/local/bin/nfc-reader-host|$BINARY_PATH|g" > "$CHROME_DIR/info.nfcreader.host.json"
    echo "✓ Chrome manifest installed"
    
    # Edge
    mkdir -p "$EDGE_DIR"
    sed "s|EXTENSION_ID_PLACEHOLDER|$EXTENSION_ID|g" "$SCRIPT_DIR/info.nfcreader.host.json" | \
        sed "s|/usr/local/bin/nfc-reader-host|$BINARY_PATH|g" > "$EDGE_DIR/info.nfcreader.host.json"
    echo "✓ Edge manifest installed"
else
    echo "Skipping Chrome/Edge installation"
fi

echo ""

# Firefox
echo "Step 3: Firefox Installation"
read -p "Install for Firefox? (y/n): " INSTALL_FIREFOX

if [ "$INSTALL_FIREFOX" = "y" ] || [ "$INSTALL_FIREFOX" = "Y" ]; then
    mkdir -p "$FIREFOX_DIR"
    sed "s|/usr/local/bin/nfc-reader-host|$BINARY_PATH|g" "$SCRIPT_DIR/nfcreader.json" > "$FIREFOX_DIR/info.nfcreader.host.json"
    echo "✓ Firefox manifest installed"
fi

echo ""
echo "====================================="
echo "Installation Complete!"
echo "====================================="
echo ""
echo "Installed locations:"
echo "  App Bundle: $APP_PATH"
echo "  Executable: $BINARY_PATH"
if [ -n "$EXTENSION_ID" ]; then
    echo "  Chrome: $CHROME_DIR/info.nfcreader.host.json"
    echo "  Edge: $EDGE_DIR/info.nfcreader.host.json"
fi
if [ "$INSTALL_FIREFOX" = "y" ] || [ "$INSTALL_FIREFOX" = "Y" ]; then
    echo "  Firefox: $FIREFOX_DIR/nfcreader.json"
fi
echo ""
echo "IMPORTANT: macOS Security"
echo "When you first run the extension, macOS may block the binary."
echo "Go to: System Preferences > Security & Privacy > General"
echo "Click 'Allow' next to the message about nfc-reader-host"
echo ""
echo "Next steps:"
echo "  1. Restart your browser"
echo "  2. Load the browser extension"
echo "  3. Allow the binary in System Preferences if prompted"
echo "  4. Test the NFC reader functionality"
echo ""
echo "To verify installation:"
echo "  \"$BINARY_PATH\" list-readers"
echo ""
