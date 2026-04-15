FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-latex-extra \
      texlive-plain-generic \
      fonts-dejavu \
      latexmk \
      make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
      "sphinx>=7.0" \
      "myst-parser>=3.0" \
      "sphinx-rtd-theme>=2.0"

WORKDIR /workspace
