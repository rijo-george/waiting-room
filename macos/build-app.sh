#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SIGN_IDENTITY="Developer ID Application: RIJO GEORGE (K8383Q54VB)"
TEAM_ID="K8383Q54VB"

echo "==> Building WaitingRoom..."
swift build -c release --arch arm64 --arch x86_64 2>&1

APP_DIR="$SCRIPT_DIR/The Waiting Room.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES"

cp .build/apple/Products/Release/WaitingRoom "$MACOS_DIR/WaitingRoom"
cp Info.plist "$CONTENTS/Info.plist"
cp AppIcon.icns "$RESOURCES/AppIcon.icns"
echo -n "APPL????" > "$CONTENTS/PkgInfo"

echo "==> Code signing..."
codesign --force --options runtime --timestamp \
    --entitlements "$SCRIPT_DIR/WaitingRoom.entitlements" \
    --sign "$SIGN_IDENTITY" \
    "$APP_DIR"

echo "==> Verifying signature..."
codesign --verify --verbose "$APP_DIR"

echo ""
echo "Built and signed: $APP_DIR"
echo "Run with: open \"$APP_DIR\""
