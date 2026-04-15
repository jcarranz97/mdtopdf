#!/usr/bin/env python3
"""filter_type.py — strip fenced divs that don't match DOC_TYPE.

Sphinx does not support Lua filters, so this script pre-processes Markdown
files before they are staged into _src/ by the Sphinx Makefile.

Syntax in .md files:

    ::: {.type1}
    Only included when DOC_TYPE=type1
    :::

    ::: {.type1 .type2}
    Included when DOC_TYPE=type1 OR DOC_TYPE=type2
    :::

Usage:
    python filter_type.py --type type1 input.md output.md
    python filter_type.py --type type2 input.md          # writes to stdout

If --type is omitted or the env var DOC_TYPE is not set, all content is kept.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Core filtering logic
# ---------------------------------------------------------------------------

# Matches:  ::: {.type1 .type2 #id key=val}
#           <body — any content including blank lines>
#           :::
_DIV_RE = re.compile(
    r"^(:::\s*\{[^}]*\})\n(.*?)^:::\s*$",
    re.MULTILINE | re.DOTALL,
)

_CLASS_RE = re.compile(r"\.(type\d+)", re.IGNORECASE)


def _should_keep(attrs: str, doc_type: str) -> bool:
    """Return True if this div's type classes include doc_type (or has none)."""
    type_classes = [c.lower() for c in _CLASS_RE.findall(attrs)]
    if not type_classes:
        return True  # no type restriction → always keep
    return doc_type in type_classes


def filter_content(text: str, doc_type: str) -> str:
    """Remove fenced divs whose type classes do not include *doc_type*."""
    doc_type = doc_type.lower()

    def replace(m: re.Match) -> str:
        opening = m.group(1)   # e.g. "::: {.type1 .type2}"
        body    = m.group(2)   # everything between the fences
        if _should_keep(opening, doc_type):
            return body.rstrip("\n")
        return ""              # remove the entire block

    result = _DIV_RE.sub(replace, text)

    # Collapse runs of 3+ blank lines left behind by removed blocks
    result = re.sub(r"\n{3,}", "\n\n", result)
    return result


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
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
