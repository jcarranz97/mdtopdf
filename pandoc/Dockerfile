FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      pandoc \
      texlive-xetex \
      texlive-fonts-recommended \
      texlive-latex-extra \
      texlive-plain-generic \
      fonts-dejavu \
      make \
      curl \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Eisvogel template
RUN mkdir -p /root/.local/share/pandoc/templates \
    && curl -sLO https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz \
    && tar -xzf Eisvogel.tar.gz --strip-components=1 --wildcards '*/eisvogel.latex' \
    && mv eisvogel.latex /root/.local/share/pandoc/templates/ \
    && rm -f Eisvogel.tar.gz

WORKDIR /workspace
