#!/bin/bash
# Windows Build Script for NFC Reader Host (Git Bash compatible)
# Replicates the GitHub Actions workflow for local builds

set -e  # Exit on error

VERSION=${1:-"1.0.0"}

echo "========================================"
echo "Building NFC Reader Host for Windows"
echo "Version: $VERSION"
echo "========================================"

# Change to nfc-reader-host directory
cd nfc-reader-host

# Step 1: Build with Maven
echo ""
echo "[1/5] Building with Maven..."
mvn clean package

# Step 2: Create custom JRE
echo ""
echo "[2/5] Creating custom JRE..."
rm -rf target/custom-jre
jlink \
    --add-modules java.base,java.smartcardio \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-6 \
    --strip-java-debug-attributes \
    --output target/custom-jre

# Step 3: Create jpackage app-image
echo ""
echo "[3/5] Creating jpackage app-image..."
rm -rf target/jpackage-input
mkdir -p target/jpackage-input
cp target/nfc-reader-host-fat.jar target/jpackage-input/

rm -rf target/jpackage
jpackage \
    --input target/jpackage-input \
    --name nfc-reader-host \
    --main-jar nfc-reader-host-fat.jar \
    --main-class info.nfcreader.host.Main \
    --type app-image \
    --runtime-image target/custom-jre \
    --dest target/jpackage

# Step 4: Check for ImageMagick and create application icon
echo ""
echo "[4/5] Creating application icon..."
if ! command -v magick &> /dev/null; then
    echo "ImageMagick not found. Please install ImageMagick."
    echo "You can install it via Chocolatey: choco install imagemagick -y"
    echo "Or download from: https://imagemagick.org/script/download.php"
    exit 1
fi

# Create the icon
mkdir -p src/main/resources/windows
magick \
    src/main/resources/icons/icon-16.png \
    src/main/resources/icons/icon-32.png \
    src/main/resources/icons/icon-48.png \
    src/main/resources/icons/icon-128.png \
    src/main/resources/windows/app-icon.ico

# Step 5: Build MSI with WiX (flattened structure)
echo ""
echo "[5/5] Building MSI installer with WiX..."
mkdir -p target/installers target/wix-build

# Copy application files and flatten JSON files to root
cp -r target/jpackage/nfc-reader-host/* target/wix-build/
cp target/installer-scripts/windows/info.nfcreader.host.json target/wix-build/
cp target/installer-scripts/windows/info.nfcreader.host.firefox.json target/wix-build/

# Set WiX tools path
export WIX="/c/Program Files (x86)/WiX Toolset v3.14"
export PATH="$WIX/bin:$PATH"

# Harvest application files
heat.exe dir target/wix-build \
    -cg ApplicationFiles \
    -gg \
    -scom \
    -sreg \
    -sfrag \
    -srd \
    -dr INSTALLDIR \
    -var var.SourceDir \
    -out target/files.wxs

# Compile WiX sources
candle.exe \
    -dSourceDir=target/wix-build \
    -dVersion="$VERSION" \
    -arch x64 \
    -ext WixUtilExtension \
    -out target/ \
    src/main/resources/windows/installer.wxs \
    target/files.wxs

# Link into MSI
light.exe \
    -out target/installers/nfc-reader-host-$VERSION.msi \
    target/installer.wixobj \
    target/files.wixobj \
    -b src/main/resources/windows \
    -ext WixUIExtension \
    -ext WixUtilExtension \
    -sval

cd ..

echo ""
echo "========================================"
echo "Build Complete!"
echo "========================================"
echo "Installers created in: nfc-reader-host/target/installers/"
echo ""
ls -lh nfc-reader-host/target/installers/
echo ""
