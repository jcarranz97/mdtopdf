# Preface {.unnumbered}

This document is a multi-author technical reference for the internal Platform
API. It covers system architecture, REST endpoint specification, and operational
procedures for deployment and incident response.

## How to Read This Guide

The guide is divided into four chapters, each owned by the engineer closest to
that subject area:

| Chapter | Author | Topic |
|---|---|---|
| 1 | Alice Nguyen | Introduction, scope, and conventions |
| 2 | Bob Martínez | Architecture, data flow, and technology choices |
| 3 | Carol Smith | Full REST API reference |
| 4 | Alice Nguyen | Deployment procedures and operational runbook |

## How This Document Is Built

Source files live in the shared `docs/` directory one level above this folder.
The `Makefile` copies them into `_src/` before Quarto renders the book, keeping
the source of truth in one place regardless of which tool is used to produce
the final output.

```
mdtopdf/
├── docs/          ← shared Markdown source (edit here)
├── pandoc/        ← renders via Pandoc + Eisvogel → PDF
├── quarto/        ← renders via Quarto → PDF + HTML  (you are here)
└── sphinx/        ← renders via Sphinx + MyST → HTML + PDF
```
