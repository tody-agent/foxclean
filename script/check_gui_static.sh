#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_pattern() {
  local file="$1"
  local pattern="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "missing GUI pattern in $file: $pattern" >&2
    exit 1
  fi
}

require_patterns() {
  local file="$1"
  shift
  local pattern
  for pattern in "$@"; do
    require_pattern "$file" "$pattern"
  done
}

require_patterns FoxCleanApp/Views/OnboardingView.swift \
  'switch currentPage' \
  'case 0: welcomePage' \
  'case 1: fdaPage' \
  'case 2: readyPage' \
  'ForEach\(0..<3' \
  'Button\("Back"\)' \
  'Button\("Next"\)' \
  'Button\("Get Started"\)' \
  'FullDiskAccessManager\.shared\.triggerRegistration\(\)' \
  'FullDiskAccessManager\.shared\.openFullDiskAccessSettings\(\)' \
  'FullDiskAccessManager\.shared\.revealAppInFinder\(\)' \
  'FullDiskAccessManager\.shared\.resetFullDiskAccess\(\)' \
  'ProtectedPath\.allPaths' \
  'refreshAccessChecks\(\)' \
  'showDiagnostics'

require_patterns FoxCleanApp/Views/OnboardingView.swift \
  'ProtectedPath\(label: "Trash"' \
  'ProtectedPath\(label: "Mail Data"' \
  'ProtectedPath\(label: "Safari Data"' \
  'ProtectedPath\(label: "Desktop"' \
  'ProtectedPath\(label: "Documents"' \
  'ProtectedPath\(label: "TCC Database"'

require_patterns FoxCleanApp/Views/DashboardView.swift \
  'switch appState\.scanState' \
  'case \.idle:' \
  'case \.scanning:' \
  'case \.completed:' \
  'case \.cleaning:' \
  'case \.cleaned:' \
  'StorageGauge\(percentUsed:' \
  'Button \{' \
  'appState\.startSmartScan\(\)' \
  'Label\("Smart Scan"' \
  'confirmationDialog\(' \
  'Button\("Clean", role: \.destructive\)' \
  'appState\.cleanAll\(\)' \
  'ProgressView\(value: appState\.scanProgress\)' \
  'CategoryToggleRow\(result:' \
  'appState\.selectAllInCategory' \
  'appState\.deselectAllInCategory'

require_patterns FoxCleanApp/Views/DashboardView.swift \
  'label: "Free Space"' \
  'label: "Junk Found"' \
  'label: "Apps"' \
  'label: "Purgeable"' \
  'Grant Full Disk Access for full results'

require_patterns FoxCleanApp/Views/Settings/SettingsView.swift \
  'TabView' \
  'Label\("General"' \
  'Label\("Cleaning"' \
  'Label\("Schedule"' \
  'Label\("About"' \
  'Toggle\("Launch FoxClean at login"' \
  'SMAppService\.mainApp\.register\(\)' \
  'SMAppService\.mainApp\.unregister\(\)' \
  'Toggle\("Show FoxClean in menu bar"' \
  'Picker\("Search sensitivity"' \
  'Toggle\("Confirm before deleting files"' \
  'Toggle\("Reduce Foxie animations"' \
  'Toggle\("Skip hidden files during scan"' \
  'Stepper\("Minimum size:' \
  'Stepper\("Files older than:' \
  'Toggle\("Enable scheduled scanning"' \
  'Picker\("Scan interval"' \
  'Toggle\("Auto-clean after scan"' \
  'Toggle\("Auto-purge purgeable space"' \
  'Toggle\("Notify on completion"' \
  'https://github.com/tody-agent/foxclean' \
  'https://github.com/tody-agent/foxclean/issues'

echo "GUI onboarding/dashboard/settings static checks passed."
