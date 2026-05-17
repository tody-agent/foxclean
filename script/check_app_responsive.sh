#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${1:-FoxClean}"
MAX_CPU="${MAX_CPU:-50}"

sleep 3

pid="$(pgrep -x "$APP_NAME" | head -n 1 || true)"
if [[ -z "$pid" ]]; then
  echo "$APP_NAME is not running" >&2
  exit 1
fi

cpu="$(ps -p "$pid" -o %cpu= | awk '{print int($1 + 0.5)}')"
if [[ -z "$cpu" ]]; then
  echo "Could not read CPU for $APP_NAME pid $pid" >&2
  exit 1
fi

if (( cpu > MAX_CPU )); then
  echo "$APP_NAME appears busy or hung: CPU ${cpu}% > ${MAX_CPU}%" >&2
  exit 1
fi

echo "$APP_NAME responsive guard passed: CPU ${cpu}% <= ${MAX_CPU}%"
