#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${FOX_VERSION:-1.0.0}"
APP_NAME="FoxClean"
EXPECTED_GITHUB_REPO="${FOX_GITHUB_REPO:-tody-agent/foxclean}"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION.dmg"
DMG_SHA_PATH="$DMG_PATH.sha256"
STRICT=0
BLOCKERS=0
WARNINGS=0

usage() {
  cat <<'USAGE'
Usage: script/release_preflight.sh [--strict]

Checks release-readiness gates that are outside normal local verification:
  - local DMG and SHA-256 sidecar
  - Developer ID signing identity configuration
  - Apple notarization environment variables, via API key or Apple ID password
  - GitHub release workflow and repository/auth readiness
  - Homebrew cask scaffold
  - manual OS-consent gates that cannot be automated

By default this prints a report and exits 0. With --strict, missing external
release prerequisites return a non-zero exit code.
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

block() {
  BLOCKERS=$((BLOCKERS + 1))
  printf 'block: %s\n' "$1"
}

have_command() {
  command -v "$1" >/dev/null 2>&1
}

has_env() {
  [[ -n "${!1:-}" ]]
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -s "$path" ]]; then
    pass "$label exists: ${path#$ROOT_DIR/}"
  else
    block "$label missing: ${path#$ROOT_DIR/}"
  fi
}

cd "$ROOT_DIR"

echo "FoxClean release preflight"
echo "version: $VERSION"
echo "github repository: $EXPECTED_GITHUB_REPO"
echo

echo "==> Local distributable"
check_file "$DMG_PATH" "DMG"
check_file "$DMG_SHA_PATH" "DMG SHA-256 sidecar"
if [[ -s "$DMG_PATH" && -s "$DMG_SHA_PATH" ]]; then
  if (cd "$ROOT_DIR/dist" && shasum -a 256 -c "$(basename "$DMG_SHA_PATH")" >/dev/null 2>&1); then
    pass "DMG checksum verifies"
  else
    block "DMG checksum does not verify"
  fi
fi
if [[ -s "$DMG_PATH" ]]; then
  if hdiutil verify "$DMG_PATH" >/dev/null 2>&1; then
    pass "DMG image verifies"
  else
    block "DMG image failed hdiutil verify"
  fi
fi

echo
echo "==> Signing and notarization"
if has_env DEVELOPER_ID_APPLICATION; then
  if security find-identity -v -p codesigning 2>/dev/null | rg -F "$DEVELOPER_ID_APPLICATION" >/dev/null 2>&1; then
    pass "Developer ID signing identity is configured and present"
  else
    block "DEVELOPER_ID_APPLICATION is set but the identity was not found in the keychain"
  fi
else
  if security find-identity -v -p codesigning 2>/dev/null | rg 'Developer ID Application' >/dev/null 2>&1; then
    warn "Developer ID Application identity exists, but DEVELOPER_ID_APPLICATION is not set"
  else
    block "Developer ID Application identity is not available"
  fi
fi

if has_env APPLE_API_KEY_PATH && has_env APPLE_API_KEY_ID && has_env APPLE_API_ISSUER_ID; then
  if [[ -s "$APPLE_API_KEY_PATH" ]]; then
    pass "notarization API key environment variables are set"
  else
    block "APPLE_API_KEY_PATH is set but the key file does not exist"
  fi
elif has_env APPLE_ID && has_env APPLE_TEAM_ID && has_env APPLE_APP_SPECIFIC_PASSWORD; then
  pass "notarization Apple ID environment variables are set"
else
  block "notarization env vars missing: APPLE_API_KEY_PATH/APPLE_API_KEY_ID/APPLE_API_ISSUER_ID or APPLE_ID/APPLE_TEAM_ID/APPLE_APP_SPECIFIC_PASSWORD"
fi

if rg -q 'notarytool submit' script/package_release.sh && rg -q 'stapler staple' script/package_release.sh; then
  pass "package script contains notarization and stapling steps"
else
  block "package script does not contain notarization and stapling steps"
fi

echo
echo "==> GitHub release"
if [[ -s ".github/workflows/release.yml" ]]; then
  pass "release workflow exists"
  if ./script/check_github_workflows.sh >/dev/null 2>&1; then
    pass "GitHub workflow static validation passes"
  else
    block "GitHub workflow static validation fails"
  fi
else
  block "release workflow missing"
fi

origin_url="$(git config --get remote.origin.url || true)"
if [[ -n "$origin_url" ]]; then
  pass "git remote origin is configured: $origin_url"
  if [[ "$origin_url" == *"$EXPECTED_GITHUB_REPO"* ]]; then
    pass "git remote origin matches expected GitHub repository"
  else
    block "git remote origin does not match expected repository $EXPECTED_GITHUB_REPO"
  fi
else
  block "git remote origin is not configured"
fi

if have_command gh; then
  if gh auth status -h github.com >/dev/null 2>&1; then
    pass "GitHub CLI is authenticated"
    if gh repo view "$EXPECTED_GITHUB_REPO" >/dev/null 2>&1; then
      pass "GitHub repository is accessible: $EXPECTED_GITHUB_REPO"
      if gh api "repos/$EXPECTED_GITHUB_REPO/pages" --jq '.build_type == "workflow" and (.html_url | length > 0)' 2>/dev/null | rg -q '^true$'; then
        pass "GitHub Pages is enabled for workflow deploys"
      else
        block "GitHub Pages is not enabled for workflow deploys"
      fi
      head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
      if [[ -n "$head_sha" ]]; then
        ci_json="$(gh run list --repo "$EXPECTED_GITHUB_REPO" --commit "$head_sha" --json workflowName,status,conclusion --limit 20 2>/dev/null || true)"
        if ruby -rjson -e '
          runs = JSON.parse(STDIN.read)
          required = %w[Build Test Lint Pages]
          latest = {}
          runs.each do |run|
            name = run.fetch("workflowName", "")
            latest[name] ||= run if required.include?(name)
          end
          missing = required.reject { |name| latest[name]&.fetch("status") == "completed" && latest[name]&.fetch("conclusion") == "success" }
          exit(missing.empty? ? 0 : 1)
        ' <<<"$ci_json"; then
          pass "latest GitHub Build/Test/Lint/Pages runs passed for HEAD"
        else
          block "latest GitHub Build/Test/Lint/Pages runs have not all passed for HEAD"
        fi
      else
        block "cannot determine HEAD SHA for GitHub workflow verification"
      fi
    else
      block "GitHub repository is not accessible through gh: $EXPECTED_GITHUB_REPO"
    fi
  else
    block "GitHub CLI is installed but not authenticated for github.com"
  fi
else
  block "GitHub CLI is not installed; release upload cannot be verified"
fi

echo
echo "==> Homebrew cask"
if [[ -s "homebrew/foxclean.rb" ]]; then
  pass "Homebrew cask draft exists"
  if ./script/check_homebrew_formula.sh >/dev/null 2>&1; then
    pass "Homebrew cask static validation passes"
  else
    block "Homebrew cask static validation fails"
  fi
else
  block "Homebrew cask draft missing"
fi

if have_command brew; then
  pass "Homebrew is installed locally"
else
  warn "Homebrew is not installed locally"
fi
block "Homebrew publication/PR access is not locally verifiable"

echo
echo "==> Manual OS gates"
block "Full Disk Access must be granted manually in macOS Privacy & Security"
block "Touch ID sudo must be authorized on real hardware by an admin user"
block "VoiceOver, contrast, RTL layout, and Gatekeeper UX require manual QA on target Macs"

echo
printf 'summary: %d blocker(s), %d warning(s)\n' "$BLOCKERS" "$WARNINGS"

if [[ "$STRICT" -eq 1 && "$BLOCKERS" -gt 0 ]]; then
  exit 1
fi
