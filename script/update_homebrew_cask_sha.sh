#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${FOX_VERSION:-1.0.0}"
FORMULA="$ROOT_DIR/homebrew/foxclean.rb"
SHA_FILE="$ROOT_DIR/dist/FoxClean-$VERSION.dmg.sha256"

[[ -s "$FORMULA" ]] || {
  echo "missing Homebrew cask: $FORMULA" >&2
  exit 1
}

[[ -s "$SHA_FILE" ]] || {
  echo "missing DMG SHA-256 sidecar: $SHA_FILE" >&2
  exit 1
}

sha="$(awk '{print $1}' "$SHA_FILE")"
if [[ ! "$sha" =~ ^[0-9a-f]{64}$ ]]; then
  echo "invalid SHA-256 in $SHA_FILE: $sha" >&2
  exit 1
fi

FOX_SHA="$sha" ruby -0pi -e 'gsub(/^  sha256 (?::no_check|"[0-9a-f]{64}")$/, "  sha256 \"#{ENV.fetch("FOX_SHA")}\"")' "$FORMULA"

if ! rg -q "^  sha256 \"$sha\"$" "$FORMULA"; then
  echo "failed to update Homebrew cask SHA-256" >&2
  exit 1
fi

echo "Updated homebrew/foxclean.rb sha256 to $sha"
