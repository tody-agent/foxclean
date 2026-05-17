#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required=(en vi es ja zh-Hans zh-Hant ar)
base="FoxCleanApp/en.lproj/Localizable.strings"

[[ -s "$base" ]] || {
  echo "missing base localization: $base" >&2
  exit 1
}
[[ -s "Resources/Localizable.xcstrings" ]] || {
  echo "missing Resources/Localizable.xcstrings" >&2
  exit 1
}

extract_keys() {
  ruby -ne 'puts $1 if $_ =~ /^\s*"((?:\\"|[^"])*)"\s*=/' "$1" | sort
}

base_keys="$(mktemp)"
extract_keys "$base" > "$base_keys"
trap 'rm -f "$base_keys" "$tmp_keys"' EXIT

for locale in "${required[@]}"; do
  file="FoxCleanApp/$locale.lproj/Localizable.strings"
  [[ -s "$file" ]] || {
    echo "missing locale file: $file" >&2
    exit 1
  }
  tmp_keys="$(mktemp)"
  extract_keys "$file" > "$tmp_keys"
  if ! diff -u "$base_keys" "$tmp_keys" >/tmp/foxclean-localization-diff.txt; then
    echo "localization key mismatch for $locale" >&2
    cat /tmp/foxclean-localization-diff.txt >&2
    exit 1
  fi
  rm -f "$tmp_keys"
done

for locale in "${required[@]}"; do
  rg -q "\"$locale\"" Resources/Localizable.xcstrings || {
    echo "Resources/Localizable.xcstrings missing locale marker: $locale" >&2
    exit 1
  }
done

echo "Localization checks passed for ${required[*]}."
