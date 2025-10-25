#!/usr/bin/env python3
import sys
from pathlib import Path

try:
    from pypdf import PdfReader
except Exception:
    print("Install pypdf: pip install pypdf", file=sys.stderr)
    sys.exit(2)

if len(sys.argv) < 3:
    print("Usage: check_pages.py <pdf> <limit>", file=sys.stderr)
    sys.exit(2)

PDF = Path(sys.argv[1])
LIMIT = int(sys.argv[2])

if not PDF.exists():
    print(f"File not found: {PDF}", file=sys.stderr)
    sys.exit(2)

n_pages = len(PdfReader(str(PDF)).pages)
if n_pages > LIMIT:
    print(f"WARNING: {PDF.name} has {n_pages} pages > limit {LIMIT}")
    sys.exit(1)
else:
    print(f"OK: {PDF.name} has {n_pages} pages (limit {LIMIT})")
