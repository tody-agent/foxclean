#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required=(
  ".github/workflows/build.yml"
  ".github/workflows/test.yml"
  ".github/workflows/lint.yml"
  ".github/workflows/release.yml"
  ".github/workflows/pages.yml"
)

for file in "${required[@]}"; do
  [[ -s "$file" ]] || {
    echo "missing workflow: $file" >&2
    exit 1
  }
  ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0))' "$file"
  rg -q '^on:' "$file"
  rg -q 'runs-on: macos-15' "$file"
done

rg -q 'xcodegen generate' .github/workflows/build.yml
rg -q 'xcodebuild -scheme FoxCleanApp' .github/workflows/build.yml
rg -q 'swift test' .github/workflows/test.yml
rg -q 'brew bundle' .github/workflows/lint.yml
rg -q './script/check_telemetry_free.sh' .github/workflows/lint.yml
rg -q './script/check_localization.sh' .github/workflows/lint.yml
rg -q './script/check_accessibility_static.sh' .github/workflows/lint.yml
rg -q './script/check_app_runtime_static.sh' .github/workflows/lint.yml
rg -q './script/check_homebrew_formula.sh' .github/workflows/lint.yml
rg -q './script/check_release_docs.sh' .github/workflows/lint.yml
rg -q './script/check_pages_site.sh' .github/workflows/lint.yml
rg -q './script/package_release.sh' .github/workflows/release.yml
rg -q 'APPLE_API_KEY_ID' .github/workflows/release.yml
rg -q 'APPLE_API_ISSUER_ID' .github/workflows/release.yml
rg -q 'softprops/action-gh-release@v2' .github/workflows/release.yml
rg -q 'actions/upload-artifact@v4' .github/workflows/release.yml
rg -q 'dist/FoxClean-\*\.dmg\.sha256' .github/workflows/release.yml
rg -q 'homebrew/foxclean\.rb' .github/workflows/release.yml
rg -q 'enablement: true' .github/workflows/pages.yml
rg -q 'actions/deploy-pages@v4' .github/workflows/pages.yml

echo "GitHub workflow static checks passed."
