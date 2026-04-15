# CLAUDE.md — mdtopdf

This repo compares three ways to build professional PDFs from Markdown:
**Pandoc + Eisvogel**, **Quarto**, and **Sphinx + MyST**. All three tools
render the same source from `docs/` so output can be compared side-by-side.

---

## Repository layout

```
mdtopdf/
├── docs/               ← SINGLE SOURCE OF TRUTH — edit only here
│   ├── 01-introduction.md
│   ├── 02-architecture.md
│   ├── 03-api-reference.md
│   ├── 04-deployment.md
│   ├── 05-code-examples.md
│   └── 06-variants.md
├── filters/
│   ├── doc-type.lua    ← Lua filter for Pandoc + Quarto (AST-level)
│   └── filter_type.py  ← Python preprocessor for Sphinx (text-level)
├── pandoc/
│   ├── Makefile
│   ├── metadata.yaml   ← fonts, colours, layout
│   ├── chapter-break.lua
│   └── pandoc-guide.md ← Pandoc feature reference
├── quarto/
│   ├── Makefile
│   ├── _quarto.yml     ← book config (PDF + HTML)
│   └── index.md        ← preface / landing page
├── sphinx/
│   ├── Makefile
│   ├── conf.py         ← Sphinx + MyST config (reads env vars for headers)
│   ├── index.md        ← toctree root
│   └── requirements.txt
└── .github/
    └── workflows/
        └── generate-pdfs.yml  ← CI: build PDFs on pull requests
```

**Never edit files in `_src/` or `output/`** — they are ephemeral build
artifacts regenerated on every `make` run.

---

## Build commands

All Makefiles share the same variables. Unset variables fall back to defaults.

### Pandoc (reads `../docs/*.md` directly — no staging step)

```bash
cd pandoc/
make                                              # full PDF, default vars
make DOC_TYPE=type2                               # different variant
make DOC_ID=5678 DOC_MAJOR=2 DOC_MINOR=01        # custom header
make preview CHAPTER=02                           # single chapter
make single                                       # pandoc-guide.md only
make clean
```

Output: `pandoc/output/platform-api-guide.pdf`

### Quarto (stages docs/ → _src/, then renders)

```bash
cd quarto/
make                                              # PDF + HTML, default vars
make pdf DOC_TYPE=type2
make html
make sync                                         # stage only, no render
make clean                                        # removes _build/ _src/ _header.tex
```

Output: `quarto/_build/`

### Sphinx (stages docs/ → _src/ with Python filter, then builds)

```bash
cd sphinx/
source venv/bin/activate    # or .venv/bin/activate
make                                              # HTML (default)
make html DOC_TYPE=type2
make pdf
make sync                                         # stage only
make clean                                        # removes _build/ _src/
```

Output: `sphinx/_build/html/` and `sphinx/_build/latex/`

---

## Document identity variables (all three tools)

| Variable | Default | Effect |
|---|---|---|
| `DOC_ID` | `1234` | Document ID in page header |
| `DOC_MAJOR` | `1` | Major revision |
| `DOC_MINOR` | `00` | Minor revision |
| `DOC_DATE` | `April 14, 2026` | Date in page header |
| `DOC_TYPE` | `type1` | Controls conditional content filtering |

Header left: `{DOC_ID} Rev {DOC_MAJOR}.{DOC_MINOR} - {DOC_DATE}`

---

## Conditional content (variant filtering)

The same `.md` source can produce different output per `DOC_TYPE`.

### Block-level (fenced divs — for paragraphs, tables, whole sections)

```markdown
::: {.type1}
Shown only in type1 builds.
:::

::: {.type1 .type2}
Shown in type1 OR type2.
:::

::: {.not-type1}
Shown in every build except type1 (if/else).
:::

::: {.not-type1 .not-type2}
Shown when type is neither type1 nor type2.
:::
```

### Inline-level (spans — for table cells, partial sentences)

```markdown
text1[ and text2]{.type1}          → type1: "text1 and text2"  type2: "text1"
text1[ and text2]{.not-type2}      → type1: "text1 and text2"  type2: "text1"
```

Put the leading space **inside** the brackets so removal leaves clean text.

**Same table, different cell content:**

```markdown
::: {.type1 .type2}
| Setting | Value |
|---------|-------|
| Mode    | basic[ and advanced]{.type1} |
:::
```

### Filter implementation

| Tool | Mechanism |
|---|---|
| Pandoc | `filters/doc-type.lua` — `Div` + `Span` AST visitors |
| Quarto | Same Lua filter, registered in `_quarto.yml` |
| Sphinx | `filters/filter_type.py` — regex passes for divs then spans |

---

## GitHub Actions

The workflow at `.github/workflows/generate-pdfs.yml` runs on every pull
request (`opened`, `synchronize`, `reopened`). It has three parallel jobs —
one per tool — that each build a PDF from the shared `docs/` source and upload
the result as a downloadable artifact so outputs can be compared side by side.

| Job | Installs | Artifact |
|---|---|---|
| `pandoc-pdf` | `pandoc`, system TeX, Eisvogel template | `pandoc-pdf` |
| `quarto-pdf` | Quarto CLI, system TeX | `quarto-pdf` |
| `sphinx-pdf` | Python + `requirements.txt`, system TeX, `latexmk` | `sphinx-pdf` |

All three jobs install `texlive-xetex` and `fonts-dejavu` (required because
every tool is configured to use `xelatex` with the DejaVu font family).

---

## Key config files

| File | Purpose |
|---|---|
| `pandoc/metadata.yaml` | Fonts, colours, title page, TOC, page layout |
| `quarto/_quarto.yml` | Book chapters, PDF/HTML format options |
| `sphinx/conf.py` | MyST extensions, LaTeX elements, `exclude_patterns` |
| `filters/doc-type.lua` | Pandoc/Quarto conditional filter |
| `filters/filter_type.py` | Sphinx conditional filter |
| `.github/workflows/generate-pdfs.yml` | CI workflow — PDF generation on PRs |

---

## What is and isn't committed

```gitignore
pandoc/output/          # generated PDFs
quarto/_src/            # staged copies of docs/
quarto/_build/          # rendered output
quarto/_header.tex      # generated from Makefile vars
sphinx/_src/            # staged copies of docs/
sphinx/_build/          # rendered output
sphinx/venv/            # Python virtual environment
sphinx/.venv/           # Python virtual environment (dotfile variant)
```

Only source files are committed. Never commit `_src/`, `_build/`, or `output/`.

---

## Known gotchas

- **`pandoc/` reads `../docs/` directly** — no `_src/` staging. Quarto and
  Sphinx need staging because they cannot reference files outside their project
  directory.
- **Quarto `_header.tex`** is generated by the Makefile from `DOC_*` vars
  using `printf`. Avoid characters like `\f`, `\r`, `\t` in variable values —
  `printf` interprets them as control characters.
- **Sphinx `exclude_patterns`** must include both `venv/**` and `.venv/**`,
  otherwise Sphinx crawls the virtual environment and reads package READMEs
  and autosummary templates as documentation sources.
- **Sphinx `autosectionlabel_prefix_document = True`** is set to prevent
  duplicate-label warnings when two source files share a heading name.
- **`--variable` vs `--metadata` in Pandoc** — `--variable` inserts values
  raw into LaTeX; `--metadata` escapes them as Markdown. Using the wrong one
  silently produces broken output (e.g. `\thepage` becomes literal text).
- **Eisvogel uses `scrartcl`** which has no `\chapter` command. Chapter
  page-breaks are handled by `pandoc/chapter-break.lua`.
