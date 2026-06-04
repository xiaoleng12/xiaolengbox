#!/bin/bash
# ============================================
#  XiaoLengBox Build Script
#  小冷工具箱 编译脚本
# ============================================
#  Usage / 用法:
#    ./build.sh          # Build debug version / 编译调试版
#    ./build.sh release  # Build release version + .app / 编译正式版并打包
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="小冷工具箱"
BUNDLE_ID="com.xiaolengbox.app"
VERSION="3.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 XiaoLengBox Build Script${NC}"
echo "================================"

# Check Swift is available
if ! command -v swift &> /dev/null; then
    echo -e "${RED}Error: Swift not found. Please install Xcode Command Line Tools:${NC}"
    echo "  xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "Swift: $SWIFT_VERSION"

# Build mode
if [ "$1" = "release" ]; then
    MODE="release"
    echo -e "${YELLOW}Mode: Release${NC}"
else
    MODE="debug"
    echo -e "${YELLOW}Mode: Debug${NC}"
fi

echo ""
echo "Building..."

# Run swift build
if [ "$MODE" = "release" ]; then
    swift build -c release
    BINARY=".build/release/XiaoLengBox"
else
    swift build
    BINARY=".build/debug/XiaoLengBox"
fi

echo -e "${GREEN}✓ Build successful${NC}"

# Package as .app (release only)
if [ "$MODE" = "release" ]; then
    echo ""
    echo "Packaging .app bundle..."

    APP_DIR="${APP_NAME}.app"
    rm -rf "$APP_DIR"
    mkdir -p "$APP_DIR/Contents/MacOS"
    mkdir -p "$APP_DIR/Contents/Resources"

    # Copy binary
    cp "$BINARY" "$APP_DIR/Contents/MacOS/"

    # Copy resources
    if [ -d "Resources" ]; then
        cp -R Resources/* "$APP_DIR/Contents/Resources/" 2>/dev/null || true
    fi

    # Create Info.plist
    cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>XiaoLengBox</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
</dict>
</plist>
PLIST

    echo -e "${GREEN}✓ App bundle created: ${APP_DIR}${NC}"
    echo ""
    echo "To run:"
    echo -e "  ${YELLOW}open \"${APP_DIR}\"${NC}"
    echo ""
    echo "App bundle contents:"
    find "$APP_DIR" -type f | sed 's/^/  /'
else
    echo ""
    echo "To run:"
    echo -e "  ${YELLOW}swift run${NC}"
    echo ""
    echo "To build release version with .app bundle:"
    echo -e "  ${YELLOW}./build.sh release${NC}"
fi

echo ""
echo -e "${GREEN}Done!${NC}"
