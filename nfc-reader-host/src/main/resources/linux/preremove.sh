#!/bin/bash
# Pre-removal script for DEB/RPM packages
# This runs before the package is removed

set -e

echo "Removing native messaging manifests..."

# System-wide directories
CHROME_DIR="/etc/opt/chrome/native-messaging-hosts"
CHROMIUM_DIR="/etc/chromium/native-messaging-hosts"
EDGE_DIR="/etc/opt/edge/native-messaging-hosts"
FIREFOX_DIR="/usr/lib/mozilla/native-messaging-hosts"

# Remove manifests
rm -f "$CHROME_DIR/info.nfcreader.host.json"
rm -f "$CHROMIUM_DIR/info.nfcreader.host.json"
rm -f "$EDGE_DIR/info.nfcreader.host.json"
rm -f "$FIREFOX_DIR/info.nfcreader.host.json"

echo "Native messaging manifests removed"

exit 0
