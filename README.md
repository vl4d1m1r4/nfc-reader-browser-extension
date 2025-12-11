# NFC Reader Browser Extension

A browser extension that reads NFC-A cards from an external USB-connected reader (ACR122U) and auto-fills input fields with card UIDs. The extension uses a Java native messaging host for cross-platform smart card reader access.

> **🚀 New to this project?** Check out the [Quick Start Guide](QUICKSTART.md) to get running in 5 minutes!

## Features

- 📱 **Read NFC-A Cards**: Support for 4, 7, and 10 byte UIDs
- ✨ **Auto-Fill**: Automatically fills focused input fields with card UIDs
- 🔌 **ACR122U Support**: Works with ACR122U and other PC/SC compatible readers
- 💻 **Cross-Platform**: Linux, macOS, and Windows support
- 🌐 **Multi-Browser**: Chrome, Edge, and Firefox compatible
- 🔒 **Secure**: Native messaging protocol with local-only communication
- ⚡ **Native Performance**: GraalVM native binaries (no JRE required)

## Architecture

The project consists of two main components:

1. **Java Native Messaging Host** (`nfc-reader-host/`)
   - Communicates with NFC readers using `javax.smartcardio`
   - Compiled to native binaries with GraalVM
   - Implements Chrome/Firefox native messaging protocol

2. **Browser Extension** (`browser-extension/`)
   - Manifest V3 extension for Chrome/Edge
   - Native messaging client
   - Popup UI for reader selection and control
   - Content script for auto-filling input fields

## Quick Start

### 1. Build the Native Host

Requires Java 11+ and GraalVM:

```bash
cd nfc-reader-host
mvn clean package -Pnative
```

This creates a native binary in `target/nfc-reader-host` (or `nfc-reader-host.exe` on Windows).

### 2. Install the Native Host

#### Linux
```bash
cd install/linux
./install.sh
```

#### macOS
```bash
cd install/macos
./install.sh
```

#### Windows (Run as Administrator)
```cmd
cd install\windows
install.bat
```

### 3. Install the Browser Extension

1. Open Chrome/Edge and navigate to `chrome://extensions/`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `browser-extension` folder
5. Copy the extension ID and provide it during native host installation

### 4. Use the Extension

1. Click the extension icon in your toolbar
2. Select your NFC reader from the dropdown
3. Click "Start Listening"
4. Focus on any text input field
5. Scan an NFC card - the UID will auto-fill!

## Project Structure

```
nfc-reader/
├── nfc-reader-host/          # Java native messaging host
│   ├── src/
│   │   ├── main/java/        # Source code
│   │   ├── test/java/        # Unit tests
│   │   └── resources/        # GraalVM config
│   ├── pom.xml               # Maven configuration
│   └── README.md
│
├── browser-extension/        # Browser extension
│   ├── manifest.json         # Extension manifest
│   ├── background/           # Background service worker
│   ├── popup/                # Extension popup UI
│   ├── content/              # Content script
│   ├── icons/                # Extension icons
│   └── README.md
│
├── install/                  # Installation scripts
│   ├── linux/               # Linux installation
│   ├── macos/               # macOS installation
│   ├── windows/             # Windows installation
│   └── README.md
│
├── PLAN.md                  # Implementation plan
└── README.md                # This file
```

## Requirements

### Development
- Java 11 or higher
- Maven 3.6+
- GraalVM (for building native images)
- NFC reader (ACR122U recommended)

### Runtime
- **Native Host**: No JRE required (self-contained binary)
- **PC/SC Support**:
  - Linux: `pcscd` service
  - macOS: Built-in
  - Windows: Smart Card service
- **Browser**: Chrome 88+, Edge 88+, or Firefox 90+

## Supported NFC Cards

- **NFC-A (ISO 14443A)** cards
- UID formats:
  - 4 bytes (single size)
  - 7 bytes (double size)
  - 10 bytes (triple size)

Common compatible cards:
- MIFARE Classic
- MIFARE Ultralight
- MIFARE DESFire
- NTAG series
- Many access control cards

## Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get up and running in 5 minutes ⚡
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions 🔧
- **[Development Guide](DEVELOPMENT.md)** - Build, test, and contribute 💻
- [Java Host README](nfc-reader-host/README.md) - Build instructions and API
- [Extension README](browser-extension/README.md) - Extension usage and development
- [Installation Guide](install/README.md) - Platform-specific installation
- [Implementation Plan](PLAN.md) - Detailed project plan
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - What has been built

## Development

### Building

**Java Host:**
```bash
cd nfc-reader-host

# Regular JAR (for development)
mvn clean package

# Native binary (for production)
mvn clean package -Pnative
```

**Extension:**
No build step required - load directly in browser developer mode.

### Testing

**Java Host:**
```bash
cd nfc-reader-host

# Run unit tests
mvn test

# Test manually
java -jar target/nfc-reader-host-fat.jar list-readers
java -jar target/nfc-reader-host-fat.jar listen 0
```

**Extension:**
1. Load unpacked extension in browser
2. Open browser console for debugging
3. Check background service worker logs
4. Test on web pages with input fields

## Troubleshooting

### Native host not found
- Ensure native host is installed (see installation guide)
- Verify extension ID matches in manifest
- Restart browser after installation

### No readers detected
- Check NFC reader is connected
- Verify PC/SC service is running
- Try: `nfc-reader-host list-readers`

### Card not detected
- Ensure card is close enough to reader
- Check reader has power (LED should be on)
- Verify card type is NFC-A compatible

### Auto-fill not working
- Focus on a text input field before scanning
- Check content script is loaded (browser console)
- Verify input type is supported

See [Installation Guide](install/README.md) for more troubleshooting tips.

## Security

- Native messaging host only accepts connections from registered extension
- No network communication - all local
- Host runs with user privileges (not root/admin)
- Only accesses PC/SC smart card readers
- No sensitive data storage

## Browser Compatibility

| Browser | Status | Notes |
|---------|--------|-------|
| Chrome 88+ | ✅ Supported | Manifest V3 |
| Edge 88+ | ✅ Supported | Manifest V3 |
| Firefox 90+ | ✅ Supported | May need Manifest V2 adjustments |

## Known Limitations

- Only NFC-A cards supported (not NFC-B or NFC-F)
- Reads UID only (no block data reading/writing)
- Single reader mode (can't monitor multiple readers simultaneously)
- Auto-fill requires manual focus on input field

## Future Enhancements

- [ ] Support for NFC-B and NFC-F cards
- [ ] Read/write block data
- [ ] Multiple reader support
- [ ] Card UID history
- [ ] Configurable UID format (hex/decimal)
- [ ] Auto-submit form option
- [ ] Chrome Web Store / Firefox Add-ons publication

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

[License information to be added]

## Acknowledgments

- Uses `javax.smartcardio` for cross-platform smart card access
- Built with GraalVM Native Image for optimal performance
- Follows Chrome/Firefox native messaging protocol

## Support

For issues, questions, or feature requests, please:
1. Check the troubleshooting sections in documentation
2. Review existing issues
3. Create a new issue with detailed information

---

**Note**: This extension requires physical NFC hardware and is intended for development, testing, or specialized workflows involving NFC card UIDs.
