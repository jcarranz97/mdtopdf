# mdtopdf — Markdown to PDF with Pandoc

[![Build Docker images](https://github.com/jcarranz97/mdtopdf/actions/workflows/build-pandoc-image.yml/badge.svg)](https://github.com/jcarranz97/mdtopdf/actions/workflows/build-pandoc-image.yml)
[![Test Docker images](https://github.com/jcarranz97/mdtopdf/actions/workflows/test-docker-images.yml/badge.svg)](https://github.com/jcarranz97/mdtopdf/actions/workflows/test-docker-images.yml)
[![Generate PDFs](https://github.com/jcarranz97/mdtopdf/actions/workflows/generate-pdfs.yml/badge.svg)](https://github.com/jcarranz97/mdtopdf/actions/workflows/generate-pdfs.yml)

A configurable framework and Docker image for generating professional PDFs from
Markdown using **Pandoc**. Write your content in plain Markdown, run one command,
get a polished PDF — no LaTeX knowledge required.

The Docker image bundles Pandoc, XeLaTeX, fonts, and the Makefile so you don't
need to install anything locally.

---

## Quick Start

Pull the image and point it at your Markdown files:

```bash
docker run --rm \
  -v /path/to/your/docs:/docs \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  DOCS_DIR=/docs \
  DOC_ID=1234 \
  DOC_MAJOR=1 \
  DOC_MINOR=0 \
  DOC_DATE="April 2026"
```

Output: `/path/to/your/docs/output.pdf`

All variables are optional — omit any you don't need and the Makefile
defaults kick in.

---

## Project Structure

```text
mdtopdf/
├── docs/                  ← shared Markdown source (the only place you edit)
│   ├── 01-introduction.md
│   ├── 02-architecture.md
│   ├── 03-api-reference.md
│   ├── 04-deployment.md
│   ├── 05-code-examples.md
│   └── 06-variants.md
├── filters/
│   ├── doc-type.lua       ← Lua filter for conditional content (Pandoc + Quarto)
│   └── filter_type.py     ← Python preprocessor for conditional content (Sphinx)
├── pandoc/
│   ├── chapter-break.lua  ← Lua filter for chapter page breaks (Eisvogel workaround)
│   ├── metadata.yaml      ← document settings: fonts, colors, title page, layout
│   ├── pandoc-guide.md    ← Pandoc feature reference
│   ├── Dockerfile
│   └── Makefile
├── quarto/                ← alternative tool (not actively maintained)
└── sphinx/                ← alternative tool (not actively maintained)
```

`docs/` is the single source of truth. **Never edit files in `_src/` or
`output/`** — they are ephemeral build artifacts regenerated on every `make` run.

---

## Using This Template for Your Own Project

### Option 1 — Docker (no local install)

Mount your docs folder and run:

```bash
docker run --rm \
  -v /path/to/your/docs:/docs \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  DOCS_DIR=/docs \
  DOC_ID=1234 \
  DOC_MAJOR=1 \
  DOC_MINOR=0 \
  DOC_DATE="April 2026"
```

### Option 2 — Custom styling

Extract the default `metadata.yaml`, edit it, then mount it back:

```bash
# 1. Extract the default config
docker run --rm ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  cat /defaults/metadata.yaml > metadata.yaml

# 2. Edit metadata.yaml — change fonts, colors, titlepage settings, etc.

# 3. Build with your custom metadata
docker run --rm \
  -v /path/to/your/docs:/docs \
  -v "$(pwd)/metadata.yaml":/pandoc/metadata.yaml \
  ghcr.io/jcarranz97/mdtopdf-pandoc:latest \
  DOCS_DIR=/docs DOC_ID=1234 DOC_MAJOR=1 DOC_MINOR=0
```

### Option 3 — Clone and adapt

Clone the repo to get the full setup: Makefile, filters, CI workflow, and
sample docs.

```bash
git clone https://github.com/jcarranz97/mdtopdf.git
cd mdtopdf/pandoc/
make
```

Files to copy into your own project:

| File | Purpose |
|---|---|
| `pandoc/metadata.yaml` | Fonts, colors, title page, layout |
| `pandoc/Makefile` | Build targets |
| `pandoc/chapter-break.lua` | Chapter page-break workaround for Eisvogel |
| `filters/doc-type.lua` | Conditional content filter |

Put your `.md` files in `docs/` and run `make`.

---

## Document Identity Variables

All page headers are controlled by four Makefile variables:

| Variable | Default | Description |
|---|---|---|
| `DOC_ID` | `1234` | Document identifier |
| `DOC_MAJOR` | `1` | Major revision number |
| `DOC_MINOR` | `00` | Minor revision number |
| `DOC_DATE` | `April 14, 2026` | Document date |

These combine into the **top-left header**: `{DOC_ID} Rev {DOC_MAJOR}.{DOC_MINOR} - {DOC_DATE}`

Pass any combination to `make` — unset variables fall back to defaults:

```bash
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01
make DOC_ID=9001 DOC_MAJOR=3 DOC_MINOR=05 DOC_DATE="June 30, 2026"
```

---

## Customization (`metadata.yaml`)

All visual settings live in `pandoc/metadata.yaml`. Individual chapter files
carry no YAML header — authors only write content.

### Document metadata

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

### Font size

```yaml
fontsize: 10pt   # compact
fontsize: 11pt   # default
fontsize: 12pt   # larger, good for accessibility
```

### Font families

```yaml
mainfont: "DejaVu Serif"      # body text (serif)
sansfont: "DejaVu Sans"       # headings (sans-serif)
monofont: "DejaVu Sans Mono"  # code blocks
```

List fonts available on your system:

```bash
fc-list : family | sort
```

### Page layout

```yaml
geometry: "margin=2.5cm"
papersize: a4        # or: letter
linestretch: 1.25
```

### Title page (Eisvogel-specific)

```yaml
titlepage: true
titlepage-color: "1E2A38"
titlepage-text-color: "FFFFFF"
titlepage-rule-color: "4A90D9"
titlepage-rule-height: 4
logo: "logo.png"
logo-width: 120
```

### Table of contents

```yaml
toc: true
toc-own-page: true
toc-depth: 3
```

### Link colors

```yaml
linkcolor: "4A90D9"
urlcolor: "4A90D9"
citecolor: "4A90D9"
```

---

## Example Templates

Different LaTeX templates can be swapped in via the `--template` flag and
`metadata.yaml`. The following templates have been tested and documented.

### Eisvogel

[Eisvogel](https://github.com/Wandmalfarbe/pandoc-latex-template) is a clean,
professional LaTeX template for Pandoc. It supports title pages, colored
headings, syntax highlighting, and a wide range of layout options — all
configurable through YAML front matter.

The default configuration in this repo (`pandoc/metadata.yaml`) targets
Eisvogel. See the [Customization](#customization-metadatayaml) section for the
full list of supported variables and the
[Manual Installation](#manual-installation) section for setup instructions.

> Screenshots coming soon.

---

## Document Variants (Conditional Content)

The same `.md` source can produce different PDFs for different audiences by
wrapping content in **fenced divs** tagged with a document type.

### Block-level

```markdown
This paragraph appears in every variant.

::: {.type1}
This block is only included when DOC_TYPE=type1.
:::

::: {.type1 .type2}
Included when DOC_TYPE=type1 OR DOC_TYPE=type2.
:::

::: {.not-type1}
Shown in every build except type1.
:::
```

### Inline (spans — for table cells and partial sentences)

```markdown
text1[ and text2]{.type1}       → type1: "text1 and text2"  |  type2: "text1"
text1[ and text2]{.not-type2}   → type1: "text1 and text2"  |  type2: "text1"
```

Put the leading space **inside** the brackets so removal leaves clean text.

### Building a specific variant

```bash
make DOC_TYPE=type2
make DOC_TYPE=type3 DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01
```

If `DOC_TYPE` is not set, all content is kept (no filtering applied).

The filter is implemented as a Lua filter (`filters/doc-type.lua`) that
operates at the Pandoc AST level — fenced divs and spans are handled cleanly
without any text-level preprocessing.

### Adding a new type

1. Choose a name following the `typeN` pattern (e.g. `type4`).
2. Wrap content in `.md` files with `::: {.type4}` … `:::`.
3. Build with `DOC_TYPE=type4` — no config changes needed.

---

## Multi-File Workflow

### Why split into multiple files

- **Parallel authoring** — each contributor owns one file; content merge conflicts are eliminated.
- **Focused pull requests** — a PR that only touches `03-api-reference.md` is immediately clear in scope.
- **Independent review** — chapters can be reviewed and approved separately.

### Chapter file conventions

| Convention | Reason |
|---|---|
| Numeric prefix (`01-`, `02-`) | Controls glob order; no manual sorting |
| Kebab-case filenames | Shell-safe; no quoting needed in scripts |
| No YAML header in chapter files | Metadata is centralized in `metadata.yaml` |
| One `#` heading per file | Maps to one top-level chapter in the TOC |

### Previewing a single chapter

```bash
cd pandoc/
make preview CHAPTER=02

# or directly with pandoc:
pandoc metadata.yaml ../docs/02-architecture.md \
  --template eisvogel --pdf-engine xelatex -o preview.pdf
```

---

## Running Locally (no Docker)

If you prefer not to use the Docker image, install the required tools directly
on your system and run the Makefile from the `pandoc/` directory.

### Installation

Install the following packages before running any build commands:

#### Pandoc

```bash
# macOS
brew install pandoc

# Ubuntu / Debian — install the official binary (apt package is often outdated)
curl -L https://github.com/jgm/pandoc/releases/latest/download/pandoc-3.6.4-linux-amd64.tar.gz \
  | tar xz --strip-components=1 -C ~/.local

pandoc --version
```

#### LaTeX engine

```bash
# macOS
brew install --cask mactex

# Ubuntu / Debian
sudo apt install texlive-xetex texlive-fonts-recommended texlive-fonts-extra
```

#### Eisvogel template

```bash
mkdir -p ~/.local/share/pandoc/templates

curl -L https://github.com/Wandmalfarbe/pandoc-latex-template/releases/download/2.4.2/Eisvogel-2.4.2.tar.gz \
  -o /tmp/eisvogel.tar.gz
tar -xzf /tmp/eisvogel.tar.gz -C /tmp/
cp /tmp/eisvogel.latex ~/.local/share/pandoc/templates/

ls ~/.local/share/pandoc/templates/
# → eisvogel.latex
```

> **Version note:** the 2.4.2 release tag has no `v` prefix.

### Build Commands

```bash
cd pandoc/

make                                              # full PDF, default vars
make DOC_TYPE=type2                               # different variant
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01        # custom header
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01 DOC_DATE="May 1, 2026"

make preview CHAPTER=02     # single chapter preview
make single                 # pandoc-guide.md only → output/pandoc-guide.pdf
make clean                  # remove output/
make help                   # list all targets
```

Output: `pandoc/output/platform-api-guide.pdf`

#### Full CLI Reference

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

---

## GitHub Actions

The workflow at `.github/workflows/generate-pdfs.yml` runs on every pull
request. It builds a PDF from `docs/` and uploads it as a downloadable artifact
so you can review the rendered output before merging.

---

## Known Gotchas

- **`--variable` vs `--metadata` in Pandoc** — `--variable` inserts values
  raw into LaTeX; `--metadata` escapes them as Markdown. Using the wrong one
  silently produces broken output (e.g. `\thepage` becomes literal text).
- **Eisvogel uses `scrartcl`** which has no `\chapter` command. Chapter
  page-breaks are handled by `pandoc/chapter-break.lua`.
- **Quarto `_header.tex`** is generated by the Makefile using `printf`. Avoid
  characters like `\f`, `\r`, `\t` in variable values.

---

## Alternatives

This repo also contains configurations for **Quarto** and **Sphinx + MyST**,
kept for reference only. They are not actively maintained and their Docker
images may be out of date.

| Tool | Best for |
|---|---|
| Pandoc *(this project)* | Single or multi-file PDFs, CLI-driven, configurable templates |
| Quarto | Books or reports that need both PDF and HTML from one source |
| Sphinx + MyST | Full documentation sites, Python projects |
