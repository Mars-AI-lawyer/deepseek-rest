#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$PROJECT_DIR/DeepSeekBalance"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="DeepSeekBalance"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

echo "=== Step 1: Process icon ==="
python3 "$PROJECT_DIR/prepare_icon.py"

echo "=== Step 2: Clean build ==="
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "=== Step 3: Compile Swift sources ==="
swiftc \
    -target arm64-apple-macos12.0 \
    -o "$MACOS_DIR/$APP_NAME" \
    "$SOURCE_DIR/main.swift" \
    "$SOURCE_DIR/AppDelegate.swift" \
    "$SOURCE_DIR/DeepSeekAPI.swift" \
    "$SOURCE_DIR/KeychainManager.swift" \
    "$SOURCE_DIR/TokenPromptController.swift" \
    "$SOURCE_DIR/BalanceViewController.swift" \
    "$SOURCE_DIR/MiMoAPI.swift" \
    "$SOURCE_DIR/MiMoLoginWindowController.swift" \
    "$SOURCE_DIR/MiMoBalanceViewController.swift"

echo "=== Step 4: Copy resources ==="
cp "$SOURCE_DIR/Assets/status_icon.png" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/Assets/status_icon@2x.png" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/Assets/status_icon@3x.png" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/Assets/AppIcon.icns" "$RESOURCES_DIR/"
cp "$SOURCE_DIR/Info.plist" "$CONTENTS/"

echo "=== Step 5: Sign (ad-hoc) ==="
codesign --force --sign - "$APP_BUNDLE" 2>/dev/null || echo "Ad-hoc signing skipped (non-critical)"

echo "=== Done ==="
echo "App bundle at: $APP_BUNDLE"
echo "Run with: open '$APP_BUNDLE'"
