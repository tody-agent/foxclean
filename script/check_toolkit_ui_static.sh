#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_pattern() {
  local file="$1"
  local pattern="$2"
  if ! rg -q -- "$pattern" "$file"; then
    echo "missing toolkit UI pattern in $file: $pattern" >&2
    exit 1
  fi
}

require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'ProjectScanner\(\)\.scan'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Dictionary\(grouping: entries'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Section\(group\.project\)'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Text\("Recent"\)'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'suggested: !artifact\.isRecent'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'selectedIDs = Set\(entries\.filter'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Recent artifacts are left unchecked by default'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Remove selected project artifacts\?'

require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'enum InstallerSort'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Picker\("Sort"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'sourceFilters'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'selectedSource == "All"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'ageDescription'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'selectedIDs = Set\(entries\.filter'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Remove selected installers\?'

require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'FileOperator\(\)\.clean\(files, mode: \.trash\)'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'confirmationDialog'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Edit whitelist'

echo "Toolkit UI static checks passed."
