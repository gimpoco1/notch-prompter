#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT="$ROOT_DIR/NotchPrompter"

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
ARCH=$(uname -m)

# Use a conservative deployment target so the binary runs on your current macOS.
TARGET="${ARCH}-apple-macos13.0"

xcrun --sdk macosx swiftc "$ROOT_DIR/NotchPrompter.swift" \
  -o "$OUT" \
  -target "$TARGET" \
  -framework Cocoa \
  -framework SwiftUI \
  -framework Combine \
  -framework AVFoundation \
  -Xlinker -sectcreate \
  -Xlinker __TEXT \
  -Xlinker __info_plist \
  -Xlinker "$ROOT_DIR/Info.plist"

"$OUT"
