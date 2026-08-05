# Makefile
# -------------------------------------------------------------------
# Per-file rendering, one PDF/DOCX per grant section.
#
# MECH selects the mechanism profile (_quarto-<MECH>.yml at the repo root),
# which is the single source of truth for page limits and the section list.
# Nothing here hardcodes a page limit; scripts/profile_params.py extracts them.
#
#   make sections MECH=r03        all sections for an R03
#   make research MECH=dp2        research strategy + its page check
#   make preflight MECH=r35       validate mechanism-specific structure
#   make one FILE=src/sections/03-specific-aims.qmd FORMAT=docx
# -------------------------------------------------------------------

.PHONY: sections sections-pdf sections-docx aims research one preflight clean

# tools & dirs
# NB: keep comments on their own line. A trailing comment after `?=` becomes
# part of the value, trailing spaces and all.
QUARTO   ?= quarto
OUT      ?= _out
SECT_OUT ?= $(OUT)/sections
# used by `make one`
FORMAT   ?= pdf
# r01 | r03 | r21 | dp2 | r35
MECH     ?= r01

# Quarto reads the profile from the environment; no --profile flag needed.
export QUARTO_PROFILE := $(MECH)

$(if $(wildcard _quarto-$(MECH).yml),,\
  $(error Unknown MECH '$(MECH)': _quarto-$(MECH).yml not found. Try r01, r03, r21, dp2, or r35))

# MECHANISM, LIMIT_*, and SECTIONS are generated from the active profile and
# included below. Make auto-remakes the include and restarts, so editing a
# profile yml is picked up on the next build.
PROFILE_MK := $(OUT)/profile-$(MECH).mk
-include $(PROFILE_MK)

$(PROFILE_MK): _quarto-$(MECH).yml _quarto.yml scripts/profile_params.py
	@mkdir -p $(@D)
	@python3 scripts/profile_params.py $(MECH) > $@ || (rm -f $@; exit 1)

preflight: $(PROFILE_MK)
	@python3 scripts/check_profile_compliance.py $(MECH)

# derived targets
PDFS  := $(patsubst src/sections/%.qmd,$(SECT_OUT)/%.pdf,$(SECTIONS))
DOCXS := $(patsubst src/sections/%.qmd,$(SECT_OUT)/%.docx,$(SECTIONS))

# -------------------------------------------------------------------
# Pattern rules: QMD -> PDF/DOCX (per-file, non-book)
# -------------------------------------------------------------------
$(SECT_OUT)/%.pdf: src/sections/%.qmd | $(PROFILE_MK) preflight
	@mkdir -p $(SECT_OUT)
	$(QUARTO) render "$<" --to pdf --output-dir $(SECT_OUT) -o "$(notdir $@)"

$(SECT_OUT)/%.docx: src/sections/%.qmd | $(PROFILE_MK) preflight
	@mkdir -p $(SECT_OUT)
	$(QUARTO) render "$<" --to docx --output-dir $(SECT_OUT) -o "$(notdir $@)"

# -------------------------------------------------------------------
# 1) ALL FILES (one by one)
# -------------------------------------------------------------------
sections: sections-pdf
sections-pdf: $(PDFS)
sections-docx: $(DOCXS)

# -------------------------------------------------------------------
# 2) SPECIFIC AIMS
#    Profiles without a Specific Aims attachment omit its page limit, so this
#    target refuses to produce an attachment that the mechanism forbids.
# -------------------------------------------------------------------
# A mechanism without an `aims` page limit has no Aims page at all, so we
# build nothing for it and let the recipe fail loudly.
AIMS_TARGETS := $(if $(LIMIT_aims),$(SECT_OUT)/03-specific-aims.pdf $(SECT_OUT)/03-specific-aims.docx)

aims: $(AIMS_TARGETS)
	@test -n "$(LIMIT_aims)" || { \
	  echo "make: *** MECH='$(MECH)' has no Specific Aims section (see _quarto-$(MECH).yml)." >&2; \
	  echo "make: *** This mechanism forbids that attachment; do not submit one." >&2; exit 1; }
	python3 scripts/check_pages.py "$(SECT_OUT)/03-specific-aims.pdf" $(LIMIT_aims)

# -------------------------------------------------------------------
# 3) RESEARCH STRATEGY
#    Derived from the profile's section list rather than hardcoded, because
#    DP2 and MIRA use mechanism-specific essay/program strategy files.
# -------------------------------------------------------------------
RESEARCH_SRC := $(filter %research-strategy.qmd %research-strategy-dp2.qmd %research-strategy-mira.qmd,$(SECTIONS))
RESEARCH_PDF := $(patsubst src/sections/%.qmd,$(SECT_OUT)/%.pdf,$(RESEARCH_SRC))

research: $(RESEARCH_PDF) $(patsubst %.pdf,%.docx,$(RESEARCH_PDF))
	python3 scripts/check_pages.py "$(RESEARCH_PDF)" $(LIMIT_strategy)

# -------------------------------------------------------------------
# 4) USER-SPECIFIED FILE
#    Usage: make one FILE=src/sections/03-specific-aims.qmd [FORMAT=pdf|docx]
# -------------------------------------------------------------------
one: preflight
	@test -n "$(FILE)" || (echo "Usage: make one FILE=src/sections/<file>.qmd [FORMAT=pdf|docx]"; exit 1)
	@test -n "$(LIMIT_aims)" || test "$(notdir $(FILE))" != "03-specific-aims.qmd" || { \
	  echo "make: *** MECH='$(MECH)' forbids a Specific Aims attachment." >&2; exit 1; }
	@mkdir -p $(SECT_OUT)
	$(QUARTO) render "$(FILE)" --to $(FORMAT) \
	  --output-dir $(SECT_OUT) -o "$$(basename "$${FILE%.qmd}").$(FORMAT)"

# -------------------------------------------------------------------
# Clean files
# -------------------------------------------------------------------
clean:
	rm -rf $(OUT) .quarto
