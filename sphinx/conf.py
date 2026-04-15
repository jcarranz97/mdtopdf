# Sphinx configuration — Platform API Technical Guide
# Docs: https://www.sphinx-doc.org/en/master/usage/configuration.html

import os

# ─── Document identity (set from the Makefile via environment variables) ───────
# Override from the CLI:
#   make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"

_doc_id    = os.environ.get("DOC_ID",    "1234")
_doc_major = os.environ.get("DOC_MAJOR", "1")
_doc_minor = os.environ.get("DOC_MINOR", "00")
_doc_date  = os.environ.get("DOC_DATE",  "April 14, 2026")

_header_left  = f"{_doc_id} Rev {_doc_major}.{_doc_minor} - {_doc_date}"
_header_right = "Platform API -- Technical Guide"   # -- becomes em-dash in LaTeX
_doc_type     = os.environ.get("DOC_TYPE", "type1")

# ─── Project metadata ─────────────────────────────────────────────────────────

project = "Platform API — Technical Guide"
author = "Alice Nguyen, Bob Martínez, Carol Smith"
release = "1.0"
language = "en"

# ─── Extensions ───────────────────────────────────────────────────────────────

extensions = [
    "myst_parser",              # parse .md files with MyST
    "sphinx.ext.autosectionlabel",  # auto-generate section labels for cross-refs
]

# ─── Source files ─────────────────────────────────────────────────────────────

source_suffix = {
    ".md": "markdown",
    ".rst": "restructuredtext",
}

# Root document (the main toctree)
root_doc = "index"

# Patterns to ignore when looking for source files.
# Both venv/ and .venv/ are excluded so Sphinx never walks into the virtual
# environment and tries to parse package README files or autosummary templates
# as documentation sources.
exclude_patterns = [
    "_build",
    "_build/**",
    "venv",
    "venv/**",
    ".venv",
    ".venv/**",
    "_src/.gitkeep",
    "Thumbs.db",
    ".DS_Store",
]

# ─── MyST configuration ───────────────────────────────────────────────────────

myst_enable_extensions = [
    "colon_fence",      # allow :::{directive} syntax
    "deflist",          # definition lists
    "tasklist",         # - [ ] / - [x] checkboxes
    "smartquotes",      # smart quotes and dashes
]

myst_heading_anchors = 3    # auto-generate anchors for h1–h3

# Prefix every autosectionlabel with the document path so two files that share
# a heading name (e.g. "Overview") don't produce duplicate-label warnings.
autosectionlabel_prefix_document = True

# ─── HTML output ──────────────────────────────────────────────────────────────

html_theme = "sphinx_rtd_theme"

html_theme_options = {
    "navigation_depth": 4,
    "titles_only": False,
    "collapse_navigation": False,
}

html_show_sourcelink = False

# ─── PDF output (via LaTeX) ───────────────────────────────────────────────────

latex_engine = "xelatex"    # required for custom fonts

latex_elements = {
    "papersize": "a4paper",
    "pointsize": "11pt",
    "geometry": r"\usepackage[margin=2.5cm]{geometry}",
    "fontpkg": r"""
\usepackage{fontspec}
\setmainfont{DejaVu Serif}
\setsansfont{DejaVu Sans}
\setmonofont{DejaVu Sans Mono}[Scale=0.9]
""",
    "preamble": r"""
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{xcolor}
%% ── headers and footers ──────────────────────────────────────────────────────
%% Sphinx already loads fancyhdr — just redefine its page styles.
%% Header/footer values are injected by conf.py from environment variables.
%% 'normal' is used for regular body pages.
\fancypagestyle{normal}{%%
  \fancyhf{}%%
  \fancyhead[L]{\small %(header_left)s}%%
  \fancyhead[R]{\small %(header_right)s}%%
  \fancyfoot[C]{\textcolor[HTML]{4A90D9}{%(doc_type)s}}%%
  \fancyfoot[R]{\thepage}%%
  \renewcommand{\headrulewidth}{0.4pt}%%
  \renewcommand{\footrulewidth}{0pt}%%
}
%% 'plain' is used for chapter-opening pages, TOC, index, etc.
\fancypagestyle{plain}{%%
  \fancyhf{}%%
  \fancyhead[L]{\small %(header_left)s}%%
  \fancyhead[R]{\small %(header_right)s}%%
  \fancyfoot[C]{\textcolor[HTML]{4A90D9}{%(doc_type)s}}%%
  \fancyfoot[R]{\thepage}%%
  \renewcommand{\headrulewidth}{0.4pt}%%
  \renewcommand{\footrulewidth}{0pt}%%
}
""" % {"header_left": _header_left, "header_right": _header_right, "doc_type": _doc_type},
}

latex_documents = [
    (
        root_doc,
        "platform-api-guide.tex",
        project,
        author,
        "manual",
    ),
]
