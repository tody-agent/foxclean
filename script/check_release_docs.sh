#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required_docs=(
  "docs/release/IMPLEMENTATION_AUDIT.md"
  "docs/release/SPEC_TRACEABILITY.md"
  "docs/release/QA.md"
  "docs/release/RELEASE_NOTES_v1.0.0.md"
  "docs/release/LAUNCH_POSTS.md"
)

for file in "${required_docs[@]}"; do
  [[ -s "$file" ]] || {
    echo "missing release doc: $file" >&2
    exit 1
  }
done

required_patterns=(
  'script/verify_local.sh --launch --package'
  'script/release_preflight.sh'
  'FoxClean-1.0.0.dmg.sha256'
  'Show HN: FoxClean'
  'Product Hunt'
  'Download: https://github.com/tody-agent/foxclean/releases/latest'
)

for pattern in "${required_patterns[@]}"; do
  rg -q "$pattern" docs/release || {
    echo "missing release doc pattern: $pattern" >&2
    exit 1
  }
done

echo "Release documentation checks passed."
