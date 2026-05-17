#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="$ROOT_DIR/.build/verification"
RUN_LAUNCH=0
RUN_PACKAGE=0

for arg in "$@"; do
  case "$arg" in
    --launch)
      RUN_LAUNCH=1
      ;;
    --package)
      RUN_PACKAGE=1
      ;;
    -h|--help)
      cat <<'USAGE'
Usage: script/verify_local.sh [--launch] [--package]

Runs the local FoxClean verification gate:
  - swift test
  - xcodegen generate, when xcodegen is installed
  - xcodebuild for FoxCleanCore, FoxCleanCLI, and FoxCleanApp
  - selected fox CLI smoke checks
  - optional app build/run verification with --launch
  - optional local unsigned DMG packaging with --package

Release-only gates such as Developer ID signing, notarization, uploading a
GitHub release, and Homebrew submission are intentionally not run here.
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 64
      ;;
  esac
done

mkdir -p "$ARTIFACT_DIR"
cd "$ROOT_DIR"

step() {
  printf '\n==> %s\n' "$1"
}

run_log() {
  local name="$1"
  shift
  local log_file="$ARTIFACT_DIR/$name.log"
  echo "+ $*"
  if "$@" >"$log_file" 2>&1; then
    echo "pass: $name"
  else
    echo "fail: $name"
    echo "last log lines from $log_file:"
    tail -n 80 "$log_file" || true
    exit 1
  fi
}

run_json_smoke() {
  local name="$1"
  shift
  local output_file="$ARTIFACT_DIR/$name.json"
  echo "+ $*"
  if "$@" >"$output_file" 2>"$ARTIFACT_DIR/$name.stderr"; then
    if [[ ! -s "$output_file" ]]; then
      echo "fail: $name produced an empty JSON output"
      exit 1
    fi
    if ! ruby -rjson -e 'JSON.parse(File.read(ARGV.fetch(0)))' "$output_file"; then
      echo "fail: $name produced invalid JSON"
      cat "$output_file" || true
      exit 1
    fi
    echo "pass: $name"
  else
    echo "fail: $name"
    cat "$ARTIFACT_DIR/$name.stderr" || true
    exit 1
  fi
}

run_contains() {
  local name="$1"
  local expected="$2"
  shift 2
  local log_file="$ARTIFACT_DIR/$name.log"
  echo "+ $*"
  if "$@" >"$log_file" 2>&1 && rg -q "$expected" "$log_file"; then
    echo "pass: $name"
  else
    echo "fail: $name"
    echo "expected pattern: $expected"
    tail -n 80 "$log_file" || true
    exit 1
  fi
}

step "Swift package tests"
run_log "swift-test" swift test

step "Xcode project generation"
if command -v xcodegen >/dev/null 2>&1; then
  run_log "xcodegen-generate" xcodegen generate
else
  echo "skip: xcodegen is not installed; install dependencies with Brewfile before release."
fi

step "GitHub workflow static checks"
run_log "github-workflows" ./script/check_github_workflows.sh
run_log "pages-site" ./script/check_pages_site.sh
run_log "homebrew-formula" ./script/check_homebrew_formula.sh
run_log "release-docs" ./script/check_release_docs.sh

step "Localization and accessibility static checks"
run_log "localization" ./script/check_localization.sh
run_log "accessibility-static" ./script/check_accessibility_static.sh
run_log "app-runtime-static" ./script/check_app_runtime_static.sh

step "Xcode builds"
run_log "xcodebuild-core" xcodebuild -scheme FoxCleanCore -destination "platform=macOS" build
run_log "xcodebuild-cli" xcodebuild -scheme FoxCleanCLI -destination "platform=macOS" build
run_log "xcodebuild-app" xcodebuild -scheme FoxCleanApp -destination "platform=macOS" build

step "CLI smoke checks"
run_log "fox-version" swift run fox --version
run_contains "fox-no-args-noninteractive" "Usage: fox <command>" swift run fox
run_log "fox-status" swift run fox status
run_log "fox-completion-zsh" swift run fox completion zsh
run_log "fox-completion-bash" swift run fox completion bash
run_log "fox-completion-fish" swift run fox completion fish
run_log "fox-open-print-url" swift run fox open monitor --print-url
run_log "fox-touchid-status" swift run fox touchid status --json
run_log "fox-touchid-enable-dry-run" swift run fox touchid enable --dry-run --json
run_log "fox-touchid-disable-dry-run" swift run fox touchid disable --dry-run --json
run_json_smoke "fox-optimize-dry-run" swift run fox optimize
run_json_smoke "fox-scan-apps" swift run fox scan apps --json
run_json_smoke "fox-scan-orphans" swift run fox scan orphans --json
run_json_smoke "fox-clean-system-junk-dry-run" swift run fox clean systemJunk
run_json_smoke "fox-installer" swift run fox installer
run_json_smoke "fox-purge-sources" swift run fox purge --paths Sources
run_json_smoke "fox-log-show" swift run fox log show
run_json_smoke "fox-analyze-sources" swift run fox analyze Sources --json

step "Privacy checks"
run_log "telemetry-free" ./script/check_telemetry_free.sh

if [[ "$RUN_LAUNCH" -eq 1 ]]; then
  step "App launch verification"
  run_log "build-and-run-verify" ./script/build_and_run.sh --verify
  run_log "embedded-fox-version" "$ROOT_DIR/dist/FoxClean.app/Contents/Resources/fox" --version
  run_log "app-responsive" ./script/check_app_responsive.sh FoxClean
else
  step "App launch verification"
  echo "skip: pass --launch to run ./script/build_and_run.sh --verify."
fi

if [[ "$RUN_PACKAGE" -eq 1 ]]; then
  step "Release package verification"
  run_log "package-release" ./script/package_release.sh
  run_log "release-applications-link" test -L "$ROOT_DIR/dist/release/Applications"
  run_log "release-app-archs" lipo -archs "$ROOT_DIR/dist/release/FoxClean.app/Contents/MacOS/FoxClean"
  run_log "release-cli-archs" lipo -archs "$ROOT_DIR/dist/release/FoxClean.app/Contents/Resources/fox"
  run_log "release-core-archs" lipo -archs "$ROOT_DIR/dist/release/FoxClean.app/Contents/Frameworks/FoxCleanCore.framework/Versions/A/FoxCleanCore"
  run_log "dmg-verify" hdiutil verify "$ROOT_DIR/dist/FoxClean-1.0.0.dmg"
  run_log "dmg-sha256" /bin/sh -c "cd '$ROOT_DIR/dist' && shasum -a 256 -c 'FoxClean-1.0.0.dmg.sha256'"
  run_log "completion-audit" ./script/completion_audit.sh
else
  step "Release package verification"
  echo "skip: pass --package to build and verify a local unsigned DMG."
fi

step "Local verification complete"
echo "Artifacts: $ARTIFACT_DIR"
