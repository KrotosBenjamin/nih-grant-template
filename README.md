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
make sections MECH=r03        # R03 structure used by d-start-r03
make sections MECH=dp2        # DP2 essay + integrated references
make sections MECH=r35        # MIRA program strategy, no Specific Aims
make preflight MECH=r35       # check mechanism-specific attachment rules
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
| R35 (ESI MIRA) | **none** | 6 pg (program-level) |
| DP2 | **none** | 10 pg (essay-style, including references) |

**DP2 has no Specific Aims page or separate References Cited attachment.** Its
profile omits both, and `make aims MECH=dp2` fails on purpose. DP2 uses
`04-research-strategy-dp2.qmd`; cited references print at the end and count
against its ten-page limit. The current scaffold also includes the one-page
Facilities & Other Resources attachment demonstrated by
`../dp2-regulatory-twins`.

**ESI MIRA also has no Specific Aims attachment.** The R35 profile follows the
PAR-27-032 structure demonstrated by `../mira-context-regulation`: it selects
`04-research-strategy-mira.qmd`, a program-level strategy without the standard
Significance / Innovation / Approach headings. Preflight rejects a prohibited
attachment, designation, or strategy heading before rendering. Its profile also
selects `05-budget-justification-mira.qmd`, which reflects the non-itemized MIRA
budget rather than the standard detailed/modular justification scaffold.

**R03 retains the standard structure** demonstrated by `../d-start-r03`: a
one-page Specific Aims attachment and six-page Research Strategy, plus the
standard administrative attachments selected in `_quarto-r03.yml`.

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
- Citations live in `src/bib/references.bib`; cite like `@doe2020`. For most
  mechanisms the bibliography prints in `90-references.qmd`, with hyperlinks
  stripped. DP2 prints cited works inside its Research Strategy instead.
- `08-data-management-sharing.qmd` uses the 2026 Pilot DMS Plan scaffold used
  by the MIRA proposal. The prior six-element format remains available as
  `08-data-management-sharing-legacy.qmd`; select the format required for the
  application's receipt date and NOFO.

### Reusable boilerplate

The R03 project demonstrates an optional `common/` subtree for institutional
Facilities, Equipment, rigor, authentication, and sharing text. Keep such
content in a private repository because it quickly becomes institution- and
lab-specific. This template does not vendor the R03 project's prose; if you use
the pattern, include shared QMD snippets from your own pinned subtree and keep
proposal-specific claims in `src/sections/`.

### Default PDF highlighting

Every mechanism inherits blue attachment titles, pale blue `##` heading
bands, and blue accent bars on `###` headings. The numbered Research Strategy
uses blue ruled headings while retaining its A./B./C. and A1. numbering.
Short Markdown block quotes become centered, pale green statement boxes:

```markdown
> **Key question.** What will this work make possible?
```

Edit `heading`, `headingbg`, `quotebg`, and `quoterule` in the `PALETTE`
table in `filters/color.lua` to change the colors. Layout is defined in
`templates/tex/preamble.tex`. Statement boxes cannot split across pages, so
keep them short. These automatic decorations apply to PDF; DOCX retains its
reference-document styles.

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

In DOCX a colored span becomes a raw run, so nested bold/italic
inside it flattens to plain text (the filter warns when this happens).
Automatic PDF heading and quote highlighting does not carry over to DOCX.

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
2. `make preflight MECH=<mech>` to catch a structurally invalid attachment set.
3. `make sections MECH=r01` for a clean baseline.
4. Work one section at a time: `make one FILE=src/sections/<file>.qmd`.
5. If a PDF fails to build:
   - Comment out recent edits and re-render.
   - Check the LaTeX log in `_out/` for missing packages or bad syntax.
   - Render `FORMAT=docx` to isolate content problems from LaTeX ones.
6. `make sections MECH=bogus` errors immediately with the valid mechanisms.
