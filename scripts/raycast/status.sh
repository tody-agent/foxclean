#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title FoxClean Status
# @raycast.mode fullOutput

swift run --package-path "$(dirname "$0")/../.." fox status
