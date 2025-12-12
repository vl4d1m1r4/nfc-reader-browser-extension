#!/bin/bash
# macOS uninstall script
# Users need to run this manually before deleting the app

set -e

echo "Removing native messaging manifests..."

# System-wide directories
CHROME_DIR="/Library/Google/Chrome/NativeMessagingHosts"
EDGE_DIR="/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
FIREFOX_DIR="/Library/Application Support/Mozilla/NativeMessagingHosts"

# Remove manifests
sudo rm -f "$CHROME_DIR/info.nfcreader.host.json"
sudo rm -f "$EDGE_DIR/info.nfcreader.host.json"
sudo rm -f "$FIREFOX_DIR/info.nfcreader.host.json"

echo "Native messaging manifests removed"
echo ""
echo "You can now delete /Applications/nfc-reader-host.app"

exit 0
