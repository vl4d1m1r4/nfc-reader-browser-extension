# NFC Reader Browser Extension - Implementation Plan

## Project Overview
Create a browser extension that reads NFC-A cards from an external USB-connected reader (ACR122U) using a Java console application as a native messaging host.

## Architecture

### Components
1. **Java Console Application** (Native Messaging Host)
   - Native binaries for each OS: `nfc-reader-host` (Linux/macOS), `nfc-reader-host.exe` (Windows)
   - Built with GraalVM Native Image
   - Self-contained executables (no JRE required)
   - Communicates via stdin/stdout using native messaging protocol

2. **Browser Extension**
   - Configuration UI for reader selection
   - Native messaging client
   - Auto-fills focused input fields with NFC card UIDs

## Implementation Plan

### Phase 1: Java Application (`nfc-reader-host/`)

#### 1.1 Project Setup
- [ ] Create Maven/Gradle project structure
- [ ] Add dependencies:
  - `javax.smartcardio` (built-in Java API for smart card readers)
  - JSON library for native messaging (e.g., `org.json` or `gson`)
- [ ] Configure GraalVM Native Image plugin
- [ ] Set up native-image configuration:
  - Reflection configuration for smartcard API
  - Resource configuration for bundled files
  - JNI configuration if needed
- [ ] Configure build profiles for each OS:
  - Linux: `nfc-reader-host`
  - macOS: `nfc-reader-host`
  - Windows: `nfc-reader-host.exe`

#### 1.2 Core Components

**Command Structure:**
```
# Linux/macOS
./nfc-reader-host <command> [options]

# Windows
nfc-reader-host.exe <command> [options]
```

**Commands to implement:**
1. `list-readers` - Enumerate connected NFC readers
2. `listen <reader-index>` - Monitor reader for card UIDs
3. `native-messaging` - Run in native messaging mode

**Classes:**
- `Main.java` - Entry point, command dispatcher
- `ReaderManager.java` - Interface with javax.smartcardio
- `NativeMessagingHost.java` - Handle browser communication protocol
- `CardReader.java` - Read NFC-A UIDs (handle different lengths: 4, 7, 10 bytes)
- `CommandHandler.java` - Process commands and return JSON responses

#### 1.3 NFC Reading Logic
- Initialize card terminals using `TerminalFactory`
- Connect to ACR122U specifically
- Read UID from NFC-A cards using APDU commands:
  - Standard: `FF CA 00 00 00` (Get Data command)
- Handle different UID formats (single, double, triple size)
- Convert UID bytes to hex string

#### 1.4 Native Messaging Protocol
- Read 4-byte message length (native byte order)
- Read JSON message
- Process command
- Write response with 4-byte length prefix + JSON

#### 1.5 Testing
- Unit tests for card reading logic
- Mock reader for development testing
- Manual testing with ACR122U

### Phase 2: Browser Extension (`browser-extension/`)

#### 2.1 Project Structure
```
browser-extension/
├── manifest.json
├── background/
│   ├── background.js
│   └── native-messaging.js
├── popup/
│   ├── popup.html
│   ├── popup.js
│   └── popup.css
├── content/
│   └── content.js
└── icons/
    └── icon-*.png
```

#### 2.2 Manifest Configuration
- Manifest V3
- Permissions: `nativeMessaging`, `activeTab`, `storage`
- Native messaging host declaration
- Background service worker
- Content script injection

#### 2.3 Components

**Background Script:**
- Detect OS using `navigator.platform` or `runtime.getPlatformInfo()`
- Establish native messaging connection to `info.nfcreader.host`
- Manage reader state
- Relay messages between popup and native host
- Handle connection errors and reconnection
- Provide clear error messages if host not installed

**Popup UI:**
- Display available readers (dropdown)
- Show connection status
- Toggle listening mode (Start/Stop)
- Display last read UID
- Settings: selected reader preference (saved to storage)

**Content Script:**
- Find focused input element
- Insert UID value when received from background
- Handle different input types (text, number, etc.)

#### 2.4 Communication Flow
1. User opens popup
2. Extension requests reader list from Java app
3. User selects reader and clicks "Start Listening"
4. Background sends listen command to Java app
5. Java app continuously monitors for cards
6. On card detection, Java sends UID to extension
7. Extension forwards UID to content script
8. Content script fills focused input

### Phase 3: Native Messaging Host Registration

#### 3.1 Host Manifest Files
Create OS-specific host manifests for each browser:

**Linux - Chrome/Edge:** `info.nfcreader.host.json`
```json
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "/usr/local/bin/nfc-reader-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://<extension-id>/"
  ]
}
```

**macOS - Chrome/Edge:** `info.nfcreader.host.json`
```json
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "/usr/local/bin/nfc-reader-host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://<extension-id>/"
  ]
}
```

**Windows - Chrome/Edge:** `info.nfcreader.host.json`
```json
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "C:\\Program Files\\NFCReader\\nfc-reader-host.exe",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://<extension-id>/"
  ]
}
```

**Firefox (all platforms):** `nfcreader.json`
```json
{
  "name": "info.nfcreader.host",
  "description": "NFC Reader Native Messaging Host",
  "path": "<os-specific-path>",
  "type": "stdio",
  "allowed_extensions": [
    "nfc-reader@example.com"
  ]
}
```

#### 3.2 Installation Scripts

**Linux (`install-linux.sh`):**
- Copy `nfc-reader-host` binary to `/usr/local/bin/`
- Set executable permissions (`chmod +x`)
- Install Chrome manifest to `~/.config/google-chrome/NativeMessagingHosts/`
- Install Firefox manifest to `~/.mozilla/native-messaging-hosts/`
- Create symlinks for Chromium, Edge if needed

**macOS (`install-macos.sh`):**
- Copy `nfc-reader-host` binary to `/usr/local/bin/`
- Set executable permissions (`chmod +x`)
- Install Chrome manifest to `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/`
- Install Firefox manifest to `~/Library/Application Support/Mozilla/NativeMessagingHosts/`
- Handle code signing requirements

**Windows (`install-windows.bat`):**
- Copy `nfc-reader-host.exe` to `C:\Program Files\NFCReader\`
- Create registry entries for Chrome/Edge:
  - `HKEY_CURRENT_USER\Software\Google\Chrome\NativeMessagingHosts\info.nfcreader.host`
  - `HKEY_CURRENT_USER\Software\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host`
- Install Firefox manifest to `%APPDATA%\Mozilla\NativeMessagingHosts\`
- Add to PATH (optional)

**Uninstall scripts:**
- `uninstall-linux.sh`
- `uninstall-macos.sh`
- `uninstall-windows.bat`
- Remove binaries, manifests, and registry entries

### Phase 4: Development & Testing

#### 4.1 Development Setup
- **Java app:** 
  - Development: Run with `java -jar` or IDE for debugging
  - Production: Build native binaries with GraalVM for each target OS
  - Use agent-assisted config generation: `java -agentlib:native-image-agent=config-output-dir=...`
- **Extension:** Load unpacked in Chrome/Firefox
- **Testing:** Mock native host for development without installing binaries
- **Cross-platform builds:** Use CI/CD or Docker for building binaries for all platforms

#### 4.2 Testing Checklist
- [ ] Java app lists ACR122U reader correctly
- [ ] Java app reads 4-byte UID cards
- [ ] Java app reads 7-byte UID cards
- [ ] Java app reads 10-byte UID cards
- [ ] Native messaging communication works
- [ ] Extension popup shows available readers
- [ ] Extension can start/stop listening
- [ ] UID auto-fills in focused input
- [ ] Works on Chrome
- [ ] Works on Firefox
- [ ] Works on Edge
- [ ] Cross-platform: Windows
- [ ] Cross-platform: macOS
- [ ] Cross-platform: Linux

### Phase 5: Documentation & Packaging

#### 5.1 Documentation
- `README.md` - Project overview, installation, usage
- `DEVELOPMENT.md` - Build instructions, testing guide
- `TROUBLESHOOTING.md` - Common issues and solutions

#### 5.2 Build Scripts
- **Java Native Builds:**
  - `build-linux.sh` - Compile native binary for Linux
  - `build-macos.sh` - Compile native binary for macOS
  - `build-windows.bat` - Compile native binary for Windows
  - Use GraalVM `native-image` command with proper configurations
  - CI/CD pipeline for automated multi-platform builds
- **Extension Packaging:**
  - Package script for Chrome Web Store (zip)
  - Package script for Firefox Add-ons (xpi)
- **Release Packaging:**
  - Create installers with binaries + installation scripts
  - Separate packages per OS
- Version management across all components

#### 5.3 Distribution
- Release checklist
- Installation guide for end users
- Support for direct installation (not via store)

## Technology Stack

### Java Application
- **Language:** Java 11+ (for cross-platform compatibility)
- **Build Tool:** Maven or Gradle with GraalVM Native Image plugin
- **Runtime:** GraalVM Native Image (for native binary compilation)
- **Dependencies:**
  - `javax.smartcardio` (included in JDK)
  - `org.json` or `com.google.code.gson` for JSON handling
- **Testing:** JUnit 5
- **Build outputs:**
  - Linux: ELF 64-bit executable
  - macOS: Mach-O 64-bit executable (requires code signing)
  - Windows: PE32+ executable

### Browser Extension
- **Languages:** JavaScript (ES6+), HTML5, CSS3
- **APIs:** Chrome/Firefox Native Messaging API
- **Manifest:** Version 3 (Chrome) / Version 2 (Firefox if needed)

## DRY Principles Applied
1. Shared JSON message format between commands
2. Reusable card reading logic for all UID types
3. Common error handling patterns
4. Shared configuration storage in extension
5. Unified native messaging protocol handler

## ACR122U Specific Considerations
- Driver requirements (PC/SC support)
- APDU command compatibility
- LED feedback control (optional feature)
- Beeper control (optional feature)

## Security Considerations
- Validate all input from native messaging
- Sanitize UIDs before insertion into DOM
- Handle disconnection gracefully
- No sensitive data storage
- Minimal permissions requested
- Verify native host binary integrity (checksums)
- macOS: Code sign binaries to avoid Gatekeeper issues
- Windows: Consider signing executables to avoid SmartScreen warnings
- Restrict native messaging host permissions (file system access)

## Future Enhancements (Optional)
- Support for other NFC card types (NFC-B, NFC-F)
- Read/write block data
- Multiple reader support simultaneously
- Card UID history
- Configurable UID format (hex, decimal, etc.)
- Auto-submit form option
