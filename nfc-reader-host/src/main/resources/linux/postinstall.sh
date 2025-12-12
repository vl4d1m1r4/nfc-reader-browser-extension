#!/bin/bash
# Post-installation script for DEB/RPM packages
# This runs after the package is installed

set -e

INSTALL_ROOT="$1"
APP_DIR="${INSTALL_ROOT}/opt/nfc-reader-host"
BINARY_PATH="${APP_DIR}/bin/nfc-reader-host"
RESOURCE_DIR="${APP_DIR}/lib/app"

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
    
    # Copy Chrome manifest template and update path
    if [ -f "${RESOURCE_DIR}/info.nfcreader.host.json" ]; then
        sed "s|/usr/local/bin/nfc-reader-host|${BINARY_PATH}|g" "${RESOURCE_DIR}/info.nfcreader.host.json" > "$CHROME_DIR/info.nfcreader.host.json"
        cp "$CHROME_DIR/info.nfcreader.host.json" "$CHROMIUM_DIR/"
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

exit 0
