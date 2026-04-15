# Markdown → PDF: Tool Comparison

This folder is a hands-on comparison of three approaches to turning Markdown
files into professional PDFs. All three tools render the same source content
from `docs/` so the output can be compared side-by-side.

## Tool Overview

| | Pandoc + Eisvogel | Quarto | Sphinx + MyST |
|---|---|---|---|
| **Best for** | Single or multi-file PDFs, full control | Books, reports, HTML + PDF from one source | Full doc sites, Python projects |
| **Config style** | YAML front matter in `.md` or `metadata.yaml` | `_quarto.yml` | `conf.py` (Python) |
| **PDF engine** | LaTeX (xelatex/lualatex) | LaTeX or Typst | LaTeX (xelatex) |
| **HTML output** | No (needs separate tool) | Yes, built-in | Yes, built-in |
| **Learning curve** | Low | Low–Medium | Medium |
| **Install size** | Small (+ LaTeX) | Medium (+ LaTeX) | Small (pip only; + LaTeX for PDF) |

## Project Structure

```text
mdtopdf/
├── README.md              ← this file
├── docs/                  ← shared Markdown source (the only place you edit)
│   ├── 01-introduction.md
│   ├── 02-architecture.md
│   ├── 03-api-reference.md
│   ├── 04-deployment.md
│   ├── 05-code-examples.md
│   └── 06-variants.md
├── filters/               ← shared filters used across tools
│   ├── doc-type.lua       ← Lua filter for Pandoc + Quarto (AST-level filtering)
│   └── filter_type.py     ← Python preprocessor for Sphinx (text-level filtering)
├── pandoc/
│   ├── chapter-break.lua  ← Lua filter for chapter page breaks (Eisvogel workaround)
│   ├── metadata.yaml      ← document-level settings (fonts, colors, layout)
│   ├── pandoc-guide.md    ← deep-dive reference for Pandoc features
│   ├── Dockerfile         ← pre-built image for CI and local use
│   └── Makefile
├── quarto/
│   ├── _quarto.yml        ← Quarto project config (book format, PDF + HTML)
│   ├── index.md           ← preface / landing page
│   ├── Dockerfile         ← pre-built image for CI and local use
│   └── Makefile
└── sphinx/
    ├── conf.py            ← Sphinx + MyST config
    ├── index.md           ← toctree (table of contents)
    ├── requirements.txt   ← Python dependencies
    ├── Dockerfile         ← pre-built image for CI and local use
    └── Makefile
```

## Shared Source (`docs/`)

All chapter files live in `docs/` and are shared across all three tools.
**This is the only directory authors need to edit.**

The numeric prefix (`01-`, `02-`, …) controls the chapter order when files
are globbed alphabetically. No manual sorting is needed in build scripts.

Each tool stages files into its own local `_src/` directory before building —
this is an implementation detail of the Makefiles; `_src/` is ephemeral and
should be added to `.gitignore`.

---

## Use This for Your Own Project

Your Markdown files stay where they are. Pull the Docker image and point it at
your docs — no cloning, no copying files around.

---

### Option 1 — Instant PDF (no config needed)

```bash
docker run --rm \
  -v /path/to/your/docs:/docs \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  pandoc /docs/*.md \
    --template eisvogel \
    --pdf-engine xelatex \
    --from markdown+smart \
    --toc --number-sections \
    --metadata title="My Document" \
    --metadata author="Your Name" \
    -o /docs/output.pdf
```

Replace `/path/to/your/docs` with the folder containing your `.md` files.
The PDF is written back into the same folder.

---

### Option 2 — Use the default styling (metadata.yaml)

The image ships a ready-to-use `metadata.yaml` at `/defaults/metadata.yaml`
with Eisvogel styling pre-configured (title page, fonts, colors, headers).
Mount only your docs folder and reference it:

```bash
docker run --rm \
  -v /path/to/your/docs:/docs \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  pandoc /defaults/metadata.yaml /docs/*.md \
    --template eisvogel \
    --pdf-engine xelatex \
    -o /docs/output.pdf
```

---

### Option 3 — Customize the styling

Copy the default `metadata.yaml` out of the image, edit it, then mount it
alongside your docs:

```bash
# 1. Extract the default config
docker run --rm ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  cat /defaults/metadata.yaml > metadata.yaml

# 2. Edit metadata.yaml — change title, author, fonts, colors, etc.

# 3. Build using your custom config
docker run --rm \
  -v /path/to/your/docs:/docs \
  -v "$(pwd)/metadata.yaml":/metadata.yaml \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  pandoc /metadata.yaml /docs/*.md \
    --template eisvogel \
    --pdf-engine xelatex \
    -o /docs/output.pdf
```

The image also ships the Lua filters at `/defaults/doc-type.lua` (conditional
content) and `/defaults/chapter-break.lua` (chapter page breaks). Add them to
the pandoc command with `--lua-filter=/defaults/doc-type.lua` if you use the
`::: {.type1}` syntax in your docs.

---

### Option 3 (Quarto) — Extract defaults and adapt

The Quarto image ships its default project config at `/defaults/`:

```bash
# Extract the default configs
docker run --rm ghcr.io/jcarranz97/mdtopdf-quarto:latest \
  cat /defaults/_quarto.yml > _quarto.yml
docker run --rm ghcr.io/jcarranz97/mdtopdf-quarto:latest \
  cat /defaults/index.md > index.md
```

Edit `_quarto.yml` to list your own chapter files under `book.chapters`, then
mount your project directory and build:

```bash
docker run --rm \
  -v /path/to/your/project:/project \
  -w /project \
  -e QUARTO_LATEX_AUTO_INSTALL=false \
  ghcr.io/jcarranz97/mdtopdf-quarto:latest \
  quarto render --to pdf
```

---

### Option 3 (Sphinx) — Extract defaults and adapt

The Sphinx image ships its default config at `/defaults/`:

```bash
# Extract the default configs
docker run --rm ghcr.io/jcarranz97/mdtopdf-sphinx:latest \
  cat /defaults/conf.py > conf.py
docker run --rm ghcr.io/jcarranz97/mdtopdf-sphinx:latest \
  cat /defaults/index.md > index.md
```

Edit `conf.py` (project name, author) and `index.md` (add your chapter files
to the toctree), then build:

```bash
docker run --rm \
  -v /path/to/your/project:/project \
  ghcr.io/jcarranz97/mdtopdf-sphinx:latest \
  sphinx-build -b latex /project /project/_build/latex
```

---

### Option 4 — Full project (Makefile, CI, all three tools)

Clone the repo when you want the complete setup: the Makefile with all
targets, CI workflows, or to use all three tools side by side.

```bash
git clone https://github.com/jcarranz97/mdtopdf.git
cd mdtopdf
```

Files to copy into your own project if you want to adopt a specific tool:

| Tool | Files to copy | What they do |
|---|---|---|
| Pandoc | `pandoc/metadata.yaml`, `pandoc/Makefile`, `pandoc/chapter-break.lua`, `filters/doc-type.lua` | Styling, build targets, filters |
| Quarto | `quarto/_quarto.yml`, `quarto/index.md`, `quarto/Makefile` | Project config, preface, build targets |
| Sphinx | `sphinx/conf.py`, `sphinx/index.md`, `sphinx/Makefile`, `sphinx/requirements.txt` | Build config, toctree, build targets, deps |

Put your `.md` files in `docs/` and run via Docker (see
[Quick Start](#quick-start-run-the-sample-docs)) or locally with `make`.

---

## Quick Start (run the sample docs)

Each tool has a pre-built Docker image with all dependencies included —
pandoc, LaTeX, fonts, and templates. No local installation required.

### Pandoc + Eisvogel

```bash
docker pull ghcr.io/jcarranz97/mdtopdf-pandoc:latest

docker run --rm \
  -v "$(pwd)":/workspace \
  -w /workspace/pandoc \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  make
```

Output: `pandoc/output/platform-api-guide.pdf`

### Quarto

```bash
docker pull ghcr.io/jcarranz97/mdtopdf-quarto:latest

docker run --rm \
  -v "$(pwd)":/workspace \
  -w /workspace/quarto \
  -e QUARTO_LATEX_AUTO_INSTALL=false \
  ghcr.io/jcarranz97/mdtopdf-quarto:latest \
  make pdf
```

Output: `quarto/_build/`

### Sphinx + MyST

```bash
docker pull ghcr.io/jcarranz97/mdtopdf-sphinx:latest

docker run --rm \
  -v "$(pwd)":/workspace \
  -w /workspace/sphinx \
  ghcr.io/jcarranz97/mdtopdf-sphinx:latest \
  make pdf
```

Output: `sphinx/_build/latex/`

---

## Pandoc + Eisvogel

Pandoc is a universal document converter. The conversion pipeline is:

```
docs/*.md  →  Pandoc  →  LaTeX (Eisvogel template)  →  PDF
```

### Build Commands

```bash
cd pandoc/

make                        # build with default header values
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01   # custom header values
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"

make single                 # build pandoc-guide.md alone → output/pandoc-guide.pdf
make preview CHAPTER=02     # preview a single chapter (also accepts DOC_* vars)
make clean                  # remove output/
make help                   # list all targets
```

See [Document Identity Variables](#document-identity-variables) for full details.

### Full CLI Reference

```bash
pandoc metadata.yaml ../docs/*.md \
  --from markdown+smart \
  --to pdf \
  --template eisvogel \
  --pdf-engine xelatex \
  --highlight-style tango \
  --number-sections \
  -o output/platform-api-guide.pdf
```

| Flag | Purpose |
|---|---|
| `--from markdown+smart` | Enable smart quotes and dashes |
| `--template eisvogel` | Use the Eisvogel LaTeX template |
| `--pdf-engine xelatex` | Required for custom fonts (TTF/OTF) |
| `--highlight-style tango` | Syntax highlight theme (`pygments`, `kate`, `zenburn`, …) |
| `--number-sections` | Auto-number headings (1, 1.1, 1.1.1 …) |

### Customization (`metadata.yaml`)

All visual settings live in `pandoc/metadata.yaml`. Individual chapter files
carry no YAML header — authors only write content.

#### Document metadata

```yaml
title: "Your Document Title"
author:
  - "Alice Nguyen"
  - "Bob Martínez"
date: "2026-04-14"
subject: "Engineering Documentation"
keywords: [api, architecture, deployment]
lang: "en"
```

#### Font size

```yaml
fontsize: 10pt   # compact
fontsize: 11pt   # default, comfortable for most documents
fontsize: 12pt   # larger, good for accessibility
```

#### Font families

With `xelatex` you can use any system font by name:

```yaml
mainfont: "Georgia"           # body text (serif)
sansfont: "Helvetica Neue"    # headings (sans-serif)
monofont: "JetBrains Mono"    # code blocks
```

Safe cross-platform defaults:

| Role | Safe default | Alternative |
|---|---|---|
| Body | `DejaVu Serif` | `Times New Roman` |
| Headings | `DejaVu Sans` | `Arial` |
| Code | `DejaVu Sans Mono` | `Courier New` |

List fonts available on your system:

```bash
fc-list : family | sort
```

#### Page layout

```yaml
geometry: "margin=2.5cm"                                    # uniform
geometry: "top=3cm, bottom=2cm, left=2.5cm, right=2cm"     # per-side
papersize: a4        # or: letter
linestretch: 1.25    # 1.0 = single, 1.5 = one-and-a-half, 2.0 = double
```

#### Title page (Eisvogel-specific)

```yaml
titlepage: true
titlepage-color: "1E2A38"       # background color (hex, no #)
titlepage-text-color: "FFFFFF"  # title and author text color
titlepage-rule-color: "4A90D9"  # accent line color
titlepage-rule-height: 4        # accent line thickness (pt)
logo: "logo.png"                # optional logo image path
logo-width: 120                 # logo width in mm
```

#### Table of contents

```yaml
toc: true
toc-own-page: true    # TOC on its own page
toc-depth: 3          # include up to h3 headings
```

#### Link colors

```yaml
linkcolor: "4A90D9"   # internal cross-references
urlcolor: "4A90D9"    # external URLs
citecolor: "4A90D9"   # bibliography citations
```

Set all three to `"black"` for print-ready output.

#### Tables

Standard pipe tables:

```markdown
| Left | Center | Right |
|------|:------:|------:|
| A    |   B    |     C |
```

Multi-line cells (grid table syntax):

```markdown
+------------------+-----------------------------+
| Header 1         | Header 2                    |
+==================+=============================+
| Long cell that   | Another long cell that      |
| wraps across     | wraps as well               |
+------------------+-----------------------------+
```

Table caption:

```markdown
| Name  | Score |
|-------|-------|
| Alice | 95    |

Table: Exam results — Spring 2026
```

#### Images

```markdown
![Caption](path/to/image.png){ width=80% }
![Caption](path/to/image.png){ width=10cm }
```

### Manual Installation

<details>
<summary>Expand if you prefer to install locally instead of using Docker</summary>

#### Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu / Debian — the apt package is often several major versions behind.
# Install the official binary instead:
curl -L https://github.com/jgm/pandoc/releases/latest/download/pandoc-3.6.4-linux-amd64.tar.gz \
  | tar xz --strip-components=1 -C ~/.local

# Verify
pandoc --version
```

#### LaTeX engine (required for PDF output)

```bash
# macOS
brew install --cask mactex

# Ubuntu / Debian
sudo apt install texlive-xetex texlive-fonts-recommended texlive-fonts-extra
```

#### Eisvogel template

Eisvogel is a third-party template — it is never installed automatically with
Pandoc. You must place it in Pandoc's user templates directory manually.

```bash
# Create the templates directory
mkdir -p ~/.local/share/pandoc/templates

# Download Eisvogel
# v2.4.2 = last release supporting Pandoc 2.x
# For Pandoc 3.x, use the latest release from the GitHub releases page
curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/2.4.2/Eisvogel-2.4.2.tar.gz \
  -o /tmp/eisvogel.tar.gz

tar -xzf /tmp/eisvogel.tar.gz -C /tmp/
cp /tmp/eisvogel.latex ~/.local/share/pandoc/templates/

# Verify
ls ~/.local/share/pandoc/templates/
# → eisvogel.latex
```

> **Version note:** the 2.4.2 release tag has no `v` prefix — the download URL
> is `.../download/2.4.2/...`, not `.../download/v2.4.2/...`.

</details>

---

## Quarto

Quarto is a scientific publishing system built on Pandoc. It produces PDF
(via LaTeX or Typst), HTML, Word, and EPUB from the same source.

```
docs/*.md  →  Quarto  →  LaTeX  →  PDF
                      →  HTML
```

### Build Commands

```bash
cd quarto/

make                        # build PDF + HTML with default header values
make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01   # custom header values
make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"

make html                   # HTML only → _build/html/
make sync                   # copy latest docs/ into _src/ without building
make clean                  # remove _build/, _src/, and generated _header.tex
make help                   # list all targets
```

See [Document Identity Variables](#document-identity-variables) for full details.

### Customization (`_quarto.yml`)

#### Document metadata

```yaml
book:
  title: "Your Document Title"
  author:
    - "Alice Nguyen"
    - "Bob Martínez"
  date: "2026-04-14"
  chapters:
    - index.md
    - _src/01-introduction.md
    - _src/02-architecture.md
```

#### PDF options

```yaml
format:
  pdf:
    documentclass: scrreprt   # KOMA-Script report (cleaner than default)
    papersize: a4
    fontsize: 11pt
    geometry:
      - margin=2.5cm
    mainfont: "DejaVu Serif"
    sansfont: "DejaVu Sans"
    monofont: "DejaVu Sans Mono"
    colorlinks: true
    linkcolor: "336699"
    urlcolor: "336699"
    number-sections: true
    toc: true
    toc-depth: 3
    highlight-style: tango
```

`documentclass` controls the overall layout. Common choices:

| Class | Description |
|---|---|
| `scrreprt` | KOMA-Script report — clean, modern (default in this project) |
| `scrbook` | KOMA-Script book — adds chapter pages, better for long docs |
| `report` | Standard LaTeX report |
| `article` | Standard LaTeX article — no chapters |

#### HTML options

```yaml
format:
  html:
    theme: cosmo        # Bootswatch theme (cosmo, flatly, darkly, …)
    toc: true
    toc-depth: 3
    number-sections: true
    code-copy: true     # adds a copy button to code blocks
    highlight-style: tango
```

### Manual Installation

<details>
<summary>Expand if you prefer to install locally instead of using Docker</summary>

#### Quarto CLI

```bash
# macOS
brew install quarto

# Ubuntu / Debian / WSL2
curl -LO https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.42/quarto-1.6.42-linux-amd64.deb
sudo dpkg -i quarto-1.6.42-linux-amd64.deb
rm quarto-1.6.42-linux-amd64.deb

# Verify
quarto --version
```

#### LaTeX engine (required for PDF output)

```bash
# macOS
brew install --cask mactex

# Ubuntu / Debian / WSL2
sudo apt install texlive-xetex texlive-fonts-recommended texlive-fonts-extra
```

Alternatively, Quarto can manage its own minimal LaTeX distribution:

```bash
quarto install tinytex
```

</details>

---

## Sphinx + MyST

Sphinx is the documentation engine behind the official Python, Linux kernel,
and many other major open-source project docs. MyST-Parser adds full Markdown
support so you never have to write reStructuredText.

```
docs/*.md  →  MyST-Parser  →  Sphinx  →  HTML
                                      →  LaTeX  →  PDF
```

### Build Commands

```bash
cd sphinx/

make                        # build HTML with default header values
make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01   # custom header values
make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"

make html                   # HTML site  → _build/html/index.html
make sync                   # copy latest docs/ into _src/ without building
make clean                  # remove _build/ and _src/
make help                   # list all targets
```

See [Document Identity Variables](#document-identity-variables) for full details.

Open the HTML site locally:

```bash
open _build/html/index.html          # macOS
xdg-open _build/html/index.html      # Linux
```

### Customization (`conf.py`)

#### Project metadata

```python
project = "Platform API — Technical Guide"
author  = "Alice Nguyen, Bob Martínez, Carol Smith"
release = "1.0"
language = "en"
```

#### Extensions

```python
extensions = [
    "myst_parser",                   # parse .md files
    "sphinx.ext.autosectionlabel",   # auto cross-reference labels
]
```

#### MyST features

```python
myst_enable_extensions = [
    "colon_fence",    # :::{directive} syntax (alternative to ```)
    "deflist",        # definition lists
    "tasklist",       # - [ ] / - [x] checkboxes
    "smartquotes",    # smart quotes and dashes
]

myst_heading_anchors = 3    # auto-anchor h1–h3
```

#### HTML theme

```python
html_theme = "sphinx_rtd_theme"     # Read the Docs theme
# Other options: "furo", "pydata_sphinx_theme", "alabaster"

html_theme_options = {
    "navigation_depth": 4,
    "collapse_navigation": False,
}
```

#### PDF via LaTeX (`latex_elements`)

```python
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
}
```

#### Table of contents depth (`index.md`)

```markdown
{toctree}
:maxdepth: 3     # heading levels shown in sidebar and TOC
:numbered:       # auto-number sections
```

### Manual Installation

<details>
<summary>Expand if you prefer to install locally instead of using Docker</summary>

```bash
cd sphinx/

# Create a virtual environment (recommended)
python -m venv .venv
source .venv/bin/activate     # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Verify
sphinx-build --version
```

`requirements.txt` contents:

```text
sphinx>=7.0
myst-parser>=3.0
sphinx-rtd-theme>=2.0
```

#### LaTeX engine (for PDF output only)

```bash
# macOS
brew install --cask mactex

# Ubuntu / Debian / WSL2
sudo apt install texlive-xetex texlive-fonts-recommended texlive-fonts-extra
```

</details>

---

## Document Variants (Conditional Content)

The same `.md` source files can produce different PDFs for different audiences
by wrapping content in **fenced divs** tagged with a document type. Content
outside any div is always included.

### Include syntax

Show a block only for specific types:

```markdown
This paragraph appears in every variant.

::: {.type1}
This block is only included when DOC_TYPE=type1.
:::

::: {.type1 .type2}
This block is included when DOC_TYPE=type1 OR DOC_TYPE=type2.
:::
```

### Negation syntax (if / else)

Use `.not-typeN` to show a block for every type **except** the listed ones.
This gives you a true if/else without naming every other type:

```markdown
::: {.type1}
This text appears only in the type1 build.
:::

::: {.not-type1}
This text appears in every other build (type2, type3, …).
:::
```

Stack multiple negations to exclude more than one type:

```markdown
::: {.not-type1 .not-type2}
This appears only when DOC_TYPE is neither type1 nor type2.
:::
```

Three-way if / else-if / else — only one block is rendered per build:

```markdown
::: {.type1}
Shown only for type1.
:::

::: {.type2}
Shown only for type2.
:::

::: {.not-type1 .not-type2}
Shown for type3 (or any type that is not type1 or type2).
:::
```

The `:::` fenced div syntax is standard Pandoc Markdown. GitHub and Obsidian
render the content inside without any special treatment (the type classes are
simply ignored by those renderers), so authors see all content in preview.

### Inline syntax (spans — for table cells and partial sentences)

Block-level divs cannot go inside a table cell. For **cell-level** or
**inline** conditional content, use a span — the same class names apply:

```markdown
[conditional text]{.type1}       ← shown only in type1
[conditional text]{.not-type2}   ← shown in every type except type2
```

**Primary use-case: same table in two types, different cell content.**
Wrap the table in a div so it appears in both types, then use spans inside
cells to vary the text:

```markdown
::: {.type1 .type2}
| Setting | Value |
|---------|-------|
| Mode    | basic[ and advanced]{.type1} |
| Tier    | standard[ / enterprise]{.not-type2} |
:::
```

type1 renders: `basic and advanced` / `standard / enterprise`  
type2 renders: `basic` / `standard`

**Authoring tip — put spaces inside the span, not outside:**

```markdown
<!-- Correct: removal leaves clean "text1" -->
text1[ and text2]{.type1}

<!-- Avoid: removal leaves "text1 " with a trailing space -->
text1 [and text2]{.type1}
```

Spans also work in headings, paragraphs, and anywhere inline content appears.

### Rules

| Class | Behaviour |
|---|---|
| None | Always shown |
| `.typeN` | Shown only if `DOC_TYPE` matches one of the listed types |
| `.not-typeN` | Shown unless `DOC_TYPE` matches one of the listed types |
| Mixed (`.typeN` + `.not-typeN`) | Include-classes take precedence; avoid mixing |

Applies equally to block-level divs (`::: {…}`) and inline spans (`[…]{…}`).

### Building a Specific Variant

```bash
# Pandoc — default is type1
make DOC_TYPE=type2
make DOC_TYPE=type3 DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01   # combine with identity vars

# Quarto
make pdf DOC_TYPE=type2

# Sphinx
make html DOC_TYPE=type2
make pdf  DOC_TYPE=type3
```

If `DOC_TYPE` is not set, all content is kept (no filtering applied).

### How Each Tool Implements It

| Tool | Mechanism | File |
|---|---|---|
| **Pandoc** | Lua filter handles both `Div` (block) and `Span` (inline) AST nodes | `filters/doc-type.lua` |
| **Quarto** | Same Lua filter, registered in `_quarto.yml` under `project.filters` | `filters/doc-type.lua` |
| **Sphinx** | Python pre-processor: one regex pass for block divs, one for inline spans | `filters/filter_type.py` |

Pandoc and Quarto filter at the **AST level** (after parsing, before rendering)
so the filter is format-agnostic. Sphinx filters at the **text level** before
the file is handed to Sphinx, which is equivalent for the syntax used here.

### Adding a New Type

1. Choose a name following the `typeN` pattern (e.g. `type4`).
2. Wrap content in `.md` files with `::: {.type4}` … `:::`.
3. Build with `DOC_TYPE=type4` — no changes to any config file needed.

### Shared Filters Location

```text
mdtopdf/
└── filters/
    ├── doc-type.lua      ← Lua filter for Pandoc + Quarto
    └── filter_type.py   ← Python preprocessor for Sphinx
```

---

## Document Identity Variables

All three Makefiles support the same four variables for controlling the header
that appears on every page of the PDF output:

| Variable | Default | Description |
|---|---|---|
| `DOC_ID` | `1234` | Document identifier |
| `DOC_MAJOR` | `1` | Major revision number |
| `DOC_MINOR` | `00` | Minor revision number |
| `DOC_DATE` | `April 14, 2026` | Document date |

These combine to produce the **top-left header**: `{DOC_ID} Rev {DOC_MAJOR}.{DOC_MINOR} - {DOC_DATE}`

The **top-right header** (`Platform API - Technical Guide`) and **bottom-right footer** (page number) are fixed and not configurable from the CLI.

### Overriding from the Command Line

Pass variables directly to `make` — any combination works, unset variables
fall back to their defaults:

```bash
# Change ID and revision only — date stays at default
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01

# Change everything
make DOC_ID=9001 DOC_MAJOR=3 DOC_MINOR=05 DOC_DATE="June 30, 2026"

# Works the same for all tools and all targets
make pdf DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01        # quarto
make html DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01       # sphinx
```

### How Each Tool Implements It

| Tool | Mechanism |
|---|---|
| **Pandoc** | `--metadata=header-left:"..."` flags passed at build time, overriding `metadata.yaml` |
| **Quarto** | Makefile generates `_header.tex` with `printf`; `_quarto.yml` references it via `include-in-header: _header.tex` |
| **Sphinx** | `conf.py` reads `os.environ.get("DOC_ID", ...)` etc.; Makefile exports the variables before calling `sphinx-build` |

### Generated Files to Gitignore

The Quarto build generates `_header.tex` from the Makefile variables. It is
ephemeral and should not be committed:

```gitignore
pandoc/output/
quarto/_src/
quarto/_build/
quarto/_header.tex
sphinx/_src/
sphinx/_build/
```

---

## Multi-File Workflow

All three tools are configured to use the same `docs/` source. This section
covers the workflow conventions shared across all tools.

### Why Split Into Multiple Files

- **Parallel authoring** — each contributor owns one file; merge conflicts on
  content are eliminated.
- **Focused pull requests** — a PR that only touches `03-api-reference.md` is
  immediately clear in scope.
- **Independent review** — chapters can be reviewed and approved separately.
- **Reusability** — a file like `appendix-glossary.md` can be included in
  multiple builds by referencing it in different configs.

### The `_src/` Staging Pattern

Quarto and Sphinx require all source files to live inside (or relative to)
their project directory. To avoid duplicating files in the repo, each tool's
`Makefile` copies `../docs/*.md` into a local `_src/` directory before
building:

```
make sync   # or make (which calls sync automatically)
```

`_src/` is ephemeral — add it to `.gitignore`. The source of truth is always
`docs/`.

```gitignore
# .gitignore entries for this project
pandoc/output/
quarto/_src/
quarto/_build/
quarto/_header.tex
sphinx/_src/
sphinx/_build/
```

### Chapter File Conventions

| Convention | Reason |
|---|---|
| Numeric prefix (`01-`, `02-`) | Controls glob order; no manual sorting |
| Kebab-case filenames | Shell-safe; no quoting needed in scripts |
| No YAML header in chapter files | Metadata is centralized per-tool |
| One `#` heading per file | Maps to one top-level chapter in the TOC |
| Blockquote for author attribution | Visible in output without custom template work |

Author attribution blockquote (used in this project's chapter files):

```markdown
# Architecture Overview

> **Author:** Bob Martínez — last updated 2026-04-11
```

### Git Workflow for Collaborative Writing

```text
main
├── feature/ch02-architecture   ← Bob's branch
├── feature/ch03-api            ← Carol's branch
└── feature/ch04-deployment     ← Alice's branch
```

Preview a single chapter during a pull request review (Pandoc):

```bash
cd pandoc/
pandoc metadata.yaml ../docs/02-architecture.md \
  --template eisvogel --pdf-engine xelatex -o preview.pdf
```

Once all chapter PRs are merged, `make` assembles the final document.

---

## Tool Recommendation

This section ranks the three tools specifically for the use case demonstrated
in this project: **versioned technical PDFs with conditional content, CLI-driven
document identity, and a multi-file shared source**.

---

### #1 — Pandoc + Eisvogel *(recommended)*

Pandoc is the closest match to this use case. Every feature needed here maps
directly to a first-class Pandoc primitive with no workarounds.

**Pros**

- **Conditional content is a first-class feature.** The Lua filter operates at
  the AST level — it sees the parsed document, not raw text — so fenced divs
  are handled cleanly and reliably. No separate preprocessing step.
- **CLI overrides are native.** `--variable=key:value` passes values straight
  into the LaTeX template without any intermediate file generation or
  environment-variable plumbing.
- **No staging directory.** `../docs/*.md` is referenced directly; no `_src/`
  copy step, no sync target, no stale-file risk.
- **Fast iteration.** Single command, no project scaffolding, no build graph.
  `make preview CHAPTER=02` renders one chapter in seconds.
- **Eisvogel output is polished out of the box.** Title page, colored headings,
  code block styling, and table formatting all work without extra configuration.

**Cons**

- `--variable` vs `--metadata` is a non-obvious distinction: `--metadata`
  processes values as Markdown (escaping LaTeX commands), `--variable` does not.
  Using the wrong one silently produces broken output.
- Eisvogel is a third-party template with no guarantee of long-term maintenance.
  If it stops being updated, you own the template.
- Eisvogel hard-codes the `scrartcl` document class, which has no `\chapter`
  command. Chapter page-breaks require a Lua workaround (`chapter-break.lua`).
- No native HTML output. A separate tool or pipeline is needed if you ever want
  a browsable site from the same source.

---

### #2 — Quarto

Quarto is a good choice if HTML output matters as much as PDF, or if the
document is long enough to benefit from Quarto's native book format (numbered
parts, cross-references, bibliography). The Lua filter is shared with Pandoc,
so conditional content works identically.

**Pros**

- Produces PDF and HTML from the same source and the same build command.
- Book format handles chapter numbering, TOC, and cross-references natively.
- Uses the same Lua filter as Pandoc — no extra code for conditional content.
- `documentclass` is freely configurable (`scrreprt`, `scrbook`, `report`, etc.)
  with proper `\chapter` support; no workaround needed for chapter breaks.
- Actively developed with frequent releases.

**Cons**

- Custom headers/footers require generating an intermediate `_header.tex` file
  from the Makefile. The `printf` approach is fragile: `\f`, `\r`, and `\t` in
  format strings are interpreted as control characters (form feed, carriage
  return, tab), corrupting the generated file silently.
- Breaking changes between Quarto versions have already surfaced in this
  project: the `filters` key moved from `project:` to the top level, breaking
  an existing config without a clear error.
- `_src/` staging is required because Quarto cannot reference files outside its
  project directory.
- Heavier installation footprint than Pandoc alone.

---

### #3 — Sphinx + MyST

Sphinx is the right tool for large documentation *sites* — versioned API docs,
multi-project portals, auto-generated reference pages from docstrings. For
standalone PDFs it is over-engineered, and the PDF pipeline is a secondary
citizen compared to the HTML output.

**Pros**

- Python-native configuration (`conf.py` is plain Python). Every aspect of the
  build is programmable without leaving the Python ecosystem.
- Excellent HTML output with themes like Read the Docs, Furo, and PyData.
- Best-in-class for API documentation via `autodoc`, `autosummary`, and
  `intersphinx`.
- Very mature and stable — the same tool that builds the Python standard library
  docs.

**Cons**

- No Lua filter support. Conditional content requires a separate Python
  preprocessor (`filter_type.py`) that runs as a text-level regex pass before
  staging. It works for simple cases but is less robust than AST-level
  filtering.
- Python's `%` string formatting in `conf.py` interacts badly with LaTeX: every
  `%` in the preamble (comments, `%%` end-of-line suppressors) must be manually
  doubled to `%%`, and any non-ASCII character after a `%` (e.g. `─` in a
  comment line) causes a `ValueError` at startup.
- PDF output is a second-class citizen. Sphinx generates an intermediate `.tex`
  file that then requires a separate `make -C _build/latex` call; the resulting
  layout is less polished than Eisvogel without significant custom LaTeX.
- `_src/` staging is required.
- Most complex setup of the three.

---

### Summary

| | Pandoc | Quarto | Sphinx |
|---|:---:|:---:|:---:|
| PDF quality (out of the box) | ★★★ | ★★★ | ★★ |
| Conditional content | ★★★ | ★★★ | ★★ |
| CLI-driven identity/variants | ★★★ | ★★ | ★★ |
| HTML output | — | ★★★ | ★★★ |
| Setup simplicity | ★★★ | ★★ | ★ |
| Config fragility | low | medium | medium |
| **Best fit for this project** | **yes** | if HTML needed | large doc sites |

---

## General Tips

- **Commit only source, not output.** `.md` files diff cleanly; PDFs and HTML
  sites do not. Generate output in CI or on demand.
- **CI builds.** The GitHub Actions workflow (`.github/workflows/generate-pdfs.yml`)
  runs on every pull request and uses the Docker images to build all three PDFs,
  uploading them as downloadable artifacts for side-by-side comparison.
- **Print vs. screen.** Set `linkcolor: black` / `urlcolor: black` (Pandoc,
  Quarto) for documents that will be printed; use accent colors for digital
  distribution.
- **Font availability.** All three tools rely on `xelatex` to use system fonts
  by name. Run `fc-list : family | sort` to see what is available. The
  `DejaVu` family is a safe default that ships with most Linux distributions.

---

## Maintaining Docker Images

Each tool has a pre-built image hosted on **GitHub Container Registry (GHCR)**,
free for public repositories. Images are rebuilt automatically when their
`Dockerfile` changes on `main`, and can be triggered manually from the Actions
tab.

| Tool | Image | Defaults baked in at `/defaults/` |
|---|---|---|
| Pandoc + Eisvogel | `ghcr.io/jcarranz97/mdtopdf-pandoc:latest` | `metadata.yaml`, `chapter-break.lua`, `doc-type.lua` |
| Quarto | `ghcr.io/jcarranz97/mdtopdf-quarto:latest` | `_quarto.yml`, `index.md`, `doc-type.lua` |
| Sphinx + MyST | `ghcr.io/jcarranz97/mdtopdf-sphinx:latest` | `conf.py`, `index.md`, `filter_type.py` |

### Rebuild and push an image

```bash
# Pandoc
cd pandoc/
docker build -t ghcr.io/jcarranz97/mdtopdf-pandoc:latest .
docker push ghcr.io/jcarranz97/mdtopdf-pandoc:latest

# Quarto (pin a specific version with --build-arg)
cd quarto/
docker build --build-arg QUARTO_VERSION=1.6.42 \
  -t ghcr.io/jcarranz97/mdtopdf-quarto:latest .
docker push ghcr.io/jcarranz97/mdtopdf-quarto:latest

# Sphinx
cd sphinx/
docker build -t ghcr.io/jcarranz97/mdtopdf-sphinx:latest .
docker push ghcr.io/jcarranz97/mdtopdf-sphinx:latest
```

Pushing requires logging in first:

```bash
docker login ghcr.io -u jcarranz97 --password-stdin
```

> **Note:** If `sphinx/requirements.txt` changes (new packages or version
> bumps), rebuild and push the Sphinx image so CI picks up the updated
> dependencies.
