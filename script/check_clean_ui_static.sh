#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_pattern() {
  local file="$1"
  local pattern="$2"
  if ! rg -q "$pattern" "$file"; then
    echo "missing clean UI pattern in $file: $pattern" >&2
    exit 1
  fi
}

category_count="$(
  ruby -ne 'puts $1 if $_ =~ /^\s*case\s+([a-zA-Z0-9_]+)\s*=/' FoxCleanApp/Models/Models.swift |
    ruby -ne 'puts $_ unless $_.strip == "smartScan"' |
    wc -l |
    tr -d ' '
)"
if [[ "$category_count" -lt 9 ]]; then
  echo "expected at least 9 cleanup categories, found $category_count" >&2
  exit 1
fi

require_pattern FoxCleanApp/Models/Models.swift 'static var scannable'
require_pattern FoxCleanApp/Views/MainWindow.swift 'ForEach\(CleaningCategory\.scannable\)'

require_pattern FoxCleanApp/Views/CategoryDetailView.swift 'Button\("Select All"\)'
require_pattern FoxCleanApp/Views/CategoryDetailView.swift 'Button\("Deselect All"\)'
require_pattern FoxCleanApp/Views/CategoryDetailView.swift 'confirmationDialog\("Clean'
require_pattern FoxCleanApp/Views/CategoryDetailView.swift 'role: \.destructive'
require_pattern FoxCleanApp/Views/CategoryDetailView.swift 'NSWorkspace\.shared\.selectFile'

require_pattern FoxCleanApp/Logic/Scanning/AppInfoFetcher.swift 'protectedBundleIDs'
require_pattern FoxCleanApp/Logic/Scanning/AppInfoFetcher.swift 'url\.path\.hasPrefix\("/System"\)'
require_pattern FoxCleanApp/Logic/Scanning/AppInfoFetcher.swift '!Self\.protectedBundleIDs\.contains'
require_pattern FoxCleanApp/Views/Apps/AppListView.swift 'HSplitView'
require_pattern FoxCleanApp/Views/Apps/AppFilesView.swift 'Button\("Select All"\)'
require_pattern FoxCleanApp/Views/Apps/AppFilesView.swift 'Button\("Deselect All"\)'
require_pattern FoxCleanApp/Views/Apps/AppFilesView.swift 'alert\("Remove'
require_pattern FoxCleanApp/Views/Apps/AppFilesView.swift 'role: \.destructive'

require_pattern FoxCleanApp/Views/Orphans/OrphanListView.swift 'Button\("Scan for Orphans"\)'
require_pattern FoxCleanApp/Views/Orphans/OrphanListView.swift 'Button\("Remove Selected'
require_pattern FoxCleanApp/Views/Orphans/OrphanListView.swift 'OrphanSafetyPolicy\.isSafeCandidate'
require_pattern FoxCleanApp/Views/Orphans/OrphanListView.swift 'NSWorkspace\.shared\.selectFile'

echo "Clean/uninstall/orphans UI static checks passed."
