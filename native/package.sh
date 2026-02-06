#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT_BIN="$ROOT_DIR/native/NotchPrompter"
APP_DIR="$ROOT_DIR/dist/Notch Prompter.app"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
ARCH=$(uname -m)
TARGET="${ARCH}-apple-macos13.0"

xcrun --sdk macosx swiftc "$ROOT_DIR/native/NotchPrompter.swift" \
  -o "$OUT_BIN" \
  -target "$TARGET" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework Combine \
  -framework AVFoundation

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$OUT_BIN" "$APP_DIR/Contents/MacOS/NotchPrompter"
cp "$ROOT_DIR/native/Info.plist" "$APP_DIR/Contents/Info.plist"

# Ad-hoc sign to reduce Gatekeeper warnings for local sharing.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

mkdir -p "$ROOT_DIR/dist"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ROOT_DIR/dist/NotchPrompter.zip"

echo "Built: $APP_DIR"
echo "Zip:   $ROOT_DIR/dist/NotchPrompter.zip"
