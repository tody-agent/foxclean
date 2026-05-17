#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SOURCE_PATHS=(FoxCleanApp Sources Package.swift project.yml)

failures=0

check_absent() {
  local label="$1"
  local pattern="$2"
  if rg -n --hidden --glob '!FoxCleanApp/Logic/Scanning/**' --glob '!FoxCleanApp/Services/ScanEngine.swift' "$pattern" "${SOURCE_PATHS[@]}" >/tmp/foxclean-telemetry-check.txt; then
    echo "fail: $label"
    cat /tmp/foxclean-telemetry-check.txt
    failures=$((failures + 1))
  else
    echo "pass: $label"
  fi
}

check_absent "no analytics SDK imports" '^\s*import\s+(Sentry|Firebase|FirebaseAnalytics|Amplitude|Mixpanel|PostHog|Segment|Datadog|Bugsnag|Crashlytics)\b'
check_absent "no analytics package references" '(Sentry|FirebaseAnalytics|Amplitude|Mixpanel|PostHog|Segment|Datadog|Bugsnag|Crashlytics)'
check_absent "no outbound URLSession usage" '\bURLSession\b'
check_absent "no legacy NSURLConnection usage" '\bNSURLConnection\b'
check_absent "no tracking identifiers" '\bASIdentifierManager\b|\bAdSupport\b'

rm -f /tmp/foxclean-telemetry-check.txt

if [[ "$failures" -gt 0 ]]; then
  echo "Telemetry-free check failed with $failures issue(s)." >&2
  exit 1
fi

echo "Telemetry-free check passed."
