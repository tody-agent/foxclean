#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMULA="$ROOT_DIR/homebrew/foxclean.rb"

[[ -s "$FORMULA" ]] || {
  echo "missing Homebrew cask: $FORMULA" >&2
  exit 1
}

rg -q '^cask "foxclean" do$' "$FORMULA"
rg -q 'version "1\.0\.0"' "$FORMULA"
rg -q '^  sha256 "[0-9a-f]{64}"$' "$FORMULA"
rg -q 'github.com/foxclean/foxclean/releases/download/v#\{version\}/FoxClean-#\{version\}\.dmg' "$FORMULA"
rg -q 'app "FoxClean\.app"' "$FORMULA"
rg -q 'binary "#\{appdir\}/FoxClean\.app/Contents/Resources/fox"' "$FORMULA"
rg -q 'zap trash:' "$FORMULA"

ruby -c "$FORMULA" >/dev/null

SHA_FILE="$ROOT_DIR/dist/FoxClean-1.0.0.dmg.sha256"
if [[ -s "$SHA_FILE" ]]; then
  artifact_sha="$(awk '{print $1}' "$SHA_FILE")"
  rg -q "^  sha256 \"$artifact_sha\"$" "$FORMULA" || {
    echo "Homebrew cask sha256 does not match $SHA_FILE" >&2
    exit 1
  }
fi

echo "Homebrew cask static checks passed."
