#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${FOX_VERSION:-1.0.0}"
STRICT=0
FAILURES=0
WARNINGS=0

usage() {
  cat <<'USAGE'
Usage: script/completion_audit.sh [--strict]

Audits the user objective against concrete local artifacts:
  - spec/sped inputs
  - PureMac and Mole source folders
  - OpenSpec structure
  - app/core/CLI project artifacts
  - verifier evidence
  - local DMG/checksum/Homebrew release artifacts
  - external/manual release blockers via release_preflight

By default this reports incomplete external gates but exits 0. With --strict,
missing artifacts or external blockers return non-zero.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --strict)
      STRICT=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 64
      ;;
  esac
done

pass() {
  printf 'pass: %s\n' "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf 'warn: %s\n' "$1"
}

fail() {
  FAILURES=$((FAILURES + 1))
  printf 'fail: %s\n' "$1"
}

require_file() {
  local path="$1"
  local label="$2"
  if [[ -s "$path" ]]; then
    pass "$label: $path"
  else
    fail "$label missing: $path"
  fi
}

require_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$path" ]]; then
    pass "$label: $path"
  else
    fail "$label missing: $path"
  fi
}

require_log_contains() {
  local log="$1"
  local pattern="$2"
  local label="$3"
  if [[ -s "$log" ]] && rg -q "$pattern" "$log"; then
    pass "$label"
  else
    fail "$label missing evidence in $log"
  fi
}

cd "$ROOT_DIR"

echo "FoxClean completion audit"
echo
echo "Objective:"
echo "Read sped.md/spec.md, use the two downloaded source folders, implement FoxClean as fully as possible automatically, and verify completion without asking for more input."
echo

echo "==> Prompt inputs"
require_file "spec.md" "project spec"
require_file "sped.md" "sped alias"
require_dir "PureMac" "PureMac source folder"
require_dir "Mole" "Mole source folder"

echo
echo "==> Project artifacts"
require_file "Package.swift" "Swift package"
require_file "project.yml" "XcodeGen project definition"
require_dir "FoxCleanApp" "macOS app target"
require_dir "Sources/FoxCleanCore" "shared core target"
require_dir "Sources/FoxCleanCLI" "CLI target"
require_file "LICENSE" "MIT license"
require_file "NOTICE" "source credits"

echo
echo "==> OpenSpec"
for change in \
  add-foxclean-foundation \
  add-scan-clean-core \
  add-gui-onboarding-mascot \
  add-clean-uninstall-orphans \
  add-disk-analyzer-system-monitor \
  add-purge-installer-optimize \
  add-cli-menubar-launchers \
  add-polish-i18n-release; do
  require_file "openspec/changes/$change/proposal.md" "OpenSpec $change proposal"
  require_file "openspec/changes/$change/design.md" "OpenSpec $change design"
  require_file "openspec/changes/$change/tasks.md" "OpenSpec $change tasks"
done

echo
echo "==> Verification evidence"
require_log_contains ".build/verification/swift-test.log" "Test Suite.*passed|✔" "swift test log exists"
require_log_contains ".build/verification/xcodebuild-app.log" "BUILD SUCCEEDED" "FoxCleanApp build succeeded"
require_log_contains ".build/verification/app-responsive.log" "responsive guard passed" "app responsiveness guard passed"
require_log_contains ".build/verification/app-runtime-static.log" "App runtime static checks passed" "runtime static guard passed"
require_log_contains ".build/verification/pages-site.log" "GitHub Pages site static checks passed" "Pages static guard passed"
require_log_contains ".build/verification/release-docs.log" "Release documentation checks passed" "release docs guard passed"

echo
echo "==> Release artifacts"
require_file "dist/FoxClean-$VERSION.dmg" "local DMG"
require_file "dist/FoxClean-$VERSION.dmg.sha256" "local DMG checksum"
if [[ -s "dist/FoxClean-$VERSION.dmg.sha256" ]]; then
  if (cd dist && shasum -a 256 -c "FoxClean-$VERSION.dmg.sha256" >/dev/null 2>&1); then
    pass "DMG checksum verifies"
  else
    fail "DMG checksum failed"
  fi
fi
if [[ -L "dist/release/Applications" ]]; then
  pass "DMG staging includes Applications symlink"
else
  fail "DMG staging Applications symlink missing"
fi
if ./script/check_homebrew_formula.sh >/dev/null 2>&1; then
  pass "Homebrew cask static validation passes"
else
  fail "Homebrew cask static validation fails"
fi

echo
echo "==> External/manual gates"
preflight_output="$("$ROOT_DIR/script/release_preflight.sh")"
printf '%s\n' "$preflight_output"
if rg -q '^summary: 0 blocker' <<<"$preflight_output"; then
  pass "external release preflight has no blockers"
else
  warn "external release preflight still has blockers"
fi

echo
printf 'completion audit summary: %d failure(s), %d warning(s)\n' "$FAILURES" "$WARNINGS"

if [[ "$FAILURES" -gt 0 ]]; then
  exit 1
fi

if [[ "$STRICT" -eq 1 && "$WARNINGS" -gt 0 ]]; then
  exit 1
fi
