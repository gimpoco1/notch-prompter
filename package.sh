#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_BIN="$ROOT_DIR/NotchPrompter"
APP_DIR="$ROOT_DIR/dist/Notch Prompter.app"
ICON_PNG="$ROOT_DIR/icon.png"
ICONSET_DIR="$ROOT_DIR/.build/AppIcon.iconset"
ICON_ICNS="$ROOT_DIR/.build/AppIcon.icns"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
ARCH=$(uname -m)
TARGET="${ARCH}-apple-macos13.0"

xcrun --sdk macosx swiftc "$ROOT_DIR/NotchPrompter.swift" \
  -o "$OUT_BIN" \
  -target "$TARGET" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework Combine \
  -framework AVFoundation

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$OUT_BIN" "$APP_DIR/Contents/MacOS/NotchPrompter"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/config.json" "$APP_DIR/Contents/Resources/config.json"

if [ -f "$ICON_PNG" ]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"
  for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    sips -z "$((size * 2))" "$((size * 2))" "$ICON_PNG" --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET_DIR" -o "$ICON_ICNS"
  cp "$ICON_ICNS" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign to reduce Gatekeeper warnings for local sharing.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

mkdir -p "$ROOT_DIR/dist"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ROOT_DIR/dist/NotchPrompter.zip"

echo "Built: $APP_DIR"
echo "Zip:   $ROOT_DIR/dist/NotchPrompter.zip"
