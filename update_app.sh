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

if [ -f "$SCRIPT_DIR/$APP_NAME.entitlements" ]; then
    # Use stable "FlowX Dev" identity if available, otherwise fall back to ad-hoc
    SIGN_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "FlowX Dev" | head -1 | awk -F'"' '{print $2}')
    if [ -n "$SIGN_IDENTITY" ]; then
        codesign --force --sign "$SIGN_IDENTITY" --entitlements "$SCRIPT_DIR/$APP_NAME.entitlements" "$APP_BUNDLE"
        echo "==> Signed with $SIGN_IDENTITY (stable identity)"
    else
        codesign --force --sign - --entitlements "$SCRIPT_DIR/$APP_NAME.entitlements" "$APP_BUNDLE"
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
