#!/bin/bash
# macOS post-install script for PKG installer
# This runs after the package is installed

set -e

APP_PATH="/Applications/nfc-reader-host.app"
BINARY_PATH="${APP_PATH}/Contents/MacOS/nfc-reader-host"

# Get extension IDs from environment or use defaults
CHROME_EXT_ID="${CHROME_EXTENSION_ID:-EXTENSION_ID_PLACEHOLDER}"
FIREFOX_EXT_ID="${FIREFOX_EXTENSION_ID:-nfc@nfcreader.info}"

# Install native messaging manifests for all users
install_manifests() {
    echo "Installing native messaging manifests..."
    
    # System-wide directories (accessible to all users)
    CHROME_DIR="/Library/Google/Chrome/NativeMessagingHosts"
    EDGE_DIR="/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
    FIREFOX_DIR="/Library/Application Support/Mozilla/NativeMessagingHosts"
    
    # Create directories
    mkdir -p "$CHROME_DIR"
    mkdir -p "$EDGE_DIR"
    mkdir -p "$FIREFOX_DIR"
    
    # Chrome/Edge manifest
    cat > "$CHROME_DIR/info.nfcreader.host.json" << EOF
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "${BINARY_PATH}",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://${CHROME_EXT_ID}/"
  ]
}
EOF
    
    cp "$CHROME_DIR/info.nfcreader.host.json" "$EDGE_DIR/"
    
    # Firefox manifest
    cat > "$FIREFOX_DIR/info.nfcreader.host.json" << EOF
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "${BINARY_PATH}",
  "type": "stdio",
  "allowed_extensions": [
    "${FIREFOX_EXT_ID}"
  ]
}
EOF
    
    # Set permissions
    chmod 644 "$CHROME_DIR/info.nfcreader.host.json"
    chmod 644 "$EDGE_DIR/info.nfcreader.host.json"
    chmod 644 "$FIREFOX_DIR/info.nfcreader.host.json"
    
    echo "Native messaging manifests installed successfully"
}

# Make sure binary is executable
chmod +x "$BINARY_PATH" 2>/dev/null || true

# Install manifests
install_manifests

echo "NFC Reader Host installation completed"
echo ""
echo "IMPORTANT: Update the extension ID in the manifest files:"
echo "  - Chrome/Edge: $CHROME_DIR/info.nfcreader.host.json"
echo "  - Firefox: $FIREFOX_DIR/info.nfcreader.host.json"

exit 0
