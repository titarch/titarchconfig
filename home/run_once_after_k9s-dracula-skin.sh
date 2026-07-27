#!/bin/sh
# point k9s at the tracked dracula skin. config.yaml is app-managed (k9s rewrites
# it), so we nudge just the one key rather than track the whole file. best-effort:
# needs python3+pyyaml, else no-ops (the skin file itself is always deployed).
cfg="$HOME/.config/k9s/config.yaml"
mkdir -p "$(dirname "$cfg")"
python3 - "$cfg" <<'PY' 2>/dev/null || true
import sys, yaml
p = sys.argv[1]
try:
    d = yaml.safe_load(open(p)) or {}
except Exception:
    d = {}
d.setdefault("k9s", {}).setdefault("ui", {})["skin"] = "dracula"
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
