#!/usr/bin/env python3
"""Emit GNU Make variables from the active Quarto profile's params.

The profile ymls (_quarto-<mech>.yml at the repo root) are the single source of
truth for page limits and the per-mechanism section list. The Makefile includes
this script's output rather than hardcoding those numbers a second time.

We shell out to `quarto inspect` rather than parsing the yml directly for two
reasons: it emits JSON (so stdlib `json` suffices — no pyyaml, no yq), and it
returns the _quarto.yml + profile merge, so profile files only carry deltas.

Usage: profile_params.py <mechanism>
"""
import json
import os
import subprocess
import sys

prof = sys.argv[1] if len(sys.argv) > 1 else "r01"

r = subprocess.run(
    ["quarto", "inspect"],
    capture_output=True,
    text=True,
    env={**os.environ, "QUARTO_PROFILE": prof},
)
if r.returncode != 0:
    sys.exit(f"quarto inspect failed for profile '{prof}': {r.stderr.strip()[:300]}")

params = json.loads(r.stdout).get("config", {}).get("params", {})
if not params:
    sys.exit(f"profile '{prof}' defines no params (is _quarto-{prof}.yml at the repo root?)")

print(f"MECHANISM := {params.get('mechanism', '')}")
for k, v in (params.get("page-limits") or {}).items():
    print(f"LIMIT_{k} := {v}")
print("SECTIONS := " + " ".join(f"src/sections/{s}.qmd" for s in params.get("sections") or []))
