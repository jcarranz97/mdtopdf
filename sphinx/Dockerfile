FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-latex-extra \
      texlive-plain-generic \
      fonts-dejavu \
      lmodern \
      latexmk \
      make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
      "sphinx>=7.0" \
      "myst-parser>=3.0" \
      "sphinx-rtd-theme>=2.0"

# Bake default config files into the image at /defaults/ so users can
# reference them without cloning the repo.
# Build context must be the repo root for these COPY paths to resolve.
COPY sphinx/conf.py /defaults/conf.py
COPY sphinx/index.md /defaults/index.md
COPY filters/filter_type.py /defaults/filter_type.py

WORKDIR /workspace
