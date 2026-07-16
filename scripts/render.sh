#!/usr/bin/env bash
# Render every section for a mechanism to PDF, then check page limits.
#
#   scripts/render.sh            # defaults to r01
#   scripts/render.sh dp2        # r01 | r03 | r21 | dp2 | r35
#
# The section list and page limits come from _quarto-<mech>.yml via
# scripts/profile_params.py — the same single source of truth the Makefile uses.
# For a single file, prefer: make one FILE=src/sections/<file>.qmd
set -euo pipefail

MECH="${1:-r01}"
export QUARTO_PROFILE="$MECH"

if [[ ! -f "_quarto-${MECH}.yml" ]]; then
  echo "Unknown mechanism '${MECH}': _quarto-${MECH}.yml not found." >&2
  exit 1
fi

vars="$(python3 scripts/profile_params.py "$MECH")"
sections="$(sed -n 's/^SECTIONS := //p' <<<"$vars")"

mkdir -p _out/sections

for f in $sections; do
  name="$(basename "${f%.qmd}")"
  echo "Rendering $f ..."
  quarto render "$f" --to pdf --output-dir _out/sections -o "${name}.pdf"
  echo "  -> _out/sections/${name}.pdf"
done

# Page limits are keyed by section role, not filename. A limit that is declared
# but whose PDF is missing means the mapping below has drifted from the section
# names — fail loudly rather than skipping the check, which is how the original
# page checks stayed broken unnoticed.
check() { # <LIMIT_ var name> <pdf-basename>...
  local limit="$1"; shift
  local value f
  value="$(sed -n "s/^${limit} := //p" <<<"$vars")"
  [[ -z "$value" ]] && return 0   # mechanism has no such section
  for f in "$@"; do
    if [[ -f "_out/sections/${f}.pdf" ]]; then
      python3 scripts/check_pages.py "_out/sections/${f}.pdf" "$value"
      return 0
    fi
  done
  echo "ERROR: ${limit}=${value} declared in _quarto-${MECH}.yml but none of" \
       "these rendered: $*" >&2
  exit 1
}

check LIMIT_abstract  01-project-summary
check LIMIT_narrative 02-project-narrative
check LIMIT_aims      03-specific-aims
# DP2 uses the essay-style strategy file; every other mechanism uses the triad.
check LIMIT_strategy  04-research-strategy 04-research-strategy-dp2

echo "All ${MECH} sections rendered."
