# ─── Document identity (override from CLI) ────────────────────────────────────
#   make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"
#   make html DOC_TYPE=type2

DOC_ID    ?= 1234
DOC_MAJOR ?= 1
DOC_MINOR ?= 00
DOC_DATE  ?= April 14, 2026
DOC_TYPE  ?= type1

# Export so conf.py and filter_type.py can read them via os.environ
export DOC_ID DOC_MAJOR DOC_MINOR DOC_DATE DOC_TYPE

# ─── Configuration ────────────────────────────────────────────────────────────

DOCS_DIR  = ../docs
SRC_DIR   = _src
BUILD_DIR = _build

# sphinx-build flags
SPHINX = sphinx-build
FLAGS  = -c .              # conf.py is in this directory (sphinx/)

# ─── Helpers ──────────────────────────────────────────────────────────────────

# Sphinx requires all source files to live under the source directory it is
# pointed at. Since conf.py and index.md live here in sphinx/, this is the
# source root. We stage the shared docs/ files into _src/ so Sphinx can find
# them while the source of truth remains in ../docs/.
$(SRC_DIR):
	@mkdir -p $(SRC_DIR)

# ─── Targets ──────────────────────────────────────────────────────────────────

.PHONY: all html pdf clean sync help

## all: Build HTML documentation (default)
all: html

## html: Build HTML site
html: sync
	$(SPHINX) $(FLAGS) -b html . $(BUILD_DIR)/html
	@echo "HTML built → $(BUILD_DIR)/html/index.html"

## pdf: Build PDF via LaTeX (requires a LaTeX distribution)
pdf: sync
	$(SPHINX) $(FLAGS) -b latex . $(BUILD_DIR)/latex
	make -C $(BUILD_DIR)/latex
	@echo "PDF built → $(BUILD_DIR)/latex/platform-api-guide.pdf"

## sync: Filter docs/ by DOC_TYPE and stage into _src/ (run before any build)
sync: $(SRC_DIR)
	@for f in $(DOCS_DIR)/*.md; do \
		python3 ../filters/filter_type.py --type $(DOC_TYPE) \
			"$$f" "$(SRC_DIR)/$$(basename $$f)"; \
	done
	@echo "Synced $(DOCS_DIR)/ → $(SRC_DIR)/ [DOC_TYPE=$(DOC_TYPE)]"

## clean: Remove build output and staged source files
clean:
	rm -rf $(BUILD_DIR)/ $(SRC_DIR)/

## help: Show this help message
help:
	@grep -E '^## ' Makefile | sed 's/## /  /'
