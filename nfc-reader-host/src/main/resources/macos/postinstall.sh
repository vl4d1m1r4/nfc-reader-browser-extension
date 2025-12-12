#!/bin/bash
# macOS post-install script for PKG installer
# This runs after the package is installed

set -e

APP_PATH="/Applications/nfc-reader-host.app"
BINARY_PATH="${APP_PATH}/Contents/MacOS/nfc-reader-host"
RESOURCE_DIR="${APP_PATH}/Contents/app"

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
    
    # Copy Chrome manifest template and update path
    if [ -f "${RESOURCE_DIR}/info.nfcreader.host.json" ]; then
        sed "s|/usr/local/bin/nfc-reader-host|${BINARY_PATH}|g" "${RESOURCE_DIR}/info.nfcreader.host.json" > "$CHROME_DIR/info.nfcreader.host.json"
        cp "$CHROME_DIR/info.nfcreader.host.json" "$EDGE_DIR/"
    else
        echo "Warning: Manifest template not found at ${RESOURCE_DIR}/info.nfcreader.host.json"
        return 1
    fi
    
    # Create Firefox manifest (convert allowed_origins to allowed_extensions)
    sed -e "s|/usr/local/bin/nfc-reader-host|${BINARY_PATH}|g" \
        -e 's/"allowed_origins"/"allowed_extensions"/g' \
        -e 's|chrome-extension://\([^/]*\)/|\1|g' \
        "${RESOURCE_DIR}/info.nfcreader.host.json" > "$FIREFOX_DIR/info.nfcreader.host.json"
    
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

exit 0
