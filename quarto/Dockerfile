FROM ubuntu:24.04

ARG QUARTO_VERSION=1.6.42
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
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

RUN curl -fsSLo /tmp/quarto.deb \
      "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb

# Bake default config files into the image at /defaults/ so users can
# reference them without cloning the repo.
# Build context must be the repo root for these COPY paths to resolve.
COPY quarto/_quarto.yml /defaults/_quarto.yml
COPY quarto/index.md /defaults/index.md
COPY filters/doc-type.lua /defaults/doc-type.lua

WORKDIR /workspace
