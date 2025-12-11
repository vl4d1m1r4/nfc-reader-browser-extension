# NFC Reader - Installation Guide

This directory contains installation scripts and manifests for the native messaging host across different platforms.

## Directory Structure

```
install/
├── linux/          Linux installation files
├── macos/          macOS installation files
└── windows/        Windows installation files
```

## Prerequisites

Before installing the native host, ensure you have:

1. **Built the native binary** for your platform:
   ```bash
   cd ../nfc-reader-host
   mvn clean package -Pnative
   ```

2. **PC/SC smart card support**:
   - **Linux**: pcscd service (usually pre-installed)
   - **macOS**: Built-in support
   - **Windows**: Built-in Smart Card service

3. **NFC Reader**: ACR122U or compatible PC/SC reader connected

## Installation Instructions

### Linux

```bash
cd install/linux
./install.sh
```

The script will:
- Copy the binary to `/usr/local/bin/nfc-reader-host` (requires sudo)
- Ask for your Chrome/Edge extension ID
- Optionally install Firefox manifest
- Install manifests to:
  - Chrome: `~/.config/google-chrome/NativeMessagingHosts/`
  - Chromium: `~/.config/chromium/NativeMessagingHosts/`
  - Edge: `~/.config/microsoft-edge/NativeMessagingHosts/`
  - Firefox: `~/.mozilla/native-messaging-hosts/`

**Uninstall:**
```bash
cd install/linux
./uninstall.sh
```

### macOS

```bash
cd install/macos
./install.sh
```

The script will:
- Copy the binary to `/usr/local/bin/nfc-reader-host` (requires sudo)
- Ask for your Chrome/Edge extension ID
- Optionally install Firefox manifest
- Install manifests to:
  - Chrome: `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/`
  - Edge: `~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/`
  - Firefox: `~/Library/Application Support/Mozilla/NativeMessagingHosts/`

**Important**: On first run, macOS may block the binary. Go to:
`System Preferences > Security & Privacy > General` and click "Allow".

**Uninstall:**
```bash
cd install/macos
./uninstall.sh
```

### Windows

**Run as Administrator:**

```cmd
cd install\windows
install.bat
```

The script will:
- Copy the binary to `C:\Program Files\NFCReader\nfc-reader-host.exe`
- Ask for your Chrome/Edge extension ID
- Optionally install Firefox manifest
- Create registry entries:
  - Chrome: `HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\com.nfcreader.host`
  - Edge: `HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\com.nfcreader.host`
- Install Firefox manifest to: `%APPDATA%\Mozilla\NativeMessagingHosts\`

**Uninstall (Run as Administrator):**
```cmd
cd install\windows
uninstall.bat
```

## Getting the Extension ID

### Chrome/Edge

1. Open `chrome://extensions/` (or `edge://extensions/`)
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked" and select the `browser-extension` folder
4. Copy the Extension ID shown under the extension name
5. Run the installation script and paste the ID when prompted

### Firefox

Firefox doesn't use extension IDs in the same way. The manifest uses:
- Extension ID: `nfc-reader@example.com` (configured in manifest)

## Verification

After installation, verify that the native host is working:

### Linux/macOS
```bash
/usr/local/bin/nfc-reader-host list-readers
```

### Windows
```cmd
"C:\Program Files\NFCReader\nfc-reader-host.exe" list-readers
```

You should see a list of connected NFC readers.

## Troubleshooting

### "Native messaging host not found"

**Chrome/Edge:**
- Verify the manifest file exists in the correct location
- Check that the extension ID in the manifest matches your extension
- Restart the browser
- Check browser console for specific error messages

**Firefox:**
- Verify the manifest file exists in `~/.mozilla/native-messaging-hosts/` (Linux/macOS) or `%APPDATA%\Mozilla\NativeMessagingHosts\` (Windows)
- Restart Firefox
- Check the browser console for errors

### "Permission denied" or "Access denied"

**Linux/macOS:**
- Ensure the binary is executable: `chmod +x /usr/local/bin/nfc-reader-host`
- Check file permissions

**macOS specific:**
- Allow the binary in System Preferences > Security & Privacy

**Windows:**
- Ensure you ran the installation script as Administrator
- Check that the Smart Card service is running

### No readers found

- Ensure your NFC reader is connected
- Check PC/SC service:
  - Linux: `systemctl status pcscd`
  - Windows: Check Services for "Smart Card"
- Try unplugging and reconnecting the reader
- Verify the reader works with other tools (e.g., `pcsc_scan` on Linux)

### Testing without browser

You can test the native host directly:

```bash
# List readers
nfc-reader-host list-readers

# Listen on first reader
nfc-reader-host listen 0
```

## Manual Installation

If the scripts don't work, you can install manually:

1. Copy the binary to the appropriate location
2. Edit the manifest JSON file to add your extension ID
3. Copy the manifest to the correct browser-specific directory
4. Restart your browser

See the platform-specific directories for manifest templates.

## Security Notes

- The native messaging host only accepts connections from the specified extension ID
- The host runs with user privileges (not root/administrator)
- All communication is local (no network access)
- The host only accesses PC/SC smart card readers

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify PC/SC service is running
3. Check browser console for error messages
4. Test the native host binary directly
