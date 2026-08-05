#!/usr/bin/env python3
"""Validate mechanism-specific attachment structure before rendering."""

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN_HEADING = re.compile(r"^\s*#{1,6}\s+(.+?)\s*#*\s*$")
MIRA_PROHIBITED_TERM = re.compile(r"\baims?\b", re.IGNORECASE)
MIRA_PROHIBITED_HEADINGS = {"significance", "innovation", "approach"}


def active_sections(mechanism: str) -> list[Path]:
    result = subprocess.run(
        [sys.executable, str(ROOT / "scripts/profile_params.py"), mechanism],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    for line in result.stdout.splitlines():
        if line.startswith("SECTIONS := "):
            items = line.removeprefix("SECTIONS := ").split()
            return [ROOT / item for item in items]
    raise RuntimeError(f"profile '{mechanism}' did not provide a section list")


def normalized_heading(line: str) -> str | None:
    match = MARKDOWN_HEADING.match(line)
    if not match:
        return None
    heading = re.sub(r"\s*\{[^}]*\}\s*$", "", match.group(1))
    return heading.strip(" *_`").casefold()


def relative_names(sections: list[Path]) -> set[str]:
    return {path.relative_to(ROOT).as_posix() for path in sections}


def check_files(sections: list[Path]) -> list[str]:
    return [
        f"active attachment is missing: {path.relative_to(ROOT)}"
        for path in sections
        if not path.is_file()
    ]


def check_dp2(sections: list[Path]) -> list[str]:
    names = relative_names(sections)
    errors: list[str] = []
    required = {
        "src/sections/04-research-strategy-dp2.qmd",
        "src/sections/06-facilities.qmd",
    }

    if any("specific-aim" in name.casefold() for name in names):
        errors.append("the active DP2 profile includes a Specific Aims attachment")
    if "src/sections/90-references.qmd" in names:
        errors.append(
            "the active DP2 profile includes a separate References Cited attachment"
        )
    for path in sorted(required - names):
        errors.append(f"the active DP2 profile must include {path}")
    return errors


def check_r35(sections: list[Path]) -> list[str]:
    names = relative_names(sections)
    errors: list[str] = []
    mira_strategy = "src/sections/04-research-strategy-mira.qmd"

    if any("specific-aim" in name.casefold() for name in names):
        errors.append("the active R35 profile includes a Specific Aims attachment")
    if mira_strategy not in names:
        errors.append(f"the active R35 profile must include {mira_strategy}")

    for path in sections:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for line_number, line in enumerate(text.splitlines(), start=1):
            if MIRA_PROHIBITED_TERM.search(line):
                errors.append(
                    f"{path.relative_to(ROOT)}:{line_number}: "
                    "prohibited MIRA designation"
                )
            if path.name == "04-research-strategy-mira.qmd":
                heading = normalized_heading(line)
                if heading in MIRA_PROHIBITED_HEADINGS:
                    errors.append(
                        f"{path.relative_to(ROOT)}:{line_number}: prohibited "
                        f"Research Strategy heading '{heading}'"
                    )
    return errors


def main() -> int:
    mechanism = sys.argv[1] if len(sys.argv) > 1 else "r01"
    try:
        sections = active_sections(mechanism)
    except (RuntimeError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: could not inspect profile '{mechanism}': {exc}", file=sys.stderr)
        return 2

    errors = check_files(sections)
    if mechanism == "dp2":
        errors.extend(check_dp2(sections))
    elif mechanism == "r35":
        errors.extend(check_r35(sections))

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {mechanism} profile passed preflight ({len(sections)} attachments).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
