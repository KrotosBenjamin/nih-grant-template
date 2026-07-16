# NIH Grant Template (Quarto-based)

This template keeps **content in Markdown (QMD)** and **formatting in templates**.
Render to **PDF** (for ASSIST uploads) and **DOCX** (for coauthor edits) from the same source.

Supported mechanisms: **R01**, **R03**, **R21**, **DP2** (New Innovator), **R35** (ESI MIRA).

## Requirements

- Install Quarto: https://quarto.org
- A LaTeX distribution for PDF output (`quarto install tinytex` is enough)
- Page checks use `pypdf` if installed, otherwise `pdfinfo` (poppler-utils),
  which ships with most TeX installs. Neither needs setting up separately.

## Render

`MECH` selects the mechanism. Everything — page limits, which sections exist —
follows from it.

```bash
make sections MECH=r01        # every section for an R01
make sections MECH=dp2        # DP2: essay-style strategy, no Specific Aims
make research MECH=r35        # one section + its page check
make one FILE=src/sections/03-specific-aims.qmd FORMAT=docx
make clean
```

Or render a whole mechanism with page checks in one go:

```bash
scripts/render.sh dp2
```

PDFs land in `_out/sections/`. CI builds all five mechanisms on every push.

## Mechanisms and page limits

Each mechanism is a Quarto profile at the repo root — `_quarto-r01.yml`,
`_quarto-dp2.yml`, and so on. Each declares its `page-limits` and its
`sections` list, and is **the single source of truth**: the Makefile reads them
via `scripts/profile_params.py` rather than hardcoding numbers.

To change a limit or add/remove a section for a mechanism, edit its profile —
nothing else.

| Mechanism | Specific Aims | Research Strategy |
|---|---|---|
| R01 | 1 pg | 12 pg |
| R03 / R21 | 1 pg | 6 pg |
| R35 (ESI MIRA) | 1 pg | 6 pg |
| DP2 | **none** | 10 pg (essay-style) |

**DP2 has no Specific Aims page.** Its profile omits the section, and
`make aims MECH=dp2` fails on purpose rather than producing a PDF you must not
submit. DP2 also uses `04-research-strategy-dp2.qmd` — an essay, not the
Significance/Innovation/Approach triad — since DP2 is judged on the
investigator and the idea, and preliminary data are not expected.

Over-limit sections **fail the build**. That is deliberate: an over-length
section is rejected at submission, so it should be rejected here first.

> **Verify every limit against your NOFO.** NIH resets page limits with each
> reissue, and they vary by activity code and institute. The values here are
> common defaults, not a guarantee. Confirm current NIH SF424 (R&R) guidance
> for fonts, margins, and limits.

## Edit

- Write content in `src/sections/`. Start new sections from
  `templates/qmd/section-template.qmd`, which documents the available patterns.
- Add a section by creating the file and listing it in the relevant
  `_quarto-<mech>.yml` `sections:`.
- Figures go in `assets/figures/`; cite as `@fig-myplot`.
- Citations live in `src/bib/references.bib`; cite like `@doe2020`. The
  bibliography prints only in `90-references.qmd`, with hyperlinks stripped.

### Colored text

Any hex value, or a named palette color:

```markdown
[our advantage]{color="accent"}
[critical caveat]{color="#B00020"}
## [Approach]{color="accent"}

::: {color="#0B4F71"}
A whole block — paragraphs and lists included.
:::
```

Renders in PDF, DOCX, and HTML. Named colors (`accent`, `alert`, `muted`,
`success`) are defined **once** in the `PALETTE` table in `filters/color.lua`;
edit them there and every section follows. An unrecognized color warns and
renders the text uncolored rather than breaking the build.

Two caveats: in DOCX a colored span becomes a raw run, so nested bold/italic
inside it flattens to plain text (the filter warns when this happens). And
headings are black by default — `templates/tex/preamble.tex` has a
commented-out recipe for colored headings if you want them.

A useful habit: flag unresolved text with `[TBD: confirm this]{color="alert"}`
while drafting so it is impossible to miss before submission.

### Wrapped figures

`\rswrap{r}{3.05in}{path.pdf}{Caption}` wraps text around a figure with no
surrounding whitespace — the single biggest page-saver available. It is
LaTeX-only, so always pair it with a `.content-visible when-format="docx"`
fallback; see `src/sections/04-research-strategy.qmd`.

## Fonts

Default is lualatex + TeX Gyre Heros (approximates Arial). To use pdflatex
instead — faster, smaller TinyTeX footprint — set `pdf-engine: pdflatex` in
`_quarto.yml`, drop `mainfont`, and uncomment the `helvet` lines in
`templates/tex/preamble.tex`.

## Troubleshooting

1. `quarto check` to confirm the install.
2. `make sections MECH=r01` for a clean baseline.
3. Work one section at a time: `make one FILE=src/sections/<file>.qmd`.
4. If a PDF fails to build:
   - Comment out recent edits and re-render.
   - Check the LaTeX log in `_out/` for missing packages or bad syntax.
   - Render `FORMAT=docx` to isolate content problems from LaTeX ones.
5. `make sections MECH=bogus` errors immediately with the valid mechanisms.
