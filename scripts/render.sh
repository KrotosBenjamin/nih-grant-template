#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-r01}"   # r01 | r03 | r21
export QUARTO_PROFILE="$PROFILE"
quarto render
echo "Rendered with profile: $PROFILE → _out/"
