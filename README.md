# NIH Grant Template (Quarto-based)

This template keeps **content in Markdown (QMD)** and **formatting in templates**.
Render to **PDF** (for ASSIST uploads) and **DOCX** (for coauthor edits) from the same source.

## Requirements
- Install Quarto: https://quarto.org
- (Optional) LaTeX distribution for PDF (TinyTeX/MiKTeX/TeX Live)

## Render
```bash
# R01 (12-page strategy)
scripts/render.sh r01

# R03 / R21 (6-page strategy)
scripts/render.sh r03
scripts/render.sh r21
```

Artifacts appear in `_out/`.

## Edit

* Write content in `src/sections/`.
* Add figures to `assets/figures/` and reference as `![](../../assets/figures/myplot.png){#fig:myplot}`.
* Manage citations in `src/bib/references.bib` and cite like `@doe2020`.

## Tips

* Use profiles to switch page-limit mindset (the template does not enforce limits).
* Keep `appendix` excluded for submission via `params.include-appendix: false`.

## Verify NOFO

Always confirm current NIH NOFO formatting rules (fonts, margins, page limits) for your mechanism and institute. Always confirm the latest **NIH SF424 (R&R) guidance** (fonts, margins, page limits).


# step-by-step dev & troubleshooting

1. install Quarto, clone repo, `quarto check`.
2. run `scripts/render.sh r01` to ensure a clean baseline PDF.
3. work **one section at a time**:
   - render a single file for speed:
     `quarto render src/sections/01-specific-aims.qmd --to pdf`
4. add citations/figures incrementally; re-render after each change.
5. if PDF fails to build:
   - comment out recent edits; re-render.
   - check LaTeX logs in `_out/` for missing packages or bad syntax.
   - temporarily switch to `format: docx` to isolate content issues.
6. when stable, commit small, focused changes with clear messages.
7. switch mechanisms by running with a different profile env:
   `QUARTO_PROFILE=r21 quarto render`.
