#!/usr/bin/env bash
# setup.sh — add mdtopdf to an existing project
#
# Run from the root of your project (where docs/ lives):
#   bash <(curl -fsSL https://raw.githubusercontent.com/jcarranz97/mdtopdf/main/setup.sh)
#
# Options:
#   --force   overwrite files that already exist

set -euo pipefail

BASE="https://raw.githubusercontent.com/jcarranz97/mdtopdf/main"

FILES=(
  "pandoc/Makefile"
  "pandoc/metadata.yaml"
  "pandoc/chapter-break.lua"
  "filters/doc-type.lua"
)

# ── Argument parsing ──────────────────────────────────────────────────────────

FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    --help|-h)
      echo "Usage: setup.sh [--force]"
      echo ""
      echo "  --force   overwrite files that already exist"
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      echo "       Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

# ── Pre-flight checks ─────────────────────────────────────────────────────────

if ! command -v curl &>/dev/null; then
  echo "error: curl is required but was not found on PATH." >&2
  exit 1
fi

echo "mdtopdf setup"
echo "Target: $(pwd)/"
echo ""

if [ ! -d "docs" ]; then
  echo "warning: no docs/ directory found in the current directory."
  echo "         Make sure you are running this from the root of your project."
  echo ""
fi

# ── Download files ────────────────────────────────────────────────────────────

mkdir -p pandoc filters

DOWNLOADED=0
SKIPPED=0

for file in "${FILES[@]}"; do
  if [ -f "$file" ] && [ "$FORCE" -eq 0 ]; then
    echo "  skip      $file  (already exists — use --force to overwrite)"
    SKIPPED=$((SKIPPED + 1))
  else
    curl -fsSL "$BASE/$file" -o "$file"
    echo "  downloaded  $file"
    DOWNLOADED=$((DOWNLOADED + 1))
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
[ "$DOWNLOADED" -gt 0 ] && echo "$DOWNLOADED file(s) downloaded."
[ "$SKIPPED"    -gt 0 ] && echo "$SKIPPED file(s) skipped."

echo ""
echo "Next steps:"
echo "  1. Install Pandoc, LaTeX, and the Eisvogel template if you haven't yet."
echo "     See: https://github.com/jcarranz97/mdtopdf#installation"
echo "  2. Edit pandoc/metadata.yaml — set your title, author, fonts, and colors."
echo "  3. cd pandoc/ && make"
