#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="FlowX"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
INSTALL_PATH="/Applications/$APP_NAME.app"

# Check if installed to /Applications, otherwise update in-place
if [ -d "$INSTALL_PATH" ]; then
    TARGET="$INSTALL_PATH"
else
    TARGET="$APP_BUNDLE"
fi

echo "==> Quitting $APP_NAME if running..."
pkill -x "$APP_NAME" 2>/dev/null && sleep 1 || true

echo "==> Building $APP_NAME (release)..."
cd "$SCRIPT_DIR"
swift build -c release 2>&1

echo "==> Generating app icon..."
ICON_PATH="$SCRIPT_DIR/Resources/AppIcon.icns"
swift "$SCRIPT_DIR/Scripts/generate_icon.swift" "$ICON_PATH"

echo "==> Assembling $APP_NAME.app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$SCRIPT_DIR/.build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$SCRIPT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Bundle Secrets.plist (API key — gitignored)
if [ -f "$SCRIPT_DIR/Resources/Secrets.plist" ]; then
    cp "$SCRIPT_DIR/Resources/Secrets.plist" "$APP_BUNDLE/Contents/Resources/Secrets.plist"
    echo "==> Bundled Secrets.plist"
else
    echo "==> WARNING: Resources/Secrets.plist not found — API key will not be bundled!"
fi

# Bundle Sparkle framework
SPARKLE_PATH=$(find "$SCRIPT_DIR/.build" -name "Sparkle.framework" -type d 2>/dev/null | head -1)
if [ -n "$SPARKLE_PATH" ]; then
    mkdir -p "$APP_BUNDLE/Contents/Frameworks"
    cp -R "$SPARKLE_PATH" "$APP_BUNDLE/Contents/Frameworks/"
    echo "==> Bundled Sparkle.framework"
fi

# Set rpath so the binary finds Sparkle.framework in Contents/Frameworks
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP_BUNDLE/Contents/MacOS/$APP_NAME" 2>/dev/null || true

if [ -f "$SCRIPT_DIR/$APP_NAME.entitlements" ]; then
    # Use stable "FlowX Dev" identity if available, otherwise fall back to ad-hoc
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "FlowX Dev" | head -1 | awk -F'"' '{print $2}')
    if [ -n "$SIGN_IDENTITY" ]; then
        codesign --force --deep --sign "$SIGN_IDENTITY" --entitlements "$SCRIPT_DIR/$APP_NAME.entitlements" "$APP_BUNDLE"
        echo "==> Signed with $SIGN_IDENTITY (stable identity)"
    else
        codesign --force --deep --sign - --entitlements "$SCRIPT_DIR/$APP_NAME.entitlements" "$APP_BUNDLE"
        echo "==> Signed ad-hoc (accessibility may need re-granting after rebuilds)"
    fi
fi

# If installed in /Applications, replace it
if [ "$TARGET" = "$INSTALL_PATH" ]; then
    echo "==> Updating $INSTALL_PATH..."
    rm -rf "$INSTALL_PATH"
    cp -R "$APP_BUNDLE" "$INSTALL_PATH"
fi

echo "==> Launching $APP_NAME..."
open "$TARGET"

echo ""
echo "==> Done! $APP_NAME is up and running."
