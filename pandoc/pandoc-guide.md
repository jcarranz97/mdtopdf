---
title: "Writing Documentation in Markdown and Exporting to PDF with Pandoc"
author: "Your Name"
date: "2026-04-13"
subject: "Technical Documentation"
keywords: [pandoc, markdown, pdf, documentation, templates]
lang: "en"
toc: true
toc-own-page: true
titlepage: true
titlepage-color: "1E2A38"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "4A90D9"
titlepage-rule-height: 4
logo: ""
fontsize: 11pt
mainfont: "DejaVu Serif"
sansfont: "DejaVu Sans"
monofont: "DejaVu Sans Mono"
geometry: "margin=2.5cm"
linkcolor: "4A90D9"
urlcolor: "4A90D9"
numbersections: true
---

# Introduction

Pandoc is a universal document converter that transforms Markdown files into
high-quality PDFs, HTML pages, EPUB books, Word documents, and many other
formats. Combined with a polished template like **Eisvogel**, plain `.md` files
become professional-looking documents indistinguishable from those produced by
dedicated desktop publishing tools.

This document itself is a working example — the YAML block at the top drives
every visual decision described below.

---

# How It Works

The conversion pipeline is:

```
Markdown (.md)  →  Pandoc  →  LaTeX  →  PDF
```

Pandoc reads the Markdown source, applies a LaTeX template, and calls a LaTeX
engine (typically `xelatex` or `lualatex`) to produce the final PDF. The
template controls the entire visual layout; you only ever edit the Markdown.

## Installation

### Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu / Debian — the apt package is often several major versions behind.
# Install the official binary instead:
curl -L https://github.com/jgm/pandoc/releases/latest/download/pandoc-3.6.4-linux-amd64.tar.gz \
  | tar xz --strip-components=1 -C ~/.local
```

### LaTeX engine (required for PDF output)

```bash
# macOS
brew install --cask mactex

# Ubuntu / Debian
sudo apt install texlive-xetex texlive-fonts-recommended texlive-fonts-extra
```

### Eisvogel template

Eisvogel is a third-party template — it is never installed automatically with
Pandoc. You must place it in Pandoc's user templates directory manually.

```bash
# Create the templates directory if it does not exist
mkdir -p ~/.local/share/pandoc/templates

# Download Eisvogel (v2.4.2 = last release supporting Pandoc 2.x)
# For Pandoc 3.x use the latest release instead
curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/2.4.2/Eisvogel-2.4.2.tar.gz \
  -o /tmp/eisvogel.tar.gz

# Extract and copy the template file
tar -xzf /tmp/eisvogel.tar.gz -C /tmp/
cp /tmp/eisvogel.latex ~/.local/share/pandoc/templates/

# Verify
ls ~/.local/share/pandoc/templates/
# → eisvogel.latex
```

> **Version compatibility:** Eisvogel v2.4.2 supports Pandoc 2.x. If you are
> running Pandoc 3.x, use the latest Eisvogel release. You can check your
> version with `pandoc --version`.

## Basic Conversion Command

```bash
pandoc pandoc-guide.md \
  --from markdown \
  --to pdf \
  --template eisvogel \
  --pdf-engine xelatex \
  -o pandoc-guide.pdf
```

---

# YAML Front Matter — The Control Panel

Every configurable option lives in the YAML block between the `---` fences at
the top of the `.md` file. No separate config file is needed for most projects.

## Metadata Fields

```yaml
title: "Your Document Title"
author: "Author Name"           # or a list: ["Alice", "Bob"]
date: "2026-04-13"
subject: "Internal Memo"
keywords: [pandoc, pdf, docs]
lang: "en"
```

These populate the PDF metadata (visible in document properties) and the title
page when `titlepage: true` is set.

---

# Typography — Fonts and Sizes

## Font Size

Controlled by the `fontsize` key. Pandoc/LaTeX accepts standard sizes:

```yaml
fontsize: 10pt    # compact
fontsize: 11pt    # default, comfortable for most documents
fontsize: 12pt    # larger, good for presentations or accessibility
```

## Font Families

With `xelatex` or `lualatex` as the engine you can use **any system font** by
name — no installation beyond the font itself is required.

```yaml
mainfont: "Georgia"              # body text (serif)
sansfont: "Helvetica Neue"       # headings (sans-serif)
monofont: "JetBrains Mono"       # code blocks
```

Safe cross-platform defaults that ship with most systems:

| Role       | Safe Default         | Alternative             |
|------------|----------------------|-------------------------|
| Body       | `DejaVu Serif`       | `Times New Roman`       |
| Headings   | `DejaVu Sans`        | `Arial`                 |
| Code       | `DejaVu Sans Mono`   | `Courier New`           |

To list all fonts available on your system:

```bash
fc-list : family | sort   # Linux/macOS
```

## Font Options (weight, features)

OpenType font features can be passed inline:

```yaml
mainfont: "Linux Libertine O"
mainfontoptions:
  - "Numbers=OldStyle"
  - "Ligatures=TeX"
```

---

# Page Layout and Geometry

## Margins

```yaml
geometry: "margin=2.5cm"               # uniform margins
geometry: "top=3cm, bottom=2cm, left=2.5cm, right=2cm"   # per-side
```

## Paper Size

```yaml
papersize: a4        # default in most templates
papersize: letter    # US standard
```

## Line Spacing

```yaml
linestretch: 1.25    # 1.0 = single, 1.5 = one-and-a-half, 2.0 = double
```

---

# Title Page Customization (Eisvogel)

The Eisvogel template provides a rich, customizable title page:

```yaml
titlepage: true
titlepage-color: "1E2A38"          # background color (hex, no #)
titlepage-text-color: "FFFFFF"     # title and author text
titlepage-rule-color: "4A90D9"     # accent line color
titlepage-rule-height: 4           # thickness of the accent line (pt)
logo: "logo.png"                   # optional logo image
logo-width: 120                    # logo width in mm
```

---

# Table of Contents

```yaml
toc: true             # enable the TOC
toc-own-page: true    # place TOC on its own page
toc-depth: 3          # include headings up to level 3 (default: 3)
```

In Markdown, headings map directly to TOC entries:

```markdown
# Level 1 — chapter
## Level 2 — section
### Level 3 — subsection
```

---

# Tables

Markdown tables are converted automatically. Eisvogel styles them with
alternating row shading and a header band:

## Simple Table

| Column A     | Column B     | Column C     |
|--------------|:------------:|-------------:|
| Left-aligned | Centered     | Right-aligned|
| Row 2        | Row 2        | Row 2        |
| Row 3        | Row 3        | Row 3        |

## Alignment Syntax

Colons in the separator row control alignment:

```markdown
| Left | Center | Right |
|------|:------:|------:|
| ...  |  ...   |  ...  |
```

## Wide Tables (grid tables)

For tables with long content, use Pandoc's **grid table** syntax which supports
multi-line cells:

```markdown
+------------------+-----------------------------+
| Header 1         | Header 2                    |
+==================+=============================+
| A longer cell    | Another long cell with      |
| that wraps       | wrapping content            |
+------------------+-----------------------------+
```

## Table Caption

Captions are added with the `Table:` prefix immediately after the table:

```markdown
| Name  | Score |
|-------|-------|
| Alice | 95    |
| Bob   | 87    |

Table: Exam results — Spring 2026
```

---

# Code Blocks

Fenced code blocks are syntax-highlighted automatically:

````markdown
```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```
````

Produces:

```python
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

The highlight style is set with:

```bash
pandoc ... --highlight-style tango    # or: pygments, kate, espresso, zenburn
```

---

# Links and Colors

```yaml
linkcolor: "4A90D9"     # internal cross-references
urlcolor: "4A90D9"      # external URLs
citecolor: "4A90D9"     # bibliography citations
```

Set all three to `"black"` for print-ready output with no colored links.

---

# Images

```markdown
![Caption text](path/to/image.png){ width=80% }
```

The `{ width=80% }` attribute is a Pandoc extension that scales the image
relative to the text width. You can also use absolute sizes: `{ width=10cm }`.

---

# Full Reference Command

```bash
pandoc pandoc-guide.md \
  --from markdown+smart \
  --to pdf \
  --template eisvogel \
  --pdf-engine xelatex \
  --highlight-style tango \
  --number-sections \
  -o pandoc-guide.pdf
```

| Flag                      | Purpose                                      |
|---------------------------|----------------------------------------------|
| `--from markdown+smart`   | Enable smart quotes and dashes               |
| `--template eisvogel`     | Use the Eisvogel LaTeX template              |
| `--pdf-engine xelatex`    | Required for custom fonts (TTF/OTF)          |
| `--highlight-style tango` | Syntax highlight theme for code blocks       |
| `--number-sections`       | Auto-number headings (1, 1.1, 1.1.1 …)      |

---

# Multi-File Documents

For large documents or those written by multiple authors, splitting content
across several `.md` files is the recommended approach. Pandoc concatenates
them in the order you list them before running any conversion.

## Why Split Files?

- **Parallel authoring**: each contributor owns one or more chapter files
  without touching others, which eliminates merge conflicts on shared content.
- **Focused diffs**: a pull request that only modifies `03-api-reference.md`
  is immediately clear in scope — reviewers do not have to scroll through
  unrelated chapters.
- **Independent review**: sections can be reviewed and approved separately
  before the final document is assembled.
- **Reusability**: a chapter like `appendix-glossary.md` can be included in
  multiple documents by referencing it in different build commands.

## Recommended File Structure

```text
project-doc/
├── metadata.yaml          ← shared YAML front matter (title, fonts, colors…)
├── chapters/
│   ├── 01-introduction.md      ← Author: Alice
│   ├── 02-architecture.md      ← Author: Bob
│   ├── 03-api-reference.md     ← Author: Carol
│   └── 04-deployment.md        ← Author: Alice
└── Makefile               ← build automation
```

The numeric prefix on chapter files (`01-`, `02-`, …) keeps them ordered in
the filesystem and makes the glob pattern `chapters/*.md` produce the correct
sequence automatically.

## Separating Metadata from Content

When using multiple source files, put the YAML front matter in its own
`metadata.yaml` file and pass it as the first argument to Pandoc. That way
individual chapter files stay clean and authors do not need to worry about
document-level settings.

`metadata.yaml`:

```yaml
---
title: "Platform API — Technical Guide"
author:
  - "Alice Nguyen"
  - "Bob Martínez"
  - "Carol Smith"
date: "2026-04-13"
subject: "Engineering Documentation"
keywords: [api, architecture, deployment]
lang: "en"
toc: true
toc-own-page: true
titlepage: true
titlepage-color: "1E2A38"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "4A90D9"
titlepage-rule-height: 4
fontsize: 11pt
mainfont: "DejaVu Serif"
sansfont: "DejaVu Sans"
monofont: "DejaVu Sans Mono"
geometry: "margin=2.5cm"
linkcolor: "4A90D9"
urlcolor: "4A90D9"
numbersections: true
---
```

Chapter files carry **no YAML header** — just content:

```markdown
# Introduction

This chapter covers…
```

## Build Command

```bash
pandoc metadata.yaml chapters/*.md \
  --from markdown+smart \
  --to pdf \
  --template eisvogel \
  --pdf-engine xelatex \
  --highlight-style tango \
  --number-sections \
  -o output/platform-api-guide.pdf
```

The `chapters/*.md` glob expands in alphabetical order, so the `01-`, `02-`
prefixes determine chapter sequence.

To control the order explicitly (useful when not all files should be included):

```bash
pandoc metadata.yaml \
  chapters/01-introduction.md \
  chapters/02-architecture.md \
  chapters/04-deployment.md \
  --template eisvogel --pdf-engine xelatex -o output/guide.pdf
```

## Per-Chapter Author Attribution

Pandoc does not natively render per-chapter author bylines, but a simple
convention is to add a blockquote at the top of each chapter file:

```markdown
# Architecture Overview

> **Author:** Bob Martínez — last updated 2026-04-10

This chapter describes…
```

This renders as a styled pull-quote in the PDF and makes authorship visible
inside the document without affecting the title page.

## Using a Makefile for Automation

A `Makefile` at the project root avoids retyping the long Pandoc command and
gives collaborators a single entry point:

```makefile
OUTPUT  = output/platform-api-guide.pdf
SOURCES = metadata.yaml $(wildcard chapters/*.md)
FLAGS   = --from markdown+smart --template eisvogel \
          --pdf-engine xelatex --highlight-style tango \
          --number-sections

$(OUTPUT): $(SOURCES)
	@mkdir -p output
	pandoc $(FLAGS) $^ -o $@

clean:
	rm -f $(OUTPUT)
```

Run `make` to build; it only rebuilds when a source file has changed. Run
`make clean` to remove the generated PDF.

## Git Workflow for Collaborative Writing

```text
main
├── feature/chapter-02-architecture   ← Bob's branch
├── feature/chapter-03-api            ← Carol's branch
└── feature/chapter-04-deployment     ← Alice's branch
```

Each author works on their own branch, opens a pull request targeting `main`,
and the reviewer can build a preview PDF of just that chapter:

```bash
# preview a single chapter during review
pandoc metadata.yaml chapters/02-architecture.md \
  --template eisvogel --pdf-engine xelatex -o preview.pdf
```

Once all chapter PRs are merged, `make` on `main` produces the final assembled
document.

## Chapter File Conventions

| Convention | Reason |
|---|---|
| Numeric prefix (`01-`, `02-`) | Controls glob order; no manual sorting |
| Kebab-case filenames | Shell-safe; no quoting needed in scripts |
| No YAML header in chapters | Keeps authoring simple; metadata is centralized |
| One `#` heading per file | Maps to one top-level chapter in the TOC |
| Blockquote for author/date | Visible attribution without custom template work |

---

# Tips

- **Version control friendly**: `.md` files diff cleanly; PDFs do not.
  Commit only the source; generate the PDF in CI or on demand.
- **Variables file**: Extract the YAML into a `metadata.yaml` (shown above)
  and pass it as the first Pandoc argument to share settings across builds.
- **Print vs. screen**: Use `linkcolor: black` and `urlcolor: black` for
  documents that will be printed; use colors for digital distribution.
- **CI builds**: Add a GitHub Actions job that runs `make` on every push to
  `main` and uploads the PDF as a build artifact — contributors always have
  access to the latest assembled document without running Pandoc locally.
