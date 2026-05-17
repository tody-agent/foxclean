#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FoxClean"
VERSION="${FOX_VERSION:-1.0.0}"
DERIVED_DATA="$ROOT_DIR/.build/release-derived-data"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/release"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
DMG_SHA_PATH="$DMG_PATH.sha256"

cd "$ROOT_DIR"

if command -v xcodegen >/dev/null 2>&1; then
  xcodegen generate
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

xcodebuild \
  -scheme FoxCleanApp \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM="" \
  build

BUILT_APP="$(find "$DERIVED_DATA/Build/Products/Release" -maxdepth 2 -name "$APP_NAME.app" -type d | head -n 1)"
if [[ -z "$BUILT_APP" ]]; then
  echo "Release app bundle not found." >&2
  exit 1
fi

cp -R "$BUILT_APP" "$APP_BUNDLE"
ln -s /Applications "$STAGING_DIR/Applications"
"$APP_BUNDLE/Contents/Resources/fox" --version >/dev/null

require_universal() {
  local binary="$1"
  local archs
  archs="$(lipo -archs "$binary")"
  if [[ "$archs" != *"arm64"* || "$archs" != *"x86_64"* ]]; then
    echo "Expected universal arm64+x86_64 binary at $binary, got: $archs" >&2
    exit 1
  fi
}

require_universal "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
require_universal "$APP_BUNDLE/Contents/Resources/fox"
require_universal "$APP_BUNDLE/Contents/Frameworks/FoxCleanCore.framework/Versions/A/FoxCleanCore"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  codesign --force --deep --options runtime --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$APP_BUNDLE"
else
  echo "skip: DEVELOPER_ID_APPLICATION not set; producing unsigned local DMG."
fi

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
  codesign --force --timestamp --sign "$DEVELOPER_ID_APPLICATION" "$DMG_PATH"
fi

if [[ -n "${APPLE_API_KEY_PATH:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --key "$APPLE_API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_ISSUER_ID" \
    --wait
  xcrun stapler staple "$DMG_PATH"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
else
  echo "skip: notarization env vars are not set."
fi

(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$DMG_PATH")" >"$(basename "$DMG_SHA_PATH")"
)

"$ROOT_DIR/script/update_homebrew_cask_sha.sh"

echo "$DMG_PATH"
