#!/bin/bash
# Post-installation script for DEB/RPM packages
# This runs after the package is installed

set -e

INSTALL_ROOT="$1"
APP_DIR="${INSTALL_ROOT}/opt/nfc-reader-host"
BINARY_PATH="${APP_DIR}/bin/nfc-reader-host"

# Get extension IDs from environment or use defaults
CHROME_EXT_ID="${CHROME_EXTENSION_ID:-EXTENSION_ID_PLACEHOLDER}"
FIREFOX_EXT_ID="${FIREFOX_EXTENSION_ID:-nfc-reader@example.com}"

# Install native messaging manifests for all users
install_manifests() {
    echo "Installing native messaging manifests..."
    
    # System-wide directories (accessible to all users)
    CHROME_DIR="/etc/opt/chrome/native-messaging-hosts"
    CHROMIUM_DIR="/etc/chromium/native-messaging-hosts"
    EDGE_DIR="/etc/opt/edge/native-messaging-hosts"
    FIREFOX_DIR="/usr/lib/mozilla/native-messaging-hosts"
    
    # Create directories
    mkdir -p "$CHROME_DIR" "$CHROMIUM_DIR" "$EDGE_DIR" "$FIREFOX_DIR"
    
    # Chrome/Chromium manifest
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
    
    cp "$CHROME_DIR/info.nfcreader.host.json" "$CHROMIUM_DIR/"
    cp "$CHROME_DIR/info.nfcreader.host.json" "$EDGE_DIR/"
    
    # Firefox manifest (uses allowed_extensions instead of allowed_origins)
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
    chmod 644 "$CHROMIUM_DIR/info.nfcreader.host.json"
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
echo ""
echo "Replace EXTENSION_ID_PLACEHOLDER with your actual extension ID."

exit 0
