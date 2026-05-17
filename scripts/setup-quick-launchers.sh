#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Raycast scripts are available in: $ROOT/scripts/raycast"
echo "Add that folder in Raycast Extensions > Script Commands."
