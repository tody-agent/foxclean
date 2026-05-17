#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if rg -q 'MenuBarExtra' FoxCleanApp; then
  echo "SwiftUI MenuBarExtra is disabled for FoxClean because it regressed startup responsiveness." >&2
  exit 1
fi

required_patterns=(
  'menuBarController = MenuBarController\(\)'
  'NSStatusItem'
  'NSPopover'
  'NSStatusBar\.system\.statusItem'
  '@State private var selectedSection'
)

for pattern in "${required_patterns[@]}"; do
  rg -q "$pattern" FoxCleanApp || {
    echo "missing app runtime pattern: $pattern" >&2
    exit 1
  }
done

echo "App runtime static checks passed."
