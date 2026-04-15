#!/usr/bin/env python3
"""filter_type.py — strip fenced divs and inline spans that don't match DOC_TYPE.

Sphinx does not support Lua filters, so this script pre-processes Markdown
files before they are staged into _src/ by the Sphinx Makefile.

── BLOCK-LEVEL (fenced divs) ─────────────────────────────────────────────────

    ::: {.type1}
    Only included when DOC_TYPE=type1
    :::

    ::: {.type1 .type2}
    Included when DOC_TYPE=type1 OR DOC_TYPE=type2
    :::

    ::: {.not-type1}
    Shown for type2, type3, … — anything that is not type1 (if/else)
    :::

── INLINE-LEVEL (spans — use inside table cells, headings, paragraphs) ───────

Same type and not-type classes work inside square-bracket spans:

    text1[ and text2]{.type1}
      → type1 build: "text1 and text2"
      → type2 build: "text1"

    text1[ and text2]{.not-type2}
      → type1 build: "text1 and text2"
      → type2 build: "text1"

Primary use-case — same table in two types, different cell content:

    ::: {.type1 .type2}
    | Setting | Value                           |
    |---------|---------------------------------|
    | Mode    | basic[ and advanced]{.type1}    |
    :::

── Rules ────────────────────────────────────────────────────────────────────
  • An element with no type class is always kept unchanged.
  • Include-classes (.typeN) take precedence over exclude-classes (.not-typeN).
  • If --type is omitted or $DOC_TYPE is not set, all content is kept.
  • Spans with no type class (e.g. [text]{.red}) are left completely unchanged.

Usage:
    python filter_type.py --type type1 input.md output.md
    python filter_type.py --type type2 input.md          # writes to stdout
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Compiled patterns
# ---------------------------------------------------------------------------

# Block-level: ::: {.type1 .not-type2 #id key=val}  …body…  :::
_DIV_RE = re.compile(
    r"^(:::\s*\{[^}]*\})\n(.*?)^:::\s*$",
    re.MULTILINE | re.DOTALL,
)

# Inline-level: [content]{attrs}
# Requires content to have no nested brackets — covers all practical cases.
# Does NOT match link syntax [text](url) or [text][ref] because those are
# followed by ( or [ rather than {.
_SPAN_RE = re.compile(r"\[([^\[\]]*)\]\{([^}]*)\}")

# Class extractors (shared by both levels)
_INCLUDE_CLASS_RE = re.compile(r"\.(type\d+)", re.IGNORECASE)
_EXCLUDE_CLASS_RE = re.compile(r"\.(not-type\d+)", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Shared decision logic (mirrors classify() in doc-type.lua)
# ---------------------------------------------------------------------------

def _classify(attrs: str, doc_type: str) -> str:
    """Return 'keep', 'remove', or 'neutral' (no type classes present)."""
    include_types = [c.lower() for c in _INCLUDE_CLASS_RE.findall(attrs)]
    # Strip the "not-" prefix so we compare bare type names
    exclude_types = [c.lower()[4:] for c in _EXCLUDE_CLASS_RE.findall(attrs)]

    if not include_types and not exclude_types:
        return "neutral"

    if include_types:
        return "keep" if doc_type in include_types else "remove"

    # Exclude-classes only
    return "remove" if doc_type in exclude_types else "keep"


# ---------------------------------------------------------------------------
# Block pass — fenced divs
# ---------------------------------------------------------------------------

def _filter_divs(text: str, doc_type: str) -> str:
    def replace(m: re.Match) -> str:
        opening = m.group(1)
        body    = m.group(2)
        decision = _classify(opening, doc_type)
        if decision in ("keep", "neutral"):
            return body.rstrip("\n")
        return ""

    result = _DIV_RE.sub(replace, text)
    # Collapse runs of 3+ blank lines left behind by removed blocks
    return re.sub(r"\n{3,}", "\n\n", result)


# ---------------------------------------------------------------------------
# Inline pass — spans
# ---------------------------------------------------------------------------

def _filter_spans(text: str, doc_type: str) -> str:
    def replace(m: re.Match) -> str:
        content = m.group(1)
        attrs   = m.group(2)
        decision = _classify(attrs, doc_type)
        if decision == "neutral":
            return m.group(0)   # no type class → leave span completely unchanged
        if decision == "keep":
            return content      # unwrap: keep text, drop the span markers
        return ""               # remove text and span markers entirely

    return _SPAN_RE.sub(replace, text)


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def filter_content(text: str, doc_type: str) -> str:
    """Apply both block and inline filtering for *doc_type*."""
    doc_type = doc_type.lower()
    text = _filter_divs(text, doc_type)
    text = _filter_spans(text, doc_type)
    return text


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--type",
        dest="doc_type",
        default=os.environ.get("DOC_TYPE", ""),
        help="Document type to keep (e.g. type1). Defaults to $DOC_TYPE.",
    )
    parser.add_argument("input",          help="Input Markdown file")
    parser.add_argument("output", nargs="?", help="Output file (default: stdout)")
    args = parser.parse_args()

    text = Path(args.input).read_text(encoding="utf-8")

    if args.doc_type:
        filtered = filter_content(text, args.doc_type)
    else:
        filtered = text  # no type set → pass through unchanged

    if args.output:
        Path(args.output).write_text(filtered, encoding="utf-8")
    else:
        sys.stdout.write(filtered)


if __name__ == "__main__":
    main()
