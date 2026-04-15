# ─── Document identity (override from CLI) ────────────────────────────────────
#   make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"
#   make pdf DOC_TYPE=type2

DOC_ID    ?= 1234
DOC_MAJOR ?= 1
DOC_MINOR ?= 00
DOC_DATE  ?= April 14, 2026
DOC_TYPE  ?= type1

# Export so the Lua filter (doc-type.lua) can read DOC_TYPE via os.getenv()
export DOC_TYPE

HEADER_LEFT  = $(DOC_ID) Rev $(DOC_MAJOR).$(DOC_MINOR) - $(DOC_DATE)
HEADER_RIGHT = Platform API - Technical Guide

# ─── Configuration ────────────────────────────────────────────────────────────

DOCS_DIR = ../docs
SRC_DIR  = _src

# ─── Helpers ──────────────────────────────────────────────────────────────────

# _header.tex is generated on every build so header values are always current.
# It is referenced by _quarto.yml via: include-in-header: _header.tex
_header.tex: Makefile
	@printf '%s\n' '\usepackage{booktabs}'                                          >  $@
	@printf '%s\n' '\usepackage{longtable}'                                         >> $@
	@printf '%s\n' '\usepackage{fancyhdr}'                                          >> $@
	@printf '%s\n' '\usepackage{xcolor}'                                            >> $@
	@printf '%s\n' '\pagestyle{fancy}'                                              >> $@
	@printf '%s\n' '\fancyhf{}'                                                     >> $@
	@printf '%s\n' '\fancyhead[L]{\small $(HEADER_LEFT)}'                          >> $@
	@printf '%s\n' '\fancyhead[R]{\small $(HEADER_RIGHT)}'                         >> $@
	@printf '%s\n' '\fancyfoot[C]{\textcolor[HTML]{4A90D9}{$(DOC_TYPE)}}'          >> $@
	@printf '%s\n' '\fancyfoot[R]{\thepage}'                                        >> $@
	@printf '%s\n' '\renewcommand{\headrulewidth}{0.4pt}'                           >> $@
	@printf '%s\n' '\renewcommand{\footrulewidth}{0pt}'                             >> $@
	@printf '%s\n' '\fancypagestyle{plain}{%'                                       >> $@
	@printf '%s\n' '  \fancyhf{}%'                                                  >> $@
	@printf '%s\n' '  \fancyhead[L]{\small $(HEADER_LEFT)}%'                        >> $@
	@printf '%s\n' '  \fancyhead[R]{\small $(HEADER_RIGHT)}%'                      >> $@
	@printf '%s\n' '  \fancyfoot[C]{\textcolor[HTML]{4A90D9}{$(DOC_TYPE)}}%'       >> $@
	@printf '%s\n' '  \fancyfoot[R]{\thepage}%'                                    >> $@
	@printf '%s\n' '  \renewcommand{\headrulewidth}{0.4pt}%'                       >> $@
	@printf '%s\n' '  \renewcommand{\footrulewidth}{0pt}%'                         >> $@
	@printf '%s\n' '}'                                                              >> $@
	@echo "Generated $@ ($(HEADER_LEFT), DOC_TYPE=$(DOC_TYPE))"

$(SRC_DIR): $(DOCS_DIR)/*.md
	@mkdir -p $(SRC_DIR)
	@cp $(DOCS_DIR)/*.md $(SRC_DIR)/
	@echo "Staged source files → $(SRC_DIR)/"

# ─── Targets ──────────────────────────────────────────────────────────────────

.PHONY: all pdf html clean sync help

## all: Build both PDF and HTML (default)
all: _header.tex sync
	quarto render

## pdf: Build PDF only
pdf: _header.tex sync
	quarto render --to pdf

## html: Build HTML only
html: _header.tex sync
	quarto render --to html

## sync: Copy latest docs/ files into _src/ (run before any build)
sync: $(SRC_DIR)
	@cp $(DOCS_DIR)/*.md $(SRC_DIR)/
	@echo "Synced $(DOCS_DIR)/ → $(SRC_DIR)/"

## clean: Remove generated output, staged sources, and generated header
clean:
	rm -rf _build/ $(SRC_DIR)/ _header.tex

## help: Show this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
