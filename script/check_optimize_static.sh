#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_pattern() {
  local file="$1"
  local pattern="$2"
  if ! rg -q -- "$pattern" "$file"; then
    echo "missing optimize pattern in $file: $pattern" >&2
    exit 1
  fi
}

task_count="$(
  ruby -ne 'puts $1 if $_ =~ /^\s*id:\s*"([^"]+)"/' Sources/FoxCleanCore/Toolkit/Toolkit.swift |
    wc -l |
    tr -d ' '
)"
if [[ "$task_count" -lt 6 ]]; then
  echo "expected at least 6 optimization tasks, found $task_count" >&2
  exit 1
fi

require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'defaultWhitelistURL'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'optimize_whitelist'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'loadWhitelist'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'includeSkipped'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'allowAdminPrompt'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'Skipped \(whitelisted\)'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift '/usr/bin/osascript'
require_pattern Sources/FoxCleanCore/Toolkit/Toolkit.swift 'with administrator privileges'

require_pattern Sources/FoxCleanCLI/main.swift '--whitelist'
require_pattern Sources/FoxCleanCLI/main.swift '--admin-prompt'
require_pattern Sources/FoxCleanCLI/main.swift 'Optimizer\.loadWhitelist\(\)'

require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Toggle\("Use optimize_whitelist"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Label\("Preview"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Label\("Run Selected"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'Label\("Run All"'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'ProgressView\("Running optimization tasks'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'OptimizationReport'
require_pattern FoxCleanApp/Views/Tools/ToolkitViews.swift 'allowAdminPrompt: true'

require_pattern Tests/FoxCleanCoreTests/FoxCleanCoreTests.swift 'testOptimizerReportsSkippedTasksAndWhitelist'
require_pattern Tests/FoxCleanCoreTests/FoxCleanCoreTests.swift 'testOptimizerLoadsWhitelistFile'

echo "Optimize static checks passed."
