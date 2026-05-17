#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

[[ -s docs/site/index.html ]] || {
  echo "missing docs/site/index.html" >&2
  exit 1
}

[[ -s FoxCleanApp/Assets.xcassets/AppIcon.appiconset/icon_512.png ]] || {
  echo "missing source app icon for Pages site" >&2
  exit 1
}

required_site_patterns=(
  '<title>FoxClean</title>'
  'brew install --cask foxclean'
  'No telemetry'
  'assets/icon_512.png'
)

for pattern in "${required_site_patterns[@]}"; do
  rg -q "$pattern" docs/site/index.html || {
    echo "missing Pages site pattern: $pattern" >&2
    exit 1
  }
done

required_workflow_patterns=(
  'actions/configure-pages@v5'
  'enablement: true'
  'actions/upload-pages-artifact@v3'
  'actions/deploy-pages@v4'
  'cp FoxCleanApp/Assets.xcassets/AppIcon.appiconset/icon_512.png docs/site/assets/icon_512.png'
)

for pattern in "${required_workflow_patterns[@]}"; do
  rg -q "$pattern" .github/workflows/pages.yml || {
    echo "missing Pages workflow pattern: $pattern" >&2
    exit 1
  }
done

ruby -e 'require "yaml"; YAML.load_file(".github/workflows/pages.yml")'

echo "GitHub Pages site static checks passed."
