#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title FoxClean Analyze Home
# @raycast.mode fullOutput

swift run --package-path "$(dirname "$0")/../.." fox analyze "$HOME"
