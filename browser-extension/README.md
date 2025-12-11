# NFC Reader Browser Extension

Browser extension for reading NFC-A cards from an ACR122U USB reader and auto-filling input fields with card UIDs.

## Features

- 📱 Read NFC-A card UIDs (4, 7, and 10 byte UIDs)
- ✨ Auto-fill focused input fields with card UIDs
- 🔌 Support for ACR122U and compatible readers
- 🎯 Simple, user-friendly interface
- 🔒 Secure native messaging communication

## Installation

### Prerequisites

1. **Native Host Application**: Install the NFC Reader native messaging host (see `../nfc-reader-host/README.md`)
2. **NFC Reader**: ACR122U or compatible PC/SC reader
3. **Browser**: Chrome, Edge, or Firefox

### Installing the Extension

#### Chrome/Edge (Developer Mode)

1. Open Chrome/Edge and navigate to `chrome://extensions/` (or `edge://extensions/`)
2. Enable "Developer mode" using the toggle in the top right
3. Click "Load unpacked"
4. Select the `browser-extension` folder
5. The extension icon should appear in your toolbar

#### Firefox (Temporary Add-on)

1. Open Firefox and navigate to `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on"
3. Select the `manifest.json` file from the `browser-extension` folder
4. The extension will be loaded temporarily (until browser restart)

## Usage

1. **Click the extension icon** in your toolbar to open the popup
2. **Select your NFC reader** from the dropdown (if multiple readers are available)
3. **Click "Start Listening"** to begin monitoring for NFC cards
4. **Focus on an input field** on any webpage
5. **Scan an NFC card** - the UID will automatically fill the focused field

### Visual Feedback

- **Status Indicator**: 
  - 🟢 Green: Connected and ready
  - 🔵 Blue (pulsing): Listening for cards
  - 🔴 Red: Error occurred
- **Notifications**: Brief notification appears when a card is scanned
- **Field Highlight**: The filled input field is briefly highlighted

## Supported Input Types

The extension will auto-fill these input types:
- `<input type="text">`
- `<input type="search">`
- `<input type="tel">`
- `<input type="url">`
- `<input type="email">`
- `<input type="number">`
- `<textarea>`

## Permissions

The extension requires these permissions:
- **nativeMessaging**: To communicate with the native host application
- **activeTab**: To fill input fields on the current tab
- **storage**: To remember your reader selection

## Troubleshooting

### "Native messaging host not installed" error

This means the native host application is not properly installed. Please:
1. Install the native host (see `../nfc-reader-host/README.md`)
2. Verify the host manifest is in the correct location
3. Restart your browser

### Reader not appearing in the list

- Ensure your NFC reader is connected
- Check that PC/SC service is running (Linux: `pcscd`, Windows: Smart Card service)
- Click the "Refresh" button in the extension popup
- Try disconnecting and reconnecting the reader

### UID not filling the input field

- Make sure an input field is focused (click inside it)
- Ensure the input type is supported (text, textarea, etc.)
- Check the browser console for any errors

## Development

### Project Structure

```
browser-extension/
├── manifest.json           # Extension manifest
├── background/
│   ├── background.js       # Service worker
│   └── native-messaging.js # Native messaging handler
├── popup/
│   ├── popup.html          # Popup UI
│   ├── popup.css           # Popup styles
│   └── popup.js            # Popup logic
├── content/
│   └── content.js          # Content script for filling inputs
└── icons/
    └── *.png              # Extension icons
```

### Testing

1. Load the extension in developer mode
2. Open the browser console (F12) and check for errors
3. Open the extension popup and test reader detection
4. Navigate to any webpage with input fields
5. Test card scanning and auto-fill functionality

### Debugging

- **Background script logs**: `chrome://extensions/` → click "service worker" under the extension
- **Popup logs**: Right-click the popup → "Inspect"
- **Content script logs**: Open page console (F12) on any webpage

## Icons

Place icon files in the `icons/` directory:
- `icon-16.png` (16x16px)
- `icon-32.png` (32x32px)
- `icon-48.png` (48x48px)
- `icon-128.png` (128x128px)

You can generate these from a single SVG or high-resolution PNG.

## Browser Compatibility

- ✅ Chrome 88+
- ✅ Microsoft Edge 88+
- ✅ Firefox 90+ (with minor manifest adjustments for Manifest V2)

## License

[License information to be added]

## Support

For issues, please check:
1. Native host installation and configuration
2. NFC reader connectivity and drivers
3. Browser console errors
4. Extension permissions
