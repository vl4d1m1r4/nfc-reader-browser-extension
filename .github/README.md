# GitHub Actions CI/CD

This directory contains GitHub Actions workflows for automated building, testing, and releasing of the NFC Reader Host application.

## Workflows

### 1. CI Build (`ci.yml`)

**Trigger**: Push or Pull Request to `main` or `develop` branches

**Purpose**: Continuous Integration - validates that the code builds and tests pass on all platforms

**Jobs**:
- **test**: Runs unit tests with Maven
- **build-linux**: Builds on Ubuntu, creates JAR and jpackage app-image
- **build-macos**: Builds on macOS, creates JAR and jpackage app-image
- **build-windows**: Builds on Windows, creates JAR and jpackage app-image

**Artifacts**: 
- Test results (JUnit reports)
- Built JAR files for each platform

### 2. Release Build (`release.yml`)

**Trigger**: 
- Push of a version tag (e.g., `v1.0.0`)
- Manual workflow dispatch (with extension ID inputs)

**Purpose**: Creates installer packages with native messaging manifests and GitHub releases

**Extension ID Configuration**:
When manually triggering the workflow, you can specify:
- **Chrome/Edge Extension ID**: The Chrome Web Store extension ID (defaults to `EXTENSION_ID_PLACEHOLDER`)
- **Firefox Extension ID**: The Firefox Add-on ID (defaults to `nfc@nfcreader.info`)

These IDs are automatically embedded in the native messaging manifests during installation.

**Jobs**:
- **build-linux**: 
  - Builds DEB package with post-install scripts
  - Builds RPM package with post-install scripts
  - Creates tarball
  - Automatically installs native messaging manifests system-wide
  
- **build-macos**: 
  - Builds DMG installer with post-install script
  - Automatically installs native messaging manifests to /Library
  
- **build-windows**: 
  - Builds MSI installer with post-install script
  - Builds EXE installer with post-install script
  - Automatically registers native messaging manifests in Windows Registry
  
- **create-release**: 
  - Creates GitHub Release with all installers
  - Generates release notes automatically

### Quick Reference - Required Secrets

**Extension IDs** (configure via workflow inputs when manually triggering):
- Chrome/Edge Extension ID from Chrome Web Store
- Firefox Extension ID from addons.mozilla.org

**Note**: Post-install scripts will automatically set up native messaging manifests with the provided extension IDs. Users no longer need to manually configure manifest files.

## Creating a Release

### Method 1: Tag Push (Recommended)

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This will automatically:
1. Trigger the release workflow
2. Build installers for all platforms
3. Sign them (if secrets are configured)
4. Create a GitHub Release
5. Upload installers to the release

### Method 2: Manual Trigger with Extension IDs

1. Go to **Actions** tab in GitHub
2. Select **Build and Release Installers**
3. Click **Run workflow**
4. Enter your extension IDs:
   - **Chrome/Edge Extension ID**: Your Chrome Web Store extension ID
   - **Firefox Extension ID**: Your Firefox add-on ID
5. Select branch and click **Run workflow**

This method creates artifacts but does NOT create a GitHub Release (only tag pushes do).

### Extension ID Format Examples

- **Chrome/Edge**: `abcdefghijklmnopqrstuvwxyz123456` (32 character ID from Chrome Web Store)
- **Firefox**: `nfc-reader@yourdomain.com` or `{12345678-1234-1234-1234-123456789012}`

## Workflow Details

### Build Matrix

| Platform | Runner | JDK | Output Formats |
|----------|--------|-----|----------------|
| Linux | ubuntu-latest | Temurin 23 | DEB, RPM, tar.gz |
| macOS | macos-latest | Temurin 23 | DMG |
| Windows | windows-latest | Temurin 23 | MSI, EXE |

### Native Messaging Manifest Installation

The installers automatically configure native messaging manifests:

**Linux (DEB/RPM)**:
- Chrome: `/etc/opt/chrome/native-messaging-hosts/info.nfcreader.host.json`
- Chromium: `/etc/chromium/native-messaging-hosts/info.nfcreader.host.json`
- Edge: `/etc/opt/edge/native-messaging-hosts/info.nfcreader.host.json`
- Firefox: `/usr/lib/mozilla/native-messaging-hosts/info.nfcreader.host.json`

**macOS (DMG)**:
- Chrome: `/Library/Google/Chrome/NativeMessagingHosts/info.nfcreader.host.json`
- Edge: `/Library/Application Support/Microsoft Edge/NativeMessagingHosts/info.nfcreader.host.json`
- Firefox: `/Library/Application Support/Mozilla/NativeMessagingHosts/info.nfcreader.host.json`

**Windows (MSI/EXE)**:
- Chrome: Registry key `HKLM\SOFTWARE\Google\Chrome\NativeMessagingHosts\info.nfcreader.host`
- Edge: Registry key `HKLM\SOFTWARE\Microsoft\Edge\NativeMessagingHosts\info.nfcreader.host`
- Firefox: `C:\ProgramData\Mozilla\NativeMessagingHosts\info.nfcreader.host.json`
| Windows | windows-latest | Temurin 11 | MSI, EXE |

### Build Steps

1. **Checkout**: Clone the repository
2. **Setup JDK**: Install Java 11 (Temurin distribution)
3. **Maven Build**: Build with `mvn clean package`
4. **jlink**: Create minimal custom JRE (~42MB)
5. **jpackage**: Create self-contained application
6. **Code Signing**: Sign the application (if secrets configured)
7. **Installer Creation**: Create platform-specific installers
8. **Upload**: Upload artifacts to GitHub

### Artifact Retention

- CI builds: 90 days
- Release builds: Indefinite (attached to GitHub Release)

## Testing Workflows Locally

### Using Act

You can test GitHub Actions locally using [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash  # Linux

# Run CI workflow
act push

# Run release workflow (requires secrets)
act -s MACOS_CERTIFICATE="..." -s WINDOWS_CERTIFICATE="..." push -e .github/workflows/release.yml
```

### Local Build

To test the same build process locally:

```bash
# Run the build script
./build.sh

# Verify the output
ls -lh nfc-reader-host/target/jpackage/
```

## Monitoring Builds

- View workflow runs: **Actions** tab in GitHub
- Download artifacts: Click on a completed workflow run
- View logs: Click on any job to see detailed logs
- Email notifications: Configure in GitHub settings

## Troubleshooting

### Build Fails on Maven Package

- Check Java version (should be 11+)
- Check Maven is correctly configured
- Review test failures in test results artifact

### Code Signing Fails

- Verify secrets are correctly set in repository settings
- Check certificate hasn't expired
- Review signing step logs for specific errors

### jpackage Fails

- Ensure JDK 14+ is used (should be, using JDK 11+)
- Check that custom JRE was created successfully
- Verify platform-specific tools are available

### Release Not Created

- Ensure you pushed a tag (not just created it locally)
- Tag must match pattern `v*` (e.g., v1.0.0)
- Check workflow permissions (Settings → Actions → General)

## Security Considerations

### Secrets Management

- Never commit certificates or passwords
- Rotate secrets periodically
- Use separate certificates for CI/CD vs. production if possible
- Limit secret access to specific workflows

### Workflow Permissions

The workflows require:
- `contents: write` - For creating releases
- `packages: write` - For publishing packages (if enabled)

These are granted via `GITHUB_TOKEN` automatically.

## Customization

### Changing Version Number

Edit `nfc-reader-host/pom.xml`:

```xml
<version>1.0.0</version>
```

Or use Maven versions plugin:

```bash
mvn versions:set -DnewVersion=1.1.0
```

### Adding More Build Steps

Edit the workflow files in `.github/workflows/`:

1. Add new steps to existing jobs
2. Or create new jobs in the workflow
3. Use existing jobs as templates

### Customizing Installers

Modify jpackage parameters in the workflow files:

- `--app-version`: Application version
- `--vendor`: Vendor name
- `--description`: Application description
- `--icon`: Application icon (needs to be added to repo)
- `--license-file`: License file path

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [jpackage Guide](https://docs.oracle.com/en/java/javase/14/jpackage/)
- [Maven Documentation](https://maven.apache.org/guides/)
