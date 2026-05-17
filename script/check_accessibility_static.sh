#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required_patterns=(
  'accessibilityLabel\("FoxClean sidebar"\)'
  'accessibilityLabel\("Full Disk Access status"\)'
  'accessibilityLabel\("Disk usage treemap"\)'
  'accessibilityLabel\("CPU history"\)'
  'accessibilityLabel\("Storage used"\)'
  'accessibilityLabel\("Scan progress"\)'
  'accessibilityLabel\("Optimization result"\)'
  'accessibilityDescription: "FoxClean"'
  'accessibilityReduceMotion'
  'Toggle\("Reduce Foxie animations"'
  'FoxClean also follows the macOS Reduce Motion setting'
  'Button\("Keyboard Shortcuts"'
  'accessibilityLabel\("Keyboard shortcuts"\)'
)

for pattern in "${required_patterns[@]}"; do
  rg -q "$pattern" FoxCleanApp || {
    echo "missing accessibility pattern: $pattern" >&2
    exit 1
  }
done

echo "Accessibility static checks passed."
