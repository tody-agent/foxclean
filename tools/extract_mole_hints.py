#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
payload = {
    "source": "Mole/lib/clean/hints.sh",
    "hints": [
        {"key": "xcode-derived-data", "paths": ["~/Library/Developer/Xcode/DerivedData"], "category": "xcodeJunk"},
        {"key": "homebrew-cache", "paths": ["~/Library/Caches/Homebrew", "/opt/homebrew/Library/Caches"], "category": "developerCache"},
        {"key": "npm-cache", "paths": ["~/.npm"], "category": "developerCache"},
        {"key": "trash", "paths": ["~/.Trash"], "category": "trash"},
    ],
}
print(json.dumps(payload, indent=2, ensure_ascii=False))
