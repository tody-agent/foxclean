#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FoxClean"
BUNDLE="$ROOT/dist/${APP_NAME}.app"

cd "$ROOT"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ! -d FoxClean.xcodeproj ]]; then
  xcodegen generate
fi

xcodebuild -scheme FoxCleanApp -destination 'platform=macOS' build

APP_PATH="$(find "$HOME/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/*/${APP_NAME}.app" -maxdepth 8 -type d 2>/dev/null | tail -n 1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Built app bundle not found" >&2
  exit 1
fi

rm -rf "$BUNDLE"
mkdir -p "$(dirname "$BUNDLE")"
cp -R "$APP_PATH" "$BUNDLE"
/usr/bin/open -n "$BUNDLE"

if [[ "${1:-}" == "--verify" ]]; then
  sleep 2
  pgrep -x "$APP_NAME" >/dev/null
fi
