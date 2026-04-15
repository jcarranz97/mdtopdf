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

# Mirror the repo layout so the Makefile's relative paths resolve identically
# inside the container as they do in the repo:
#   /pandoc/Makefile  →  WORKDIR
#   /pandoc/metadata.yaml  /pandoc/chapter-break.lua
#   /filters/doc-type.lua  →  ../filters/ from /pandoc/
#
# /defaults/ is kept as a user-facing extraction point (Option 2 in the docs).
# Build context must be the repo root for these COPY paths to resolve.
COPY pandoc/Makefile          /pandoc/Makefile
COPY pandoc/metadata.yaml     /pandoc/metadata.yaml
COPY pandoc/chapter-break.lua /pandoc/chapter-break.lua
COPY filters/doc-type.lua     /filters/doc-type.lua
COPY pandoc/metadata.yaml     /defaults/metadata.yaml

COPY pandoc/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

WORKDIR /pandoc
