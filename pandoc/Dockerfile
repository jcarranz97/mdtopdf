FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      pandoc \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-latex-extra \
      texlive-plain-generic \
      fonts-dejavu \
      lmodern \
      make \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Eisvogel template into the system-wide pandoc data directory
RUN mkdir -p /usr/share/pandoc/data/templates \
    && curl -sLO https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
    && tar -xzf Eisvogel.tar.gz --strip-components=1 --wildcards '*/eisvogel.latex' \
    && mv eisvogel.latex /usr/share/pandoc/data/templates/ \
    && rm -f Eisvogel.tar.gz

# Bake default config files into the image at /defaults/ so users can
# reference them without cloning the repo.
# Build context must be the repo root for these COPY paths to resolve.
COPY pandoc/metadata.yaml /defaults/metadata.yaml
COPY pandoc/chapter-break.lua /defaults/chapter-break.lua
COPY filters/doc-type.lua /defaults/doc-type.lua

WORKDIR /workspace
