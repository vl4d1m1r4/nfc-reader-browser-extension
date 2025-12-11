#!/bin/bash

# NFC Reader Host - macOS Installation Script
# This script installs the native messaging host for Chrome, Edge, and Firefox

set -e

echo "NFC Reader Host - macOS Installation"
echo "====================================="
echo ""

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="nfc-reader-host"
INSTALL_DIR="/usr/local/bin"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"

# Chrome/Edge paths
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
EDGE_DIR="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"

# Firefox path
FIREFOX_DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"

# Check if binary exists
if [ ! -f "$SCRIPT_DIR/../../nfc-reader-host/target/$BINARY_NAME" ]; then
    echo "Error: Native host binary not found!"
    echo "Please build the native image first:"
    echo "  cd ../nfc-reader-host"
    echo "  mvn clean package -Pnative"
    exit 1
fi

echo "Step 1: Installing binary to $INSTALL_DIR"

# Create /usr/local/bin if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR"
fi

# Copy binary to /usr/local/bin
sudo cp "$SCRIPT_DIR/../../nfc-reader-host/target/$BINARY_NAME" "$BINARY_PATH"
sudo chmod +x "$BINARY_PATH"

echo "✓ Binary installed to $BINARY_PATH"
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
    # Create Chrome manifest
    echo "Installing Chrome/Edge manifests..."
    
    # Chrome
    mkdir -p "$CHROME_DIR"
    sed "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/g" "$SCRIPT_DIR/com.nfcreader.host.json" > "$CHROME_DIR/com.nfcreader.host.json"
    echo "✓ Chrome manifest installed"
    
    # Edge
    mkdir -p "$EDGE_DIR"
    sed "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/g" "$SCRIPT_DIR/com.nfcreader.host.json" > "$EDGE_DIR/com.nfcreader.host.json"
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
    cp "$SCRIPT_DIR/nfcreader.json" "$FIREFOX_DIR/nfcreader.json"
    echo "✓ Firefox manifest installed"
fi

echo ""
echo "====================================="
echo "Installation Complete!"
echo "====================================="
echo ""
echo "Installed locations:"
echo "  Binary: $BINARY_PATH"
if [ -n "$EXTENSION_ID" ]; then
    echo "  Chrome: $CHROME_DIR/com.nfcreader.host.json"
    echo "  Edge: $EDGE_DIR/com.nfcreader.host.json"
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
echo "  $BINARY_NAME list-readers"
echo ""
