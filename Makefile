# Makefile
# -------------------------------------------------------------------
# Per-file rendering uses the "sections" profile (non-book project).
# Ensure _quarto-sections.yml exists at repo root.
# -------------------------------------------------------------------

.PHONY: sections sections-pdf sections-docx aims research one clean

# tools & dirs
QUARTO           ?= quarto
OUT              ?= _out
SECT_OUT         ?= $(OUT)/sections
PROFILE_SECTIONS ?= sections       # matches _quarto-sections.yml
FORMAT           ?= pdf            # used by `make one`
MECH ?= r01                        # r01 | r03 | r21
STRATEGY_LIMIT := $(if $(filter $(MECH),r01),12,6)

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

# -------------------------------------------------------------------
# Pattern rules: QMD -> PDF/DOCX (per-file, non-book)
# -------------------------------------------------------------------
$(SECT_OUT)/%.pdf: src/sections/%.qmd
	@mkdir -p $(SECT_OUT)
	$(QUARTO) render --profile $(PROFILE_SECTIONS) "$<" --to pdf \
	--output-dir $(SECT_OUT) -o "$(notdir $@)"

$(SECT_OUT)/%.docx: src/sections/%.qmd
	@mkdir -p $(SECT_OUT)
	$(QUARTO) render --profile $(PROFILE_SECTIONS) "$<" --to docx \
	--output-dir $(SECT_OUT) -o "$(notdir $@)"

# -------------------------------------------------------------------
# 1) ALL FILES (one by one)
# -------------------------------------------------------------------
sections: sections-pdf
sections-pdf: $(PDFS)
sections-docx: $(DOCXS)

# -------------------------------------------------------------------
# 2) SPECIFIC AIMS
# -------------------------------------------------------------------
AIMS_FILE := src/sections/03-specific-aims.qmd
AIMS_LIMIT ?= 1
aims: $(SECT_OUT)/$(notdir $(AIMS_FILE:.qmd=.pdf)) $(SECT_OUT)/$(notdir $(AIMS_FILE:.qmd=.docx))
	python3 scripts/check_pages.py "$(OUT)/$(notdir $(AIMS_FILE:.qmd=.pdf))" $(AIMS_LIMIT) || true

# -------------------------------------------------------------------
# 3) RESEARCH STRATEGY
# -------------------------------------------------------------------
RESEARCH_FILE := src/sections/04-research-strategy.qmd
research: $(SECT_OUT)/$(notdir $(RESEARCH_FILE:.qmd=.pdf)) $(SECT_OUT)/$(notdir $(RESEARCH_FILE:.qmd=.docx))
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
