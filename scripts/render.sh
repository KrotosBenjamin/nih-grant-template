# scripts/render-one.sh
#!/usr/bin/env bash
set -euo pipefail
file="${1:?usage: scripts/render-one.sh path/to/file.qmd}"
name="$(basename "${file%.*}")"
mkdir -p _out/sections
quarto render --profile sections "$file" --to pdf \
  --output-dir _out/sections -o "${name}.pdf"
echo "Wrote _out/sections/${name}.pdf"
