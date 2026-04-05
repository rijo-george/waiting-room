#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="The Waiting Room"
DMG_NAME="WaitingRoom"
VERSION="1.0.0"
DMG_FINAL="$SCRIPT_DIR/$DMG_NAME-$VERSION.dmg"
DMG_TEMP="$SCRIPT_DIR/_dmg_temp.dmg"
STAGING="$SCRIPT_DIR/_dmg_staging"

SIGN_IDENTITY="Developer ID Application: RIJO GEORGE (K8383Q54VB)"
TEAM_ID="K8383Q54VB"

echo "==> Building and signing app..."
bash build-app.sh

echo "==> Preparing DMG staging..."
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp -R "$SCRIPT_DIR/$APP_NAME.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# Background image
mkdir -p "$STAGING/.background"
cat > /tmp/dmg_bg.py << 'PYEOF'
import os
width, height = 600, 400
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}">
  <rect width="100%" height="100%" fill="#1a1a2e"/>
  <text x="300" y="60" text-anchor="middle" font-family="Helvetica Neue" font-size="16" font-weight="bold" fill="#7b68ee">The Waiting Room</text>
  <text x="300" y="260" text-anchor="middle" font-family="Helvetica Neue" font-size="13" fill="#666688">Drag the app to Applications</text>
</svg>'''
with open("/tmp/dmg_bg.svg", "w") as f:
    f.write(svg)
os.system(f'qlmanage -t -s {width}x{height} -o /tmp "/tmp/dmg_bg.svg" 2>/dev/null && mv "/tmp/dmg_bg.svg.png" "/tmp/dmg_bg.png" 2>/dev/null || true')
PYEOF
python3 /tmp/dmg_bg.py 2>/dev/null || true
[ -f /tmp/dmg_bg.png ] && cp /tmp/dmg_bg.png "$STAGING/.background/bg.png"

SIZE_KB=$(du -sk "$STAGING" | awk '{print $1}')
SIZE_KB=$((SIZE_KB + 10240))

echo "==> Creating DMG..."
rm -f "$DMG_TEMP" "$DMG_FINAL"

hdiutil create -srcfolder "$STAGING" \
    -volname "$APP_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE_KB}k \
    "$DMG_TEMP"

MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | \
    grep "/Volumes/" | awk -F'\t' '{print $NF}')

echo "==> Configuring DMG layout..."
osascript << APPLESCRIPT
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {200, 120, 800, 520}
        set theViewOptions to icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 80
        set position of item "$APP_NAME.app" of container window to {150, 180}
        set position of item "Applications" of container window to {450, 180}
        try
            set background picture of theViewOptions to file ".background:bg.png"
        end try
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$MOUNT_DIR"

echo "==> Compressing DMG..."
hdiutil convert "$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DMG_FINAL"
rm -rf "$STAGING" "$DMG_TEMP"

# Sign the DMG itself
echo "==> Signing DMG..."
codesign --force --sign "$SIGN_IDENTITY" "$DMG_FINAL"

# Notarize
echo "==> Submitting for notarization..."
echo "    (This uploads to Apple and waits for approval — may take a few minutes)"

xcrun notarytool submit "$DMG_FINAL" \
    --keychain-profile "notary" \
    --wait 2>&1 || {
    echo ""
    echo "!! Notarization requires a stored keychain profile."
    echo "!! Run this once to set it up:"
    echo ""
    echo "   xcrun notarytool store-credentials \"notary\" \\"
    echo "       --apple-id YOUR_APPLE_ID@email.com \\"
    echo "       --team-id $TEAM_ID"
    echo ""
    echo "   (It will ask for an app-specific password."
    echo "    Generate one at https://appleid.apple.com/account/manage → App-Specific Passwords)"
    echo ""
    echo "   Then re-run this script."
    exit 1
}

# Staple the notarization ticket to the DMG
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$DMG_FINAL"

echo ""
echo "========================================="
echo "  DMG created, signed, and notarized!"
echo "  $DMG_FINAL"
echo "  Size: $(du -sh "$DMG_FINAL" | awk '{print $1}')"
echo "========================================="
echo ""
echo "Anyone can now open this with zero warnings."
echo "To test: open \"$DMG_FINAL\""
