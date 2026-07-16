#!/usr/bin/env python3
"""Warn when a rendered section exceeds its page limit.

Usage: check_pages.py <pdf> <limit>

Exits 1 if over the limit, 2 on usage/IO errors. The Makefile does NOT swallow
these — a page-limit violation should fail the build, since an over-length
section is rejected at submission.
"""
import subprocess
import sys
from pathlib import Path


def page_count(path):
    """Count pages via pypdf, falling back to pdfinfo (ships with poppler-utils,
    which comes with any TeX/Quarto install) so no pip install is required."""
    try:
        from pypdf import PdfReader
        return len(PdfReader(str(path)).pages)
    except Exception:
        pass

    try:
        result = subprocess.run(
            ["pdfinfo", str(path)], check=True, capture_output=True, text=True
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print("Install pypdf (pip install pypdf) or pdfinfo (poppler-utils) "
              "to check page counts", file=sys.stderr)
        sys.exit(2)

    for line in result.stdout.splitlines():
        if line.startswith("Pages:"):
            return int(line.split(":", 1)[1].strip())

    print(f"Could not determine page count for {path}", file=sys.stderr)
    sys.exit(2)


if len(sys.argv) < 3:
    print("Usage: check_pages.py <pdf> <limit>", file=sys.stderr)
    sys.exit(2)

PDF = Path(sys.argv[1])
LIMIT = int(sys.argv[2])

if not PDF.exists():
    print(f"File not found: {PDF}", file=sys.stderr)
    sys.exit(2)

n_pages = page_count(PDF)
if n_pages > LIMIT:
    print(f"WARNING: {PDF.name} has {n_pages} pages > limit {LIMIT}")
    sys.exit(1)
else:
    print(f"OK: {PDF.name} has {n_pages} pages (limit {LIMIT})")
