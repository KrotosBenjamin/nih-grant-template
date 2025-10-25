# Makefile
# -------------------------------------------------------------------
# Per-file rendering uses the "sections" profile (non-book project).
# Ensure _quarto-sections.yml exists at repo root.
# -------------------------------------------------------------------

.PHONY: all sections sections-pdf sections-docx aims research one r01 r21 r03 clean

# tools & dirs
QUARTO            ?= quarto
OUT               ?= _output
PROFILE_SECTIONS  ?= sections       # matches _quarto-sections.yml
FORMAT            ?= pdf            # used by `make one`

# section file list (edit to match your repo)
SECTIONS := \
  src/sections/01-project-summary.qmd \
  src/sections/02-project-narrative.qmd \
  src/sections/03-SpecificAims.qmd \
  src/sections/04-research-strategy.qmd \
  src/sections/90-references.qmd

# derived targets
PDFS  := $(patsubst src/sections/%.qmd,$(OUT)/%.pdf,$(SECTIONS))
DOCXS := $(patsubst src/sections/%.qmd,$(OUT)/%.docx,$(SECTIONS))

# page-limit checks (override on CLI if you want)
AIMS_FILE      := src/sections/03-SpecificAims.qmd
RESEARCH_FILE  := src/sections/04-research-strategy.qmd
AIMS_LIMIT     ?= 1
STRATEGY_LIMIT ?= 12

# -------------------------------------------------------------------
# Pattern rules: QMD -> PDF/DOCX (per-file, non-book)
# -------------------------------------------------------------------
$(OUT)/%.pdf: src/sections/%.qmd
	@mkdir -p $(OUT)
	$(QUARTO) render --profile $(PROFILE_SECTIONS) "$<" --to pdf \
	  --output-dir $(OUT) -o "$(notdir $@)"

$(OUT)/%.docx: src/sections/%.qmd
	@mkdir -p $(OUT)
	$(QUARTO) render --profile $(PROFILE_SECTIONS) "$<" --to docx \
	  --output-dir $(OUT) -o "$(notdir $@)"

# -------------------------------------------------------------------
# 1) ALL FILES (one by one)
# -------------------------------------------------------------------
sections: sections-pdf
sections-pdf: $(PDFS)
sections-docx: $(DOCXS)

# -------------------------------------------------------------------
# 2) SPECIFIC AIMS
# -------------------------------------------------------------------
aims: $(OUT)/$(notdir $(AIMS_FILE:.qmd=.pdf)) $(OUT)/$(notdir $(AIMS_FILE:.qmd=.docx))
	python3 scripts/check_pages.py "$(OUT)/$(notdir $(AIMS_FILE:.qmd=.pdf))" $(AIMS_LIMIT) || true

# -------------------------------------------------------------------
# 3) RESEARCH STRATEGY
# -------------------------------------------------------------------
research: $(OUT)/$(notdir $(RESEARCH_FILE:.qmd=.pdf)) $(OUT)/$(notdir $(RESEARCH_FILE:.qmd=.docx))
	python3 scripts/check_pages.py "$(OUT)/$(notdir $(RESEARCH_FILE:.qmd=.pdf))" $(STRATEGY_LIMIT) || true

# -------------------------------------------------------------------
# 4) USER-SPECIFIED FILE
#    Usage: make one FILE=sections/03-SpecificAims.qmd [FORMAT=pdf|docx]
# -------------------------------------------------------------------
one:
	@test -n "$(FILE)" || (echo "Usage: make one FILE=sections/<file>.qmd [FORMAT=pdf|docx]"; exit 1)
	@mkdir -p $(OUT)
	$(QUARTO) render --profile $(PROFILE_SECTIONS) "$(FILE)" --to $(FORMAT) \
	  --output-dir $(OUT) -o "$$(basename "$${FILE%.qmd}").$(FORMAT)"

# -------------------------------------------------------------------
# Clean files
# -------------------------------------------------------------------
clean:
	rm -rf $(OUT) .quarto
