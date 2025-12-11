#!/bin/bash

# Universal build script for NFC Reader Host
# Creates self-contained JAR with minimal JRE
# Works on Linux, macOS, and Windows (via Git Bash/WSL)

set -e

echo "Building NFC Reader Host - Self-Contained JAR"
echo "=============================================="
echo ""

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM=linux;;
    Darwin*)    PLATFORM=macos;;
    CYGWIN*|MINGW*|MSYS*)    PLATFORM=windows;;
    *)          PLATFORM=unknown;;
esac

echo "Detected platform: $PLATFORM"
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo "Error: Maven not found!"
    echo "Please install Maven: https://maven.apache.org/install.html"
    exit 1
fi

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Error: Java not found!"
    echo "Please install Java JDK 11 or later"
    exit 1
fi

# Navigate to project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/nfc-reader-host"

echo "Building with Maven..."
mvn clean package

echo ""
echo "Creating minimal JRE with jlink..."

# Only include essential modules
MODULES="java.base,java.smartcardio"
echo "Using modules: $MODULES"

# Platform-specific library extension
case "$PLATFORM" in
    macos)   LIB_EXT="dylib";;
    windows) LIB_EXT="dll";;
    *)       LIB_EXT="so";;
esac

# Create custom JRE with only needed modules
jlink \
  --add-modules "$MODULES" \
  --strip-debug \
  --no-man-pages \
  --no-header-files \
  --compress=zip-6 \
  --strip-java-debug-attributes \
  --output target/custom-jre

echo "Custom JRE size: $(du -sh target/custom-jre | cut -f1)"

echo ""
echo "Creating self-contained executable with jpackage..."

# Create a clean input directory with only the JAR
mkdir -p target/jpackage-input
cp target/nfc-reader-host-fat.jar target/jpackage-input/

# Create jpackage runtime image with custom JRE
jpackage \
  --input target/jpackage-input \
  --name nfc-reader-host \
  --main-jar nfc-reader-host-fat.jar \
  --main-class info.nfcreader.host.Main \
  --type app-image \
  --runtime-image target/custom-jre \
  --dest target/jpackage

echo ""
echo "==============================================="
echo "Build Complete!"
echo "==============================================="
echo ""
echo "JAR location: target/nfc-reader-host-fat.jar"
echo "Custom JRE: target/custom-jre/ ($(du -sh target/custom-jre | cut -f1))"

# Platform-specific output location
case "$PLATFORM" in
    macos)
        APP_PATH="target/jpackage/nfc-reader-host.app"
        EXECUTABLE="$APP_PATH/Contents/MacOS/nfc-reader-host"
        echo "Self-contained app: $APP_PATH ($(du -sh $APP_PATH | cut -f1))"
        echo ""
        echo "The jpackage version includes a minimal bundled JRE and can run standalone."
        echo ""
        echo "IMPORTANT: Code Signing (macOS Catalina and later)"
        echo "For distribution, you should sign the app:"
        echo "  codesign -s 'Developer ID' --deep $APP_PATH"
        ;;
    windows)
        APP_PATH="target/jpackage/nfc-reader-host"
        EXECUTABLE="$APP_PATH/nfc-reader-host.exe"
        echo "Self-contained app: $APP_PATH"
        echo ""
        echo "The jpackage version includes a minimal bundled JRE and can run standalone."
        ;;
    *)
        APP_PATH="target/jpackage/nfc-reader-host"
        EXECUTABLE="$APP_PATH/bin/nfc-reader-host"
        echo "Self-contained app: $APP_PATH ($(du -sh $APP_PATH | cut -f1))"
        echo ""
        echo "The jpackage version includes a minimal bundled JRE and can run standalone."
        ;;
esac

echo ""
echo "Next steps:"
echo "  1. Test the JAR: java -jar target/nfc-reader-host-fat.jar list-readers"
echo "  2. Test jpackage: $EXECUTABLE list-readers"
echo "  3. Install: cd ../install/$PLATFORM && ./install.sh"
echo ""
