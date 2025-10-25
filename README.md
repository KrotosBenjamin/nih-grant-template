# NIH Grant Template (Quarto-based)

This template keeps **content in Markdown (QMD)** and **formatting in templates**.
Render to **PDF** (for ASSIST uploads) and **DOCX** (for coauthor edits) from the same source.

## Quick start
1. Install [Quarto](https://quarto.org) and `xelatex` (TeX Live or TinyTeX). Optionally install Arial; Helvetica will be used if Arial is absent.
2. Edit `params/*.yml` and `sections/*.qmd`.
3. Build: `make r01` (or `r21`, `r03`). PDFs land in `_output/`.

## Best practices
- **One section per file**; keep each mechanism’s driver file tiny.
- Use small reusable snippets in `sections/_includes.qmd` (e.g., Rigor, Resource Sharing).
- Track with Git; use branches + PRs for trainee edits.
- Add a `styles/nih.docx` reference document if your admin office insists on Word styling.
- Consider pandoc filters for checks (e.g., banned phrases, placeholder text, missing figure calls).

## Compliance notes
- Always confirm the latest **NIH SF424 (R&R) guidance** (fonts, margins, page limits) for your FOA.
- Use safe defaults here; adjust `templates/nih.tex`/`_quarto.yml` if your institute allows different settings.
