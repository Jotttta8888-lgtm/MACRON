#!/bin/bash
APP="/Applications/MACRON.app"
DEVELOPER_ID="Developer ID Application: TU_NOMBRE"
echo "=== MACRON Distribution ==="
codesign --force --options runtime --deep --sign "$DEVELOPER_ID" "$APP"
hdiutil create -volname "MACRON" -srcfolder "$APP" -ov -format UDZO "$HOME/Desktop/MACRON.dmg"
xcrun notarytool submit "$HOME/Desktop/MACRON.dmg" --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple "$HOME/Desktop/MACRON.dmg"
echo "✅ Listo: $HOME/Desktop/MACRON.dmg"
