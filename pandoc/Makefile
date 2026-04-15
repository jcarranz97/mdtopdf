# ─── Document identity (override from CLI) ────────────────────────────────────
#   make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"
#   make DOC_TYPE=type2

DOC_ID    ?= 1234
DOC_MAJOR ?= 1
DOC_MINOR ?= 00
DOC_DATE  ?= April 14, 2026
DOC_TYPE  ?= type1

# ─── Source directory (override to point at your own docs) ────────────────────
#   make DOCS_DIR=/path/to/your/docs
# When DOCS_DIR is changed from the default the PDF is written back into that
# same folder so the output is easy to find without mounting a second volume.
DOCS_DIR  ?= ../docs

# Export so the Lua filter (doc-type.lua) can read DOC_TYPE via os.getenv()
export DOC_TYPE

HEADER_LEFT  = $(DOC_ID) Rev $(DOC_MAJOR).$(DOC_MINOR) - $(DOC_DATE)
HEADER_RIGHT = Platform API - Technical Guide

# Passed as --variable flags (not --metadata) so values are inserted raw into
# the LaTeX template without Markdown escaping. --metadata would escape
# backslashes, turning \thepage into literal text instead of a LaTeX command.
# footer-left uses \mbox{} (an invisible LaTeX box) because Eisvogel treats
# empty strings as "not set" and falls back to its defaults.
HEADER_FLAGS = \
	--variable=header-left:"$(HEADER_LEFT)" \
	--variable=header-right:"$(HEADER_RIGHT)" \
	--variable=footer-left:"\\mbox{}" \
	--variable=footer-center:"\\textcolor[HTML]{4A90D9}{$(DOC_TYPE)}" \
	--variable=footer-right:"\\thepage"

# ─── Configuration ────────────────────────────────────────────────────────────

# Output file — when using a custom DOCS_DIR the PDF is written into that
# folder; when using the default (repo's docs/) it goes to output/ as usual.
ifeq ($(DOCS_DIR),../docs)
OUTPUT  ?= output/platform-api-guide.pdf
else
OUTPUT  ?= $(DOCS_DIR)/output.pdf
endif

# Source files — metadata first, then chapters from DOCS_DIR
SOURCES = metadata.yaml $(wildcard $(DOCS_DIR)/*.md)

# Pandoc flags shared across all targets
FLAGS = \
	--from markdown+smart \
	--template eisvogel \
	--pdf-engine xelatex \
	--highlight-style tango \
	--number-sections \
	--lua-filter=../filters/doc-type.lua \
	--lua-filter=chapter-break.lua

# ─── Targets ──────────────────────────────────────────────────────────────────

.PHONY: all clean preview help

## all: Build the full PDF document (default target)
all: $(OUTPUT)

$(OUTPUT): $(SOURCES)
	@mkdir -p output
	pandoc $(FLAGS) $(HEADER_FLAGS) $^ -o $@
	@echo "Built: $@"

## preview: Build a quick draft of a single chapter (usage: make preview CHAPTER=02)
preview:
	@if [ -z "$(CHAPTER)" ]; then \
		echo "Usage: make preview CHAPTER=02"; exit 1; \
	fi
	@mkdir -p output
	pandoc $(FLAGS) $(HEADER_FLAGS) metadata.yaml ../docs/$(CHAPTER)-*.md \
		-o output/preview-$(CHAPTER).pdf
	@echo "Preview built: output/preview-$(CHAPTER).pdf"

## single: Build only the pandoc-guide.md reference document
single:
	@mkdir -p output
	pandoc $(FLAGS) pandoc-guide.md -o output/pandoc-guide.pdf
	@echo "Built: output/pandoc-guide.pdf"

## clean: Remove generated PDFs
clean:
	rm -rf output/

## help: Show this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
