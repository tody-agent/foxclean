#!/usr/bin/env python3
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = ROOT / "Mole/lib/core/app_protection.sh"
text = source.read_text()

def array(name):
    match = re.search(rf"{name}=\((.*?)\)", text, re.S)
    if not match:
        return []
    return re.findall(r'"([^"]+)"', match.group(1))

payload = {
    "source": str(source.relative_to(ROOT)),
    "systemCritical": array("SYSTEM_CRITICAL_BUNDLES"),
    "systemCriticalFast": array("SYSTEM_CRITICAL_BUNDLES_FAST"),
    "dataProtected": array("DATA_PROTECTED_BUNDLES"),
}
print(json.dumps(payload, indent=2, ensure_ascii=False))
